import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:distributeapp/model/dto/entity_ids.dart';

part 'sync_manifest.freezed.dart';
part 'sync_manifest.g.dart';

@freezed
abstract class SyncManifest with _$SyncManifest {
  factory SyncManifest({
    @JsonKey(name: 'latest_server_time') required DateTime latestServerTime,
    required EntityIDs changed,
    required EntityIDs removed,
  }) = _SyncManifest;

  factory SyncManifest.fromJson(Map<String, dynamic> json) =>
      _$SyncManifestFromJson(json);
}
