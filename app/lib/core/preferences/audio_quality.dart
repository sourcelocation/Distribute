import 'package:collection/collection.dart';

class AudioQualityOption {
  final String id;
  final String label;
  final int bitrateKbps;
  final bool isLossless;

  const AudioQualityOption({
    required this.id,
    required this.label,
    required this.bitrateKbps,
    required this.isLossless,
  });

  factory AudioQualityOption.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['variant'];
    final id = (rawId is String && rawId.isNotEmpty)
        ? rawId
        : _fallbackId(
            bitrateKbps: (json['bitrate_kbps'] ?? json['bitrate'] ?? 0) as int,
            lossless: json['lossless'] == true,
          );
    final bitrate = (json['bitrate_kbps'] ?? json['bitrate'] ?? 0) as int;
    final lossless = json['lossless'] == true || bitrate == 0;
    final label =
        (json['label'] as String?) ?? (lossless ? 'Lossless' : '$bitrate kbps');
    return AudioQualityOption(
      id: id,
      label: label,
      bitrateKbps: bitrate,
      isLossless: lossless,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'bitrate_kbps': bitrateKbps,
    'lossless': isLossless,
  };

  static String _fallbackId({
    required int bitrateKbps,
    required bool lossless,
  }) {
    if (lossless || bitrateKbps == 0) return 'lossless';
    return '${bitrateKbps}k';
  }

  @override
  bool operator ==(Object other) =>
      other is AudioQualityOption && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class AudioQualityCatalog {
  static const AudioQualityOption lossless = AudioQualityOption(
    id: 'lossless',
    label: 'Lossless',
    bitrateKbps: 0,
    isLossless: true,
  );
  static const List<AudioQualityOption> defaults = [lossless];

  static List<AudioQualityOption> normalize(List<AudioQualityOption> options) {
    final seen = <String>{};
    final normalized = <AudioQualityOption>[];
    for (final option in options) {
      if (seen.add(option.id)) {
        normalized.add(option);
      }
    }
    return normalized.isEmpty ? defaults : normalized;
  }

  static AudioQualityOption resolveSelection({
    required AudioQualityOption? current,
    required List<AudioQualityOption> options,
  }) {
    if (options.isEmpty) return lossless;
    if (current == null) return _defaultOption(options);
    final byId = options.firstWhereOrNull((o) => o.id == current.id);
    if (byId != null) return byId;
    if (current.isLossless) {
      return options.firstWhereOrNull((o) => o.isLossless) ?? options.first;
    }
    return _closestBitrate(current.bitrateKbps, options);
  }

  static AudioQualityOption resolveById(
    String? id,
    List<AudioQualityOption> options,
  ) {
    if (options.isEmpty) return lossless;
    if (id == null || id.isEmpty) {
      return _defaultOption(options);
    }
    final byId = options.firstWhereOrNull((o) => o.id == id);
    if (byId != null) return byId;
    return _defaultOption(options);
  }

  static AudioQualityOption _closestBitrate(
    int bitrateKbps,
    List<AudioQualityOption> options,
  ) {
    final lossy =
        options.where((o) => !o.isLossless && o.bitrateKbps > 0).toList()
          ..sort((a, b) => a.bitrateKbps.compareTo(b.bitrateKbps));
    if (lossy.isEmpty) {
      return options.firstWhereOrNull((o) => o.isLossless) ?? options.first;
    }
    final below = lossy.where((o) => o.bitrateKbps <= bitrateKbps).toList();
    if (below.isNotEmpty) return below.last;
    return lossy.first;
  }

  static AudioQualityOption _defaultOption(List<AudioQualityOption> options) {
    final lossy =
        options.where((o) => !o.isLossless && o.bitrateKbps > 0).toList()
          ..sort((a, b) => a.bitrateKbps.compareTo(b.bitrateKbps));
    if (lossy.isNotEmpty) return lossy.first;
    return options.first;
  }
}
