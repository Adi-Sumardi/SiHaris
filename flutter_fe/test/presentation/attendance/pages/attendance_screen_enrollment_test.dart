import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gaji_pro/data/models/responses/face_recognition/face_recognition_status_model.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_recognition_status/face_recognition_status_bloc.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_recognition_status/face_recognition_status_event.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_recognition_status/face_recognition_status_state.dart';

class MockFaceRecognitionStatusBloc
    extends MockBloc<FaceRecognitionStatusEvent, FaceRecognitionStatusState>
    implements FaceRecognitionStatusBloc {}

/// Test the enrollment check logic (tidak mounting AttendanceScreen penuh
/// karena membutuhkan kamera, geolocator, dll).
/// Menggunakan test-helper widget yang mensimulasikan logika enrollment check.
class _EnrollmentCheckView extends StatelessWidget {
  const _EnrollmentCheckView({
    required this.statusBloc,
    required this.onStartAttendance,
  });

  final FaceRecognitionStatusBloc statusBloc;
  final VoidCallback onStartAttendance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider<FaceRecognitionStatusBloc>.value(
        value: statusBloc,
        child: Scaffold(
          body: BlocBuilder<FaceRecognitionStatusBloc, FaceRecognitionStatusState>(
            builder: (context, state) {
              return Center(
                child: ElevatedButton(
                  onPressed: () => _handleClockIn(context, state),
                  child: const Text('Clock In'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Simulasi logika yang harus ada di AttendanceScreen._startAttendanceFlow:
  /// Cek status enrollment sebelum membuka FaceVerifyScreen
  void _handleClockIn(BuildContext context, FaceRecognitionStatusState state) {
    if (state is FaceRecognitionStatusLoaded && !state.status.enrolled) {
      // Belum enroll — tampilkan dialog
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Face Recognition Belum Terdaftar'),
          content: const Text(
            'Anda harus mendaftarkan wajah terlebih dahulu sebelum melakukan absensi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Nanti'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('Daftar Sekarang'),
            ),
          ],
        ),
      );
    } else {
      // Sudah enroll atau status belum dimuat — lanjut attendance flow
      onStartAttendance();
    }
  }
}

void main() {
  late MockFaceRecognitionStatusBloc mockStatusBloc;

  setUp(() {
    mockStatusBloc = MockFaceRecognitionStatusBloc();
    when(() => mockStatusBloc.stream)
        .thenAnswer((_) => const Stream.empty());
  });

  group('AttendanceScreen — enrollment status check', () {
    testWidgets(
        'RED: menampilkan dialog saat user belum enroll face recognition',
        (tester) async {
      // Arrange: status belum enroll
      when(() => mockStatusBloc.state).thenReturn(
        FaceRecognitionStatusLoaded(
          FaceRecognitionStatusModel(enrolled: false),
        ),
      );

      bool attendanceStarted = false;

      await tester.pumpWidget(
        _EnrollmentCheckView(
          statusBloc: mockStatusBloc,
          onStartAttendance: () => attendanceStarted = true,
        ),
      );
      await tester.pump();

      // Act: tap Clock In
      await tester.tap(find.text('Clock In'));
      await tester.pumpAndSettle();

      // Assert: dialog muncul (bukan langsung ke attendance flow)
      expect(find.text('Face Recognition Belum Terdaftar'), findsOneWidget);
      expect(find.text('Daftar Sekarang'), findsOneWidget);
      expect(attendanceStarted, isFalse);
    });

    testWidgets(
        'melanjutkan attendance flow saat user sudah enroll',
        (tester) async {
      // Arrange: status sudah enroll
      when(() => mockStatusBloc.state).thenReturn(
        FaceRecognitionStatusLoaded(
          FaceRecognitionStatusModel(enrolled: true),
        ),
      );

      bool attendanceStarted = false;

      await tester.pumpWidget(
        _EnrollmentCheckView(
          statusBloc: mockStatusBloc,
          onStartAttendance: () => attendanceStarted = true,
        ),
      );
      await tester.pump();

      // Act: tap Clock In
      await tester.tap(find.text('Clock In'));
      await tester.pumpAndSettle();

      // Assert: tidak ada dialog, langsung attendance flow
      expect(find.text('Face Recognition Belum Terdaftar'), findsNothing);
      expect(attendanceStarted, isTrue);
    });

    testWidgets(
        'melanjutkan attendance flow saat status masih loading (fail graceful)',
        (tester) async {
      // Arrange: status belum dimuat
      when(() => mockStatusBloc.state)
          .thenReturn(FaceRecognitionStatusInitial());

      bool attendanceStarted = false;

      await tester.pumpWidget(
        _EnrollmentCheckView(
          statusBloc: mockStatusBloc,
          onStartAttendance: () => attendanceStarted = true,
        ),
      );
      await tester.pump();

      // Act: tap Clock In saat status belum diload
      await tester.tap(find.text('Clock In'));
      await tester.pumpAndSettle();

      // Assert: tidak crash, lanjut attendance flow (fallback graceful)
      expect(attendanceStarted, isTrue);
    });

    testWidgets(
        'dialog memiliki tombol Nanti yang menutup dialog',
        (tester) async {
      when(() => mockStatusBloc.state).thenReturn(
        FaceRecognitionStatusLoaded(
          FaceRecognitionStatusModel(enrolled: false),
        ),
      );

      await tester.pumpWidget(
        _EnrollmentCheckView(
          statusBloc: mockStatusBloc,
          onStartAttendance: () {},
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Clock In'));
      await tester.pumpAndSettle();

      // Dialog muncul
      expect(find.text('Face Recognition Belum Terdaftar'), findsOneWidget);

      // Tap Nanti
      await tester.tap(find.text('Nanti'));
      await tester.pumpAndSettle();

      // Dialog tertutup
      expect(find.text('Face Recognition Belum Terdaftar'), findsNothing);
    });

    test('FaceRecognitionStatusModel.enrolled field tersedia', () {
      final enrolled = FaceRecognitionStatusModel(enrolled: true);
      final notEnrolled = FaceRecognitionStatusModel(enrolled: false);

      expect(enrolled.enrolled, isTrue);
      expect(notEnrolled.enrolled, isFalse);
    });

    test('FaceRecognitionStatusLoaded menyimpan status dengan benar', () {
      final status = FaceRecognitionStatusModel(enrolled: true);
      final state = FaceRecognitionStatusLoaded(status);

      expect(state.status.enrolled, isTrue);
    });
  });
}
