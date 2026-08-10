import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/core/utils/image_normalization_util.dart';

void main() {
  group('ImageNormalizationUtil', () {
    group('extractYPlaneWithoutPadding', () {
      test('should return same bytes when no padding', () {
        // Arrange
        final width = 4;
        final height = 4;
        final yPlane = Uint8List.fromList(List.generate(16, (i) => i));
        final yRowStride = 4; // No padding

        // Act
        final result = ImageNormalizationUtil.extractYPlaneWithoutPadding(
          yPlane,
          yRowStride,
          width,
          height,
        );

        // Assert
        expect(result, equals(yPlane));
      });

      test('should extract Y plane skipping padding bytes', () {
        // Arrange - simulate CPH2365 issue with padding
        final width = 4;
        final height = 2;
        final yRowStride = 6; // 4 pixels + 2 padding

        // Create plane with padding: [0,1,2,3,P,P,4,5,6,7,P,P]
        final yPlane = Uint8List.fromList([
          0, 1, 2, 3, 255, 255, // Row 0 + padding
          4, 5, 6, 7, 255, 255, // Row 1 + padding
        ]);

        // Act
        final result = ImageNormalizationUtil.extractYPlaneWithoutPadding(
          yPlane,
          yRowStride,
          width,
          height,
        );

        // Assert - should only contain actual pixels
        expect(result.length, equals(8)); // width * height
        expect(result, equals(Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7])));
      });

      test('should handle larger padding (CPH2365: stride=1536, width=1280)', () {
        // Arrange - simulate actual CPH2365 dimensions (scaled down)
        final width = 128;
        final height = 2;
        final yRowStride = 154; // 128 pixels + 26 padding

        // Create plane with actual pixel values
        final List<int> planeData = [];
        for (int row = 0; row < height; row++) {
          for (int col = 0; col < width; col++) {
            planeData.add((row * width + col) % 256);
          }
          // Add padding bytes
          for (int p = 0; p < (yRowStride - width); p++) {
            planeData.add(0xFF);
          }
        }
        final yPlane = Uint8List.fromList(planeData);

        // Act
        final result = ImageNormalizationUtil.extractYPlaneWithoutPadding(
          yPlane,
          yRowStride,
          width,
          height,
        );

        // Assert
        expect(result.length, equals(width * height));

        // First row should start with 0,1,2,...
        expect(result[0], equals(0));
        expect(result[1], equals(1));
        expect(result[127], equals(127));

        // Second row should continue from previous
        expect(result[128], equals((1 * 128) % 256));
      });
    });

    group('calculateImageStats', () {
      test('should calculate correct stats for uniform image', () {
        // Arrange
        final yPlane = Uint8List.fromList(List.filled(100, 128));

        // Act
        final stats = ImageNormalizationUtil.calculateImageStats(yPlane);

        // Assert
        expect(double.parse(stats['avg_brightness'] as String), closeTo(128.0, 0.01));
        expect(stats['min'], equals(128));
        expect(stats['max'], equals(128));
        expect(stats['contrast'], equals(0));
      });

      test('should calculate correct stats for varied image', () {
        // Arrange - values 0 to 99
        final yPlane = Uint8List.fromList(List.generate(100, (i) => i));

        // Act
        final stats = ImageNormalizationUtil.calculateImageStats(yPlane);

        // Assert
        expect(double.parse(stats['avg_brightness'] as String), closeTo(49.5, 0.01));
        expect(stats['min'], equals(0));
        expect(stats['max'], equals(99));
        expect(stats['contrast'], equals(99));
      });

      test('should handle extreme values', () {
        // Arrange
        final yPlane = Uint8List.fromList([0, 255]);

        // Act
        final stats = ImageNormalizationUtil.calculateImageStats(yPlane);

        // Assert
        expect(stats['min'], equals(0));
        expect(stats['max'], equals(255));
        expect(stats['contrast'], equals(255));
      });
    });

    group('normalizeYPlane (Histogram Equalization)', () {
      test('should not change uniform image significantly', () {
        // Arrange - all pixels same value
        final width = 10;
        final height = 10;
        final yPlane = Uint8List.fromList(List.filled(100, 128));

        // Act
        final result = ImageNormalizationUtil.normalizeYPlane(
          yPlane,
          width,
          height,
        );

        // Assert
        expect(result.length, equals(100));
        // With contrast limiting (0.7 blend), values should stay close to original
        for (int i = 0; i < result.length; i++) {
          expect(result[i], closeTo(128, 50)); // Allow some variation
        }
      });

      test('should increase contrast for low-contrast image', () {
        // Arrange - narrow range 100-110
        final width = 10;
        final height = 10;
        final yPlane = Uint8List.fromList(
          List.generate(100, (i) => 100 + (i % 11)),
        );

        // Calculate original contrast
        int origMin = 255, origMax = 0;
        for (var v in yPlane) {
          if (v < origMin) origMin = v;
          if (v > origMax) origMax = v;
        }
        final originalContrast = origMax - origMin;

        // Act
        final result = ImageNormalizationUtil.normalizeYPlane(
          yPlane,
          width,
          height,
        );

        // Calculate new contrast
        int newMin = 255, newMax = 0;
        for (var v in result) {
          if (v < newMin) newMin = v;
          if (v > newMax) newMax = v;
        }
        final newContrast = newMax - newMin;

        // Assert - contrast should increase
        expect(newContrast, greaterThan(originalContrast));
      });

      test('should handle very bright image', () {
        // Arrange - all values near 255
        final width = 5;
        final height = 5;
        final yPlane = Uint8List.fromList(List.filled(25, 250));

        // Act
        final result = ImageNormalizationUtil.normalizeYPlane(
          yPlane,
          width,
          height,
        );

        // Assert - should not exceed 255
        expect(result.every((v) => v <= 255), isTrue);
        expect(result.every((v) => v >= 0), isTrue);
      });

      test('should handle very dark image', () {
        // Arrange - all values near 0
        final width = 5;
        final height = 5;
        final yPlane = Uint8List.fromList(List.filled(25, 5));

        // Act
        final result = ImageNormalizationUtil.normalizeYPlane(
          yPlane,
          width,
          height,
        );

        // Assert - should not go below 0
        expect(result.every((v) => v >= 0), isTrue);
        expect(result.every((v) => v <= 255), isTrue);
      });
    });

    group('simpleNormalizeBrightness', () {
      test('should brighten dark image', () {
        // Arrange - dark image (avg ~50)
        final width = 10;
        final height = 10;
        final yPlane = Uint8List.fromList(List.filled(100, 50));

        // Act
        final result = ImageNormalizationUtil.simpleNormalizeBrightness(
          yPlane,
          width,
          height,
        );

        // Assert - should be brighter (closer to 128)
        final avgOriginal = yPlane.reduce((a, b) => a + b) / yPlane.length;
        final avgNormalized = result.reduce((a, b) => a + b) / result.length;

        expect(avgNormalized, greaterThan(avgOriginal));
      });

      test('should darken bright image', () {
        // Arrange - bright image (avg ~200)
        final width = 10;
        final height = 10;
        final yPlane = Uint8List.fromList(List.filled(100, 200));

        // Act
        final result = ImageNormalizationUtil.simpleNormalizeBrightness(
          yPlane,
          width,
          height,
        );

        // Assert - should be darker (closer to 128)
        final avgOriginal = yPlane.reduce((a, b) => a + b) / yPlane.length;
        final avgNormalized = result.reduce((a, b) => a + b) / result.length;

        expect(avgNormalized, lessThan(avgOriginal));
      });

      test('should not change neutral image much', () {
        // Arrange - neutral image (avg ~128)
        final width = 10;
        final height = 10;
        final yPlane = Uint8List.fromList(List.filled(100, 128));

        // Act
        final result = ImageNormalizationUtil.simpleNormalizeBrightness(
          yPlane,
          width,
          height,
        );

        // Assert - should stay close to 128
        final avgNormalized = result.reduce((a, b) => a + b) / result.length;
        expect(avgNormalized, closeTo(128, 5));
      });

      test('should clamp values to 0-255 range', () {
        // Arrange - extreme values
        final width = 2;
        final height = 2;
        final yPlane = Uint8List.fromList([0, 0, 255, 255]);

        // Act
        final result = ImageNormalizationUtil.simpleNormalizeBrightness(
          yPlane,
          width,
          height,
        );

        // Assert
        expect(result.every((v) => v >= 0 && v <= 255), isTrue);
      });
    });

    group('NV21 Reconstruction', () {
      test('should create NV21 with correct size', () {
        // Arrange
        final width = 8;
        final height = 8;
        final yPlane = Uint8List.fromList(List.filled(64, 128));
        final uvPlane = Uint8List.fromList(List.filled(32, 128));

        // Act
        final result = ImageNormalizationUtil.reconstructNV21(
          yPlane,
          uvPlane,
          width,
          height,
        );

        // Assert
        // NV21 = Y (width*height) + UV interleaved (width*height/2)
        expect(result.length, equals(width * height + (width * height ~/ 2)));
      });

      test('should preserve Y plane in output', () {
        // Arrange
        final width = 4;
        final height = 4;
        final yPlane = Uint8List.fromList(List.generate(16, (i) => i));
        final uvPlane = Uint8List.fromList(List.filled(8, 128));

        // Act
        final result = ImageNormalizationUtil.reconstructNV21(
          yPlane,
          uvPlane,
          width,
          height,
        );

        // Assert - first width*height bytes should be Y plane
        for (int i = 0; i < 16; i++) {
          expect(result[i], equals(i));
        }
      });

      test('should handle UV plane correctly', () {
        // Arrange
        final width = 4;
        final height = 4;
        final yPlane = Uint8List.fromList(List.filled(16, 100));
        final uvPlane = Uint8List.fromList([
          64, 192, // First chroma pair
          64, 192, // Second chroma pair
          64, 192, // Third chroma pair
          64, 192, // Fourth chroma pair
        ]);

        // Act
        final result = ImageNormalizationUtil.reconstructNV21(
          yPlane,
          uvPlane,
          width,
          height,
        );

        // Assert - UV should be after Y plane
        expect(result[16], equals(64)); // First V
        expect(result[17], equals(192)); // First U
      });
    });
  });
}
