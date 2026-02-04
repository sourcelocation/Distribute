import 'package:distributeapp/core/database/database.dart';
import 'package:distributeapp/model/playlist_folder.dart';

import '../core/database/daos/folders_dao.dart';
import 'package:uuid/uuid.dart';

class FolderRepository {
  final FoldersDao _dao;

  FolderRepository(this._dao);

  Stream<List<PlaylistFolder>> getFolders(String? parentId) {
    return _dao
        .watchByFolder(parentId)
        .map(
          (folders) => folders.map((f) => PlaylistFolder.fromDb(f)).toList(),
        );
  }

  Stream<PlaylistFolder?> watchFolder(String id) {
    return _dao
        .watchFolder(id)
        .map((f) => f == null ? null : PlaylistFolder.fromDb(f));
  }

  Future<void> createFolder(String name, String? parentFolderId) async {
    final newFolder = FolderEntity(
      id: const Uuid().v4(),
      name: name,
      parentFolderId: parentFolderId,
    );

    await _dao.createFolder(newFolder);
  }

  Future<void> renameFolder(String id, String newName) async {
    await _dao.renameFolder(id, newName);
  }

  Future<void> deleteFolder(String id) async {
    await _dao.deleteFolder(id);
  }
}
