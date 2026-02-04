import 'package:dio/dio.dart';
import 'package:distributeapp/model/server_search_result.dart';

class SearchApi {
  final Dio client;

  SearchApi(this.client);

  Future<List<ServerSearchResult>> searchSongs(String query) async {
    final response = await client.get(
      '/api/search',
      queryParameters: {'q': query},
    );

    final results = (response.data as List)
        .map((json) => ServerSearchResult.fromJson(json))
        .toList();
    return results;
  }
}
