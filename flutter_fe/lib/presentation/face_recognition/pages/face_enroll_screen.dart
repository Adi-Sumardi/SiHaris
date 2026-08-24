import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import '../../../core/config/device_face_detector_config.dart';
import '../../../core/ml/recognizer.dart';
import '../../../core/ml/recognition_embedding.dart';
import '../../../core/constants/colors.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/models/requests/face_recognition/face_enroll_request_model.dart';
import '../bloc/face_enroll/face_enroll_bloc.dart';
import '../bloc/face_enroll/face_enroll_event.dart';
import '../bloc/face_enroll/face_enroll_state.dart';
import '../widgets/face_detector_painter.dart';
import 'detector_view.dart';

class FaceEnrollScreen extends StatefulWidget {
  const FaceEnrollScreen({super.key});

  @override
  State<FaceEnrollScreen> createState() => _FaceEnrollScreenState();
}

class _FaceEnrollScreenState extends State<FaceEnrollScreen> {
  FaceDetector? _faceDetector;
  DeviceFaceDetectorConfig? _detectorConfig;

  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  var _cameraLensDirection = CameraLensDirection.front;

  late List<RecognitionEmbedding> recognitions = [];
  CameraImage? frame;
  late Recognizer recognizer;
  bool register = false;
  bool _faceDetected = false;

  List<Face>? _latestFaces;
  InputImage? _latestInputImage;

  int _frameCount = 0;
  int _faceDetectedCount = 0;

  @override
  void initState() {
    super.initState();
    recognizer = Recognizer();
    _initFaceDetector();
  }

  /// Build the FaceDetector using device-specific tuning so mid-range
  /// chipsets (Snapdragon 6xx, MediaTek, Samsung Bengal, ColorOS 13,
  /// MIUI 13, ...) that struggle with the strict default settings can
  /// still detect a face. Mirrors the config already used by
  /// FaceVerifyScreen for the attendance flow.
  Future<void> _initFaceDetector() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        _detectorConfig = DeviceFaceDetectorConfig.fromDeviceInfo(
          brand: info.brand,
          model: info.model,
          board: info.board,
          hardware: info.hardware,
          sdkVersion: info.version.sdkInt,
        );
      } else {
        final info = await deviceInfo.iosInfo;
        _detectorConfig = DeviceFaceDetectorConfig.fromDeviceInfo(
          brand: 'Apple',
          model: info.model,
          board: '',
          hardware: '',
          sdkVersion: 0,
        );
      }

      if (kDebugMode) {
        log(_detectorConfig!.toDebugString());
      }
    } catch (e) {
      log('⚠️ Failed to resolve device face detector config: $e');
      _detectorConfig = null;
    }

    if (!mounted) return;

    setState(() {
      _faceDetector = FaceDetector(
        options: _detectorConfig?.options ??
            FaceDetectorOptions(
              performanceMode: FaceDetectorMode.accurate,
              minFaceSize: 0.1,
              enableContours: false,
              enableLandmarks: false,
              enableTracking: true,
            ),
      );
    });
  }

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector?.close();
    super.dispose();
  }

  void _takePicture(CameraImage cameraImage) async {
    log("📸 Taking picture with camera image: ${cameraImage.width}x${cameraImage.height}");
    frame = cameraImage;

    // If we already have detected faces from recent frames, process immediately!
    if (_latestFaces != null && _latestFaces!.isNotEmpty && _latestInputImage != null) {
      log("⚡ Instant capture with ${_latestFaces!.length} detected face(s)");
      register = false;
      await _performFaceRecognition(_latestFaces!, _latestInputImage!);
      return;
    }

    setState(() {
      register = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sedang mendeteksi wajah, harap tetap menghadap kamera..."),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  img.Image? image;

  Future<void> _performFaceRecognition(List<Face> faces, InputImage inputImage) async {
    try {
      recognitions.clear();

      log('🔍 Processing ${faces.length} face(s) for registration');

      // Convert camera image to color image
      image = _convertCameraImage(frame!);

      // Determine rotation angle based on platform and camera
      int rotationAngle;
      if (Platform.isIOS && _cameraLensDirection == CameraLensDirection.front) {
        rotationAngle = 0;
      } else if (Platform.isAndroid) {
        rotationAngle = _cameraLensDirection == CameraLensDirection.front ? 270 : 90;
      } else {
        final rotEnum = inputImage.metadata?.rotation ?? InputImageRotation.rotation0deg;
        rotationAngle = _rotationToDegrees(rotEnum);
      }

      // Rotate the ENTIRE image FIRST (before cropping)
      final rotatedImage = rotationAngle != 0
          ? img.copyRotate(image!, angle: rotationAngle)
          : image!;

      log('🔄 Image rotated: ${image!.width}x${image!.height} -> ${rotatedImage.width}x${rotatedImage.height} (angle: $rotationAngle)');

      for (Face face in faces) {
        Rect faceRect = face.boundingBox;

        // Crop from ROTATED image using bounding box directly
        img.Image croppedFace = img.copyCrop(
          rotatedImage,
          x: faceRect.left.toInt().clamp(0, rotatedImage.width),
          y: faceRect.top.toInt().clamp(0, rotatedImage.height),
          width: faceRect.width.toInt().clamp(1, rotatedImage.width - faceRect.left.toInt()),
          height: faceRect.height.toInt().clamp(1, rotatedImage.height - faceRect.top.toInt()),
        );

        log('✂️ Face cropped: ${croppedFace.width}x${croppedFace.height}');

        RecognitionEmbedding recognition = recognizer.recognize(
          croppedFace,
          face.boundingBox,
        );

        recognitions.add(recognition);

        log('🧬 Face embedding extracted: ${recognition.embedding.length} dimensions');

        if (register) {
          _showFaceRegistrationDialog(croppedFace, recognition);
          register = false;
        }
      }

      setState(() {});
    } catch (e, stackTrace) {
      log('❌ Error in performFaceRecognition: $e');
      log('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Face recognition error: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showFaceRegistrationDialog(img.Image croppedFace, RecognitionEmbedding recognition) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Daftarkan Wajah", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                Uint8List.fromList(img.encodeBmp(croppedFace)),
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            BlocConsumer<FaceEnrollBloc, FaceEnrollState>(
              listener: (context, state) async {
                if (state is FaceEnrollSuccess) {
                  // Save embedding to local storage for verification
                  await AuthLocalDatasource().saveFaceEmbedding(recognition.embedding);

                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    Navigator.of(context).pop(true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Wajah berhasil didaftarkan!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
                if (state is FaceEnrollError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is FaceEnrollLoading) {
                  return const SizedBox(
                    height: 48,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          String? photoBase64;
                          try {
                            photoBase64 = base64Encode(img.encodeJpg(croppedFace, quality: 85));
                          } catch (e) {
                            debugPrint('Failed to encode cropped face to jpg: $e');
                          }

                          context.read<FaceEnrollBloc>().add(
                            SubmitFaceEnroll(
                              request: FaceEnrollRequestModel(
                                descriptors: recognition.embedding,
                                photoBase64: photoBase64,
                              ),
                            ),
                          );
                        },
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Convert camera image to RGB image
  img.Image _convertCameraImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;

    if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      // iOS BGRA8888 format
      return _convertBGRA8888toRGB(cameraImage);
    } else if (cameraImage.format.group == ImageFormatGroup.nv21) {
      // Android NV21 -> grayscale
      final rowStride = cameraImage.planes[0].bytesPerRow;
      final yPlane = cameraImage.planes[0].bytes;
      final out = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final yVal = yPlane[y * rowStride + x];
          out.setPixelRgba(x, y, yVal, yVal, yVal, 255);
        }
      }
      return out;
    } else if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      // YUV_420_888
      return _convertYUV420toRGB(cameraImage);
    } else {
      throw Exception("Format kamera tidak didukung: ${cameraImage.format.group}");
    }
  }

  img.Image _convertYUV420toRGB(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final out = img.Image(width: width, height: height);

    // Check if we have enough planes for YUV420
    if (image.planes.length < 3) {
      // Fallback to grayscale if not enough planes
      log('⚠️ YUV420 expected 3 planes, got ${image.planes.length}. Using grayscale.');
      final yPlane = image.planes[0];
      final yRowStride = yPlane.bytesPerRow;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final yIndex = y * yRowStride + x;
          final yVal = yIndex < yPlane.bytes.length ? yPlane.bytes[yIndex] : 128;
          out.setPixelRgba(x, y, yVal, yVal, yVal, 255);
        }
      }
      return out;
    }

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yRowStride = yPlane.bytesPerRow;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      final yRow = y * yRowStride;
      final uvRow = (y ~/ 2) * uvRowStride;

      for (int x = 0; x < width; x++) {
        final yIndex = yRow + x;
        final yVal = yIndex < yPlane.bytes.length ? yPlane.bytes[yIndex] : 128;
        final uvIndex = uvRow + (x ~/ 2) * uvPixelStride;

        if (uvIndex < uPlane.bytes.length && uvIndex < vPlane.bytes.length) {
          final uVal = uPlane.bytes[uvIndex];
          final vVal = vPlane.bytes[uvIndex];

          int r = (yVal + 1.370705 * (vVal - 128)).round();
          int g = (yVal - 0.337633 * (uVal - 128) - 0.698001 * (vVal - 128)).round();
          int b = (yVal + 1.732446 * (uVal - 128)).round();

          out.setPixelRgba(x, y, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255), 255);
        } else {
          out.setPixelRgba(x, y, 128, 128, 128, 255);
        }
      }
    }
    return out;
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

  @override
  Widget build(BuildContext context) {
    return DetectorView(
      title: 'Face Detector',
      customPaint: _customPaint,
      faceDetected: _faceDetected,
      onImage: _processImage,
      initialCameraLensDirection: _cameraLensDirection,
      onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
      onTakePicture: _takePicture,
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    try {
      if (!_canProcess) return;
      if (_isBusy) return;
      final detector = _faceDetector;
      if (detector == null) return; // still resolving device-specific config

      _isBusy = true;
      _frameCount++;

      final stopwatch = Stopwatch()..start();
      final faces = await detector.processImage(inputImage);
      stopwatch.stop();

      // Log detection result periodically
      if (kDebugMode && _frameCount % 30 == 0) {
        if (faces.isEmpty) {
          log("❌ Frame #$_frameCount: NO FACE DETECTED (${stopwatch.elapsedMilliseconds}ms)");
        } else {
          log("✅ Frame #$_frameCount: ${faces.length} face(s) DETECTED! (${stopwatch.elapsedMilliseconds}ms)");
        }
      }

      if (faces.isEmpty) {
        if (register) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Tidak ada wajah terdeteksi. Coba lagi dengan pencahayaan cukup."),
                backgroundColor: AppColors.warning,
              ),
            );
          }
          register = false;
        }
        _customPaint = null;
        _faceDetected = false;
        _latestFaces = null;
        _isBusy = false;
        if (mounted) setState(() {});
        return;
      }

      _faceDetectedCount++;
      _faceDetected = true;
      _latestFaces = faces;
      _latestInputImage = inputImage;

      if (inputImage.metadata?.size != null && inputImage.metadata?.rotation != null) {
        final painter = FaceDetectorPainter(
          faces: faces,
          imageSize: inputImage.metadata!.size,
          rotation: inputImage.metadata!.rotation,
          cameraLensDirection: _cameraLensDirection,
        );

        if (register) {
          log('🎯 Starting face recognition for ${faces.length} face(s)');
          register = false;
          await _performFaceRecognition(faces, inputImage);
        }

        _customPaint = CustomPaint(painter: painter);
      } else {
        _customPaint = null;
      }

      _isBusy = false;
      if (mounted) setState(() {});
    } catch (e, stackTrace) {
      log("❌ Error in _processImage: $e");
      log("Stack trace: $stackTrace");
      _isBusy = false;
    }
  }

  int _rotationToDegrees(InputImageRotation r) {
    switch (r) {
      case InputImageRotation.rotation0deg:
        return 0;
      case InputImageRotation.rotation90deg:
        return 90;
      case InputImageRotation.rotation180deg:
        return 180;
      case InputImageRotation.rotation270deg:
        return 270;
    }
  }
}
