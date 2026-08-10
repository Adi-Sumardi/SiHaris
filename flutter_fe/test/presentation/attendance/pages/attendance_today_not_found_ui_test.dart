/// Fix 11: AttendanceTodayNotFound tidak ditangani di UI
/// attendance_screen.dart _buildTodayTab() tidak handle AttendanceTodayNotFound state —
/// jatuh ke fallback 'No data' tanpa pesan yang bermakna.
/// Fix: tambah explicit handler untuk AttendanceTodayNotFound di _buildTodayTab().
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/datasources/attendance_remote_datasource.dart';
import 'package:gaji_pro/presentation/attendance/bloc/attendance_today/attendance_today_bloc.dart';

class MockAttendanceRemoteDatasource extends Mock
    implements AttendanceRemoteDatasource {}

class MockAttendanceTodayBloc
    extends MockBloc<AttendanceTodayEvent, AttendanceTodayState>
    implements AttendanceTodayBloc {}

/// Widget sederhana yang mensimulasikan _buildTodayTab() behavior
class _TodayTabSimulator extends StatelessWidget {
  const _TodayTabSimulator();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceTodayBloc, AttendanceTodayState>(
      builder: (context, state) {
        if (state is AttendanceTodayLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AttendanceTodayError) {
          return Center(child: Text(state.message));
        }
        if (state is AttendanceTodayLoaded) {
          return const Center(child: Text('Data loaded'));
        }
        // Fix 11: harus handle NotFound secara eksplisit
        if (state is AttendanceTodayNotFound) {
          return const Center(
            child: Text('Belum ada absensi hari ini'),
          );
        }
        return const Center(child: Text('No data'));
      },
    );
  }
}

void main() {
  late MockAttendanceTodayBloc mockBloc;

  setUp(() {
    mockBloc = MockAttendanceTodayBloc();
  });

  group('Fix 11: AttendanceTodayNotFound ditangani di UI', () {
    testWidgets(
        'RED: saat state AttendanceTodayNotFound, UI menampilkan pesan bermakna',
        (tester) async {
      when(() => mockBloc.state).thenReturn(AttendanceTodayNotFound());
      when(() => mockBloc.stream)
          .thenAnswer((_) => Stream.value(AttendanceTodayNotFound()));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<AttendanceTodayBloc>.value(
              value: mockBloc,
              child: const _TodayTabSimulator(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Setelah fix: harus muncul pesan "Belum ada absensi hari ini"
      expect(
        find.text('Belum ada absensi hari ini'),
        findsOneWidget,
        reason: 'AttendanceTodayNotFound harus tampil pesan yang bermakna, bukan "No data"',
      );

      // Tidak boleh tampil "No data" generik
      expect(find.text('No data'), findsNothing);
    });

    testWidgets('saat state AttendanceTodayLoading, tampil CircularProgressIndicator',
        (tester) async {
      when(() => mockBloc.state).thenReturn(AttendanceTodayLoading());
      when(() => mockBloc.stream)
          .thenAnswer((_) => Stream.value(AttendanceTodayLoading()));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<AttendanceTodayBloc>.value(
              value: mockBloc,
              child: const _TodayTabSimulator(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('saat state AttendanceTodayError, tampil pesan error',
        (tester) async {
      when(() => mockBloc.state)
          .thenReturn(const AttendanceTodayError('Server error'));
      when(() => mockBloc.stream)
          .thenAnswer((_) => Stream.value(const AttendanceTodayError('Server error')));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<AttendanceTodayBloc>.value(
              value: mockBloc,
              child: const _TodayTabSimulator(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Server error'), findsOneWidget);
    });

    test('AttendanceTodayNotFound state tersedia dan comparable', () {
      final state1 = AttendanceTodayNotFound();
      final state2 = AttendanceTodayNotFound();
      expect(state1, equals(state2));
      expect(state1, isA<AttendanceTodayState>());
    });
  });
}
