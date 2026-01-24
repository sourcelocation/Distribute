import 'package:dio/dio.dart';
import 'package:distributeapp/model/user.dart';

class AuthAPI {
  final Dio client;

  AuthAPI(this.client);

  Future<({LoggedInUser user, String? rootFolderId})> login(
    String username,
    String password,
  ) async {
    try {
      final response = await client.post(
        '/api/users/login',
        data: {'username': username, 'password': password},
      );

      final rootFolderId = response.data['user']['root_folder_id'] as String?;

      final user = LoggedInUser(
        username: response.data['username'] as String,
        token: response.data['token'] as String,
        id: response.data['id'] as String,
        rootFolderId: rootFolderId,
      );

      return (user: user, rootFolderId: rootFolderId);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid username or password');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<void> signup(String username, String password) async {
    try {
      await client.post(
        '/api/users/signup',
        data: {'username': username, 'password': password},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('Validation failed or invalid input');
      }
      throw Exception('Network error: ${e.message}');
    }
  }
}
