import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/responses/leave_balance_model.dart';

void main() {
  const tLeaveBalanceModel = LeaveBalanceModel(
    leaveTypeId: 1,
    leaveTypeName: 'Cuti Tahunan',
    year: 2026,
    entitledDays: 12,
    usedDays: 2,
    pendingDays: 1,
    remainingDays: 9,
  );

  test('should be a subclass of LeaveBalanceModel', () async {
    expect(tLeaveBalanceModel, isA<LeaveBalanceModel>());
  });

  group('fromJson', () {
    test('should return a valid model when the JSON is valid', () async {
      // arrange
      final Map<String, dynamic> jsonMap = {
        "leave_type_id": 1,
        "leave_type_name": "Cuti Tahunan",
        "year": 2026,
        "entitled_days": 12,
        "used_days": 2,
        "pending_days": 1,
        "remaining_days": 9,
      };
      // act
      final result = LeaveBalanceModel.fromJson(jsonMap);
      // assert
      expect(result, tLeaveBalanceModel);
    });

    test('should handle missing optional fields with defaults', () async {
      // arrange
      final Map<String, dynamic> jsonMap = {
        "entitled_days": 12,
        "used_days": 2,
        "pending_days": 1,
        "remaining_days": 9,
      };
      // act
      final result = LeaveBalanceModel.fromJson(jsonMap);
      // assert
      expect(result.leaveTypeId, 0);
      expect(result.leaveTypeName, '');
      expect(result.year, DateTime.now().year);
    });
  });

  group('toJson', () {
    test('should return a JSON map containing the proper data', () async {
      // act
      final result = tLeaveBalanceModel.toJson();
      // assert
      final expectedMap = {
        "leave_type_id": 1,
        "leave_type_name": "Cuti Tahunan",
        "year": 2026,
        "entitled_days": 12,
        "used_days": 2,
        "pending_days": 1,
        "remaining_days": 9,
      };
      expect(result, expectedMap);
    });
  });

  group('equality', () {
    test('should return true when comparing same values', () {
      const model1 = LeaveBalanceModel(
        leaveTypeId: 1,
        leaveTypeName: 'Cuti Tahunan',
        year: 2026,
        entitledDays: 12,
        usedDays: 2,
        pendingDays: 1,
        remainingDays: 9,
      );
      const model2 = LeaveBalanceModel(
        leaveTypeId: 1,
        leaveTypeName: 'Cuti Tahunan',
        year: 2026,
        entitledDays: 12,
        usedDays: 2,
        pendingDays: 1,
        remainingDays: 9,
      );
      expect(model1, model2);
    });

    test('should return false when comparing different values', () {
      const model1 = LeaveBalanceModel(
        leaveTypeId: 1,
        leaveTypeName: 'Cuti Tahunan',
        year: 2026,
        entitledDays: 12,
        usedDays: 2,
        pendingDays: 1,
        remainingDays: 9,
      );
      const model2 = LeaveBalanceModel(
        leaveTypeId: 2,
        leaveTypeName: 'Cuti Sakit',
        year: 2026,
        entitledDays: 14,
        usedDays: 0,
        pendingDays: 0,
        remainingDays: 14,
      );
      expect(model1, isNot(model2));
    });
  });
}
