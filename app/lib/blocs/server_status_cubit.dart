import 'package:distributeapp/model/server_info.dart';
import 'package:distributeapp/main.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../api/status_api.dart';
import '../core/utils/server_url_utils.dart';

part 'server_status_cubit.freezed.dart';

// State
@freezed
class ServerStatusState with _$ServerStatusState {
  const factory ServerStatusState.initial() = _Initial;
  const factory ServerStatusState.loading() = _Loading;
  const factory ServerStatusState.loaded(
    ServerInfo info, {
    String? validationMessage,
  }) = _Loaded;
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

      String? validationMessage;
      // Check version compatibility
      // Server version format example: "s0.2.4" or "0.2.4"
      // Client version format example: "0.2.4"
      final serverVer = info.version.replaceAll(RegExp(r'^[a-zA-Z]'), '');
      final clientVer = version; // global from main.dart

      if (serverVer.isNotEmpty && clientVer.isNotEmpty) {
        final serverParts = serverVer.split('.');
        final clientParts = clientVer.split('.');

        if (serverParts.length >= 2 && clientParts.length >= 2) {
          final serverMajor = int.parse(serverParts[0]);
          final serverMinor = int.parse(serverParts[1]);
          final clientMajor = int.parse(clientParts[0]);
          final clientMinor = int.parse(clientParts[1]);

          if (serverMajor > clientMajor ||
              (serverMajor >= clientMajor && serverMinor > clientMinor)) {
            validationMessage =
                "You are using an outdated client version. Please update to v$version.";
          } else if (serverMajor < clientMajor ||
              (serverMajor <= clientMajor && serverMinor < clientMinor)) {
            validationMessage =
                "The server is out of date. Please update to at least s$version.";
          }
        }
      }

      emit(
        ServerStatusState.loaded(info, validationMessage: validationMessage),
      );
    } catch (e) {
      emit(ServerStatusState.error(_mapErrorToMessage(e)));
    }
  }

  Future<ConnectionResult> discoverConnection(String rawUrl) async {
    final normalized = ServerUrlUtils.normalizeUrl(rawUrl);

    // 1. Try normalized URL (usually HTTPS)
    try {
      await _api.getServerInfo(baseUrl: normalized);
      return ConnectionResult.success(normalized);
    } catch (_) {
      // 2. If HTTPS, try HTTP fallback
      if (normalized.startsWith('https://')) {
        final httpUrl = normalized.replaceFirst('https://', 'http://');
        try {
          await _api.getServerInfo(baseUrl: httpUrl);
          return ConnectionResult.httpFallback(httpUrl);
        } catch (_) {}
      }
    }
    return const ConnectionResult.failure();
  }

  String _mapErrorToMessage(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return "Connection timed out. Check your network.";
        case DioExceptionType.badResponse:
          return "Server returned an error (404/500). Check the URL.";
        case DioExceptionType.connectionError:
          if (error.message?.contains('SocketException') == true) {
            if (error.message?.contains('host lookup') == true) {
              return "Could not find server. Check the URL.";
            }
            if (error.message?.contains('Connection refused') == true) {
              return "Connection refused. Ensure the server is running.";
            }
          }
          return "Connection error. Check the URL and server status.";
        case DioExceptionType.badCertificate:
          return "SSL/TLS Error. Server might use an invalid certificate.";
        default:
          return "Network error: ${error.message}";
      }
    }
    return "An unexpected error occurred: $error";
  }
}

@freezed
class ConnectionResult with _$ConnectionResult {
  const factory ConnectionResult.success(String url) = _Success;
  const factory ConnectionResult.httpFallback(String url) = _HttpFallback;
  const factory ConnectionResult.failure() = _Failure;
}
