import 'package:dio/dio.dart';

class RequestsApi {
  final Dio client;

  RequestsApi({required this.client});

  Future<void> submitMailRequest(String message, String category) async {
    try {
      await client.post(
        '/api/mails',
        data: {'category': category, 'message': message},
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to submit request',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }
}
