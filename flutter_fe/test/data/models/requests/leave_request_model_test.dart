import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/requests/leave_request_model.dart';

void main() {
  final tLeaveRequestModel = LeaveRequestModel(
    leaveTypeId: 1,
    startDate: '2024-02-20',
    endDate: '2024-02-21',
    reason: 'Sakit',
    attachment: File('path/to/file.jpg'),
    emergencyContact: '08123456789',
  );

  test('should be a subclass of LeaveRequestModel', () async {
    expect(tLeaveRequestModel, isA<LeaveRequestModel>());
  });

  group('toJson', () {
    test(
      'should return a JSON map containing the proper data for multipart request',
      () async {
        // act
        final result = tLeaveRequestModel.toJson();
        // assert
        final expectedMap = {
          "leave_type_id": "1",
          "start_date": "2024-02-20",
          "end_date": "2024-02-21",
          "reason": "Sakit",
          "emergency_contact": "08123456789",
          "is_half_day": "0", // boolean converted to string 0/1 for multipart
        };
        expect(result, expectedMap);
      },
    );
  });
}
