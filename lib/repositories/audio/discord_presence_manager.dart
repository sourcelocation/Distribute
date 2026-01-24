import 'package:distributeapp/repositories/audio/music_player_controller.dart';
import 'package:distributeapp/core/artwork/artwork_repository.dart';
import 'package:distributeapp/core/preferences/settings_repository.dart';
import 'package:flutter_discord_rpc/flutter_discord_rpc.dart';

class DiscordPresenceManager {
  final ArtworkRepository artworkRepository;
  final SettingsRepository settingsRepository;
  final String appDataPath;

  DiscordPresenceManager({
    required this.artworkRepository,
    required this.settingsRepository,
    required this.appDataPath,
  });

  void listenTo(Stream<ControllerState> stream) {
    stream.listen(_updatePresence);
  }

  void _updatePresence(ControllerState state) async {
    if (!settingsRepository.discordRPCEnabled ||
        !FlutterDiscordRPC.instance.isConnected) {
      return;
    }

    if (state.isPlaying && state.currentSong != null) {
      final song = state.currentSong!;
      final duration = await song.getDuration(appDataPath);

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
          timestamps: RPCTimestamps(
            start: DateTime.now().millisecondsSinceEpoch,
            end: duration != null
                ? (DateTime.now().millisecondsSinceEpoch +
                          duration.inMilliseconds)
                      .toInt()
                : null,
          ),
        ),
      );
    } else if (!state.isPlaying) {
      FlutterDiscordRPC.instance.clearActivity();
    }
  }
}
