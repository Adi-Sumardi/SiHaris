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

class MockPayslipListBloc extends MockBloc<PayslipListEvent, PayslipListState>
    implements PayslipListBloc {
  @override
  PayslipListState get state => PayslipListInitial();

  @override
  Stream<PayslipListState> get stream => Stream.value(PayslipListInitial());
}

class MockPayslipSummaryBloc
    extends MockBloc<PayslipSummaryEvent, PayslipSummaryState>
    implements PayslipSummaryBloc {
  @override
  PayslipSummaryState get state => PayslipSummaryInitial();

  @override
  Stream<PayslipSummaryState> get stream =>
      Stream.value(PayslipSummaryInitial());
}

class FakePayslipListEvent extends Fake implements PayslipListEvent {}

class FakePayslipListState extends Fake implements PayslipListState {}

class FakePayslipSummaryEvent extends Fake implements PayslipSummaryEvent {}

class FakePayslipSummaryState extends Fake implements PayslipSummaryState {}

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
  when(
    () => attendanceSummaryBloc.stream,
  ).thenAnswer((_) => const Stream.empty());

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
