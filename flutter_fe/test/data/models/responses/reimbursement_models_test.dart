import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/responses/reimbursement_model.dart';
import 'package:gaji_pro/data/models/responses/reimbursement_category_model.dart';
import 'package:gaji_pro/data/models/responses/reimbursement_summary_model.dart';

void main() {
  group('ReimbursementModel', () {
    const tReimbursementModel = ReimbursementModel(
      id: 1,
      category: 'Transport',
      amount: 150000,
      formattedAmount: 'Rp 150.000',
      description: 'Taxi to client meeting',
      expenseDate: '2026-02-15',
      receiptUrl: 'https://example.com/receipts/1.jpg',
      status: 'approved',
      statusLabel: 'Disetujui',
      approvedBy: 'Manager HR',
      approvedAt: '2026-02-16T10:30:00Z',
      rejectionReason: null,
      paidAt: '2026-02-17T14:00:00Z',
      paymentMethod: 'Bank Transfer',
      createdAt: '2026-02-15T09:00:00Z',
    );

    final tJson = {
      'id': 1,
      'category': 'Transport',
      'amount': 150000,
      'formatted_amount': 'Rp 150.000',
      'description': 'Taxi to client meeting',
      'expense_date': '2026-02-15',
      'receipt_url': 'https://example.com/receipts/1.jpg',
      'status': 'approved',
      'status_label': 'Disetujui',
      'approved_by': 'Manager HR',
      'approved_at': '2026-02-16T10:30:00Z',
      'rejection_reason': null,
      'paid_at': '2026-02-17T14:00:00Z',
      'payment_method': 'Bank Transfer',
      'created_at': '2026-02-15T09:00:00Z',
    };

    test('should create ReimbursementModel from JSON', () {
      final result = ReimbursementModel.fromJson(tJson);
      expect(result, tReimbursementModel);
    });

    test('should convert ReimbursementModel to JSON', () {
      final result = tReimbursementModel.toJson();
      expect(result, tJson);
    });

    test('should support equality comparison', () {
      const model1 = ReimbursementModel(
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
      );
      const model2 = ReimbursementModel(
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
      );
      expect(model1, model2);
    });
  });

  group('ReimbursementCategoryModel', () {
    const tCategoryModel = ReimbursementCategoryModel(
      id: 1,
      name: 'Transport',
      description: 'Transportation expenses',
      maxAmount: 500000,
      requiresReceipt: true,
    );

    final tJson = {
      'id': 1,
      'name': 'Transport',
      'description': 'Transportation expenses',
      'max_amount': 500000,
      'requires_receipt': true,
    };

    test('should create ReimbursementCategoryModel from JSON', () {
      final result = ReimbursementCategoryModel.fromJson(tJson);
      expect(result, tCategoryModel);
    });

    test('should convert ReimbursementCategoryModel to JSON', () {
      final result = tCategoryModel.toJson();
      expect(result, tJson);
    });

    test('should support equality comparison', () {
      const model1 = ReimbursementCategoryModel(
        id: 1,
        name: 'Transport',
        description: 'Transportation',
        maxAmount: 500000,
        requiresReceipt: true,
      );
      const model2 = ReimbursementCategoryModel(
        id: 1,
        name: 'Transport',
        description: 'Transportation',
        maxAmount: 500000,
        requiresReceipt: true,
      );
      expect(model1, model2);
    });
  });

  group('ReimbursementSummaryModel', () {
    const tSummaryModel = ReimbursementSummaryModel(
      totalRequests: 12,
      pendingRequests: 3,
      approvedRequests: 7,
      paidRequests: 5,
      totalAmount: 5000000,
      approvedAmount: 3500000,
      paidAmount: 2500000,
      pendingAmount: 1500000,
    );

    final tJson = {
      'total_requests': 12,
      'pending_requests': 3,
      'approved_requests': 7,
      'paid_requests': 5,
      'total_amount': 5000000,
      'approved_amount': 3500000,
      'paid_amount': 2500000,
      'pending_amount': 1500000,
    };

    test('should create ReimbursementSummaryModel from JSON', () {
      final result = ReimbursementSummaryModel.fromJson(tJson);
      expect(result, tSummaryModel);
    });

    test('should convert ReimbursementSummaryModel to JSON', () {
      final result = tSummaryModel.toJson();
      expect(result, tJson);
    });

    test('should support equality comparison', () {
      const model1 = ReimbursementSummaryModel(
        totalRequests: 10,
        pendingRequests: 2,
        approvedRequests: 5,
        paidRequests: 3,
        totalAmount: 4000000,
        approvedAmount: 2500000,
        paidAmount: 1500000,
        pendingAmount: 1000000,
      );
      const model2 = ReimbursementSummaryModel(
        totalRequests: 10,
        pendingRequests: 2,
        approvedRequests: 5,
        paidRequests: 3,
        totalAmount: 4000000,
        approvedAmount: 2500000,
        paidAmount: 1500000,
        pendingAmount: 1000000,
      );
      expect(model1, model2);
    });
  });
}
