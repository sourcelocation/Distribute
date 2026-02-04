import 'package:distributeapp/api/download_api.dart';
import 'package:distributeapp/core/artwork/artwork_repository.dart';
import 'package:distributeapp/model/song.dart';
import 'package:distributeapp/repositories/playlist_repository.dart';

class SongDownloadService {
  static const double _artworkWeight = 0.1;

  final DownloadApi _downloadApi;
  final ArtworkRepository _artworkRepository;
  final PlaylistRepository _playlistRepository;

  SongDownloadService(
    this._downloadApi,
    this._artworkRepository,
    this._playlistRepository,
  );

  Future<void> downloadSongWithArtwork(
    Song song,
    void Function(double progress)? onProgress,
  ) async {
    if (song.fileId == null) {
      throw Exception('Song has no fileId');
    }

    onProgress?.call(0.0);

    await _ensureArtwork(song.albumId);
    onProgress?.call(_artworkWeight);

    await _downloadApi.downloadFile(song, (received, total) {
      if (total <= 0) return;
      final audioProgress = received / total;
      final overall = (_artworkWeight + (1 - _artworkWeight) * audioProgress)
          .clamp(0.0, 1.0);
      onProgress?.call(overall);
    });

    await _playlistRepository.updateSongDownloaded(song.id, true);
    onProgress?.call(1.0);
  }

  Future<void> deleteSongFile(Song song) async {
    await _downloadApi.deleteFile(song);
    await _playlistRepository.updateSongDownloaded(song.id, false);
  }

  Future<void> _ensureArtwork(String albumId) async {
    await _artworkRepository.getArtworkFile(albumId, ArtQuality.hq);
    await _artworkRepository.getArtworkFile(albumId, ArtQuality.lq);
  }
}
