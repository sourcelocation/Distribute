import 'dart:io';

import 'package:distributeapp/core/preferences/settings_repository.dart';

import 'package:dio/dio.dart';
import 'package:distributeapp/model/song.dart';

class DownloadApi {
  final Dio client;
  final SettingsRepository settings;

  DownloadApi({required this.client, required this.settings});

  String get _rootPath => settings.rootPath;

  Future<void> downloadFile(
    Song song,
    void Function(int, int)? onReceiveProgress,
  ) async {
    final fileID = song.fileId;
    final url = '/api/songs/download/$fileID';

    final tempFile = File('${song.localPath(_rootPath)}.tmp');
    await tempFile.parent.create(recursive: true);

    await client.download(
      url,
      tempFile.path,
      onReceiveProgress: onReceiveProgress,
    );
    if (await tempFile.exists()) {
      await tempFile.rename(song.localPath(_rootPath));
    }
  }

  Future<void> deleteFile(Song song) async {
    final fileObj = File(song.localPath(_rootPath));
    if (await fileObj.exists()) {
      await fileObj.delete();
    }
  }
}
