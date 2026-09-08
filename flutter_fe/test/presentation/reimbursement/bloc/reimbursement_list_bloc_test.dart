import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/datasources/reimbursement_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/reimbursement_category_model.dart';
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

  const tCategory = ReimbursementCategoryModel(
    id: 1,
    name: 'Transport',
    description: 'Transportation expenses',
    maxAmount: 500000,
    requiresReceipt: true,
  );

  const tReimbursements = [
    ReimbursementModel(
      id: 1,
      category: tCategory,
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
        const ReimbursementListLoaded(tReimbursements, hasReachedMax: true),
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
        const ReimbursementListLoaded(tReimbursements, hasReachedMax: true),
      ],
    );

    blocTest<ReimbursementListBloc, ReimbursementListState>(
      'hasReachedMax is false when a full page (15 items) is returned',
      build: () {
        when(
          () => mockDatasource.getReimbursements(
            status: any(named: 'status'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            page: any(named: 'page'),
          ),
        ).thenAnswer(
          (_) async => List.generate(15, (i) => tReimbursements.first),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadReimbursements()),
      expect: () => [
        ReimbursementListLoading(),
        ReimbursementListLoaded(
          List.generate(15, (i) => tReimbursements.first),
          hasReachedMax: false,
        ),
      ],
    );

    blocTest<ReimbursementListBloc, ReimbursementListState>(
      'appends to the existing list instead of replacing it when loading page 2',
      build: () {
        when(
          () => mockDatasource.getReimbursements(
            status: any(named: 'status'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            page: 2,
          ),
        ).thenAnswer((_) async => tReimbursements);
        return bloc;
      },
      seed: () => const ReimbursementListLoaded(
        tReimbursements,
        hasReachedMax: false,
      ),
      act: (bloc) => bloc.add(const LoadReimbursements(page: 2)),
      expect: () => [
        ReimbursementListLoaded(
          [...tReimbursements, ...tReimbursements],
          hasReachedMax: true,
        ),
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
        const ReimbursementListLoaded(tReimbursements, hasReachedMax: true),
      ],
    );
  });
}
