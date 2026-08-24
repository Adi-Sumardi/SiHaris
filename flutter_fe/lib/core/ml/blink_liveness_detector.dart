/// Tracks eye-open probability across consecutive camera frames to detect a
/// single deliberate blink (eyes open -> closed -> open again).
///
/// Used as a lightweight liveness signal before face verification: a static
/// photo or a video held up to the camera cannot trivially produce a blink
/// cycle on demand the way a live person can, so requiring one blink before
/// capture rules out the simplest spoofing attempts.
///
/// Not a substitute for the `enable_liveness_detection`/`liveness_passed`
/// contract's stronger guarantees (e.g. depth sensing) — it's a best-effort
/// check achievable with the 2D face classification already available via
/// ML Kit, matching what the client can realistically detect.
class BlinkLivenessDetector {
  BlinkLivenessDetector({
    this.openThreshold = 0.6,
    this.closedThreshold = 0.4,
  }) : assert(closedThreshold < openThreshold);

  /// Average eye-open probability at/above which eyes are considered open.
  final double openThreshold;

  /// Average eye-open probability at/below which eyes are considered closed.
  final double closedThreshold;

  bool _eyesWereOpen = false;
  bool _sawClosed = false;
  bool _blinkDetected = false;

  bool get blinkDetected => _blinkDetected;

  void reset() {
    _eyesWereOpen = false;
    _sawClosed = false;
    _blinkDetected = false;
  }

  /// Feed the latest frame's eye-open probabilities (0.0–1.0). Pass `null`
  /// for either eye when ML Kit couldn't estimate it (e.g. classification
  /// disabled, eye not visible) — such frames are ignored rather than
  /// treated as "closed", so a bad frame can't fake a blink.
  ///
  /// Returns `true` the moment a full open→closed→open cycle completes;
  /// once detected it stays `true` for the lifetime of this instance (or
  /// until [reset]).
  bool onFrame({
    required double? leftEyeOpenProbability,
    required double? rightEyeOpenProbability,
  }) {
    if (_blinkDetected) return true;
    if (leftEyeOpenProbability == null || rightEyeOpenProbability == null) {
      return false;
    }

    final avg = (leftEyeOpenProbability + rightEyeOpenProbability) / 2;

    if (avg >= openThreshold) {
      if (_sawClosed) {
        _blinkDetected = true;
        return true;
      }
      _eyesWereOpen = true;
    } else if (avg <= closedThreshold && _eyesWereOpen) {
      _sawClosed = true;
    }

    return false;
  }
}
