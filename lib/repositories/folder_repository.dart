import 'package:distributeapp/core/database/database.dart';
import 'package:distributeapp/core/sync_manager.dart';
import 'package:distributeapp/model/playlist_folder.dart';

import '../core/database/daos/folders_dao.dart';
import 'package:uuid/uuid.dart';

class FolderRepository {
  final FoldersDao _dao;
  final SyncManager _syncManager;

  FolderRepository(this._dao, this._syncManager);

  Stream<List<PlaylistFolder>> getAllFolders() {
    return _dao.watchAll().map(
      (folders) => folders.map((f) => PlaylistFolder.fromDb(f)).toList(),
    );
  }

  Future<void> createFolder(String name, String? parentFolderId) async {
    final newFolder = FolderEntity(
      id: const Uuid().v4(),
      name: name,
      parentFolderId: parentFolderId,
    );

    await _dao.createFolder(newFolder);
    _syncManager.triggerSync();
  }

  Future<void> renameFolder(String id, String newName) async {
    await _dao.renameFolder(id, newName);
    _syncManager.triggerSync();
  }

  Future<void> deleteFolder(String id) async {
    await _dao.deleteFolder(id);
    _syncManager.triggerSync();
  }
}
