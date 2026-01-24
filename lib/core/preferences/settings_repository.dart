import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  static const _kServerURL = 'server_url';
  static const _kHasAcceptedEula = 'has_accepted_eula';
  static const _kDiscordRPCEnabled = 'discord_rpc_enabled';
  static const _kDummySoundEnabled = 'dummy_sound_enabled';
  static const _kDebugMode = 'debug_mode';
  static const _kOnboardingCompleted = 'onboarding_completed';

  String get serverURL {
    return _prefs.getString(_kServerURL) ?? '';
  }

  bool get hasAcceptedEula {
    return _prefs.getBool(_kHasAcceptedEula) ?? false;
  }

  bool get onboardingCompleted {
    return _prefs.getBool(_kOnboardingCompleted) ?? false;
  }

  bool get discordRPCEnabled {
    return _prefs.getBool(_kDiscordRPCEnabled) ?? true;
  }

  bool get dummySoundEnabled {
    return _prefs.getBool(_kDummySoundEnabled) ?? false;
  }

  bool get debugMode {
    return _prefs.getBool(_kDebugMode) ?? false;
  }

  Future<void> setServerURL(String value) async =>
      await _prefs.setString(_kServerURL, value);

  Future<void> setHasAcceptedEula(bool accepted) async {
    await _prefs.setBool(_kHasAcceptedEula, accepted);
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(_kOnboardingCompleted, completed);
  }

  Future<void> setDiscordRPCEnabled(bool enabled) async {
    await _prefs.setBool(_kDiscordRPCEnabled, enabled);
  }

  Future<void> setDummySoundEnabled(bool enabled) async {
    await _prefs.setBool(_kDummySoundEnabled, enabled);
  }

  Future<void> setDebugMode(bool enabled) async {
    await _prefs.setBool(_kDebugMode, enabled);
  }
}
