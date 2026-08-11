import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/datasources/office_location_remote_datasource.dart';
import 'package:gaji_pro/core/constants/variables.dart';
import 'package:gaji_pro/data/models/requests/validate_gps_request_model.dart';
import '../../mocks/mock_http_client.dart';
import '../../mocks/mock_auth_local_datasource.dart';

void main() {
  late OfficeLocationRemoteDatasource datasource;
  late MockHttpClient mockHttpClient;
  late MockAuthLocalDatasource mockLocalDatasource;

  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockLocalDatasource = MockAuthLocalDatasource();
    datasource = OfficeLocationRemoteDatasource(
      client: mockHttpClient,
      localDatasource: mockLocalDatasource,
    );
    when(() => mockLocalDatasource.getAssignedOffices()).thenAnswer((_) async => []);
  });

  const testToken = 'test_token_123';

  final tOfficeJson = {
    'id': 1,
    'name': 'Kantor Pusat',
    'code': 'KP-01',
    'address': 'Jl. Sudirman No.1',
    'city': 'Jakarta',
    'province': 'DKI Jakarta',
    'latitude': -6.2,
    'longitude': 106.8,
    'radius': 100,
    'is_active': true,
    'is_headquarters': true,
    'is_primary': true,
  };

  // ── getOfficeLocations ──────────────────────────────────────────────────

  group('getOfficeLocations', () {
    test('should return List<OfficeLocationModel> when successful', () async {
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.get(
            Uri.parse(Variables.officeLocations),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({'success': true, 'data': [tOfficeJson]}),
            200,
          ));

      final result = await datasource.getOfficeLocations();

      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Expected Right'),
        (r) {
          expect(r.length, 1);
          expect(r.first.name, 'Kantor Pusat');
        },
      );
    });

    test('should return Left when status code is not 200', () async {
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.get(
            Uri.parse(Variables.officeLocations),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({'message': 'Server error'}),
            500,
          ));

      final result = await datasource.getOfficeLocations();

      expect(result.isLeft(), isTrue);
    });

    test('should return Left when token is null', () async {
      when(() => mockLocalDatasource.getToken()).thenAnswer((_) async => null);

      final result = await datasource.getOfficeLocations();

      expect(result.isLeft(), isTrue);
    });
  });

  // ── getAssignedOffices ──────────────────────────────────────────────────

  group('getAssignedOffices', () {
    test('should return assigned offices when successful', () async {
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.get(
            Uri.parse(Variables.officeLocationsAssigned),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({'success': true, 'data': [tOfficeJson]}),
            200,
          ));

      final result = await datasource.getAssignedOffices();

      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Expected Right'),
        (r) => expect(r.first.isPrimary, isTrue),
      );
    });

    test('should return Left on error', () async {
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.get(
            Uri.parse(Variables.officeLocationsAssigned),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async =>
          http.Response(jsonEncode({'message': 'Not found'}), 404));

      final result = await datasource.getAssignedOffices();

      expect(result.isLeft(), isTrue);
    });
  });

  // ── getOfficeLocationDetail ─────────────────────────────────────────────

  group('getOfficeLocationDetail', () {
    test('should return OfficeLocationModel when successful', () async {
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.get(
            Uri.parse(Variables.officeLocationDetail(1)),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({'success': true, 'data': tOfficeJson}),
            200,
          ));

      final result = await datasource.getOfficeLocationDetail(1);

      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Expected Right'),
        (r) => expect(r.id, 1),
      );
    });

    test('should return Left when not found', () async {
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.get(
            Uri.parse(Variables.officeLocationDetail(999)),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async =>
          http.Response(jsonEncode({'message': 'Not found'}), 404));

      final result = await datasource.getOfficeLocationDetail(999);

      expect(result.isLeft(), isTrue);
    });
  });

  // ── validateGps ─────────────────────────────────────────────────────────

  group('validateGps', () {
    const tRequest = ValidateGpsRequestModel(
      latitude: -6.2001,
      longitude: 106.8001,
    );

    final tValidResponse = {
      'success': true,
      'data': {
        'valid': true,
        'office_location_id': 1,
        'distance': 15.5,
        'reason': null,
        'office': tOfficeJson,
      },
    };

    final tInvalidResponse = {
      'success': true,
      'data': {
        'valid': false,
        'office_location_id': null,
        'distance': 500.0,
        'reason': 'outside_radius',
        'office': null,
      },
    };

    test('should return GpsValidationResponse with valid=true when in radius',
        () async {
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.post(
            Uri.parse(Variables.officeLocationsValidateGps),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async =>
          http.Response(jsonEncode(tValidResponse), 200));

      final result = await datasource.validateGps(tRequest);

      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Expected Right'),
        (r) {
          expect(r.valid, isTrue);
          expect(r.distance, 15.5);
        },
      );
    });

    test('should return GpsValidationResponse with valid=false when outside radius',
        () async {
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.post(
            Uri.parse(Variables.officeLocationsValidateGps),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async =>
          http.Response(jsonEncode(tInvalidResponse), 200));

      final result = await datasource.validateGps(tRequest);

      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Expected Right'),
        (r) {
          expect(r.valid, isFalse);
          expect(r.reason, 'outside_radius');
        },
      );
    });

    test('should return Left when server error', () async {
      when(() => mockLocalDatasource.getToken())
          .thenAnswer((_) async => testToken);
      when(() => mockHttpClient.post(
            Uri.parse(Variables.officeLocationsValidateGps),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async =>
          http.Response(jsonEncode({'message': 'Server error'}), 500));

      final result = await datasource.validateGps(tRequest);

      expect(result.isLeft(), isTrue);
    });
  });
}
