import 'dart:async';
import 'package:distributeapp/model/playlist.dart';
import 'package:distributeapp/model/playlist_folder.dart';
import 'package:distributeapp/repositories/folder_repository.dart';
import 'package:distributeapp/repositories/playlist_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rxdart/rxdart.dart';

import 'package:distributeapp/repositories/auth_repository.dart';

part 'file_system_bloc.freezed.dart';

// Events
@freezed
class FileSystemEvent with _$FileSystemEvent {
  const factory FileSystemEvent.loadFolder(String? folderId) = _LoadFolder;
  const factory FileSystemEvent.createFolder(String name) = _CreateFolderReq;
  const factory FileSystemEvent.createPlaylist(String name) =
      _CreatePlaylistReq;
  const factory FileSystemEvent.renamePlaylist(String playlistId, String name) =
      _RenamePlaylistReq;
  const factory FileSystemEvent.deletePlaylist(String playlistId) =
      _DeletePlaylistReq;
  const factory FileSystemEvent.renameFolder(String folderId, String name) =
      _RenameFolderReq;
  const factory FileSystemEvent.deleteFolder(String folderId) =
      _DeleteFolderReq;
}

// States
@freezed
class FileSystemState with _$FileSystemState {
  const factory FileSystemState.loading() = _Loading;
  const factory FileSystemState.loaded({
    required List<PlaylistFolder> subFolders,
    required List<Playlist> playlists,
    required String currentFolderId,
    required String currentFolderName,
    required bool isRoot,
  }) = _Loaded;
}

class FileSystemBloc extends Bloc<FileSystemEvent, FileSystemState> {
  final FolderRepository _folderRepo;
  final PlaylistRepository _playlistRepo;
  final AuthRepository _authRepo;
  final String initialFolderId;

  FileSystemBloc({
    required FolderRepository folderRepo,
    required PlaylistRepository playlistRepo,
    required AuthRepository authRepo,
    required this.initialFolderId,
  }) : _folderRepo = folderRepo,
       _playlistRepo = playlistRepo,
       _authRepo = authRepo,
       super(const FileSystemState.loading()) {
    on<_LoadFolder>(_onLoadFolder);
    on<_CreateFolderReq>(_onCreateFolder);
    on<_CreatePlaylistReq>(_onCreatePlaylist);
    on<_RenamePlaylistReq>(_onRenamePlaylist);
    on<_DeletePlaylistReq>(_onDeletePlaylist);
    on<_RenameFolderReq>(_onRenameFolder);
    on<_DeleteFolderReq>(_onDeleteFolder);
  }

  Future<void> _onLoadFolder(
    _LoadFolder event,
    Emitter<FileSystemState> emit,
  ) async {
    emit(const FileSystemState.loading());

    // Use current root if folderId is null
    final rootId = _authRepo.rootFolderId;
    if (event.folderId == null && rootId == null) {
      emit(const FileSystemState.loading());
      return;
    }

    final targetFolderId = (event.folderId == null) ? rootId! : event.folderId!;

    final combinedStream = Rx.combineLatest2(
      _folderRepo.getAllFolders(),
      _playlistRepo.getPlaylists(targetFolderId),
      (List<PlaylistFolder> allFolders, List<Playlist> playlists) {
        final subFolders = allFolders
            .where((f) => f.parentFolderId == targetFolderId)
            .toList();

        String? currentFolderName;
        if (targetFolderId.isNotEmpty) {
          try {
            if (targetFolderId == _authRepo.rootFolderId) {
            } else {
              currentFolderName = allFolders
                  .firstWhere((f) => f.id == targetFolderId)
                  .name;
            }
          } catch (_) {}
        }

        return FileSystemState.loaded(
          subFolders: subFolders,
          playlists: playlists,
          currentFolderId: targetFolderId,
          currentFolderName:
              (currentFolderName == null &&
                  targetFolderId == _authRepo.rootFolderId)
              ? "Distribute"
              : (currentFolderName ?? "Unknown Folder"),
          isRoot: targetFolderId == _authRepo.rootFolderId,
        );
      },
    );

    await emit.forEach(
      combinedStream,
      onData: (state) => state,
      onError: (_, _) => const FileSystemState.loading(),
    );
  }

  Future<void> _onCreateFolder(
    _CreateFolderReq event,
    Emitter<FileSystemState> emit,
  ) async {
    final currentState = state;
    await currentState.maybeWhen(
      loaded:
          (
            subFolders,
            playlists,
            currentFolderId,
            currentFolderName,
            isRoot,
          ) async {
            await _folderRepo.createFolder(event.name, currentFolderId);
          },
      orElse: () async {},
    );
  }

  Future<void> _onCreatePlaylist(
    _CreatePlaylistReq event,
    Emitter<FileSystemState> emit,
  ) async {
    final currentState = state;
    await currentState.maybeWhen(
      loaded:
          (
            subFolders,
            playlists,
            currentFolderId,
            currentFolderName,
            isRoot,
          ) async {
            await _playlistRepo.createPlaylist(event.name, currentFolderId);
          },
      orElse: () async {},
    );
  }

  Future<void> _onRenamePlaylist(
    _RenamePlaylistReq event,
    Emitter<FileSystemState> emit,
  ) async {
    final currentState = state;
    await currentState.maybeWhen(
      loaded:
          (
            subFolders,
            playlists,
            currentFolderId,
            currentFolderName,
            isRoot,
          ) async {
            await _playlistRepo.renamePlaylist(event.playlistId, event.name);
          },
      orElse: () async {},
    );
  }

  Future<void> _onDeletePlaylist(
    _DeletePlaylistReq event,
    Emitter<FileSystemState> emit,
  ) async {
    final currentState = state;
    await currentState.maybeWhen(
      loaded:
          (
            subFolders,
            playlists,
            currentFolderId,
            currentFolderName,
            isRoot,
          ) async {
            await _playlistRepo.deletePlaylist(event.playlistId);
          },
      orElse: () async {},
    );
  }

  Future<void> _onRenameFolder(
    _RenameFolderReq event,
    Emitter<FileSystemState> emit,
  ) async {
    final currentState = state;
    await currentState.maybeWhen(
      loaded:
          (
            subFolders,
            playlists,
            currentFolderId,
            currentFolderName,
            isRoot,
          ) async {
            await _folderRepo.renameFolder(event.folderId, event.name);
          },
      orElse: () async {},
    );
  }

  Future<void> _onDeleteFolder(
    _DeleteFolderReq event,
    Emitter<FileSystemState> emit,
  ) async {
    final currentState = state;
    await currentState.maybeWhen(
      loaded:
          (
            subFolders,
            playlists,
            currentFolderId,
            currentFolderName,
            isRoot,
          ) async {
            await _folderRepo.deleteFolder(event.folderId);
          },
      orElse: () async {},
    );
  }
}
