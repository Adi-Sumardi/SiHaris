import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/datasources/reimbursement_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/reimbursement_model.dart';
import 'package:gaji_pro/presentation/reimbursement/bloc/reimbursement_detail/reimbursement_detail_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockReimbursementRemoteDatasource extends Mock
    implements ReimbursementRemoteDatasource {}

void main() {
  late ReimbursementDetailBloc bloc;
  late MockReimbursementRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockReimbursementRemoteDatasource();
    bloc = ReimbursementDetailBloc(mockDatasource);
  });

  tearDown(() {
    bloc.close();
  });

  const tReimbursement = ReimbursementModel(
    id: 1,
    category: 'Transport',
    amount: 150000,
    formattedAmount: 'Rp 150.000',
    description: 'Taxi to client meeting',
    expenseDate: '2026-02-15',
    receiptUrl: 'https://example.com/receipt.jpg',
    status: 'approved',
    statusLabel: 'Disetujui',
    approvedBy: 'Manager HR',
    approvedAt: '2026-02-16T10:00:00Z',
    rejectionReason: null,
    paidAt: null,
    paymentMethod: null,
    createdAt: '2026-02-15T09:00:00Z',
  );

  test('initial state should be ReimbursementDetailInitial', () {
    expect(bloc.state, equals(ReimbursementDetailInitial()));
  });

  group('LoadReimbursementDetail', () {
    blocTest<ReimbursementDetailBloc, ReimbursementDetailState>(
      'emits [Loading, Loaded] when detail is fetched successfully',
      build: () {
        when(
          () => mockDatasource.getReimbursementDetail(1),
        ).thenAnswer((_) async => tReimbursement);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadReimbursementDetail(1)),
      expect: () => [
        ReimbursementDetailLoading(),
        const ReimbursementDetailLoaded(tReimbursement),
      ],
    );

    blocTest<ReimbursementDetailBloc, ReimbursementDetailState>(
      'emits [Loading, Error] when fetching detail fails',
      build: () {
        when(
          () => mockDatasource.getReimbursementDetail(1),
        ).thenThrow(Exception('Not found'));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadReimbursementDetail(1)),
      expect: () => [
        ReimbursementDetailLoading(),
        const ReimbursementDetailError('Exception: Not found'),
      ],
    );
  });
}
