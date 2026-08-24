import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:gaji_pro/core/ml/active_liveness_detector.dart';

void main() {
  group('ActiveLivenessDetector', () {
    const imageSize = Size(480, 640);

    Face createMockFace({
      Rect boundingBox = const Rect.fromLTWH(100, 100, 200, 250),
      double? leftEyeOpenProbability,
      double? rightEyeOpenProbability,
      double? smilingProbability,
      double? headEulerAngleX,
      double? headEulerAngleY,
      double? headEulerAngleZ,
      int? trackingId = 1,
    }) {
      return Face(
        boundingBox: boundingBox,
        landmarks: {},
        contours: {},
        leftEyeOpenProbability: leftEyeOpenProbability,
        rightEyeOpenProbability: rightEyeOpenProbability,
        smilingProbability: smilingProbability,
        headEulerAngleX: headEulerAngleX,
        headEulerAngleY: headEulerAngleY,
        headEulerAngleZ: headEulerAngleZ,
        trackingId: trackingId,
      );
    }

    test('initial state with no face returns waitingForFace', () {
      final detector = ActiveLivenessDetector(
        challenges: [
          LivenessChallenge.fromType(LivenessChallengeType.blink),
        ],
      );

      final result = detector.processFrame(
        faces: [],
        imageSize: imageSize,
      );

      expect(result.status, LivenessStatus.waitingForFace);
      expect(result.isLivenessPassed, isFalse);
    });

    test('multiple faces returns faceInvalid', () {
      final detector = ActiveLivenessDetector(
        challenges: [
          LivenessChallenge.fromType(LivenessChallengeType.blink),
        ],
      );

      final face1 = createMockFace(trackingId: 1);
      final face2 = createMockFace(trackingId: 2);

      final result = detector.processFrame(
        faces: [face1, face2],
        imageSize: imageSize,
      );

      expect(result.status, LivenessStatus.faceInvalid);
      expect(result.message, contains('1 wajah'));
    });

    test('face too small returns faceInvalid', () {
      final detector = ActiveLivenessDetector(
        challenges: [
          LivenessChallenge.fromType(LivenessChallengeType.blink),
        ],
      );

      // Face width is only 20px / 480px = ~4% (< 15%)
      final smallFace = createMockFace(
        boundingBox: const Rect.fromLTWH(100, 100, 20, 30),
      );

      final result = detector.processFrame(
        faces: [smallFace],
        imageSize: imageSize,
      );

      expect(result.status, LivenessStatus.faceInvalid);
      expect(result.message, contains('Dekatkan wajah'));
    });

    test('blink challenge completes on open -> closed -> open cycle', () {
      final detector = ActiveLivenessDetector(
        challenges: [
          LivenessChallenge.fromType(LivenessChallengeType.blink),
        ],
      );

      // Frame 1: Eyes open
      var res = detector.processFrame(
        faces: [
          createMockFace(leftEyeOpenProbability: 0.9, rightEyeOpenProbability: 0.9),
        ],
        imageSize: imageSize,
      );
      expect(res.status, LivenessStatus.challenging);

      // Frame 2: Eyes closed
      res = detector.processFrame(
        faces: [
          createMockFace(leftEyeOpenProbability: 0.1, rightEyeOpenProbability: 0.1),
        ],
        imageSize: imageSize,
      );
      expect(res.status, LivenessStatus.challenging);

      // Frame 3: Eyes open again -> Success!
      res = detector.processFrame(
        faces: [
          createMockFace(leftEyeOpenProbability: 0.9, rightEyeOpenProbability: 0.9),
        ],
        imageSize: imageSize,
      );
      expect(res.status, LivenessStatus.allCompleted);
      expect(res.isLivenessPassed, isTrue);
    });

    test('turn left challenge completes when head rotates to left', () {
      final detector = ActiveLivenessDetector(
        challenges: [
          LivenessChallenge.fromType(LivenessChallengeType.turnLeft),
        ],
      );

      // Frame 1: Center/neutral
      var res = detector.processFrame(
        faces: [createMockFace(headEulerAngleY: 0.0)],
        imageSize: imageSize,
      );
      expect(res.status, LivenessStatus.challenging);

      // Frame 2: Turn Left (front camera: yaw > 16.0)
      res = detector.processFrame(
        faces: [createMockFace(headEulerAngleY: 22.0)],
        imageSize: imageSize,
      );
      expect(res.status, LivenessStatus.allCompleted);
      expect(res.isLivenessPassed, isTrue);
    });

    test('turn right challenge completes when head rotates to right', () {
      final detector = ActiveLivenessDetector(
        challenges: [
          LivenessChallenge.fromType(LivenessChallengeType.turnRight),
        ],
      );

      // Frame 1: Center/neutral
      var res = detector.processFrame(
        faces: [createMockFace(headEulerAngleY: 0.0)],
        imageSize: imageSize,
      );
      expect(res.status, LivenessStatus.challenging);

      // Frame 2: Turn Right (front camera: yaw < -16.0)
      res = detector.processFrame(
        faces: [createMockFace(headEulerAngleY: -20.0)],
        imageSize: imageSize,
      );
      expect(res.status, LivenessStatus.allCompleted);
      expect(res.isLivenessPassed, isTrue);
    });

    test('smile challenge completes on neutral -> smiling transition', () {
      final detector = ActiveLivenessDetector(
        challenges: [
          LivenessChallenge.fromType(LivenessChallengeType.smile),
        ],
      );

      // Frame 1: Neutral expression
      var res = detector.processFrame(
        faces: [createMockFace(smilingProbability: 0.1)],
        imageSize: imageSize,
      );
      expect(res.status, LivenessStatus.challenging);

      // Frame 2: Big smile
      res = detector.processFrame(
        faces: [createMockFace(smilingProbability: 0.85)],
        imageSize: imageSize,
      );
      expect(res.status, LivenessStatus.allCompleted);
      expect(res.isLivenessPassed, isTrue);
    });

    test('multi-step challenge transitions through steps before allCompleted', () {
      final detector = ActiveLivenessDetector(
        challenges: [
          LivenessChallenge.fromType(LivenessChallengeType.smile),
          LivenessChallenge.fromType(LivenessChallengeType.turnLeft),
        ],
      );

      expect(detector.totalSteps, 2);

      // Step 1: Smile neutral -> smile
      detector.processFrame(
        faces: [createMockFace(smilingProbability: 0.1)],
        imageSize: imageSize,
      );
      final res1 = detector.processFrame(
        faces: [createMockFace(smilingProbability: 0.85)],
        imageSize: imageSize,
      );
      expect(res1.status, LivenessStatus.stepCompleted);
      expect(res1.currentStep, 1);
    });
  });
}
