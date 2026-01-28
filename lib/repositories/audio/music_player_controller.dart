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
import 'queue_manager.dart';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';

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
    required bool isShuffled,
    required LoopMode loopMode,
    required ArtworkData artworkData,
    required ArtworkData? nextArtworkData,
    required ArtworkData? previousArtworkData,
    required AudioProcessingState processingState,
  }) = _ControllerState;

  factory ControllerState.initial() => ControllerState(
    currentSong: null,
    mediaItem: null,
    queue: <MediaItem>[],
    queueIndex: -1,
    position: Duration.zero,
    isPlaying: false,
    isShuffled: false,
    loopMode: LoopMode.all,
    artworkData: ArtworkData.empty,
    nextArtworkData: null,
    previousArtworkData: null,
    processingState: AudioProcessingState.idle,
  );

  Duration get duration => mediaItem?.duration ?? Duration.zero;
}

class MusicPlayerController {
  final ArtworkRepository artworkRepository;
  final SettingsRepository settingsRepository;
  final PlaylistRepository playlistRepository;
  final DownloadApi downloadApi;

  late final AudioBackend _audioBackend;
  late final QueueManager _queueManager;
  late final DiscordPresenceManager _discordManager;

  String get rootPath => settingsRepository.rootPath;

  Future<bool> isSongAvailable(Song song) async {
    final localPath = song.localPath(rootPath);
    return await File(localPath).exists();
  }

  List<Song>? _lastProcessedQueue;
  final Map<String, MediaItem> _mediaItemCache = {};

  final StreamController<ControllerState> _stateController =
      StreamController<ControllerState>.broadcast();
  ControllerState _state = ControllerState.initial();
  Stream<ControllerState> get stateStream => _stateController.stream;
  ControllerState get state => _state;

  Duration get currentPosition => _audioBackend.getPosition();

  StreamSubscription? _queueSubscription;
  StreamSubscription? _audioSubscription;
  StreamSubscription? _gaplessSubscription;

  MusicPlayerController({
    required this.artworkRepository,
    required this.settingsRepository,
    required this.playlistRepository,
    required this.downloadApi,
  }) {
    _audioBackend = AudioBackend(
      dummySoundEnabled: settingsRepository.dummySoundEnabled,
    );
    _queueManager = QueueManager();
    _discordManager = DiscordPresenceManager(
      artworkRepository: artworkRepository,
      settingsRepository: settingsRepository,
    );

    _discordManager.listenTo(stateStream);
  }

  Future<void> init() async {
    await _audioBackend.init();

    // Use switchMap to cancel previous pending play requests if queue changes rapidly
    _queueSubscription = _queueManager.stateStream
        .switchMap((qState) => Stream.fromFuture(_onQueueStateChanged(qState)))
        .listen((_) {});

    _audioSubscription = _audioBackend.onSongFinished.listen(_onSongFinished);
    _gaplessSubscription = _audioBackend.onAutomaticSongTransition.listen(
      _onAutomaticSongTransition,
    );
  }

  Future<void> dispose() async {
    await _queueSubscription?.cancel();
    await _audioSubscription?.cancel();
    await _gaplessSubscription?.cancel();

    await stop(clearQueue: true);

    _queueManager.dispose();
    await _stateController.close();
    _audioBackend.dispose();
  }

  // --- Playback Actions ---

  Future<void> playSong(Song song) async {
    final isAvailable = await isSongAvailable(song);
    if (!isAvailable) return;

    // Setting queue sets index=0
    _queueManager.setQueue([song]);
    // _onQueueStateChanged will trigger playback
  }

  Future<void> playSongFromPlaylist(List<Song> songs, int initialIndex) async {
    _queueManager.setQueue(songs, initialIndex: initialIndex);
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
    } else {
      // Nothing playing, try playing current queue item
      if (_queueManager.currentSong != null) {
        await _playEntry(_queueManager.currentSong!);
      }
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
      _queueManager.clear();
      _mediaItemCache.clear();
      _lastProcessedQueue = null;
    }

    _emitState(
      _state.copyWith(
        isPlaying: false,
        processingState: AudioProcessingState.idle,
        position: Duration.zero,
        mediaItem: clearQueue ? null : _state.mediaItem,
        currentSong: clearQueue ? null : _state.currentSong,
        // Queue state syncs from Manager automatically, but we force sync if clearing
      ),
    );
  }

  void clearCache() {
    _mediaItemCache.clear();
    _lastProcessedQueue = null;
  }

  Future<void> seek(Duration position) async {
    _audioBackend.seek(position);
    _emitState(_state.copyWith(position: position));
  }

  // --- Queue Actions ---

  Future<void> playFromQueueIndex(int index) async {
    _queueManager.setCurrentIndex(index);
  }

  Future<void> playNext() async {
    final next = _queueManager.getNextIndex();
    if (next != null) {
      _queueManager.setCurrentIndex(next);
    } else {
      await stop();
    }
  }

  Future<void> playPrevious() async {
    final prev = _queueManager.getPreviousIndex();
    if (prev != null) {
      _queueManager.setCurrentIndex(prev);
    } else {
      seek(Duration.zero);
    }
  }

  Future<void> appendSongToQueue(Song song) async {
    _queueManager.addSong(song);
  }

  Future<void> registerExternalQueueItem(MediaItem mediaItem) async {
    // TODO: implement, maybe, idk if it's needed
  }

  void setLoopMode(LoopMode mode) {
    _queueManager.setLoopMode(mode);
  }

  void toggleShuffle() {
    _queueManager.toggleShuffle();
  }

  // --- Internals ---

  Future<void> _onQueueStateChanged(QueueState qState) async {
    final newSong = _queueManager.currentSong;
    final songs = qState.queue;

    if (newSong?.id != _state.currentSong?.id) {
      if (newSong != null) {
        if (_isGaplessTransition) {
          _isGaplessTransition = false;

          ArtworkData artworkData = ArtworkData.empty;
          try {
            artworkData = await artworkRepository.getArtworkData(
              newSong.albumId,
              ArtQuality.hq,
            );
          } catch (_) {}

          final localPath = newSong.localPath(rootPath);
          final mediaItem = await _createMediaItem(
            newSong,
            localPath: localPath,
            loadArtwork: true,
          );

          _emitState(
            _state.copyWith(
              currentSong: newSong,
              mediaItem: mediaItem,
              position: Duration.zero,
              isPlaying: true, // Backend is playing
              processingState: AudioProcessingState.ready,
              artworkData: artworkData,
            ),
          );
        } else {
          await _playEntry(newSong);
        }
      } else {
        // ensure stopped?
      }
    }

    // Update queue representation
    // Optimization: Only map if list changed.
    List<MediaItem> mediaItems;
    if (_lastProcessedQueue != null &&
        const ListEquality().equals(songs, _lastProcessedQueue)) {
      mediaItems = _state.queue;
    } else {
      mediaItems = await Future.wait(
        songs.map((s) => _createMediaItem(s, loadArtwork: false)),
      );
      _lastProcessedQueue = List.of(songs);
    }

    _emitState(
      _state.copyWith(
        queue: mediaItems,
        queueIndex: qState.queueIndex,
        loopMode: qState.loopMode,
        isShuffled: qState.isShuffled,
        // Play status manages itself via play/pause/stop/loading
      ),
    );

    // Preload neighbors after queue state settles
    if (_state.isPlaying) {
      _preloadNeighbors();
    }
  }

  bool _isGaplessTransition = false;

  Future<void> _onAutomaticSongTransition(String path) async {
    final nextIndex = _queueManager.getNextIndex();
    if (nextIndex == null) return;

    // Set flag so _onQueueStateChanged knows not to re-play
    _isGaplessTransition = true;
    _queueManager.setCurrentIndex(nextIndex);
  }

  Future<void> _onSongFinished(_) async {
    final next = _queueManager.getNextIndex();
    if (next != null) {
      _queueManager.setCurrentIndex(next);
    } else {
      await stop(clearQueue: false);
    }
  }

  Future<void> _playEntry(Song song) async {
    final isAvailable = await isSongAvailable(song);
    if (!isAvailable) {
      _emitState(_state.copyWith(processingState: AudioProcessingState.error));
      return;
    }

    final localPath = song.localPath(rootPath);

    // 2. Emit loading state immediately to update UI
    // We construct a basic media item first to update UI instantly.
    final basicMediaItem = await _createMediaItem(song, loadArtwork: false);

    _emitState(
      _state.copyWith(
        currentSong: song,
        mediaItem: basicMediaItem,
        position: Duration.zero,
        isPlaying: false,
        processingState: AudioProcessingState.loading,
      ),
    );

    try {
      await _audioBackend.play(localPath);

      _loadArtworkForSong(song);

      final mediaItem = await _createMediaItem(
        song,
        localPath: localPath,
        loadArtwork: true,
      );

      // Check for staleness: If queue manager has moved on, don't emit 'playing' for this old song.
      if (_queueManager.currentSong?.id != song.id) {
        return;
      }

      _emitState(
        _state.copyWith(
          currentSong: song,
          mediaItem: mediaItem,
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

      if (_state.currentSong?.id != song.id) return;

      _emitState(_state.copyWith(artworkData: artworkData));
    } catch (e) {
      if (_state.currentSong?.id != song.id) return;
      _emitState(_state.copyWith(artworkData: ArtworkData.empty));
    }
  }

  Future<void> _preloadNeighbors() async {
    await Future.wait([
      _preloadNeighborItem(isNext: true),
      _preloadNeighborItem(isNext: false),
    ]);
  }

  Future<void> _preloadNeighborItem({required bool isNext}) async {
    final index = isNext
        ? _queueManager.getNextIndex()
        : _queueManager.getPreviousIndex();

    if (index != null) {
      final song = _queueManager.state.queue[index];

      if (await isSongAvailable(song) &&
          isNext &&
          settingsRepository.preloadNextSongEnabled) {
        await _audioBackend.preload(song.localPath(rootPath));
      }

      try {
        final artwork = await artworkRepository.getArtworkData(
          song.albumId,
          ArtQuality.hq,
        );

        final currentIndex = isNext
            ? _queueManager.getNextIndex()
            : _queueManager.getPreviousIndex();

        if (currentIndex == index) {
          if (isNext) {
            _emitState(_state.copyWith(nextArtworkData: artwork));
          } else {
            _emitState(_state.copyWith(previousArtworkData: artwork));
          }
        }
      } catch (e) {
        // Ignore artwork errors
      }
    } else {
      if (isNext) {
        _emitState(_state.copyWith(nextArtworkData: null));
      } else {
        _emitState(_state.copyWith(previousArtworkData: null));
      }
    }
  }

  Future<MediaItem> _createMediaItem(
    Song song, {
    String? localPath,
    bool loadArtwork = false,
  }) async {
    if (!loadArtwork && _mediaItemCache.containsKey(song.id)) {
      return _mediaItemCache[song.id]!;
    }

    Uri? artUri;
    Duration duration = Duration.zero;

    if (loadArtwork) {
      // Reuse from current state if same album, else fetch
      final cached = _state.artworkData;
      if (cached.artUri != null &&
          _state.currentSong?.albumId == song.albumId) {
        artUri = cached.artUri;
      } else {
        try {
          final artworkData = await artworkRepository.getArtworkData(
            song.albumId,
            ArtQuality.hq,
          );
          artUri = artworkData.artUri;
        } catch (e) {
          artUri = await _getArtUriFromAsset(
            'assets/menu/default-playlist-hq.png',
          );
        }
      }
      duration = Duration(
        milliseconds: (await song.getDuration(rootPath))?.inMilliseconds ?? 0,
      );
    }

    // Resolve path if not provided but needed
    final resolvedPath = localPath ?? song.localPath(rootPath);

    final item = MediaItem(
      id: song.id.toString(),
      album: song.albumTitle,
      title: song.title,
      artist: song.artist,
      duration: duration,
      artUri: artUri,
      extras: <String, dynamic>{
        'songId': song.id,
        'fileId': song.fileId,
        'isDownloaded': song.isDownloaded,
        'localPath': resolvedPath,
      },
    );

    // Update cache
    _mediaItemCache[song.id] = item;

    return item;
  }

  Future<Uri> _getArtUriFromAsset(String assetPath) async {
    final file = File('$rootPath/$assetPath');
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

  void _emitState(ControllerState next) {
    _state = next;
    _stateController.add(_state);
  }
}
