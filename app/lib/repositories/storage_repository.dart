import 'dart:io';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:flutter/foundation.dart';

class StorageRepository {
  Future<int> getFreeSpaceInBytes(String path) async {
    Directory target = Directory(path);
    if (!await target.exists()) {
      target = target.parent;
    }

    if (Platform.isMacOS || Platform.isLinux) {
      return _getDesktopFreeSpace(target.path);
    }

    try {
      final freeSpaceMb = await DiskSpacePlus().getFreeDiskSpaceForPath(
        target.path,
      );
      return ((freeSpaceMb ?? 0) * 1024 * 1024).toInt();
    } catch (e) {
      debugPrint("DiskSpacePlus failed: $e");
      return 0;
    }
  }

  Future<int> _getDesktopFreeSpace(String path) async {
    try {
      final result = await Process.run('df', ['-k', path]);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final lines = output.trim().split('\n');
        if (lines.length >= 2) {
          final parts = lines[1].split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            final availableBlocks = int.tryParse(parts[3]);
            if (availableBlocks != null) {
              return availableBlocks * 1024;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Failed to check disk space on desktop: $e");
    }
    return 0;
  }

  Future<int> calculateDirectorySize(Directory dir) async {
    int total = 0;
    try {
      if (await dir.exists()) {
        await for (var entity in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            total += await entity.length();
          }
        }
      }
    } catch (e) {
      debugPrint("Error calculating size: $e");
    }
    return total;
  }

  Stream<double> moveFiles({
    required String oldPath,
    required String newPath,
  }) async* {
    final oldDir = Directory(oldPath);
    final newDir = Directory(newPath);

    if (!await oldDir.exists()) {
      yield 1.0;
      return;
    }

    // Try to rename the directory atomically first.
    try {
      // Ensure the parent of the new directory exists
      await newDir.parent.create(recursive: true);

      // If newDir already exists, rename might fail or overwrite depending on OS.
      // Ideally we want to merge, but standard rename replaces.
      // If we are moving to a location that doesn't exist yet, rename is perfect.
      if (!await newDir.exists()) {
        await oldDir.rename(newPath);
        yield 1.0;
        return;
      }
    } catch (e) {
      // Fallthrough to manual copy mechanism if rename fails (e.g. cross-device)
      debugPrint("Atomic rename failed, falling back to copy: $e");
    }

    // Fallback: Copy file by file (cross-device or merge scenario)
    int totalBytes = await calculateDirectorySize(oldDir);
    int bytesTransferred = 0;

    // Ensure new directory exists
    await newDir.create(recursive: true);

    final entities = await oldDir.list(recursive: true).toList();

    for (final entity in entities) {
      if (entity is File) {
        final relativePath = entity.path.replaceFirst(oldDir.path, '');
        // Handle leading slash if present
        final cleanRelative = relativePath.startsWith('/')
            ? relativePath.substring(1)
            : relativePath;

        final newFile = File('${newDir.path}/$cleanRelative');

        await newFile.parent.create(recursive: true);

        final fileSize = await entity.length();

        try {
          // Try rename first (fast move on same FS)
          await entity.rename(newFile.path);
        } catch (e) {
          // Cross-device link or other error, fall back to copy-delete
          await entity.copy(newFile.path);
          await entity.delete();
        }

        bytesTransferred += fileSize;

        if (totalBytes > 0) {
          yield bytesTransferred / totalBytes;
        }
      }
    }

    // Cleanup old directory
    if (oldDir.path.endsWith('/Distribute') ||
        oldDir.path.contains('/Distribute/')) {
      try {
        await oldDir.delete(recursive: true);
      } catch (e) {
        debugPrint("Failed to delete old directory: $e");
      }
    } else {
      debugPrint(
        "Skipping deletion of old directory as it does not look like a Distribute folder: ${oldDir.path}",
      );
    }

    yield 1.0;
  }
}
