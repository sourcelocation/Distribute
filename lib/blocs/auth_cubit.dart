import 'dart:async';
import 'package:distributeapp/model/user.dart';
import 'package:distributeapp/core/database/database.dart';
import 'package:distributeapp/core/sync_manager.dart';
import 'package:distributeapp/repositories/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_cubit.freezed.dart';

// States
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(LoggedInUser user) = _Authenticated;
  const factory AuthState.error(String message) = _Error;
  const factory AuthState.unauthenticated() = _Unauthenticated;
}

// Cubit
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repo;
  final SyncManager _syncManager;
  final AppDatabase _db;

  AuthCubit(this._repo, this._syncManager, this._db)
    : super(const AuthState.initial());

  Future<void> login(String username, String password) async {
    emit(const AuthState.loading());
    try {
      final user = await _repo.login(username, password);
      await _syncManager.triggerSync();
      emit(AuthState.authenticated(user));
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> signup(String username, String password) async {
    emit(const AuthState.loading());
    try {
      await _repo.signup(username, password);
      await login(username, password);
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  void checkAuthStatus() {
    final user = _repo.loggedInUser;
    if (user != null) {
      emit(AuthState.authenticated(user));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> logout() async {
    await _syncManager.reset();
    await _db.clearAllData();
    await _repo.logout();
    emit(const AuthState.initial());
  }
}
