import 'dart:async';
import 'package:distributeapp/model/playlist.dart';
import 'package:distributeapp/model/playlist_folder.dart';
import 'package:distributeapp/repositories/folder_repository.dart';
import 'package:distributeapp/repositories/playlist_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rxdart/rxdart.dart';

import 'package:distributeapp/repositories/auth_repository.dart';

part 'file_system_bloc.freezed.dart';

// Events
@freezed
abstract class FileSystemEvent with _$FileSystemEvent {
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
abstract class FileSystemState with _$FileSystemState {
  const factory FileSystemState.loading() = _Loading;
  const factory FileSystemState.loaded({
    required List<PlaylistFolder> subFolders,
    required List<Playlist> playlists,
    required String currentFolderId,
    required String currentFolderName,
    required bool isRoot,
  }) = _Loaded;
  const factory FileSystemState.error(String message) = _Error;
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

    final nameStream = (targetFolderId == _authRepo.rootFolderId)
        ? Stream<String?>.value(null)
        : _folderRepo
              .watchFolder(targetFolderId)
              .map((f) => f?.name)
              .handleError((e, s) {
                debugPrint("Error watching folder name: $e");
                throw e;
              });

    final foldersStream = _folderRepo.getFolders(targetFolderId).handleError((
      e,
      s,
    ) {
      debugPrint("Error fetching folders: $e");
      throw e;
    });

    final playlistsStream = _playlistRepo
        .getPlaylists(targetFolderId)
        .handleError((e, s) {
          debugPrint("Error fetching playlists: $e");
          throw e;
        });

    final combinedStream = Rx.combineLatest3(
      foldersStream,
      playlistsStream,
      nameStream,
      (
        List<PlaylistFolder> subFolders,
        List<Playlist> playlists,
        String? folderName,
      ) {
        return FileSystemState.loaded(
          subFolders: subFolders,
          playlists: playlists,
          currentFolderId: targetFolderId,
          currentFolderName:
              (folderName == null && targetFolderId == _authRepo.rootFolderId)
              ? "Distribute"
              : (folderName ?? "Unknown Folder"),
          isRoot: targetFolderId == _authRepo.rootFolderId,
        );
      },
    );

    await emit.forEach(
      combinedStream,
      onData: (state) => state,
      onError: (error, stackTrace) {
        debugPrint("FileSystemBloc error: $error");
        return FileSystemState.error(error.toString());
      },
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
