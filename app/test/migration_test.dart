import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:distributeapp/core/database/database.dart';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as p;

void main() {
  test('migration from v1 to v2 adds order column', () async {
    final tempDir = await Directory.systemTemp.createTemp();
    final dbFile = File(p.join(tempDir.path, 'test_migration.db'));

    final rawDb = sqlite3.open(dbFile.path);

    rawDb.execute('''
      CREATE TABLE playlist_songs (
        playlist_id TEXT NOT NULL,
        song_id TEXT NOT NULL,
        PRIMARY KEY (playlist_id, song_id)
      );
    ''');

    rawDb.execute('''
      INSERT INTO playlist_songs (playlist_id, song_id) VALUES ('p1', 's1');
    ''');
    rawDb.execute('''
      INSERT INTO playlist_songs (playlist_id, song_id) VALUES ('p1', 's2');
    ''');

    rawDb.userVersion = 1;
    rawDb.dispose();

    final database = AppDatabase.forTesting(NativeDatabase(dbFile));

    final songs = await database.playlistSongs.select().get();

    expect(songs.length, 2);

    final s1 = songs.firstWhere((s) => s.songId == 's1');
    final s2 = songs.firstWhere((s) => s.songId == 's2');

    expect(s1.order, isNotEmpty);
    expect(s2.order, isNotEmpty);

    expect(s1.order.compareTo(s2.order) < 0, isTrue);
    debugPrint('s1 order: ${s1.order}, s2 order: ${s2.order}');

    await database.close();
    await tempDir.delete(recursive: true);
  });
}
