import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import 'package:gaji_pro/core/ml/recognizer.dart';
import 'package:gaji_pro/core/config/device_camera_config.dart';
import 'package:gaji_pro/core/config/device_face_detector_config.dart';
import 'package:gaji_pro/data/models/requests/face_recognition/face_verify_request_model.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_verify/face_verify_bloc.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_verify/face_verify_event.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_verify/face_verify_state.dart';
import 'package:gaji_pro/presentation/face_recognition/widgets/face_detector_painter.dart';

/// Face verification screen used before clock-in/clock-out.
/// Captures face, extracts embedding, and calls FaceVerifyBloc.
///
/// On success (FaceVerifyMatched), calls [onVerified] with the confidence.
/// Caller decides what to do next (navigate to confirmation/map screen).
class FaceVerifyScreen extends StatefulWidget {
  const FaceVerifyScreen({
    super.key,
    required this.verificationType,
    this.onVerified,
    this.onFailed,
  });

  final VerificationType verificationType;

  /// Called when face is matched. Receives [confidence] and [descriptors].
  final void Function(double confidence, List<double> descriptors)? onVerified;

  /// Called when face does not match or error occurs.
  final void Function(String reason)? onFailed;

  @override
  State<FaceVerifyScreen> createState() => _FaceVerifyScreenState();
}

class _FaceVerifyScreenState extends State<FaceVerifyScreen> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  final Recognizer _recognizer = Recognizer();

  bool _isProcessing = false;
  bool _isCameraReady = false;
  List<Face> _detectedFaces = [];
  List<double>? _lastEmbedding;

  InputImageRotation _rotation = InputImageRotation.rotation0deg;
  Size _imageSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    await _recognizer.loadModel();

    final deviceInfo = DeviceInfoPlugin();
    late DeviceCameraConfig config;
    late DeviceFaceDetectorConfig detectorConfig;

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      config = DeviceCameraConfig.fromDeviceInfo(
        brand: info.brand,
        model: info.model,
        osVersion: info.version.release,
      );
      detectorConfig = DeviceFaceDetectorConfig.fromDeviceInfo(
        brand: info.brand,
        model: info.model,
        board: info.board,
        hardware: info.hardware,
        sdkVersion: info.version.sdkInt,
      );
    } else {
      final info = await deviceInfo.iosInfo;
      config = DeviceCameraConfig.fromDeviceInfo(
        brand: 'Apple',
        model: info.model,
        osVersion: info.systemVersion,
      );
      detectorConfig = DeviceFaceDetectorConfig.fromDeviceInfo(
        brand: 'Apple',
        model: info.model,
        board: '',
        hardware: '',
        sdkVersion: 0,
      );
    }

    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final configsToTry = [
      (ResolutionPreset.medium, config.preferredImageFormat),
      (ResolutionPreset.medium, null),
      (ResolutionPreset.low, config.preferredImageFormat),
      (ResolutionPreset.low, null),
      (ResolutionPreset.high, config.preferredImageFormat),
      (ResolutionPreset.high, null),
    ];

    bool initialized = false;
    for (final cfg in configsToTry) {
      try {
        if (_cameraController != null) {
          try {
            await _cameraController!.stopImageStream();
          } catch (_) {}
          try {
            await _cameraController!.dispose();
          } catch (_) {}
          _cameraController = null;
        }

        _cameraController = CameraController(
          front,
          cfg.$1,
          imageFormatGroup: cfg.$2,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        initialized = true;
        break;
      } catch (_) {}
    }

    if (!initialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menginisialisasi kamera.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    _faceDetector = FaceDetector(options: detectorConfig.options);

    if (!mounted) return;
    setState(() => _isCameraReady = true);

    _cameraController!.startImageStream(_processCameraImage);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || !mounted) return;
    _isProcessing = true;

    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector!.processImage(inputImage);

      if (mounted) {
        setState(() {
          _detectedFaces = faces;
          _imageSize = Size(image.width.toDouble(), image.height.toDouble());
        });
      }
    } catch (_) {
      // ignore frame errors
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _buildInputImage(CameraImage image) {
    final camera = _cameraController!.description;

    InputImageRotation rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotation.rotation0deg;
    } else {
      rotation = InputImageRotationValue.fromRawValue(
            camera.sensorOrientation,
          ) ??
          InputImageRotation.rotation270deg;
    }
    _rotation = rotation;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _captureAndVerify() async {
    if (_cameraController == null || !_isCameraReady) return;
    if (_detectedFaces.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wajah tidak terdeteksi')),
        );
      }
      return;
    }

    await _cameraController!.stopImageStream();

    try {
      final xfile = await _cameraController!.takePicture();
      final Uint8List bytes = await File(xfile.path).readAsBytes();

      final image = img.decodeImage(bytes);
      if (image == null) {
        _restartCamera();
        return;
      }

      final face = _detectedFaces.first;
      final cropRect = _scaledBoundingBox(face.boundingBox, image);
      final croppedImage = img.copyCrop(
        image,
        x: cropRect.left.toInt(),
        y: cropRect.top.toInt(),
        width: cropRect.width.toInt(),
        height: cropRect.height.toInt(),
      );

      final result = _recognizer.recognize(croppedImage, cropRect);
      final embedding = result.embedding;
      _lastEmbedding = embedding;

      if (mounted) {
        context.read<FaceVerifyBloc>().add(
          VerifyFace(
            request: FaceVerifyRequestModel(
              descriptors: embedding,
              verificationType: widget.verificationType,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        _restartCamera();
      }
    }
  }

  Rect _scaledBoundingBox(Rect box, img.Image image) {
    final scaleX = image.width / _imageSize.width;
    final scaleY = image.height / _imageSize.height;
    return Rect.fromLTRB(
      (box.left * scaleX).clamp(0, image.width.toDouble()),
      (box.top * scaleY).clamp(0, image.height.toDouble()),
      (box.right * scaleX).clamp(0, image.width.toDouble()),
      (box.bottom * scaleY).clamp(0, image.height.toDouble()),
    );
  }

  void _restartCamera() {
    _cameraController?.startImageStream(_processCameraImage);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.verificationType == VerificationType.clockIn
        ? 'Verifikasi Clock In'
        : 'Verifikasi Clock Out';

    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<FaceVerifyBloc, FaceVerifyState>(
        listener: (context, state) {
          if (state is FaceVerifyMatched) {
            _cameraController?.stopImageStream();
            widget.onVerified?.call(
              state.response.confidence,
              _lastEmbedding ?? [],
            );
          } else if (state is FaceVerifyNotMatched) {
            widget.onFailed?.call('Wajah tidak cocok');
          } else if (state is FaceVerifyError) {
            widget.onFailed?.call(state.message);
          }
        },
        builder: (context, state) {
          if (state is FaceVerifyLoading) return _buildLoading();
          if (state is FaceVerifyMatched) return _buildSuccess(state);
          if (state is FaceVerifyNotMatched) return _buildNotMatched(state);
          if (state is FaceVerifyError) return _buildError(state.message);
          return _buildCamera(label);
        },
      ),
    );
  }

  Widget _buildCamera(String label) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_isCameraReady && _cameraController != null)
          CameraPreview(_cameraController!)
        else
          const Center(child: CircularProgressIndicator(color: Colors.white)),

        if (_isCameraReady)
          FaceGuideOverlay(
            faceDetected: _detectedFaces.isNotEmpty,
            instruction: _detectedFaces.isNotEmpty
                ? 'Wajah terdeteksi — tekan tombol kamera'
                : 'Posisikan wajah dalam lingkaran',
          ),

        if (_isCameraReady &&
            _cameraController != null &&
            _imageSize != Size.zero)
          CustomPaint(
            painter: FaceDetectorPainter(
              faces: _detectedFaces,
              imageSize: _imageSize,
              rotation: _rotation,
              cameraLensDirection: CameraLensDirection.front,
            ),
          ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),

        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _captureAndVerify,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _detectedFaces.isNotEmpty ? Colors.white : Colors.white38,
                  border: Border.all(color: Colors.white54, width: 3),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 32,
                  color: _detectedFaces.isNotEmpty ? Colors.black87 : Colors.white54,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Memverifikasi wajah...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(FaceVerifyMatched state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 80),
            const SizedBox(height: 24),
            const Text(
              'Wajah Dikenali',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.response.toConfidencePercentage(),
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kepercayaan',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, state.response),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Lanjutkan',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotMatched(FaceVerifyNotMatched state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.face_retouching_off,
              color: Colors.redAccent,
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              'Wajah Tidak Dikenali',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kepercayaan: ${state.response.toConfidencePercentage()}',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.read<FaceVerifyBloc>().add(ResetFaceVerify());
                _restartCamera();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 80),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.read<FaceVerifyBloc>().add(ResetFaceVerify());
                _restartCamera();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
