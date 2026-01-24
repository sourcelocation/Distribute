import 'package:distributeapp/core/database/database.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'playlist.freezed.dart';
part 'playlist.g.dart';

@freezed
abstract class Playlist with _$Playlist {
  const factory Playlist({
    required String id,
    required String name,
    String? folderId,
  }) = _Playlist;

  factory Playlist.fromDb(PlaylistEntity data) {
    return Playlist(id: data.id, name: data.name, folderId: data.folderId);
  }

  factory Playlist.fromJson(Map<String, dynamic> json) =>
      _$PlaylistFromJson(json);
}
