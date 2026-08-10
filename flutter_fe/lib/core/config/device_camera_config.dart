import 'package:camera/camera.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

/// Device-specific camera configuration untuk handle berbagai vendor
/// yang memiliki implementasi Camera2 API berbeda
class DeviceCameraConfig {
  final String deviceBrand;
  final String deviceModel;
  final String osVersion;

  // Camera format preferences
  final ImageFormatGroup preferredImageFormat;
  final bool needsImageNormalization;
  final bool hasAggressiveAIBeauty;
  final InputImageFormat mlKitInputFormat;

  // Rotation handling
  final bool hasReliableOrientation;
  final int fallbackRotationDegrees;

  // Detection info
  final String detectedAs;

  const DeviceCameraConfig({
    required this.deviceBrand,
    required this.deviceModel,
    required this.osVersion,
    required this.preferredImageFormat,
    required this.needsImageNormalization,
    required this.hasAggressiveAIBeauty,
    required this.mlKitInputFormat,
    required this.hasReliableOrientation,
    required this.fallbackRotationDegrees,
    required this.detectedAs,
  });

  /// Factory: Create config based on device info
  factory DeviceCameraConfig.fromDeviceInfo({
    required String brand,
    required String model,
    required String osVersion,
  }) {
    final brandLower = brand.toLowerCase();

    // OPPO DEVICES
    if (brandLower == 'oppo') {
      if (osVersion.contains('13') || osVersion.contains('CPH2365')) {
        return const DeviceCameraConfig(
          deviceBrand: 'OPPO',
          deviceModel: 'ColorOS 13',
          osVersion: 'Android 13',
          preferredImageFormat: ImageFormatGroup.nv21,
          mlKitInputFormat: InputImageFormat.nv21,
          needsImageNormalization: true,
          hasAggressiveAIBeauty: true,
          hasReliableOrientation: false,
          fallbackRotationDegrees: 0,
          detectedAs: 'OPPO ColorOS 13 (Problematic - AI Beauty Fix Enabled)',
        );
      }
      return const DeviceCameraConfig(
        deviceBrand: 'OPPO',
        deviceModel: 'ColorOS 14/15',
        osVersion: 'Android 14/15',
        preferredImageFormat: ImageFormatGroup.yuv420,
        mlKitInputFormat: InputImageFormat.nv21,
        needsImageNormalization: false,
        hasAggressiveAIBeauty: false,
        hasReliableOrientation: true,
        fallbackRotationDegrees: 0,
        detectedAs: 'OPPO ColorOS 14/15 (Good - No Fix Needed)',
      );
    }

    // XIAOMI / REDMI DEVICES (MIUI)
    if (brandLower == 'xiaomi' || brandLower == 'redmi') {
      if (osVersion.contains('13')) {
        return const DeviceCameraConfig(
          deviceBrand: 'Xiaomi/Redmi',
          deviceModel: 'MIUI 13',
          osVersion: 'Android 13',
          preferredImageFormat: ImageFormatGroup.nv21,
          mlKitInputFormat: InputImageFormat.nv21,
          needsImageNormalization: true,
          hasAggressiveAIBeauty: true,
          hasReliableOrientation: false,
          fallbackRotationDegrees: 0,
          detectedAs: 'Xiaomi/Redmi MIUI 13 (Problematic - AI Beauty Fix Enabled)',
        );
      }
      return const DeviceCameraConfig(
        deviceBrand: 'Xiaomi/Redmi',
        deviceModel: 'MIUI 14+',
        osVersion: 'Android 14+',
        preferredImageFormat: ImageFormatGroup.yuv420,
        mlKitInputFormat: InputImageFormat.nv21,
        needsImageNormalization: false,
        hasAggressiveAIBeauty: false,
        hasReliableOrientation: true,
        fallbackRotationDegrees: 0,
        detectedAs: 'Xiaomi/Redmi MIUI 14+ (Good - No Fix Needed)',
      );
    }

    // VIVO DEVICES
    if (brandLower == 'vivo') {
      return const DeviceCameraConfig(
        deviceBrand: 'Vivo',
        deviceModel: 'FuntouchOS',
        osVersion: 'Various',
        preferredImageFormat: ImageFormatGroup.nv21,
        mlKitInputFormat: InputImageFormat.nv21,
        needsImageNormalization: true,
        hasAggressiveAIBeauty: true,
        hasReliableOrientation: false,
        fallbackRotationDegrees: 0,
        detectedAs: 'Vivo (Problematic - AI Beauty Fix Enabled)',
      );
    }

    // REALME DEVICES
    if (brandLower == 'realme') {
      return const DeviceCameraConfig(
        deviceBrand: 'Realme',
        deviceModel: 'RealmeUI',
        osVersion: 'Various',
        preferredImageFormat: ImageFormatGroup.nv21,
        mlKitInputFormat: InputImageFormat.nv21,
        needsImageNormalization: true,
        hasAggressiveAIBeauty: true,
        hasReliableOrientation: false,
        fallbackRotationDegrees: 0,
        detectedAs: 'Realme (Problematic - AI Beauty Fix Enabled)',
      );
    }

    // SAMSUNG DEVICES
    if (brandLower == 'samsung') {
      return const DeviceCameraConfig(
        deviceBrand: 'Samsung',
        deviceModel: 'One UI',
        osVersion: 'Various',
        preferredImageFormat: ImageFormatGroup.yuv420,
        mlKitInputFormat: InputImageFormat.yuv_420_888,
        needsImageNormalization: false,
        hasAggressiveAIBeauty: false,
        hasReliableOrientation: true,
        fallbackRotationDegrees: 0,
        detectedAs: 'Samsung (Good - Standard Config)',
      );
    }

    // DEFAULT (Stock Android, Pixel, etc.)
    return const DeviceCameraConfig(
      deviceBrand: 'Unknown',
      deviceModel: 'Stock Android',
      osVersion: 'Various',
      preferredImageFormat: ImageFormatGroup.yuv420,
      mlKitInputFormat: InputImageFormat.yuv_420_888,
      needsImageNormalization: false,
      hasAggressiveAIBeauty: false,
      hasReliableOrientation: true,
      fallbackRotationDegrees: 0,
      detectedAs: 'Unknown/Stock Android (Safe Default)',
    );
  }

  String toDebugString() {
    return '''
DeviceCameraConfig:
  Brand: $deviceBrand
  Model: $deviceModel
  OS: $osVersion
  Image Format: ${preferredImageFormat.name}
  ML Kit Format: ${mlKitInputFormat.name}
  Needs Normalization: $needsImageNormalization
  Has AI Beauty: $hasAggressiveAIBeauty
  Reliable Orientation: $hasReliableOrientation
  Fallback Rotation: $fallbackRotationDegrees°
''';
  }
}
