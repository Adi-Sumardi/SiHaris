import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/core/constants/variables.dart';
import 'package:gaji_pro/data/datasources/auth_local_datasource.dart';
import 'package:gaji_pro/data/datasources/reimbursement_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/reimbursement_category_model.dart';
import 'package:gaji_pro/data/models/responses/reimbursement_model.dart';
import 'package:gaji_pro/data/models/responses/reimbursement_summary_model.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockAuthLocalDatasource extends Mock implements AuthLocalDatasource {}

class FakeUri extends Fake implements Uri {}

void main() {
  late ReimbursementRemoteDatasource datasource;
  late MockHttpClient mockHttpClient;
  late MockAuthLocalDatasource mockAuthLocalDatasource;

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockAuthLocalDatasource = MockAuthLocalDatasource();
    datasource = ReimbursementRemoteDatasource(
      mockHttpClient,
      mockAuthLocalDatasource,
    );
    registerFallbackValue(FakeUri());
  });

  const tToken = 'test_token';

  group('getReimbursements', () {
    final tReimbursements = [
      const ReimbursementModel(
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

    test('should return list of reimbursements on success', () async {
      when(
        () => mockAuthLocalDatasource.getToken(),
      ).thenAnswer((_) async => tToken);
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          '{"data": [{"id": 1, "category": "Transport", "amount": 150000, "formatted_amount": "Rp 150.000", "description": "Taxi", "expense_date": "2026-02-15", "receipt_url": null, "status": "pending", "status_label": "Pending", "approved_by": null, "approved_at": null, "rejection_reason": null, "paid_at": null, "payment_method": null, "created_at": "2026-02-15T09:00:00Z"}]}',
          200,
        ),
      );

      final result = await datasource.getReimbursements();

      expect(result, tReimbursements);
    });

    test(
      'should return filtered reimbursements with query parameters',
      () async {
        when(
          () => mockAuthLocalDatasource.getToken(),
        ).thenAnswer((_) async => tToken);
        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) async => http.Response('{"data": []}', 200));

        final result = await datasource.getReimbursements(
          status: 'approved',
          startDate: '2026-02-01',
          endDate: '2026-02-28',
        );

        expect(result, []);
      },
    );

    test('should throw exception on error', () async {
      when(
        () => mockAuthLocalDatasource.getToken(),
      ).thenAnswer((_) async => tToken);
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Error', 500));

      expect(() => datasource.getReimbursements(), throwsException);
    });
  });

  group('getReimbursementDetail', () {
    const tReimbursement = ReimbursementModel(
      id: 1,
      category: 'Transport',
      amount: 150000,
      formattedAmount: 'Rp 150.000',
      description: 'Taxi',
      expenseDate: '2026-02-15',
      receiptUrl: 'https://example.com/receipt.jpg',
      status: 'approved',
      statusLabel: 'Disetujui',
      approvedBy: 'Manager',
      approvedAt: '2026-02-16T10:00:00Z',
      rejectionReason: null,
      paidAt: null,
      paymentMethod: null,
      createdAt: '2026-02-15T09:00:00Z',
    );

    test('should return reimbursement detail on success', () async {
      when(
        () => mockAuthLocalDatasource.getToken(),
      ).thenAnswer((_) async => tToken);
      when(
        () => mockHttpClient.get(
          Uri.parse(Variables.reimbursementDetail(1)),
          headers: {'Authorization': 'Bearer $tToken'},
        ),
      ).thenAnswer(
        (_) async => http.Response(
          '{"data": {"id": 1, "category": "Transport", "amount": 150000, "formatted_amount": "Rp 150.000", "description": "Taxi", "expense_date": "2026-02-15", "receipt_url": "https://example.com/receipt.jpg", "status": "approved", "status_label": "Disetujui", "approved_by": "Manager", "approved_at": "2026-02-16T10:00:00Z", "rejection_reason": null, "paid_at": null, "payment_method": null, "created_at": "2026-02-15T09:00:00Z"}}',
          200,
        ),
      );

      final result = await datasource.getReimbursementDetail(1);

      expect(result, tReimbursement);
    });

    test('should throw exception on error', () async {
      when(
        () => mockAuthLocalDatasource.getToken(),
      ).thenAnswer((_) async => tToken);
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Not found', 404));

      expect(() => datasource.getReimbursementDetail(1), throwsException);
    });
  });

  group('getCategories', () {
    final tCategories = [
      const ReimbursementCategoryModel(
        id: 1,
        name: 'Transport',
        description: 'Transportation expenses',
        maxAmount: 500000,
        requiresReceipt: true,
      ),
    ];

    test('should return list of categories on success', () async {
      when(
        () => mockAuthLocalDatasource.getToken(),
      ).thenAnswer((_) async => tToken);
      when(
        () => mockHttpClient.get(
          Uri.parse(Variables.reimbursementCategories),
          headers: {'Authorization': 'Bearer $tToken'},
        ),
      ).thenAnswer(
        (_) async => http.Response(
          '{"data": [{"id": 1, "name": "Transport", "description": "Transportation expenses", "max_amount": 500000, "requires_receipt": true}]}',
          200,
        ),
      );

      final result = await datasource.getCategories();

      expect(result, tCategories);
    });

    test('should throw exception on error', () async {
      when(
        () => mockAuthLocalDatasource.getToken(),
      ).thenAnswer((_) async => tToken);
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Error', 500));

      expect(() => datasource.getCategories(), throwsException);
    });
  });

  group('getSummary', () {
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

    test('should return summary on success', () async {
      when(
        () => mockAuthLocalDatasource.getToken(),
      ).thenAnswer((_) async => tToken);
      when(
        () => mockHttpClient.get(
          Uri.parse('${Variables.reimbursementSummary}?month=2&year=2026'),
          headers: {'Authorization': 'Bearer $tToken'},
        ),
      ).thenAnswer(
        (_) async => http.Response(
          '{"data": {"total_requests": 12, "pending_requests": 3, "approved_requests": 7, "paid_requests": 5, "total_amount": 5000000, "approved_amount": 3500000, "paid_amount": 2500000, "pending_amount": 1500000}}',
          200,
        ),
      );

      final result = await datasource.getSummary(month: 2, year: 2026);

      expect(result, tSummary);
    });

    test('should throw exception on error', () async {
      when(
        () => mockAuthLocalDatasource.getToken(),
      ).thenAnswer((_) async => tToken);
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Error', 500));

      expect(
        () => datasource.getSummary(month: 2, year: 2026),
        throwsException,
      );
    });
  });
}
