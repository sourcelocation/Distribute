import 'package:freezed_annotation/freezed_annotation.dart';

part 'server_song_file.freezed.dart';
part 'server_song_file.g.dart';

@freezed
abstract class ServerSongFile with _$ServerSongFile {
  factory ServerSongFile({
    required String id,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    required String format,
    required int duration,
  }) = _ServerSongFile;

  factory ServerSongFile.fromJson(Map<String, dynamic> json) =>
      _$ServerSongFileFromJson(json);
}
