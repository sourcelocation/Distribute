import 'package:distributeapp/model/server_search_result.dart';
import 'package:distributeapp/model/song.dart';
import 'package:distributeapp/repositories/playlist_repository.dart';

class PlaylistHelper {
  static Future<Song?> addRemoteSongAndPrepareDownload(
    PlaylistRepository repo,
    String playlistId,
    ServerSearchResultSong song,
  ) async {
    await repo.addSongWithMetadata(playlistId, song);

    final files = await repo.fetchSongFiles(song.id);

    if (files.isEmpty) {
      return Song(
        id: song.id,
        title: song.title,
        artists: song.artists.map((a) => a.name).toList(),
        albumTitle: song.albumTitle,
        albumId: song.albumId,
        fileId: null,
        format: null,
        isDownloaded: false,
      );
    }

    final bestFile = files.first;

    await repo.updateSongFile(song.id, bestFile.id, bestFile.format);

    return Song(
      id: song.id,
      title: song.title,
      artists: song.artists.map((a) => a.name).toList(),
      albumTitle: song.albumTitle,
      albumId: song.albumId,
      fileId: bestFile.id,
      format: bestFile.format,
      isDownloaded: false,
    );
  }
}
