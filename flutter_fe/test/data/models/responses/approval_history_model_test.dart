import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/responses/approval_history_model.dart';

void main() {
  group('ApprovalHistoryModel', () {
    test('should parse from JSON correctly', () {
      final json = {
        'type': 'leave',
        'id': 1,
        'employee_name': 'John Doe',
        'status': 'approved',
        'approved_at': '2026-02-15T14:30:00Z',
        'notes': null,
      };

      final model = ApprovalHistoryModel.fromJson(json);

      expect(model.type, 'leave');
      expect(model.id, 1);
      expect(model.employeeName, 'John Doe');
      expect(model.status, 'approved');
      expect(model.approvedAt, '2026-02-15T14:30:00Z');
      expect(model.notes, null);
    });

    test('should parse rejection with notes from JSON', () {
      final json = {
        'type': 'reimbursement',
        'id': 5,
        'employee_name': 'Jane Smith',
        'status': 'rejected',
        'approved_at': '2026-02-16T10:00:00Z',
        'notes': 'Receipt not clear enough',
      };

      final model = ApprovalHistoryModel.fromJson(json);

      expect(model.type, 'reimbursement');
      expect(model.status, 'rejected');
      expect(model.notes, 'Receipt not clear enough');
    });

    test('should convert to JSON correctly', () {
      final model = ApprovalHistoryModel(
        type: 'overtime',
        id: 3,
        employeeName: 'Bob Wilson',
        status: 'approved',
        approvedAt: '2026-02-17T09:00:00Z',
        notes: null,
      );

      final json = model.toJson();

      expect(json['type'], 'overtime');
      expect(json['id'], 3);
      expect(json['employee_name'], 'Bob Wilson');
      expect(json['status'], 'approved');
      expect(json['approved_at'], '2026-02-17T09:00:00Z');
      expect(json['notes'], null);
    });
  });
}
