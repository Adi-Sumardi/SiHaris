import 'dart:developer';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import '../../../core/config/device_camera_config.dart';
import '../../../core/ml/recognizer.dart';
import '../../../core/ml/recognition_embedding.dart';
import '../../../core/constants/colors.dart';

class CameraView extends StatefulWidget {
  const CameraView({
    super.key,
    required this.customPaint,
    required this.onImage,
    this.onCameraFeedReady,
    this.onDetectorViewModeChanged,
    this.onCameraLensDirectionChanged,
    this.initialCameraLensDirection = CameraLensDirection.back,
    required this.onTakePicture,
  });

  final CustomPaint? customPaint;
  final Function(InputImage inputImage) onImage;
  final VoidCallback? onCameraFeedReady;
  final VoidCallback? onDetectorViewModeChanged;
  final Function(CameraLensDirection direction)? onCameraLensDirectionChanged;
  final CameraLensDirection initialCameraLensDirection;
  final Function(CameraImage cameraImage) onTakePicture;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  static List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = -1;
  double _currentZoomLevel = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  bool _changingCameraLens = false;

  late List<RecognitionEmbedding> recognitions = [];
  CameraImage? frame;
  CameraLensDirection camDirec = CameraLensDirection.front;
  late Recognizer recognizer;

  int _inputImageLogCounter = 0;
  static const int _inputImageLogInterval = 30;

  DeviceCameraConfig? _deviceConfig;

  @override
  void initState() {
    super.initState();
    recognizer = Recognizer();
    _initialize();
  }

  void _initialize() async {
    if (kDebugMode) {
      log('');
      log('═══════════════════════════════════════════════════════');
      log('🎬 CAMERA INITIALIZATION (Face Register)');
      log('═══════════════════════════════════════════════════════');
      log('📱 Platform: ${Platform.operatingSystem}');
    }

    if (_cameras.isEmpty) {
      _cameras = await availableCameras();

      if (kDebugMode) {
        log('📷 Available cameras: ${_cameras.length}');
        for (var i = 0; i < _cameras.length; i++) {
          log('   Camera $i: ${_cameras[i].name}');
          log('      - Lens: ${_cameras[i].lensDirection}');
          log('      - Sensor orientation: ${_cameras[i].sensorOrientation}°');
        }
      }
    }

    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == widget.initialCameraLensDirection) {
        _cameraIndex = i;
        break;
      }
    }

    if (_cameraIndex != -1) {
      if (kDebugMode) {
        log('✅ Selected camera: ${_cameras[_cameraIndex].name}');
        log('   Lens direction: ${widget.initialCameraLensDirection}');
        log('   Starting live feed...');
      }

      _startLiveFeed();
    } else {
      if (kDebugMode) {
        log('❌ ERROR: No camera found with lens direction: ${widget.initialCameraLensDirection}');
        log('═══════════════════════════════════════════════════════');
      }
    }
  }

  @override
  void dispose() {
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _liveFeedBody());
  }

  Widget _liveFeedBody() {
    if (_cameras.isEmpty) return Container();
    if (_controller == null) return Container();
    if (_controller?.value.isInitialized == false) return Container();
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(
            child: _changingCameraLens
                ? const Center(child: Text('Mengganti kamera...'))
                : CameraPreview(_controller!, child: widget.customPaint),
          ),
          _backButton(),
          _titleBar(),
          _takePictureButton(),
        ],
      ),
    );
  }

  Widget _backButton() => Positioned(
    top: 40,
    left: 8,
    child: SizedBox(
      height: 50.0,
      width: 50.0,
      child: FloatingActionButton(
        heroTag: Object(),
        onPressed: () => Navigator.of(context).pop(),
        backgroundColor: Colors.black54,
        child: const Icon(Icons.arrow_back_ios_outlined, size: 20),
      ),
    ),
  );

  Widget _titleBar() => Positioned(
    top: 50,
    left: 0,
    right: 0,
    child: const Center(
      child: Text(
        'Daftarkan Wajah',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  Widget _takePictureButton() => Positioned(
    bottom: 40,
    left: 0,
    right: 0,
    child: Column(
      children: [
        const Text(
          'Posisikan wajah dalam frame',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            if (frame != null) {
              widget.onTakePicture(frame!);
            }
          },
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              border: Border.all(color: Colors.white54, width: 3),
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _applyManualCameraSettings() async {
    if (_controller == null) return;

    try {
      await _controller!.setFlashMode(FlashMode.off);
      log('✅ Flash mode set to OFF');
    } catch (e) {
      log('⚠️ Failed to set flash mode: $e');
    }

    try {
      await _controller!.setFocusMode(FocusMode.auto);
      log('✅ Focus mode set to AUTO');
    } catch (e) {
      log('⚠️ Failed to set focus mode: $e');
    }

    try {
      await _controller!.setExposureMode(ExposureMode.auto);
      log('✅ Exposure mode set to AUTO');
    } catch (e) {
      log('⚠️ Failed to set exposure mode: $e');
    }

    try {
      await _controller!.setZoomLevel(1.0);
      log('✅ Zoom level set to 1.0');
    } catch (e) {
      log('⚠️ Failed to set zoom level: $e');
    }
  }

  Future<void> _initializeDeviceConfig() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;

        _deviceConfig = DeviceCameraConfig.fromDeviceInfo(
          brand: androidInfo.brand,
          model: androidInfo.model,
          osVersion: androidInfo.version.release,
        );
      }
    } catch (e) {
      log('⚠️ Failed to initialize device config: $e');
      _deviceConfig = null;
    }
  }

  Future _startLiveFeed() async {
    final camera = _cameras[_cameraIndex];

    await _initializeDeviceConfig();

    final preferredFormat =
        _deviceConfig?.preferredImageFormat ??
        (Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888);

    final configsToTry = [
      (ResolutionPreset.medium, preferredFormat),
      (ResolutionPreset.medium, null),
      (ResolutionPreset.low, preferredFormat),
      (ResolutionPreset.low, null),
      (ResolutionPreset.high, preferredFormat),
      (ResolutionPreset.high, null),
    ];

    for (final config in configsToTry) {
      final preset = config.$1;
      final formatGroup = config.$2;

      try {
        if (_controller != null) {
          try {
            await _controller!.stopImageStream();
          } catch (_) {}
          try {
            await _controller!.dispose();
          } catch (_) {}
          _controller = null;
        }

        _controller = CameraController(
          camera,
          preset,
          enableAudio: false,
          imageFormatGroup: formatGroup,
        );

        await _controller!.initialize();

        if (!mounted) return;

        if (kDebugMode) {
          log('✅ Camera controller initialized!');
          log('   Preset: $preset, FormatGroup: $formatGroup');
          log('   Resolution: ${_controller?.value.previewSize}');
        }

        await _applyManualCameraSettings();

        _controller?.getMinZoomLevel().then((value) {
          _currentZoomLevel = value;
          _minAvailableZoom = value;
        });
        _controller?.getMaxZoomLevel().then((value) {
          _maxAvailableZoom = value;
        });

        await _controller?.startImageStream(_processCameraImage);

        if (widget.onCameraFeedReady != null) {
          widget.onCameraFeedReady!();
        }
        if (widget.onCameraLensDirectionChanged != null) {
          widget.onCameraLensDirectionChanged!(camera.lensDirection);
        }

        if (mounted) {
          setState(() {});
        }
        return; // Success!
      } catch (error) {
        if (kDebugMode) {
          log('⚠️ Failed camera init preset=$preset formatGroup=$formatGroup: $error');
        }
      }
    }
  }

  Future _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  void _processCameraImage(CameraImage image) {
    if (!mounted || _controller == null) {
      return;
    }

    frame = image;

    if (kDebugMode && Platform.isIOS && _inputImageLogCounter % 30 == 0) {
      log('');
      log('📷 Camera image received (#${_inputImageLogCounter + 1})');
      log('   Size: ${image.width}x${image.height}');
      log('   Format: ${image.format.group.name}');
      log('   Planes: ${image.planes.length}');
    }

    final inputImage = _inputImageFromCameraImage(image);

    if (inputImage == null) {
      if (kDebugMode) {
        log('❌ FAILED to create InputImage from camera image!');
      }
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

    final bool shouldLog = (_inputImageLogCounter % _inputImageLogInterval == 0);
    _inputImageLogCounter++;

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
      final orientationValue = _orientations[deviceOrientation];

      var rotationCompensation = orientationValue ?? 0;

      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }

      if (shouldLog) {
        log('🔍 [InputImage #$_inputImageLogCounter] Rotation compensation: $rotationCompensation degrees');
      }

      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) {
      log('❌ [InputImage #$_inputImageLogCounter] CRITICAL: Cannot create InputImageRotation!');
      return null;
    }

    // iOS BGRA8888 handling
    if (Platform.isIOS) {
      final format = InputImageFormatValue.fromRawValue(image.format.raw);

      if (format == null) {
        log('❌ iOS: Unknown format raw value: ${image.format.raw}');
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

    // Android NV21 handling
    if (shouldLog) {
      log('✅ [InputImage #$_inputImageLogCounter] Rotation: ${rotation.toString()}');
      log('🔍 [InputImage #$_inputImageLogCounter] Planes count: ${image.planes.length}');
    }

    // Check if image has correct number of planes for YUV420/NV21
    if (image.planes.length < 3) {
      // Some devices (e.g. Redmi A2) provide NV21 directly with 1 plane
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
        log('⚠️ [InputImage #$_inputImageLogCounter] Unexpected number of planes: ${image.planes.length}');
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

  Uint8List _yuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final yPlane = image.planes[0].bytes;
    final uPlane = image.planes[1].bytes;
    final vPlane = image.planes[2].bytes;

    final yRowStride = image.planes[0].bytesPerRow;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel!;

    final nv21 = Uint8List(width * height + (width * height ~/ 2));

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
    return nv21;
  }
}
