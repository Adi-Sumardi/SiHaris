import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/core/services/face_recognition_service.dart';

void main() {
  group('RecognitionEmbedding', () {
    test('should create RecognitionEmbedding with location and embedding', () {
      // Arrange
      const location = Rect.fromLTWH(10, 20, 100, 100);
      final embedding = List<double>.generate(192, (i) => i * 0.01);

      // Act
      final result = RecognitionEmbedding(location, embedding);

      // Assert
      expect(result.location, equals(location));
      expect(result.embedding, equals(embedding));
      expect(result.embedding.length, equals(192));
    });

    test('should handle empty embedding list', () {
      // Arrange
      const location = Rect.fromLTWH(0, 0, 50, 50);
      final embedding = <double>[];

      // Act
      final result = RecognitionEmbedding(location, embedding);

      // Assert
      expect(result.embedding.isEmpty, isTrue);
    });
  });

  group('FaceValidationResult', () {
    test('should create FaceValidationResult with isValid true', () {
      // Arrange & Act
      final result = FaceValidationResult(isValid: true, distance: 0.5);

      // Assert
      expect(result.isValid, isTrue);
      expect(result.distance, equals(0.5));
    });

    test('should create FaceValidationResult with isValid false', () {
      // Arrange & Act
      final result = FaceValidationResult(isValid: false, distance: 1.5);

      // Assert
      expect(result.isValid, isFalse);
      expect(result.distance, equals(1.5));
    });

    test('toString should return formatted string', () {
      // Arrange
      final result = FaceValidationResult(isValid: true, distance: 0.8765);

      // Act
      final str = result.toString();

      // Assert
      expect(str, contains('isValid: true'));
      expect(str, contains('distance: 0.8765'));
    });
  });

  group('PairEmbedding', () {
    test('should create PairEmbedding with distance', () {
      // Arrange & Act
      final pair = PairEmbedding(0.75);

      // Assert
      expect(pair.distance, equals(0.75));
    });

    test('should allow distance to be modified', () {
      // Arrange
      final pair = PairEmbedding(-5);

      // Act
      pair.distance = 0.5;

      // Assert
      expect(pair.distance, equals(0.5));
    });
  });

  group('FaceEmbeddingMatcher', () {
    group('Constants', () {
      test('embeddingSize should be 192', () {
        expect(FaceEmbeddingMatcher.embeddingSize, equals(192));
      });

      test('defaultThreshold should be 1.0', () {
        expect(FaceEmbeddingMatcher.defaultThreshold, equals(1.0));
      });
    });

    group('findNearest (Euclidean Distance)', () {
      test('should return 0 distance for identical embeddings', () {
        // Arrange
        final emb1 = List<double>.generate(192, (i) => 0.5);
        final emb2 = List<double>.generate(192, (i) => 0.5);

        // Act
        final result = FaceEmbeddingMatcher.findNearest(emb1, emb2);

        // Assert
        expect(result.distance, closeTo(0.0, 0.0001));
      });

      test('should return correct distance for different embeddings', () {
        // Arrange
        final emb1 = List<double>.filled(192, 0.0);
        final emb2 = List<double>.filled(192, 1.0);

        // Expected: sqrt(192 * 1^2) = sqrt(192) ≈ 13.856
        final expectedDistance = 13.8564; // sqrt(192)

        // Act
        final result = FaceEmbeddingMatcher.findNearest(emb1, emb2);

        // Assert
        expect(result.distance, closeTo(expectedDistance, 0.01));
      });

      test('should return distance < 1.0 for similar embeddings', () {
        // Arrange - embeddings with small differences
        final emb1 = List<double>.generate(192, (i) => 0.5);
        final emb2 = List<double>.generate(
          192,
          (i) => 0.5 + (i % 10 == 0 ? 0.05 : 0.0),
        );

        // Act
        final result = FaceEmbeddingMatcher.findNearest(emb1, emb2);

        // Assert
        expect(result.distance, lessThan(1.0));
      });

      test('should return distance > 1.0 for very different embeddings', () {
        // Arrange - embeddings with large differences
        final emb1 = List<double>.generate(192, (i) => -1.0);
        final emb2 = List<double>.generate(192, (i) => 1.0);

        // Act
        final result = FaceEmbeddingMatcher.findNearest(emb1, emb2);

        // Assert
        expect(result.distance, greaterThan(1.0));
      });

      test('should handle embeddings with negative values', () {
        // Arrange
        final emb1 = List<double>.generate(192, (i) => -0.5);
        final emb2 = List<double>.generate(192, (i) => 0.5);

        // Expected: sqrt(192 * 1.0^2) = sqrt(192) ≈ 13.856
        final expectedDistance = 13.8564;

        // Act
        final result = FaceEmbeddingMatcher.findNearest(emb1, emb2);

        // Assert
        expect(result.distance, closeTo(expectedDistance, 0.01));
      });
    });

    group('validateFaceMatch', () {
      test('should return valid for distance < threshold', () {
        // Arrange
        final currentEmbedding = List<double>.filled(192, 0.5);
        final registeredEmbedding = List<double>.filled(192, 0.5);

        // Act
        final result = FaceEmbeddingMatcher.validateFaceMatch(
          currentEmbedding: currentEmbedding,
          registeredEmbedding: registeredEmbedding,
        );

        // Assert
        expect(result.isValid, isTrue);
        expect(result.distance, closeTo(0.0, 0.0001));
      });

      test('should return invalid for distance >= threshold', () {
        // Arrange - very different embeddings
        final currentEmbedding = List<double>.filled(192, -1.0);
        final registeredEmbedding = List<double>.filled(192, 1.0);

        // Act
        final result = FaceEmbeddingMatcher.validateFaceMatch(
          currentEmbedding: currentEmbedding,
          registeredEmbedding: registeredEmbedding,
        );

        // Assert
        expect(result.isValid, isFalse);
        expect(result.distance, greaterThan(1.0));
      });

      test('should use custom threshold when provided', () {
        // Arrange
        final currentEmbedding = List<double>.generate(192, (i) => 0.5);
        final registeredEmbedding = List<double>.generate(
          192,
          (i) => 0.5 + (i % 5 == 0 ? 0.1 : 0.0),
        );

        // Act - with low threshold
        final resultLowThreshold = FaceEmbeddingMatcher.validateFaceMatch(
          currentEmbedding: currentEmbedding,
          registeredEmbedding: registeredEmbedding,
          threshold: 0.1,
        );

        // Act - with high threshold
        final resultHighThreshold = FaceEmbeddingMatcher.validateFaceMatch(
          currentEmbedding: currentEmbedding,
          registeredEmbedding: registeredEmbedding,
          threshold: 5.0,
        );

        // Assert
        expect(resultLowThreshold.isValid, isFalse);
        expect(resultHighThreshold.isValid, isTrue);
      });

      test('should return invalid when registered embedding is null', () {
        // Arrange
        final currentEmbedding = List<double>.filled(192, 0.5);

        // Act
        final result = FaceEmbeddingMatcher.validateFaceMatch(
          currentEmbedding: currentEmbedding,
          registeredEmbedding: null,
        );

        // Assert
        expect(result.isValid, isFalse);
        expect(result.distance, equals(-1.0));
      });

      test('should return invalid when registered embedding is empty', () {
        // Arrange
        final currentEmbedding = List<double>.filled(192, 0.5);

        // Act
        final result = FaceEmbeddingMatcher.validateFaceMatch(
          currentEmbedding: currentEmbedding,
          registeredEmbedding: [],
        );

        // Assert
        expect(result.isValid, isFalse);
        expect(result.distance, equals(-1.0));
      });
    });

    group('parseEmbeddingString', () {
      test('should parse comma-separated embedding string', () {
        // Arrange
        final embeddingValues = List<double>.generate(192, (i) => i * 0.01);
        final embeddingString = embeddingValues.join(',');

        // Act
        final result =
            FaceEmbeddingMatcher.parseEmbeddingString(embeddingString);

        // Assert
        expect(result, isNotNull);
        expect(result!.length, equals(192));
        expect(result[0], closeTo(0.0, 0.0001));
        expect(result[1], closeTo(0.01, 0.0001));
        expect(result[191], closeTo(1.91, 0.0001));
      });

      test('should return null for null input', () {
        // Act
        final result = FaceEmbeddingMatcher.parseEmbeddingString(null);

        // Assert
        expect(result, isNull);
      });

      test('should return null for empty string', () {
        // Act
        final result = FaceEmbeddingMatcher.parseEmbeddingString('');

        // Assert
        expect(result, isNull);
      });

      test('should handle whitespace in embedding string', () {
        // Arrange
        final embeddingString = '0.1, 0.2, 0.3, 0.4, 0.5';

        // Act
        final result =
            FaceEmbeddingMatcher.parseEmbeddingString(embeddingString);

        // Assert
        expect(result, isNotNull);
        expect(result!.length, equals(5));
        expect(result[0], closeTo(0.1, 0.0001));
        expect(result[4], closeTo(0.5, 0.0001));
      });

      test('should return null for invalid format', () {
        // Arrange
        final embeddingString = 'invalid,data,here';

        // Act
        final result =
            FaceEmbeddingMatcher.parseEmbeddingString(embeddingString);

        // Assert
        expect(result, isNull);
      });
    });

    group('embeddingToString', () {
      test('should convert embedding list to comma-separated string', () {
        // Arrange
        final embedding = [0.1, 0.2, 0.3];

        // Act
        final result = FaceEmbeddingMatcher.embeddingToString(embedding);

        // Assert
        expect(result, equals('0.1,0.2,0.3'));
      });

      test('should handle empty list', () {
        // Act
        final result = FaceEmbeddingMatcher.embeddingToString([]);

        // Assert
        expect(result, equals(''));
      });

      test('should handle negative values', () {
        // Arrange
        final embedding = [-0.5, 0.0, 0.5];

        // Act
        final result = FaceEmbeddingMatcher.embeddingToString(embedding);

        // Assert
        expect(result, equals('-0.5,0.0,0.5'));
      });
    });

    group('calculateSimilarityPercentage', () {
      test('should return 100% for distance 0', () {
        // Act
        final result = FaceEmbeddingMatcher.calculateSimilarityPercentage(0.0);

        // Assert
        expect(result, closeTo(100.0, 0.01));
      });

      test('should return 50% for distance 1.0', () {
        // Act
        final result = FaceEmbeddingMatcher.calculateSimilarityPercentage(1.0);

        // Assert
        expect(result, closeTo(50.0, 0.01));
      });

      test('should return 0% for distance 2.0', () {
        // Act
        final result = FaceEmbeddingMatcher.calculateSimilarityPercentage(2.0);

        // Assert
        expect(result, closeTo(0.0, 0.01));
      });

      test('should not return negative percentage', () {
        // Act
        final result = FaceEmbeddingMatcher.calculateSimilarityPercentage(5.0);

        // Assert
        expect(result, greaterThanOrEqualTo(0.0));
      });
    });

    group('isEmbeddingValid', () {
      test('should return true for valid 192-dim embedding', () {
        // Arrange
        final embedding = List<double>.generate(192, (i) => i * 0.01);

        // Act
        final result = FaceEmbeddingMatcher.isEmbeddingValid(embedding);

        // Assert
        expect(result, isTrue);
      });

      test('should return false for null embedding', () {
        // Act
        final result = FaceEmbeddingMatcher.isEmbeddingValid(null);

        // Assert
        expect(result, isFalse);
      });

      test('should return false for wrong size embedding', () {
        // Arrange
        final embedding = List<double>.generate(100, (i) => i * 0.01);

        // Act
        final result = FaceEmbeddingMatcher.isEmbeddingValid(embedding);

        // Assert
        expect(result, isFalse);
      });

      test('should return false for all-zero embedding', () {
        // Arrange
        final embedding = List<double>.filled(192, 0.0);

        // Act
        final result = FaceEmbeddingMatcher.isEmbeddingValid(embedding);

        // Assert
        expect(result, isFalse);
      });

      test('should return true for embedding with some zeros', () {
        // Arrange
        final embedding = List<double>.generate(
          192,
          (i) => i % 2 == 0 ? 0.0 : 0.5,
        );

        // Act
        final result = FaceEmbeddingMatcher.isEmbeddingValid(embedding);

        // Assert
        expect(result, isTrue);
      });
    });

    group('createEmptyEmbedding', () {
      test('should create 192-dim zero embedding', () {
        // Act
        final result = FaceEmbeddingMatcher.createEmptyEmbedding();

        // Assert
        expect(result.length, equals(192));
        expect(result.every((v) => v == 0.0), isTrue);
      });
    });
  });

  group('Image Preprocessing (imageToArray logic)', () {
    // Note: These tests verify the normalization formula without actual image

    test('normalization formula should map 0 to -1.0', () {
      // Formula: (value - 127.5) / 127.5
      final normalized = (0 - 127.5) / 127.5;
      expect(normalized, closeTo(-1.0, 0.01));
    });

    test('normalization formula should map 127 to ~0', () {
      // Formula: (value - 127.5) / 127.5
      final normalized = (127 - 127.5) / 127.5;
      expect(normalized, closeTo(0.0, 0.01));
    });

    test('normalization formula should map 255 to ~1.0', () {
      // Formula: (value - 127.5) / 127.5
      final normalized = (255 - 127.5) / 127.5;
      expect(normalized, closeTo(1.0, 0.01));
    });
  });

  group('FaceRecognitionService Constants', () {
    test('width should be 112', () {
      expect(FaceRecognitionService.width, equals(112));
    });

    test('height should be 112', () {
      expect(FaceRecognitionService.height, equals(112));
    });

    test('embeddingSize should be 192', () {
      expect(FaceRecognitionService.embeddingSize, equals(192));
    });

    test('defaultThreshold should be 1.0', () {
      expect(FaceRecognitionService.defaultThreshold, equals(1.0));
    });
  });
}
