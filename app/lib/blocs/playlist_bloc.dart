import 'package:distributeapp/blocs/download_cubit.dart';
import 'package:distributeapp/core/helpers/playlist_helper.dart';
import 'package:distributeapp/model/server_search_result.dart';
import 'package:distributeapp/repositories/playlist_repository.dart';
import 'package:distributeapp/model/playlist.dart';
import 'package:distributeapp/model/song.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'playlist_bloc.freezed.dart';

// Events
@freezed
class PlaylistEvent with _$PlaylistEvent {
  const factory PlaylistEvent.load() = _Load;
  const factory PlaylistEvent.removeSong({
    required String playlistId,
    required String songId,
  }) = _RemoveSong;
  const factory PlaylistEvent.addLocalSong({
    required String playlistId,
    required String songId,
  }) = _AddLocalSong;
  const factory PlaylistEvent.addRemoteSong({
    required String playlistId,
    required String songId,
    required ServerSearchResultSong song,
  }) = _AddRemoteSong;
  const factory PlaylistEvent.rename({
    required String playlistId,
    required String name,
  }) = _Rename;
  const factory PlaylistEvent.delete({required String playlistId}) = _Delete;
  const factory PlaylistEvent.moveFolder({
    required String itemId,
    required String folderId,
  }) = _MoveFolder;
  const factory PlaylistEvent.movePlaylist({
    required String itemId,
    required String folderId,
  }) = _MovePlaylist;
  const factory PlaylistEvent.moveSong({
    required String playlistId,
    required String songId,
    required int oldIndex,
    required int newIndex,
  }) = _MoveSong;
}

// States
@freezed
class PlaylistState with _$PlaylistState {
  const factory PlaylistState.loading() = _Loading;
  const factory PlaylistState.error(String message) = _Error;
  const factory PlaylistState.loaded({
    required Playlist playlist,
    required List<Song> songs,
  }) = _Loaded;
  const factory PlaylistState.deleted() = _Deleted;
}

// Bloc
class PlaylistBloc extends Bloc<PlaylistEvent, PlaylistState> {
  final PlaylistRepository _repo;
  final DownloadCubit _downloadCubit;
  final String playlistId;

  PlaylistBloc({
    required PlaylistRepository repo,
    required DownloadCubit downloadCubit,
    required this.playlistId,
  }) : _repo = repo,
       _downloadCubit = downloadCubit,
       super(const PlaylistState.loading()) {
    on<_Load>(_onLoad);
    on<_RemoveSong>(_onRemoveSongFromPlaylist);
    on<_AddLocalSong>(_onAddLocalSongToPlaylist);
    on<_AddRemoteSong>(_onAddRemoteSongToPlaylist);
    on<_Rename>(_onRenamePlaylist);
    on<_Delete>(_onDeletePlaylist);
    on<_MoveFolder>(_onMoveFolder);
    on<_MovePlaylist>(_onMovePlaylist);
    on<_MoveSong>(_onMoveSong);
  }

  Future<void> _onLoad(_Load event, Emitter<PlaylistState> emit) async {
    final stream = Rx.combineLatest2(
      _repo.getPlaylist(playlistId),
      _repo.getSongs(playlistId),
      (Playlist playlist, List<Song> songs) {
        return PlaylistState.loaded(playlist: playlist, songs: songs);
      },
    );

    await emit.forEach(
      stream,
      onData: (state) => state,
      onError: (error, stack) => PlaylistState.error("Stream error: $error"),
    );
  }

  Future<void> _onRemoveSongFromPlaylist(
    _RemoveSong event,
    Emitter<PlaylistState> emit,
  ) async {
    try {
      await _repo.removeSongFromPlaylist(event.playlistId, event.songId);
    } catch (e) {
      emit(PlaylistState.error("Failed to remove song: $e"));
    }
  }

  Future<void> _onAddLocalSongToPlaylist(
    _AddLocalSong event,
    Emitter<PlaylistState> emit,
  ) async {
    try {
      await _repo.addSongToPlaylist(event.playlistId, event.songId);
    } catch (e) {
      emit(PlaylistState.error("Failed to add song: $e"));
    }
  }

  Future<void> _onAddRemoteSongToPlaylist(
    _AddRemoteSong event,
    Emitter<PlaylistState> emit,
  ) async {
    try {
      final song = await PlaylistHelper.addRemoteSongAndPrepareDownload(
        _repo,
        event.playlistId,
        event.song,
      );

      if (song != null && song.fileId != null) {
        _downloadCubit.downloadSong(song);
      }
    } catch (e) {
      emit(PlaylistState.error("Failed to add song: $e"));
    }
  }

  Future<void> _onRenamePlaylist(
    _Rename event,
    Emitter<PlaylistState> emit,
  ) async {
    try {
      await _repo.renamePlaylist(event.playlistId, event.name);
    } catch (e) {
      emit(PlaylistState.error("Failed to rename playlist: $e"));
    }
  }

  Future<void> _onDeletePlaylist(
    _Delete event,
    Emitter<PlaylistState> emit,
  ) async {
    try {
      await _repo.deletePlaylist(event.playlistId);
      emit(const PlaylistState.deleted());
    } catch (e) {
      emit(PlaylistState.error("Failed to delete playlist: $e"));
    }
  }

  Future<void> _onMoveFolder(
    _MoveFolder event,
    Emitter<PlaylistState> emit,
  ) async {
    try {
      await _repo.moveFolder(event.itemId, event.folderId);
    } catch (e) {
      emit(PlaylistState.error("Failed to move folder: $e"));
    }
  }

  Future<void> _onMovePlaylist(
    _MovePlaylist event,
    Emitter<PlaylistState> emit,
  ) async {
    try {
      await _repo.movePlaylist(event.itemId, event.folderId);
    } catch (e) {
      emit(PlaylistState.error("Failed to move playlist: $e"));
    }
  }

  Future<void> _onMoveSong(_MoveSong event, Emitter<PlaylistState> emit) async {
    final currentState = state;
    if (currentState is! _Loaded) return;

    var oldIndex = event.oldIndex;
    var newIndex = event.newIndex;

    // ReorderableListView increments newIndex by 1 when moving down
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    if (oldIndex == newIndex) return;

    final songs = currentState.songs;
    if (oldIndex < 0 ||
        oldIndex >= songs.length ||
        newIndex < 0 ||
        newIndex >= songs.length) {
      return;
    }

    String? prevOrderId;
    String? nextOrderId;

    var mutableSongs = List<Song>.from(songs);
    final movedSong = mutableSongs.removeAt(oldIndex);
    mutableSongs.insert(newIndex, movedSong);

    if (newIndex > 0) {
      prevOrderId = mutableSongs[newIndex - 1].order;
    }

    if (newIndex < mutableSongs.length - 1) {
      nextOrderId = mutableSongs[newIndex + 1].order;
    }

    try {
      await _repo.moveSong(
        event.playlistId,
        event.songId,
        prevOrderId,
        nextOrderId,
      );
    } catch (e) {
      emit(PlaylistState.error("Failed to move song: $e"));
    }
  }
}
