import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:distributeapp/model/song.dart';
import 'package:distributeapp/repositories/audio/music_player_controller.dart';

part 'music_player_bloc.freezed.dart';

@freezed
class MusicPlayerEvent with _$MusicPlayerEvent {
  const factory MusicPlayerEvent.started() = _Started;
  const factory MusicPlayerEvent.playSong(Song song) = _PlaySong;
  const factory MusicPlayerEvent.play() = _Play;
  const factory MusicPlayerEvent.pause() = _Pause;
  const factory MusicPlayerEvent.togglePlayPause() = _TogglePlayPause;
  const factory MusicPlayerEvent.stop() = _Stop;
  const factory MusicPlayerEvent.seek(Duration position) = _Seek;
}

class MusicPlayerBloc extends Bloc<MusicPlayerEvent, ControllerState> {
  final MusicPlayerController _controller;

  MusicPlayerBloc({required MusicPlayerController controller})
    : _controller = controller,
      super(controller.state) {
    on<_Started>(_onStarted);

    on<_PlaySong>(_onPlaySong);
    on<_Play>(_onPlay);
    on<_Pause>(_onPause);
    on<_TogglePlayPause>(_onTogglePlayPause);
    on<_Stop>(_onStop);
    on<_Seek>(_onSeek);

    add(const MusicPlayerEvent.started());
  }

  Future<void> _onStarted(_Started event, Emitter<ControllerState> emit) async {
    await emit.forEach<ControllerState>(
      _controller.stateStream,
      onData: (state) => state,
    );
  }

  Future<void> _onPlaySong(
    _PlaySong event,
    Emitter<ControllerState> emit,
  ) async {
    await _controller.playSong(event.song);
  }

  Future<void> _onPlay(_Play event, Emitter<ControllerState> emit) async {
    await _controller.play();
  }

  Future<void> _onPause(_Pause event, Emitter<ControllerState> emit) async {
    await _controller.pause();
  }

  Future<void> _onTogglePlayPause(
    _TogglePlayPause event,
    Emitter<ControllerState> emit,
  ) async {
    await _controller.togglePlayPause();
  }

  Future<void> _onStop(_Stop event, Emitter<ControllerState> emit) async {
    await _controller.stop();
  }

  Future<void> _onSeek(_Seek event, Emitter<ControllerState> emit) async {
    await _controller.seek(event.position);
  }
}
