import 'package:distributeapp/core/database/database.dart';
import 'package:drift/drift.dart';
import '../tables.dart';

part 'sync_dao.g.dart';

@DriftAccessor(
  tables: [
    SyncQueue,
    Folders,
    Playlists,
    Songs,
    Albums,
    Artists,
    PlaylistSongs,
    SongArtists,
  ],
)
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(super.db);

  // Get items FIFO (First-In-First-Out)
  Future<List<SyncQueueData>> getPendingItems() {
    return (select(
      syncQueue,
    )..orderBy([(t) => OrderingTerm(expression: t.createdAt)])).get();
  }

  Future<void> deleteItem(int id) {
    return (delete(syncQueue)..where((t) => t.id.equals(id))).go();
  }

  Future<void> saveFolders(List<FoldersCompanion> list) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(folders, list);
    });
  }

  Future<void> savePlaylists(List<PlaylistsCompanion> list) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(playlists, list);
    });
  }

  Future<void> saveSongs(List<SongsCompanion> list) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(songs, list);
    });
  }

  Future<void> saveAlbums(List<AlbumsCompanion> list) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(albums, list);
    });
  }

  Future<void> saveArtists(List<ArtistsCompanion> list) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(artists, list);
    });
  }

  Future<void> saveSongArtists(List<SongArtistsCompanion> list) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(songArtists, list);
    });
  }

  Future<void> deleteItems(String table, List<String> ids) async {
    switch (table) {
      case 'folders':
        await (delete(folders)..where((t) => t.id.isIn(ids))).go();
        break;
      case 'playlists':
        await (delete(playlists)..where((t) => t.id.isIn(ids))).go();
        break;
      case 'songs':
        await (delete(songs)..where((t) => t.id.isIn(ids))).go();
        break;
      case 'albums':
        await (delete(albums)..where((t) => t.id.isIn(ids))).go();
        break;
      case 'artists':
        await (delete(artists)..where((t) => t.id.isIn(ids))).go();
        break;
    }
  }

  Future<void> replacePlaylistSongs(
    String playlistId,
    List<String> songIds,
  ) async {
    await transaction(() async {
      // Delete existing songs for playlist
      await (delete(
        playlistSongs,
      )..where((t) => t.playlistId.equals(playlistId))).go();
      // Insert new
      await batch((batch) {
        batch.insertAll(
          playlistSongs,
          songIds
              .map(
                (sid) => PlaylistSongsCompanion.insert(
                  playlistId: playlistId,
                  songId: sid,
                ),
              )
              .toList(),
        );
      });
    });
  }
}
