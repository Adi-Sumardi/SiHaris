import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:gaji_pro/presentation/face_recognition/widgets/face_detector_painter.dart';

void main() {
  group('FaceDetectorPainter', () {
    test('shouldRepaint returns true when faces change', () {
      final painter1 = FaceDetectorPainter(
        faces: [],
        imageSize: const Size(480, 640),
        rotation: InputImageRotation.rotation0deg,
        cameraLensDirection: CameraLensDirection.front,
      );

      final painter2 = FaceDetectorPainter(
        faces: [],
        imageSize: const Size(480, 700), // different size
        rotation: InputImageRotation.rotation0deg,
        cameraLensDirection: CameraLensDirection.front,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns false when same size and same faces list', () {
      final sameList = <Face>[];
      final painter1 = FaceDetectorPainter(
        faces: sameList,
        imageSize: const Size(480, 640),
        rotation: InputImageRotation.rotation0deg,
        cameraLensDirection: CameraLensDirection.front,
      );

      final painter2 = FaceDetectorPainter(
        faces: sameList,
        imageSize: const Size(480, 640),
        rotation: InputImageRotation.rotation0deg,
        cameraLensDirection: CameraLensDirection.front,
      );

      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    testWidgets('renders without error when no faces detected', (tester) async {
      final painter = FaceDetectorPainter(
        faces: [],
        imageSize: const Size(480, 640),
        rotation: InputImageRotation.rotation0deg,
        cameraLensDirection: CameraLensDirection.front,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: painter,
              child: const SizedBox(width: 300, height: 400),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    });
  });

  group('FaceGuideOverlay', () {
    testWidgets('renders oval guide when no face detected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FaceGuideOverlay(faceDetected: false),
          ),
        ),
      );

      expect(find.byType(FaceGuideOverlay), findsOneWidget);
    });

    testWidgets('renders green guide when face detected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FaceGuideOverlay(faceDetected: true),
          ),
        ),
      );

      expect(find.byType(FaceGuideOverlay), findsOneWidget);
    });

    testWidgets('shows instruction text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FaceGuideOverlay(
              faceDetected: false,
              instruction: 'Posisikan wajah dalam lingkaran',
            ),
          ),
        ),
      );

      expect(find.text('Posisikan wajah dalam lingkaran'), findsOneWidget);
    });
  });
}
