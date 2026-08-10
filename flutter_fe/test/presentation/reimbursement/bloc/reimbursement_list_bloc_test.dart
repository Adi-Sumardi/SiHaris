import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/datasources/reimbursement_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/reimbursement_model.dart';
import 'package:gaji_pro/presentation/reimbursement/bloc/reimbursement_list/reimbursement_list_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockReimbursementRemoteDatasource extends Mock
    implements ReimbursementRemoteDatasource {}

void main() {
  late ReimbursementListBloc bloc;
  late MockReimbursementRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockReimbursementRemoteDatasource();
    bloc = ReimbursementListBloc(mockDatasource);
  });

  tearDown(() {
    bloc.close();
  });

  const tReimbursements = [
    ReimbursementModel(
      id: 1,
      category: 'Transport',
      amount: 150000,
      formattedAmount: 'Rp 150.000',
      description: 'Taxi',
      expenseDate: '2026-02-15',
      receiptUrl: null,
      status: 'pending',
      statusLabel: 'Pending',
      approvedBy: null,
      approvedAt: null,
      rejectionReason: null,
      paidAt: null,
      paymentMethod: null,
      createdAt: '2026-02-15T09:00:00Z',
    ),
  ];

  test('initial state should be ReimbursementListInitial', () {
    expect(bloc.state, equals(ReimbursementListInitial()));
  });

  group('LoadReimbursements', () {
    blocTest<ReimbursementListBloc, ReimbursementListState>(
      'emits [Loading, Loaded] when data is fetched successfully',
      build: () {
        when(
          () => mockDatasource.getReimbursements(
            status: any(named: 'status'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            page: any(named: 'page'),
          ),
        ).thenAnswer((_) async => tReimbursements);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadReimbursements()),
      expect: () => [
        ReimbursementListLoading(),
        const ReimbursementListLoaded(tReimbursements, hasReachedMax: false),
      ],
    );

    blocTest<ReimbursementListBloc, ReimbursementListState>(
      'emits [Loading, Loaded] with filters when status is provided',
      build: () {
        when(
          () => mockDatasource.getReimbursements(
            status: 'approved',
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            page: any(named: 'page'),
          ),
        ).thenAnswer((_) async => tReimbursements);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadReimbursements(status: 'approved')),
      expect: () => [
        ReimbursementListLoading(),
        const ReimbursementListLoaded(tReimbursements, hasReachedMax: false),
      ],
    );

    blocTest<ReimbursementListBloc, ReimbursementListState>(
      'emits [Loading, Error] when fetching data fails',
      build: () {
        when(
          () => mockDatasource.getReimbursements(
            status: any(named: 'status'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            page: any(named: 'page'),
          ),
        ).thenThrow(Exception('Failed to load'));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadReimbursements()),
      expect: () => [
        ReimbursementListLoading(),
        const ReimbursementListError('Exception: Failed to load'),
      ],
    );
  });

  group('RefreshReimbursements', () {
    blocTest<ReimbursementListBloc, ReimbursementListState>(
      'emits [Loading, Loaded] when refresh is successful',
      build: () {
        when(
          () => mockDatasource.getReimbursements(
            status: any(named: 'status'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            page: any(named: 'page'),
          ),
        ).thenAnswer((_) async => tReimbursements);
        return bloc;
      },
      act: (bloc) => bloc.add(const RefreshReimbursements()),
      expect: () => [
        ReimbursementListLoading(),
        const ReimbursementListLoaded(tReimbursements, hasReachedMax: false),
      ],
    );
  });
}
