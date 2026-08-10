import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/responses/dashboard/dashboard_models.dart';

void main() {
  group('DashboardResponseModel', () {
    test('should create instance with required fields', () {
      final response = DashboardResponseModel(success: true);

      expect(response.success, true);
      expect(response.message, isNull);
      expect(response.data, isNull);
    });

    test('fromJson should parse correctly', () {
      final json = {
        'success': true,
        'message': 'Berhasil',
        'data': {
          'attendance': {
            'today_status': 'present',
            'clock_in': '08:00',
            'clock_out': '17:00',
            'monthly_present': 20,
            'monthly_absent': 1,
            'monthly_late': 2,
          },
          'leave': {
            'annual_balance': 12.0,
            'annual_used': 3.5,
            'pending_requests': 1,
          },
          'payroll': {
            'last_payslip_month': 'Januari 2026',
            'last_payslip_amount': 5000000,
            'ytd_gross': 60000000,
            'ytd_net': 55000000,
          },
          'requests': {
            'pending_overtime': 2,
            'pending_reimbursement': 1,
            'pending_leave': 0,
          },
        },
      };

      final response = DashboardResponseModel.fromJson(json);

      expect(response.success, true);
      expect(response.message, 'Berhasil');
      expect(response.data, isNotNull);
      expect(response.data!.attendance, isNotNull);
      expect(response.data!.attendance!.todayStatus, 'present');
      expect(response.data!.leave, isNotNull);
      expect(response.data!.leave!.annualBalance, 12.0);
      expect(response.data!.payroll, isNotNull);
      expect(response.data!.payroll!.lastPayslipAmount, 5000000);
      expect(response.data!.requests, isNotNull);
      expect(response.data!.requests!.pendingOvertime, 2);
    });

    test('fromJson should handle null data', () {
      final json = {
        'success': false,
        'message': 'Error',
      };

      final response = DashboardResponseModel.fromJson(json);

      expect(response.success, false);
      expect(response.data, isNull);
    });

    test('toJson should return correct map', () {
      final response = DashboardResponseModel(
        success: true,
        message: 'OK',
        data: DashboardData(
          attendance: DashboardAttendance(
            todayStatus: 'present',
            clockIn: '08:00',
            monthlyPresent: 20,
          ),
        ),
      );

      final json = response.toJson();

      expect(json['success'], true);
      expect(json['message'], 'OK');
      expect(json['data'], isNotNull);
    });
  });

  group('DashboardData', () {
    test('should create instance with all sections', () {
      final data = DashboardData(
        attendance: DashboardAttendance(todayStatus: 'present'),
        leave: DashboardLeave(annualBalance: 12),
        payroll: DashboardPayroll(lastPayslipAmount: 5000000),
        requests: DashboardRequests(pendingOvertime: 1),
      );

      expect(data.attendance, isNotNull);
      expect(data.leave, isNotNull);
      expect(data.payroll, isNotNull);
      expect(data.requests, isNotNull);
    });

    test('fromJson should parse all sections', () {
      final json = {
        'attendance': {
          'today_status': 'late',
          'clock_in': '09:15',
          'clock_out': null,
          'monthly_present': 18,
          'monthly_absent': 2,
          'monthly_late': 3,
        },
        'leave': {
          'annual_balance': 10,
          'annual_used': 5,
          'pending_requests': 2,
        },
        'payroll': {
          'last_payslip_month': 'Februari 2026',
          'last_payslip_amount': 6000000,
          'ytd_gross': 72000000,
          'ytd_net': 65000000,
        },
        'requests': {
          'pending_overtime': 3,
          'pending_reimbursement': 2,
          'pending_leave': 1,
        },
      };

      final data = DashboardData.fromJson(json);

      expect(data.attendance!.todayStatus, 'late');
      expect(data.attendance!.clockIn, '09:15');
      expect(data.attendance!.monthlyLate, 3);
      expect(data.leave!.annualUsed, 5.0);
      expect(data.payroll!.lastPayslipMonth, 'Februari 2026');
      expect(data.requests!.pendingLeave, 1);
    });
  });

  group('DashboardAttendance', () {
    test('should create instance with all fields', () {
      final attendance = DashboardAttendance(
        todayStatus: 'present',
        clockIn: '08:00',
        clockOut: '17:00',
        monthlyPresent: 20,
        monthlyAbsent: 1,
        monthlyLate: 2,
      );

      expect(attendance.todayStatus, 'present');
      expect(attendance.clockIn, '08:00');
      expect(attendance.clockOut, '17:00');
      expect(attendance.monthlyPresent, 20);
      expect(attendance.monthlyAbsent, 1);
      expect(attendance.monthlyLate, 2);
    });

    test('fromJson should parse correctly', () {
      final json = {
        'today_status': 'absent',
        'clock_in': null,
        'clock_out': null,
        'monthly_present': 15,
        'monthly_absent': 5,
        'monthly_late': 0,
      };

      final attendance = DashboardAttendance.fromJson(json);

      expect(attendance.todayStatus, 'absent');
      expect(attendance.clockIn, isNull);
      expect(attendance.monthlyPresent, 15);
    });

    test('should have correct helper getters', () {
      final present = DashboardAttendance(todayStatus: 'present');
      final late = DashboardAttendance(todayStatus: 'late');
      final absent = DashboardAttendance(todayStatus: 'absent');

      expect(present.isPresent, true);
      expect(present.isLate, false);
      expect(late.isLate, true);
      expect(absent.isAbsent, true);
      expect(present.hasClockedIn, false);
    });

    test('hasClockedIn should return true when clockIn is set', () {
      final attendance = DashboardAttendance(
        todayStatus: 'present',
        clockIn: '08:00',
      );

      expect(attendance.hasClockedIn, true);
      expect(attendance.hasClockedOut, false);
    });

    test('toJson should return correct map', () {
      final attendance = DashboardAttendance(
        todayStatus: 'present',
        clockIn: '08:00',
        clockOut: '17:00',
        monthlyPresent: 20,
        monthlyAbsent: 1,
        monthlyLate: 2,
      );

      final json = attendance.toJson();

      expect(json['today_status'], 'present');
      expect(json['clock_in'], '08:00');
      expect(json['clock_out'], '17:00');
      expect(json['monthly_present'], 20);
    });
  });

  group('DashboardLeave', () {
    test('should create instance with all fields', () {
      final leave = DashboardLeave(
        annualBalance: 12,
        annualUsed: 5,
        pendingRequests: 2,
      );

      expect(leave.annualBalance, 12.0);
      expect(leave.annualUsed, 5.0);
      expect(leave.pendingRequests, 2);
    });

    test('fromJson should parse correctly', () {
      final json = {
        'annual_balance': 10,
        'annual_used': 3,
        'pending_requests': 1,
      };

      final leave = DashboardLeave.fromJson(json);

      expect(leave.annualBalance, 10.0);
      expect(leave.annualUsed, 3.0);
      expect(leave.pendingRequests, 1);
    });

    test('fromJson should handle float values for half-day leaves', () {
      final json = {
        'annual_balance': 12.0,
        'annual_used': 5.5,
        'pending_requests': 1,
      };

      final leave = DashboardLeave.fromJson(json);

      expect(leave.annualBalance, 12.0);
      expect(leave.annualUsed, 5.5);
      expect(leave.remaining, 6.5);
    });

    test('should calculate remaining correctly', () {
      final leave = DashboardLeave(
        annualBalance: 12,
        annualUsed: 5,
      );

      expect(leave.remaining, 7.0);
    });

    test('toJson should return correct map', () {
      final leave = DashboardLeave(
        annualBalance: 12,
        annualUsed: 5,
        pendingRequests: 1,
      );

      final json = leave.toJson();

      expect(json['annual_balance'], 12.0);
      expect(json['annual_used'], 5.0);
      expect(json['pending_requests'], 1);
    });
  });

  group('DashboardPayroll', () {
    test('should create instance with all fields', () {
      final payroll = DashboardPayroll(
        lastPayslipMonth: 'Januari 2026',
        lastPayslipAmount: 5000000,
        ytdGross: 60000000,
        ytdNet: 55000000,
      );

      expect(payroll.lastPayslipMonth, 'Januari 2026');
      expect(payroll.lastPayslipAmount, 5000000);
      expect(payroll.ytdGross, 60000000);
      expect(payroll.ytdNet, 55000000);
    });

    test('fromJson should parse correctly', () {
      final json = {
        'last_payslip_month': 'Februari 2026',
        'last_payslip_amount': 6000000,
        'ytd_gross': 72000000,
        'ytd_net': 65000000,
      };

      final payroll = DashboardPayroll.fromJson(json);

      expect(payroll.lastPayslipMonth, 'Februari 2026');
      expect(payroll.lastPayslipAmount, 6000000);
      expect(payroll.ytdGross, 72000000);
      expect(payroll.ytdNet, 65000000);
    });

    test('fromJson should handle integer and double values', () {
      final json = {
        'last_payslip_month': 'Maret 2026',
        'last_payslip_amount': 5500000.50,
        'ytd_gross': 66000000,
        'ytd_net': 60000000.75,
      };

      final payroll = DashboardPayroll.fromJson(json);

      expect(payroll.lastPayslipAmount, 5500000.50);
      expect(payroll.ytdGross, 66000000);
      expect(payroll.ytdNet, 60000000.75);
    });

    test('toJson should return correct map', () {
      final payroll = DashboardPayroll(
        lastPayslipMonth: 'Januari 2026',
        lastPayslipAmount: 5000000,
        ytdGross: 60000000,
        ytdNet: 55000000,
      );

      final json = payroll.toJson();

      expect(json['last_payslip_month'], 'Januari 2026');
      expect(json['last_payslip_amount'], 5000000);
      expect(json['ytd_gross'], 60000000);
      expect(json['ytd_net'], 55000000);
    });
  });

  group('DashboardRequests', () {
    test('should create instance with all fields', () {
      final requests = DashboardRequests(
        pendingOvertime: 2,
        pendingReimbursement: 3,
        pendingLeave: 1,
      );

      expect(requests.pendingOvertime, 2);
      expect(requests.pendingReimbursement, 3);
      expect(requests.pendingLeave, 1);
    });

    test('fromJson should parse correctly', () {
      final json = {
        'pending_overtime': 1,
        'pending_reimbursement': 2,
        'pending_leave': 0,
      };

      final requests = DashboardRequests.fromJson(json);

      expect(requests.pendingOvertime, 1);
      expect(requests.pendingReimbursement, 2);
      expect(requests.pendingLeave, 0);
    });

    test('should calculate total pending', () {
      final requests = DashboardRequests(
        pendingOvertime: 2,
        pendingReimbursement: 3,
        pendingLeave: 1,
      );

      expect(requests.totalPending, 6);
    });

    test('should handle default values', () {
      final requests = DashboardRequests();

      expect(requests.pendingOvertime, 0);
      expect(requests.pendingReimbursement, 0);
      expect(requests.pendingLeave, 0);
      expect(requests.totalPending, 0);
    });

    test('toJson should return correct map', () {
      final requests = DashboardRequests(
        pendingOvertime: 2,
        pendingReimbursement: 3,
        pendingLeave: 1,
      );

      final json = requests.toJson();

      expect(json['pending_overtime'], 2);
      expect(json['pending_reimbursement'], 3);
      expect(json['pending_leave'], 1);
    });
  });

  group('AttendanceChartModel', () {
    test('should create instance with labels and datasets', () {
      final chart = AttendanceChartModel(
        labels: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum'],
        datasets: [
          ChartDataset(label: 'Jam Kerja', data: [8.0, 8.5, 7.5, 8.0, 9.0]),
        ],
      );

      expect(chart.labels.length, 5);
      expect(chart.datasets.length, 1);
      expect(chart.datasets[0].label, 'Jam Kerja');
      expect(chart.datasets[0].data.length, 5);
    });

    test('fromJson should parse correctly', () {
      final json = {
        'labels': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        'datasets': [
          {
            'label': 'Working Hours',
            'data': [8.0, 8.5, 7.5, 8.0, 9.0, 0.0, 0.0],
          },
        ],
      };

      final chart = AttendanceChartModel.fromJson(json);

      expect(chart.labels.length, 7);
      expect(chart.labels[0], 'Mon');
      expect(chart.datasets.length, 1);
      expect(chart.datasets[0].label, 'Working Hours');
      expect(chart.datasets[0].data[0], 8.0);
    });

    test('fromJson should handle integer data values', () {
      final json = {
        'labels': ['Mon', 'Tue'],
        'datasets': [
          {
            'label': 'Hours',
            'data': [8, 9], // integers instead of doubles
          },
        ],
      };

      final chart = AttendanceChartModel.fromJson(json);

      expect(chart.datasets[0].data[0], 8.0);
      expect(chart.datasets[0].data[1], 9.0);
    });

    test('fromJson should handle empty datasets', () {
      final json = {
        'labels': [],
        'datasets': [],
      };

      final chart = AttendanceChartModel.fromJson(json);

      expect(chart.labels, isEmpty);
      expect(chart.datasets, isEmpty);
    });

    test('toJson should return correct map', () {
      final chart = AttendanceChartModel(
        labels: ['Mon', 'Tue'],
        datasets: [
          ChartDataset(label: 'Hours', data: [8.0, 9.0]),
        ],
      );

      final json = chart.toJson();

      expect(json['labels'], ['Mon', 'Tue']);
      expect(json['datasets'].length, 1);
      expect(json['datasets'][0]['label'], 'Hours');
      expect(json['datasets'][0]['data'], [8.0, 9.0]);
    });
  });

  group('ChartDataset', () {
    test('should create instance with label and data', () {
      final dataset = ChartDataset(
        label: 'Working Hours',
        data: [8.0, 8.5, 7.5],
      );

      expect(dataset.label, 'Working Hours');
      expect(dataset.data.length, 3);
    });

    test('fromJson should parse correctly', () {
      final json = {
        'label': 'Overtime',
        'data': [1.0, 2.0, 0.0],
      };

      final dataset = ChartDataset.fromJson(json);

      expect(dataset.label, 'Overtime');
      expect(dataset.data, [1.0, 2.0, 0.0]);
    });

    test('toJson should return correct map', () {
      final dataset = ChartDataset(
        label: 'Hours',
        data: [8.0, 9.0],
      );

      final json = dataset.toJson();

      expect(json['label'], 'Hours');
      expect(json['data'], [8.0, 9.0]);
    });
  });

  group('QuickStatsModel', () {
    test('should create instance with all fields', () {
      final stats = QuickStatsModel(
        totalWorkingDaysThisMonth: 22,
        totalPresentDays: 20,
        totalAbsentDays: 1,
        totalLeaveDays: 1,
        totalLateCount: 3,
        totalOvertimeHours: 10.5,
        attendancePercentage: 90.9,
      );

      expect(stats.totalWorkingDaysThisMonth, 22);
      expect(stats.totalPresentDays, 20);
      expect(stats.totalAbsentDays, 1);
      expect(stats.totalLeaveDays, 1);
      expect(stats.totalLateCount, 3);
      expect(stats.totalOvertimeHours, 10.5);
      expect(stats.attendancePercentage, 90.9);
    });

    test('fromJson should parse correctly', () {
      final json = {
        'total_working_days_this_month': 22,
        'total_present_days': 18,
        'total_absent_days': 2,
        'total_leave_days': 2,
        'total_late_count': 5,
        'total_overtime_hours': 8.0,
        'attendance_percentage': 81.8,
      };

      final stats = QuickStatsModel.fromJson(json);

      expect(stats.totalWorkingDaysThisMonth, 22);
      expect(stats.totalPresentDays, 18);
      expect(stats.totalAbsentDays, 2);
      expect(stats.totalLeaveDays, 2);
      expect(stats.totalLateCount, 5);
      expect(stats.totalOvertimeHours, 8.0);
      expect(stats.attendancePercentage, 81.8);
    });

    test('fromJson should handle integer values for doubles', () {
      final json = {
        'total_working_days_this_month': 20,
        'total_present_days': 18,
        'total_absent_days': 1,
        'total_leave_days': 1,
        'total_late_count': 2,
        'total_overtime_hours': 5, // integer
        'attendance_percentage': 90, // integer
      };

      final stats = QuickStatsModel.fromJson(json);

      expect(stats.totalOvertimeHours, 5.0);
      expect(stats.attendancePercentage, 90.0);
    });

    test('fromJson should handle null values with defaults', () {
      final json = <String, dynamic>{};

      final stats = QuickStatsModel.fromJson(json);

      expect(stats.totalWorkingDaysThisMonth, 0);
      expect(stats.totalPresentDays, 0);
      expect(stats.totalAbsentDays, 0);
      expect(stats.totalLeaveDays, 0);
      expect(stats.totalLateCount, 0);
      expect(stats.totalOvertimeHours, 0.0);
      expect(stats.attendancePercentage, 0.0);
    });

    test('toJson should return correct map', () {
      final stats = QuickStatsModel(
        totalWorkingDaysThisMonth: 22,
        totalPresentDays: 20,
        totalAbsentDays: 1,
        totalLeaveDays: 1,
        totalLateCount: 3,
        totalOvertimeHours: 10.5,
        attendancePercentage: 90.9,
      );

      final json = stats.toJson();

      expect(json['total_working_days_this_month'], 22);
      expect(json['total_present_days'], 20);
      expect(json['total_absent_days'], 1);
      expect(json['total_leave_days'], 1);
      expect(json['total_late_count'], 3);
      expect(json['total_overtime_hours'], 10.5);
      expect(json['attendance_percentage'], 90.9);
    });

    test('helper getters should return correct formatted strings', () {
      final stats = QuickStatsModel(
        totalWorkingDaysThisMonth: 22,
        totalPresentDays: 20,
        totalAbsentDays: 1,
        totalLeaveDays: 1,
        totalLateCount: 3,
        totalOvertimeHours: 10.5,
        attendancePercentage: 90.9,
      );

      expect(stats.attendanceDisplay, '20/22 Hari');
      expect(stats.absentDisplay, '1 Hari');
      expect(stats.leaveDisplay, '1 Hari');
      expect(stats.lateDisplay, '3 Kali');
      expect(stats.overtimeDisplay, '10.5 Jam');
      expect(stats.percentageDisplay, '90.9%');
    });
  });
}
