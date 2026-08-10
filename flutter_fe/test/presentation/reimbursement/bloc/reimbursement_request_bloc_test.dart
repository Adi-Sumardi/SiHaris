import 'dart:io';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/datasources/reimbursement_remote_datasource.dart';
import 'package:gaji_pro/data/models/requests/reimbursement_request_model.dart';
import 'package:gaji_pro/data/models/responses/reimbursement_model.dart';
import 'package:gaji_pro/presentation/reimbursement/bloc/reimbursement_request/reimbursement_request_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockReimbursementRemoteDatasource extends Mock
    implements ReimbursementRemoteDatasource {}

class MockFile extends Mock implements File {}

void main() {
  late ReimbursementRequestBloc bloc;
  late MockReimbursementRemoteDatasource mockDatasource;

  setUpAll(() {
    registerFallbackValue(
      const ReimbursementRequestModel(
        categoryId: 1,
        amount: 100000,
        description: 'Test',
        expenseDate: '2026-02-15',
      ),
    );
    registerFallbackValue(MockFile());
  });

  setUp(() {
    mockDatasource = MockReimbursementRemoteDatasource();
    bloc = ReimbursementRequestBloc(mockDatasource);
  });

  tearDown(() {
    bloc.close();
  });

  const tRequest = ReimbursementRequestModel(
    categoryId: 1,
    amount: 150000,
    description: 'Taxi to client meeting',
    expenseDate: '2026-02-15',
  );

  const tCreatedReimbursement = ReimbursementModel(
    id: 1,
    category: 'Transport',
    amount: 150000,
    formattedAmount: 'Rp 150.000',
    description: 'Taxi to client meeting',
    expenseDate: '2026-02-15',
    receiptUrl: 'https://example.com/receipt.jpg',
    status: 'pending',
    statusLabel: 'Pending',
    approvedBy: null,
    approvedAt: null,
    rejectionReason: null,
    paidAt: null,
    paymentMethod: null,
    createdAt: '2026-02-15T09:00:00Z',
  );

  test('initial state should be ReimbursementRequestInitial', () {
    expect(bloc.state, equals(ReimbursementRequestInitial()));
  });

  group('SubmitReimbursementRequest', () {
    blocTest<ReimbursementRequestBloc, ReimbursementRequestState>(
      'emits [Submitting, Success] when request is submitted successfully',
      build: () {
        when(
          () => mockDatasource.createReimbursement(any(), any()),
        ).thenAnswer((_) async => tCreatedReimbursement);
        return bloc;
      },
      act: (bloc) => bloc.add(const SubmitReimbursementRequest(tRequest, null)),
      expect: () => [
        ReimbursementRequestSubmitting(),
        const ReimbursementRequestSuccess(tCreatedReimbursement),
      ],
    );

    blocTest<ReimbursementRequestBloc, ReimbursementRequestState>(
      'emits [Submitting, Success] when request with file is submitted successfully',
      build: () {
        when(
          () => mockDatasource.createReimbursement(any(), any()),
        ).thenAnswer((_) async => tCreatedReimbursement);
        return bloc;
      },
      act: (bloc) => bloc.add(SubmitReimbursementRequest(tRequest, MockFile())),
      expect: () => [
        ReimbursementRequestSubmitting(),
        const ReimbursementRequestSuccess(tCreatedReimbursement),
      ],
    );

    blocTest<ReimbursementRequestBloc, ReimbursementRequestState>(
      'emits [Submitting, Error] when submission fails',
      build: () {
        when(
          () => mockDatasource.createReimbursement(any(), any()),
        ).thenThrow(Exception('Failed to submit'));
        return bloc;
      },
      act: (bloc) => bloc.add(const SubmitReimbursementRequest(tRequest, null)),
      expect: () => [
        ReimbursementRequestSubmitting(),
        const ReimbursementRequestError('Exception: Failed to submit'),
      ],
    );
  });
}
