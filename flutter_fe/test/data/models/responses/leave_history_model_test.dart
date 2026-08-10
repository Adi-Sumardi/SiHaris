import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/responses/leave_model.dart';
import 'package:gaji_pro/data/models/responses/leave_type_model.dart';

void main() {
  const tLeaveType = LeaveTypeModel(
    id: 1,
    name: 'Cuti Tahunan',
    quota: 12,
    isPaid: true,
    requiresAttachment: false,
  );

  const tLeaveModel = LeaveModel(
    id: 1,
    requestNumber: 'LV-2024-001',
    leaveType: tLeaveType,
    startDate: '2024-02-20',
    endDate: '2024-02-21',
    totalDays: 2,
    isHalfDay: false,
    reason: 'Liburan',
    status: 'pending',
    statusLabel: 'Menunggu Persetujuan',
    createdAt: '2024-02-01',
  );

  test('should be a subclass of LeaveModel', () async {
    expect(tLeaveModel, isA<LeaveModel>());
  });

  group('fromJson', () {
    test('should return a valid model when the JSON is valid', () async {
      // arrange
      final Map<String, dynamic> jsonMap = {
        "id": 1,
        "request_number": "LV-2024-001",
        "leave_type": {
          "id": 1,
          "name": "Cuti Tahunan",
          "quota": 12,
          "is_paid": true,
          "requires_attachment": false,
        },
        "start_date": "2024-02-20",
        "end_date": "2024-02-21",
        "total_days": 2,
        "is_half_day": false,
        "reason": "Liburan",
        "status": "pending",
        "status_label": "Menunggu Persetujuan",
        "created_at": "2024-02-01",
      };
      // act
      final result = LeaveModel.fromJson(jsonMap);
      // assert
      expect(result, tLeaveModel);
    });
  });

  group('toJson', () {
    test('should return a JSON map containing the proper data', () async {
      // act
      final result = tLeaveModel.toJson();
      // assert
      final expectedMap = {
        "id": 1,
        "request_number": "LV-2024-001",
        "leave_type": {
          "id": 1,
          "name": "Cuti Tahunan",
          "quota": 12,
          "is_paid": true,
          "requires_attachment": false,
        },
        "start_date": "2024-02-20",
        "end_date": "2024-02-21",
        "total_days": 2,
        "is_half_day": false,
        "reason": "Liburan",
        "status": "pending",
        "status_label": "Menunggu Persetujuan",
        "created_at": "2024-02-01",
        "half_day_type": null,
        "attachment": null,
        "approved_by": null,
        "approved_at": null,
        "rejection_reason": null,
      };
      expect(result, expectedMap);
    });
  });
}
