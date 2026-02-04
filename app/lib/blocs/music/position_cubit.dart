import 'dart:async';
import 'package:distributeapp/repositories/audio/music_player_controller.dart';
import 'package:distributeapp/blocs/music/music_player_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PositionCubit extends Cubit<Duration> {
  final MusicPlayerController _controller;
  final MusicPlayerBloc _musicCubit;
  StreamSubscription? _musicStateSubscription;
  Timer? _timer;

  PositionCubit({
    required MusicPlayerController controller,
    required MusicPlayerBloc musicCubit,
  }) : _controller = controller,
       _musicCubit = musicCubit,
       super(Duration.zero) {
    _musicStateSubscription = _musicCubit.stream.listen((state) {
      if (state.isPlaying) {
        _startTracking();
      } else {
        _stopTracking();
      }
    });

    if (_musicCubit.state.isPlaying) {
      _startTracking();
    }
  }

  void _startTracking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      emit(_controller.currentPosition);
    });
  }

  void _stopTracking() {
    _timer?.cancel();
    emit(_controller.currentPosition);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _musicStateSubscription?.cancel();
    return super.close();
  }
}
