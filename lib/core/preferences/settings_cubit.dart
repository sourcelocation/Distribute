import 'package:distributeapp/core/preferences/settings_repository.dart';
import 'package:distributeapp/core/preferences/settings_state.dart';
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
        ),
      );

  void setServerURL(String url) async {
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
}
