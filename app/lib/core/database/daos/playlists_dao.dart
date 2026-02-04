import 'dart:convert';
import 'package:distributeapp/core/database/database.dart';
import 'package:drift/drift.dart';
import '../tables.dart';
import '../../utils/ordering.dart';

part 'playlists_dao.g.dart';

@DriftAccessor(
  tables: [Playlists, Songs, PlaylistSongs, SyncQueue, Folders, SongArtists],
)
class PlaylistsDao extends DatabaseAccessor<AppDatabase>
    with _$PlaylistsDaoMixin {
  PlaylistsDao(super.db);

  Stream<List<PlaylistEntity>> watchByFolder(String? folderId) {
    return (select(playlists)..where(
          (t) => folderId == null
              ? t.folderId.isNull()
              : t.folderId.equals(folderId),
        ))
        .watch();
  }

  Stream<PlaylistEntity> watchPlaylist(String playlistId) {
    return (select(
      playlists,
    )..where((t) => t.id.equals(playlistId))).watchSingle();
  }

  Stream<List<TypedResult>> watchSongs(String playlistId) {
    final query =
        select(songs).join([
            innerJoin(playlistSongs, playlistSongs.songId.equalsExp(songs.id)),
            leftOuterJoin(albums, albums.id.equalsExp(songs.albumId)),
            leftOuterJoin(songArtists, songArtists.songId.equalsExp(songs.id)),
            leftOuterJoin(artists, artists.id.equalsExp(songArtists.artistId)),
          ])
          ..where(playlistSongs.playlistId.equals(playlistId))
          ..orderBy([OrderingTerm(expression: playlistSongs.order)]);

    return query.watch();
  }

  Future<void> createPlaylist(PlaylistEntity newPlaylist) async {
    await transaction(() async {
      await into(playlists).insert(newPlaylist);
      await into(syncQueue).insert(
        SyncQueueCompanion.insert(
          action: 'CREATE',
          entityTable: 'playlists',
          payload: jsonEncode(newPlaylist.toJson()),
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> updatePlaylistName(String id, String newName) async {
    await transaction(() async {
      await (update(playlists)..where((t) => t.id.equals(id))).write(
        PlaylistsCompanion(name: Value(newName)),
      );
      await into(syncQueue).insert(
        SyncQueueCompanion.insert(
          action: 'UPDATE_NAME',
          entityTable: 'playlists',
          payload: jsonEncode({'id': id, 'name': newName}),
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> deletePlaylist(String id) async {
    await transaction(() async {
      await (delete(playlists)..where((t) => t.id.equals(id))).go();
      await into(syncQueue).insert(
        SyncQueueCompanion.insert(
          action: 'DELETE',
          entityTable: 'playlists',
          payload: jsonEncode({'id': id}),
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    await transaction(() async {
      final lastSong =
          await (select(playlistSongs)
                ..where((t) => t.playlistId.equals(playlistId))
                ..orderBy([
                  (t) => OrderingTerm(
                    expression: t.order,
                    mode: OrderingMode.desc,
                  ),
                ])
                ..limit(1))
              .getSingleOrNull();

      final nextOrder = generateNextKey(lastSong?.order ?? '');

      await into(playlistSongs).insert(
        PlaylistSongsCompanion.insert(
          playlistId: playlistId,
          songId: songId,
          order: Value(nextOrder),
        ),
        mode: InsertMode.insert,
      );

      await into(syncQueue).insert(
        SyncQueueCompanion.insert(
          action: 'ADD_SONG',
          entityTable: 'playlist_songs',
          payload: jsonEncode({
            'playlistId': playlistId,
            'songId': songId,
            'order': nextOrder,
          }),
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> addSongToPlaylistWithMetadata({
    required String playlistId,
    required SongEntity song,
    required AlbumEntity album,
    required List<ArtistEntity> artists,
  }) async {
    await transaction(() async {
      await into(albums).insert(album, mode: InsertMode.insertOrIgnore);
      await into(songs).insert(song, mode: InsertMode.insertOrIgnore);

      for (final artist in artists) {
        await into(
          this.artists,
        ).insert(artist, mode: InsertMode.insertOrIgnore);

        await into(songArtists).insert(
          SongArtistsCompanion.insert(songId: song.id, artistId: artist.id),
          mode: InsertMode.insertOrIgnore,
        );
      }

      final lastSong =
          await (select(playlistSongs)
                ..where((t) => t.playlistId.equals(playlistId))
                ..orderBy([
                  (t) => OrderingTerm(
                    expression: t.order,
                    mode: OrderingMode.desc,
                  ),
                ])
                ..limit(1))
              .getSingleOrNull();

      final nextOrder = generateNextKey(lastSong?.order ?? '');

      await into(playlistSongs).insert(
        PlaylistSongsCompanion.insert(
          playlistId: playlistId,
          songId: song.id,
          order: Value(nextOrder),
        ),
        mode: InsertMode.insert,
      );

      await into(syncQueue).insert(
        SyncQueueCompanion.insert(
          action: 'ADD_SONG',
          entityTable: 'playlist_songs',
          payload: jsonEncode({
            'playlistId': playlistId,
            'songId': song.id,
            'order': nextOrder,
          }),
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    await transaction(() async {
      await (delete(playlistSongs)..where(
            (t) => t.playlistId.equals(playlistId) & t.songId.equals(songId),
          ))
          .go();
      await into(syncQueue).insert(
        SyncQueueCompanion.insert(
          action: 'REMOVE_SONG',
          entityTable: 'playlist_songs',
          payload: jsonEncode({'playlistId': playlistId, 'songId': songId}),
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> moveFolder(String itemId, String? folderId) async {
    await transaction(() async {
      await (update(folders)..where((t) => t.id.equals(itemId))).write(
        FoldersCompanion(parentFolderId: Value(folderId)),
      );
      await into(syncQueue).insert(
        SyncQueueCompanion.insert(
          action: 'MOVE',
          entityTable: 'folders',
          payload: jsonEncode({'id': itemId, 'parentId': folderId}),
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> movePlaylist(String itemId, String? folderId) async {
    await transaction(() async {
      await (update(playlists)..where((t) => t.id.equals(itemId))).write(
        PlaylistsCompanion(folderId: Value(folderId)),
      );
      await into(syncQueue).insert(
        SyncQueueCompanion.insert(
          action: 'MOVE',
          entityTable: 'playlists',
          payload: jsonEncode({'id': itemId, 'folderId': folderId}),
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> updateSongFile(
    String songId,
    String fileId,
    String format,
  ) async {
    await transaction(() async {
      await (update(songs)..where((t) => t.id.equals(songId))).write(
        SongsCompanion(fileId: Value(fileId), format: Value(format)),
      );
    });
  }

  Future<List<String>> getDownloadedFileIds() async {
    final result = await (select(
      songs,
    )..where((t) => t.isDownloaded.equals(true))).get();
    return result.map((song) => song.fileId).nonNulls.toList();
  }

  Future<void> updateSongDownloaded(String songId, bool downloaded) async {
    await (update(songs)..where((t) => t.id.equals(songId))).write(
      SongsCompanion(isDownloaded: Value(downloaded)),
    );
  }

  Future<void> moveSong(
    String playlistId,
    String songId,
    String? prevOrderId,
    String? nextOrderId,
  ) async {
    await transaction(() async {
      final newOrder = generateKeyBetween(prevOrderId, nextOrderId);

      await (update(playlistSongs)..where(
            (t) => t.playlistId.equals(playlistId) & t.songId.equals(songId),
          ))
          .write(PlaylistSongsCompanion(order: Value(newOrder)));

      await into(syncQueue).insert(
        SyncQueueCompanion.insert(
          action: 'MOVE_SONG',
          entityTable: 'playlist_songs',
          payload: jsonEncode({
            'playlistId': playlistId,
            'songId': songId,
            'order': newOrder,
          }),
          createdAt: DateTime.now(),
        ),
      );
    });
  }
}
