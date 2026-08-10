import 'dart:io';

class LeaveRequestModel {
  final int leaveTypeId;
  final String startDate;
  final String endDate;
  final bool isHalfDay;
  final String? halfDayType;
  final String? reason;
  final File? attachment;
  final String? emergencyContact;

  const LeaveRequestModel({
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    this.isHalfDay = false,
    this.halfDayType,
    this.reason,
    this.attachment,
    this.emergencyContact,
  });

  Map<String, String> toJson() {
    final Map<String, String> data = {
      'leave_type_id': leaveTypeId.toString(),
      'start_date': startDate,
      'end_date': endDate,
      'is_half_day': isHalfDay ? '1' : '0',
    };

    if (reason != null && reason!.isNotEmpty) {
      data['reason'] = reason!;
    }

    if (emergencyContact != null && emergencyContact!.isNotEmpty) {
      data['emergency_contact'] = emergencyContact!;
    }

    if (isHalfDay && halfDayType != null) {
      data['half_day_type'] = halfDayType!;
    }

    return data;
  }
}
