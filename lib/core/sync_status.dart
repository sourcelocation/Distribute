import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_status.freezed.dart';

@freezed
class SyncStatus with _$SyncStatus {
  const factory SyncStatus.idle() = _Idle;
  const factory SyncStatus.syncing() = _Syncing;
  const factory SyncStatus.error(String message) = _Error;
}
