import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/datasources/office_location_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/office_location_model.dart';
import 'package:gaji_pro/presentation/office_location/bloc/office_location/office_location_bloc.dart';
import 'package:gaji_pro/presentation/office_location/bloc/office_location/office_location_event.dart';
import 'package:gaji_pro/presentation/office_location/bloc/office_location/office_location_state.dart';

class MockOfficeLocationRemoteDatasource extends Mock
    implements OfficeLocationRemoteDatasource {}

const tOffice = OfficeLocationModel(
  id: 1,
  name: 'Kantor Pusat',
  latitude: -6.2,
  longitude: 106.8,
  radius: 100,
);

void main() {
  late OfficeLocationBloc bloc;
  late MockOfficeLocationRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockOfficeLocationRemoteDatasource();
    bloc = OfficeLocationBloc(datasource: mockDatasource);
  });

  tearDown(() => bloc.close());

  test('initial state should be OfficeLocationInitial', () {
    expect(bloc.state, isA<OfficeLocationInitial>());
  });

  // ── GetOfficeLocations ──────────────────────────────────────────────────

  group('GetOfficeLocations', () {
    blocTest<OfficeLocationBloc, OfficeLocationState>(
      'emits [Loading, Loaded] when getOfficeLocations succeeds',
      build: () {
        when(() => mockDatasource.getOfficeLocations())
            .thenAnswer((_) async => const Right([tOffice]));
        return bloc;
      },
      act: (b) => b.add(GetOfficeLocations()),
      expect: () => [
        isA<OfficeLocationLoading>(),
        isA<OfficeLocationLoaded>(),
      ],
      verify: (_) {
        verify(() => mockDatasource.getOfficeLocations()).called(1);
      },
    );

    blocTest<OfficeLocationBloc, OfficeLocationState>(
      'emits [Loading, Error] when getOfficeLocations fails',
      build: () {
        when(() => mockDatasource.getOfficeLocations())
            .thenAnswer((_) async => const Left('Server error'));
        return bloc;
      },
      act: (b) => b.add(GetOfficeLocations()),
      expect: () => [
        isA<OfficeLocationLoading>(),
        isA<OfficeLocationError>(),
      ],
    );

    blocTest<OfficeLocationBloc, OfficeLocationState>(
      'OfficeLocationLoaded berisi data yang benar',
      build: () {
        when(() => mockDatasource.getOfficeLocations())
            .thenAnswer((_) async => const Right([tOffice]));
        return bloc;
      },
      act: (b) => b.add(GetOfficeLocations()),
      expect: () => [
        isA<OfficeLocationLoading>(),
        OfficeLocationLoaded(const [tOffice]),
      ],
    );
  });

  // ── GetAssignedOffices ──────────────────────────────────────────────────

  group('GetAssignedOffices', () {
    blocTest<OfficeLocationBloc, OfficeLocationState>(
      'emits [Loading, Loaded] when getAssignedOffices succeeds',
      build: () {
        when(() => mockDatasource.getAssignedOffices())
            .thenAnswer((_) async => const Right([tOffice]));
        return bloc;
      },
      act: (b) => b.add(GetAssignedOffices()),
      expect: () => [
        isA<OfficeLocationLoading>(),
        isA<OfficeLocationLoaded>(),
      ],
    );

    blocTest<OfficeLocationBloc, OfficeLocationState>(
      'emits [Loading, Error] when getAssignedOffices fails',
      build: () {
        when(() => mockDatasource.getAssignedOffices())
            .thenAnswer((_) async => const Left('Unauthorized'));
        return bloc;
      },
      act: (b) => b.add(GetAssignedOffices()),
      expect: () => [
        isA<OfficeLocationLoading>(),
        isA<OfficeLocationError>(),
      ],
    );
  });
}
