import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/responses/pending_approvals_model.dart';

void main() {
  group('PendingApprovalsModel', () {
    test('should parse from JSON correctly', () {
      final json = {
        'leave_requests': [
          {
            'id': 1,
            'request_number': 'LV-2026-001',
            'leave_type': {
              'id': 1,
              'name': 'Cuti Tahunan',
              'quota': 12,
              'is_paid': true,
              'requires_attachment': false,
            },
            'start_date': '2026-03-01',
            'end_date': '2026-03-03',
            'total_days': 3,
            'is_half_day': false,
            'reason': 'Family vacation',
            'status': 'pending',
            'status_label': 'Menunggu Persetujuan',
            'created_at': '2026-02-15T10:00:00Z',
          },
        ],
        'overtime_requests': [],
        'reimbursements': [
          {
            'id': 5,
            'category': 'transport',
            'amount': 50000,
            'formatted_amount': 'Rp 50.000',
            'description': 'Taxi to client office',
            'expense_date': '2026-02-10',
            'receipt_url': 'https://example.com/receipt.jpg',
            'status': 'pending',
            'status_label': 'Menunggu Persetujuan',
            'created_at': '2026-02-11T08:00:00Z',
          },
        ],
        'total_pending': 2,
      };

      final model = PendingApprovalsModel.fromJson(json);

      expect(model.leaveRequests.length, 1);
      expect(model.leaveRequests[0].id, 1);
      expect(model.leaveRequests[0].requestNumber, 'LV-2026-001');
      expect(model.overtimeRequests.length, 0);
      expect(model.reimbursements.length, 1);
      expect(model.reimbursements[0].id, 5);
      expect(model.totalPending, 2);
    });

    test('should convert to JSON correctly', () {
      final model = PendingApprovalsModel(
        leaveRequests: [],
        overtimeRequests: [],
        reimbursements: [],
        totalPending: 0,
      );

      final json = model.toJson();

      expect(json['leave_requests'], []);
      expect(json['overtime_requests'], []);
      expect(json['reimbursements'], []);
      expect(json['total_pending'], 0);
    });

    test('should support equality comparison', () {
      final model1 = PendingApprovalsModel(
        leaveRequests: [],
        overtimeRequests: [],
        reimbursements: [],
        totalPending: 0,
      );

      final model2 = PendingApprovalsModel(
        leaveRequests: [],
        overtimeRequests: [],
        reimbursements: [],
        totalPending: 0,
      );

      expect(model1, equals(model2));
    });
  });
}
