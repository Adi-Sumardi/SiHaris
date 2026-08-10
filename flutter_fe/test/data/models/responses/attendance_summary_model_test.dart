import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/responses/attendance_summary_model.dart';

void main() {
  group('AttendanceSummaryModel', () {
    test('fromJson should return valid model with API response keys (total_* prefix)', () {
      // This is the actual API response format
      final jsonMap = {
        "total_working_days": 20,
        "total_present": 18,
        "total_absent": 1,
        "total_late": 2,
        "total_leave": 1,
        "total_working_hours": 160.5,
        "total_overtime_hours": 5.5,
        "total_late_minutes": 45,
      };

      final result = AttendanceSummaryModel.fromJson(jsonMap);

      expect(result.totalWorkingDays, 20);
      expect(result.present, 18);
      expect(result.absent, 1);
      expect(result.late, 2);
      expect(result.leave, 1);
      expect(result.workingHours, '160.5j');
      expect(result.overtimeHours, '5.5j');
    });

    test('fromJson should handle legacy keys without total_ prefix', () {
      final jsonMap = {
        "total_working_days": 20,
        "present": 18,
        "absent": 1,
        "late": 2,
        "leave": 1,
        "total_working_hours": 160.0,
        "total_overtime_hours": 5.0,
      };

      final result = AttendanceSummaryModel.fromJson(jsonMap);

      expect(result.present, 18);
      expect(result.absent, 1);
      expect(result.late, 2);
      expect(result.leave, 1);
    });

    test('fromJson should handle null values', () {
      final jsonMap = <String, dynamic>{
        "total_working_days": null,
        "total_present": null,
        "total_absent": null,
        "total_late": null,
        "total_leave": null,
        "total_working_hours": null,
        "total_overtime_hours": null,
      };

      final result = AttendanceSummaryModel.fromJson(jsonMap);

      expect(result.totalWorkingDays, 0);
      expect(result.present, 0);
      expect(result.absent, 0);
      expect(result.late, 0);
      expect(result.leave, 0);
      expect(result.workingHours, '');
      expect(result.overtimeHours, '');
    });

    test('toJson should return valid map', () {
      const model = AttendanceSummaryModel(
        totalWorkingDays: 20,
        present: 18,
        absent: 1,
        late: 2,
        leave: 1,
        workingHours: '160.5j',
        overtimeHours: '5.5j',
      );

      final result = model.toJson();

      expect(result['total_working_days'], 20);
      expect(result['present'], 18);
      expect(result['absent'], 1);
      expect(result['late'], 2);
      expect(result['leave'], 1);
      expect(result['working_hours'], '160.5j');
      expect(result['overtime_hours'], '5.5j');
    });
  });
}
