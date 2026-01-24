import 'package:freezed_annotation/freezed_annotation.dart';

part 'server_album.freezed.dart';
part 'server_album.g.dart';

@freezed
abstract class ServerAlbum with _$ServerAlbum {
  factory ServerAlbum({
    required String id,
    required String title,
    @JsonKey(name: 'release_date') required DateTime releaseDate,
  }) = _ServerAlbum;

  factory ServerAlbum.fromJson(Map<String, dynamic> json) =>
      _$ServerAlbumFromJson(json);
}
