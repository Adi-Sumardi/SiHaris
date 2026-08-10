/// Dashboard API Response Model
/// Sesuai dengan API docs: GET /dashboard
class DashboardResponseModel {
  final bool success;
  final String? message;
  final DashboardData? data;

  DashboardResponseModel({
    required this.success,
    this.message,
    this.data,
  });

  factory DashboardResponseModel.fromJson(Map<String, dynamic> json) {
    return DashboardResponseModel(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null ? DashboardData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

/// Dashboard Data - Contains all dashboard sections
class DashboardData {
  final DashboardAttendance? attendance;
  final DashboardLeave? leave;
  final DashboardPayroll? payroll;
  final DashboardRequests? requests;
  final DashboardSchedule? schedule;

  DashboardData({
    this.attendance,
    this.leave,
    this.payroll,
    this.requests,
    this.schedule,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      attendance: json['attendance'] != null
          ? DashboardAttendance.fromJson(json['attendance'])
          : null,
      leave:
          json['leave'] != null ? DashboardLeave.fromJson(json['leave']) : null,
      payroll: json['payroll'] != null
          ? DashboardPayroll.fromJson(json['payroll'])
          : null,
      requests: json['requests'] != null
          ? DashboardRequests.fromJson(json['requests'])
          : null,
      schedule: json['schedule'] != null
          ? DashboardSchedule.fromJson(json['schedule'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attendance': attendance?.toJson(),
      'leave': leave?.toJson(),
      'payroll': payroll?.toJson(),
      'requests': requests?.toJson(),
      'schedule': schedule?.toJson(),
    };
  }
}

/// Dashboard Schedule Section - Today's work schedule
class DashboardSchedule {
  final String name;
  final String startTime;
  final String endTime;
  final bool isOvernight;

  DashboardSchedule({
    required this.name,
    required this.startTime,
    required this.endTime,
    this.isOvernight = false,
  });

  factory DashboardSchedule.fromJson(Map<String, dynamic> json) {
    return DashboardSchedule(
      name: json['name'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      isOvernight: json['is_overnight'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'start_time': startTime,
      'end_time': endTime,
      'is_overnight': isOvernight,
    };
  }
}

/// Dashboard Attendance Section
/// { today_status, clock_in, clock_out, monthly_present, monthly_absent, monthly_late }
class DashboardAttendance {
  final String? todayStatus; // 'present', 'late', 'absent', null (not clocked in)
  final String? clockIn;
  final String? clockOut;
  final int monthlyPresent;
  final int monthlyAbsent;
  final int monthlyLate;

  DashboardAttendance({
    this.todayStatus,
    this.clockIn,
    this.clockOut,
    this.monthlyPresent = 0,
    this.monthlyAbsent = 0,
    this.monthlyLate = 0,
  });

  factory DashboardAttendance.fromJson(Map<String, dynamic> json) {
    return DashboardAttendance(
      todayStatus: json['today_status'],
      clockIn: json['clock_in'],
      clockOut: json['clock_out'],
      monthlyPresent: _parseInt(json['monthly_present']) ?? 0,
      monthlyAbsent: _parseInt(json['monthly_absent']) ?? 0,
      monthlyLate: _parseInt(json['monthly_late']) ?? 0,
    );
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
      'today_status': todayStatus,
      'clock_in': clockIn,
      'clock_out': clockOut,
      'monthly_present': monthlyPresent,
      'monthly_absent': monthlyAbsent,
      'monthly_late': monthlyLate,
    };
  }

  bool get isPresent => todayStatus == 'present';
  bool get isLate => todayStatus == 'late';
  bool get isAbsent => todayStatus == 'absent';
  bool get hasClockedIn => clockIn != null;
  bool get hasClockedOut => clockOut != null;

  String get formattedClockIn => clockIn ?? '--:--';
  String get formattedClockOut => clockOut ?? '--:--';

  /// Parse time string "HH:mm" to DateTime (today)
  DateTime? _parseTime(String? timeStr) {
    if (timeStr == null) return null;
    final parts = timeStr.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  /// Get working minutes so far
  /// If clocked out: returns difference between clock_out and clock_in
  /// If only clocked in: returns difference between now and clock_in
  int get workingMinutes {
    final clockInTime = _parseTime(clockIn);
    if (clockInTime == null) return 0;

    final endTime = _parseTime(clockOut) ?? DateTime.now();
    return endTime.difference(clockInTime).inMinutes.clamp(0, 1440);
  }

  /// Get working hours as formatted string (e.g., "5j 30m")
  String get formattedWorkingHours {
    final minutes = workingMinutes;
    if (minutes == 0 && !hasClockedIn) return '--';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) {
      return '${hours}j ${mins}m';
    } else if (hours > 0) {
      return '${hours}j';
    } else {
      return '${mins}m';
    }
  }

  /// Progress value for 8-hour workday (0.0 to 1.0)
  double get workingProgress {
    const targetMinutes = 8 * 60; // 8 hours
    return (workingMinutes / targetMinutes).clamp(0.0, 1.0);
  }
}

/// Dashboard Leave Section
/// { annual_balance, annual_used, pending_requests }
/// Note: annual_balance and annual_used can be float for half-day leaves
class DashboardLeave {
  final double annualBalance;
  final double annualUsed;
  final int pendingRequests;

  DashboardLeave({
    this.annualBalance = 0,
    this.annualUsed = 0,
    this.pendingRequests = 0,
  });

  factory DashboardLeave.fromJson(Map<String, dynamic> json) {
    return DashboardLeave(
      annualBalance: _parseDouble(json['annual_balance']) ?? 0,
      annualUsed: _parseDouble(json['annual_used']) ?? 0,
      pendingRequests: _parseInt(json['pending_requests']) ?? 0,
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
      'annual_balance': annualBalance,
      'annual_used': annualUsed,
      'pending_requests': pendingRequests,
    };
  }

  double get remaining => annualBalance - annualUsed;
}

/// Dashboard Payroll Section
/// { last_payslip_month, last_payslip_amount, ytd_gross, ytd_net }
class DashboardPayroll {
  final String? lastPayslipMonth;
  final double lastPayslipAmount;
  final double ytdGross;
  final double ytdNet;

  DashboardPayroll({
    this.lastPayslipMonth,
    this.lastPayslipAmount = 0,
    this.ytdGross = 0,
    this.ytdNet = 0,
  });

  factory DashboardPayroll.fromJson(Map<String, dynamic> json) {
    return DashboardPayroll(
      lastPayslipMonth: json['last_payslip_month'],
      lastPayslipAmount: _parseDouble(json['last_payslip_amount']) ?? 0,
      ytdGross: _parseDouble(json['ytd_gross']) ?? 0,
      ytdNet: _parseDouble(json['ytd_net']) ?? 0,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'last_payslip_month': lastPayslipMonth,
      'last_payslip_amount': lastPayslipAmount,
      'ytd_gross': ytdGross,
      'ytd_net': ytdNet,
    };
  }
}

/// Dashboard Requests Section
/// { pending_overtime, pending_reimbursement, pending_leave }
class DashboardRequests {
  final int pendingOvertime;
  final int pendingReimbursement;
  final int pendingLeave;

  DashboardRequests({
    this.pendingOvertime = 0,
    this.pendingReimbursement = 0,
    this.pendingLeave = 0,
  });

  factory DashboardRequests.fromJson(Map<String, dynamic> json) {
    return DashboardRequests(
      pendingOvertime: _parseInt(json['pending_overtime']) ?? 0,
      pendingReimbursement: _parseInt(json['pending_reimbursement']) ?? 0,
      pendingLeave: _parseInt(json['pending_leave']) ?? 0,
    );
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
      'pending_overtime': pendingOvertime,
      'pending_reimbursement': pendingReimbursement,
      'pending_leave': pendingLeave,
    };
  }

  int get totalPending => pendingOvertime + pendingReimbursement + pendingLeave;
}
