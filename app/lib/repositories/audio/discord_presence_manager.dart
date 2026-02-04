import 'package:distributeapp/repositories/audio/music_player_controller.dart';
import 'package:distributeapp/core/artwork/artwork_repository.dart';
import 'package:distributeapp/core/preferences/settings_repository.dart';
import 'package:flutter_discord_rpc/flutter_discord_rpc.dart';

class DiscordPresenceManager {
  final ArtworkRepository artworkRepository;
  final SettingsRepository settingsRepository;

  DiscordPresenceManager({
    required this.artworkRepository,
    required this.settingsRepository,
  });

  void listenTo(Stream<ControllerState> stream) {
    stream
        .distinct((previous, next) {
          return previous.currentSong == next.currentSong &&
              previous.isPlaying == next.isPlaying &&
              (previous.position - next.position).abs().inSeconds < 1;
        })
        .listen(_updatePresence);
  }

  String? _lastSongId;
  Duration? _cachedDuration;

  void _updatePresence(ControllerState state) async {
    try {
      if (!settingsRepository.discordRPCEnabled ||
          !FlutterDiscordRPC.instance.isConnected) {
        return;
      }
    } catch (_) {
      return;
    }

    if (state.isPlaying && state.currentSong != null) {
      final song = state.currentSong!;

      // Cache duration to avoid heavy I/O and isolate spawning
      if (_lastSongId != song.id || _cachedDuration == null) {
        _lastSongId = song.id;
        _cachedDuration = await song.getDuration(settingsRepository.rootPath);
      }

      final duration = _cachedDuration;
      final position = state.position;

      final now = DateTime.now().millisecondsSinceEpoch;
      final startTimestamp = now - position.inMilliseconds;
      final endTimestamp = duration != null
          ? startTimestamp + duration.inMilliseconds
          : null;

      FlutterDiscordRPC.instance.setActivity(
        activity: RPCActivity(
          assets: RPCAssets(
            largeImage: artworkRepository.fullApiURL(
              song.albumId,
              ArtQuality.hq,
            ),
            largeText: "${song.artist} – ${song.title}",
          ),
          buttons: [
            const RPCButton(
              label: "♬ Play on DistributeApp",
              url: "https://github.com/sourcelocation/",
            ),
          ],
          details: song.title,
          activityType: ActivityType.listening,
          timestamps: RPCTimestamps(start: startTimestamp, end: endTimestamp),
        ),
      );
    } else if (!state.isPlaying) {
      FlutterDiscordRPC.instance.clearActivity();
    }
  }
}
