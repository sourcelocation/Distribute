import 'dart:io';

import 'package:dio/dio.dart';
import 'package:distributeapp/model/song.dart';

class DownloadApi {
  final Dio client;
  final String appDataPath;

  DownloadApi({required this.client, required this.appDataPath});

  Future<void> downloadFile(
    Song song,
    void Function(int, int)? onReceiveProgress,
  ) async {
    final fileID = song.fileId;
    final url = '/api/songs/download/$fileID';

    final tempFile = File('${song.localPath(appDataPath)}.tmp');
    await tempFile.parent.create(recursive: true);

    await client.download(
      url,
      tempFile.path,
      onReceiveProgress: onReceiveProgress,
    );
    if (await tempFile.exists()) {
      await tempFile.rename(song.localPath(appDataPath));
    }
  }

  Future<void> deleteFile(Song song) async {
    final fileObj = File(song.localPath(appDataPath));
    if (await fileObj.exists()) {
      await fileObj.delete();
    }
  }
}
