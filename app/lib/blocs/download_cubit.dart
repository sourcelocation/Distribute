import 'package:distributeapp/model/song.dart';
import 'package:distributeapp/repositories/download/song_download_service.dart';
import 'package:distributeapp/repositories/playlist_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'download_cubit.freezed.dart';

@freezed
sealed class DownloadStatus with _$DownloadStatus {
  const factory DownloadStatus.initial() = DownloadStatusInitial;
  const factory DownloadStatus.pending() = DownloadStatusPending;
  const factory DownloadStatus.loading({required double progress}) =
      DownloadStatusLoading;
  const factory DownloadStatus.success() = DownloadStatusSuccess;
  const factory DownloadStatus.error({required String message}) =
      DownloadStatusError;
}

@freezed
abstract class DownloadState with _$DownloadState {
  const factory DownloadState({
    @Default({}) Map<String, DownloadStatus> queue,
  }) = _DownloadState;
}

class DownloadCubit extends Cubit<DownloadState> {
  final SongDownloadService _downloadService;
  final PlaylistRepository _playlistRepository;

  final List<Song> _downloadQueue = [];

  bool _isDownloading = false;

  DownloadCubit(
    this._downloadService,
    this._playlistRepository,
  )
    : super(const DownloadState());

  void downloadSong(Song song) {
    if (song.fileId == null) {
      throw Exception("Song has no fileId");
    }
    if (_downloadQueue.any((s) => s.id == song.id) ||
        state.queue[song.id] is DownloadStatusLoading) {
      return;
    }
    _updateStatus(song.id, const DownloadStatus.pending());
    _downloadQueue.add(song);
    _processQueue();
  }

  Future<void> downloadPlaylist(List<Song> songs) async {
    for (final song in songs) {
      if (song.isDownloaded) continue;

      if (song.fileId != null) {
        downloadSong(song);
      } else {
        // Fetch available files and pick the first one
        try {
          final files = await _playlistRepository.fetchSongFiles(song.id);
          if (files.isNotEmpty) {
            final file = files.first;
            await _playlistRepository.updateSongFile(
              song.id,
              file.id,
              file.format,
            );

            final updatedSong = song.copyWith(
              fileId: file.id,
              format: file.format,
            );
            downloadSong(updatedSong);
          }
        } catch (e) {
          // Skip if we can't fetch files
          continue;
        }
      }
    }
  }

  Future<void> removeDownloadsFromPlaylist(List<Song> songs) async {
    for (final song in songs) {
      if (song.isDownloaded) {
        await deleteFile(song);
      }
    }
  }

  Future<void> _processQueue() async {
    if (_isDownloading || _downloadQueue.isEmpty) return;

    _isDownloading = true;
    final song = _downloadQueue.removeAt(0);

    try {
      await _downloadInternal(song);
    } finally {
      _isDownloading = false;
      _processQueue();
    }
  }

  Future<void> _downloadInternal(Song song) async {
    if (song.fileId == null) {
      throw Exception("Song has no fileId");
    }
    _updateStatus(song.id, const DownloadStatus.loading(progress: 0.0));

    try {
      await _downloadService.downloadSongWithArtwork(song, (progress) {
        _updateStatus(
          song.id,
          DownloadStatus.loading(progress: progress),
        );
      });
      _updateStatus(song.id, const DownloadStatus.success());
    } catch (e) {
      _updateStatus(song.id, DownloadStatus.error(message: e.toString()));
    }
  }

  void _updateStatus(String songId, DownloadStatus status) {
    emit(state.copyWith(queue: {...state.queue, songId: status}));
  }

  Future<void> deleteFile(Song song) async {
    try {
      await _downloadService.deleteSongFile(song);
      _updateStatus(song.id, const DownloadStatus.initial());
    } catch (e) {
      _updateStatus(song.id, DownloadStatus.error(message: e.toString()));
    }
  }
}
