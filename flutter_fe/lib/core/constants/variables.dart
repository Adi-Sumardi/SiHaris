/// API Variables - SSOT: https://gajipro.jagoflutter.com/docs?api-docs.json
/// API Version: 1.0.0
/// Base URL: /api/v1
/// Authentication: Bearer Token (Sanctum)
class Variables {
  // Production (server testing - siharis.yapinet.id):
  static const String baseUrl = 'https://siharis.yapinet.id';
  // Local development (iOS simulator menjangkau host via 127.0.0.1):
  // static const String baseUrl = 'http://127.0.0.1:8000';
  // Development (ganti dengan IP local untuk device fisik / Android emulator pakai 10.0.2.2):
  // static const String baseUrl = 'http://192.168.18.183:8000';

  static const String apiBaseUrl = '$baseUrl/api/v1';

  // ============================================
  // Authentication & Contact
  // ============================================
  static const String login = '$apiBaseUrl/auth/login';
  static const String requestOtp = '$apiBaseUrl/auth/request-otp';
  static const String verifyOtp = '$apiBaseUrl/auth/verify-otp';
  static const String demoRegister = '$apiBaseUrl/auth/demo-register';
  static const String logout = '$apiBaseUrl/auth/logout';
  static const String profile = '$apiBaseUrl/auth/profile';
  static const String changePassword = '$apiBaseUrl/auth/change-password';
  static const String deleteAccount = '$apiBaseUrl/auth/delete-account';
  static const String adminWhatsappUrl =
      'https://wa.me/6281292702075?text=Halo%20Admin%20SiHaris%2C%20saya%20butuh%20bantuan%20mengenai%20akun%20aplikasi';

  // ============================================
  // Dashboard
  // ============================================
  static const String dashboard = '$apiBaseUrl/dashboard';
  static const String dashboardAttendanceChart =
      '$apiBaseUrl/dashboard/attendance-chart';
  static const String dashboardQuickStats = '$apiBaseUrl/dashboard/quick-stats';

  // ============================================
  // Attendance
  // ============================================
  static const String attendanceToday = '$apiBaseUrl/attendance/today';
  static const String attendanceClockIn = '$apiBaseUrl/attendance/clock-in';
  static const String attendanceClockOut = '$apiBaseUrl/attendance/clock-out';
  static const String attendanceHistory = '$apiBaseUrl/attendance/history';
  static const String attendanceSummary = '$apiBaseUrl/attendance/summary';

  // ============================================
  // Leave Management
  // ============================================
  static const String leaves = '$apiBaseUrl/leaves';
  static String leaveDetail(int id) => '$apiBaseUrl/leaves/$id';
  static String leaveCancel(int id) => '$apiBaseUrl/leaves/$id/cancel';
  static const String leaveBalance = '$apiBaseUrl/leaves/balance';
  static const String leaveTypes = '$apiBaseUrl/leaves/types';

  // ============================================
  // Overtime
  // ============================================
  static const String overtime = '$apiBaseUrl/overtimes';
  static String overtimeDetail(int id) => '$apiBaseUrl/overtimes/$id';
  static String overtimeCancel(int id) => '$apiBaseUrl/overtimes/$id/cancel';
  static const String overtimeSummary = '$apiBaseUrl/overtimes/summary';

  // ============================================
  // Payslip / Payroll
  // ============================================
  static const String payslips = '$apiBaseUrl/payslips';
  static String payslipDetail(int id) => '$apiBaseUrl/payslips/$id';
  static String payslipDownload(int id) => '$apiBaseUrl/payslips/$id/download';
  static const String payslipSummary = '$apiBaseUrl/payslips/summary';

  // ============================================
  // Tax Forms (Bukti Potong 1721-A1)
  // ============================================
  static const String taxForms = '$apiBaseUrl/tax-forms';
  static const String taxFormYears = '$apiBaseUrl/tax-forms/years';
  static String taxFormDetail(int id) => '$apiBaseUrl/tax-forms/$id';
  static String taxFormDownload(int id) => '$apiBaseUrl/tax-forms/$id/download';

  // ============================================
  // Reimbursement
  // ============================================
  static const String reimbursements = '$apiBaseUrl/reimbursements';
  static String reimbursementDetail(int id) => '$apiBaseUrl/reimbursements/$id';
  static const String reimbursementCategories =
      '$apiBaseUrl/reimbursements/categories';
  static const String reimbursementSummary =
      '$apiBaseUrl/reimbursements/summary';

  // ============================================
  // Announcements
  // ============================================
  static const String announcements = '$apiBaseUrl/announcements';
  static String announcementDetail(int id) => '$apiBaseUrl/announcements/$id';
  static String announcementRead(int id) =>
      '$apiBaseUrl/announcements/$id/read';
  static const String announcementUnreadCount =
      '$apiBaseUrl/announcements/unread-count';

  static const String notifications = '$apiBaseUrl/notifications';
  static const String notificationUnreadCount =
      '$apiBaseUrl/notifications/unread-count';
  static const String notificationMarkAllRead =
      '$apiBaseUrl/notifications/mark-all-read';
  static String notificationRead(int id) =>
      '$apiBaseUrl/notifications/$id/read';
  static String notificationDelete(int id) => '$apiBaseUrl/notifications/$id';

  // ============================================
  // Approvals (Manager)
  // ============================================
  static const String approvalsPending = '$apiBaseUrl/approvals/pending';
  static const String approvalsHistory = '$apiBaseUrl/approvals/history';

  // Leave Approvals
  static String approveLeave(int id) =>
      '$apiBaseUrl/approvals/leave/$id/approve';
  static String rejectLeave(int id) => '$apiBaseUrl/approvals/leave/$id/reject';

  // Overtime Approvals
  static String approveOvertime(int id) =>
      '$apiBaseUrl/approvals/overtime/$id/approve';
  static String rejectOvertime(int id) =>
      '$apiBaseUrl/approvals/overtime/$id/reject';

  // Reimbursement Approvals
  static String approveReimbursement(int id) =>
      '$apiBaseUrl/approvals/reimbursement/$id/approve';
  static String rejectReimbursement(int id) =>
      '$apiBaseUrl/approvals/reimbursement/$id/reject';

  // ============================================
  // Face Recognition
  // ============================================
  static const String faceRecognitionStatus =
      '$apiBaseUrl/face-recognition/status';
  static const String faceRecognitionEnroll =
      '$apiBaseUrl/face-recognition/enroll';
  static const String faceRecognitionVerify =
      '$apiBaseUrl/face-recognition/verify';
  static const String faceRecognitionEnrollment =
      '$apiBaseUrl/face-recognition/enroll';
  static const String faceRecognitionResetRequest =
      '$apiBaseUrl/face-recognition/reset-request';
  static const String faceRecognitionResetRequestStatus =
      '$apiBaseUrl/face-recognition/reset-request/status';

  // ============================================
  // Office Location
  // ============================================
  static const String officeLocations = '$apiBaseUrl/office-locations';
  static const String officeLocationsAssigned =
      '$apiBaseUrl/office-locations/assigned';
  static String officeLocationDetail(int id) =>
      '$apiBaseUrl/office-locations/$id';
  static const String officeLocationsValidateGps =
      '$apiBaseUrl/office-locations/validate-gps';

  // ============================================
  // Employee Schedule (resolved shift per date)
  // ============================================
  static const String schedule = '$apiBaseUrl/schedule';

  // ============================================
  // Device Token (Push Notifications)
  // ============================================
  static const String deviceTokens = '$apiBaseUrl/device-tokens';
  static const String deviceTokenRegister =
      '$apiBaseUrl/device-tokens/register';
  static const String deviceTokenUnregister =
      '$apiBaseUrl/device-tokens/unregister';
  static const String deviceTokenRefresh = '$apiBaseUrl/device-tokens/refresh';
}
