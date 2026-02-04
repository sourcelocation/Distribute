import 'package:dio/dio.dart';

class ServerStatusApi {
  final Dio client;

  ServerStatusApi(this.client);

  Future<Map<String, dynamic>> getServerInfo({String? baseUrl}) async {
    final path = baseUrl != null ? '$baseUrl/api/info' : '/api/info';
    final response = await client.get(
      path,
      options: Options(
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );

    return response.data as Map<String, dynamic>;
  }
}
