import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:audio_service/audio_service.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:distributeapp/model/song.dart';
import 'package:distributeapp/api/download_api.dart';
import 'package:distributeapp/core/artwork/artwork_repository.dart';
import 'package:distributeapp/core/preferences/settings_repository.dart';
import 'package:distributeapp/repositories/playlist_repository.dart';

import 'audio_backend.dart';
import 'discord_presence_manager.dart';

part 'music_player_controller.freezed.dart';

@freezed
sealed class ControllerState with _$ControllerState {
  const ControllerState._();
  const factory ControllerState({
    Song? currentSong,
    MediaItem? mediaItem,
    required List<MediaItem> queue,
    required int queueIndex,
    required Duration position,
    required bool isPlaying,
    required ArtworkData artworkData,
    required AudioProcessingState processingState,
  }) = _ControllerState;

  factory ControllerState.initial() => ControllerState(
    currentSong: null,
    mediaItem: null,
    queue: <MediaItem>[],
    queueIndex: -1,
    position: Duration.zero,
    isPlaying: false,
    artworkData: ArtworkData.empty,
    processingState: AudioProcessingState.idle,
  );

  Duration get duration => mediaItem?.duration ?? Duration.zero;
}

class MusicPlayerController {
  final ArtworkRepository artworkRepository;
  final SettingsRepository settingsRepository;
  final PlaylistRepository playlistRepository;
  final DownloadApi downloadApi;
  final String appDataPath;

  late final AudioBackend _audioBackend;
  late final DiscordPresenceManager _discordManager;

  MusicPlayerController({
    required this.artworkRepository,
    required this.settingsRepository,
    required this.playlistRepository,
    required this.downloadApi,
    required this.appDataPath,
  }) {
    _audioBackend = AudioBackend(
      dummySoundEnabled: settingsRepository.dummySoundEnabled,
    );
    _discordManager = DiscordPresenceManager(
      artworkRepository: artworkRepository,
      settingsRepository: settingsRepository,
      appDataPath: appDataPath,
    );

    _discordManager.listenTo(stateStream);
  }

  final StreamController<ControllerState> _stateController =
      StreamController<ControllerState>.broadcast();
  ControllerState _state = ControllerState.initial();
  Stream<ControllerState> get stateStream => _stateController.stream;
  ControllerState get state => _state;

  final List<_QueueEntry> _queue = [];

  Duration get currentPosition => _audioBackend.getPosition();

  Future<void> init() async {
    await _audioBackend.init();
  }

  Future<void> dispose() async {
    await stop(clearQueue: true);
    await _stateController.close();
  }

  Future<void> playSong(Song song) async {
    final isAvailable = await _isFileAvailableLocally(song);

    if (!isAvailable) {
      return;
    }

    final entry = await _buildQueueEntry(song);
    _queue.clear();
    _queue.add(entry);

    await _startEntry(entry, queueIndex: 0);
  }

  Future<void> play() async {
    if (_state.isPlaying) return;

    if (_state.currentSong != null) {
      _audioBackend.resume();
      _emitState(
        _state.copyWith(
          isPlaying: true,
          processingState: AudioProcessingState.ready,
        ),
      );
      return;
    }

    if (_state.queueIndex >= 0) {
      await playFromQueueIndex(_state.queueIndex);
    }
  }

  Future<void> pause() async {
    _audioBackend.pause();
    _emitState(_state.copyWith(isPlaying: false));
  }

  Future<void> togglePlayPause() async {
    if (_state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> stop({bool clearQueue = false}) async {
    await _audioBackend.stop();

    if (clearQueue) {
      _queue.clear();
    }

    _emitState(
      _state.copyWith(
        isPlaying: false,
        processingState: AudioProcessingState.idle,
        position: Duration.zero,
        mediaItem: clearQueue ? null : _state.mediaItem,
        currentSong: clearQueue ? null : _state.currentSong,
        queue: clearQueue ? const [] : _queueMediaItems,
        queueIndex: clearQueue ? -1 : _state.queueIndex,
      ),
    );
  }

  Future<void> seek(Duration position) async {
    _audioBackend.seek(position);
    _emitState(_state.copyWith(position: position));
  }

  Future<void> playFromQueueIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;

    final entry = await _ensureLocalPath(_queue[index]);
    _queue[index] = entry;

    await _startEntry(entry, queueIndex: index);
  }

  Future<void> appendSongToQueue(Song song) async {
    final entry = await _buildQueueEntry(song);
    _queue.add(entry);
    _emitState(_state.copyWith(queue: _queueMediaItems));
  }

  Future<void> registerExternalQueueItem(MediaItem mediaItem) async {
    _queue.add(_QueueEntry(mediaItem: mediaItem));
    _emitState(_state.copyWith(queue: _queueMediaItems));
  }

  Future<void> _startEntry(_QueueEntry entry, {required int queueIndex}) async {
    final localPath = entry.localPath ?? entry.mediaItem.extras?['localPath'];

    if (localPath == null) {
      return;
    }

    try {
      await _audioBackend.play(localPath);

      _loadArtworkForSong(entry.song);

      _emitState(
        _state.copyWith(
          currentSong: entry.song,
          mediaItem: entry.mediaItem,
          queue: _queueMediaItems,
          queueIndex: queueIndex,
          position: Duration.zero,
          isPlaying: true,
          processingState: AudioProcessingState.ready,
        ),
      );
    } catch (e) {
      _emitState(_state.copyWith(processingState: AudioProcessingState.error));
    }
  }

  Future<void> _loadArtworkForSong(Song? song) async {
    if (song == null) return;
    try {
      final artworkData = await artworkRepository.getArtworkData(
        song.albumId,
        ArtQuality.hq,
      );
      _emitState(_state.copyWith(artworkData: artworkData));
    } catch (e) {
      _emitState(_state.copyWith(artworkData: ArtworkData.empty));
    }
  }

  Future<bool> _isFileAvailableLocally(Song song) async {
    final localPath = song.localPath(appDataPath);
    return await File(localPath).exists();
  }

  Future<_QueueEntry> _buildQueueEntry(Song song) async {
    final localPath = song.localPath(appDataPath);
    final mediaItem = await _buildMediaItem(song, localPath);
    return _QueueEntry(song: song, localPath: localPath, mediaItem: mediaItem);
  }

  Future<_QueueEntry> _ensureLocalPath(_QueueEntry entry) async {
    if (entry.localPath != null) return entry;
    if (entry.song == null) return entry;
    final path = entry.song!.localPath(appDataPath);
    return entry.copyWith(localPath: path);
  }

  Future<MediaItem> _buildMediaItem(Song song, String localPath) async {
    Uri? artUri;
    try {
      final artworkFile = await artworkRepository.getArtworkFile(
        song.albumId,
        ArtQuality.hq,
      );
      artUri = Uri.file(artworkFile.path);
    } catch (e) {
      artUri = await _getArtUriFromAsset('assets/default-playlist-hq.png');
    }

    return MediaItem(
      id: song.id.toString(),
      album: song.albumTitle,
      title: song.title,
      artist: song.artist,
      duration: Duration(
        milliseconds:
            (await song.getDuration(appDataPath))?.inMilliseconds ?? 0,
      ),
      artUri: artUri,
      extras: <String, dynamic>{
        'songId': song.id,
        'fileId': song.fileId,
        'localPath': localPath,
      },
    );
  }

  Future<Uri> _getArtUriFromAsset(String assetPath) async {
    final file = File('$appDataPath/$assetPath');
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    if (!await file.exists()) {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      await file.writeAsBytes(bytes);
    }
    return Uri.file(file.path);
  }

  List<MediaItem> get _queueMediaItems =>
      List<MediaItem>.unmodifiable(_queue.map((e) => e.mediaItem));

  void _emitState(ControllerState next) {
    _state = next;
    _stateController.add(_state);
  }
}

class _QueueEntry {
  final Song? song;
  final String? localPath;
  final MediaItem mediaItem;

  const _QueueEntry({required this.mediaItem, this.song, this.localPath});

  _QueueEntry copyWith({Song? song, String? localPath, MediaItem? mediaItem}) {
    return _QueueEntry(
      song: song ?? this.song,
      localPath: localPath ?? this.localPath,
      mediaItem: mediaItem ?? this.mediaItem,
    );
  }
}
