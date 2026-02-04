import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:distributeapp/repositories/audio/music_player_controller.dart';

class AppAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final MusicPlayerController _controller;
  StreamSubscription<ControllerState>? _stateSubscription;

  AppAudioHandler({required MusicPlayerController controller})
    : _controller = controller {
    _stateSubscription = _controller.stateStream.listen(_syncFromController);
    _syncFromController(_controller.state);
  }

  void _syncFromController(ControllerState state) {
    queue.add(state.queue);
    if (state.mediaItem != null) {
      mediaItem.add(state.mediaItem);
    }

    playbackState.add(
      PlaybackState(
        controls: state.isPlaying
            ? const [
                MediaControl.skipToPrevious,
                MediaControl.pause,
                MediaControl.stop,
                MediaControl.skipToNext,
              ]
            : const [
                MediaControl.skipToPrevious,
                MediaControl.play,
                MediaControl.stop,
                MediaControl.skipToNext,
              ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: state.processingState,
        playing: state.isPlaying,
        queueIndex: state.queueIndex >= 0 ? state.queueIndex : null,
        updatePosition: state.position,
        bufferedPosition: state.position,
      ),
    );
  }

  Future<void> close() async {
    await _stateSubscription?.cancel();
    super.stop();
  }

  @override
  Future<void> play() => _controller.play();

  @override
  Future<void> pause() => _controller.pause();

  @override
  Future<void> stop() => _controller.stop();

  @override
  Future<void> seek(Duration position) => _controller.seek(position);

  @override
  Future<void> skipToQueueItem(int index) =>
      _controller.playFromQueueIndex(index);

  @override
  Future<void> skipToNext() => _controller.playNext();

  @override
  Future<void> skipToPrevious() => _controller.playPrevious();

  @override
  Future<void> addQueueItem(MediaItem mediaItem) =>
      _controller.registerExternalQueueItem(mediaItem);
}
