import 'package:distributeapp/model/local_search_result.dart';
import 'package:distributeapp/model/server_search_result.dart';
import 'package:distributeapp/repositories/search_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rxdart/rxdart.dart';

part 'search_bloc.freezed.dart';

@freezed
sealed class SongSearchEvent with _$SongSearchEvent {
  const factory SongSearchEvent.queryChanged(String query) = _QueryChanged;
}

@freezed
abstract class SongSearchState with _$SongSearchState {
  const factory SongSearchState.initial() = _Initial;

  const factory SongSearchState.content({
    @Default([]) List<LocalSearchResult> localResults,
    @Default([]) List<ServerSearchResult> remoteResults,
    @Default(false) bool isRemoteLoading,
  }) = _Content;

  const factory SongSearchState.error(String message) = _Error;
}

class SearchBloc extends Bloc<SongSearchEvent, SongSearchState> {
  final SearchRepository _repo;

  SearchBloc({required SearchRepository repo})
    : _repo = repo,
      super(const SongSearchState.initial()) {
    on<_QueryChanged>(
      _onQueryChanged,
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 300))
          .switchMap(mapper),
    );
  }

  Future<void> _onQueryChanged(
    _QueryChanged event,
    Emitter<SongSearchState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(const SongSearchState.initial());
      return;
    }

    emit(const SongSearchState.content(isRemoteLoading: true));

    final localStream = _repo.searchSongs(event.query);

    final remoteStream = _repo
        .searchRemote(event.query)
        .asStream()
        .map((data) => data as List<ServerSearchResult>?)
        .startWith(null)
        .doOnError((e, s) => debugPrint('Remote search error: $e'))
        .onErrorReturn([]);

    await emit.forEach(
      Rx.combineLatest2(localStream, remoteStream, (
        List<LocalSearchResult> local,
        List<ServerSearchResult>? remote,
      ) {
        return SongSearchState.content(
          localResults: local,
          remoteResults: remote ?? [],
          isRemoteLoading: remote == null,
        );
      }),
      onData: (state) => state,
      onError: (error, stack) {
        debugPrint('Search error: $error');
        return SongSearchState.error(error.toString());
      },
    );
  }
}
