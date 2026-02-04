import 'package:distributeapp/api/search_api.dart';
import 'package:distributeapp/core/database/daos/search_dao.dart';

import 'package:distributeapp/model/local_search_result.dart';
import 'package:distributeapp/model/server_search_result.dart';

class SearchRepository {
  final SearchDao _dao;
  final SearchApi _api;

  SearchRepository(this._dao, this._api);

  Stream<List<LocalSearchResult>> searchSongs(String query) {
    if (query.isEmpty) return Stream.value([]);

    return _dao.watchFuzzySearch(query);
  }

  Future<List<ServerSearchResult>> searchRemote(String query) =>
      _api.searchSongs(query);
}
