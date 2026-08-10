import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/presentation/overtime/bloc/list/overtime_list_bloc.dart';
import 'package:gaji_pro/presentation/overtime/bloc/list/overtime_list_event.dart';
import 'package:gaji_pro/presentation/overtime/bloc/list/overtime_list_state.dart';
import 'package:gaji_pro/data/datasources/overtime_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/overtime_model.dart';

class MockOvertimeRemoteDatasource extends Mock
    implements OvertimeRemoteDatasource {}

void main() {
  late OvertimeListBloc bloc;
  late MockOvertimeRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockOvertimeRemoteDatasource();
    bloc = OvertimeListBloc(mockDatasource);
  });

  tearDown(() {
    bloc.close();
  });

  group('OvertimeListBloc', () {
    final tOvertimeModel = OvertimeModel(
      id: 1,
      date: '2026-02-15',
      startTime: '17:00',
      endTime: '19:00',
      overtimeHours: '2:00',
      overtimeType: 'weekday',
      overtimeTypeLabel: 'Hari Kerja',
      overtimeAmount: 50000,
      formattedAmount: 'Rp 50.000',
      reason: 'Urgent',
      status: 'pending',
      statusLabel: 'Menunggu',
      createdAt: '2026-02-15T18:00:00Z',
    );

    test('initial state is OvertimeListInitial', () {
      expect(bloc.state, OvertimeListInitial());
    });

    blocTest<OvertimeListBloc, OvertimeListState>(
      'emits [Loading, Loaded] when GetOvertimeList is added and success',
      build: () {
        when(
          () => mockDatasource.getOvertimes(
            page: 1,
            status: null,
            startDate: null,
            endDate: null,
          ),
        ).thenAnswer((_) async => [tOvertimeModel]);
        return bloc;
      },
      act: (bloc) => bloc.add(const GetOvertimeList()),
      expect: () => [
        OvertimeListLoading(),
        OvertimeListLoaded(overtimes: [tOvertimeModel], hasReachedMax: false),
      ],
    );

    blocTest<OvertimeListBloc, OvertimeListState>(
      'emits [Loading, Error] when GetOvertimeList fails',
      build: () {
        when(
          () => mockDatasource.getOvertimes(
            page: 1, // Corrected named argument usage if needed, or positional
            status: null,
            startDate: null,
            endDate: null,
          ),
        ).thenThrow(Exception('Failed'));
        return bloc;
      },
      act: (bloc) => bloc.add(const GetOvertimeList()),
      expect: () => [
        OvertimeListLoading(),
        const OvertimeListError('Exception: Failed'),
      ],
    );
  });
}
