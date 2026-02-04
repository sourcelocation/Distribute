import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:distributeapp/model/song.dart';
import 'package:rxdart/rxdart.dart';

part 'queue_manager.freezed.dart';

enum LoopMode { off, all, one }

@freezed
sealed class QueueState with _$QueueState {
  const factory QueueState({
    required List<Song> queue,
    required int queueIndex,
    required List<Song> originalQueue,
    required bool isShuffled,
    required LoopMode loopMode,
  }) = _QueueState;

  factory QueueState.initial() => const QueueState(
    queue: [],
    queueIndex: -1,
    originalQueue: [],
    isShuffled: false,
    loopMode: LoopMode.all,
  );
}

class QueueManager {
  final BehaviorSubject<QueueState> _stateSubject = BehaviorSubject.seeded(
    QueueState.initial(),
  );

  Stream<QueueState> get stateStream => _stateSubject.stream;
  QueueState get state => _stateSubject.value;

  Song? get currentSong {
    if (state.queueIndex >= 0 && state.queueIndex < state.queue.length) {
      return state.queue[state.queueIndex];
    }
    return null;
  }

  void setQueue(List<Song> songs, {int initialIndex = 0}) {
    _emit(
      state.copyWith(
        queue: List.of(songs),
        originalQueue: List.of(songs),
        queueIndex: initialIndex,
        isShuffled: false,
      ),
    );
  }

  void addSong(Song song) {
    final newQueue = List<Song>.from(state.queue)..add(song);
    final newOriginal = List<Song>.from(state.originalQueue)..add(song);
    _emit(state.copyWith(queue: newQueue, originalQueue: newOriginal));
  }

  int? getNextIndex() {
    if (state.queue.isEmpty) return null;

    if (state.loopMode == LoopMode.one) {
      if (state.queueIndex == -1 && state.queue.isNotEmpty) return 0;
      return state.queueIndex;
    }

    final nextIndex = state.queueIndex + 1;

    if (nextIndex < state.queue.length) {
      return nextIndex;
    }

    if (state.loopMode == LoopMode.all) {
      return 0;
    }

    return null;
  }

  int? getPreviousIndex() {
    if (state.queue.isEmpty) return null;

    final prevIndex = state.queueIndex - 1;
    if (prevIndex >= 0) {
      return prevIndex;
    }

    if (state.loopMode == LoopMode.all) {
      return state.queue.length - 1;
    }

    return 0;
  }

  void setCurrentIndex(int index) {
    if (index >= -1 && index < state.queue.length) {
      _emit(state.copyWith(queueIndex: index));
    }
  }

  void setLoopMode(LoopMode mode) {
    _emit(state.copyWith(loopMode: mode));
  }

  void toggleShuffle() {
    final shouldShuffle = !state.isShuffled;
    List<Song> newQueue;
    int newIndex = state.queueIndex;

    final currentSong = this.currentSong;

    if (shouldShuffle) {
      final listToShuffle = List<Song>.from(state.originalQueue);
      if (currentSong != null) {
        listToShuffle.removeWhere((s) => s.id == currentSong.id);
      }
      listToShuffle.shuffle();

      if (currentSong != null) {
        newQueue = [currentSong, ...listToShuffle];
        newIndex = 0;
      } else {
        newQueue = listToShuffle;
        newIndex = -1;
      }
    } else {
      newQueue = List.of(state.originalQueue);
      if (currentSong != null) {
        newIndex = newQueue.indexWhere((s) => s.id == currentSong.id);
      } else {
        newIndex = -1;
      }
    }

    _emit(
      state.copyWith(
        isShuffled: shouldShuffle,
        queue: newQueue,
        queueIndex: newIndex,
      ),
    );
  }

  void clear() {
    _emit(QueueState.initial());
  }

  void _emit(QueueState newState) {
    _stateSubject.add(newState);
  }

  void dispose() {
    _stateSubject.close();
  }
}
