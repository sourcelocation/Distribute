import 'package:dio/dio.dart';
import 'package:distributeapp/model/available_file.dart';

class SongsApi {
  final Dio client;

  SongsApi(this.client);

  Future<List<AvailableFile>> getAvailableFiles(String songId) async {
    final response = await client.get('/api/songs/$songId/files');

    if (response.statusCode == 200) {
      final List<dynamic> list = response.data;
      return list.map((json) => AvailableFile.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load song files');
    }
  }
}
