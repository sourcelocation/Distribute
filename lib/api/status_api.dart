import 'package:dio/dio.dart';

class ServerStatusApi {
  final Dio client;

  ServerStatusApi(this.client);

  Future<Map<String, dynamic>> getServerInfo() async {
    try {
      final response = await client.get('/api/info');

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}
