import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Device-specific FaceDetector configuration
/// untuk handle devices dengan ML Kit detection issues
class DeviceFaceDetectorConfig {
  final String deviceModel;
  final String deviceBoard;
  final String deviceHardware;
  final int sdkVersion;

  final FaceDetectorOptions options;
  final String reason;
  final bool isProblematic;

  const DeviceFaceDetectorConfig({
    required this.deviceModel,
    required this.deviceBoard,
    required this.deviceHardware,
    required this.sdkVersion,
    required this.options,
    required this.reason,
    required this.isProblematic,
  });

  /// Factory: Create optimal FaceDetectorOptions based on device info
  factory DeviceFaceDetectorConfig.fromDeviceInfo({
    required String brand,
    required String model,
    required String board,
    required String hardware,
    required int sdkVersion,
  }) {
    final brandLower = brand.toLowerCase();
    final modelLower = model.toLowerCase();
    final boardLower = board.toLowerCase();
    final hardwareLower = hardware.toLowerCase();

    // SAMSUNG SM-A235F (Galaxy A23 5G) - Snapdragon 695 (board: bengal)
    if (brandLower == 'samsung' &&
        (modelLower.contains('sm-a235') || boardLower == 'bengal')) {
      return DeviceFaceDetectorConfig(
        deviceModel: model,
        deviceBoard: board,
        deviceHardware: hardware,
        sdkVersion: sdkVersion,
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          minFaceSize: 0.05,
          enableContours: false,
          enableLandmarks: false,
          enableClassification: false,
          enableTracking: false,
        ),
        reason: 'Samsung Galaxy A23 5G (Snapdragon 695) - Requires relaxed detection settings',
        isProblematic: true,
      );
    }

    // SNAPDRAGON 6xx SERIES
    if (hardwareLower == 'qcom' &&
        (boardLower.contains('bengal') ||
         boardLower.contains('holi') ||
         boardLower.contains('khaje'))) {
      return DeviceFaceDetectorConfig(
        deviceModel: model,
        deviceBoard: board,
        deviceHardware: hardware,
        sdkVersion: sdkVersion,
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          minFaceSize: 0.05,
          enableContours: false,
          enableLandmarks: false,
          enableClassification: false,
          enableTracking: false,
        ),
        reason: 'Qualcomm Snapdragon 6xx Series - Optimized for mid-range chipset',
        isProblematic: true,
      );
    }

    // MEDIATEK DEVICES
    if (hardwareLower.contains('mt') || hardwareLower.contains('mediatek')) {
      return DeviceFaceDetectorConfig(
        deviceModel: model,
        deviceBoard: board,
        deviceHardware: hardware,
        sdkVersion: sdkVersion,
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          minFaceSize: 0.05,
          enableContours: false,
          enableLandmarks: false,
          enableClassification: false,
          enableTracking: false,
        ),
        reason: 'MediaTek chipset - Requires fast mode for better compatibility',
        isProblematic: true,
      );
    }

    // OPPO/REALME ColorOS 13 (Android 13)
    if ((brandLower == 'oppo' || brandLower == 'realme') && sdkVersion == 33) {
      return DeviceFaceDetectorConfig(
        deviceModel: model,
        deviceBoard: board,
        deviceHardware: hardware,
        sdkVersion: sdkVersion,
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          minFaceSize: 0.05,
          enableContours: false,
          enableLandmarks: false,
          enableClassification: false,
          enableTracking: false,
        ),
        reason: 'OPPO/Realme ColorOS 13 - Known compatibility issues with ML Kit',
        isProblematic: true,
      );
    }

    // XIAOMI MIUI 13 (Android 13)
    if (brandLower == 'xiaomi' && sdkVersion == 33) {
      return DeviceFaceDetectorConfig(
        deviceModel: model,
        deviceBoard: board,
        deviceHardware: hardware,
        sdkVersion: sdkVersion,
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          minFaceSize: 0.05,
          enableContours: false,
          enableLandmarks: false,
          enableClassification: false,
          enableTracking: false,
        ),
        reason: 'Xiaomi MIUI 13 - Optimized for better face detection',
        isProblematic: true,
      );
    }

    // SAMSUNG (OTHER MODELS - GOOD)
    if (brandLower == 'samsung') {
      return DeviceFaceDetectorConfig(
        deviceModel: model,
        deviceBoard: board,
        deviceHardware: hardware,
        sdkVersion: sdkVersion,
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          minFaceSize: 0.1,
          enableContours: false,
          enableLandmarks: false,
          enableClassification: false,
          enableTracking: false,
        ),
        reason: 'Samsung device - Standard accurate mode',
        isProblematic: false,
      );
    }

    // DEFAULT (Stock Android, Pixel, etc.)
    return DeviceFaceDetectorConfig(
      deviceModel: model,
      deviceBoard: board,
      deviceHardware: hardware,
      sdkVersion: sdkVersion,
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.1,
        enableContours: false,
        enableLandmarks: false,
        enableClassification: false,
        enableTracking: false,
      ),
      reason: 'Default configuration - Standard accurate mode',
      isProblematic: false,
    );
  }

  String get summary {
    final mode = options.performanceMode == FaceDetectorMode.fast ? 'FAST' : 'ACCURATE';
    final minSize = (options.minFaceSize * 100).toInt();
    return 'Mode: $mode, MinFace: $minSize%, Problematic: $isProblematic';
  }

  /// Print config untuk debugging
  String toDebugString() {
    return '''
DeviceFaceDetectorConfig:
  Device: $deviceModel
  Board: $deviceBoard
  Hardware: $deviceHardware
  SDK: $sdkVersion

  FaceDetectorOptions:
    Performance Mode: ${options.performanceMode}
    Min Face Size: ${(options.minFaceSize * 100).toInt()}%
    Enable Contours: ${options.enableContours}
    Enable Landmarks: ${options.enableLandmarks}
    Enable Classification: ${options.enableClassification}
    Enable Tracking: ${options.enableTracking}

  Reason: $reason
  Is Problematic: $isProblematic
''';
  }
}
