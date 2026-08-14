import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/responses/attendance_today_model.dart';
import 'package:gaji_pro/data/models/responses/office_location_model.dart';

void main() {
  const tOfficeParams = OfficeLocationModel(
    id: 1,
    name: 'Head Office',
    code: 'HO',
    address: 'Jl. Jend. Sudirman',
    city: 'Jakarta',
    province: 'DKI Jakarta',
    latitude: -6.2088,
    longitude: 106.8456,
    radius: 100,
    isActive: true,
    isHeadquarters: true,
    isPrimary: true,
  );

  const tAttendanceTodayModel = AttendanceTodayModel(
    id: 1,
    date: '2023-10-27',
    clockIn: '08:00',
    clockOut: '17:00',
    status: 'present',
    statusLabel: 'Hadir',
    lateMinutes: 0,
    workingMinutes: 540,
    faceVerified: true,
    officeLocation: tOfficeParams,
    schedule: Schedule(startTime: '08:00', endTime: '17:00'),
  );

  group('fromJson', () {
    test('should return a valid model from JSON', () {
      // arrange
      final Map<String, dynamic> jsonMap = json.decode(
        fixture('attendance_today.json'),
      );
      // act
      final result = AttendanceTodayModel.fromJson(jsonMap);
      // assert
      expect(result, tAttendanceTodayModel);
    });
  });

  group('toJson', () {
    test('should return a JSON map containing proper data', () {
      // act
      final result = tAttendanceTodayModel.toJson();
      // assert
      final expectedMap = {
        "id": 1,
        "date": "2023-10-27",
        "clock_in": "08:00",
        "clock_out": "17:00",
        "status": "present",
        "status_label": "Hadir",
        "late_minutes": 0,
        "working_minutes": 540,
        "face_verified": true,
        "office_location": {
          "id": 1,
          "name": "Head Office",
          "code": "HO",
          "address": "Jl. Jend. Sudirman",
          "city": "Jakarta",
          "province": "DKI Jakarta",
          "latitude": -6.2088,
          "longitude": 106.8456,
          "radius": 100,
          "is_active": true,
          "is_headquarters": true,
          "is_primary": true,
        },
        "schedule": {"name": null, "start_time": "08:00", "end_time": "17:00"},
        "clock_in_source": null,
        "clock_out_source": null,
      };
      expect(result, expectedMap);
    });
  });
}

String fixture(String name) => """
{
  "id": 1,
  "date": "2023-10-27",
  "clock_in": "08:00",
  "clock_out": "17:00",
  "status": "present",
  "status_label": "Hadir",
  "late_minutes": 0,
  "working_minutes": 540,
  "face_verified": true,
  "office_location": {
    "id": 1,
    "name": "Head Office",
    "code": "HO",
    "address": "Jl. Jend. Sudirman",
    "city": "Jakarta",
    "province": "DKI Jakarta",
    "latitude": -6.2088,
    "longitude": 106.8456,
    "radius": 100,
    "is_active": true,
    "is_headquarters": true,
    "is_primary": true
  },
  "schedule": {
    "start_time": "08:00",
    "end_time": "17:00"
  }
}
""";
