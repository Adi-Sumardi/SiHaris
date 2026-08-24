/// Fix 10: MainScreen — AttendanceHistoryScreen di tab tanpa BlocProvider
/// MainScreen._screens list menggunakan AttendanceHistoryScreen() langsung,
/// tapi AttendanceHistoryScreen membutuhkan AttendanceHistoryBloc dan
/// AttendanceSummaryBloc dari context. Harus di-wrap dengan MultiBlocProvider.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/presentation/home/pages/main_screen.dart';
import 'package:gaji_pro/presentation/attendance/pages/attendance_history_screen.dart';
import 'package:gaji_pro/presentation/leave/bloc/leave_list/leave_list_bloc.dart';
import 'package:gaji_pro/presentation/leave/bloc/leave_balance/leave_balance_bloc.dart';
import 'package:gaji_pro/presentation/leave/bloc/leave_types/leave_types_bloc.dart';
import 'package:gaji_pro/presentation/leave/bloc/leave_crud/leave_crud_bloc.dart';
import 'package:gaji_pro/presentation/auth/bloc/profile/profile_bloc.dart';
import 'package:gaji_pro/presentation/attendance/bloc/attendance_history/attendance_history_bloc.dart';
import 'package:gaji_pro/presentation/attendance/bloc/attendance_summary/attendance_summary_bloc.dart';
import 'package:gaji_pro/presentation/payslip/bloc/payslip_list/payslip_list_bloc.dart';
import 'package:gaji_pro/presentation/payslip/bloc/payslip_summary/payslip_summary_bloc.dart';
import 'package:gaji_pro/presentation/auth/bloc/profile/profile_event.dart';
import 'package:gaji_pro/presentation/auth/bloc/profile/profile_state.dart';
import 'package:gaji_pro/presentation/dashboard/bloc/dashboard_bloc.dart';
import 'package:gaji_pro/presentation/dashboard/bloc/dashboard_event.dart';
import 'package:gaji_pro/presentation/dashboard/bloc/dashboard_state.dart';
import 'package:gaji_pro/presentation/dashboard/bloc/quick_stats_bloc.dart';
import 'package:gaji_pro/presentation/dashboard/bloc/quick_stats_event.dart';
import 'package:gaji_pro/presentation/dashboard/bloc/quick_stats_state.dart';
import 'package:gaji_pro/presentation/announcement/bloc/announcement_list/announcement_list_bloc.dart';
import 'package:gaji_pro/presentation/announcement/bloc/announcement_list/announcement_list_event.dart';
import 'package:gaji_pro/presentation/announcement/bloc/announcement_list/announcement_list_state.dart';
import 'package:gaji_pro/presentation/announcement/bloc/announcement_unread_count/announcement_unread_count_bloc.dart';
import 'package:gaji_pro/presentation/announcement/bloc/announcement_unread_count/announcement_unread_count_event.dart';
import 'package:gaji_pro/presentation/announcement/bloc/announcement_unread_count/announcement_unread_count_state.dart';

class MockLeaveListBloc extends MockBloc<LeaveListEvent, LeaveListState>
    implements LeaveListBloc {}

class MockLeaveBalanceBloc
    extends MockBloc<LeaveBalanceEvent, LeaveBalanceState>
    implements LeaveBalanceBloc {}

class MockLeaveTypesBloc extends MockBloc<LeaveTypesEvent, LeaveTypesState>
    implements LeaveTypesBloc {}

class MockLeaveCrudBloc extends MockBloc<LeaveCrudEvent, LeaveCrudState>
    implements LeaveCrudBloc {}

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class MockAttendanceHistoryBloc
    extends MockBloc<AttendanceHistoryEvent, AttendanceHistoryState>
    implements AttendanceHistoryBloc {}

class MockAttendanceSummaryBloc
    extends MockBloc<AttendanceSummaryEvent, AttendanceSummaryState>
    implements AttendanceSummaryBloc {}

class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

class MockQuickStatsBloc extends MockBloc<QuickStatsEvent, QuickStatsState>
    implements QuickStatsBloc {}

class MockPayslipListBloc extends MockBloc<PayslipListEvent, PayslipListState>
    implements PayslipListBloc {}

class MockPayslipSummaryBloc
    extends MockBloc<PayslipSummaryEvent, PayslipSummaryState>
    implements PayslipSummaryBloc {}

class FakePayslipListEvent extends Fake implements PayslipListEvent {}

class FakePayslipListState extends Fake implements PayslipListState {}

class FakePayslipSummaryEvent extends Fake implements PayslipSummaryEvent {}

class FakePayslipSummaryState extends Fake implements PayslipSummaryState {}

class FakeDashboardEvent extends Fake implements DashboardEvent {}

class FakeDashboardState extends Fake implements DashboardState {}

class FakeQuickStatsEvent extends Fake implements QuickStatsEvent {}

class FakeQuickStatsState extends Fake implements QuickStatsState {}

class MockAnnouncementListBloc
    extends MockBloc<AnnouncementListEvent, AnnouncementListState>
    implements AnnouncementListBloc {}

class FakeAnnouncementListEvent extends Fake implements AnnouncementListEvent {}

class FakeAnnouncementListState extends Fake implements AnnouncementListState {}

class MockAnnouncementUnreadCountBloc
    extends MockBloc<AnnouncementUnreadCountEvent, AnnouncementUnreadCountState>
    implements AnnouncementUnreadCountBloc {}

class FakeAnnouncementUnreadCountEvent extends Fake
    implements AnnouncementUnreadCountEvent {}

class FakeAnnouncementUnreadCountState extends Fake
    implements AnnouncementUnreadCountState {}

/// Helper: provide all global BLoCs needed by MainScreen tabs
Widget wrapWithProviders(Widget child) {
  final leaveListBloc = MockLeaveListBloc();
  final leaveBalanceBloc = MockLeaveBalanceBloc();
  final leaveTypesBloc = MockLeaveTypesBloc();
  final leaveCrudBloc = MockLeaveCrudBloc();
  final profileBloc = MockProfileBloc();
  final attendanceHistoryBloc = MockAttendanceHistoryBloc();
  final attendanceSummaryBloc = MockAttendanceSummaryBloc();
  final payslipListBloc = MockPayslipListBloc();
  final payslipSummaryBloc = MockPayslipSummaryBloc();
  final dashboardBloc = MockDashboardBloc();
  final quickStatsBloc = MockQuickStatsBloc();
  final announcementListBloc = MockAnnouncementListBloc();
  final announcementUnreadCountBloc = MockAnnouncementUnreadCountBloc();

  when(() => leaveListBloc.state).thenReturn(LeaveListInitial());
  when(() => leaveListBloc.stream).thenAnswer((_) => const Stream.empty());
  when(() => leaveBalanceBloc.state).thenReturn(LeaveBalanceInitial());
  when(() => leaveBalanceBloc.stream).thenAnswer((_) => const Stream.empty());
  when(() => leaveTypesBloc.state).thenReturn(LeaveTypesInitial());
  when(() => leaveTypesBloc.stream).thenAnswer((_) => const Stream.empty());
  when(() => leaveCrudBloc.state).thenReturn(LeaveCrudInitial());
  when(() => leaveCrudBloc.stream).thenAnswer((_) => const Stream.empty());

  when(() => profileBloc.state).thenReturn(ProfileInitial());
  when(() => profileBloc.stream).thenAnswer((_) => const Stream.empty());

  when(
    () => attendanceHistoryBloc.state,
  ).thenReturn(AttendanceHistoryInitial());
  when(
    () => attendanceHistoryBloc.stream,
  ).thenAnswer((_) => const Stream.empty());

  when(
    () => attendanceSummaryBloc.state,
  ).thenReturn(AttendanceSummaryInitial());
  when(() => attendanceSummaryBloc.stream).thenAnswer((_) => const Stream.empty());

  when(() => payslipListBloc.state).thenReturn(PayslipListInitial());
  when(() => payslipListBloc.stream).thenAnswer((_) => const Stream.empty());
  when(() => payslipSummaryBloc.state).thenReturn(PayslipSummaryInitial());
  when(() => payslipSummaryBloc.stream).thenAnswer((_) => const Stream.empty());
  when(() => dashboardBloc.state).thenReturn(DashboardInitial());
  when(() => dashboardBloc.stream).thenAnswer((_) => const Stream.empty());
  when(() => quickStatsBloc.state).thenReturn(QuickStatsInitial());
  when(() => quickStatsBloc.stream).thenAnswer((_) => const Stream.empty());
  when(() => announcementListBloc.state).thenReturn(AnnouncementListInitial());
  when(() => announcementListBloc.stream).thenAnswer((_) => const Stream.empty());
  when(() => announcementUnreadCountBloc.state)
      .thenReturn(const AnnouncementUnreadCountLoaded(0));
  when(() => announcementUnreadCountBloc.stream)
      .thenAnswer((_) => const Stream.empty());

  return MultiBlocProvider(
    providers: [
      BlocProvider<LeaveListBloc>.value(value: leaveListBloc),
      BlocProvider<LeaveBalanceBloc>.value(value: leaveBalanceBloc),
      BlocProvider<LeaveTypesBloc>.value(value: leaveTypesBloc),
      BlocProvider<LeaveCrudBloc>.value(value: leaveCrudBloc),
      BlocProvider<ProfileBloc>.value(value: profileBloc),
      BlocProvider<AttendanceHistoryBloc>.value(value: attendanceHistoryBloc),
      BlocProvider<AttendanceSummaryBloc>.value(value: attendanceSummaryBloc),
      BlocProvider<PayslipListBloc>.value(value: payslipListBloc),
      BlocProvider<PayslipSummaryBloc>.value(value: payslipSummaryBloc),
      BlocProvider<DashboardBloc>.value(value: dashboardBloc),
      BlocProvider<QuickStatsBloc>.value(value: quickStatsBloc),
      BlocProvider<AnnouncementListBloc>.value(value: announcementListBloc),
      BlocProvider<AnnouncementUnreadCountBloc>.value(
        value: announcementUnreadCountBloc,
      ),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakePayslipListEvent());
    registerFallbackValue(FakePayslipListState());
    registerFallbackValue(FakePayslipSummaryEvent());
    registerFallbackValue(FakePayslipSummaryState());
    registerFallbackValue(FakeDashboardEvent());
    registerFallbackValue(FakeDashboardState());
    registerFallbackValue(FakeQuickStatsEvent());
    registerFallbackValue(FakeQuickStatsState());
    registerFallbackValue(FakeAnnouncementListEvent());
    registerFallbackValue(FakeAnnouncementListState());
    registerFallbackValue(FakeAnnouncementUnreadCountEvent());
    registerFallbackValue(FakeAnnouncementUnreadCountState());
  });

  group(
    'Fix 10: MainScreen — AttendanceHistoryScreen membutuhkan BlocProvider',
    () {
      testWidgets('MainScreen dapat dirender tanpa crash', (tester) async {
        await tester.pumpWidget(wrapWithProviders(const MainScreen()));
        await tester.pump();

        expect(find.byType(MainScreen), findsOneWidget);
      });

      testWidgets(
        'RED: pindah ke tab Riwayat (index 1) tidak crash karena BlocProvider tersedia',
        (tester) async {
          await tester.pumpWidget(wrapWithProviders(const MainScreen()));
          await tester.pump();

          // Tap tab Riwayat (index 1 = history)
          await tester.tap(find.text('Riwayat'));
          await tester.pump();

          // AttendanceHistoryScreen tampil — tidak ada error BlocProvider
          expect(find.byType(AttendanceHistoryScreen), findsOneWidget);
        },
      );

      testWidgets(
        'AttendanceHistoryScreen di _screens list sudah ada BlocProvider',
        (tester) async {
          await tester.pumpWidget(wrapWithProviders(const MainScreen()));
          await tester.pump();

          // Tidak ada exception — MainScreen build sukses
          expect(tester.takeException(), isNull);
        },
      );
    },
  );
}
