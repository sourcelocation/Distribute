import 'dart:async';
import 'dart:convert';

import 'package:distributeapp/model/user.dart';
import 'package:distributeapp/api/auth_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final AuthAPI api;
  final SharedPreferences prefs;

  AuthRepository({required this.api, required this.prefs});

  Future<LoggedInUser> login(String username, String password) async {
    final result = await api.login(username, password);
    final loggedInUser = result.user;

    final jsonStr = jsonEncode(loggedInUser.toJson());
    await prefs.setString('logged_in_user', jsonStr);
    return loggedInUser;
  }

  Future<void> signup(String username, String password) async {
    await api.signup(username, password);
  }

  LoggedInUser? get loggedInUser {
    final jsonStr = prefs.getString('logged_in_user');
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return LoggedInUser.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  String? get rootFolderId => loggedInUser?.rootFolderId;

  bool get isLoggedIn => prefs.containsKey('logged_in_user');

  Future<void> logout() async {
    await prefs.remove('logged_in_user');
    await prefs.remove('root_folder_id');
  }
}
