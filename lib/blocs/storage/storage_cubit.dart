import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:distributeapp/core/preferences/settings_cubit.dart';
import 'package:distributeapp/repositories/storage_repository.dart';
import 'package:distributeapp/core/artwork/artwork_repository.dart';
import 'package:distributeapp/repositories/audio/music_player_controller.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'storage_state.dart';
part 'storage_cubit.freezed.dart';

class StorageCubit extends Cubit<StorageState> {
  final StorageRepository _storageRepository;
  final SettingsCubit _settingsCubit;
  final ArtworkRepository _artworkRepository;
  final MusicPlayerController _musicPlayerController;

  StorageCubit({
    required StorageRepository storageRepository,
    required SettingsCubit settingsCubit,
    required ArtworkRepository artworkRepository,
    required MusicPlayerController musicPlayerController,
  }) : _storageRepository = storageRepository,
       _settingsCubit = settingsCubit,
       _artworkRepository = artworkRepository,
       _musicPlayerController = musicPlayerController,
       super(const StorageState.initial());

  Future<void> requestMove(String selectedPath) async {
    String newPath = selectedPath;

    if (newPath.endsWith(Platform.pathSeparator)) {
      newPath = newPath.substring(0, newPath.length - 1);
    }

    final String paramName = newPath.split(Platform.pathSeparator).last;
    if (paramName != 'Distribute') {
      newPath = '$newPath${Platform.pathSeparator}Distribute';
    }

    emit(const StorageState.checking());

    try {
      final oldRootPath = _settingsCubit.state.rootPath;

      if (p.equals(oldRootPath, newPath)) {
        emit(
          const StorageState.error(
            "Selected location is the same as the current one.",
          ),
        );
        return;
      }

      if (p.isWithin(oldRootPath, newPath)) {
        emit(
          const StorageState.error(
            "New location cannot be a subdirectory of the current one as it would cause issues during file transfer.",
          ),
        );
        return;
      }

      final freeSpace = await _storageRepository.getFreeSpaceInBytes(newPath);

      final oldDir = Directory(oldRootPath);
      final requiredBytes = await _storageRepository.calculateDirectorySize(
        oldDir,
      );

      if (freeSpace < requiredBytes) {
        emit(
          StorageState.insufficientSpace(
            requiredBytes: requiredBytes,
            availableBytes: freeSpace,
            pendingPath: newPath,
          ),
        );
      } else {
        await _startTransfer(oldRootPath, newPath);
      }
    } catch (e) {
      emit(StorageState.error(e.toString()));
    }
  }

  Future<void> confirmMoveWithoutTransfer(String newPath) async {
    await _settingsCubit.setCustomDownloadPath(newPath);
    _artworkRepository.clearCache();
    _musicPlayerController.clearCache();
    emit(const StorageState.success());
  }

  Future<void> startTransfer(String newPath) async {
    final oldRootPath = _settingsCubit.state.rootPath;
    await _startTransfer(oldRootPath, newPath);
  }

  Future<void> _startTransfer(String oldPath, String newPath) async {
    emit(const StorageState.transferring(0.0));

    try {
      if (oldPath == newPath) {
        emit(const StorageState.success());
        return;
      }

      await for (final progress in _storageRepository.moveFiles(
        oldPath: oldPath,
        newPath: newPath,
      )) {
        emit(StorageState.transferring(progress));
      }

      await _settingsCubit.setCustomDownloadPath(newPath);
      _artworkRepository.clearCache();
      _musicPlayerController.clearCache();
      emit(const StorageState.success());
    } catch (e) {
      emit(StorageState.error(e.toString()));
    }
  }

  void reset() {
    emit(const StorageState.initial());
  }
}
