import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/responses/leave_type_model.dart';
// import '../../../../fixtures/fixture_reader.dart'; // Not used in this test actually

void main() {
  const tLeaveTypeModel = LeaveTypeModel(
    id: 1,
    name: 'Cuti Tahunan',
    quota: 12,
    isPaid: true,
    requiresAttachment: false,
  );

  test('should be a subclass of LeaveTypeModel entity', () async {
    expect(tLeaveTypeModel, isA<LeaveTypeModel>());
  });

  group('fromJson', () {
    test('should return a valid model when the JSON is valid', () async {
      // arrange
      final Map<String, dynamic> jsonMap = {
        "id": 1,
        "name": "Cuti Tahunan",
        "quota": 12,
        "is_paid": true,
        "requires_attachment": false,
      };
      // act
      final result = LeaveTypeModel.fromJson(jsonMap);
      // assert
      expect(result, tLeaveTypeModel);
    });
  });

  group('toJson', () {
    test('should return a JSON map containing the proper data', () async {
      // act
      final result = tLeaveTypeModel.toJson();
      // assert
      final expectedMap = {
        "id": 1,
        "name": "Cuti Tahunan",
        "quota": 12,
        "is_paid": true,
        "requires_attachment": false,
      };
      expect(result, expectedMap);
    });
  });
}
