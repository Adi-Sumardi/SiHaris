import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/datasources/office_location_remote_datasource.dart';
import 'package:gaji_pro/data/models/requests/validate_gps_request_model.dart';
import 'package:gaji_pro/data/models/responses/office_location_model.dart';
import 'package:gaji_pro/presentation/office_location/bloc/gps_validation/gps_validation_bloc.dart';
import 'package:gaji_pro/presentation/office_location/bloc/gps_validation/gps_validation_event.dart';
import 'package:gaji_pro/presentation/office_location/bloc/gps_validation/gps_validation_state.dart';

class MockOfficeLocationRemoteDatasource extends Mock
    implements OfficeLocationRemoteDatasource {}

class FakeValidateGpsRequestModel extends Fake
    implements ValidateGpsRequestModel {}

const tValidResponse = GpsValidationResponse(
  valid: true,
  officeLocationId: 1,
  distance: 15.5,
);

const tInvalidResponse = GpsValidationResponse(
  valid: false,
  distance: 500.0,
  reason: 'outside_radius',
);

void main() {
  late GpsValidationBloc bloc;
  late MockOfficeLocationRemoteDatasource mockDatasource;

  setUpAll(() {
    registerFallbackValue(FakeValidateGpsRequestModel());
  });

  setUp(() {
    mockDatasource = MockOfficeLocationRemoteDatasource();
    bloc = GpsValidationBloc(datasource: mockDatasource);
  });

  tearDown(() => bloc.close());

  test('initial state should be GpsValidationInitial', () {
    expect(bloc.state, isA<GpsValidationInitial>());
  });

  // ── ValidateGpsLocation ─────────────────────────────────────────────────

  group('ValidateGpsLocation', () {
    blocTest<GpsValidationBloc, GpsValidationState>(
      'emits [Loading, Success] saat valid=true',
      build: () {
        when(() => mockDatasource.validateGps(any()))
            .thenAnswer((_) async => const Right(tValidResponse));
        return bloc;
      },
      act: (b) => b.add(const ValidateGpsLocation(
        latitude: -6.2001,
        longitude: 106.8001,
      )),
      expect: () => [
        isA<GpsValidationLoading>(),
        isA<GpsValidationSuccess>(),
      ],
    );

    blocTest<GpsValidationBloc, GpsValidationState>(
      'GpsValidationSuccess berisi response yang benar',
      build: () {
        when(() => mockDatasource.validateGps(any()))
            .thenAnswer((_) async => const Right(tValidResponse));
        return bloc;
      },
      act: (b) => b.add(const ValidateGpsLocation(
        latitude: -6.2001,
        longitude: 106.8001,
      )),
      expect: () => [
        isA<GpsValidationLoading>(),
        GpsValidationSuccess(tValidResponse),
      ],
    );

    blocTest<GpsValidationBloc, GpsValidationState>(
      'emits [Loading, Success] saat valid=false (outside radius)',
      build: () {
        when(() => mockDatasource.validateGps(any()))
            .thenAnswer((_) async => const Right(tInvalidResponse));
        return bloc;
      },
      act: (b) => b.add(const ValidateGpsLocation(
        latitude: -7.0,
        longitude: 110.0,
      )),
      expect: () => [
        isA<GpsValidationLoading>(),
        GpsValidationSuccess(tInvalidResponse),
      ],
    );

    blocTest<GpsValidationBloc, GpsValidationState>(
      'emits [Loading, Failure] saat API error',
      build: () {
        when(() => mockDatasource.validateGps(any()))
            .thenAnswer((_) async => const Left('Network error'));
        return bloc;
      },
      act: (b) => b.add(const ValidateGpsLocation(
        latitude: -6.2001,
        longitude: 106.8001,
      )),
      expect: () => [
        isA<GpsValidationLoading>(),
        isA<GpsValidationFailure>(),
      ],
    );
  });

  // ── ResetGpsValidation ──────────────────────────────────────────────────

  group('ResetGpsValidation', () {
    blocTest<GpsValidationBloc, GpsValidationState>(
      'emits [Initial] setelah reset',
      build: () => bloc,
      seed: () => GpsValidationSuccess(tValidResponse),
      act: (b) => b.add(ResetGpsValidation()),
      expect: () => [isA<GpsValidationInitial>()],
    );
  });
}
