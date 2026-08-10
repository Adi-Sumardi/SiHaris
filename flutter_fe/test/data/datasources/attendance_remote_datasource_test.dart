import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/datasources/attendance_remote_datasource.dart';
import 'package:gaji_pro/core/constants/variables.dart';
import 'package:gaji_pro/data/models/requests/clock_in_request_model.dart';
import 'package:gaji_pro/data/models/requests/clock_out_request_model.dart';
import '../../mocks/mock_http_client.dart';
import '../../mocks/mock_auth_local_datasource.dart';

class MockFile extends Mock implements File {}

void main() {
  late AttendanceRemoteDatasource datasource;
  late MockHttpClient mockHttpClient;
  late MockAuthLocalDatasource mockLocalDatasource;

  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(http.Request('POST', Uri()));
    registerFallbackValue(http.MultipartRequest('POST', Uri()));
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockLocalDatasource = MockAuthLocalDatasource();
    datasource = AttendanceRemoteDatasource(
      client: mockHttpClient,
      localDatasource: mockLocalDatasource,
    );
  });

  const testToken = 'test_token_123';

  group('getTodayAttendance', () {
    final tAttendanceResponse = {
      'success': true,
      'data': {
        'id': 1,
        'date': '2023-10-27',
        'clock_in': '08:00',
        'clock_out': '17:00',
        'status': 'present',
        'status_label': 'Hadir',
        'late_minutes': 0,
        'working_minutes': 540,
        'face_verified': true,
        'office_location': null,
        'schedule': null,
      },
    };

    test('should return AttendanceTodayModel when successful', () async {
      // arrange
      when(
        () => mockLocalDatasource.getToken(),
      ).thenAnswer((_) async => testToken);
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode(tAttendanceResponse), 200),
      );

      // act
      final result = await datasource.getTodayAttendance();

      // assert
      expect(result.isRight(), true);
      verify(
        () => mockHttpClient.get(
          Uri.parse(Variables.attendanceToday),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('should return error when failed', () async {
      // arrange
      when(
        () => mockLocalDatasource.getToken(),
      ).thenAnswer((_) async => testToken);
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Error', 500));

      // act
      final result = await datasource.getTodayAttendance();

      // assert
      expect(result.isLeft(), true);
    });
  });

  group('clockIn', () {
    final tRequest = ClockInRequestModel(
      latitude: -6.2,
      longitude: 106.8,
      officeLocationId: 1,
      gpsVerified: true,
      faceVerified: true,
    );

    final tSuccessResponse = {
      'success': true,
      'message': 'Clock in success',
      'data': {
        'id': 1,
        'date': '2023-10-27',
        'status': 'present',
        'status_label': 'Hadir',
      },
    };

    test(
      'should return success message when clock in is successful (no photo)',
      () async {
        // arrange
        when(
          () => mockLocalDatasource.getToken(),
        ).thenAnswer((_) async => testToken);
        when(() => mockHttpClient.send(any())).thenAnswer(
          (_) async => http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode(tSuccessResponse))),
            200,
          ),
        );

        // act
        final result = await datasource.clockIn(tRequest);

        // assert
        expect(result.isRight(), true);
        verify(() => mockHttpClient.send(any())).called(1);
      },
    );

    test(
      'RED: clockIn harus kirim face_descriptors sebagai JSON string ke backend',
      () async {
        // arrange
        final descriptors = List<double>.generate(128, (i) => i * 0.01);
        final tRequestWithDescriptors = ClockInRequestModel(
          latitude: -6.2,
          longitude: 106.8,
          officeLocationId: 1,
          gpsVerified: true,
          faceVerified: true,
          faceConfidence: 0.91,
          faceDescriptors: descriptors,
        );

        http.BaseRequest? capturedRequest;
        when(() => mockLocalDatasource.getToken())
            .thenAnswer((_) async => testToken);
        when(() => mockHttpClient.send(any())).thenAnswer((invocation) async {
          capturedRequest = invocation.positionalArguments[0] as http.BaseRequest;
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode(tSuccessResponse))),
            200,
          );
        });

        // act
        final result = await datasource.clockIn(tRequestWithDescriptors);

        // assert: request berhasil
        expect(result.isRight(), true);

        // assert: face_descriptors harus ada di fields multipart request
        expect(capturedRequest, isA<http.MultipartRequest>());
        final multipart = capturedRequest as http.MultipartRequest;
        expect(
          multipart.fields.containsKey('face_descriptors'),
          isTrue,
          reason: 'face_descriptors harus dikirim ke backend sebagai field multipart',
        );

        // assert: nilainya valid JSON array
        final descriptorsJson = multipart.fields['face_descriptors']!;
        final decoded = jsonDecode(descriptorsJson) as List;
        expect(decoded.length, 128);
      },
    );
  });

  group('clockOut', () {
    final tRequest = ClockOutRequestModel(
      latitude: -6.2,
      longitude: 106.8,
      officeLocationId: 1,
      gpsVerified: true,
      faceVerified: true,
    );

    final tSuccessResponse = {
      'success': true,
      'message': 'Clock out success',
      'data': {
        'id': 1,
        'date': '2023-10-27',
        'status': 'present',
        'status_label': 'Hadir',
      },
    };

    test(
      'should return success message when clock out is successful',
      () async {
        // arrange
        when(
          () => mockLocalDatasource.getToken(),
        ).thenAnswer((_) async => testToken);
        when(() => mockHttpClient.send(any())).thenAnswer(
          (_) async => http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode(tSuccessResponse))),
            200,
          ),
        );

        // act
        final result = await datasource.clockOut(tRequest);

        // assert
        expect(result.isRight(), true);
        verify(() => mockHttpClient.send(any())).called(1);
      },
    );

    test(
      'RED: clockOut harus kirim face_descriptors sebagai JSON string ke backend',
      () async {
        // arrange
        final descriptors = List<double>.generate(128, (i) => i * 0.01);
        final tRequestWithDescriptors = ClockOutRequestModel(
          latitude: -6.2,
          longitude: 106.8,
          officeLocationId: 1,
          gpsVerified: true,
          faceVerified: true,
          faceConfidence: 0.88,
          faceDescriptors: descriptors,
        );

        http.BaseRequest? capturedRequest;
        when(() => mockLocalDatasource.getToken())
            .thenAnswer((_) async => testToken);
        when(() => mockHttpClient.send(any())).thenAnswer((invocation) async {
          capturedRequest = invocation.positionalArguments[0] as http.BaseRequest;
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode(tSuccessResponse))),
            200,
          );
        });

        // act
        final result = await datasource.clockOut(tRequestWithDescriptors);

        // assert: request berhasil
        expect(result.isRight(), true);

        // assert: face_descriptors harus ada di fields multipart request
        expect(capturedRequest, isA<http.MultipartRequest>());
        final multipart = capturedRequest as http.MultipartRequest;
        expect(
          multipart.fields.containsKey('face_descriptors'),
          isTrue,
          reason: 'face_descriptors harus dikirim ke backend sebagai field multipart',
        );

        // assert: nilainya valid JSON array
        final descriptorsJson = multipart.fields['face_descriptors']!;
        final decoded = jsonDecode(descriptorsJson) as List;
        expect(decoded.length, 128);
      },
    );
  });

  group('getHistory', () {
    final tHistoryResponse = {
      'success': true,
      'data': [
        {
          'id': 1,
          'date': '2023-10-27',
          'status': 'present',
          'status_label': 'Hadir',
        },
      ],
      'meta': {'total': 1},
    };

    test(
      'should return List<AttendanceHistoryModel> when successful',
      () async {
        // arrange
        when(
          () => mockLocalDatasource.getToken(),
        ).thenAnswer((_) async => testToken);
        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer(
          (_) async => http.Response(jsonEncode(tHistoryResponse), 200),
        );

        // act
        final result = await datasource.getHistory();

        // assert
        expect(result.isRight(), true);
        result.fold((l) => fail('should fail'), (r) => expect(r, isNotEmpty));
      },
    );
  });

  group('getSummary', () {
    final tSummaryResponse = {
      'success': true,
      'data': {
        'total_working_days': 20,
        'present': 18,
        'absent': 1,
        'late': 1,
        'leave': 0,
        'working_hours': '160:00',
        'overtime_hours': '05:30',
      },
    };

    test('should return AttendanceSummaryModel when successful', () async {
      // arrange
      when(
        () => mockLocalDatasource.getToken(),
      ).thenAnswer((_) async => testToken);
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode(tSummaryResponse), 200),
      );

      // act
      final result = await datasource.getSummary(month: 10, year: 2023);

      // assert
      expect(result.isRight(), true);
      verify(
        () => mockHttpClient.get(
          any(), // checking strict URI might be tedious with query params order
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });
  });
}
