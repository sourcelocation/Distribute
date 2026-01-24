import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class AudioBackend {
  AudioSession? _session;
  SoundHandle? _soundHandle;
  final bool _dummySoundEnabled;

  AudioBackend({bool dummySoundEnabled = false})
    : _dummySoundEnabled = dummySoundEnabled;

  Future<void> init() async {
    if (_dummySoundEnabled) return;

    await SoLoud.instance.init(
      sampleRate: 44100,
      bufferSize: 2048,
      channels: Channels.stereo,
    );

    _session = await AudioSession.instance;
    // await _session!.configure(
    //   const AudioSessionConfiguration(
    //     avAudioSessionCategory: AVAudioSessionCategory.ambient,
    //     avAudioSessionCategoryOptions:
    //         AVAudioSessionCategoryOptions.mixWithOthers,
    //     avAudioSessionMode: AVAudioSessionMode.defaultMode,
    //     avAudioSessionRouteSharingPolicy:
    //         AVAudioSessionRouteSharingPolicy.defaultPolicy,
    //     androidAudioAttributes: AndroidAudioAttributes(
    //       contentType: AndroidAudioContentType.music,
    //       flags: AndroidAudioFlags.none,
    //       usage: AndroidAudioUsage.media,
    //     ),
    //     androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
    //     androidWillPauseWhenDucked: true,
    //   ),
    // );
    _handleInterruptions(_session!);
  }

  Future<void> play(String localPath) async {
    if (_dummySoundEnabled) return;

    await _session!.configure(AudioSessionConfiguration.music());

    await stop(disposeSession: false);
    await _session?.setActive(true);

    try {
      final source = await SoLoud.instance.loadFile(localPath);
      _soundHandle = await SoLoud.instance.play(source);
    } catch (e) {
      debugPrint('AudioBackend Error: $e');
      rethrow;
    }
  }

  Future<void> stop({bool disposeSession = true}) async {
    if (_soundHandle != null) {
      SoLoud.instance.stop(_soundHandle!);
      SoLoud.instance.disposeAllSources();
      _soundHandle = null;
    }
    if (disposeSession) {
      await _session?.setActive(false);
    }
  }

  void pause() {
    if (_soundHandle != null) {
      SoLoud.instance.setPause(_soundHandle!, true);
    }
  }

  void resume() {
    if (_soundHandle != null) {
      SoLoud.instance.setPause(_soundHandle!, false);
    }
  }

  void seek(Duration position) {
    if (_soundHandle != null &&
        SoLoud.instance.getIsValidVoiceHandle(_soundHandle!)) {
      SoLoud.instance.seek(_soundHandle!, position);
    }
  }

  Duration getPosition() {
    if (_soundHandle == null) return Duration.zero;
    final seconds = SoLoud.instance.getPosition(_soundHandle!);
    return Duration(milliseconds: seconds.inMilliseconds);
  }

  void _handleInterruptions(AudioSession session) {
    session.becomingNoisyEventStream.listen((_) => pause());

    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            SoLoud.instance.fadeGlobalVolume(
              0.1,
              const Duration(milliseconds: 300),
            );
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            pause();
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            SoLoud.instance.fadeGlobalVolume(
              1,
              const Duration(milliseconds: 300),
            );
            break;
          case AudioInterruptionType.pause:
            resume();
            break;
          case AudioInterruptionType.unknown:
            break;
        }
      }
    });
  }
}
