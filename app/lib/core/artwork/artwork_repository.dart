import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:distributeapp/core/preferences/settings_repository.dart';
import 'package:distributeapp/core/artwork/artwork_processor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;

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

  Color _vibrantize(Color color) {
    final hsl = HSLColor.fromColor(color);
    final saturation = (hsl.saturation + 0.0).clamp(0.0, 1.0);
    final lightness = (hsl.lightness - 0.25).clamp(0.0, 1.0);
    return hsl.withSaturation(saturation).withLightness(lightness).toColor();
  }

  Color _contrastMonochrome(Color color) {
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

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

    final future = _ensureArtworkFile(albumId, quality);
    _pendingDownloads[key] = future;

    future.whenComplete(() {
      _pendingDownloads.remove(key);
    });

    return future;
  }

  Future<File> _ensureArtworkFile(String albumId, ArtQuality quality) async {
    final absolutePath = getAbsolutePath(albumId, quality);
    final file = File(absolutePath);

    if (await file.exists()) {
      return file;
    }

    await file.parent.create(recursive: true);

    if (quality == ArtQuality.lq) {
      return _generateLowQualityArtwork(albumId, file);
    }

    return _downloadArtworkFile(albumId, quality);
  }

  Future<File> _generateLowQualityArtwork(
    String albumId,
    File targetFile,
  ) async {
    try {
      final hqFile = await getArtworkFile(albumId, ArtQuality.hq);
      final bytes = await hqFile.readAsBytes();
      final resizedBytes = await compute(
        _resizeImageBytes,
        _ArtworkResizeParams(
          bytes,
          _kLowQualityMaxDimension,
          _kLowQualityJpegQuality,
        ),
      );

      final tempFile = File('${targetFile.path}.tmp');
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      await tempFile.writeAsBytes(resizedBytes, flush: true);
      if (await tempFile.exists()) {
        await tempFile.rename(targetFile.path);
      }

      return targetFile;
    } catch (e) {
      debugPrint('Failed to generate low quality artwork: $e');
      return _downloadArtworkFile(albumId, ArtQuality.lq);
    }
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

      final colors = await extractArtworkColors(file);
      final primaryColor = Color(colors.primaryColor);
      final backgroundColor = Color(colors.backgroundColor);
      final oppositeColor = _contrastMonochrome(backgroundColor);

      debugPrint("Primary color HEX: ${primaryColor.value.toRadixString(16)}");
      debugPrint(
        "Background color HEX: ${backgroundColor.value.toRadixString(16)}",
      );
      debugPrint("Effect color HEX: ${oppositeColor.value.toRadixString(16)}");
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

const int _kLowQualityMaxDimension = 400;
const int _kLowQualityJpegQuality = 80;

class _ArtworkResizeParams {
  final Uint8List bytes;
  final int maxDimension;
  final int quality;

  _ArtworkResizeParams(this.bytes, this.maxDimension, this.quality);
}

List<int> _resizeImageBytes(_ArtworkResizeParams params) {
  final decoded = img.decodeImage(params.bytes);
  if (decoded == null) {
    return params.bytes;
  }

  final width = decoded.width;
  final height = decoded.height;
  final largestDimension = max(width, height);
  final ratio = largestDimension > params.maxDimension
      ? params.maxDimension / largestDimension
      : 1.0;

  final newWidth = max(1, (width * ratio).round());
  final newHeight = max(1, (height * ratio).round());

  final resized = img.copyResize(
    decoded,
    width: newWidth,
    height: newHeight,
    interpolation: img.Interpolation.average,
  );

  return img.encodeJpg(resized, quality: params.quality);
}
