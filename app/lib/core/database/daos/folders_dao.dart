import 'dart:convert';
import 'package:distributeapp/core/database/database.dart';
import 'package:drift/drift.dart';
import '../tables.dart';

part 'folders_dao.g.dart';

@DriftAccessor(tables: [Folders, SyncQueue])
class FoldersDao extends DatabaseAccessor<AppDatabase> with _$FoldersDaoMixin {
  FoldersDao(super.db);

  Stream<List<FolderEntity>> watchByFolder(String? parentId) {
    return (select(folders)..where(
          (t) => parentId == null
              ? t.parentFolderId.isNull()
              : t.parentFolderId.equals(parentId),
        ))
        .watch();
  }

  Stream<FolderEntity?> watchFolder(String id) {
    return (select(folders)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<void> createFolder(FolderEntity newFolder) async {
    await transaction(() async {
      // 1. Save locally
      await into(folders).insert(newFolder);

      // 2. Log to SyncQueue
      await into(syncQueue).insert(
        SyncQueueCompanion.insert(
          action: 'CREATE',
          entityTable: 'folders',
          payload: jsonEncode(
            newFolder.toJson(),
          ), // Ensure your model has toJson
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> renameFolder(String id, String newName) async {
    await transaction(() async {
      await (update(folders)..where((t) => t.id.equals(id))).write(
        FoldersCompanion(name: Value(newName)),
      );

      await into(syncQueue).insert(
        SyncQueueCompanion.insert(
          action: 'RENAME',
          entityTable: 'folders',
          payload: jsonEncode({'id': id, 'name': newName}),
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> deleteFolder(String id) async {
    await transaction(() async {
      await (delete(folders)..where((t) => t.id.equals(id))).go();

      await into(syncQueue).insert(
        SyncQueueCompanion.insert(
          action: 'DELETE',
          entityTable: 'folders',
          payload: jsonEncode({'id': id}),
          createdAt: DateTime.now(),
        ),
      );
    });
  }
}
