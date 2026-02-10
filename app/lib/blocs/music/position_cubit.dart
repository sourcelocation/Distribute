import 'dart:async';
import 'package:distributeapp/repositories/audio/music_player_controller.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PositionCubit extends Cubit<Duration> {
  final MusicPlayerController _controller;
  StreamSubscription<Duration>? _positionSubscription;

  PositionCubit({
    required MusicPlayerController controller,
  })  : _controller = controller,
        super(Duration.zero) {
    _positionSubscription = _controller.positionStream.listen(emit);
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    return super.close();
  }
}
