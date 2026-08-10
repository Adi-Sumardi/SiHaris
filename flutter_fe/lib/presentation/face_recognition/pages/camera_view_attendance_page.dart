// Copied EXACTLY from CSA project - camera_view_attendance_page.dart
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../../core/ml/recognizer.dart';
import '../../../core/ml/recognition_embedding.dart';
import '../../../core/constants/colors.dart';

class CameraViewAttendancePage extends StatefulWidget {
  const CameraViewAttendancePage({
    super.key,
    required this.title,
    required this.customPaint,
    required this.onImage,
    this.onCameraFeedReady,
    this.onCameraLensDirectionChanged,
    this.initialCameraLensDirection = CameraLensDirection.back,
    required this.onTakePicture,
  });

  final String title;
  final CustomPaint? customPaint;
  final Function(InputImage inputImage) onImage;
  final VoidCallback? onCameraFeedReady;

  final Function(CameraLensDirection direction)? onCameraLensDirectionChanged;
  final CameraLensDirection initialCameraLensDirection;
  final Function(CameraImage cameraImage) onTakePicture;

  @override
  State<CameraViewAttendancePage> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraViewAttendancePage> {
  static List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = -1;
  double _currentZoomLevel = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  final bool _changingCameraLens = false;

  late List<RecognitionEmbedding> recognitions = [];
  CameraImage? frame;
  CameraLensDirection camDirec = CameraLensDirection.front;
  Recognizer? recognizer;
  FaceDetector? detector;

  int _cameraFrameCount = 0;

  @override
  void initState() {
    super.initState();

    try {
      recognizer = Recognizer();

      detector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
        ),
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        developer.log(
          'CameraView initialization error',
          error: e,
          stackTrace: stackTrace,
        );
      }

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal inisialisasi: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        });
      }
    }

    _initialize();
  }

  void _initialize() async {
    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
      }

      if (_cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada kamera yang terdeteksi pada perangkat ini'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      for (var i = 0; i < _cameras.length; i++) {
        if (_cameras[i].lensDirection == widget.initialCameraLensDirection) {
          _cameraIndex = i;
          break;
        }
      }

      if (_cameraIndex != -1) {
        _startLiveFeed();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Kamera ${widget.initialCameraLensDirection.name} tidak tersedia'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        developer.log('Camera detection error: $e');
        developer.log('Stack trace: $stackTrace');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendeteksi kamera: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _stopLiveFeed();
    super.dispose();
  }

  @override
  void didUpdateWidget(CameraViewAttendancePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger rebuild when customPaint changes
    if (widget.customPaint != oldWidget.customPaint) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_outlined, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _liveFeedBody(),
    );
  }

  Widget _liveFeedBody() {
    if (_cameras.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Memuat daftar kamera...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_controller == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Menginisialisasi kamera...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_controller?.value.isInitialized == false) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Menyiapkan kamera...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Mohon tunggu sebentar',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Center(
          child: _changingCameraLens
              ? const Center(
                  child: Text(
                    'Ganti Kamera...',
                    style: TextStyle(color: Colors.white, fontSize: 24.0),
                  ),
                )
              : CameraPreview(_controller!, child: widget.customPaint),
        ),
        _zoomControl(),
        _takePictureButton(),
      ],
    );
  }

  Widget _takePictureButton() => Positioned(
    bottom: 60.0,
    left: MediaQuery.of(context).size.width / 2 - 35.0,
    child: IconButton(
      onPressed: () {
        if (frame == null) {
          if (kDebugMode) {
            developer.log(
              'Take picture button clicked but NO FRAME available!',
            );
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kamera belum siap. Mohon tunggu sebentar.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        widget.onTakePicture(frame!);
      },
      icon: const Icon(Icons.circle, size: 70.0),
      color: AppColors.danger,
    ),
  );

  Widget _zoomControl() => Positioned(
    bottom: 36,
    left: 0,
    right: 0,
    child: Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: 250,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Slider(
                value: _currentZoomLevel,
                min: _minAvailableZoom,
                max: _maxAvailableZoom,
                activeColor: Colors.white,
                inactiveColor: Colors.white30,
                onChanged: (value) async {
                  setState(() {
                    _currentZoomLevel = value;
                  });
                  await _controller?.setZoomLevel(value);
                },
              ),
            ),
            Container(
              width: 50,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    '${_currentZoomLevel.toStringAsFixed(1)}x',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future _startLiveFeed() async {
    try {
      final camera = _cameras[_cameraIndex];

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _controller?.initialize().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Camera initialization timeout');
        },
      );

      if (!mounted) {
        return;
      }

      _controller?.getMinZoomLevel().then((value) {
        _currentZoomLevel = value;
        _minAvailableZoom = value;
      });
      _controller?.getMaxZoomLevel().then((value) {
        _maxAvailableZoom = value;
      });

      await _controller?.startImageStream(_processCameraImage).then((value) {
        if (widget.onCameraFeedReady != null) {
          widget.onCameraFeedReady!();
        }
        if (widget.onCameraLensDirectionChanged != null) {
          widget.onCameraLensDirectionChanged!(camera.lensDirection);
        }
      });

      setState(() {});
    } catch (e, stackTrace) {
      if (kDebugMode) {
        developer.log('Camera initialization error: $e');
        developer.log('Stack trace: $stackTrace');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menginisialisasi kamera: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      rethrow;
    }
  }

  Future _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  void _processCameraImage(CameraImage image) async {
    if (!mounted || _controller == null) {
      return;
    }

    frame = image;
    _cameraFrameCount++;

    final inputImage = _inputImageFromCameraImage(image);

    if (inputImage == null) {
      return;
    }

    widget.onImage(inputImage);
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      if (camera.lensDirection == CameraLensDirection.front) {
        rotation = InputImageRotation.rotation0deg;
      } else {
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      }
    } else {
      final deviceOrientation = _controller!.value.deviceOrientation;
      var rotationCompensation = _orientations[deviceOrientation];

      if (rotationCompensation == null) {
        if (kDebugMode) {
          developer.log(
            'Device orientation not found: $deviceOrientation, using portraitUp (0)',
          );
        }
        rotationCompensation = 0;
      }

      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }

      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) {
      if (kDebugMode) {
        developer.log('Invalid rotation value!');
      }
      return null;
    }

    // iOS handling
    if (Platform.isIOS) {
      final format = InputImageFormatValue.fromRawValue(image.format.raw);

      if (format == null) {
        if (kDebugMode) {
          developer.log('iOS: Unknown format raw value: ${image.format.raw}');
        }
        return null;
      }

      final plane = image.planes.first;

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      );

      return InputImage.fromBytes(bytes: plane.bytes, metadata: metadata);
    }

    // Android handling
    // Check if image has correct number of planes for YUV420/NV21
    if (image.planes.length < 3) {
      // Some devices provide NV21 directly with 1 plane
      if (image.planes.length == 1) {
        final plane = image.planes.first;
        final metadata = InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: plane.bytesPerRow,
        );
        return InputImage.fromBytes(bytes: plane.bytes, metadata: metadata);
      }

      if (kDebugMode) {
        developer.log('Unexpected number of planes: ${image.planes.length}');
      }
      return null;
    }

    final bytes = _yuv420ToNv21(image);

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: InputImageFormat.nv21,
      bytesPerRow: image.width,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  bool _yuv420LoggedOnce = false;

  Uint8List _yuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final yPlane = image.planes[0].bytes;
    final uPlane = image.planes[1].bytes;
    final vPlane = image.planes[2].bytes;

    final yRowStride = image.planes[0].bytesPerRow;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    if (kDebugMode && !_yuv420LoggedOnce) {
      developer.log('YUV420 Conversion Info:');
      developer.log('  - Image size: ${width}x$height');
      developer.log(
        '  - Plane 0 (Y): bytesPerRow=$yRowStride, length=${yPlane.length}',
      );
      developer.log(
        '  - Plane 1 (U): bytesPerRow=$uvRowStride, bytesPerPixel=$uvPixelStride, length=${uPlane.length}',
      );
      developer.log(
        '  - Plane 2 (V): bytesPerRow=${image.planes[2].bytesPerRow}, bytesPerPixel=${image.planes[2].bytesPerPixel}, length=${vPlane.length}',
      );

      if (yRowStride > width) {
        developer.log(
          '  Y PLANE HAS PADDING: bytesPerRow=$yRowStride > width=$width',
        );
      }
      _yuv420LoggedOnce = true;
    }

    final nv21 = Uint8List(width * height + (width * height ~/ 2));

    // Handle Y plane padding
    if (yRowStride > width) {
      int nv21Offset = 0;
      for (int row = 0; row < height; row++) {
        final yPlaneOffset = row * yRowStride;
        nv21.setRange(nv21Offset, nv21Offset + width, yPlane, yPlaneOffset);
        nv21Offset += width;
      }
    } else {
      nv21.setRange(0, width * height, yPlane);
    }

    int offset = width * height;

    try {
      for (int row = 0; row < height ~/ 2; row++) {
        for (int col = 0; col < width ~/ 2; col++) {
          final idx = row * uvRowStride + col * uvPixelStride;

          if (idx < vPlane.length && idx < uPlane.length) {
            nv21[offset++] = vPlane[idx];
            nv21[offset++] = uPlane[idx];
          } else {
            nv21[offset++] = 128;
            nv21[offset++] = 128;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error in YUV conversion: $e');
      }
    }

    return nv21;
  }

  double calculateSymmetry(
    Point<int>? leftPosition,
    Point<int>? rightPosition,
  ) {
    if (leftPosition != null && rightPosition != null) {
      final double dx = (rightPosition.x - leftPosition.x).abs().toDouble();
      final double dy = (rightPosition.y - leftPosition.y).abs().toDouble();
      final distance = Offset(dx, dy).distance;

      return distance;
    }

    return 0.0;
  }
}
