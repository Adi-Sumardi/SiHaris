import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/presentation/overtime/bloc/action/overtime_action_bloc.dart';
import 'package:gaji_pro/presentation/overtime/bloc/summary/overtime_summary_bloc.dart';
import 'package:gaji_pro/data/datasources/overtime_remote_datasource.dart';
import 'package:gaji_pro/data/models/requests/overtime_request_model.dart';
import 'package:gaji_pro/data/models/responses/overtime_summary_model.dart';

class MockOvertimeRemoteDatasource extends Mock
    implements OvertimeRemoteDatasource {}

void main() {
  late MockOvertimeRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockOvertimeRemoteDatasource();
  });

  group('OvertimeActionBloc', () {
    late OvertimeActionBloc bloc;

    setUp(() {
      bloc = OvertimeActionBloc(mockDatasource);
    });

    tearDown(() {
      bloc.close();
    });

    const tRequest = OvertimeRequestModel(
      date: '2026-02-16',
      startTime: '18:00',
      endTime: '20:00',
    );

    blocTest<OvertimeActionBloc, OvertimeActionState>(
      'emits [Loading, Success] when CreateOvertime is successful',
      build: () {
        when(
          () => mockDatasource.createOvertime(tRequest),
        ).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(const CreateOvertime(tRequest)),
      expect: () => [
        OvertimeActionLoading(),
        const OvertimeActionSuccess('Permintaan lembur berhasil dibuat'),
      ],
    );

    blocTest<OvertimeActionBloc, OvertimeActionState>(
      'emits [Loading, Failure] when CreateOvertime fails',
      build: () {
        when(
          () => mockDatasource.createOvertime(tRequest),
        ).thenThrow(Exception('Failed'));
        return bloc;
      },
      act: (bloc) => bloc.add(const CreateOvertime(tRequest)),
      expect: () => [
        OvertimeActionLoading(),
        const OvertimeActionFailure('Exception: Failed'),
      ],
    );
  });

  group('OvertimeSummaryBloc', () {
    late OvertimeSummaryBloc bloc;

    setUp(() {
      bloc = OvertimeSummaryBloc(mockDatasource);
    });

    tearDown(() {
      bloc.close();
    });

    const tSummary = OvertimeSummaryModel(
      totalRequests: 5,
      approvedRequests: 3,
      pendingRequests: 2,
      totalHours: '10:00',
      totalAmount: 250000,
    );

    blocTest<OvertimeSummaryBloc, OvertimeSummaryState>(
      'emits [Loading, Loaded] when GetOvertimeSummary is successful',
      build: () {
        when(
          () => mockDatasource.getOvertimeSummary(month: 2, year: 2026),
        ).thenAnswer((_) async => tSummary);
        return bloc;
      },
      act: (bloc) => bloc.add(const GetOvertimeSummary(month: 2, year: 2026)),
      expect: () => [
        OvertimeSummaryLoading(),
        const OvertimeSummaryLoaded(tSummary),
      ],
    );

    blocTest<OvertimeSummaryBloc, OvertimeSummaryState>(
      'emits [Loading, Error] when GetOvertimeSummary fails',
      build: () {
        when(
          () => mockDatasource.getOvertimeSummary(month: 2, year: 2026),
        ).thenThrow(Exception('Failed'));
        return bloc;
      },
      act: (bloc) => bloc.add(const GetOvertimeSummary(month: 2, year: 2026)),
      expect: () => [
        OvertimeSummaryLoading(),
        const OvertimeSummaryError('Exception: Failed'),
      ],
    );
  });
}
