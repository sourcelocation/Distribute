import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class AudioBackend {
  AudioSession? _session;
  final bool _dummySoundEnabled;
  _PlaybackJob? _currentJob;
  _PlaybackJob? _preparedJob;

  final _songFinishedController = StreamController<void>.broadcast();
  Stream<void> get onSongFinished => _songFinishedController.stream;

  final _gaplessTransitionController = StreamController<String>.broadcast();
  Stream<String> get onAutomaticSongTransition =>
      _gaplessTransitionController.stream;

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
    await _session!.configure(AudioSessionConfiguration.music());
    _handleInterruptions(_session!);
  }

  Future<void> play(String localPath) async {
    if (_dummySoundEnabled) return;

    if (_preparedJob?.path == localPath && _preparedJob!.isLoaded) {
      await stop(disposeSession: false, clearPrepared: false);
      _currentJob = _preparedJob;
      _preparedJob = null;
    } else {
      await stop(disposeSession: false);
      _currentJob = _PlaybackJob(localPath, _session!, _onJobFinished);
      await _currentJob!.load();
    }

    try {
      await _currentJob!.play();
      await _session?.setActive(true);
    } catch (e) {
      debugPrint('AudioBackend Error: $e');
      rethrow;
    }
  }

  Future<void> preload(String localPath) async {
    if (_dummySoundEnabled) return;

    if (_preparedJob?.path == localPath) return;

    await _preparedJob?.stop();

    final job = _PlaybackJob(localPath, _session!, _onJobFinished);
    _preparedJob = job;

    try {
      await job.load();
    } catch (e) {
      debugPrint("Preload error: $e");
      if (_preparedJob == job) _preparedJob = null;
    }
  }

  Future<void> stop({
    bool disposeSession = true,
    bool clearPrepared = true,
  }) async {
    if (_currentJob != null) {
      await _currentJob!.stop();
      _currentJob = null;
    }

    if (clearPrepared && _preparedJob != null) {
      await _preparedJob!.stop();
      _preparedJob = null;
    }

    if (disposeSession) {
      await _session?.setActive(false);
    }
  }

  void _onJobFinished(_PlaybackJob job) {
    if (_currentJob != job) return;

    if (_preparedJob != null && _preparedJob!.isLoaded) {
      debugPrint("AudioBackend: Gapless transition to ${_preparedJob!.path}");

      final oldJob = _currentJob;
      _currentJob = _preparedJob;
      _preparedJob = null;

      _currentJob!.play().then((_) {
        _gaplessTransitionController.add(_currentJob!.path);
      });

      oldJob?.stop();
    } else {
      _songFinishedController.add(null);
    }
  }

  void pause() {
    _currentJob?.pause();
  }

  void resume() {
    _currentJob?.resume();
  }

  void seek(Duration position) {
    _currentJob?.seek(position);
  }

  Duration getPosition() {
    return _currentJob?.getPosition() ?? Duration.zero;
  }

  void dispose() {
    _songFinishedController.close();
    _gaplessTransitionController.close();
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

typedef _JobCallback = void Function(_PlaybackJob job);

class _PlaybackJob {
  final String path;
  final AudioSession session;
  final _JobCallback onFinished;

  AudioSource? _source;
  SoundHandle? _handle;
  StreamSubscription? _eventSub;

  bool _isCancelled = false;
  bool _isManualStop = false;
  bool isLoaded = false;

  _PlaybackJob(this.path, this.session, this.onFinished);

  Future<void> load() async {
    if (_isCancelled) return;

    try {
      final source = await SoLoud.instance.loadFile(path);
      if (_isCancelled) {
        SoLoud.instance.disposeSource(source);
        return;
      }
      _source = source;
      isLoaded = true;

      _eventSub = source.soundEvents.listen((event) {
        if (event.event == SoundEventType.handleIsNoMoreValid &&
            !_isManualStop &&
            _handle != null) {
          if (event.handle == _handle!) {
            onFinished(this);
          }
        }
      });
    } catch (e) {
      if (!_isCancelled) rethrow;
    }
  }

  Future<void> play() async {
    if (_isCancelled || !isLoaded || _source == null) return;
    try {
      _handle = await SoLoud.instance.play(_source!);
    } catch (e) {
      debugPrint(
        "AudioBackend: Failed to play AudioSource. It might be invalid: $e",
      );
      isLoaded = false;
      _source = null;
      rethrow;
    }
  }

  Future<void> stop() async {
    _isCancelled = true;
    _isManualStop = true;

    if (_handle != null) {
      SoLoud.instance.stop(_handle!);
      _handle = null;
    }

    if (_source != null) {
      SoLoud.instance.disposeSource(_source!);
      _source = null;
    }

    await _eventSub?.cancel();
  }

  void pause() {
    if (_handle != null) SoLoud.instance.setPause(_handle!, true);
  }

  void resume() {
    if (_handle != null) SoLoud.instance.setPause(_handle!, false);
  }

  void seek(Duration pos) {
    if (_handle != null && SoLoud.instance.getIsValidVoiceHandle(_handle!)) {
      SoLoud.instance.seek(_handle!, pos);
    }
  }

  Duration getPosition() {
    if (_handle == null) return Duration.zero;
    final s = SoLoud.instance.getPosition(_handle!);
    return Duration(milliseconds: s.inMilliseconds);
  }
}
