import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:distributeapp/core/preferences/audio_quality.dart';

part 'server_info.freezed.dart';
part 'server_info.g.dart';

@freezed
abstract class ServerInfo with _$ServerInfo {
  const factory ServerInfo({
    required String version,
    @JsonKey(name: 'request_mail_categories', defaultValue: [])
    required List<String> requestMailCategories,
    @JsonKey(name: 'request_mail_announcement')
    required String requestMailAnnouncement,
    @JsonKey(name: 'transcode_qualities', defaultValue: [])
    required List<AudioQualityOption> transcodeQualities,
  }) = _ServerInfo;

  factory ServerInfo.fromJson(Map<String, dynamic> json) =>
      _$ServerInfoFromJson(json);
}
