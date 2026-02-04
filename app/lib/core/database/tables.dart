import 'package:drift/drift.dart';

@DataClassName('FolderEntity')
class Folders extends Table {
  TextColumn get id => text()();
  TextColumn get parentFolderId => text().nullable().references(Folders, #id)();
  TextColumn get name => text()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PlaylistEntity')
class Playlists extends Table {
  TextColumn get id => text()();
  TextColumn get folderId => text().nullable().references(Folders, #id)();
  TextColumn get name => text()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SongEntity')
class Songs extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get albumId => text().references(Albums, #id)();
  IntColumn get durationSeconds => integer()();
  TextColumn get fileId => text().nullable()();
  TextColumn get format => text().nullable()();
  BoolColumn get isDownloaded => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AlbumEntity')
class Albums extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  DateTimeColumn get releaseDate => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ArtistEntity')
class Artists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Join table for Many-to-Many
class PlaylistSongs extends Table {
  TextColumn get playlistId => text().references(Playlists, #id)();
  TextColumn get songId => text().references(Songs, #id)();
  TextColumn get order => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {playlistId, songId};
}

class SongArtists extends Table {
  TextColumn get songId => text().references(Songs, #id)();
  TextColumn get artistId => text().references(Artists, #id)();

  @override
  Set<Column> get primaryKey => {songId, artistId};
}

// The Outbox Queue
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get action => text()();
  TextColumn get entityTable => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
}
