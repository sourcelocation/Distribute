enum DownloadMode {
  downloadAll,
  streamOnly,
}

extension DownloadModeX on DownloadMode {
  static DownloadMode fromIndex(int index) {
    if (index < 0 || index >= DownloadMode.values.length) {
      return DownloadMode.downloadAll;
    }
    return DownloadMode.values[index];
  }
}
