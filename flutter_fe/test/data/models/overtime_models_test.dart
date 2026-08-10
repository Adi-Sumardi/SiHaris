import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/responses/overtime_model.dart';
import 'package:gaji_pro/data/models/responses/overtime_summary_model.dart';
import 'package:gaji_pro/data/models/requests/overtime_request_model.dart';

void main() {
  group('OvertimeModels', () {
    test('OvertimeModel should parse JSON correctly', () {
      final json = {
        'id': 1,
        'date': '2026-02-15',
        'start_time': '17:00',
        'end_time': '19:00',
        'overtime_hours': '2:00',
        'overtime_type': 'weekday',
        'overtime_type_label': 'Hari Kerja',
        'overtime_amount': 50000,
        'formatted_amount': 'Rp 50.000',
        'reason': 'Urgent task',
        'status': 'pending',
        'status_label': 'Menunggu',
        'approved_by': null,
        'approved_at': null,
        'rejection_reason': null,
        'created_at': '2026-02-15T18:00:00Z',
      };

      final model = OvertimeModel.fromJson(json);

      expect(model.id, 1);
      expect(model.reason, 'Urgent task');
      expect(model.toJson(), json);
    });

    test('OvertimeSummaryModel should parse JSON correctly', () {
      final json = {
        'total_requests': 5,
        'approved_requests': 3,
        'pending_requests': 2,
        'total_hours': '10:30',
        'total_amount': 250000,
      };

      final model = OvertimeSummaryModel.fromJson(json);

      expect(model.totalRequests, 5);
      expect(model.totalHours, '10:30');
      expect(model.toJson(), json);
    });

    test('OvertimeRequestModel should serialize to JSON correctly', () {
      const model = OvertimeRequestModel(
        date: '2026-02-16',
        startTime: '18:00',
        endTime: '20:00',
        reason: 'Project deadline',
      );

      final json = model.toJson();

      expect(json['date'], '2026-02-16');
      expect(json['start_time'], '18:00');
      expect(json['reason'], 'Project deadline');
    });
  });
}
