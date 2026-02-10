import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:distributeapp/core/preferences/vinyl_style.dart';
import 'package:distributeapp/core/preferences/audio_quality.dart';

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
  static const _kDownloadMode = 'download_mode';
  static const _kStreamingQualityId = 'streaming_quality_id';
  static const _kDownloadQualityId = 'download_quality_id';
  static const _kAvailableQualities = 'available_audio_qualities';
  static const _kPlayerVolume = 'player_volume';

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

  int get downloadModeIndex {
    return _prefs.getInt(_kDownloadMode) ?? 0;
  }

  Future<void> setDownloadModeIndex(int index) async {
    await _prefs.setInt(_kDownloadMode, index);
  }

  String? get streamingQualityId {
    final stored = _prefs.getString(_kStreamingQualityId);
    if (stored != null && stored.isNotEmpty) return stored;
    return null;
  }

  Future<void> setStreamingQualityId(String id) async {
    await _prefs.setString(_kStreamingQualityId, id);
  }

  String? get downloadQualityId {
    final stored = _prefs.getString(_kDownloadQualityId);
    if (stored != null && stored.isNotEmpty) return stored;
    return null;
  }

  Future<void> setDownloadQualityId(String id) async {
    await _prefs.setString(_kDownloadQualityId, id);
  }

  List<AudioQualityOption> get availableQualities {
    final raw = _prefs.getString(_kAvailableQualities);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final options = decoded
              .whereType<Map>()
              .map((item) => AudioQualityOption.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList();
          return AudioQualityCatalog.normalize(options);
        }
      } catch (_) {}
    }
    return AudioQualityCatalog.defaults;
  }

  Future<void> setAvailableQualities(List<AudioQualityOption> options) async {
    final normalized = AudioQualityCatalog.normalize(options);
    final raw = jsonEncode(
      normalized.map((option) => option.toJson()).toList(),
    );
    await _prefs.setString(_kAvailableQualities, raw);
  }

  AudioQualityOption get streamingQuality {
    final options = availableQualities;
    return AudioQualityCatalog.resolveById(streamingQualityId, options);
  }

  AudioQualityOption get downloadQuality {
    final options = availableQualities;
    return AudioQualityCatalog.resolveById(downloadQualityId, options);
  }

  double get playerVolume {
    final value = _prefs.getDouble(_kPlayerVolume);
    if (value == null) return 1.0;
    return value.clamp(0.0, 1.0);
  }

  Future<void> setPlayerVolume(double volume) async {
    final value = volume.clamp(0.0, 1.0);
    await _prefs.setDouble(_kPlayerVolume, value);
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
