import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';
import 'daos/folders_dao.dart';
import 'daos/playlists_dao.dart';
import 'daos/sync_dao.dart';
import 'daos/search_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Folders,
    Playlists,
    Songs,
    PlaylistSongs,
    SyncQueue,
    Albums,
    Artists,
    SongArtists,
  ],
  daos: [FoldersDao, PlaylistsDao, SyncDao, SearchDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<void> wipeDatabase() async {
    await close();
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    await file.delete();
    _openConnection();
  }

  Future<void> clearAllData() async {
    await batch((batch) {
      batch.deleteWhere(folders, (row) => const Constant(true));
      batch.deleteWhere(playlists, (row) => const Constant(true));
      batch.deleteWhere(songs, (row) => const Constant(true));
      batch.deleteWhere(playlistSongs, (row) => const Constant(true));
      batch.deleteWhere(syncQueue, (row) => const Constant(true));
      batch.deleteWhere(albums, (row) => const Constant(true));
      batch.deleteWhere(artists, (row) => const Constant(true));
      batch.deleteWhere(songArtists, (row) => const Constant(true));
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
