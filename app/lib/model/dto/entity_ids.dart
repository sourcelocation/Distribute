import 'package:freezed_annotation/freezed_annotation.dart';

part 'entity_ids.freezed.dart';
part 'entity_ids.g.dart';

@freezed
abstract class EntityIDs with _$EntityIDs {
  factory EntityIDs({
    required List<String> playlists,
    required List<String> folders,
    required List<String> songs,
    required List<String> albums,
    required List<String> artists,
  }) = _EntityIDs;

  factory EntityIDs.fromJson(Map<String, dynamic> json) =>
      _$EntityIDsFromJson(json);
}
