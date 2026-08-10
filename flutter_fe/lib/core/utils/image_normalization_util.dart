import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Utility untuk normalize image yang kena AI Beauty processing
/// Khusus untuk devices seperti OPPO ColorOS 13, Xiaomi MIUI 13, Vivo, dll
/// yang memiliki aggressive AI face enhancement
class ImageNormalizationUtil {
  /// Normalize YUV image untuk reduce AI Beauty effect
  /// Returns: { 'nv21_bytes': Uint8List, 'duration_ms': int, ... }
  static Map<String, dynamic> normalizeYUVImage(CameraImage image) {
    final startTime = DateTime.now();

    final width = image.width;
    final height = image.height;

    final yPlane = image.planes[0].bytes;
    final yRowStride = image.planes[0].bytesPerRow;
    final uPlane = image.planes[1].bytes;
    final vPlane = image.planes[2].bytes;

    // Extract Y plane dengan padding handling untuk CPH2365
    final yPlaneWithoutPadding = extractYPlaneWithoutPadding(
      yPlane,
      yRowStride,
      width,
      height,
    );

    final originalStats = calculateImageStats(yPlaneWithoutPadding);
    final normalizedY = normalizeYPlane(yPlaneWithoutPadding, width, height);
    final normalizedStats = calculateImageStats(normalizedY);

    // Reconstruct NV21 format: Y + interleaved VU
    final nv21 = Uint8List(width * height + (width * height ~/ 2));
    nv21.setRange(0, width * height, normalizedY);

    int offset = width * height;
    final chromaRowStride = image.planes[1].bytesPerRow;
    final chromaPixelStride = image.planes[1].bytesPerPixel!;

    for (int row = 0; row < height ~/ 2; row++) {
      for (int col = 0; col < width ~/ 2; col++) {
        final idx = row * chromaRowStride + col * chromaPixelStride;

        if (idx < vPlane.length && idx < uPlane.length) {
          nv21[offset++] = vPlane[idx];
          nv21[offset++] = uPlane[idx];
        } else {
          nv21[offset++] = 128;
          nv21[offset++] = 128;
        }
      }
    }

    final duration = DateTime.now().difference(startTime).inMilliseconds;

    return {
      'nv21_bytes': nv21,
      'duration_ms': duration,
      'original_stats': originalStats,
      'normalized_stats': normalizedStats,
    };
  }

  /// Extract Y plane without padding (CRITICAL FIX for CPH2365)
  ///
  /// CPH2365 has bytesPerRow=1536 but width=1280, so we need to skip padding
  static Uint8List extractYPlaneWithoutPadding(
    Uint8List yPlane,
    int yRowStride,
    int width,
    int height,
  ) {
    // If no padding, return as-is
    if (yRowStride == width) {
      return yPlane;
    }

    // Log padding detection (only in debug mode)
    if (kDebugMode) {
      developer.log('[ImageNormalization] Y PLANE PADDING DETECTED!');
      developer.log(
        '  bytesPerRow=$yRowStride > width=$width (padding: ${yRowStride - width} bytes)',
      );
      developer.log(
        '[ImageNormalization] Extracting Y plane row-by-row to skip padding',
      );
    }

    // Has padding - need to extract row by row
    final extracted = Uint8List(width * height);
    int dstOffset = 0;

    for (int row = 0; row < height; row++) {
      final srcOffset = row * yRowStride;
      extracted.setRange(dstOffset, dstOffset + width, yPlane, srcOffset);
      dstOffset += width;
    }

    return extracted;
  }

  /// Calculate image statistics untuk logging
  static Map<String, dynamic> calculateImageStats(Uint8List yPlane) {
    int sum = 0;
    int min = 255;
    int max = 0;

    for (int i = 0; i < yPlane.length; i++) {
      final value = yPlane[i];
      sum += value;
      if (value < min) min = value;
      if (value > max) max = value;
    }

    final avgBrightness = sum / yPlane.length;
    final contrast = max - min;

    return {
      'avg_brightness': avgBrightness.toStringAsFixed(2),
      'min': min,
      'max': max,
      'contrast': contrast,
    };
  }

  /// Normalize Y plane (brightness) untuk counter AI Beauty effect
  ///
  /// AI Beauty biasanya:
  /// - Smoothing berlebihan (reduce contrast)
  /// - Brighten skin tones
  /// - Soften details
  ///
  /// Solution:
  /// - Contrast Limited Adaptive Histogram Equalization (CLAHE)
  /// - Restore local contrast
  static Uint8List normalizeYPlane(Uint8List yPlane, int width, int height) {
    final normalized = Uint8List(yPlane.length);

    // ========================================
    // STEP 1: Calculate histogram
    // ========================================
    final histogram = List<int>.filled(256, 0);
    for (int i = 0; i < yPlane.length; i++) {
      histogram[yPlane[i]]++;
    }

    // ========================================
    // STEP 2: Calculate cumulative distribution (CDF)
    // ========================================
    final cdf = List<int>.filled(256, 0);
    cdf[0] = histogram[0];
    for (int i = 1; i < 256; i++) {
      cdf[i] = cdf[i - 1] + histogram[i];
    }

    // ========================================
    // STEP 3: Normalize CDF untuk histogram equalization
    // ========================================
    final cdfMin = cdf.firstWhere((value) => value > 0);
    final totalPixels = width * height;

    final lookupTable = List<int>.filled(256, 0);
    for (int i = 0; i < 256; i++) {
      // Histogram equalization formula
      if (totalPixels > cdfMin) {
        final normalizedVal =
            ((cdf[i] - cdfMin) * 255) ~/ (totalPixels - cdfMin);
        lookupTable[i] = normalizedVal.clamp(0, 255);
      } else {
        lookupTable[i] = i;
      }
    }

    // ========================================
    // STEP 4: Apply contrast limiting (CLAHE-like)
    // ========================================
    // Limit contrast boost untuk avoid over-enhancement
    const double contrastLimit =
        0.7; // 0.0 = no change, 1.0 = full equalization

    for (int i = 0; i < yPlane.length; i++) {
      final originalValue = yPlane[i];
      final equalizedValue = lookupTable[originalValue];

      // Blend original dengan equalized (soft normalization)
      final blended =
          (originalValue * (1 - contrastLimit) + equalizedValue * contrastLimit)
              .round();

      normalized[i] = blended.clamp(0, 255);
    }

    return normalized;
  }

  /// Simple brightness normalization (faster, less aggressive)
  /// Hanya adjust brightness menuju neutral (128)
  static Uint8List simpleNormalizeBrightness(
    Uint8List yPlane,
    int width,
    int height,
  ) {
    // Calculate average brightness
    int sum = 0;
    for (int i = 0; i < yPlane.length; i++) {
      sum += yPlane[i];
    }
    final avgBrightness = sum ~/ yPlane.length;

    // Adjust brightness towards neutral (128)
    const targetBrightness = 128;
    final adjustment = targetBrightness - avgBrightness;

    // Create adjusted Y plane
    final adjustedY = Uint8List(yPlane.length);
    for (int i = 0; i < yPlane.length; i++) {
      final adjusted = yPlane[i] + (adjustment * 0.3).round();
      adjustedY[i] = adjusted.clamp(0, 255);
    }

    return adjustedY;
  }

  /// Reconstruct NV21 format from Y and UV planes
  ///
  /// NV21 format: Y plane followed by interleaved VU chroma
  static Uint8List reconstructNV21(
    Uint8List yPlane,
    Uint8List uvPlane,
    int width,
    int height,
  ) {
    // NV21 = Y (width*height) + UV interleaved (width*height/2)
    final nv21 = Uint8List(width * height + (width * height ~/ 2));

    // Copy Y plane
    nv21.setRange(0, width * height, yPlane);

    // Copy UV plane (already interleaved VU)
    nv21.setRange(width * height, nv21.length, uvPlane);

    return nv21;
  }

  /// Safe bounds check for UV plane copy
  /// Returns neutral UV value (128) if out of bounds
  static int safeGetUV(Uint8List plane, int index) {
    if (index < plane.length) {
      return plane[index];
    }
    return 128; // Neutral UV
  }
}
