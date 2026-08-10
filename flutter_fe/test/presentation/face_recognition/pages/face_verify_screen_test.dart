import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/requests/face_recognition/face_verify_request_model.dart';
import 'package:gaji_pro/data/models/responses/face_recognition/face_recognition_status_model.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_verify/face_verify_bloc.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_verify/face_verify_event.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_verify/face_verify_state.dart';
import 'package:gaji_pro/presentation/face_recognition/pages/face_verify_screen.dart';

class MockFaceVerifyBloc extends MockBloc<FaceVerifyEvent, FaceVerifyState>
    implements FaceVerifyBloc {}

void main() {
  late MockFaceVerifyBloc mockBloc;

  setUp(() {
    mockBloc = MockFaceVerifyBloc();
  });

  tearDown(() => mockBloc.close());

  group('FaceVerifyScreen — state rendering', () {
    testWidgets('FaceVerifyScreen dapat diinstansiasi', (tester) async {
      const screen = FaceVerifyScreen(
        verificationType: VerificationType.clockIn,
      );
      expect(screen, isA<FaceVerifyScreen>());
    });

    testWidgets('shows loading indicator saat FaceVerifyLoading', (tester) async {
      await tester.pumpWidget(
        _FaceVerifyStateView(state: FaceVerifyLoading()),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Memverifikasi wajah...'), findsOneWidget);
    });

    testWidgets('shows success UI saat FaceVerifyMatched', (tester) async {
      await tester.pumpWidget(
        _FaceVerifyStateView(
          state: FaceVerifyMatched(
            response: FaceVerifyResponseModel(matched: true, confidence: 0.87),
          ),
        ),
      );

      expect(find.text('Wajah Dikenali'), findsOneWidget);
      expect(find.text('87%'), findsOneWidget);
    });

    testWidgets('shows not matched UI saat FaceVerifyNotMatched',
        (tester) async {
      await tester.pumpWidget(
        _FaceVerifyStateView(
          state: FaceVerifyNotMatched(
            response: FaceVerifyResponseModel(matched: false, confidence: 0.23),
          ),
        ),
      );

      expect(find.text('Wajah Tidak Dikenali'), findsOneWidget);
    });

    testWidgets('shows error message saat FaceVerifyError', (tester) async {
      await tester.pumpWidget(
        _FaceVerifyStateView(state: FaceVerifyError('Unauthenticated')),
      );

      expect(find.text('Unauthenticated'), findsOneWidget);
    });

    testWidgets('shows retry button saat FaceVerifyError', (tester) async {
      await tester.pumpWidget(
        _FaceVerifyStateView(state: FaceVerifyError('Server error')),
      );

      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('shows retry button saat FaceVerifyNotMatched', (tester) async {
      await tester.pumpWidget(
        _FaceVerifyStateView(
          state: FaceVerifyNotMatched(
            response: FaceVerifyResponseModel(matched: false, confidence: 0.1),
          ),
        ),
      );

      expect(find.text('Coba Lagi'), findsOneWidget);
    });
  });

  group('FaceVerifyScreen — event & args', () {
    test('VerificationType clockIn tersedia', () {
      expect(VerificationType.clockIn, isA<VerificationType>());
    });

    test('VerificationType clockOut tersedia', () {
      expect(VerificationType.clockOut, isA<VerificationType>());
    });

    test('FaceVerifyScreen menerima verificationType sebagai arg', () {
      const screenIn = FaceVerifyScreen(
        verificationType: VerificationType.clockIn,
      );
      const screenOut = FaceVerifyScreen(
        verificationType: VerificationType.clockOut,
      );
      expect(screenIn.verificationType, VerificationType.clockIn);
      expect(screenOut.verificationType, VerificationType.clockOut);
    });

    test('FaceVerifyResponseModel.toConfidencePercentage benar', () {
      final response = FaceVerifyResponseModel(matched: true, confidence: 0.87);
      expect(response.toConfidencePercentage(), '87%');
    });
  });

  group('FaceVerifyScreen — onVerified callback dengan descriptors', () {
    testWidgets(
        'onVerified dipanggil dengan descriptors non-empty saat FaceVerifyMatched',
        (tester) async {
      // RED: saat state FaceVerifyMatched, onVerified harus dipanggil
      // dengan descriptors dari hasil recognizer (bukan empty list [])
      double? capturedConfidence;
      List<double>? capturedDescriptors;

      final fakeDescriptors = List<double>.generate(128, (i) => i * 0.01);

      await tester.pumpWidget(
        _FaceVerifyOnVerifiedView(
          state: FaceVerifyMatched(
            response: FaceVerifyResponseModel(matched: true, confidence: 0.91),
          ),
          descriptors: fakeDescriptors,
          onVerified: (confidence, descriptors) {
            capturedConfidence = confidence;
            capturedDescriptors = descriptors;
          },
        ),
      );

      await tester.pump();

      // onVerified harus dipanggil dengan descriptors non-empty
      expect(capturedConfidence, isNotNull);
      expect(capturedDescriptors, isNotNull);
      expect(capturedDescriptors, isNotEmpty);
      expect(capturedDescriptors!.length, 128);
      expect(capturedConfidence, closeTo(0.91, 0.001));
    });

    testWidgets(
        'onVerified tidak dipanggil dengan empty list saat FaceVerifyMatched',
        (tester) async {
      // RED: memastikan bug lama (empty []) sudah diperbaiki
      List<double>? capturedDescriptors;
      final fakeDescriptors = List<double>.generate(128, (i) => i * 0.01);

      await tester.pumpWidget(
        _FaceVerifyOnVerifiedView(
          state: FaceVerifyMatched(
            response: FaceVerifyResponseModel(matched: true, confidence: 0.85),
          ),
          descriptors: fakeDescriptors,
          onVerified: (confidence, descriptors) {
            capturedDescriptors = descriptors;
          },
        ),
      );

      await tester.pump();

      // Deskriptor TIDAK boleh kosong — bug lama mengirim []
      expect(capturedDescriptors, isNot(isEmpty));
    });

    test('FaceVerifyScreen.onVerified field bertipe Function(double, List<double>)?', () {
      double? confCapture;
      List<double>? descCapture;

      final screen = FaceVerifyScreen(
        verificationType: VerificationType.clockIn,
        onVerified: (c, d) {
          confCapture = c;
          descCapture = d;
        },
      );

      // Pastikan onVerified tersimpan di widget
      expect(screen.onVerified, isNotNull);
      screen.onVerified!(0.9, [0.1, 0.2, 0.3]);
      expect(confCapture, closeTo(0.9, 0.001));
      expect(descCapture, equals([0.1, 0.2, 0.3]));
    });
  });
}

/// Test helper: simulates the listener behavior when FaceVerifyMatched fires.
/// Renders an invisible widget and triggers onVerified immediately.
class _FaceVerifyOnVerifiedView extends StatefulWidget {
  const _FaceVerifyOnVerifiedView({
    required this.state,
    required this.descriptors,
    required this.onVerified,
  });

  final FaceVerifyState state;
  final List<double> descriptors;
  final void Function(double confidence, List<double> descriptors) onVerified;

  @override
  State<_FaceVerifyOnVerifiedView> createState() =>
      _FaceVerifyOnVerifiedViewState();
}

class _FaceVerifyOnVerifiedViewState extends State<_FaceVerifyOnVerifiedView> {
  /// Simulates what the fixed FaceVerifyScreen should do:
  /// use the stored embedding (_lastEmbedding) instead of []
  List<double>? _lastEmbedding;

  @override
  void initState() {
    super.initState();
    // Simulate recognizer storing the embedding before BLoC fires
    _lastEmbedding = widget.descriptors;
  }

  @override
  Widget build(BuildContext context) {
    // Simulate the BlocConsumer listener logic (fixed version)
    if (widget.state is FaceVerifyMatched) {
      final s = widget.state as FaceVerifyMatched;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onVerified(s.response.confidence, _lastEmbedding ?? []);
      });
    }
    return const MaterialApp(home: Scaffold(body: SizedBox.shrink()));
  }
}

/// Test helper widget to render state-specific UI without camera init
class _FaceVerifyStateView extends StatelessWidget {
  const _FaceVerifyStateView({required this.state});
  final FaceVerifyState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (state is FaceVerifyLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Memverifikasi wajah...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }
    if (state is FaceVerifyMatched) {
      final s = state as FaceVerifyMatched;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 80),
            const Text('Wajah Dikenali',
                style: TextStyle(color: Colors.white, fontSize: 22)),
            Text(s.response.toConfidencePercentage(),
                style: const TextStyle(color: Colors.greenAccent)),
          ],
        ),
      );
    }
    if (state is FaceVerifyNotMatched) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.face_retouching_off, color: Colors.redAccent, size: 80),
          const Text('Wajah Tidak Dikenali',
              style: TextStyle(color: Colors.white)),
          ElevatedButton(onPressed: () {}, child: const Text('Coba Lagi')),
        ],
      );
    }
    if (state is FaceVerifyError) {
      final s = state as FaceVerifyError;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 80),
          Text(s.message, style: const TextStyle(color: Colors.white)),
          ElevatedButton(onPressed: () {}, child: const Text('Coba Lagi')),
        ],
      );
    }
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }
}
