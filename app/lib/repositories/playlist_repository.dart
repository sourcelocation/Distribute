import 'package:collection/collection.dart';
import 'package:distributeapp/core/database/database.dart';
import 'package:distributeapp/model/playlist.dart';
import 'package:distributeapp/model/server_search_result.dart';
import 'package:distributeapp/model/song.dart';
import 'package:distributeapp/model/available_file.dart';
import 'package:distributeapp/api/songs_api.dart';
import 'package:distributeapp/core/preferences/audio_quality.dart';

import '../core/database/daos/playlists_dao.dart';
import 'package:uuid/uuid.dart';

class PlaylistRepository {
  final PlaylistsDao _dao;
  final SongsApi _songsApi;

  PlaylistRepository(this._dao, this._songsApi);

  Future<void> addSongWithMetadata(
    String playlistId,
    ServerSearchResultSong song,
  ) async {
    final songEntity = SongEntity(
      id: song.id,
      title: song.title,
      albumId: song.albumId,
      durationSeconds: 0, // Duration unknown for remote songs until downloaded
      fileId: null,
      format: null,
      isDownloaded: false,
    );

    final albumEntity = AlbumEntity(
      id: song.albumId,
      title: song.albumTitle,
      releaseDate: DateTime.now(), // Unknown release date
    );

    final artistEntities = song.artists
        .map((a) => ArtistEntity(id: a.id, name: a.name))
        .toList();

    await _dao.addSongToPlaylistWithMetadata(
      playlistId: playlistId,
      song: songEntity,
      album: albumEntity,
      artists: artistEntities,
    );
  }

  Stream<List<Playlist>> getPlaylists(String? folderId) => _dao
      .watchByFolder(folderId)
      .map(
        (playlists) =>
            playlists.map((playlist) => Playlist.fromDb(playlist)).toList(),
      );

  Stream<Playlist> getPlaylist(String playlistId) => _dao
      .watchPlaylist(playlistId)
      .map((playlist) => Playlist.fromDb(playlist));

  Stream<List<Song>> getSongs(String playlistId) {
    return _dao.watchSongs(playlistId).map((rows) {
      final grouped = rows.groupListsBy((row) => row.readTable(_dao.songs).id);

      return grouped.values.map((songRows) {
        final songEntity = songRows.first.readTable(_dao.songs);
        final albumEntity = songRows.first.readTableOrNull(_dao.albums);

        final artistNames = songRows
            .map((row) => row.readTableOrNull(_dao.artists)?.name)
            .whereType<String>()
            .toSet()
            .toList();

        final playlistSong = songRows.first.readTableOrNull(_dao.playlistSongs);

        return Song(
          id: songEntity.id,
          title: songEntity.title,
          artists: artistNames.isEmpty ? ['Unknown Artist'] : artistNames,
          albumTitle: albumEntity?.title ?? 'Unknown Album',
          albumId: songEntity.albumId,
          fileId: songEntity.fileId,
          format: songEntity.format,
          isDownloaded: songEntity.isDownloaded,
          order: playlistSong?.order,
        );
      }).toList();
    });
  }

  Future<List<String>> getDownloadedFileIds() async {
    return _dao.getDownloadedFileIds();
  }

  Future<void> updateSongDownloaded(String songId, bool downloaded) async {
    await _dao.updateSongDownloaded(songId, downloaded);
  }

  Future<int?> getSongDurationSeconds(String songId) {
    return _dao.getSongDurationSeconds(songId);
  }

  Future<void> createPlaylist(String name, String? folderId) async {
    final newPlaylist = PlaylistEntity(
      id: const Uuid().v4(),
      name: name,
      folderId: folderId,
    );

    await _dao.createPlaylist(newPlaylist);
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    await _dao.updatePlaylistName(playlistId, newName);
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _dao.deletePlaylist(playlistId);
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    await _dao.addSongToPlaylist(playlistId, songId);
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    await _dao.removeSongFromPlaylist(playlistId, songId);
  }

  Future<List<AvailableFile>> fetchSongFiles(String songId) {
    return _songsApi.getAvailableFiles(songId);
  }

  Future<AvailableFile?> resolveFirstAvailableFile(
    String songId, {
    required AudioQualityOption preference,
    bool persistSelection = true,
  }) async {
    final files = await _songsApi.getAvailableFiles(songId);
    if (files.isEmpty) return null;

    final file = _selectPreferredFile(files, preference);
    if (file != null && persistSelection) {
      await _dao.updateSongFile(songId, file.id, file.format, file.durationMs);
    }
    return file;
  }

  AvailableFile? _selectPreferredFile(
    List<AvailableFile> files,
    AudioQualityOption preference,
  ) {
    if (files.isEmpty) return null;

    final scored = files
        .map((file) => MapEntry(file, _effectiveBitrateKbps(file)))
        .toList();
    scored.sort((a, b) => a.value.compareTo(b.value));

    if (preference.isLossless) {
      return scored.last.key;
    }

    final target = preference.bitrateKbps;
    final below = scored.where((entry) => entry.value > 0 && entry.value <= target).toList();
    if (below.isNotEmpty) {
      return below.last.key;
    }

    final above = scored.where((entry) => entry.value > 0).toList();
    if (above.isNotEmpty) {
      return above.first.key;
    }

    return scored.last.key;
  }

  int _effectiveBitrateKbps(AvailableFile file) {
    if (file.bitrate > 0) return file.bitrate;
    if (file.durationMs <= 0 || file.size <= 0) return 0;
    final seconds = file.durationMs / 1000;
    if (seconds <= 0) return 0;
    return (file.size * 8 ~/ 1000) ~/ seconds;
  }

  Future<void> updateSongFile(
    String songId,
    String fileId,
    String format,
    int? durationMs,
  ) async {
    await _dao.updateSongFile(songId, fileId, format, durationMs);
  }

  Future<void> moveFolder(String itemId, String? folderId) async {
    await _dao.moveFolder(itemId, folderId);
  }

  Future<void> movePlaylist(String itemId, String? folderId) async {
    await _dao.movePlaylist(itemId, folderId);
  }

  Future<void> moveSong(
    String playlistId,
    String songId,
    String? prevOrderId,
    String? nextOrderId,
  ) async {
    await _dao.moveSong(playlistId, songId, prevOrderId, nextOrderId);
  }
}
