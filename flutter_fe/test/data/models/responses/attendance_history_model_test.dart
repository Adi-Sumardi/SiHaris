import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/responses/attendance_history_model.dart';

void main() {
  const tAttendanceHistoryItem = AttendanceHistoryModel(
    id: 1,
    date: '2023-10-27',
    clockIn: '08:00',
    clockOut: '17:00',
    status: 'present',
    statusLabel: 'Hadir',
    officeLocationName: 'Head Office',
    workingFormatted: '9 Jam 0 Menit',
  );

  group('AttendanceHistoryModel', () {
    test('fromJson should return valid model', () {
      final Map<String, dynamic> jsonMap = {
        "id": 1,
        "date": "2023-10-27",
        "clock_in": "08:00",
        "clock_out": "17:00",
        "status": "present",
        "status_label": "Hadir",
        "office_location_name": "Head Office",
        "working_formatted": "9 Jam 0 Menit",
      };

      final result = AttendanceHistoryModel.fromJson(jsonMap);

      expect(result, tAttendanceHistoryItem);
    });

    test('toJson should return valid map', () {
      final result = tAttendanceHistoryItem.toJson();

      final expectedMap = {
        "id": 1,
        "date": "2023-10-27",
        "clock_in": "08:00",
        "clock_out": "17:00",
        "status": "present",
        "status_label": "Hadir",
        "office_location_name": "Head Office",
        "working_formatted": "9 Jam 0 Menit",
      };

      expect(result, expectedMap);
    });
  });
}
