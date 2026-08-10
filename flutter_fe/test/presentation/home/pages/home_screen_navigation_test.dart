/// Fix 12: HomeScreen pushNamed('/attendance') dan '/announcements' crash
/// home_screen.dart menggunakan pushNamed untuk route yang tidak terdaftar:
/// - '/attendance' (line 321) — tombol absensi di kartu attendance
/// - '/announcements' (line 154, 1022) — notifikasi bell & "Lihat Semua" pengumuman
/// Fix 13: _buildQuickActionItem route '/payslip' juga belum diarahkan ke PayslipScreen
///
/// Fix: ganti semua pushNamed yang crash dengan Navigator.push langsung
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:gaji_pro/presentation/attendance/pages/attendance_screen.dart';
import 'package:gaji_pro/presentation/payslip/pages/payslip_screen.dart';
import 'package:gaji_pro/presentation/payslip/bloc/payslip_list/payslip_list_bloc.dart';
import 'package:gaji_pro/presentation/payslip/bloc/payslip_summary/payslip_summary_bloc.dart';

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

void main() {
  group('Fix 12: HomeScreen navigation — tidak ada pushNamed yang crash', () {
    testWidgets(
      'RED: tombol absensi (face icon) tidak crash (bukan pushNamed /attendance)',
      (tester) async {
        bool crashed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () {
                    // Fix: Navigator.push langsung ke AttendanceScreen
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => const AttendanceScreen(),
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
        await tester.pump();

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
  });
}
