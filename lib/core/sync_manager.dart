import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:distributeapp/api/playlists_api.dart';
import 'package:distributeapp/core/database/daos/sync_dao.dart';
import 'package:distributeapp/core/database/database.dart';
import 'package:distributeapp/core/sync_status.dart';

import 'package:distributeapp/repositories/auth_repository.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class SyncManager with WidgetsBindingObserver {
  final AuthRepository authRepo;
  final SyncDao _syncDao;
  final PlaylistsApi _playlistsApi;
  final Connectivity _connectivity = Connectivity();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  StreamSubscription? _queueSubscription;
  Timer? _debounceTimer;
  Timer? _periodicTimer;

  SyncManager(this.authRepo, this._syncDao, this._playlistsApi);

  void initialize() {
    WidgetsBinding.instance.addObserver(this);

    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      if (result.contains(ConnectivityResult.none) && result.length == 1) {
        return;
      }
      triggerSync();
    });

    if (authRepo.isLoggedIn) {
      triggerSync();
    }

    // 1. Reactive Push Sync (Debounced)
    _queueSubscription = _syncDao.watchPendingItems().listen((items) {
      if (items.isNotEmpty) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 500), () {
          triggerSync();
        });
      }
    });

    // 2. Periodic Pull Sync (Every 5 minutes)
    _periodicTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      triggerSync();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      triggerSync();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _queueSubscription?.cancel();
    _debounceTimer?.cancel();
    _periodicTimer?.cancel();
    _statusController.close();
  }

  Future<void> triggerSync() async {
    if (_isSyncing) return;
    if (authRepo.loggedInUser == null) return;

    final result = await _connectivity.checkConnectivity();
    if (result.contains(ConnectivityResult.none) && result.isEmpty) return;

    _isSyncing = true;
    _statusController.add(const SyncStatus.syncing());
    try {
      await _processOutbox();
      await _performPull();
      _statusController.add(const SyncStatus.idle());
    } catch (e) {
      _statusController.add(SyncStatus.error(e.toString()));
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processOutbox() async {
    final pendingItems = await _syncDao.getPendingItems();

    for (final item in pendingItems) {
      Map<String, dynamic> data;
      try {
        data = jsonDecode(item.payload);
      } catch (e) {
        debugPrint("Sync Error (JSON) on item ${item.id}: $e");
        // Permanent error: Invalid payload, delete item to unblock queue
        await _syncDao.deleteItem(item.id);
        continue;
      }

      try {
        debugPrint(
          "Syncing item ${item.id}: ${item.action} on ${item.entityTable}",
        );
        await _performSyncAction(item, data);
        // If successful, delete from queue
        await _syncDao.deleteItem(item.id);
      } catch (e) {
        debugPrint("Sync Error on item ${item.id}: $e");
        if (_isTransientError(e)) {
          // Transient error: Stop syncing and retry later to preserve order
          break;
        } else {
          // Permanent error (e.g. 400 Bad Request): Delete item to unblock queue
          await _syncDao.deleteItem(item.id);
        }
      }
    }
  }

  String? get userId => authRepo.loggedInUser?.id;
  String? get rootFolderId => authRepo.rootFolderId;

  bool _isTransientError(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return true;
      }
      // Check for 5xx errors (Server errors)
      if (error.response != null) {
        final statusCode = error.response?.statusCode ?? 500;
        if (statusCode >= 500) {
          return true;
        }
      }
    }
    if (error is SocketException) {
      return true;
    }
    return false;
  }

  Future<void> _performSyncAction(
    SyncQueueData item,
    Map<String, dynamic> data,
  ) async {
    switch (item.entityTable) {
      case 'folders':
        await _handleFoldersAction(item.action, data);
        break;
      case 'playlists':
        await _handlePlaylistsAction(item.action, data);
        break;
      case 'playlist_songs':
        await _handlePlaylistSongsAction(item.action, data);
        break;
      default:
        // Unknown entity, consider handled so it gets deleted
        debugPrint("Unknown entity table: ${item.entityTable}");
        break;
    }
  }

  Future<void> _handleFoldersAction(
    String action,
    Map<String, dynamic> data,
  ) async {
    switch (action) {
      case 'CREATE':
        await _playlistsApi.createPlaylistFolder(
          data['id'],
          data['name'],
          data['parentFolderId'] ??
              rootFolderId ??
              (throw Exception("Root folder ID not found")),
        );
        break;
      case 'MOVE':
        await _playlistsApi.moveFolder(
          data['id'],
          data['parentId'] ??
              rootFolderId ??
              (throw Exception("Root folder ID not found")),
        );
        break;
      case 'RENAME':
        await _playlistsApi.renameFolder(data['id'], data['name']);
        break;
      case 'DELETE':
        await _playlistsApi.deleteFolder(data['id']);
        break;
      default:
        throw Exception("Unknown action for folders: $action");
    }
  }

  Future<void> _handlePlaylistsAction(
    String action,
    Map<String, dynamic> data,
  ) async {
    switch (action) {
      case 'CREATE':
        await _playlistsApi.createPlaylist(
          data['id'],
          data['name'],
          data['folderId'] ??
              rootFolderId ??
              (throw Exception("Root folder ID not found")),
        );
        break;
      case 'UPDATE_NAME':
        await _playlistsApi.renamePlaylist(data['id'], data['name']);
        break;
      case 'DELETE':
        await _playlistsApi.deletePlaylist(data['id']);
        break;
      case 'MOVE':
        await _playlistsApi.movePlaylist(
          data['id'],
          data['folderId'] ??
              rootFolderId ??
              (throw Exception("Root folder ID not found")),
        );
        break;
      default:
        throw Exception("Unknown action for playlists: $action");
    }
  }

  Future<void> _handlePlaylistSongsAction(
    String action,
    Map<String, dynamic> data,
  ) async {
    switch (action) {
      case 'ADD_SONG':
        await _playlistsApi.addSongToPlaylist(
          data['playlistId'],
          data['songId'],
        );
        break;
      case 'REMOVE_SONG':
        await _playlistsApi.removeSongFromPlaylist(
          data['playlistId'],
          data['songId'],
        );
        break;
      case 'MOVE_SONG':
        await _playlistsApi.moveSong(
          data['playlistId'],
          data['songId'],
          data['order'],
        );
        break;
      default:
        throw Exception("Unknown action for playlist_songs: $action");
    }
  }

  Future<DateTime?> _getLastSyncTime() async {
    final userId = authRepo.loggedInUser?.id;
    if (userId == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('last_sync_time_$userId');
    if (str == null) return null;
    return str.isEmpty ? null : DateTime.parse(str);
  }

  Future<void> reset() async {
    _saveLastSyncTime(DateTime(1971));
  }

  Future<void> _saveLastSyncTime(DateTime? time) async {
    final userId = authRepo.loggedInUser?.id;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final timeStr = time?.toUtc().toIso8601String() ?? '';
    debugPrint('Saving last sync time for user $userId: $timeStr');
    await prefs.setString('last_sync_time_$userId', timeStr);
  }

  Future<Set<String>> _getDirtyIds() async {
    final pending = await _syncDao.getPendingItems();
    final dirty = <String>{};
    for (final item in pending) {
      if (item.entityTable == 'playlists' ||
          item.entityTable == 'playlist_songs' ||
          item.entityTable == 'folders') {
        try {
          final data = jsonDecode(item.payload);
          String? id;
          if (item.entityTable == 'playlists') id = data['id'];
          if (item.entityTable == 'playlist_songs') id = data['playlistId'];
          if (item.entityTable == 'folders') id = data['id'];
          if (id != null) dirty.add(id);
        } catch (_) {}
      }
    }
    return dirty;
  }

  Future<void> _performPull() async {
    debugPrint("Starting Pull Sync...");
    debugPrint("Last Sync Time: ${await _getLastSyncTime()}");
    final lastSync = await _getLastSyncTime();
    final manifest = await _playlistsApi.getSyncChanges(lastSync);

    // 0. Identify local dirty items (skip updates for these)
    final dirtyIds = await _getDirtyIds();

    // Process Deletions (Protected: Skip deletion if item is dirty)
    if (manifest.removed.playlists.isNotEmpty) {
      final toDelete = manifest.removed.playlists
          .where((id) => !dirtyIds.contains(id))
          .toList();
      if (toDelete.isNotEmpty) {
        await _syncDao.deleteItems('playlists', toDelete);
      }
    }
    if (manifest.removed.folders.isNotEmpty) {
      final toDelete = manifest.removed.folders
          .where((id) => !dirtyIds.contains(id)) // PROTECTED DELETION
          .toList();
      if (toDelete.isNotEmpty) {
        await _syncDao.deleteItems('folders', toDelete);
      }
    }
    if (manifest.removed.songs.isNotEmpty) {
      await _syncDao.deleteItems('songs', manifest.removed.songs);
    }
    if (manifest.removed.albums.isNotEmpty) {
      await _syncDao.deleteItems('albums', manifest.removed.albums);
    }
    if (manifest.removed.artists.isNotEmpty) {
      await _syncDao.deleteItems('artists', manifest.removed.artists);
    }

    // Fetch & Upsert Components
    // 1. Artists
    if (manifest.changed.artists.isNotEmpty) {
      final artists = await _playlistsApi.getArtistsBatch(
        manifest.changed.artists,
      );
      await _syncDao.saveArtists(
        artists
            .map(
              (a) => ArtistsCompanion(
                id: Value(a.id),
                name: Value(a.name),
                updatedAt: Value(DateTime.now()),
              ),
            )
            .toList(),
      );
    }

    // 2. Albums
    if (manifest.changed.albums.isNotEmpty) {
      final albums = await _playlistsApi.getAlbumsBatch(
        manifest.changed.albums,
      );
      await _syncDao.saveAlbums(
        albums
            .map(
              (a) => AlbumsCompanion(
                id: Value(a.id),
                title: Value(a.title),
                releaseDate: Value(a.releaseDate),
                updatedAt: Value(DateTime.now()),
              ),
            )
            .toList(),
      );
    }

    // 3. Songs
    if (manifest.changed.songs.isNotEmpty) {
      final songs = await _playlistsApi.getSongsBatch(manifest.changed.songs);

      await _syncDao.saveSongs(
        songs
            .map(
              (s) => SongsCompanion(
                id: Value(s.id),
                title: Value(s.title),
                albumId: Value(s.albumId),
                durationSeconds: Value(0),
                isDownloaded: Value(false),
                updatedAt: Value(DateTime.now()),
              ),
            )
            .toList(),
      );

      // Save Artists from Songs (upsert)
      final allArtists = songs.expand((s) => s.artists).toList();
      if (allArtists.isNotEmpty) {
        await _syncDao.saveArtists(
          allArtists
              .map(
                (a) => ArtistsCompanion(
                  id: Value(a.id),
                  name: Value(a.name),
                  updatedAt: Value(DateTime.now()),
                ),
              )
              .toList(),
        );
      }

      // Save SongArtists
      final songArtists = <SongArtistsCompanion>[];
      for (final s in songs) {
        for (final a in s.artists) {
          songArtists.add(
            SongArtistsCompanion(songId: Value(s.id), artistId: Value(a.id)),
          );
        }
      }
      if (songArtists.isNotEmpty) {
        await _syncDao.saveSongArtists(songArtists);
      }
    }

    // 4. Folders
    if (manifest.changed.folders.isNotEmpty) {
      final folders = await _playlistsApi.getFoldersBatch(
        manifest.changed.folders,
      );

      final cleanFolders = folders
          .where((f) => !dirtyIds.contains(f.id)) // MERGE: Local wins
          .toList();

      if (cleanFolders.isNotEmpty) {
        await _syncDao.saveFolders(
          cleanFolders
              .map(
                (f) => FoldersCompanion(
                  id: Value(f.id),
                  name: Value(f.name),
                  parentFolderId: Value(f.parentFolderId),
                  updatedAt: Value(DateTime.now()),
                ),
              )
              .toList(),
        );
      }
    }

    // 5. Playlists
    if (manifest.changed.playlists.isNotEmpty) {
      final playlists = await _playlistsApi.getPlaylistsBatch(
        manifest.changed.playlists,
      );

      final cleanPlaylists = playlists
          .where((p) => !dirtyIds.contains(p.id))
          .toList();

      if (cleanPlaylists.isNotEmpty) {
        await _syncDao.savePlaylists(
          cleanPlaylists
              .map(
                (p) => PlaylistsCompanion(
                  id: Value(p.id),
                  name: Value(p.name),
                  folderId: Value(p.folderId),
                  updatedAt: Value(DateTime.now()),
                ),
              )
              .toList(),
        );

        // Handle Playlist Songs
        for (final p in cleanPlaylists) {
          if (p.playlistSongs.isNotEmpty) {
            await _syncDao.replacePlaylistSongs(p.id, p.playlistSongs);
          }
        }
      }
    }

    await _saveLastSyncTime(manifest.latestServerTime);
    debugPrint("Pull Sync Completed at ${manifest.latestServerTime}");
  }
}
