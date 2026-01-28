import 'dart:io';

import 'package:distributeapp/core/preferences/settings_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class ArtworkData {
  final File? imageFileHq;
  final File? imageFileLq;
  final Uri? artUri;
  final Color? _primaryColor;
  final Color? _backgroundColor;
  final Color? _effectColor;

  ArtworkData({
    required this.imageFileHq,
    required this.imageFileLq,
    required this.artUri,
    Color? primaryColor,
    Color? backgroundColor,
    Color? effectColor,
  }) : _primaryColor = primaryColor,
       _backgroundColor = backgroundColor,
       _effectColor = effectColor;

  Color get primaryColor => _primaryColor ?? Colors.grey;
  Color get backgroundColor => _backgroundColor ?? Colors.grey;
  Color get effectColor => _effectColor ?? Colors.white;

  // Helper to check if colors are actually loaded
  bool get hasColors => _primaryColor != null;

  Color tintedColor() {
    return Color.lerp(primaryColor, Colors.white, 0.7)!;
  }

  static final ArtworkData empty = ArtworkData(
    imageFileHq: null,
    imageFileLq: null,
    artUri: null,
    primaryColor: Colors.grey,
    backgroundColor: Colors.grey,
    effectColor: Colors.white,
  );
}

enum ArtQuality { hq, lq }

class ArtworkRepository {
  final Map<String, ArtworkData> _memoryCache = {};
  final Dio client;
  final SettingsRepository settings;

  ArtworkRepository(this.client, {required this.settings});

  void clearCache() {
    _memoryCache.clear();
    _pendingDownloads.clear();
  }

  final Map<String, Future<File>> _pendingDownloads = {};

  Future<File> getArtworkFile(String albumId, ArtQuality quality) {
    final key = '$albumId-$quality';
    if (_pendingDownloads.containsKey(key)) {
      return _pendingDownloads[key]!;
    }

    final future = _downloadArtworkFile(albumId, quality);
    _pendingDownloads[key] = future;

    future.whenComplete(() {
      _pendingDownloads.remove(key);
    });

    return future;
  }

  Future<File> _downloadArtworkFile(String albumId, ArtQuality quality) async {
    final absolutePath = getAbsolutePath(albumId, quality);
    final file = File(absolutePath);

    if (await file.exists()) {
      return file;
    }

    await file.parent.create(recursive: true);

    final String url = apiURL(albumId, quality);
    final tempFile = File('${file.path}.tmp');
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
    await client.download(url, tempFile.path);
    if (await tempFile.exists()) {
      await tempFile.rename(absolutePath);
    }

    return file;
  }

  Future<ArtworkData> getArtworkData(
    String albumId,
    ArtQuality quality, {
    bool loadColors = true,
  }) async {
    final cached = _memoryCache[albumId];
    if (cached != null) {
      final hasQuality = quality == ArtQuality.hq
          ? cached.imageFileHq != null
          : cached.imageFileLq != null;

      if (hasQuality && (!loadColors || cached.hasColors)) {
        return cached;
      }
    }

    try {
      final file = await getArtworkFile(albumId, quality);

      if (!loadColors) {
        final data = ArtworkData(
          imageFileHq: quality == ArtQuality.hq ? file : cached?.imageFileHq,
          imageFileLq: quality == ArtQuality.lq ? file : cached?.imageFileLq,
          artUri: Uri.file(file.path),
          primaryColor: cached?._primaryColor,
          backgroundColor: cached?._backgroundColor,
          effectColor: cached?._effectColor,
        );
        _memoryCache[albumId] = data;
        return data;
      }

      if (cached != null && cached.hasColors) {
        final newData = ArtworkData(
          imageFileHq: quality == ArtQuality.hq ? file : cached.imageFileHq,
          imageFileLq: quality == ArtQuality.lq ? file : cached.imageFileLq,
          artUri: Uri.file(file.path),
          primaryColor: cached.primaryColor,
          backgroundColor: cached.backgroundColor,
          effectColor: cached.effectColor,
        );
        _memoryCache[albumId] = newData;
        return newData;
      }

      final scheme = await ColorScheme.fromImageProvider(
        provider: FileImage(file),
        brightness: Brightness.dark,
      );

      final primaryColor = scheme.secondary;
      final backgroundColor = scheme.surface;
      final oppositeColor = scheme.onSurface;

      final data = ArtworkData(
        imageFileHq: quality == ArtQuality.hq ? file : cached?.imageFileHq,
        imageFileLq: quality == ArtQuality.lq ? file : cached?.imageFileLq,
        artUri: Uri.file(file.path),
        primaryColor: primaryColor,
        backgroundColor: backgroundColor,
        effectColor: oppositeColor,
      );

      _memoryCache[albumId] = data;
      return data;
    } catch (e) {
      return ArtworkData.empty;
    }
  }

  String apiURL(String albumId, ArtQuality quality) {
    return '/api/images/covers/$albumId/${quality == ArtQuality.hq ? "hq" : "lq"}';
  }

  String fullApiURL(String albumId, ArtQuality quality) {
    return '${client.options.baseUrl}${apiURL(albumId, quality)}';
  }

  String getRelativePath(String albumId, ArtQuality quality) {
    final String subFolder = quality == ArtQuality.hq
        ? 'album_covers_hq'
        : 'album_covers_lq';
    final String hashed = sha256.convert(utf8.encode(albumId)).toString();
    // double sharding
    final String part1 = hashed.substring(0, 2);
    final String part2 = hashed.substring(2, 4);
    return '$subFolder/$part1/$part2/$hashed.jpg';
  }

  String getAbsolutePath(String albumId, ArtQuality quality) {
    final root = settings.rootPath;
    return '$root/${getRelativePath(albumId, quality)}';
  }
}
