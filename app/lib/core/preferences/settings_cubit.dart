import 'package:distributeapp/core/preferences/settings_repository.dart';
import 'package:distributeapp/core/preferences/settings_state.dart';
import 'package:distributeapp/core/preferences/download_mode.dart';
import 'package:distributeapp/core/preferences/vinyl_style.dart';
import 'package:distributeapp/core/preferences/audio_quality.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repo;

  SettingsCubit(this._repo)
    : super(
        SettingsState(
          serverURL: _repo.serverURL,
          hasAcceptedEula: _repo.hasAcceptedEula,
          onboardingCompleted: _repo.onboardingCompleted,
          discordRPCEnabled: _repo.discordRPCEnabled,
          dummySoundEnabled: _repo.dummySoundEnabled,
          debugMode: _repo.debugMode,
          preloadNextSongEnabled: _repo.preloadNextSongEnabled,
          keepVinylSpinningWhenUnfocused:
              _repo.keepVinylSpinningWhenUnfocused,
          downloadMode: DownloadModeX.fromIndex(_repo.downloadModeIndex),
          availableQualities: _repo.availableQualities,
          streamingQuality: _repo.streamingQuality,
          downloadQuality: _repo.downloadQuality,
          playerVolume: _repo.playerVolume,
          customDownloadPath: _repo.customDownloadPath,
          defaultDataPath: _repo.defaultDataPath,
          vinylStyle: _repo.vinylStyle,
        ),
      );

  Future<void> setServerURL(String url) async {
    await _repo.setServerURL(url);
    emit(state.copyWith(serverURL: url));
  }

  void setHasAcceptedEula(bool accepted) async {
    await _repo.setHasAcceptedEula(accepted);
    emit(state.copyWith(hasAcceptedEula: accepted));
  }

  void setOnboardingCompleted(bool completed) async {
    await _repo.setOnboardingCompleted(completed);
    emit(state.copyWith(onboardingCompleted: completed));
  }

  void setDiscordRPCEnabled(bool enabled) async {
    await _repo.setDiscordRPCEnabled(enabled);
    emit(state.copyWith(discordRPCEnabled: enabled));
  }

  void setDummySoundEnabled(bool enabled) async {
    await _repo.setDummySoundEnabled(enabled);
    emit(state.copyWith(dummySoundEnabled: enabled));
  }

  void setDebugMode(bool enabled) async {
    await _repo.setDebugMode(enabled);
    emit(state.copyWith(debugMode: enabled));
  }

  void setPreloadNextSongEnabled(bool enabled) async {
    await _repo.setPreloadNextSongEnabled(enabled);
    emit(state.copyWith(preloadNextSongEnabled: enabled));
  }

  void setKeepVinylSpinningWhenUnfocused(bool enabled) async {
    await _repo.setKeepVinylSpinningWhenUnfocused(enabled);
    emit(state.copyWith(keepVinylSpinningWhenUnfocused: enabled));
  }

  Future<void> setCustomDownloadPath(String? path) async {
    await _repo.setCustomDownloadPath(path);
    emit(state.copyWith(customDownloadPath: path));
  }

  Future<void> setDownloadMode(DownloadMode mode) async {
    await _repo.setDownloadModeIndex(mode.index);
    emit(state.copyWith(downloadMode: mode));
  }

  Future<void> setAvailableQualities(List<AudioQualityOption> options) async {
    final normalized = AudioQualityCatalog.normalize(options);
    await _repo.setAvailableQualities(normalized);
    final nextStreaming = AudioQualityCatalog.resolveSelection(
      current: state.streamingQuality,
      options: normalized,
    );
    final nextDownload = AudioQualityCatalog.resolveSelection(
      current: state.downloadQuality,
      options: normalized,
    );
    if (nextStreaming.id != state.streamingQuality.id) {
      await _repo.setStreamingQualityId(nextStreaming.id);
    }
    if (nextDownload.id != state.downloadQuality.id) {
      await _repo.setDownloadQualityId(nextDownload.id);
    }
    emit(
      state.copyWith(
        availableQualities: normalized,
        streamingQuality: nextStreaming,
        downloadQuality: nextDownload,
      ),
    );
  }

  Future<void> setStreamingQuality(AudioQualityOption quality) async {
    await _repo.setStreamingQualityId(quality.id);
    emit(state.copyWith(streamingQuality: quality));
  }

  Future<void> setDownloadQuality(AudioQualityOption quality) async {
    await _repo.setDownloadQualityId(quality.id);
    emit(state.copyWith(downloadQuality: quality));
  }

  void setVinylStyle(VinylStyle style) async {
    await _repo.setVinylStyle(style);
    emit(state.copyWith(vinylStyle: style));
  }

  Future<void> setPlayerVolume(double volume) async {
    await _repo.setPlayerVolume(volume);
    emit(state.copyWith(playerVolume: volume.clamp(0.0, 1.0)));
  }
}
