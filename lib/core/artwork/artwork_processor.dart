import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

/// Result class for color extraction containing ARGB integers.
class ValidColors {
  final int primaryColor;
  final int backgroundColor;
  final int effectColor;

  ValidColors({
    required this.primaryColor,
    required this.backgroundColor,
    required this.effectColor,
  });
}

/// Extacts colors from the given file in a background isolate friendly way.
/// Returns [ValidColors] with int ARGB values.
Future<ValidColors> extractArtworkColors(File file) async {
  try {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      return _defaultColors();
    }

    // Resize to speed up processing
    final resized = img.copyResize(image, width: 100);

    final pixels = <int>[];
    for (final pixel in resized) {
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      // Store as packed RGB (0xRRGGBB)
      pixels.add((r << 16) | (g << 8) | b);
    }

    if (pixels.isEmpty) return _defaultColors();

    // --- K-Means Algorithm ---
    const int k = 4;
    const int maxIterations = 15;

    // Initialize centroids randomly
    final random = Random();
    List<int> centroids = [];
    if (pixels.length < k) {
      // Fallback if image has fewer pixels than K
      centroids = List.from(pixels);
    } else {
      for (int i = 0; i < k; i++) {
        centroids.add(pixels[random.nextInt(pixels.length)]);
      }
    }

    List<_Cluster> clusters = [];

    if (centroids.isNotEmpty) {
      for (int i = 0; i < maxIterations; i++) {
        // Reset clusters
        clusters = List.generate(centroids.length, (_) => _Cluster());

        // Assign pixels to closest centroid
        for (final pixel in pixels) {
          int pr = (pixel >> 16) & 0xFF;
          int pg = (pixel >> 8) & 0xFF;
          int pb = pixel & 0xFF;

          int minDistance = 255 * 255 * 3 + 1;
          int closestIndex = 0;

          for (int j = 0; j < centroids.length; j++) {
            final c = centroids[j];
            int cr = (c >> 16) & 0xFF;
            int cg = (c >> 8) & 0xFF;
            int cb = c & 0xFF;

            // Euclidean distance squared
            int dr = pr - cr;
            int dg = pg - cg;
            int db = pb - cb;
            int dist = dr * dr + dg * dg + db * db;

            if (dist < minDistance) {
              minDistance = dist;
              closestIndex = j;
            }
          }
          clusters[closestIndex].addPixel(pr, pg, pb);
        }

        // Recompute centroids
        bool converged = true;
        for (int j = 0; j < centroids.length; j++) {
          if (clusters[j].count > 0) {
            int newCentroid = clusters[j].getAverageColor();
            if (newCentroid != centroids[j]) {
              centroids[j] = newCentroid;
              converged = false;
            }
          }
        }

        if (converged) break;
      }
    }

    // Sort by population
    clusters.sort((a, b) => b.count.compareTo(a.count));

    // Pick the best effect color
    // We prefer the most dominant color that isn't too close to black or white/grey
    int bestEffect = 0xFFFFFFFF; // Fallback
    bool found = false;

    // Filter out empty clusters
    final validClusters = clusters.where((c) => c.count > 0).toList();

    if (validClusters.isNotEmpty) {
      // Strategy: Find the most populated cluster that satisfies saturation/luminance checks
      for (final cluster in validClusters) {
        final color = cluster.getAverageColor();

        final r = (color >> 16) & 0xFF;
        final g = (color >> 8) & 0xFF;
        final b = color & 0xFF;

        // Convert to HSL/HSV approximation for saturation/lightness check
        final mx = max(r, max(g, b));
        final mn = min(r, min(g, b));
        final d = mx - mn;

        // Conditions:
        // 1. Not too dark (mx > 30)
        // 2. Has some color (d > 10)

        if (mx > 30 && d > 10) {
          // Ideally we want something colorful.
          // If we find a dominant color that is somewhat colorful, take it.
          bestEffect = _toFullArgb(color);
          found = true;
          break;
        }
      }

      // If no "good" color found, just take the most dominant one (likely B/W image)
      if (!found) {
        bestEffect = _toFullArgb(validClusters.first.getAverageColor());
      }
    }

    return ValidColors(
      primaryColor: 0xFFFFFFFF, // Static White
      backgroundColor: 0x99000000, // Static Transparent Black (~60%)
      effectColor: bestEffect,
    );
  } catch (e) {
    return _defaultColors();
  }
}

int _toFullArgb(int rgb) {
  return 0xFF000000 | rgb;
}

ValidColors _defaultColors() {
  return ValidColors(
    primaryColor: 0xFFFFFFFF,
    backgroundColor: 0x99000000,
    effectColor: 0xFFFFFFFF,
  );
}

class _Cluster {
  int sumR = 0;
  int sumG = 0;
  int sumB = 0;
  int count = 0;

  void addPixel(int r, int g, int b) {
    sumR += r;
    sumG += g;
    sumB += b;
    count++;
  }

  int getAverageColor() {
    if (count == 0) return 0;
    int r = sumR ~/ count;
    int g = sumG ~/ count;
    int b = sumB ~/ count;
    return (r << 16) | (g << 8) | b;
  }
}
