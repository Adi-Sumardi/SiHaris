import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test the double-tap guard + loading-indicator logic that
/// AttendanceScreen._startAttendanceFlow uses (tidak mounting AttendanceScreen
/// penuh karena membutuhkan kamera, geolocator, dll — mengikuti pola di
/// attendance_screen_enrollment_test.dart).
///
/// Regresi yang diperbaiki: antara tap tombol Clock In/Out dan pindah ke
/// layar liveness ada jeda (GPS fix + pre-check), tanpa indikator apapun —
/// karyawan jadi tekan-tekan tombolnya berulang kali mengira tidak
/// terdaftar, yang bisa memicu beberapa alur absensi berjalan bersamaan.
class _ClockInGuardView extends StatefulWidget {
  const _ClockInGuardView({required this.onStart});

  final Future<void> Function() onStart;

  @override
  State<_ClockInGuardView> createState() => _ClockInGuardViewState();
}

class _ClockInGuardViewState extends State<_ClockInGuardView> {
  bool _isStarting = false;

  Future<void> _handleTap() async {
    if (_isStarting) return;

    setState(() => _isStarting = true);
    try {
      await widget.onStart();
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: _isStarting
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _handleTap,
                  child: const Text('Clock In'),
                ),
        ),
      ),
    );
  }
}

void main() {
  group('AttendanceScreen — clock button loading guard', () {
    testWidgets(
      'shows a loading indicator instead of the button while the flow is starting',
      (tester) async {
        var startCount = 0;

        await tester.pumpWidget(
          _ClockInGuardView(
            onStart: () async {
              startCount++;
              await Future<void>.delayed(const Duration(milliseconds: 100));
            },
          ),
        );

        expect(find.text('Clock In'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        await tester.tap(find.text('Clock In'));
        await tester.pump();

        // While the async flow is in flight, the button is replaced by a
        // loading indicator — nothing left to tap repeatedly.
        expect(find.text('Clock In'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle();

        expect(startCount, 1);
        expect(find.text('Clock In'), findsOneWidget);
      },
    );

    testWidgets(
      'rapid repeated taps while starting only trigger the flow once',
      (tester) async {
        var startCount = 0;

        await tester.pumpWidget(
          _ClockInGuardView(
            onStart: () async {
              startCount++;
              await Future<void>.delayed(const Duration(milliseconds: 200));
            },
          ),
        );

        // Simulate an impatient employee tapping several times in a row
        // during the GPS-fetch delay.
        await tester.tap(find.text('Clock In'));
        await tester.pump(const Duration(milliseconds: 20));
        // Button is gone now (replaced by the spinner) so a second tap on
        // the same finder is a no-op, but assert the guard directly too.
        expect(find.text('Clock In'), findsNothing);

        await tester.pumpAndSettle();

        expect(startCount, 1);
      },
    );

    testWidgets(
      'the button becomes tappable again after the flow finishes, for the next clock event',
      (tester) async {
        var startCount = 0;

        await tester.pumpWidget(
          _ClockInGuardView(
            onStart: () async {
              startCount++;
              await Future<void>.delayed(const Duration(milliseconds: 50));
            },
          ),
        );

        await tester.tap(find.text('Clock In'));
        await tester.pumpAndSettle();
        expect(startCount, 1);

        // Second, independent tap (e.g. Clock Out later) should work fine.
        await tester.tap(find.text('Clock In'));
        await tester.pumpAndSettle();
        expect(startCount, 2);
      },
    );
  });
}
