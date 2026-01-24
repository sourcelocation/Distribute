import 'package:freezed_annotation/freezed_annotation.dart';

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
  }) = _ServerInfo;

  factory ServerInfo.fromJson(Map<String, dynamic> json) =>
      _$ServerInfoFromJson(json);
}
