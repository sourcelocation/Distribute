import 'package:shared_preferences/shared_preferences.dart';
import 'package:distributeapp/core/preferences/vinyl_style.dart';

class SettingsRepository {
  final SharedPreferences _prefs;
  final String defaultDataPath;

  SettingsRepository(this._prefs, this.defaultDataPath);

  String get rootPath => customDownloadPath ?? defaultDataPath;

  static const _kServerURL = 'server_url';
  static const _kHasAcceptedEula = 'has_accepted_eula';
  static const _kDiscordRPCEnabled = 'discord_rpc_enabled';
  static const _kDummySoundEnabled = 'dummy_sound_enabled';
  static const _kDebugMode = 'debug_mode';
  static const _kOnboardingCompleted = 'onboarding_completed';
  static const _kCustomDownloadPath = 'custom_download_path';

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

  static const _kPreloadNextSongEnabled = 'preload_next_song_enabled';
  static const _kKeepVinylSpinningWhenUnfocused =
      'keep_vinyl_spinning_when_unfocused';

  bool get preloadNextSongEnabled {
    return _prefs.getBool(_kPreloadNextSongEnabled) ?? true;
  }

  Future<void> setPreloadNextSongEnabled(bool enabled) async {
    await _prefs.setBool(_kPreloadNextSongEnabled, enabled);
  }

  bool get keepVinylSpinningWhenUnfocused {
    return _prefs.getBool(_kKeepVinylSpinningWhenUnfocused) ?? false;
  }

  Future<void> setKeepVinylSpinningWhenUnfocused(bool enabled) async {
    await _prefs.setBool(_kKeepVinylSpinningWhenUnfocused, enabled);
  }

  String? get customDownloadPath {
    return _prefs.getString(_kCustomDownloadPath);
  }

  Future<void> setCustomDownloadPath(String? path) async {
    if (path == null) {
      await _prefs.remove(_kCustomDownloadPath);
    } else {
      await _prefs.setString(_kCustomDownloadPath, path);
    }
  }

  static const _kVinylStyle = 'vinyl_style';

  VinylStyle get vinylStyle {
    final value = _prefs.getInt(_kVinylStyle);
    if (value == null || value < 0 || value >= VinylStyle.values.length) {
      return VinylStyle.modern;
    }
    return VinylStyle.values[value];
  }

  Future<void> setVinylStyle(VinylStyle style) async {
    await _prefs.setInt(_kVinylStyle, style.index);
  }
}
