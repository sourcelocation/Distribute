import 'dart:async';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:path_provider/path_provider.dart';

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

    await _ensureSoLoudTempDir();

    await SoLoud.instance.init(
      sampleRate: 44100,
      bufferSize: 2048,
      channels: Channels.stereo,
    );

    _session = await AudioSession.instance;
    await _session!.configure(AudioSessionConfiguration.music());
    _handleInterruptions(_session!);
  }

  Future<void> _ensureSoLoudTempDir() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final soloudTemp = Directory('${tempDir.path}/SoLoudLoader-Temp-Files');
      await soloudTemp.create(recursive: true);
    } catch (e) {
      debugPrint('AudioBackend: Failed to create SoLoud temp dir: $e');
    }
  }

  Future<void> play(String source, {String? format}) async {
    if (_dummySoundEnabled) return;

    if (_preparedJob?.path == source && _preparedJob!.isLoaded) {
      await stop(disposeSession: false, clearPrepared: false);
      _currentJob = _preparedJob;
      _preparedJob = null;
    } else {
      await stop(disposeSession: false);
      _currentJob = _PlaybackJob(source, _session!, _onJobFinished, format);
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

  Future<void> preload(String source, {String? format}) async {
    if (_dummySoundEnabled) return;

    if (_preparedJob?.path == source) return;

    await _preparedJob?.stop();

    final job = _PlaybackJob(source, _session!, _onJobFinished, format);
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
  final String? format;

  AudioSource? _source;
  SoundHandle? _handle;
  StreamSubscription? _eventSub;
  StreamSubscription<List<int>>? _streamSub;
  HttpClient? _httpClient;
  bool _isStreamSource = false;

  bool _isCancelled = false;
  bool _isManualStop = false;
  bool isLoaded = false;

  _PlaybackJob(this.path, this.session, this.onFinished, this.format);

  Future<void> load() async {
    if (_isCancelled) return;

    try {
      final isRemote =
          path.startsWith('http://') || path.startsWith('https://');
      final source = isRemote
          ? await _loadRemote()
          : await SoLoud.instance.loadFile(path);
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

  bool _supportsBufferStream(String? fmt) {
    if (fmt == null) return false;
    switch (fmt.toLowerCase()) {
      case 'mp3':
      case 'ogg':
        return true;
      default:
        return false;
    }
  }

  Future<AudioSource> _loadRemote() async {
    if (_supportsBufferStream(format)) {
      _isStreamSource = true;
      final source = SoLoud.instance.setBufferStream(
        maxBufferSizeDuration: const Duration(hours: 4),
        bufferingType: BufferingType.preserved,
        bufferingTimeNeeds: 1.0,
        format: BufferType.auto,
      );
      await _startHttpStream(source);
      return source;
    }
    return SoLoud.instance.loadUrl(path);
  }

  Future<void> _startHttpStream(AudioSource source) async {
    _httpClient = HttpClient();
    final request = await _httpClient!.getUrl(Uri.parse(path));
    final response = await request.close();
    if (_isCancelled) return;
    if (response.statusCode != 200 && response.statusCode != 206) {
      throw Exception(
        'Stream request failed with status ${response.statusCode}',
      );
    }

    _streamSub = response.listen(
      (data) {
        if (_isCancelled) return;
        _streamSub?.pause();
        _pushChunk(source, Uint8List.fromList(data)).whenComplete(() {
          if (!_isCancelled) {
            _streamSub?.resume();
          }
        });
      },
      onDone: () {
        if (!_isCancelled) {
          try {
            SoLoud.instance.setDataIsEnded(source);
          } catch (_) {}
        }
      },
      onError: (_) {
        if (!_isCancelled) {
          try {
            SoLoud.instance.setDataIsEnded(source);
          } catch (_) {}
        }
      },
      cancelOnError: true,
    );
  }

  Future<void> _pushChunk(AudioSource source, Uint8List chunk) async {
    while (!_isCancelled) {
      try {
        SoLoud.instance.addAudioDataStream(source, chunk);
        return;
      } catch (e) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
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

    await _streamSub?.cancel();
    _streamSub = null;
    _httpClient?.close(force: true);
    _httpClient = null;

    if (_isStreamSource && _source != null) {
      try {
        SoLoud.instance.setDataIsEnded(_source!);
      } catch (_) {}
    }

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
