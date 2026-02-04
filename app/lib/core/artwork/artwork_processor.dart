import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ArtworkColors {
  final int primaryColor;
  final int backgroundColor;

  const ArtworkColors({
    required this.primaryColor,
    required this.backgroundColor,
  });
}

Future<ArtworkColors> extractArtworkColors(File file) async {
  final bytes = await file.readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return const ArtworkColors(
      primaryColor: 0xFF808080,
      backgroundColor: 0xFF808080,
    );
  }

  final resized = _downscale(decoded, 120);
  final pixels = _samplePixels(resized);
  if (pixels.isEmpty) {
    return const ArtworkColors(
      primaryColor: 0xFF808080,
      backgroundColor: 0xFF808080,
    );
  }

  final clusters = _kMeans(pixels, k: 8, iterations: 8);
  clusters.removeWhere((c) => c.population == 0);
  if (clusters.isEmpty) {
    return const ArtworkColors(
      primaryColor: 0xFF808080,
      backgroundColor: 0xFF808080,
    );
  }

  clusters.sort((a, b) => b.population.compareTo(a.population));
  final background = clusters.first;

  final backgroundLuminance = _luminance(background.color);
  final primary = _pickPrimary(clusters, backgroundLuminance);

  return ArtworkColors(
    primaryColor: primary.color.value,
    backgroundColor: background.color.value,
  );
}

img.Image _downscale(img.Image image, int maxDimension) {
  final width = image.width;
  final height = image.height;
  final largest = max(width, height);
  if (largest <= maxDimension) {
    return image;
  }

  final ratio = maxDimension / largest;
  final newWidth = max(1, (width * ratio).round());
  final newHeight = max(1, (height * ratio).round());
  return img.copyResize(
    image,
    width: newWidth,
    height: newHeight,
    interpolation: img.Interpolation.average,
  );
}

List<_PixelSample> _samplePixels(img.Image image) {
  final pixels = <_PixelSample>[];
  final step = max(1, (max(image.width, image.height) / 80).floor());
  for (int y = 0; y < image.height; y += step) {
    for (int x = 0; x < image.width; x += step) {
      final pixel = image.getPixel(x, y);
      final a = pixel.a.toInt();
      if (a < 200) continue;
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      pixels.add(_PixelSample(r, g, b));
    }
  }
  return pixels;
}

class _PixelSample {
  final int r;
  final int g;
  final int b;

  _PixelSample(this.r, this.g, this.b);
}

class _Cluster {
  int r;
  int g;
  int b;
  int population;

  _Cluster(this.r, this.g, this.b, this.population);

  Color get color => Color.fromARGB(0xFF, r, g, b);
}

List<_Cluster> _kMeans(
  List<_PixelSample> pixels, {
  required int k,
  required int iterations,
}) {
  final rand = Random(1337);
  final clusters = <_Cluster>[];
  for (int i = 0; i < k; i++) {
    final sample = pixels[rand.nextInt(pixels.length)];
    clusters.add(_Cluster(sample.r, sample.g, sample.b, 0));
  }

  for (int iter = 0; iter < iterations; iter++) {
    final sums = List<_Cluster>.generate(k, (_) => _Cluster(0, 0, 0, 0));

    for (final pixel in pixels) {
      int bestIndex = 0;
      double bestDist = double.infinity;
      for (int i = 0; i < clusters.length; i++) {
        final c = clusters[i];
        final dist = _colorDistance(pixel, c);
        if (dist < bestDist) {
          bestDist = dist;
          bestIndex = i;
        }
      }
      final sum = sums[bestIndex];
      sum.r += pixel.r;
      sum.g += pixel.g;
      sum.b += pixel.b;
      sum.population += 1;
    }

    for (int i = 0; i < clusters.length; i++) {
      final sum = sums[i];
      if (sum.population == 0) continue;
      clusters[i]
        ..r = (sum.r / sum.population).round()
        ..g = (sum.g / sum.population).round()
        ..b = (sum.b / sum.population).round()
        ..population = sum.population;
    }
  }

  return clusters;
}

double _colorDistance(_PixelSample pixel, _Cluster cluster) {
  final dr = pixel.r - cluster.r;
  final dg = pixel.g - cluster.g;
  final db = pixel.b - cluster.b;
  return (dr * dr + dg * dg + db * db).toDouble();
}

double _luminance(Color color) {
  return color.computeLuminance();
}

double _saturation(Color color) {
  final hsl = HSLColor.fromColor(color);
  return hsl.saturation;
}

_Cluster _pickPrimary(List<_Cluster> clusters, double backgroundLuminance) {
  _Cluster best = clusters.first;
  double bestScore = -1;

  for (final cluster in clusters) {
    final color = cluster.color;
    final sat = _saturation(color);
    final lum = _luminance(color);
    final lumDistance = (lum - backgroundLuminance).abs();

    final populationWeight = cluster.population.toDouble();
    final saturationWeight = pow(sat, 1.3).toDouble();
    final contrastWeight = 0.6 + lumDistance;

    final score = populationWeight * saturationWeight * contrastWeight;
    if (score > bestScore) {
      bestScore = score;
      best = cluster;
    }
  }

  return best;
}
