import 'package:freezed_annotation/freezed_annotation.dart';

part 'server_playlist.freezed.dart';
part 'server_playlist.g.dart';

@freezed
abstract class ServerPlaylist with _$ServerPlaylist {
  factory ServerPlaylist({
    required String id,
    required String name,
    @JsonKey(name: 'folder_id') String? folderId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'song_ids') required List<String> songIds,
  }) = _ServerPlaylist;

  factory ServerPlaylist.fromJson(Map<String, dynamic> json) =>
      _$ServerPlaylistFromJson(json);
}
