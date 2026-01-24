import 'package:distributeapp/model/server_info.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../api/status_api.dart';

part 'server_status_cubit.freezed.dart';

// State
@freezed
class ServerStatusState with _$ServerStatusState {
  const factory ServerStatusState.initial() = _Initial;
  const factory ServerStatusState.loading() = _Loading;
  const factory ServerStatusState.loaded(ServerInfo info) = _Loaded;
  const factory ServerStatusState.error(String message) = _Error;
}

// Cubit
class ServerStatusCubit extends Cubit<ServerStatusState> {
  final ServerStatusApi _api;

  ServerStatusCubit(this._api) : super(const ServerStatusState.initial());

  Future<void> loadStatus() async {
    emit(const ServerStatusState.loading());
    try {
      final data = await _api.getServerInfo();
      final info = ServerInfo.fromJson(data);
      emit(ServerStatusState.loaded(info));
    } catch (e) {
      emit(ServerStatusState.error(e.toString()));
    }
  }
}
