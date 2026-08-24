import 'dart:math';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Jenis tantangan interaktif untuk Active Liveness Detection
enum LivenessChallengeType {
  blink,
  turnLeft,
  turnRight,
  smile,
  nod,
}

/// Model untuk 1 langkah tantangan liveness
class LivenessChallenge {
  final LivenessChallengeType type;
  final String title;
  final String instruction;
  final int timeoutSeconds;

  const LivenessChallenge({
    required this.type,
    required this.title,
    required this.instruction,
    this.timeoutSeconds = 8,
  });

  factory LivenessChallenge.fromType(LivenessChallengeType type, {int timeoutSeconds = 8}) {
    switch (type) {
      case LivenessChallengeType.blink:
        return LivenessChallenge(
          type: type,
          title: 'Kedipkan Mata',
          instruction: 'Kedipkan kedua mata Anda perlahan',
          timeoutSeconds: timeoutSeconds,
        );
      case LivenessChallengeType.turnLeft:
        return LivenessChallenge(
          type: type,
          title: 'Tolehkan Kepala ke Kiri',
          instruction: 'Tolehkan kepala Anda perlahan ke arah kiri',
          timeoutSeconds: timeoutSeconds,
        );
      case LivenessChallengeType.turnRight:
        return LivenessChallenge(
          type: type,
          title: 'Tolehkan Kepala ke Kanan',
          instruction: 'Tolehkan kepala Anda perlahan ke arah kanan',
          timeoutSeconds: timeoutSeconds,
        );
      case LivenessChallengeType.smile:
        return LivenessChallenge(
          type: type,
          title: 'Tersenyum',
          instruction: 'Tersenyumlah ke arah kamera',
          timeoutSeconds: timeoutSeconds,
        );
      case LivenessChallengeType.nod:
        return LivenessChallenge(
          type: type,
          title: 'Anggukkan Kepala',
          instruction: 'Anggukkan kepala Anda ke bawah perlahan',
          timeoutSeconds: timeoutSeconds,
        );
    }
  }
}

/// Status keseluruhan sesi Liveness Detection
enum LivenessStatus {
  waitingForFace,
  faceInvalid,
  challenging,
  stepCompleted,
  allCompleted,
  failed,
}

/// Hasil evaluasi per frame
class LivenessFrameResult {
  final LivenessStatus status;
  final String message;
  final int currentStep;
  final int totalSteps;
  final LivenessChallenge? currentChallenge;
  final double progress; // 0.0 sampai 1.0
  final bool isLivenessPassed;
  final Face? bestFace;

  const LivenessFrameResult({
    required this.status,
    required this.message,
    required this.currentStep,
    required this.totalSteps,
    this.currentChallenge,
    this.progress = 0.0,
    this.isLivenessPassed = false,
    this.bestFace,
  });
}

/// Engine Active Liveness Detection
class ActiveLivenessDetector {
  final List<LivenessChallenge> _challenges = [];
  final List<LivenessChallenge>? customChallenges;
  final bool randomized;
  final int challengeCount;

  int _currentIndex = 0;
  LivenessStatus _status = LivenessStatus.waitingForFace;
  DateTime? _challengeStartTime;
  int? _lockedTrackingId;

  // State trackers per tantangan
  bool _blinkEyesWereOpen = false;
  bool _blinkSawClosed = false;
  bool _smileSawNeutral = false;
  bool _nodSawUpright = false;
  bool _turnSawNeutral = false;

  double _currentProgress = 0.0;
  DateTime? _stepTransitionTime;
  static const Duration _stepTransitionDuration = Duration(milliseconds: 700);

  ActiveLivenessDetector({
    List<LivenessChallenge>? challenges,
    this.randomized = true,
    this.challengeCount = 2,
  }) : customChallenges = challenges {
    reset();
  }

  /// Generate tantangan default (acak atau urut)
  static List<LivenessChallenge> _generateDefaultChallenges(bool random, int count) {
    final pool = [
      LivenessChallengeType.blink,
      LivenessChallengeType.turnLeft,
      LivenessChallengeType.turnRight,
      LivenessChallengeType.smile,
    ];

    if (random) {
      pool.shuffle(Random());
    }

    final selected = pool.take(count.clamp(1, pool.length)).toList();
    return selected.map((type) => LivenessChallenge.fromType(type)).toList();
  }

  /// Reset semua state liveness untuk sesi baru
  void reset({List<LivenessChallenge>? newChallenges}) {
    _challenges.clear();
    if (newChallenges != null && newChallenges.isNotEmpty) {
      _challenges.addAll(newChallenges);
    } else if (customChallenges != null && customChallenges!.isNotEmpty) {
      _challenges.addAll(customChallenges!);
    } else {
      final fresh = _generateDefaultChallenges(randomized, challengeCount);
      _challenges.addAll(fresh);
    }

    _currentIndex = 0;
    _status = LivenessStatus.waitingForFace;
    _challengeStartTime = null;
    _lockedTrackingId = null;
    _stepTransitionTime = null;
    _currentProgress = 0.0;

    _resetChallengeTrackers();
  }

  void _resetChallengeTrackers() {
    _blinkEyesWereOpen = false;
    _blinkSawClosed = false;
    _smileSawNeutral = false;
    _nodSawUpright = false;
    _turnSawNeutral = false;
    _currentProgress = 0.0;
  }

  int get currentStep => _currentIndex + 1;
  int get totalSteps => _challenges.length;
  bool get isAllPassed => _status == LivenessStatus.allCompleted;
  LivenessChallenge? get currentChallenge =>
      _currentIndex < _challenges.length ? _challenges[_currentIndex] : null;

  /// Memproses setiap frame dari kamera
  LivenessFrameResult processFrame({
    required List<Face> faces,
    required Size imageSize,
    CameraLensDirection cameraLensDirection = CameraLensDirection.front,
  }) {
    // 1. Sudah selesai semua?
    if (_status == LivenessStatus.allCompleted) {
      return LivenessFrameResult(
        status: LivenessStatus.allCompleted,
        message: 'Liveness terverifikasi!',
        currentStep: totalSteps,
        totalSteps: totalSteps,
        currentChallenge: null,
        progress: 1.0,
        isLivenessPassed: true,
        bestFace: faces.isNotEmpty ? faces.first : null,
      );
    }

    // 2. Transisi antar step (menampilkan feedback hijau sebentar)
    if (_stepTransitionTime != null) {
      final elapsed = DateTime.now().difference(_stepTransitionTime!);
      if (elapsed < _stepTransitionDuration) {
        return LivenessFrameResult(
          status: LivenessStatus.stepCompleted,
          message: 'Bagus! Lanjut ke langkah berikutnya...',
          currentStep: _currentIndex,
          totalSteps: totalSteps,
          currentChallenge: _challenges[_currentIndex - 1],
          progress: 1.0,
          isLivenessPassed: false,
          bestFace: faces.isNotEmpty ? faces.first : null,
        );
      } else {
        _stepTransitionTime = null;
        _challengeStartTime = DateTime.now();
        _resetChallengeTrackers();
      }
    }

    // 3. Validasi Keberadaan Wajah
    if (faces.isEmpty) {
      _status = LivenessStatus.waitingForFace;
      _lockedTrackingId = null;
      return LivenessFrameResult(
        status: LivenessStatus.waitingForFace,
        message: 'Posisikan wajah Anda di dalam frame',
        currentStep: currentStep,
        totalSteps: totalSteps,
        currentChallenge: currentChallenge,
        progress: 0.0,
        isLivenessPassed: false,
      );
    }

    // 4. Validasi Anti-Spoofing: Hanya 1 wajah yang boleh tampak
    if (faces.length > 1) {
      _status = LivenessStatus.faceInvalid;
      return LivenessFrameResult(
        status: LivenessStatus.faceInvalid,
        message: 'Pastikan hanya 1 wajah di dalam frame kamera',
        currentStep: currentStep,
        totalSteps: totalSteps,
        currentChallenge: currentChallenge,
        progress: 0.0,
        isLivenessPassed: false,
      );
    }

    final face = faces.first;

    // 5. Validasi Ukuran & Proporsi Wajah (Anti terlalu jauh / terlalu dekat)
    final faceWidthRatio = face.boundingBox.width / imageSize.width;
    if (faceWidthRatio < 0.15) {
      _status = LivenessStatus.faceInvalid;
      return LivenessFrameResult(
        status: LivenessStatus.faceInvalid,
        message: 'Dekatkan wajah Anda sedikit ke kamera',
        currentStep: currentStep,
        totalSteps: totalSteps,
        currentChallenge: currentChallenge,
        progress: 0.0,
        isLivenessPassed: false,
        bestFace: face,
      );
    }
    if (faceWidthRatio > 0.85) {
      _status = LivenessStatus.faceInvalid;
      return LivenessFrameResult(
        status: LivenessStatus.faceInvalid,
        message: 'Jauhkan wajah Anda sedikit dari kamera',
        currentStep: currentStep,
        totalSteps: totalSteps,
        currentChallenge: currentChallenge,
        progress: 0.0,
        isLivenessPassed: false,
        bestFace: face,
      );
    }

    // 6. Validasi Kontinuitas Tracking ID (Anti pergantian objek foto)
    if (face.trackingId != null) {
      if (_lockedTrackingId == null) {
        _lockedTrackingId = face.trackingId;
      } else if (_lockedTrackingId != face.trackingId) {
        // Objek wajah berganti di tengah sesi
        _status = LivenessStatus.failed;
        return LivenessFrameResult(
          status: LivenessStatus.failed,
          message: 'Pergantian wajah terdeteksi. Silakan ulangi.',
          currentStep: currentStep,
          totalSteps: totalSteps,
          currentChallenge: currentChallenge,
          progress: 0.0,
          isLivenessPassed: false,
          bestFace: face,
        );
      }
    }

    // 7. Mulai timer tantangan jika belum
    final now = DateTime.now();
    _challengeStartTime ??= now;

    final challenge = _challenges[_currentIndex];
    final challengeDuration = now.difference(_challengeStartTime!);

    // Cek timeout per tantangan
    if (challengeDuration.inSeconds > challenge.timeoutSeconds) {
      _status = LivenessStatus.failed;
      return LivenessFrameResult(
        status: LivenessStatus.failed,
        message: 'Waktu habis untuk tantangan ini. Silakan ulangi.',
        currentStep: currentStep,
        totalSteps: totalSteps,
        currentChallenge: challenge,
        progress: 0.0,
        isLivenessPassed: false,
        bestFace: face,
      );
    }

    _status = LivenessStatus.challenging;

    // 8. Evaluasi Tantangan Aktif
    final isSuccess = _evaluateChallenge(
      challenge: challenge,
      face: face,
      isFrontCamera: cameraLensDirection == CameraLensDirection.front,
    );

    if (isSuccess) {
      _currentIndex++;
      if (_currentIndex >= _challenges.length) {
        _status = LivenessStatus.allCompleted;
        return LivenessFrameResult(
          status: LivenessStatus.allCompleted,
          message: 'Liveness terverifikasi!',
          currentStep: totalSteps,
          totalSteps: totalSteps,
          currentChallenge: null,
          progress: 1.0,
          isLivenessPassed: true,
          bestFace: face,
        );
      } else {
        _status = LivenessStatus.stepCompleted;
        _stepTransitionTime = DateTime.now();
        return LivenessFrameResult(
          status: LivenessStatus.stepCompleted,
          message: 'Bagus! Lanjut ke langkah berikutnya...',
          currentStep: _currentIndex,
          totalSteps: totalSteps,
          currentChallenge: challenge,
          progress: 1.0,
          isLivenessPassed: false,
          bestFace: face,
        );
      }
    }

    return LivenessFrameResult(
      status: LivenessStatus.challenging,
      message: challenge.instruction,
      currentStep: currentStep,
      totalSteps: totalSteps,
      currentChallenge: challenge,
      progress: _currentProgress,
      isLivenessPassed: false,
      bestFace: face,
    );
  }

  /// Evaluasi kondisi tantangan spesifik
  bool _evaluateChallenge({
    required LivenessChallenge challenge,
    required Face face,
    required bool isFrontCamera,
  }) {
    switch (challenge.type) {
      case LivenessChallengeType.blink:
        return _evaluateBlink(face);

      case LivenessChallengeType.turnLeft:
        return _evaluateTurnLeft(face, isFrontCamera);

      case LivenessChallengeType.turnRight:
        return _evaluateTurnRight(face, isFrontCamera);

      case LivenessChallengeType.smile:
        return _evaluateSmile(face);

      case LivenessChallengeType.nod:
        return _evaluateNod(face);
    }
  }

  /// 1. Evaluasi Kedipan Mata (open -> closed -> open)
  bool _evaluateBlink(Face face) {
    final leftProb = face.leftEyeOpenProbability;
    final rightProb = face.rightEyeOpenProbability;

    if (leftProb == null || rightProb == null) {
      return false;
    }

    final avgProb = (leftProb + rightProb) / 2;

    const openThreshold = 0.65;
    const closedThreshold = 0.35;

    if (avgProb >= openThreshold) {
      if (_blinkSawClosed) {
        _currentProgress = 1.0;
        return true; // Siklus kedip tuntas!
      }
      _blinkEyesWereOpen = true;
      _currentProgress = 0.2;
    } else if (avgProb <= closedThreshold && _blinkEyesWereOpen) {
      _blinkSawClosed = true;
      _currentProgress = 0.7;
    }

    return false;
  }

  /// 2. Evaluasi Menoleh ke Kiri
  /// Di front camera: user menoleh ke kiri fisik = headEulerAngleY bernilai positif (> 15°)
  bool _evaluateTurnLeft(Face face, bool isFrontCamera) {
    final yaw = face.headEulerAngleY ?? 0.0;
    const targetYaw = 16.0;

    // Pastikan user mulai dari posisi menghadap lurus
    if (yaw.abs() < 8.0) {
      _turnSawNeutral = true;
    }

    final effectiveYaw = isFrontCamera ? yaw : -yaw;

    if (effectiveYaw > 0) {
      _currentProgress = (effectiveYaw / targetYaw).clamp(0.0, 1.0);
    } else {
      _currentProgress = 0.0;
    }

    if (_turnSawNeutral && effectiveYaw >= targetYaw) {
      return true;
    }
    return false;
  }

  /// 3. Evaluasi Menoleh ke Kanan
  /// Di front camera: user menoleh ke kanan fisik = headEulerAngleY bernilai negatif (< -15°)
  bool _evaluateTurnRight(Face face, bool isFrontCamera) {
    final yaw = face.headEulerAngleY ?? 0.0;
    const targetYaw = 16.0;

    // Pastikan user mulai dari posisi menghadap lurus
    if (yaw.abs() < 8.0) {
      _turnSawNeutral = true;
    }

    final effectiveYaw = isFrontCamera ? -yaw : yaw;

    if (effectiveYaw > 0) {
      _currentProgress = (effectiveYaw / targetYaw).clamp(0.0, 1.0);
    } else {
      _currentProgress = 0.0;
    }

    if (_turnSawNeutral && effectiveYaw >= targetYaw) {
      return true;
    }
    return false;
  }

  /// 4. Evaluasi Senyum (Neutral -> Smile)
  bool _evaluateSmile(Face face) {
    final smileProb = face.smilingProbability ?? 0.0;
    const smileThreshold = 0.65;
    const neutralThreshold = 0.30;

    if (smileProb <= neutralThreshold) {
      _smileSawNeutral = true;
    }

    _currentProgress = (smileProb / smileThreshold).clamp(0.0, 1.0);

    if (_smileSawNeutral && smileProb >= smileThreshold) {
      return true;
    }
    return false;
  }

  /// 5. Evaluasi Mengangguk (Head Pitch Down)
  bool _evaluateNod(Face face) {
    final pitch = face.headEulerAngleX ?? 0.0;
    const nodThreshold = 14.0; // Pitch down

    if (pitch.abs() < 6.0) {
      _nodSawUpright = true;
    }

    if (pitch > 0) {
      _currentProgress = (pitch / nodThreshold).clamp(0.0, 1.0);
    } else {
      _currentProgress = 0.0;
    }

    if (_nodSawUpright && pitch >= nodThreshold) {
      return true;
    }
    return false;
  }
}
