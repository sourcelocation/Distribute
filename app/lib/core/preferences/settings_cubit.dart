import 'package:distributeapp/core/preferences/settings_repository.dart';
import 'package:distributeapp/core/preferences/settings_state.dart';
import 'package:distributeapp/core/preferences/vinyl_style.dart';
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

  void setVinylStyle(VinylStyle style) async {
    await _repo.setVinylStyle(style);
    emit(state.copyWith(vinylStyle: style));
  }
}
