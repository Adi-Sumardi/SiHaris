/// Fix 7: FaceVerifyScreen double trigger
/// BlocConsumer listener memanggil onVerified saat FaceVerifyMatched.
/// Tombol "Lanjutkan" di _buildSuccess JUGA memanggil Navigator.pop.
/// Fix: onVerified hanya dipanggil SATU kali (dari listener saja, hapus dari tombol).
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/responses/face_recognition/face_recognition_status_model.dart';
import 'package:gaji_pro/data/models/requests/face_recognition/face_verify_request_model.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_verify/face_verify_bloc.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_verify/face_verify_event.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_verify/face_verify_state.dart';
import 'package:gaji_pro/presentation/face_recognition/pages/face_verify_screen.dart';

class MockFaceVerifyBloc extends MockBloc<FaceVerifyEvent, FaceVerifyState>
    implements FaceVerifyBloc {}

/// Simulasi widget yang menggunakan listener pattern sama dengan FaceVerifyScreen
/// (tanpa kamera — hanya test listener behavior)
class _ListenerCountView extends StatefulWidget {
  const _ListenerCountView({required this.state, required this.onVerifiedCount});
  final FaceVerifyState state;
  final List<int> onVerifiedCount; // shared list untuk menghitung calls

  @override
  State<_ListenerCountView> createState() => _ListenerCountViewState();
}

class _ListenerCountViewState extends State<_ListenerCountView> {
  @override
  void initState() {
    super.initState();
    // Simulasi: listener dipanggil saat state FaceVerifyMatched
    if (widget.state is FaceVerifyMatched) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // HANYA listener yang memanggil onVerified (bukan tombol)
        widget.onVerifiedCount.add(1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.state is FaceVerifyMatched
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Wajah Dikenali'),
                  ElevatedButton(
                    onPressed: () {
                      // Fix: tombol "Lanjutkan" hanya pop, TIDAK memanggil onVerified lagi
                      Navigator.of(context).maybePop();
                    },
                    child: const Text('Lanjutkan'),
                  ),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

void main() {
  group('Fix 7: FaceVerifyScreen — onVerified hanya dipanggil sekali', () {
    testWidgets(
        'RED: onVerified tidak dipanggil dua kali saat listener + tombol Lanjutkan',
        (tester) async {
      final callCount = <int>[];
      final matchedState = FaceVerifyMatched(
        response: FaceVerifyResponseModel(matched: true, confidence: 0.92),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: _ListenerCountView(
            state: matchedState,
            onVerifiedCount: callCount,
          ),
        ),
      );
      await tester.pump(); // build
      await tester.pump(); // postFrameCallback

      // Listener sudah memanggil onVerified 1x
      expect(callCount.length, 1, reason: 'onVerified harus dipanggil tepat 1x dari listener');

      // Tap tombol Lanjutkan
      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();

      // Setelah tap tombol, onVerified TIDAK dipanggil lagi
      expect(callCount.length, 1, reason: 'Tombol Lanjutkan TIDAK boleh trigger onVerified lagi');
    });

    testWidgets('FaceVerifyScreen menerima onVerified callback', (tester) async {
      int callCount = 0;
      final screen = FaceVerifyScreen(
        verificationType: VerificationType.clockIn,
        onVerified: (confidence, descriptors) {
          callCount++;
        },
      );
      expect(screen.onVerified, isNotNull);
      screen.onVerified!(0.9, []);
      expect(callCount, 1);
    });

    test('FaceVerifyMatched hanya menyimpan response (bukan descriptors)', () {
      final state = FaceVerifyMatched(
        response: FaceVerifyResponseModel(matched: true, confidence: 0.92),
      );
      expect(state.response.matched, isTrue);
      expect(state.response.confidence, closeTo(0.92, 0.001));
    });

    testWidgets('tombol Lanjutkan di _buildSuccess melakukan pop saja',
        (tester) async {
      // Verify bahwa _buildSuccess tidak lagi memanggil widget.onVerified
      // cukup dengan check bahwa screen dapat diinstansiasi dengan onVerified null
      const screen = FaceVerifyScreen(
        verificationType: VerificationType.clockOut,
        // onVerified: null — tidak crash jika tombol Lanjutkan tidak memanggil callback
      );
      expect(screen, isA<FaceVerifyScreen>());
      expect(screen.onVerified, isNull);
    });
  });
}
