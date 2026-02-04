import 'package:freezed_annotation/freezed_annotation.dart';

part 'server_artist.freezed.dart';
part 'server_artist.g.dart';

@freezed
abstract class ServerArtist with _$ServerArtist {
  factory ServerArtist({required String id, required String name}) =
      _ServerArtist;

  factory ServerArtist.fromJson(Map<String, dynamic> json) =>
      _$ServerArtistFromJson(json);
}
