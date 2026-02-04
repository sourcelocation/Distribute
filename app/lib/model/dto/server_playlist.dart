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
    @JsonKey(name: 'playlist_songs')
    @Default([])
    List<ServerPlaylistSong> playlistSongs,
  }) = _ServerPlaylist;

  factory ServerPlaylist.fromJson(Map<String, dynamic> json) =>
      _$ServerPlaylistFromJson(json);
}

@freezed
abstract class ServerPlaylistSong with _$ServerPlaylistSong {
  factory ServerPlaylistSong({
    @JsonKey(name: 'song_id') required String songId,
    @Default('') String order,
  }) = _ServerPlaylistSong;

  factory ServerPlaylistSong.fromJson(Map<String, dynamic> json) =>
      _$ServerPlaylistSongFromJson(json);
}
