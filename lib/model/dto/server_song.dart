import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:distributeapp/model/dto/server_artist.dart';

part 'server_song.freezed.dart';
part 'server_song.g.dart';

@freezed
abstract class ServerSong with _$ServerSong {
  factory ServerSong({
    required String id,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    required String title,
    @JsonKey(name: 'album_id') required String albumId,
    required List<ServerArtist> artists,
  }) = _ServerSong;

  factory ServerSong.fromJson(Map<String, dynamic> json) =>
      _$ServerSongFromJson(json);
}
