import 'package:distributeapp/api/requests_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'requests_cubit.freezed.dart';

@freezed
class RequestsState with _$RequestsState {
  const factory RequestsState.initial() = _Initial;
  const factory RequestsState.submitting() = _Submitting;
  const factory RequestsState.success() = _Success;
  const factory RequestsState.failure(String error) = _Failure;
}

class RequestsCubit extends Cubit<RequestsState> {
  final RequestsApi _api;
  RequestsCubit(this._api) : super(const RequestsState.initial());

  Future<void> submitRequest(String message, String category) async {
    emit(const RequestsState.submitting());
    try {
      await _api.submitMailRequest(message, category);
      emit(const RequestsState.success());
    } catch (e) {
      emit(RequestsState.failure(e.toString()));
    }
  }
}
