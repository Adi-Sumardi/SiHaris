import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/requests/face_recognition/face_enroll_request_model.dart';

void main() {
  final testDescriptors = List.generate(192, (i) => i * 0.01);

  group('FaceEnrollRequestModel', () {
    test('toJson() menghasilkan struktur embedding_data yang benar', () {
      final model = FaceEnrollRequestModel(descriptors: testDescriptors);
      final json = model.toJson();

      expect(json['embedding_data'], isNotNull);

      final embeddingData = jsonDecode(json['embedding_data'] as String);
      expect(embeddingData['version'], '1.0');
      expect(embeddingData['model'], 'tflite');
      expect(embeddingData['descriptors'], isA<List>());
      expect(embeddingData['descriptors'].length, 192);
    });

    test('descriptors harus 192 elemen', () {
      final model = FaceEnrollRequestModel(descriptors: testDescriptors);
      expect(model.descriptors.length, 192);
    });

    test('toJson() dengan photo menghasilkan field photo', () {
      final model = FaceEnrollRequestModel(
        descriptors: testDescriptors,
        qualityScore: 0.85,
      );
      final json = model.toJson();

      expect(json['quality_score'], 0.85);
    });

    test('toJson() tanpa qualityScore tidak menambah field quality_score', () {
      final model = FaceEnrollRequestModel(descriptors: testDescriptors);
      final json = model.toJson();

      expect(json.containsKey('quality_score'), isFalse);
    });

    test('model dengan valid embedding menyimpan nilai float yang benar', () {
      final model = FaceEnrollRequestModel(descriptors: testDescriptors);
      final json = model.toJson();

      final embeddingData = jsonDecode(json['embedding_data'] as String);
      final descriptors = List<double>.from(embeddingData['descriptors']);

      expect(descriptors[0], closeTo(0.0, 0.001));
      expect(descriptors[1], closeTo(0.01, 0.001));
      expect(descriptors[191], closeTo(1.91, 0.001));
    });
  });
}
