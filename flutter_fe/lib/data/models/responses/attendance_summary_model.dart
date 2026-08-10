class AttendanceSummaryModel {
  final int totalWorkingDays;
  final int present;
  final int absent;
  final int late;
  final int leave;
  final String workingHours;
  final String overtimeHours;

  const AttendanceSummaryModel({
    required this.totalWorkingDays,
    required this.present,
    required this.absent,
    required this.late,
    required this.leave,
    required this.workingHours,
    required this.overtimeHours,
  });

  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    // Handle working_hours - API returns number, convert to string
    final workingHoursValue = json['total_working_hours'];
    String workingHoursStr = '';
    if (workingHoursValue != null) {
      if (workingHoursValue is num) {
        workingHoursStr = '${workingHoursValue.toStringAsFixed(1)}j';
      } else {
        workingHoursStr = workingHoursValue.toString();
      }
    }

    // Handle overtime_hours - API returns number, convert to string
    final overtimeHoursValue = json['total_overtime_hours'];
    String overtimeHoursStr = '';
    if (overtimeHoursValue != null) {
      if (overtimeHoursValue is num) {
        overtimeHoursStr = '${overtimeHoursValue.toStringAsFixed(1)}j';
      } else {
        overtimeHoursStr = overtimeHoursValue.toString();
      }
    }

    return AttendanceSummaryModel(
      totalWorkingDays: json['total_working_days'] ?? 0,
      present: json['total_present'] ?? json['present'] ?? 0,
      absent: json['total_absent'] ?? json['absent'] ?? 0,
      late: json['total_late'] ?? json['late'] ?? 0,
      leave: json['total_leave'] ?? json['leave'] ?? 0,
      workingHours: workingHoursStr,
      overtimeHours: overtimeHoursStr,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_working_days': totalWorkingDays,
      'present': present,
      'absent': absent,
      'late': late,
      'leave': leave,
      'working_hours': workingHours,
      'overtime_hours': overtimeHours,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AttendanceSummaryModel &&
        other.totalWorkingDays == totalWorkingDays &&
        other.present == present &&
        other.absent == absent &&
        other.late == late &&
        other.leave == leave &&
        other.workingHours == workingHours &&
        other.overtimeHours == overtimeHours;
  }

  @override
  int get hashCode {
    return totalWorkingDays.hashCode ^
        present.hashCode ^
        absent.hashCode ^
        late.hashCode ^
        leave.hashCode ^
        workingHours.hashCode ^
        overtimeHours.hashCode;
  }
}
