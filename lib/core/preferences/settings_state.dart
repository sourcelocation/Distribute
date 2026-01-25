import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_state.freezed.dart';

@freezed
sealed class SettingsState with _$SettingsState {
  const SettingsState._();
  const factory SettingsState({
    required String serverURL,
    required bool hasAcceptedEula,
    required bool onboardingCompleted,
    required bool discordRPCEnabled,
    required bool dummySoundEnabled,
    required bool debugMode,
    required String? customDownloadPath,
    required String defaultDataPath,
  }) = _SettingsState;

  String get rootPath => customDownloadPath ?? defaultDataPath;
}
