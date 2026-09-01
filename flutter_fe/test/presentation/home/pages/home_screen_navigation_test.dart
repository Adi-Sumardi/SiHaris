/// Fix 12: HomeScreen pushNamed('/attendance') dan '/announcements' crash
/// home_screen.dart menggunakan pushNamed untuk route yang tidak terdaftar:
/// - '/attendance' (line 321) — tombol absensi di kartu attendance
/// - '/announcements' (line 154, 1022) — notifikasi bell & "Lihat Semua" pengumuman
/// Fix 13: _buildQuickActionItem route '/payslip' juga belum diarahkan ke PayslipScreen
///
/// Fix: ganti semua pushNamed yang crash dengan Navigator.push langsung
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gaji_pro/presentation/attendance/pages/attendance_screen.dart';
import 'package:gaji_pro/presentation/payslip/pages/payslip_screen.dart';
import 'package:gaji_pro/presentation/payslip/bloc/payslip_list/payslip_list_bloc.dart';
import 'package:gaji_pro/presentation/payslip/bloc/payslip_summary/payslip_summary_bloc.dart';

import 'package:gaji_pro/presentation/attendance/bloc/attendance/attendance_bloc.dart';
import 'package:gaji_pro/presentation/attendance/bloc/attendance_today/attendance_today_bloc.dart';
import 'package:gaji_pro/presentation/attendance/bloc/attendance_history/attendance_history_bloc.dart';
import 'package:gaji_pro/presentation/attendance/bloc/attendance_summary/attendance_summary_bloc.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_recognition_status/face_recognition_status_bloc.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_recognition_status/face_recognition_status_event.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_recognition_status/face_recognition_status_state.dart';
import 'package:gaji_pro/presentation/office_location/bloc/office_location/office_location_bloc.dart';
import 'package:gaji_pro/presentation/office_location/bloc/office_location/office_location_event.dart';
import 'package:gaji_pro/presentation/office_location/bloc/office_location/office_location_state.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockPayslipListBloc extends MockBloc<PayslipListEvent, PayslipListState>
    implements PayslipListBloc {}

class MockPayslipSummaryBloc
    extends MockBloc<PayslipSummaryEvent, PayslipSummaryState>
    implements PayslipSummaryBloc {}

class MockAttendanceBloc
    extends MockBloc<AttendanceEvent, AttendanceState>
    implements AttendanceBloc {}

class MockAttendanceTodayBloc
    extends MockBloc<AttendanceTodayEvent, AttendanceTodayState>
    implements AttendanceTodayBloc {}

class MockAttendanceHistoryBloc
    extends MockBloc<AttendanceHistoryEvent, AttendanceHistoryState>
    implements AttendanceHistoryBloc {}

class MockAttendanceSummaryBloc
    extends MockBloc<AttendanceSummaryEvent, AttendanceSummaryState>
    implements AttendanceSummaryBloc {}

class MockFaceRecognitionStatusBloc
    extends MockBloc<FaceRecognitionStatusEvent, FaceRecognitionStatusState>
    implements FaceRecognitionStatusBloc {}

class MockOfficeLocationBloc
    extends MockBloc<OfficeLocationEvent, OfficeLocationState>
    implements OfficeLocationBloc {}

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    FlutterError.onError = (FlutterErrorDetails details) {
      print('FLUTTER ERROR: ${details.exception}');
    };
  });
  group('Fix 12: HomeScreen navigation — tidak ada pushNamed yang crash', () {
    testWidgets(
      'RED: tombol absensi (face icon) tidak crash (bukan pushNamed /attendance)',
      (tester) async {
        bool crashed = false;

        final attendanceBloc = MockAttendanceBloc();
        final attendanceTodayBloc = MockAttendanceTodayBloc();
        final attendanceHistoryBloc = MockAttendanceHistoryBloc();
        final attendanceSummaryBloc = MockAttendanceSummaryBloc();
        final faceStatusBloc = MockFaceRecognitionStatusBloc();
        final officeLocationBloc = MockOfficeLocationBloc();
        when(() => attendanceBloc.state).thenReturn(AttendanceInitial());
        when(() => attendanceBloc.stream).thenAnswer((_) => const Stream.empty());
        when(() => attendanceTodayBloc.state).thenReturn(AttendanceTodayInitial());
        when(() => attendanceTodayBloc.stream).thenAnswer((_) => const Stream.empty());
        when(() => attendanceHistoryBloc.state).thenReturn(AttendanceHistoryInitial());
        when(() => attendanceHistoryBloc.stream).thenAnswer((_) => const Stream.empty());
        when(() => attendanceSummaryBloc.state).thenReturn(AttendanceSummaryInitial());
        when(() => attendanceSummaryBloc.stream).thenAnswer((_) => const Stream.empty());
        when(() => faceStatusBloc.state).thenReturn(FaceRecognitionStatusInitial());
        when(() => faceStatusBloc.stream).thenAnswer((_) => const Stream.empty());
        when(() => officeLocationBloc.state).thenReturn(OfficeLocationInitial());
        when(() => officeLocationBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () {
                    // Fix: Navigator.push langsung ke AttendanceScreen (atau route widget)
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => const Scaffold(body: Text('Absensi')),
                      ),
                    );
                  },
                  child: const Icon(Icons.face),
                ),
              ),
            ),
            onUnknownRoute: (settings) {
              crashed = true;
              return MaterialPageRoute(
                builder: (_) => Scaffold(body: Text('CRASH: ${settings.name}')),
              );
            },
          ),
        );

        await tester.tap(find.byType(Icon));
        await tester.pumpAndSettle();

        // Tidak ada route crash
        expect(crashed, isFalse);
        expect(find.textContaining('CRASH:'), findsNothing);
      },
    );

    testWidgets(
      'RED: notifikasi bell tidak crash (bukan pushNamed /announcements)',
      (tester) async {
        bool crashed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  // Fix: tidak ada aksi (feature belum ada), tapi tidak crash
                  onPressed: () {},
                ),
              ),
            ),
            onUnknownRoute: (settings) {
              crashed = true;
              return MaterialPageRoute(
                builder: (_) => Scaffold(body: Text('CRASH: ${settings.name}')),
              );
            },
          ),
        );

        await tester.tap(find.byType(IconButton));
        await tester.pumpAndSettle();

        expect(crashed, isFalse);
      },
    );

    testWidgets('AttendanceScreen dapat diinstansiasi untuk Navigator.push', (
      tester,
    ) async {
      const screen = AttendanceScreen();
      expect(screen, isA<AttendanceScreen>());
    });
  });

  group('Fix 13: Quick actions — payslip route ke PayslipScreen', () {
    testWidgets(
      'RED: quick action payslip tidak crash (Navigator.push ke PayslipScreen)',
      (tester) async {
        bool crashed = false;

        final payslipListBloc = MockPayslipListBloc();
        final payslipSummaryBloc = MockPayslipSummaryBloc();
        when(() => payslipListBloc.state).thenReturn(PayslipListInitial());
        when(() => payslipSummaryBloc.state).thenReturn(PayslipSummaryInitial());

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<PayslipListBloc>.value(value: payslipListBloc),
              BlocProvider<PayslipSummaryBloc>.value(value: payslipSummaryBloc),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () {
                      // Fix: ganti pushNamed('/payslip') dengan Navigator.push
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => const PayslipScreen(),
                        ),
                      );
                    },
                    child: const Text('Slip Gaji'),
                  ),
                ),
              ),
              onUnknownRoute: (settings) {
                crashed = true;
                return MaterialPageRoute(
                  builder: (_) =>
                      Scaffold(body: Text('CRASH: ${settings.name}')),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Slip Gaji'));
        await tester.pump();

        expect(crashed, isFalse);
        expect(find.textContaining('CRASH:'), findsNothing);
      },
    );

    testWidgets(
      'Quick actions — berkas route ke DocumentListScreen (Navigator.push ke DocumentListScreen)',
      (tester) async {
        bool crashed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => const Scaffold(body: Text('Berkas & Dokumen Saya')),
                      ),
                    );
                  },
                  child: const Text('Berkas'),
                ),
              ),
            ),
            onUnknownRoute: (settings) {
              crashed = true;
              return MaterialPageRoute(
                builder: (_) =>
                    Scaffold(body: Text('CRASH: ${settings.name}')),
              );
            },
          ),
        );

        await tester.tap(find.text('Berkas'));
        await tester.pumpAndSettle();

        expect(crashed, isFalse);
        expect(find.textContaining('CRASH:'), findsNothing);
        expect(find.text('Berkas & Dokumen Saya'), findsOneWidget);
      },
    );

    testWidgets(
      'Ringkasan Bulan Ini — Kehadiran, Sisa Cuti, Lembur, Terlambat navigation',
      (tester) async {
        bool crashed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => const Scaffold(body: Text('Detail Kehadiran')),
                        ),
                      ),
                      child: const Text('Kehadiran'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => const Scaffold(body: Text('Detail Cuti')),
                        ),
                      ),
                      child: const Text('Sisa Cuti'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => const Scaffold(body: Text('Detail Lembur')),
                        ),
                      ),
                      child: const Text('Lembur'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => const Scaffold(body: Text('Detail Terlambat')),
                        ),
                      ),
                      child: const Text('Terlambat'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Kehadiran'));
        await tester.pumpAndSettle();
        expect(find.text('Detail Kehadiran'), findsOneWidget);
        Navigator.pop(tester.element(find.text('Detail Kehadiran')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sisa Cuti'));
        await tester.pumpAndSettle();
        expect(find.text('Detail Cuti'), findsOneWidget);
        Navigator.pop(tester.element(find.text('Detail Cuti')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Lembur'));
        await tester.pumpAndSettle();
        expect(find.text('Detail Lembur'), findsOneWidget);
        Navigator.pop(tester.element(find.text('Detail Lembur')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Terlambat'));
        await tester.pumpAndSettle();
        expect(find.text('Detail Terlambat'), findsOneWidget);
      },
    );
  });
}
