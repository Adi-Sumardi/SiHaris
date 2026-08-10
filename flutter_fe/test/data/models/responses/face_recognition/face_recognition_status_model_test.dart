import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/responses/face_recognition/face_recognition_status_model.dart';

void main() {
  group('FaceRecognitionStatusModel', () {
    final fullJson = {
      'enrolled': true,
      'enrolled_at': '2026-02-17T10:00:00.000000Z',
      'quality_score': 0.85,
      'company_settings': {
        'face_recognition_enabled': true,
        'liveness_required': false,
        'match_threshold': 0.6,
      },
    };

    test('fromJson() parse enrolled = true dengan benar', () {
      final model = FaceRecognitionStatusModel.fromJson(fullJson);
      expect(model.enrolled, isTrue);
    });

    test('fromJson() parse enrolled_at yang nullable', () {
      final model = FaceRecognitionStatusModel.fromJson(fullJson);
      expect(model.enrolledAt, isNotNull);
      expect(model.enrolledAt, '2026-02-17T10:00:00.000000Z');
    });

    test('fromJson() parse quality_score sebagai double', () {
      final model = FaceRecognitionStatusModel.fromJson(fullJson);
      expect(model.qualityScore, 0.85);
    });

    test('fromJson() parse company_settings dengan benar', () {
      final model = FaceRecognitionStatusModel.fromJson(fullJson);
      expect(model.companySettings, isNotNull);
      expect(model.companySettings!.faceRecognitionEnabled, isTrue);
      expect(model.companySettings!.livenessRequired, isFalse);
      expect(model.companySettings!.matchThreshold, 0.6);
    });

    test('fromJson() handle enrolled = false dan null fields', () {
      final json = {
        'enrolled': false,
        'enrolled_at': null,
        'quality_score': null,
        'company_settings': null,
      };
      final model = FaceRecognitionStatusModel.fromJson(json);

      expect(model.enrolled, isFalse);
      expect(model.enrolledAt, isNull);
      expect(model.qualityScore, isNull);
      expect(model.companySettings, isNull);
    });

    test('FaceRecognitionCompanySettings fromJson() parse benar', () {
      final settingsJson = {
        'face_recognition_enabled': true,
        'liveness_required': true,
        'match_threshold': 0.75,
      };
      final settings = FaceRecognitionCompanySettings.fromJson(settingsJson);

      expect(settings.faceRecognitionEnabled, isTrue);
      expect(settings.livenessRequired, isTrue);
      expect(settings.matchThreshold, 0.75);
    });
  });

  group('FaceEnrollResponseModel', () {
    test('fromJson() parse enrolled dan quality_score', () {
      final json = {'enrolled': true, 'quality_score': 0.9};
      final model = FaceEnrollResponseModel.fromJson(json);

      expect(model.enrolled, isTrue);
      expect(model.qualityScore, 0.9);
    });

    test('fromJson() handle quality_score null', () {
      final json = {'enrolled': true, 'quality_score': null};
      final model = FaceEnrollResponseModel.fromJson(json);

      expect(model.enrolled, isTrue);
      expect(model.qualityScore, isNull);
    });
  });

  group('FaceVerifyResponseModel', () {
    test('fromJson() parse matched = true dengan confidence', () {
      final json = {'matched': true, 'confidence': 0.87};
      final model = FaceVerifyResponseModel.fromJson(json);

      expect(model.matched, isTrue);
      expect(model.confidence, 0.87);
    });

    test('fromJson() parse matched = false', () {
      final json = {'matched': false, 'confidence': 0.23};
      final model = FaceVerifyResponseModel.fromJson(json);

      expect(model.matched, isFalse);
      expect(model.confidence, 0.23);
    });

    test('confidence getter: toConfidencePercentage() benar', () {
      final model = FaceVerifyResponseModel(matched: true, confidence: 0.87);
      expect(model.toConfidencePercentage(), '87%');
    });
  });
}
