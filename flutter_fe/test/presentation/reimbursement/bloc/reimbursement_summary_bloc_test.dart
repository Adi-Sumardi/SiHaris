import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/datasources/reimbursement_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/reimbursement_summary_model.dart';
import 'package:gaji_pro/presentation/reimbursement/bloc/reimbursement_summary/reimbursement_summary_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockReimbursementRemoteDatasource extends Mock
    implements ReimbursementRemoteDatasource {}

void main() {
  late ReimbursementSummaryBloc bloc;
  late MockReimbursementRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockReimbursementRemoteDatasource();
    bloc = ReimbursementSummaryBloc(mockDatasource);
  });

  tearDown(() {
    bloc.close();
  });

  const tSummary = ReimbursementSummaryModel(
    totalRequests: 12,
    pendingRequests: 3,
    approvedRequests: 7,
    paidRequests: 5,
    totalAmount: 5000000,
    approvedAmount: 3500000,
    paidAmount: 2500000,
    pendingAmount: 1500000,
  );

  test('initial state should be ReimbursementSummaryInitial', () {
    expect(bloc.state, equals(ReimbursementSummaryInitial()));
  });

  group('LoadReimbursementSummary', () {
    blocTest<ReimbursementSummaryBloc, ReimbursementSummaryState>(
      'emits [Loading, Loaded] when summary is fetched successfully',
      build: () {
        when(
          () => mockDatasource.getSummary(month: 2, year: 2026),
        ).thenAnswer((_) async => tSummary);
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const LoadReimbursementSummary(month: 2, year: 2026)),
      expect: () => [
        ReimbursementSummaryLoading(),
        const ReimbursementSummaryLoaded(tSummary),
      ],
    );

    blocTest<ReimbursementSummaryBloc, ReimbursementSummaryState>(
      'emits [Loading, Error] when fetching summary fails',
      build: () {
        when(
          () => mockDatasource.getSummary(month: 2, year: 2026),
        ).thenThrow(Exception('Failed to load summary'));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const LoadReimbursementSummary(month: 2, year: 2026)),
      expect: () => [
        ReimbursementSummaryLoading(),
        const ReimbursementSummaryError('Exception: Failed to load summary'),
      ],
    );
  });
}
