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

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(playlistSongs, playlistSongs.order);

          final rows = await select(playlistSongs).get();

          final byPlaylist = <String, List<PlaylistSong>>{};
          for (final row in rows) {
            byPlaylist.putIfAbsent(row.playlistId, () => []).add(row);
          }

          for (final playlistId in byPlaylist.keys) {
            final songsInOrder = await customSelect(
              'SELECT playlist_id, song_id FROM playlist_songs WHERE playlist_id = ? ORDER BY rowid ASC',
              variables: [Variable.withString(playlistId)],
              readsFrom: {playlistSongs},
            ).get();

            int counter = 1;
            for (final row in songsInOrder) {
              final songId = row.read<String>('song_id');
              final orderKey = counter.toString().padLeft(2, '0');

              await (update(playlistSongs)..where(
                    (t) =>
                        t.playlistId.equals(playlistId) &
                        t.songId.equals(songId),
                  ))
                  .write(PlaylistSongsCompanion(order: Value(orderKey)));

              counter++;
            }
          }
        }
      },
    );
  }

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
