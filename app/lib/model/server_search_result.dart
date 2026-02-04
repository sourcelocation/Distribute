import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:distributeapp/model/dto/server_artist.dart';

part 'server_search_result.freezed.dart';
part 'server_search_result.g.dart';

@Freezed(unionKey: 'type', fallbackUnion: 'unknown')
sealed class ServerSearchResult with _$ServerSearchResult {
  const factory ServerSearchResult.song({
    required String id,
    required String title,
    @JsonKey(name: 'artists') required List<ServerArtist> artists,
    @JsonKey(name: 'album_id') required String albumId,
    @JsonKey(name: 'album_title') required String albumTitle,
  }) = ServerSearchResultSong;

  const factory ServerSearchResult.artist({
    required String id,
    required String title,
  }) = ServerSearchResultArtist;

  const factory ServerSearchResult.album({
    required String id,
    required String title,
  }) = ServerSearchResultAlbum;

  const factory ServerSearchResult.playlist({
    required String id,
    required String title,
  }) = ServerSearchResultPlaylist;

  const factory ServerSearchResult.unknown({
    required String id,
    required String type,
    required String title,
    String? sub,
  }) = ServerSearchResultUnknown;

  factory ServerSearchResult.fromJson(Map<String, dynamic> json) =>
      _$ServerSearchResultFromJson(json);
}
