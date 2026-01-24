import 'dart:async';
import 'package:distributeapp/core/sync_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:distributeapp/core/sync_manager.dart';

class SyncCubit extends Cubit<SyncStatus> {
  final SyncManager _syncManager;
  StreamSubscription<SyncStatus>? _subscription;
  Timer? _errorTimer;

  SyncCubit(this._syncManager)
    : super(
        _syncManager.isSyncing
            ? const SyncStatus.syncing()
            : const SyncStatus.idle(),
      ) {
    _subscription = _syncManager.statusStream.listen((status) {
      status.map(
        idle: (_) {
          _errorTimer?.cancel();
          emit(const SyncStatus.idle());
        },
        syncing: (_) {
          _errorTimer?.cancel();
          emit(const SyncStatus.syncing());
        },
        error: (s) {
          emit(SyncStatus.error(s.message));
          _errorTimer?.cancel();
          _errorTimer = Timer(const Duration(seconds: 5), () {
            state.maybeMap(
              error: (_) => emit(const SyncStatus.idle()),
              orElse: () {},
            );
          });
        },
      );
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _errorTimer?.cancel();
    return super.close();
  }
}
