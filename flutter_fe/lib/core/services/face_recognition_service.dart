import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Result of face validation containing isValid status and distance score
class FaceValidationResult {
  final bool isValid;
  final double distance;

  FaceValidationResult({required this.isValid, required this.distance});

  @override
  String toString() =>
      'FaceValidationResult(isValid: $isValid, distance: $distance)';
}

/// Face embedding with location information
class RecognitionEmbedding {
  Rect location;
  List<double> embedding;

  RecognitionEmbedding(this.location, this.embedding);
}

/// Pair embedding result with distance
class PairEmbedding {
  double distance;
  PairEmbedding(this.distance);
}

/// Face embedding matching utilities (no TFLite dependency)
///
/// Contains pure Dart logic for:
/// - Euclidean distance calculation
/// - Embedding validation
/// - String parsing/formatting
/// - Similarity calculation
///
/// This class can be tested without TFLite native library
class FaceEmbeddingMatcher {
  // Output embedding size
  static const int embeddingSize = 192;

  // Default threshold for face matching
  // Distance < threshold = match
  static const double defaultThreshold = 1.0;

  /// Calculate Euclidean distance between two embeddings
  ///
  /// [emb] - Current face embedding
  /// [authFaceEmbedding] - Registered/authorized face embedding
  ///
  /// Returns PairEmbedding with calculated distance
  static PairEmbedding findNearest(
    List<double> emb,
    List<double> authFaceEmbedding,
  ) {
    PairEmbedding pair = PairEmbedding(-5);

    double distance = 0;
    for (int i = 0; i < emb.length; i++) {
      double diff = emb[i] - authFaceEmbedding[i];
      distance += diff * diff;
    }
    distance = sqrt(distance);

    if (pair.distance == -5 || distance < pair.distance) {
      pair.distance = distance;
    }

    return pair;
  }

  /// Validate face match between current and registered embedding
  ///
  /// [currentEmbedding] - Embedding from current face capture
  /// [registeredEmbedding] - Stored embedding from registration
  /// [threshold] - Match threshold (default: 1.0, lower = stricter)
  ///
  /// Returns FaceValidationResult with isValid and distance
  static FaceValidationResult validateFaceMatch({
    required List<double> currentEmbedding,
    List<double>? registeredEmbedding,
    double threshold = defaultThreshold,
  }) {
    // Check if registered embedding exists
    if (registeredEmbedding == null || registeredEmbedding.isEmpty) {
      if (kDebugMode) {
        developer.log(
          '[FaceEmbeddingMatcher] No registered face embedding found!',
        );
      }
      return FaceValidationResult(isValid: false, distance: -1);
    }

    // Calculate distance
    final pair = findNearest(currentEmbedding, registeredEmbedding);
    final distance = pair.distance;
    final isValid = distance < threshold;

    if (kDebugMode) {
      final similarity = calculateSimilarityPercentage(distance);

      developer.log('');
      developer.log('========================================');
      developer.log('FACE RECOGNITION RESULT');
      developer.log('========================================');
      developer.log('Threshold: $threshold');
      developer.log('Distance: ${distance.toStringAsFixed(4)}');
      developer.log('Similarity: ${similarity.toStringAsFixed(2)}%');
      developer.log(
        'Gap: ${(distance - threshold).toStringAsFixed(4)} '
        '(${distance > threshold ? 'OVER' : 'UNDER'} threshold)',
      );
      developer.log('----------------------------------------');

      if (isValid) {
        developer.log('RESULT: VALID (distance < threshold)');
        final margin = threshold - distance;
        if (margin < 0.1) {
          developer.log('  Close call! Margin: ${margin.toStringAsFixed(4)}');
        } else {
          developer.log('  Good match! Margin: ${margin.toStringAsFixed(4)}');
        }
      } else {
        developer.log('RESULT: INVALID (distance >= threshold)');
        developer.log(
          '  Difference: ${(distance - threshold).toStringAsFixed(4)}',
        );
      }
      developer.log('========================================');
      developer.log('');
    }

    return FaceValidationResult(isValid: isValid, distance: distance);
  }

  /// Parse embedding string (comma-separated) to list of doubles
  ///
  /// [embeddingString] - Comma-separated string of 192 double values
  ///
  /// Returns list of doubles or null if parsing fails
  static List<double>? parseEmbeddingString(String? embeddingString) {
    if (embeddingString == null || embeddingString.isEmpty) {
      return null;
    }

    try {
      return embeddingString
          .split(',')
          .map((e) => double.parse(e.trim()))
          .toList()
          .cast<double>();
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          '[FaceEmbeddingMatcher] Failed to parse embedding string: $e',
        );
      }
      return null;
    }
  }

  /// Convert embedding list to comma-separated string
  ///
  /// [embedding] - List of 192 double values
  ///
  /// Returns comma-separated string for storage
  static String embeddingToString(List<double> embedding) {
    return embedding.join(',');
  }

  /// Calculate similarity percentage from distance
  ///
  /// [distance] - Euclidean distance between embeddings
  ///
  /// Returns percentage (0-100) where higher = more similar
  static double calculateSimilarityPercentage(double distance) {
    // Rough approximation: distance of 2.0 = 0%, distance of 0 = 100%
    final similarity = (1 - (distance / 2)) * 100;
    return similarity.clamp(0.0, 100.0);
  }

  /// Check if embedding is valid (non-null, correct size, not all zeros)
  ///
  /// [embedding] - Embedding to validate
  ///
  /// Returns true if embedding is valid for comparison
  static bool isEmbeddingValid(List<double>? embedding) {
    if (embedding == null) return false;
    if (embedding.length != embeddingSize) return false;

    // Check if all values are zero (corrupted/invalid embedding)
    final allZeros = embedding.every((val) => val == 0.0);
    if (allZeros) return false;

    return true;
  }

  /// Create empty (zero-filled) embedding
  ///
  /// Used as fallback when model is not loaded
  static List<double> createEmptyEmbedding() {
    return List.filled(embeddingSize, 0.0);
  }
}

/// Face Recognition Service using TFLite MobileFaceNet model
///
/// This service handles:
/// - Loading TFLite model for face embedding generation
/// - Converting images to model input format
/// - Generating 192-dimensional face embeddings
/// - Comparing embeddings using Euclidean distance
/// - Validating face matches against threshold
///
/// Usage:
/// ```dart
/// final service = FaceRecognitionService();
/// await service.loadModel();
///
/// // Generate embedding from image
/// final embedding = service.recognize(image, faceRect);
///
/// // Compare embeddings
/// final result = service.validateFaceMatch(
///   currentEmbedding: embedding.embedding,
///   registeredEmbedding: storedEmbedding,
/// );
///
/// if (result.isValid) {
///   print('Face matched! Distance: ${result.distance}');
/// }
/// ```
class FaceRecognitionService {
  Interpreter? interpreter;
  late InterpreterOptions _interpreterOptions;

  // Model input dimensions
  static const int width = 112;
  static const int height = 112;

  // Output embedding size
  static const int embeddingSize = 192;

  // Default threshold for face matching
  // Distance < threshold = match
  static const double defaultThreshold = 1.0;

  // State tracking
  bool isModelLoaded = false;
  String? loadError;

  String get modelName => 'assets/models/mobile_face_net.tflite';

  /// Creates a new FaceRecognitionService instance
  ///
  /// [numThreads] - Number of threads for TFLite inference (default: system default)
  /// [autoLoad] - Whether to automatically load model in constructor (default: true)
  FaceRecognitionService({int? numThreads, bool autoLoad = true}) {
    _interpreterOptions = InterpreterOptions();

    if (numThreads != null) {
      _interpreterOptions.threads = numThreads;
    }

    if (kDebugMode) {
      developer.log('[FaceRecognitionService] Constructor called');
      developer.log('  Threads: ${numThreads ?? "default"}');
    }

    // Load model async with timeout (only if autoLoad is true)
    if (autoLoad) {
      loadModel()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              developer.log(
                '[FaceRecognitionService] TIMEOUT: Model loading took >15 seconds!',
              );
              developer.log('  This usually means:');
              developer.log('  1. Asset file not found/bundled');
              developer.log('  2. TFLite initialization hung');
              developer.log(
                '  Platform: ${Platform.isIOS ? "iOS" : "Android"}',
              );

              isModelLoaded = false;
              loadError = 'Model loading timeout after 15 seconds';

              throw TimeoutException(
                'TFLite model loading timeout after 15 seconds',
                const Duration(seconds: 15),
              );
            },
          )
          .catchError((error, stackTrace) {
            developer.log(
              '[FaceRecognitionService] FATAL: Model loading failed in constructor',
              error: error,
              stackTrace: stackTrace,
            );
          });
    }
  }

  /// Load the TFLite model from assets
  Future<void> loadModel() async {
    try {
      if (kDebugMode) {
        developer.log(
          '[FaceRecognitionService] Starting to load TFLite model: $modelName',
        );
        developer.log(
          '[FaceRecognitionService] Platform: ${Platform.operatingSystem}',
        );
      }

      interpreter = await Interpreter.fromAsset(
        modelName,
        options: _interpreterOptions,
      );

      isModelLoaded = true;

      if (kDebugMode) {
        developer
            .log('[FaceRecognitionService] TFLite model loaded successfully');
        developer.log('  Model: $modelName');
        developer.log('  Input shape: ${interpreter!.getInputTensors()}');
        developer.log('  Output shape: ${interpreter!.getOutputTensors()}');
      }
    } catch (e, stackTrace) {
      isModelLoaded = false;
      loadError = e.toString();

      developer.log(
        '[FaceRecognitionService] CRITICAL: Unable to load TFLite model!',
        error: e,
        stackTrace: stackTrace,
      );

      if (kDebugMode) {
        developer.log('[FaceRecognitionService] TFLite Model Load FAILED');
        developer.log('  Model: $modelName');
        developer.log('  Error: $e');
        developer.log('  Error type: ${e.runtimeType}');
        developer.log('  Platform: ${Platform.operatingSystem}');

        // iOS-specific troubleshooting
        if (Platform.isIOS) {
          developer.log('');
          developer.log('iOS TROUBLESHOOTING:');
          developer.log(
            '  1. Check if mobile_face_net.tflite is in assets/models/',
          );
          developer.log(
            '  2. Check if pubspec.yaml includes assets/models/',
          );
          developer.log('  3. Check Podfile STRIP_STYLE settings');
          developer.log('  4. Try clean build: flutter clean && pod install');
        }
      }

      debugPrint(
        '[FaceRecognitionService] Unable to create interpreter: $e',
      );
    }
  }

  /// Convert image to TFLite input array format
  ///
  /// - Resizes image to 112x112
  /// - Extracts RGB channels
  /// - Normalizes values: (value - 127.5) / 127.5
  /// - Returns shape [1, 112, 112, 3]
  List<dynamic> imageToArray(img.Image inputImage) {
    img.Image resizedImage = img.copyResize(
      inputImage,
      width: width,
      height: height,
    );

    List<double> flattenedList = resizedImage.data!
        .expand((channel) => [channel.r, channel.g, channel.b])
        .map((value) => value.toDouble())
        .toList();

    Float32List float32Array = Float32List.fromList(flattenedList);

    int channels = 3;

    Float32List reshapedArray = Float32List(1 * height * width * channels);

    for (int c = 0; c < channels; c++) {
      for (int h = 0; h < height; h++) {
        for (int w = 0; w < width; w++) {
          int index = c * height * width + h * width + w;
          // Normalize: (value - 127.5) / 127.5 maps [0, 255] to [-1, 1]
          reshapedArray[index] =
              (float32Array[c * height * width + h * width + w] - 127.5) /
              127.5;
        }
      }
    }

    return reshapedArray.reshape([1, 112, 112, 3]);
  }

  /// Generate face embedding from image
  ///
  /// [image] - Input image (should be cropped face)
  /// [location] - Face bounding box rectangle
  ///
  /// Returns RecognitionEmbedding with 192-dimensional embedding vector
  /// Returns zero embedding if model is not loaded
  RecognitionEmbedding recognize(img.Image image, Rect location) {
    // Check if model is loaded
    if (!isModelLoaded || interpreter == null) {
      developer.log(
        '[FaceRecognitionService] CRITICAL: Cannot recognize - model not loaded!',
      );
      developer.log('  isModelLoaded: $isModelLoaded');
      developer.log(
        '  interpreter: ${interpreter != null ? "not null" : "NULL"}',
      );
      developer.log('  loadError: $loadError');

      if (kDebugMode) {
        developer.log('');
        developer
            .log('[FaceRecognitionService] Recognition FAILED - Model Not Loaded');
        developer.log('  Platform: ${Platform.operatingSystem}');
        if (loadError != null) {
          developer.log('  Load Error: $loadError');
        }
      }

      // Return empty embedding (all zeros) to avoid crash
      return RecognitionEmbedding(
        location,
        FaceEmbeddingMatcher.createEmptyEmbedding(),
      );
    }

    // Convert image to TFLite input format
    var input = imageToArray(image);

    if (kDebugMode) {
      developer.log('[FaceRecognitionService] Input shape: ${input.shape}');
    }

    // Prepare output buffer
    List output =
        List.filled(1 * embeddingSize, 0).reshape([1, embeddingSize]);

    // Run inference
    interpreter!.run(input, output);

    // Convert dynamic list to double list
    List<double> outputArray = output.first.cast<double>();

    return RecognitionEmbedding(location, outputArray);
  }

  /// Calculate Euclidean distance between two embeddings
  /// Delegates to FaceEmbeddingMatcher
  PairEmbedding findNearest(List<double> emb, List<double> authFaceEmbedding) {
    return FaceEmbeddingMatcher.findNearest(emb, authFaceEmbedding);
  }

  /// Validate face match between current and registered embedding
  /// Delegates to FaceEmbeddingMatcher
  FaceValidationResult validateFaceMatch({
    required List<double> currentEmbedding,
    List<double>? registeredEmbedding,
    double threshold = defaultThreshold,
  }) {
    return FaceEmbeddingMatcher.validateFaceMatch(
      currentEmbedding: currentEmbedding,
      registeredEmbedding: registeredEmbedding,
      threshold: threshold,
    );
  }

  /// Parse embedding string (comma-separated) to list of doubles
  /// Delegates to FaceEmbeddingMatcher
  List<double>? parseEmbeddingString(String? embeddingString) {
    return FaceEmbeddingMatcher.parseEmbeddingString(embeddingString);
  }

  /// Convert embedding list to comma-separated string
  /// Delegates to FaceEmbeddingMatcher
  String embeddingToString(List<double> embedding) {
    return FaceEmbeddingMatcher.embeddingToString(embedding);
  }

  /// Calculate similarity percentage from distance
  /// Delegates to FaceEmbeddingMatcher
  double calculateSimilarityPercentage(double distance) {
    return FaceEmbeddingMatcher.calculateSimilarityPercentage(distance);
  }

  /// Check if embedding is valid (non-null, correct size, not all zeros)
  /// Delegates to FaceEmbeddingMatcher
  bool isEmbeddingValid(List<double>? embedding) {
    return FaceEmbeddingMatcher.isEmbeddingValid(embedding);
  }

  /// Create empty (zero-filled) embedding
  /// Delegates to FaceEmbeddingMatcher
  List<double> createEmptyEmbedding() {
    return FaceEmbeddingMatcher.createEmptyEmbedding();
  }

  /// Dispose resources
  void dispose() {
    interpreter?.close();
    interpreter = null;
    isModelLoaded = false;
  }
}
