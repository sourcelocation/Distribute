import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'song.freezed.dart';

@freezed
abstract class Song with _$Song {
  const factory Song({
    required String id,
    required String title,
    required List<String> artists,
    required String albumTitle,
    required String albumId,
    required String? fileId,
    required String? format,
    required bool isDownloaded,
    String? order,
  }) = _Song;

  const Song._();

  String get artist => artists.join(', ');

  String get fileName => '$fileId.$format';

  String localPath(String rootPath) {
    return '$rootPath/downloaded/$fileName';
  }

  Future<Duration?> getDuration(String rootPath) async {
    final path = localPath(rootPath);
    final file = File(path);

    if (!await file.exists()) return null;

    try {
      return await compute(_readDuration, file);
    } catch (e) {
      return null;
    }
  }

  static Duration? _readDuration(File file) {
    final metadata = readMetadata(file, getImage: false);
    return metadata.duration;
  }
}
