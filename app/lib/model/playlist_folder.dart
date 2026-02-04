import 'package:distributeapp/core/database/database.dart';
import 'package:distributeapp/model/playlist.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'playlist_folder.freezed.dart';
part 'playlist_folder.g.dart';

@freezed
abstract class PlaylistFolder with _$PlaylistFolder {
  const factory PlaylistFolder({
    required String id,
    required String name,
    @JsonKey(name: 'folder_id') String? parentFolderId,
    @Default([])
    @JsonKey(includeFromJson: false, includeToJson: false)
    List<PlaylistFolder> children,
    @Default([])
    @JsonKey(includeFromJson: false, includeToJson: false)
    List<Playlist> playlists,
  }) = _PlaylistFolder;

  factory PlaylistFolder.fromJson(Map<String, dynamic> json) =>
      _$PlaylistFolderFromJson(json);

  factory PlaylistFolder.fromDb(FolderEntity entity) {
    return PlaylistFolder(
      id: entity.id,
      name: entity.name,
      parentFolderId: entity.parentFolderId,
    );
  }
}
