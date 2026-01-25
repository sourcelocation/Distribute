import 'package:dio/dio.dart';
import 'package:distributeapp/model/user.dart';
import 'package:distributeapp/model/dto/login_response.dart';

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

      final loginResponse = LoginResponse.fromJson(response.data);
      final userData = loginResponse.user;

      final user = LoggedInUser(
        username: loginResponse.username,
        token: loginResponse.token,
        id: loginResponse.id,
        rootFolderId: userData.rootFolderId,
        isAdmin: userData.isAdmin,
      );

      return (user: user, rootFolderId: userData.rootFolderId);
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
