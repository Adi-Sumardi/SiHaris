import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/core/ml/blink_liveness_detector.dart';

void main() {
  late BlinkLivenessDetector detector;

  setUp(() {
    detector = BlinkLivenessDetector();
  });

  test('reports no blink for a single frame with open eyes', () {
    final result = detector.onFrame(
      leftEyeOpenProbability: 0.95,
      rightEyeOpenProbability: 0.9,
    );

    expect(result, isFalse);
    expect(detector.blinkDetected, isFalse);
  });

  test('detects a blink on the open -> closed -> open cycle', () {
    expect(
      detector.onFrame(leftEyeOpenProbability: 0.9, rightEyeOpenProbability: 0.9),
      isFalse,
    );
    expect(
      detector.onFrame(leftEyeOpenProbability: 0.1, rightEyeOpenProbability: 0.05),
      isFalse,
    );
    final blinked = detector.onFrame(
      leftEyeOpenProbability: 0.92,
      rightEyeOpenProbability: 0.88,
    );

    expect(blinked, isTrue);
    expect(detector.blinkDetected, isTrue);
  });

  test('does not detect a blink from eyes staying closed (no reopen)', () {
    detector.onFrame(leftEyeOpenProbability: 0.9, rightEyeOpenProbability: 0.9);
    detector.onFrame(leftEyeOpenProbability: 0.1, rightEyeOpenProbability: 0.1);
    detector.onFrame(leftEyeOpenProbability: 0.05, rightEyeOpenProbability: 0.05);

    expect(detector.blinkDetected, isFalse);
  });

  test('does not detect a blink without ever seeing eyes open first', () {
    // Starts closed (e.g. mid-blink when tracking begins) then "opens" —
    // that's not a deliberate blink, just the starting state.
    detector.onFrame(leftEyeOpenProbability: 0.1, rightEyeOpenProbability: 0.1);
    final blinked = detector.onFrame(
      leftEyeOpenProbability: 0.9,
      rightEyeOpenProbability: 0.9,
    );

    expect(blinked, isFalse);
    expect(detector.blinkDetected, isFalse);
  });

  test('ignores frames with a null eye probability instead of treating them as closed', () {
    detector.onFrame(leftEyeOpenProbability: 0.9, rightEyeOpenProbability: 0.9);
    // A frame where ML Kit couldn't estimate one eye must not be able to
    // fake the "closed" half of the cycle.
    detector.onFrame(leftEyeOpenProbability: null, rightEyeOpenProbability: null);
    final blinked = detector.onFrame(
      leftEyeOpenProbability: 0.9,
      rightEyeOpenProbability: 0.9,
    );

    expect(blinked, isFalse);
    expect(detector.blinkDetected, isFalse);
  });

  test('mid-range probabilities (neither clearly open nor closed) do not count as either state', () {
    detector.onFrame(leftEyeOpenProbability: 0.9, rightEyeOpenProbability: 0.9);
    // 0.5 average is between closedThreshold (0.4) and openThreshold (0.6).
    detector.onFrame(leftEyeOpenProbability: 0.5, rightEyeOpenProbability: 0.5);
    final blinked = detector.onFrame(
      leftEyeOpenProbability: 0.9,
      rightEyeOpenProbability: 0.9,
    );

    expect(blinked, isFalse);
  });

  test('once detected, blinkDetected stays true even if fed more frames', () {
    detector.onFrame(leftEyeOpenProbability: 0.9, rightEyeOpenProbability: 0.9);
    detector.onFrame(leftEyeOpenProbability: 0.1, rightEyeOpenProbability: 0.1);
    detector.onFrame(leftEyeOpenProbability: 0.9, rightEyeOpenProbability: 0.9);
    expect(detector.blinkDetected, isTrue);

    detector.onFrame(leftEyeOpenProbability: 0.1, rightEyeOpenProbability: 0.1);
    expect(detector.blinkDetected, isTrue);
  });

  test('reset() clears blink state so a fresh cycle is required again', () {
    detector.onFrame(leftEyeOpenProbability: 0.9, rightEyeOpenProbability: 0.9);
    detector.onFrame(leftEyeOpenProbability: 0.1, rightEyeOpenProbability: 0.1);
    detector.onFrame(leftEyeOpenProbability: 0.9, rightEyeOpenProbability: 0.9);
    expect(detector.blinkDetected, isTrue);

    detector.reset();
    expect(detector.blinkDetected, isFalse);

    // Must observe a fresh open->closed->open cycle again after reset.
    final blinkedImmediately = detector.onFrame(
      leftEyeOpenProbability: 0.9,
      rightEyeOpenProbability: 0.9,
    );
    expect(blinkedImmediately, isFalse);
  });
}
