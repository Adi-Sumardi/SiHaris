/// Quick Stats Model
/// Sesuai dengan API docs: GET /dashboard/quick-stats
/// {
///   total_working_days_this_month, total_present_days, total_absent_days,
///   total_leave_days, total_late_count, total_overtime_hours, attendance_percentage
/// }
class QuickStatsModel {
  final int totalWorkingDaysThisMonth;
  final int totalPresentDays;
  final int totalAbsentDays;
  final int totalLeaveDays;
  final int totalLateCount;
  final double totalOvertimeHours;
  final double attendancePercentage;

  QuickStatsModel({
    this.totalWorkingDaysThisMonth = 0,
    this.totalPresentDays = 0,
    this.totalAbsentDays = 0,
    this.totalLeaveDays = 0,
    this.totalLateCount = 0,
    this.totalOvertimeHours = 0,
    this.attendancePercentage = 0,
  });

  factory QuickStatsModel.fromJson(Map<String, dynamic> json) {
    return QuickStatsModel(
      totalWorkingDaysThisMonth: _parseInt(json['total_working_days_this_month']) ?? 0,
      totalPresentDays: _parseInt(json['total_present_days']) ?? 0,
      totalAbsentDays: _parseInt(json['total_absent_days']) ?? 0,
      totalLeaveDays: _parseInt(json['total_leave_days']) ?? 0,
      totalLateCount: _parseInt(json['total_late_count']) ?? 0,
      totalOvertimeHours: _parseDouble(json['total_overtime_hours']) ?? 0,
      attendancePercentage: _parseDouble(json['attendance_percentage']) ?? 0,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'total_working_days_this_month': totalWorkingDaysThisMonth,
      'total_present_days': totalPresentDays,
      'total_absent_days': totalAbsentDays,
      'total_leave_days': totalLeaveDays,
      'total_late_count': totalLateCount,
      'total_overtime_hours': totalOvertimeHours,
      'attendance_percentage': attendancePercentage,
    };
  }

  // Helper getters untuk UI
  String get attendanceDisplay =>
      '$totalPresentDays/$totalWorkingDaysThisMonth Hari';
  String get absentDisplay => '$totalAbsentDays Hari';
  String get leaveDisplay => '$totalLeaveDays Hari';
  String get lateDisplay => '$totalLateCount Kali';
  String get overtimeDisplay => '${totalOvertimeHours.toStringAsFixed(1)} Jam';
  String get percentageDisplay =>
      '${attendancePercentage.toStringAsFixed(1)}%';
}
