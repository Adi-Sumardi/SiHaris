import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../../../core/ml/recognizer.dart';
import '../../../core/ml/recognition_embedding.dart';
import '../../../core/ml/active_liveness_detector.dart';
import '../../../core/config/device_face_detector_config.dart';
import '../../../core/constants/colors.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../widgets/face_detector_painter.dart';
import '../widgets/liveness_guide_overlay.dart';
import 'camera_view_attendance_page.dart';

// Helper function untuk encode JPEG di isolate
Uint8List _encodeJpgInIsolate(img.Image image) {
  return img.encodeJpg(image);
}

/// Result from face verification
class FaceVerificationResult {
  final bool isValid;
  final XFile image;

  /// Skor cosine similarity (0..1, makin tinggi makin cocok). Dikirim ke
  /// backend sebagai `face_confidence`.
  final double? confidence;
  final List<double>? embedding;

  /// Whether active liveness challenges were successfully satisfied.
  final bool livenessPassed;

  FaceVerificationResult({
    required this.isValid,
    required this.image,
    this.confidence,
    this.embedding,
    required this.livenessPassed,
  });
}

/// Face verification screen for attendance (Clock In/Out) with Active Liveness Detection
class FaceVerifyAttendanceScreen extends StatefulWidget {
  final bool isClockIn;

  /// Ambang cosine similarity dari company settings (default samakan dengan
  /// backend = 0.6).
  final double matchThreshold;

  const FaceVerifyAttendanceScreen({
    super.key,
    required this.isClockIn,
    this.matchThreshold = 0.48,
  });

  @override
  State<FaceVerifyAttendanceScreen> createState() =>
      _FaceVerifyAttendanceScreenState();
}

class _FaceVerifyAttendanceScreenState
    extends State<FaceVerifyAttendanceScreen> {
  late final FaceDetector _faceDetector;
  DeviceFaceDetectorConfig? _deviceConfig;

  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  var _cameraLensDirection = CameraLensDirection.front;

  late List<RecognitionEmbedding> recognitions = [];
  CameraImage? frame;

  late Recognizer recognizer;
  bool isTakePicture = false;

  // Time-based throttling
  DateTime? _lastProcessTime;
  static const _processingInterval = Duration(milliseconds: 100);

  // Stored embedding for comparison
  List<double>? _storedEmbedding;

  // Active Liveness Detection Engine
  late final ActiveLivenessDetector _livenessDetector;
  LivenessFrameResult _livenessResult = const LivenessFrameResult(
    status: LivenessStatus.waitingForFace,
    message: 'Posisikan wajah Anda di dalam lingkaran',
    currentStep: 1,
    totalSteps: 2,
  );

  @override
  void initState() {
    super.initState();

    recognizer = Recognizer();
    _livenessDetector = ActiveLivenessDetector(randomized: true, challengeCount: 2);
    _loadStoredEmbedding();
    _initializeFaceDetector();
  }

  Future<void> _loadStoredEmbedding() async {
    _storedEmbedding = await AuthLocalDatasource().getFaceEmbedding();
    if (kDebugMode) {
      log('Loaded stored embedding: ${_storedEmbedding?.length ?? 0} dimensions');
    }
  }

  Future<void> _initializeFaceDetector() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = await DeviceInfoPlugin().androidInfo;

        _deviceConfig = DeviceFaceDetectorConfig.fromDeviceInfo(
          brand: deviceInfo.brand,
          model: deviceInfo.model,
          board: deviceInfo.board,
          hardware: deviceInfo.hardware,
          sdkVersion: deviceInfo.version.sdkInt,
        );

        if (kDebugMode) {
          log('Device-Specific FaceDetector Config for Liveness:');
          log(_deviceConfig!.toDebugString());
        }

        _faceDetector = FaceDetector(
          options: _deviceConfig!.toLivenessOptions(
            enableClassification: true,
            enableTracking: true,
          ),
        );
      } else {
        // iOS
        final deviceInfo = await DeviceInfoPlugin().iosInfo;

        _deviceConfig = DeviceFaceDetectorConfig(
          deviceModel: '${deviceInfo.localizedModel} (${deviceInfo.model})',
          deviceBoard: deviceInfo.utsname.machine,
          deviceHardware: deviceInfo.utsname.machine,
          sdkVersion: 0,
          options: FaceDetectorOptions(
            performanceMode: FaceDetectorMode.accurate,
            minFaceSize: 0.1,
            enableContours: false,
            enableLandmarks: false,
            enableClassification: true,
            enableTracking: true,
          ),
          reason: 'iOS device - Standard accurate mode configuration',
          isProblematic: false,
        );

        _faceDetector = FaceDetector(options: _deviceConfig!.options);
      }
    } catch (e) {
      if (kDebugMode) {
        log('Failed to get device-specific config, using default: $e');
      }

      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: false,
          enableLandmarks: false,
          enableClassification: true,
          enableTracking: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    super.dispose();
  }

  void _onManualCapture(CameraImage cameraImage) {
    if (!_livenessResult.isLivenessPassed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_livenessResult.message),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    _takePicture(cameraImage);
  }

  void _takePicture(CameraImage cameraImage) async {
    setState(() {
      frame = cameraImage;
      isTakePicture = true;
    });
  }

  Future<XFile> _saveFullImageAsXFile(img.Image fullImage) async {
    final dir = await getApplicationDocumentsDirectory();
    final attendanceDir = Directory('${dir.path}/attendance_photos');

    if (!await attendanceDir.exists()) {
      await attendanceDir.create(recursive: true);
    }

    final path =
        '${attendanceDir.path}/full_face_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final bytes = await compute(_encodeJpgInIsolate, fullImage);

    final file = File(path);
    await file.writeAsBytes(bytes);

    if (kDebugMode) {
      log('Face image saved to: $path (${bytes.length} bytes)');
    }

    return XFile(file.path);
  }

  img.Image convertCameraImageToColorImage(CameraImage cameraImage) {
    // iOS BGRA8888 format
    if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      return _convertBGRA8888toRGB(cameraImage);
    }

    // Android: Check number of planes
    // Some devices provide NV21 with 1 plane, others provide YUV420 with 3 planes
    if (cameraImage.planes.length == 1) {
      // NV21 format with single plane - convert to grayscale
      return _convertNV21SinglePlaneToRGB(cameraImage);
    }

    if (cameraImage.planes.length < 3) {
      // Unexpected plane count - fallback to grayscale from Y plane only
      if (kDebugMode) {
        log('⚠️ Unexpected plane count: ${cameraImage.planes.length}');
      }
      return _convertYPlaneOnlyToGrayscale(cameraImage);
    }

    // Android YUV420 format with 3 planes (standard case)
    final width = cameraImage.width;
    final height = cameraImage.height;

    final yPlane = cameraImage.planes[0].bytes;
    final uPlane = cameraImage.planes[1].bytes;
    final vPlane = cameraImage.planes[2].bytes;

    final yRowStride = cameraImage.planes[0].bytesPerRow;
    final uvPixelStride = cameraImage.planes[1].bytesPerPixel!;
    final uvRowStride = cameraImage.planes[1].bytesPerRow;

    final image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);

        final yValue = yPlane[y * yRowStride + x];

        final uValue = uvIndex < uPlane.length ? uPlane[uvIndex] : 128;
        final vValue = uvIndex < vPlane.length ? vPlane[uvIndex] : 128;

        final r = (yValue + 1.370705 * (vValue - 128)).clamp(0, 255).toInt();
        final g =
            (yValue - 0.337633 * (uValue - 128) - 0.698001 * (vValue - 128))
                .clamp(0, 255)
                .toInt();
        final b = (yValue + 1.732446 * (uValue - 128)).clamp(0, 255).toInt();

        image.setPixelRgb(x, y, r, g, b);
      }
    }

    return image;
  }

  /// Convert NV21 single plane to RGB image
  /// NV21 format: Y plane followed by interleaved VU
  img.Image _convertNV21SinglePlaneToRGB(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final plane = cameraImage.planes[0];
    final bytes = plane.bytes;
    final bytesPerRow = plane.bytesPerRow;

    final image = img.Image(width: width, height: height);

    // Y data size
    final ySize = width * height;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Y value
        final yIndex = y * bytesPerRow + x;
        final yValue = yIndex < bytes.length ? bytes[yIndex] : 128;

        // VU interleaved after Y data
        // NV21: YYYYYYYY... VUVUVU...
        final uvIndex = ySize + (y ~/ 2) * width + (x ~/ 2) * 2;

        int vValue = 128;
        int uValue = 128;

        if (uvIndex + 1 < bytes.length) {
          vValue = bytes[uvIndex];
          uValue = bytes[uvIndex + 1];
        }

        final r = (yValue + 1.370705 * (vValue - 128)).clamp(0, 255).toInt();
        final g =
            (yValue - 0.337633 * (uValue - 128) - 0.698001 * (vValue - 128))
                .clamp(0, 255)
                .toInt();
        final b = (yValue + 1.732446 * (uValue - 128)).clamp(0, 255).toInt();

        image.setPixelRgb(x, y, r, g, b);
      }
    }

    return image;
  }

  /// Fallback: Convert Y plane only to grayscale
  img.Image _convertYPlaneOnlyToGrayscale(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final yPlane = cameraImage.planes[0].bytes;
    final yRowStride = cameraImage.planes[0].bytesPerRow;

    final image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yRowStride + x;
        final yValue = yIndex < yPlane.length ? yPlane[yIndex] : 128;
        image.setPixelRgb(x, y, yValue, yValue, yValue);
      }
    }

    return image;
  }

  Future<void> performFaceRecognition(List<Face> faces) async {
    try {
      recognitions.clear();

      if (_storedEmbedding == null || _storedEmbedding!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Wajah belum terdaftar. Silakan daftarkan wajah terlebih dahulu.'),
              backgroundColor: AppColors.danger,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      final colorImage = convertCameraImageToColorImage(frame!);

      // Rotation angle - same as CSA
      int rotationAngle;
      if (Platform.isIOS && _cameraLensDirection == CameraLensDirection.front) {
        rotationAngle = 0;
      } else {
        rotationAngle = _cameraLensDirection == CameraLensDirection.front
            ? 270
            : 90;
      }

      final rotatedColorImage = rotationAngle != 0
          ? img.copyRotate(colorImage, angle: rotationAngle)
          : colorImage;

      // Get largest face
      final Face face = faces.reduce((a, b) {
        final areaA = a.boundingBox.width * a.boundingBox.height;
        final areaB = b.boundingBox.width * b.boundingBox.height;
        return areaA >= areaB ? a : b;
      });
      final Rect faceRect = face.boundingBox;

      // Crop face with bounds checking
      img.Image croppedFace = img.copyCrop(
        rotatedColorImage,
        x: faceRect.left.toInt().clamp(0, rotatedColorImage.width - 1),
        y: faceRect.top.toInt().clamp(0, rotatedColorImage.height - 1),
        width: faceRect.width
            .toInt()
            .clamp(1, rotatedColorImage.width - faceRect.left.toInt()),
        height: faceRect.height
            .toInt()
            .clamp(1, rotatedColorImage.height - faceRect.top.toInt()),
      );

      RecognitionEmbedding recognition = recognizer.recognize(
        croppedFace,
        face.boundingBox,
      );

      recognitions.add(recognition);

      // Compare with stored embedding using cosine similarity (metrik & threshold
      // sama persis dengan backend). Match bila similarity >= threshold.
      final faceSimilarity =
          recognizer.cosineSimilarity(_storedEmbedding!, recognition.embedding);
      final threshold = widget.matchThreshold > 0.50 ? 0.50 : widget.matchThreshold;
      final isValid = faceSimilarity >= threshold;

      if (kDebugMode) {
        log('┌─────────────────────────────────────────────────────────');
        log('│ Face Recognition Summary');
        log('├─────────────────────────────────────────────────────────');
        log('│ Threshold (cosine): $threshold');
        log('│ Similarity: ${faceSimilarity.toStringAsFixed(4)}');
        log('│ Result: ${isValid ? 'VALID' : 'INVALID'}');
        log('└─────────────────────────────────────────────────────────');
      }

      if (!mounted) return;

      if (isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verifikasi wajah berhasil'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 1),
          ),
        );

        final xfile = await _saveFullImageAsXFile(rotatedColorImage);

        if (!mounted) return;

        Navigator.pop(
          context,
          FaceVerificationResult(
            isValid: true,
            image: xfile,
            confidence: faceSimilarity,
            embedding: recognition.embedding,
            livenessPassed: true,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wajah tidak cocok dengan data biometrik terdaftar'),
            backgroundColor: AppColors.danger,
          ),
        );

        // Require fresh liveness challenges for the next attempt
        _livenessDetector.reset();

        if (mounted) {
          setState(() {
            isTakePicture = false;
            _canProcess = true;
          });
        }
      }

      frame = null;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        log('Face recognition error: $e');
        log('Stack trace: $stackTrace');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Face recognition error: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );

        _livenessDetector.reset();

        setState(() {
          isTakePicture = false;
          _canProcess = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isClockIn ? 'Verifikasi Clock In' : 'Verifikasi Clock Out';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // LAYER 1: Camera with Liveness Overlay
          CameraViewAttendancePage(
            title: title,
            customPaint: _customPaint,
            onImage: _processImage,
            initialCameraLensDirection: _cameraLensDirection,
            onCameraLensDirectionChanged: (value) =>
                _cameraLensDirection = value,
            onTakePicture: _onManualCapture,
            overlay: LivenessGuideOverlay(
              result: _livenessResult,
              onRetry: () {
                setState(() {
                  _livenessDetector.reset();
                  _canProcess = true;
                  isTakePicture = false;
                });
              },
            ),
          ),

          // LAYER 2: Loading indicator during biometric matching
          if (isTakePicture)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Memverifikasi biometrik wajah...',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    try {
      if (!_canProcess) {
        return;
      }

      if (_isBusy) {
        return;
      }

      // Time-based throttling (except when taking picture)
      if (!isTakePicture) {
        final now = DateTime.now();
        if (_lastProcessTime != null &&
            now.difference(_lastProcessTime!) < _processingInterval) {
          return;
        }
        _lastProcessTime = now;
      }

      _isBusy = true;

      final faces = await _faceDetector.processImage(inputImage);

      // Create painter with metadata
      Size imageSize;
      InputImageRotation imageRotation;

      if (inputImage.metadata?.size != null &&
          inputImage.metadata?.rotation != null) {
        imageSize = inputImage.metadata!.size;
        imageRotation = inputImage.metadata!.rotation;
      } else {
        imageSize = inputImage.metadata?.size ?? const Size(1920, 1080);
        imageRotation =
            inputImage.metadata?.rotation ?? InputImageRotation.rotation0deg;
      }

      // 1. Process active liveness detection
      final livenessResult = _livenessDetector.processFrame(
        faces: faces,
        imageSize: imageSize,
        cameraLensDirection: _cameraLensDirection,
      );

      _livenessResult = livenessResult;

      // 2. Face Detector Painter for visualization
      final painter = FaceDetectorPainter(
        faces: faces,
        imageSize: imageSize,
        rotation: imageRotation,
        cameraLensDirection: _cameraLensDirection,
      );

      _customPaint = CustomPaint(painter: painter);

      // 3. Auto-trigger recognition as soon as all liveness challenges pass!
      if (livenessResult.status == LivenessStatus.allCompleted &&
          !isTakePicture &&
          _canProcess &&
          faces.isNotEmpty) {
        isTakePicture = true;
        _canProcess = false;
        _isBusy = false;

        if (mounted) setState(() {});

        // Process biometric matching with current frame
        await performFaceRecognition(faces);
        return;
      }

      _isBusy = false;

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      log('Error processing image in liveness verification: $e');
      _isBusy = false;
    }
  }

  img.Image _convertBGRA8888toRGB(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final out = img.Image(width: width, height: height);

    final plane = cameraImage.planes[0];
    final bytes = plane.bytes;
    final bytesPerRow = plane.bytesPerRow;
    final bytesPerPixel = plane.bytesPerPixel ?? 4;

    for (int y = 0; y < height; y++) {
      final rowStart = y * bytesPerRow;
      for (int x = 0; x < width; x++) {
        final pixelStart = rowStart + (x * bytesPerPixel);

        if (pixelStart + 3 < bytes.length) {
          final b = bytes[pixelStart];
          final g = bytes[pixelStart + 1];
          final r = bytes[pixelStart + 2];
          final a = bytes[pixelStart + 3];

          out.setPixelRgba(x, y, r, g, b, a);
        } else {
          out.setPixelRgba(x, y, 128, 128, 128, 255);
        }
      }
    }

    return out;
  }
}
