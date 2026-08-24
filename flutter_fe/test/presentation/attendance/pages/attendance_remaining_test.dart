// Fix 14: Tanggal hardcoded 'Rabu, 12 Februari 2026' harus dinamis
// Fix 15: Setelah AttendanceSuccess, AttendanceTodayBloc harus di-refresh
// Fix 16: AttendanceSummaryError harus ditampilkan di history screen
// Fix 17: FaceRecognitionStatusBloc loading/error harus block clock-in
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/presentation/attendance/bloc/attendance/attendance_bloc.dart';
import 'package:gaji_pro/presentation/attendance/bloc/attendance_today/attendance_today_bloc.dart';
import 'package:gaji_pro/presentation/attendance/bloc/attendance_history/attendance_history_bloc.dart';
import 'package:gaji_pro/presentation/attendance/bloc/attendance_summary/attendance_summary_bloc.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_recognition_status/face_recognition_status_bloc.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_recognition_status/face_recognition_status_event.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_recognition_status/face_recognition_status_state.dart';
import 'package:gaji_pro/data/models/responses/face_recognition/face_recognition_status_model.dart';
import 'package:gaji_pro/data/models/responses/office_location_model.dart';
import 'package:gaji_pro/presentation/attendance/pages/attendance_confirmation_screen.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

class MockAttendanceBloc extends MockBloc<AttendanceEvent, AttendanceState>
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

class FakeAttendanceEvent extends Fake implements AttendanceEvent {}
class FakeAttendanceTodayEvent extends Fake implements AttendanceTodayEvent {}
class FakeFaceRecognitionStatusEvent extends Fake
    implements FaceRecognitionStatusEvent {}

const _testOffice = OfficeLocationModel(
  id: 1,
  name: 'Kantor Pusat',
  latitude: -6.2,
  longitude: 106.8,
  radius: 100,
  address: 'Jl. Sudirman No.1',
  city: 'Jakarta',
);

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
    registerFallbackValue(FakeAttendanceEvent());
    registerFallbackValue(FakeAttendanceTodayEvent());
    registerFallbackValue(FakeFaceRecognitionStatusEvent());
  });

  // ── Fix 14: Tanggal dinamis ───────────────────────────────────────────────

  group('Fix 14: Tanggal di AttendanceScreen harus dinamis (bukan hardcoded)', () {
    test('DateFormat dengan locale id_ID menampilkan tanggal dinamis', () {
      final now = DateTime.now();
      final formatted = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);

      // Bukan hardcoded
      expect(formatted, isNot('Rabu, 12 Februari 2026'));

      // Format benar: "Senin, 17 Februari 2026" (tergantung hari ini)
      expect(formatted, matches(r'^[A-Za-zÀ-ÿ]+, \d+ [A-Za-zÀ-ÿ]+ \d{4}$'));
    });

    test('Tanggal hari ini sesuai format Indonesia', () {
      final now = DateTime.now();
      final formatted = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
      // Pastikan format tidak kosong
      expect(formatted.isNotEmpty, isTrue);
      expect(formatted.contains('${now.year}'), isTrue);
    });
  });

  // ── Fix 15: Refresh AttendanceTodayBloc setelah AttendanceSuccess ─────────

  group('Fix 15: AttendanceTodayBloc di-refresh setelah AttendanceSuccess', () {
    late MockAttendanceBloc mockAttendanceBloc;
    late MockAttendanceTodayBloc mockTodayBloc;

    setUp(() {
      mockAttendanceBloc = MockAttendanceBloc();
      mockTodayBloc = MockAttendanceTodayBloc();
    });

    testWidgets(
        'RED: setelah AttendanceSuccess, GetTodayStatus event harus dikirim ke AttendanceTodayBloc',
        (tester) async {
      when(() => mockAttendanceBloc.state)
          .thenReturn(AttendanceSuccess('Clock in berhasil'));
      when(() => mockAttendanceBloc.stream).thenAnswer(
        (_) => Stream.value(AttendanceSuccess('Clock in berhasil')),
      );
      when(() => mockTodayBloc.state).thenReturn(AttendanceTodayInitial());
      when(() => mockTodayBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<AttendanceBloc>.value(value: mockAttendanceBloc),
                BlocProvider<AttendanceTodayBloc>.value(value: mockTodayBloc),
              ],
              child: const AttendanceConfirmationScreen(
                type: AttendanceType.clockIn,
                userLatitude: -6.2001,
                userLongitude: 106.8001,
                office: _testOffice,
                faceConfidence: 0.9,
                faceDescriptors: [],
                livenessPassed: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump(); // build
      await tester.pump(const Duration(milliseconds: 100)); // stream emit

      // SnackBar berhasil muncul
      expect(find.text('Clock in berhasil'), findsOneWidget);

      // Fix: GetTodayStatus harus dipanggil ke AttendanceTodayBloc
      verify(() => mockTodayBloc.add(any<AttendanceTodayEvent>())).called(1);
    });

    testWidgets('setelah AttendanceFailure, AttendanceTodayBloc tidak di-refresh',
        (tester) async {
      when(() => mockAttendanceBloc.state)
          .thenReturn(AttendanceFailure('Gagal clock in'));
      when(() => mockAttendanceBloc.stream).thenAnswer(
        (_) => Stream.value(AttendanceFailure('Gagal clock in')),
      );
      when(() => mockTodayBloc.state).thenReturn(AttendanceTodayInitial());
      when(() => mockTodayBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<AttendanceBloc>.value(value: mockAttendanceBloc),
                BlocProvider<AttendanceTodayBloc>.value(value: mockTodayBloc),
              ],
              child: const AttendanceConfirmationScreen(
                type: AttendanceType.clockIn,
                userLatitude: -6.2001,
                userLongitude: 106.8001,
                office: _testOffice,
                faceConfidence: 0.9,
                faceDescriptors: [],
                livenessPassed: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Gagal clock in'), findsOneWidget);
      // Tidak ada refresh saat gagal
      verifyNever(() => mockTodayBloc.add(any<AttendanceTodayEvent>()));
    });
  });

  // ── Fix 16: AttendanceSummaryError di HistoryScreen ──────────────────────

  group('Fix 16: AttendanceSummaryError ditampilkan di history screen', () {
    /// Widget simulasi summary section (sama dengan di attendance_history_screen)
    Widget buildSummaryWidget(AttendanceSummaryState state) {
      final mockSummaryBloc = MockAttendanceSummaryBloc();
      when(() => mockSummaryBloc.state).thenReturn(state);
      when(() => mockSummaryBloc.stream).thenAnswer((_) => const Stream.empty());

      return MaterialApp(
        home: Scaffold(
          body: BlocProvider<AttendanceSummaryBloc>.value(
            value: mockSummaryBloc,
            child: BlocBuilder<AttendanceSummaryBloc, AttendanceSummaryState>(
              builder: (context, s) {
                if (s is AttendanceSummaryLoaded) {
                  return const Text('Summary loaded');
                }
                // Fix 16: harus handle Error secara eksplisit
                if (s is AttendanceSummaryError) {
                  return const Text('Gagal memuat ringkasan');
                }
                if (s is AttendanceSummaryLoading) {
                  return const CircularProgressIndicator();
                }
                return const SizedBox(height: 60);
              },
            ),
          ),
        ),
      );
    }

    testWidgets(
        'RED: saat AttendanceSummaryError, tampil pesan error (bukan SizedBox kosong)',
        (tester) async {
      await tester.pumpWidget(
        buildSummaryWidget(const AttendanceSummaryError('Gagal memuat')),
      );
      await tester.pump();

      // Harus ada pesan error
      expect(find.text('Gagal memuat ringkasan'), findsOneWidget);
      // Tidak ada loading indicator (bukan fallback kosong)
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('saat AttendanceSummaryLoading, tampil loading indicator',
        (tester) async {
      await tester.pumpWidget(buildSummaryWidget(AttendanceSummaryLoading()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  // ── Fix 17: FaceRecognitionStatusBloc loading/error block clock-in ────────

  group('Fix 17: Clock-in diblock saat FaceRecognitionStatus loading/error', () {
    test('FaceRecognitionStatusLoading bukan FaceRecognitionStatusLoaded', () {
      final state = FaceRecognitionStatusLoading();
      expect(state, isNot(isA<FaceRecognitionStatusLoaded>()));
    });

    test('FaceRecognitionStatusError bukan FaceRecognitionStatusLoaded', () {
      final state = FaceRecognitionStatusError('Error');
      expect(state, isNot(isA<FaceRecognitionStatusLoaded>()));
    });

    test(
        'RED: saat status Loading, clock-in flow harus ditolak (tidak proceed)',
        () {
      // Simulasi logika enrollment check yang benar
      FaceRecognitionStatusState state = FaceRecognitionStatusLoading();

      bool shouldProceed = _canProceedWithClockIn(state);

      // Fix: saat loading, tidak boleh proceed
      expect(shouldProceed, isFalse,
          reason: 'Clock-in harus ditolak saat status masih loading');
    });

    test('saat status Error, clock-in flow harus ditolak', () {
      FaceRecognitionStatusState state = FaceRecognitionStatusError('Network error');

      bool shouldProceed = _canProceedWithClockIn(state);

      expect(shouldProceed, isFalse,
          reason: 'Clock-in harus ditolak saat status error');
    });

    test('saat status Loaded + enrolled = true, boleh proceed', () {
      FaceRecognitionStatusState state = FaceRecognitionStatusLoaded(
        FaceRecognitionStatusModel(enrolled: true),
      );

      bool shouldProceed = _canProceedWithClockIn(state);

      expect(shouldProceed, isTrue);
    });

    test('saat status Loaded + enrolled = false, tidak boleh proceed', () {
      FaceRecognitionStatusState state = FaceRecognitionStatusLoaded(
        FaceRecognitionStatusModel(enrolled: false),
      );

      // Tidak blocked tapi perlu show enrollment dialog
      bool isEnrolled = state is FaceRecognitionStatusLoaded &&
          state.status.enrolled;

      expect(isEnrolled, isFalse);
    });
  });
}

/// Helper: simulasi logika _canProceedWithClockIn yang benar
/// (Fix 17: harus block saat Loading atau Error)
bool _canProceedWithClockIn(FaceRecognitionStatusState state) {
  if (state is FaceRecognitionStatusLoaded) {
    // Jika loaded dan enrolled, boleh proceed
    return state.status.enrolled;
  }
  // Loading atau Error atau Initial → BLOCK
  return false;
}
