import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants/colors.dart';
import 'core/services/offline_attendance/offline_attendance_service.dart';
import 'core/services/session_service.dart';
import 'presentation/auth/bloc/login/login_bloc.dart';
import 'presentation/auth/bloc/logout/logout_bloc.dart';
import 'presentation/auth/bloc/profile/profile_bloc.dart';
import 'presentation/auth/bloc/change_password/change_password_bloc.dart';
import 'presentation/auth/bloc/register/register_bloc.dart';
import 'presentation/splash/pages/splash_screen.dart';

import 'package:http/http.dart' as http;
import 'data/datasources/auth_local_datasource.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/leave_remote_datasource.dart';
import 'data/datasources/payslip_remote_datasource.dart';
import 'data/datasources/attendance_remote_datasource.dart';
import 'data/datasources/schedule_remote_datasource.dart';
import 'data/datasources/dashboard_remote_datasource.dart';
import 'data/datasources/face_recognition_datasource.dart';
import 'data/datasources/office_location_remote_datasource.dart';
import 'presentation/leave/bloc/leave_types/leave_types_bloc.dart';
import 'presentation/leave/bloc/leave_balance/leave_balance_bloc.dart';
import 'presentation/leave/bloc/leave_list/leave_list_bloc.dart';
import 'presentation/leave/bloc/leave_crud/leave_crud_bloc.dart';
import 'presentation/payslip/bloc/payslip_list/payslip_list_bloc.dart';
import 'presentation/payslip/bloc/payslip_detail/payslip_detail_bloc.dart';
import 'presentation/payslip/bloc/payslip_download/payslip_download_bloc.dart';
import 'presentation/payslip/bloc/payslip_summary/payslip_summary_bloc.dart';
import 'data/datasources/reimbursement_remote_datasource.dart';
import 'presentation/reimbursement/bloc/reimbursement_list/reimbursement_list_bloc.dart';
import 'presentation/reimbursement/bloc/reimbursement_detail/reimbursement_detail_bloc.dart';
import 'presentation/reimbursement/bloc/reimbursement_request/reimbursement_request_bloc.dart';
import 'presentation/reimbursement/bloc/reimbursement_category/reimbursement_category_bloc.dart';
import 'presentation/reimbursement/bloc/reimbursement_summary/reimbursement_summary_bloc.dart';
import 'data/datasources/announcement_remote_datasource.dart';
import 'presentation/announcement/bloc/announcement_list/announcement_list_bloc.dart';
import 'presentation/announcement/bloc/announcement_detail/announcement_detail_bloc.dart';
import 'presentation/announcement/bloc/announcement_mark_read/announcement_mark_read_bloc.dart';
import 'presentation/announcement/bloc/announcement_unread_count/announcement_unread_count_bloc.dart';
import 'data/datasources/notification_remote_datasource.dart';
import 'presentation/notification/bloc/notification_list/notification_list_bloc.dart';
import 'presentation/notification/bloc/notification_unread_count/notification_unread_count_bloc.dart';
import 'data/datasources/approval_remote_datasource.dart';
import 'presentation/approval/bloc/approval_pending/approval_pending_bloc.dart';
import 'presentation/approval/bloc/approval_action/approval_action_bloc.dart';
import 'presentation/approval/bloc/approval_history/approval_history_bloc.dart';
import 'data/datasources/overtime_remote_datasource.dart';
import 'presentation/overtime/bloc/list/overtime_list_bloc.dart';
import 'presentation/notification/bloc/device_token/device_token_bloc.dart';
import 'data/datasources/device_token_remote_datasource.dart';
import 'presentation/notification/widgets/notification_wrapper.dart';
import 'presentation/overtime/bloc/action/overtime_action_bloc.dart';
import 'presentation/overtime/bloc/summary/overtime_summary_bloc.dart';
// Dashboard & Attendance BLoCs
import 'presentation/dashboard/bloc/dashboard_blocs.dart';
import 'presentation/attendance/bloc/attendance/attendance_bloc.dart';
import 'presentation/attendance/bloc/attendance_today/attendance_today_bloc.dart';
import 'presentation/attendance/bloc/attendance_history/attendance_history_bloc.dart';
import 'presentation/attendance/bloc/attendance_summary/attendance_summary_bloc.dart';
import 'presentation/schedule/bloc/schedule/schedule_bloc.dart';
import 'presentation/face_recognition/bloc/face_recognition_status/face_recognition_status_bloc.dart';
import 'presentation/face_recognition/bloc/face_enroll/face_enroll_bloc.dart';
import 'presentation/office_location/bloc/office_location/office_location_bloc.dart';
import 'presentation/office_location/bloc/gps_validation/gps_validation_bloc.dart';
import 'presentation/profile/bloc/update_profile/update_profile_bloc.dart';
// Tax Form BLoCs
import 'data/datasources/tax_form_remote_datasource.dart';
import 'presentation/tax_form/bloc/tax_form_list/tax_form_list_bloc.dart';
import 'presentation/tax_form/bloc/tax_form_detail/tax_form_detail_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Sinkronkan absensi offline yang tertunda saat aplikasi dibuka (fire-and-forget).
  OfflineAttendanceService.instance.refreshCount();
  AttendanceRemoteDatasource().syncPendingAttendance();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const GajiProApp());
}

class GajiProApp extends StatelessWidget {
  const GajiProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => LoginBloc()),
        BlocProvider(create: (context) => RegisterBloc()),
        BlocProvider(create: (context) => LogoutBloc()),
        BlocProvider(create: (context) => ProfileBloc()),
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final leaveDatasource = LeaveRemoteDatasource(
              client: client,
              authLocalDatasource: authLocal,
            );
            return LeaveTypesBloc(leaveDatasource);
          },
        ),
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final leaveDatasource = LeaveRemoteDatasource(
              client: client,
              authLocalDatasource: authLocal,
            );
            return LeaveBalanceBloc(leaveDatasource);
          },
        ),
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final leaveDatasource = LeaveRemoteDatasource(
              client: client,
              authLocalDatasource: authLocal,
            );
            return LeaveListBloc(leaveDatasource);
          },
        ),
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final leaveDatasource = LeaveRemoteDatasource(
              client: client,
              authLocalDatasource: authLocal,
            );
            return LeaveCrudBloc(leaveDatasource);
          },
        ),
        // Payslip BLoCs
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final payslipDatasource = PayslipRemoteDatasource(
              client: client,
              authLocalDatasource: authLocal,
            );
            return PayslipListBloc(datasource: payslipDatasource);
          },
        ),
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final payslipDatasource = PayslipRemoteDatasource(
              client: client,
              authLocalDatasource: authLocal,
            );
            return PayslipDetailBloc(datasource: payslipDatasource);
          },
        ),
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final payslipDatasource = PayslipRemoteDatasource(
              client: client,
              authLocalDatasource: authLocal,
            );
            return PayslipDownloadBloc(datasource: payslipDatasource);
          },
        ),
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final payslipDatasource = PayslipRemoteDatasource(
              client: client,
              authLocalDatasource: authLocal,
            );
            return PayslipSummaryBloc(datasource: payslipDatasource);
          },
        ),
        // Reimbursement BLoCs
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final reimbursementDatasource = ReimbursementRemoteDatasource(
              client,
              authLocal,
            );
            return ReimbursementListBloc(reimbursementDatasource);
          },
        ),
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final reimbursementDatasource = ReimbursementRemoteDatasource(
              client,
              authLocal,
            );
            return ReimbursementDetailBloc(reimbursementDatasource);
          },
        ),
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final reimbursementDatasource = ReimbursementRemoteDatasource(
              client,
              authLocal,
            );
            return ReimbursementRequestBloc(reimbursementDatasource);
          },
        ),
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final reimbursementDatasource = ReimbursementRemoteDatasource(
              client,
              authLocal,
            );
            return ReimbursementCategoryBloc(reimbursementDatasource);
          },
        ),
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final reimbursementDatasource = ReimbursementRemoteDatasource(
              client,
              authLocal,
            );
            return ReimbursementSummaryBloc(reimbursementDatasource);
          },
        ),
        // Announcement BLoCs
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final announcementDatasource = AnnouncementRemoteDatasource(
              client,
              authLocal,
            );
            return AnnouncementListBloc(announcementDatasource);
          },
        ),
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final announcementDatasource = AnnouncementRemoteDatasource(
              client,
              authLocal,
            );
            return AnnouncementDetailBloc(announcementDatasource);
          },
        ),
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final announcementDatasource = AnnouncementRemoteDatasource(
              client,
              authLocal,
            );
            return AnnouncementMarkReadBloc(announcementDatasource);
          },
        ),
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final announcementDatasource = AnnouncementRemoteDatasource(
              client,
              authLocal,
            );
            return AnnouncementUnreadCountBloc(announcementDatasource);
          },
        ),
        // Notification BLoCs
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final notificationDatasource = NotificationRemoteDatasource(
              client,
              authLocal,
            );
            return NotificationListBloc(notificationDatasource);
          },
        ),
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final notificationDatasource = NotificationRemoteDatasource(
              client,
              authLocal,
            );
            return NotificationUnreadCountBloc(notificationDatasource);
          },
        ),
        // Approval BLoCs
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final approvalDatasource = ApprovalRemoteDatasource(
              client,
              authLocal,
            );
            return ApprovalPendingBloc(approvalDatasource);
          },
        ),
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final approvalDatasource = ApprovalRemoteDatasource(
              client,
              authLocal,
            );
            return ApprovalActionBloc(approvalDatasource);
          },
        ),
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final approvalDatasource = ApprovalRemoteDatasource(
              client,
              authLocal,
            );
            return ApprovalHistoryBloc(approvalDatasource);
          },
        ),
        // Overtime BLoCs
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final deviceTokenDatasource = DeviceTokenRemoteDatasource(
              client,
              authLocal,
            );
            return DeviceTokenBloc(deviceTokenDatasource);
          },
        ),
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final overtimeDatasource = OvertimeRemoteDatasource(
              client,
              authLocal,
            );
            return OvertimeListBloc(overtimeDatasource);
          },
        ),
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final overtimeDatasource = OvertimeRemoteDatasource(
              client,
              authLocal,
            );
            return OvertimeActionBloc(overtimeDatasource);
          },
        ),
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final overtimeDatasource = OvertimeRemoteDatasource(
              client,
              authLocal,
            );
            return OvertimeSummaryBloc(overtimeDatasource);
          },
        ),
        // Dashboard BLoCs
        BlocProvider(create: (context) => DashboardBloc()),
        BlocProvider(
          create: (context) =>
              QuickStatsBloc(datasource: DashboardRemoteDatasource()),
        ),
        // Attendance BLoCs
        BlocProvider(
          create: (context) =>
              AttendanceTodayBloc(datasource: AttendanceRemoteDatasource()),
        ),
        BlocProvider(
          create: (context) =>
              AttendanceBloc(datasource: AttendanceRemoteDatasource()),
        ),
        BlocProvider(
          create: (context) =>
              AttendanceHistoryBloc(datasource: AttendanceRemoteDatasource()),
        ),
        BlocProvider(
          create: (context) =>
              AttendanceSummaryBloc(datasource: AttendanceRemoteDatasource()),
        ),
        // Schedule BLoC
        BlocProvider(
          create: (context) =>
              ScheduleBloc(datasource: ScheduleRemoteDatasource()),
        ),
        // Face Recognition BLoCs
        BlocProvider(
          create: (context) => FaceRecognitionStatusBloc(
            datasource: FaceRecognitionRemoteDatasource(
              client: http.Client(),
              authLocalDatasource: AuthLocalDatasource(),
            ),
          ),
        ),
        BlocProvider(
          create: (context) => FaceEnrollBloc(
            datasource: FaceRecognitionRemoteDatasource(
              client: http.Client(),
              authLocalDatasource: AuthLocalDatasource(),
            ),
          ),
        ),
        // Office Location BLoC
        BlocProvider(
          create: (context) =>
              OfficeLocationBloc(datasource: OfficeLocationRemoteDatasource()),
        ),
        BlocProvider(
          create: (context) =>
              GpsValidationBloc(datasource: OfficeLocationRemoteDatasource()),
        ),
        // Profile BLoCs
        BlocProvider(create: (context) => ChangePasswordBloc()),
        BlocProvider(
          create: (context) =>
              UpdateProfileBloc(datasource: AuthRemoteDatasource()),
        ),
        // Tax Form BLoCs
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final taxFormDatasource = TaxFormRemoteDatasource(
              client: client,
              authLocalDatasource: authLocal,
            );
            return TaxFormListBloc(datasource: taxFormDatasource);
          },
        ),
        BlocProvider(
          create: (context) {
            final client = http.Client();
            final authLocal = AuthLocalDatasource();
            final taxFormDatasource = TaxFormRemoteDatasource(
              client: client,
              authLocalDatasource: authLocal,
            );
            return TaxFormDetailBloc(datasource: taxFormDatasource);
          },
        ),
      ],
      child: MaterialApp(
        navigatorKey: SessionService.navigatorKey,
        title: 'SiHaris',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // ... (existing theme)
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            error: AppColors.error,
            surface: AppColors.surface,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.greyLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.greyLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          cardTheme: CardThemeData(
            color: AppColors.card,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          dividerTheme: const DividerThemeData(
            color: AppColors.divider,
            thickness: 1,
          ),
        ),
        builder: (context, child) => NotificationWrapper(child: child!),
        home: const SplashScreen(),
      ),
    );
  }
}
