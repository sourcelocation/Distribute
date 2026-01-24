import 'package:distributeapp/core/database/database.dart';
import 'package:distributeapp/model/local_search_result.dart';
import 'package:drift/drift.dart';
import 'package:fuzzy/fuzzy.dart';
import '../tables.dart';

part 'search_dao.g.dart';

class SongSearchIndex {
  final String id;
  final String title;
  final String artistName;
  final String albumTitle;

  SongSearchIndex(this.id, this.title, this.artistName, this.albumTitle);
}

@DriftAccessor(tables: [Songs, Albums, Artists, SongArtists])
class SearchDao extends DatabaseAccessor<AppDatabase> with _$SearchDaoMixin {
  SearchDao(super.db);

  // In-memory cache
  List<SongSearchIndex> _searchCache = [];
  Fuzzy<SongSearchIndex>? _fuse;

  Future<void> loadIndex() async {
    final query = select(songs).join([
      leftOuterJoin(albums, albums.id.equalsExp(songs.albumId)),
      leftOuterJoin(songArtists, songArtists.songId.equalsExp(songs.id)),
      leftOuterJoin(artists, artists.id.equalsExp(songArtists.artistId)),
    ]);

    final rows = await query.get();

    final songMap = <String, SongSearchIndex>{};
    final artistNames = <String, Set<String>>{};

    for (final row in rows) {
      final s = row.readTable(songs);
      final al = row.readTableOrNull(albums);
      final a = row.readTableOrNull(artists);

      if (!songMap.containsKey(s.id)) {
        songMap[s.id] = SongSearchIndex(
          s.id,
          s.title,
          '', // Placeholder
          al?.title ?? '',
        );
      }

      if (a != null) {
        artistNames.putIfAbsent(s.id, () => {}).add(a.name);
      }
    }

    _searchCache = songMap.values.map((item) {
      final names = artistNames[item.id]?.join(', ') ?? 'Unknown Artist';
      return SongSearchIndex(item.id, item.title, names, item.albumTitle);
    }).toList();

    _fuse = Fuzzy(
      _searchCache,
      options: FuzzyOptions(
        keys: [
          WeightedKey(name: 'title', getter: (x) => x.title, weight: 1.0),
          WeightedKey(name: 'artist', getter: (x) => x.artistName, weight: 0.8),
          WeightedKey(name: 'album', getter: (x) => x.albumTitle, weight: 0.4),
        ],
        threshold: 0.4,
        shouldNormalize: true,
        tokenize: true,
        minTokenCharLength: 2,
      ),
    );
  }

  Stream<List<LocalSearchResult>> watchFuzzySearch(String query) {
    if (_fuse == null || query.isEmpty) {
      return Stream.value([]);
    }
    final searchResults = _fuse!.search(query);
    final ids = searchResults.map((r) => r.item.id).toList();

    if (ids.isEmpty) return Stream.value([]);
    final q = select(songs).join([
      leftOuterJoin(albums, albums.id.equalsExp(songs.albumId)),
      leftOuterJoin(songArtists, songArtists.songId.equalsExp(songs.id)),
      leftOuterJoin(artists, artists.id.equalsExp(songArtists.artistId)),
    ]);

    q.where(songs.id.isIn(ids));

    return q.watch().map((rows) {
      final resultList = <LocalSearchResult>[];

      // Preserve order from fuzzy search
      // First, group data
      final rowMap = <String, List<TypedResult>>{};

      for (final row in rows) {
        final id = row.readTable(songs).id;
        rowMap.putIfAbsent(id, () => []).add(row);
      }

      for (final id in ids) {
        if (!rowMap.containsKey(id)) continue;

        final songRows = rowMap[id]!;
        if (songRows.isEmpty) continue;

        final firstRow = songRows.first;
        final songRow = firstRow.readTable(songs);
        final albumRow = firstRow.readTableOrNull(albums);

        final names = <String>{};
        String artistId = ''; // just pick one for ID if needed, or join

        for (final r in songRows) {
          final a = r.readTableOrNull(artists);
          if (a != null) {
            names.add(a.name);
            if (artistId.isEmpty) artistId = a.id;
          }
        }

        final searchSong = SearchSong(
          id: songRow.id,
          createdAt: '',
          updatedAt: '',
          albumId: songRow.albumId,
          title: songRow.title,
        );

        final searchAlbum = SearchAlbum(
          id: albumRow?.id ?? '',
          createdAt: '',
          updatedAt: '',
          title: albumRow?.title ?? 'Unknown Album',
          releaseDate: albumRow?.releaseDate.toIso8601String() ?? '',
          // artistId removed
        );

        final searchArtist = SearchArtist(
          id: artistId,
          createdAt: '',
          updatedAt: '',
          name: names.isEmpty ? 'Unknown Artist' : names.join(', '),
        );

        resultList.add(
          LocalSearchResult(
            song: searchSong,
            album: searchAlbum,
            artist: searchArtist,
          ),
        );
      }

      return resultList;
    });
  }
}
