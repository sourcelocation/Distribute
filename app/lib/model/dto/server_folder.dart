import 'package:freezed_annotation/freezed_annotation.dart';

part 'server_folder.freezed.dart';
part 'server_folder.g.dart';

@freezed
abstract class ServerFolder with _$ServerFolder {
  factory ServerFolder({
    required String id,
    required String name,
    @JsonKey(name: 'parent_folder_id') String? parentFolderId,
  }) = _ServerFolder;

  factory ServerFolder.fromJson(Map<String, dynamic> json) =>
      _$ServerFolderFromJson(json);
}
