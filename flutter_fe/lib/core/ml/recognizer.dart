import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:gaji_pro/core/ml/recognition_embedding.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Result of face validation containing isValid status and distance score
class FaceValidationResult {
  final bool isValid;
  final double distance;

  FaceValidationResult({required this.isValid, required this.distance});

  @override
  String toString() =>
      'FaceValidationResult(isValid: $isValid, distance: ${distance.toStringAsFixed(4)})';
}

class Recognizer {
  Interpreter? interpreter;
  late InterpreterOptions _interpreterOptions;
  static const int WIDTH = 112;
  static const int HEIGHT = 112;
  static const int embeddingSize = 192;

  bool isModelLoaded = false;
  String? loadError;

  String get modelName => 'assets/models/mobile_face_net.tflite';

  Future<void> loadModel() async {
    try {
      if (kDebugMode) {
        developer.log('🤖 [Recognizer] Starting to load TFLite model: $modelName');
        developer.log('🤖 [Recognizer] Platform: ${Platform.operatingSystem}');
      }

      interpreter = await Interpreter.fromAsset(
        modelName,
        options: _interpreterOptions,
      );

      isModelLoaded = true;

      if (kDebugMode) {
        developer.log('✅ [Recognizer] TFLite model loaded successfully');
      }
    } catch (e, stackTrace) {
      isModelLoaded = false;
      loadError = e.toString();

      developer.log(
        '❌ [Recognizer] Unable to load TFLite model!',
        error: e,
        stackTrace: stackTrace,
      );

      debugPrint('❌ Unable to create interpreter: ${e.toString()}');
    }
  }

  Recognizer({int? numThreads}) {
    _interpreterOptions = InterpreterOptions();

    if (numThreads != null) {
      _interpreterOptions.threads = numThreads;
    }

    loadModel()
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            developer.log('⏱️ [Recognizer] TIMEOUT: Model loading took >15 seconds!');
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
            '💥 [Recognizer] Model loading failed in constructor',
            error: error,
            stackTrace: stackTrace,
          );
        });
  }

  List<dynamic> imageToArray(img.Image inputImage) {
    img.Image resizedImage = img.copyResize(
      inputImage,
      width: WIDTH,
      height: HEIGHT,
    );
    List<double> flattenedList = resizedImage.data!
        .expand((channel) => [channel.r, channel.g, channel.b])
        .map((value) => value.toDouble())
        .toList();
    Float32List float32Array = Float32List.fromList(flattenedList);
    int channels = 3;
    int height = HEIGHT;
    int width = WIDTH;
    Float32List reshapedArray = Float32List(1 * height * width * channels);
    for (int c = 0; c < channels; c++) {
      for (int h = 0; h < height; h++) {
        for (int w = 0; w < width; w++) {
          int index = c * height * width + h * width + w;
          reshapedArray[index] =
              (float32Array[c * height * width + h * width + w] - 127.5) /
              127.5;
        }
      }
    }
    return reshapedArray.reshape([1, HEIGHT, WIDTH, 3]);
  }

  RecognitionEmbedding recognize(img.Image image, Rect location) {
    if (!isModelLoaded || interpreter == null) {
      developer.log('❌ [Recognizer] Cannot recognize - model not loaded!');
      return RecognitionEmbedding(location, List.filled(embeddingSize, 0.0));
    }

    var input = imageToArray(image);
    List output = List.filled(1 * embeddingSize, 0).reshape([1, embeddingSize]);
    interpreter!.run(input, output);
    List<double> outputArray = output.first.cast<double>();

    return RecognitionEmbedding(location, outputArray);
  }

  PairEmbedding findNearest(List<double> emb, List<double> registeredEmbedding) {
    double distance = euclideanDistance(emb, registeredEmbedding);
    return PairEmbedding(distance);
  }

  /// Calculate Euclidean distance between two embedding vectors
  double euclideanDistance(List<double> emb1, List<double> emb2) {
    double distance = 0;
    final len = min(emb1.length, emb2.length);
    for (int i = 0; i < len; i++) {
      double diff = emb1[i] - emb2[i];
      distance += diff * diff;
    }
    return sqrt(distance);
  }

  /// Calculate cosine similarity between two embedding vectors.
  ///
  /// Mengembalikan nilai -1..1 (1 = identik). Metrik ini SAMA dengan yang
  /// dipakai backend ([FaceRecognitionService::calculateSimilarity]), sehingga
  /// hasil verifikasi sisi-klien dan sisi-server konsisten dan threshold
  /// `face_match_threshold` bermakna sama di kedua sisi.
  double cosineSimilarity(List<double> emb1, List<double> emb2) {
    final len = min(emb1.length, emb2.length);
    if (len == 0) return 0.0;

    double dot = 0, mag1 = 0, mag2 = 0;
    for (int i = 0; i < len; i++) {
      dot += emb1[i] * emb2[i];
      mag1 += emb1[i] * emb1[i];
      mag2 += emb2[i] * emb2[i];
    }
    mag1 = sqrt(mag1);
    mag2 = sqrt(mag2);
    if (mag1 == 0 || mag2 == 0) return 0.0;
    return dot / (mag1 * mag2);
  }

  /// Validate face embedding against a registered embedding string.
  ///
  /// [embeddingString] - comma-separated embedding values from local storage.
  /// [threshold] - ambang cosine similarity (0..1). Match bila similarity >= threshold,
  /// konsisten dengan backend. Field `distance` pada hasil berisi nilai similarity.
  FaceValidationResult validateFace(
    List<double> currentEmbedding,
    String embeddingString, {
    double threshold = 0.6,
  }) {
    if (embeddingString.isEmpty) {
      return FaceValidationResult(isValid: false, distance: -1);
    }

    final registeredEmbedding = embeddingString
        .split(',')
        .map((e) => double.tryParse(e) ?? 0.0)
        .toList()
        .cast<double>();

    final similarity = cosineSimilarity(currentEmbedding, registeredEmbedding);
    final isValid = similarity >= threshold;

    if (kDebugMode) {
      developer.log('🎯 FACE VALIDATION: similarity=${similarity.toStringAsFixed(4)}, threshold=$threshold, valid=$isValid');
    }

    return FaceValidationResult(isValid: isValid, distance: similarity);
  }
}

class PairEmbedding {
  double distance;
  PairEmbedding(this.distance);
}
