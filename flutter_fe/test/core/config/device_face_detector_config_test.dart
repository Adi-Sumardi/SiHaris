import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/core/config/device_face_detector_config.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

void main() {
  group('DeviceFaceDetectorConfig', () {
    group('Constructor', () {
      test('should create config with all required parameters', () {
        // Arrange
        final options = FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          minFaceSize: 0.1,
        );

        // Act
        final config = DeviceFaceDetectorConfig(
          deviceModel: 'SM-A235F',
          deviceBoard: 'bengal',
          deviceHardware: 'qcom',
          sdkVersion: 33,
          options: options,
          reason: 'Test device',
          isProblematic: true,
        );

        // Assert
        expect(config.deviceModel, equals('SM-A235F'));
        expect(config.deviceBoard, equals('bengal'));
        expect(config.deviceHardware, equals('qcom'));
        expect(config.sdkVersion, equals(33));
        expect(config.options, equals(options));
        expect(config.reason, equals('Test device'));
        expect(config.isProblematic, isTrue);
      });
    });

    group('fromDeviceInfo factory', () {
      group('Samsung SM-A235F (Galaxy A23 5G)', () {
        test('should use FAST mode for SM-A235F model', () {
          // Act
          final config = DeviceFaceDetectorConfig.fromDeviceInfo(
            brand: 'samsung',
            model: 'SM-A235F',
            board: 'bengal',
            hardware: 'qcom',
            sdkVersion: 33,
          );

          // Assert
          expect(config.options.performanceMode, equals(FaceDetectorMode.fast));
          expect(config.options.minFaceSize, equals(0.05));
          expect(config.isProblematic, isTrue);
          expect(config.reason, contains('Samsung Galaxy A23 5G'));
        });

        test('should use FAST mode for bengal board', () {
          // Act
          final config = DeviceFaceDetectorConfig.fromDeviceInfo(
            brand: 'Samsung',
            model: 'SM-A236B',
            board: 'bengal',
            hardware: 'qcom',
            sdkVersion: 32,
          );

          // Assert
          expect(config.options.performanceMode, equals(FaceDetectorMode.fast));
          expect(config.isProblematic, isTrue);
        });
      });

      group('Snapdragon 6xx Series', () {
        test('should use FAST mode for holi board', () {
          // Act
          final config = DeviceFaceDetectorConfig.fromDeviceInfo(
            brand: 'Xiaomi',
            model: 'Redmi Note 11',
            board: 'holi',
            hardware: 'qcom',
            sdkVersion: 31,
          );

          // Assert
          expect(config.options.performanceMode, equals(FaceDetectorMode.fast));
          expect(config.options.minFaceSize, equals(0.05));
          expect(config.isProblematic, isTrue);
          expect(config.reason, contains('Snapdragon 6xx'));
        });

        test('should use FAST mode for khaje board', () {
          // Act
          final config = DeviceFaceDetectorConfig.fromDeviceInfo(
            brand: 'Samsung',
            model: 'SM-M336',
            board: 'khaje',
            hardware: 'qcom',
            sdkVersion: 32,
          );

          // Assert
          expect(config.options.performanceMode, equals(FaceDetectorMode.fast));
          expect(config.isProblematic, isTrue);
        });
      });

      group('MediaTek Devices', () {
        test('should use FAST mode for MediaTek hardware (mt prefix)', () {
          // Act
          final config = DeviceFaceDetectorConfig.fromDeviceInfo(
            brand: 'Realme',
            model: 'RMX3263',
            board: 'k6877v1',
            hardware: 'mt6877',
            sdkVersion: 31,
          );

          // Assert
          expect(config.options.performanceMode, equals(FaceDetectorMode.fast));
          expect(config.options.minFaceSize, equals(0.05));
          expect(config.isProblematic, isTrue);
          expect(config.reason, contains('MediaTek'));
        });

        test('should use FAST mode for MediaTek hardware (mediatek keyword)', () {
          // Act
          final config = DeviceFaceDetectorConfig.fromDeviceInfo(
            brand: 'Oppo',
            model: 'CPH2325',
            board: 'k6877',
            hardware: 'mediatek',
            sdkVersion: 32,
          );

          // Assert
          expect(config.options.performanceMode, equals(FaceDetectorMode.fast));
          expect(config.isProblematic, isTrue);
        });
      });

      group('OPPO/Realme ColorOS 13', () {
        test('should use FAST mode for OPPO on Android 13', () {
          // Act
          final config = DeviceFaceDetectorConfig.fromDeviceInfo(
            brand: 'OPPO',
            model: 'CPH2365',
            board: 'k6893',
            hardware: 'k6893',
            sdkVersion: 33, // Android 13
          );

          // Assert
          expect(config.options.performanceMode, equals(FaceDetectorMode.fast));
          expect(config.options.minFaceSize, equals(0.05));
          expect(config.isProblematic, isTrue);
          expect(config.reason, contains('ColorOS 13'));
        });

        test('should use FAST mode for Realme on Android 13', () {
          // Act
          final config = DeviceFaceDetectorConfig.fromDeviceInfo(
            brand: 'realme',
            model: 'RMX3392',
            board: 'k6877',
            hardware: 'mt6877',
            sdkVersion: 33,
          );

          // Assert
          expect(config.options.performanceMode, equals(FaceDetectorMode.fast));
          expect(config.isProblematic, isTrue);
        });
      });

      group('Xiaomi MIUI 13', () {
        test('should use FAST mode for Xiaomi on Android 13', () {
          // Act
          final config = DeviceFaceDetectorConfig.fromDeviceInfo(
            brand: 'Xiaomi',
            model: 'M2102J20SI',
            board: 'lahaina',
            hardware: 'qcom',
            sdkVersion: 33,
          );

          // Assert
          expect(config.options.performanceMode, equals(FaceDetectorMode.fast));
          expect(config.options.minFaceSize, equals(0.05));
          expect(config.isProblematic, isTrue);
          expect(config.reason, contains('MIUI 13'));
        });
      });

      group('Samsung Other Models', () {
        test('should use ACCURATE mode for other Samsung devices', () {
          // Act
          final config = DeviceFaceDetectorConfig.fromDeviceInfo(
            brand: 'Samsung',
            model: 'SM-G998B',
            board: 'lahaina',
            hardware: 'qcom',
            sdkVersion: 31,
          );

          // Assert
          expect(
            config.options.performanceMode,
            equals(FaceDetectorMode.accurate),
          );
          expect(config.options.minFaceSize, equals(0.1));
          expect(config.isProblematic, isFalse);
          expect(config.reason, contains('Standard accurate mode'));
        });
      });

      group('Default Configuration', () {
        test('should use ACCURATE mode for Google Pixel', () {
          // Act
          final config = DeviceFaceDetectorConfig.fromDeviceInfo(
            brand: 'Google',
            model: 'Pixel 7',
            board: 'tensor',
            hardware: 'tensor',
            sdkVersion: 33,
          );

          // Assert
          expect(
            config.options.performanceMode,
            equals(FaceDetectorMode.accurate),
          );
          expect(config.options.minFaceSize, equals(0.1));
          expect(config.isProblematic, isFalse);
          expect(config.reason, contains('Default configuration'));
        });

        test('should use ACCURATE mode for unknown devices', () {
          // Act
          final config = DeviceFaceDetectorConfig.fromDeviceInfo(
            brand: 'UnknownBrand',
            model: 'UnknownModel',
            board: 'unknown',
            hardware: 'unknown',
            sdkVersion: 31,
          );

          // Assert
          expect(
            config.options.performanceMode,
            equals(FaceDetectorMode.accurate),
          );
          expect(config.isProblematic, isFalse);
        });
      });

      group('Case Insensitivity', () {
        test('should handle mixed case brand names', () {
          // Act
          final config1 = DeviceFaceDetectorConfig.fromDeviceInfo(
            brand: 'SAMSUNG',
            model: 'SM-A235F',
            board: 'bengal',
            hardware: 'qcom',
            sdkVersion: 33,
          );

          final config2 = DeviceFaceDetectorConfig.fromDeviceInfo(
            brand: 'Samsung',
            model: 'sm-a235f',
            board: 'BENGAL',
            hardware: 'QCOM',
            sdkVersion: 33,
          );

          // Assert - both should be detected as problematic
          expect(config1.isProblematic, isTrue);
          expect(config2.isProblematic, isTrue);
        });
      });

      group('Disabled Features', () {
        test('should disable all optional features for problematic devices', () {
          // Act
          final config = DeviceFaceDetectorConfig.fromDeviceInfo(
            brand: 'samsung',
            model: 'SM-A235F',
            board: 'bengal',
            hardware: 'qcom',
            sdkVersion: 33,
          );

          // Assert
          expect(config.options.enableContours, isFalse);
          expect(config.options.enableLandmarks, isFalse);
          expect(config.options.enableClassification, isFalse);
          expect(config.options.enableTracking, isFalse);
        });
      });
    });

    group('summary', () {
      test('should return FAST mode summary for problematic device', () {
        // Arrange
        final config = DeviceFaceDetectorConfig.fromDeviceInfo(
          brand: 'samsung',
          model: 'SM-A235F',
          board: 'bengal',
          hardware: 'qcom',
          sdkVersion: 33,
        );

        // Act
        final summary = config.summary;

        // Assert
        expect(summary, contains('FAST'));
        expect(summary, contains('5%'));
        expect(summary, contains('true'));
      });

      test('should return ACCURATE mode summary for good device', () {
        // Arrange
        final config = DeviceFaceDetectorConfig.fromDeviceInfo(
          brand: 'Google',
          model: 'Pixel 7',
          board: 'tensor',
          hardware: 'tensor',
          sdkVersion: 33,
        );

        // Act
        final summary = config.summary;

        // Assert
        expect(summary, contains('ACCURATE'));
        expect(summary, contains('10%'));
        expect(summary, contains('false'));
      });
    });

    group('toDebugString', () {
      test('should include all device information', () {
        // Arrange
        final config = DeviceFaceDetectorConfig.fromDeviceInfo(
          brand: 'samsung',
          model: 'SM-A235F',
          board: 'bengal',
          hardware: 'qcom',
          sdkVersion: 33,
        );

        // Act
        final debugString = config.toDebugString();

        // Assert
        expect(debugString, contains('SM-A235F'));
        expect(debugString, contains('bengal'));
        expect(debugString, contains('qcom'));
        expect(debugString, contains('33'));
        expect(debugString, contains('FaceDetectorMode.fast'));
        expect(debugString, contains('5%'));
        expect(debugString, contains('Is Problematic: true'));
      });
    });
  });
}
