part of 'storage_cubit.dart';

@freezed
class StorageState with _$StorageState {
  const factory StorageState.initial() = _Initial;
  const factory StorageState.checking() = _Checking;
  const factory StorageState.insufficientSpace({
    required int requiredBytes,
    required int availableBytes,
    required String pendingPath,
  }) = _InsufficientSpace;
  const factory StorageState.transferring(double progress) = _Transferring;
  const factory StorageState.success() = _Success;
  const factory StorageState.error(String message) = _Error;
}
