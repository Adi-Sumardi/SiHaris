import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/datasources/face_recognition_datasource.dart';
import 'package:gaji_pro/data/models/requests/face_recognition/face_enroll_request_model.dart';
import 'package:gaji_pro/data/models/requests/face_recognition/face_verify_request_model.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late FaceRecognitionRemoteDatasource datasource;
  late MockHttpClient mockClient;

  final testDescriptors = List.generate(192, (i) => i * 0.01);

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://fallback.test'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    datasource = FaceRecognitionRemoteDatasource(client: mockClient);
    SharedPreferences.setMockInitialValues({'token': 'test_token'});
  });

  group('getStatus()', () {
    final statusResponseJson = {
      'enrolled': true,
      'enrolled_at': '2026-02-17T10:00:00.000000Z',
      'quality_score': 0.85,
      'company_settings': {
        'face_recognition_enabled': true,
        'liveness_required': false,
        'match_threshold': 0.6,
      },
    };

    test('returns FaceRecognitionStatusModel on 200', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(
                jsonEncode(statusResponseJson),
                200,
              ));

      final result = await datasource.getStatus();

      expect(result, isA<Right>());
      result.fold(
        (l) => fail('Expected Right but got Left: $l'),
        (r) {
          expect(r.enrolled, isTrue);
          expect(r.qualityScore, 0.85);
          expect(r.companySettings?.faceRecognitionEnabled, isTrue);
        },
      );
    });

    test('returns "Unauthenticated" on 401', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async =>
              http.Response('{"message": "Unauthenticated."}', 401));

      final result = await datasource.getStatus();

      expect(result, isA<Left>());
      result.fold(
        (l) => expect(l, 'Unauthenticated'),
        (r) => fail('Expected Left'),
      );
    });

    test('returns error message on network exception', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(Exception('No internet'));

      final result = await datasource.getStatus();

      expect(result, isA<Left>());
      result.fold(
        (l) => expect(l, contains('Terjadi kesalahan')),
        (r) => fail('Expected Left'),
      );
    });
  });

  group('enroll()', () {
    final enrollRequest = FaceEnrollRequestModel(
      descriptors: testDescriptors,
      qualityScore: 0.9,
    );

    test('returns FaceEnrollResponseModel on 200', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({'enrolled': true, 'quality_score': 0.9}),
            200,
          ));

      final result = await datasource.enroll(enrollRequest);

      expect(result, isA<Right>());
      result.fold(
        (l) => fail('Expected Right but got Left: $l'),
        (r) {
          expect(r.enrolled, isTrue);
          expect(r.qualityScore, 0.9);
        },
      );
    });

    test('returns "Unauthenticated" on 401', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async =>
          http.Response('{"message": "Unauthenticated."}', 401));

      final result = await datasource.enroll(enrollRequest);

      result.fold(
        (l) => expect(l, 'Unauthenticated'),
        (r) => fail('Expected Left'),
      );
    });

    test('returns validation error message on 422', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'message': 'The given data was invalid.',
              'errors': {
                'embedding_data': ['The embedding data field is required.'],
              },
            }),
            422,
          ));

      final result = await datasource.enroll(enrollRequest);

      result.fold(
        (l) => expect(l, contains('embedding data')),
        (r) => fail('Expected Left'),
      );
    });
  });

  group('verify()', () {
    final verifyRequest = FaceVerifyRequestModel(
      descriptors: testDescriptors,
      verificationType: VerificationType.clockIn,
    );

    test('returns FaceVerifyResponseModel matched=true on 200', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({'matched': true, 'confidence': 0.87}),
            200,
          ));

      final result = await datasource.verify(verifyRequest);

      expect(result, isA<Right>());
      result.fold(
        (l) => fail('Expected Right but got Left: $l'),
        (r) {
          expect(r.matched, isTrue);
          expect(r.confidence, 0.87);
        },
      );
    });

    test('returns FaceVerifyResponseModel matched=false on 200', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({'matched': false, 'confidence': 0.23}),
            200,
          ));

      final result = await datasource.verify(verifyRequest);

      result.fold(
        (l) => fail('Expected Right'),
        (r) => expect(r.matched, isFalse),
      );
    });
  });

  group('deleteEnrollment()', () {
    test('returns true on 200', () async {
      when(() => mockClient.delete(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async =>
              http.Response(jsonEncode({'message': 'deleted'}), 200));

      final result = await datasource.deleteEnrollment();

      expect(result, isA<Right>());
      result.fold(
        (l) => fail('Expected Right'),
        (r) => expect(r, isTrue),
      );
    });

    test('returns "Unauthenticated" on 401', () async {
      when(() => mockClient.delete(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async =>
              http.Response('{"message": "Unauthenticated."}', 401));

      final result = await datasource.deleteEnrollment();

      result.fold(
        (l) => expect(l, 'Unauthenticated'),
        (r) => fail('Expected Left'),
      );
    });
  });
}
