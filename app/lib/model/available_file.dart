import 'package:freezed_annotation/freezed_annotation.dart';

part 'available_file.freezed.dart';
part 'available_file.g.dart';

@freezed
abstract class AvailableFile with _$AvailableFile {
  const factory AvailableFile({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'format') required String format,
    @JsonKey(name: 'bitrate', defaultValue: 0) required int bitrate,
    @JsonKey(name: 'size', defaultValue: 0) required int size,
    @JsonKey(name: 'duration', defaultValue: 0) required int durationMs,
  }) = _AvailableFile;

  factory AvailableFile.fromJson(Map<String, dynamic> json) =>
      _$AvailableFileFromJson(json);
}
