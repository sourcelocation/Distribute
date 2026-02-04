import 'package:freezed_annotation/freezed_annotation.dart';

part 'local_search_result.freezed.dart';
part 'local_search_result.g.dart';

@freezed
abstract class LocalSearchResult with _$LocalSearchResult {
  const factory LocalSearchResult({
    required SearchSong song,
    required SearchAlbum album,
    required SearchArtist artist,
  }) = _LocalSearchResult;

  const LocalSearchResult._();

  factory LocalSearchResult.fromJson(Map<String, dynamic> json) =>
      _$LocalSearchResultFromJson(json);

  String get id => song.id;
  String get title => song.title;
  String get artistName => artist.name;
  String get artistId => artist.id;
  String get albumTitle => album.title;
  String get albumId => album.id;
}

@freezed
abstract class SearchSong with _$SearchSong {
  const factory SearchSong({
    @JsonKey(name: 'ID', defaultValue: '') required String id,
    @JsonKey(name: 'CreatedAt', defaultValue: '') required String createdAt,
    @JsonKey(name: 'UpdatedAt', defaultValue: '') required String updatedAt,
    @JsonKey(name: 'DeletedAt') String? deletedAt,
    @JsonKey(name: 'AlbumID', defaultValue: '') required String albumId,
    @JsonKey(name: 'Title', defaultValue: '') required String title,
  }) = _SearchSong;

  factory SearchSong.fromJson(Map<String, dynamic> json) =>
      _$SearchSongFromJson(json);
}

@freezed
abstract class SearchAlbum with _$SearchAlbum {
  const factory SearchAlbum({
    @JsonKey(name: 'ID', defaultValue: '') required String id,
    @JsonKey(name: 'CreatedAt', defaultValue: '') required String createdAt,
    @JsonKey(name: 'UpdatedAt', defaultValue: '') required String updatedAt,
    @JsonKey(name: 'DeletedAt') String? deletedAt,
    @JsonKey(name: 'Title', defaultValue: '') required String title,
    @JsonKey(name: 'ReleaseDate', defaultValue: '') required String releaseDate,
  }) = _SearchAlbum;

  factory SearchAlbum.fromJson(Map<String, dynamic> json) =>
      _$SearchAlbumFromJson(json);
}

@freezed
abstract class SearchArtist with _$SearchArtist {
  const factory SearchArtist({
    @JsonKey(name: 'ID', defaultValue: '') required String id,
    @JsonKey(name: 'CreatedAt', defaultValue: '') required String createdAt,
    @JsonKey(name: 'UpdatedAt', defaultValue: '') required String updatedAt,
    @JsonKey(name: 'DeletedAt') String? deletedAt,
    @JsonKey(name: 'Name', defaultValue: '') required String name,
  }) = _SearchArtist;

  factory SearchArtist.fromJson(Map<String, dynamic> json) =>
      _$SearchArtistFromJson(json);
}

@freezed
abstract class SearchFile with _$SearchFile {
  const factory SearchFile({
    @JsonKey(name: 'ID', defaultValue: '') required String id,
    @JsonKey(name: 'Format', defaultValue: '') required String format,
  }) = _SearchFile;

  factory SearchFile.fromJson(Map<String, dynamic> json) =>
      _$SearchFileFromJson(json);
}
