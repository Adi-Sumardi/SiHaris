import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Translates X coordinate from image space to canvas space,
/// handling mirroring for front camera.
double translateX(
  double x,
  Size canvasSize,
  Size imageSize,
  InputImageRotation rotation,
  CameraLensDirection direction,
) {
  switch (rotation) {
    case InputImageRotation.rotation90deg:
      return x * canvasSize.width / imageSize.height;
    case InputImageRotation.rotation270deg:
      return canvasSize.width - x * canvasSize.width / imageSize.height;
    case InputImageRotation.rotation0deg:
    case InputImageRotation.rotation180deg:
      switch (direction) {
        case CameraLensDirection.back:
          return x * canvasSize.width / imageSize.width;
        default:
          return canvasSize.width - x * canvasSize.width / imageSize.width;
      }
  }
}

/// Translates Y coordinate from image space to canvas space.
double translateY(
  double y,
  Size canvasSize,
  Size imageSize,
  InputImageRotation rotation,
  CameraLensDirection direction,
) {
  switch (rotation) {
    case InputImageRotation.rotation90deg:
    case InputImageRotation.rotation270deg:
      return y * canvasSize.height / imageSize.width;
    case InputImageRotation.rotation0deg:
    case InputImageRotation.rotation180deg:
      return y * canvasSize.height / imageSize.height;
  }
}

/// CustomPainter that draws face bounding boxes and landmarks
/// on top of the camera preview.
class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter({
    required this.faces,
    required this.imageSize,
    required this.rotation,
    required this.cameraLensDirection,
  });

  final List<Face> faces;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = faces.isEmpty ? Colors.white54 : Colors.greenAccent;

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0
      ..color = Colors.greenAccent;

    for (final face in faces) {
      final left = translateX(
        face.boundingBox.left,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final top = translateY(
        face.boundingBox.top,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final right = translateX(
        face.boundingBox.right,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final bottom = translateY(
        face.boundingBox.bottom,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );

      canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), boxPaint);

      // Draw key landmarks
      for (final type in FaceLandmarkType.values) {
        final landmark = face.landmarks[type];
        if (landmark?.position != null) {
          canvas.drawCircle(
            Offset(
              translateX(
                landmark!.position.x.toDouble(),
                size,
                imageSize,
                rotation,
                cameraLensDirection,
              ),
              translateY(
                landmark.position.y.toDouble(),
                size,
                imageSize,
                rotation,
                cameraLensDirection,
              ),
            ),
            2,
            dotPaint,
          );
        }
      }

      // Draw face contours
      for (final type in FaceContourType.values) {
        final contour = face.contours[type];
        if (contour?.points != null) {
          for (final Point point in contour!.points) {
            canvas.drawCircle(
              Offset(
                translateX(
                  point.x.toDouble(),
                  size,
                  imageSize,
                  rotation,
                  cameraLensDirection,
                ),
                translateY(
                  point.y.toDouble(),
                  size,
                  imageSize,
                  rotation,
                  cameraLensDirection,
                ),
              ),
              1,
              boxPaint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize || oldDelegate.faces != faces;
  }
}

/// Oval guide overlay that shows the user where to position their face.
/// Color changes from white (no face) to green (face detected).
/// Uses ClipPath to create a true transparent cutout.
class FaceGuideOverlay extends StatelessWidget {
  const FaceGuideOverlay({
    super.key,
    required this.faceDetected,
    this.instruction,
  });

  final bool faceDetected;
  final String? instruction;

  @override
  Widget build(BuildContext context) {
    final color = faceDetected ? Colors.greenAccent : Colors.white70;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Dark overlay with oval cutout using ClipPath
        ClipPath(
          clipper: _OvalHoleClipper(),
          child: Container(color: Colors.black.withValues(alpha: 0.5)),
        ),
        // Oval border only
        CustomPaint(
          painter: _OvalBorderPainter(borderColor: color),
          child: const SizedBox.expand(),
        ),
        // Instruction text at bottom of oval
        Positioned(
          bottom: 120,
          left: 16,
          right: 16,
          child: Text(
            instruction ?? 'Posisikan wajah dalam lingkaran',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
            ),
          ),
        ),
      ],
    );
  }
}

/// Clips out an oval hole from the center
class _OvalHoleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // Oval dimensions - more proportional for face shape
    // Width: 65% of screen width
    // Height: 40% of screen height (slightly taller than wide for face shape)
    final ovalWidth = size.width * 0.65;
    final ovalHeight = ovalWidth * 1.25; // 1.25 ratio for natural face oval

    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.40),
      width: ovalWidth,
      height: ovalHeight,
    );

    // Full rectangle path
    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Oval path to cut out
    final ovalPath = Path()..addOval(ovalRect);

    // Combine: outer - oval = donut shape
    return Path.combine(PathOperation.difference, outerPath, ovalPath);
  }

  @override
  bool shouldReclip(_OvalHoleClipper oldClipper) => false;
}

/// Draws only the oval border
class _OvalBorderPainter extends CustomPainter {
  const _OvalBorderPainter({required this.borderColor});
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Same dimensions as clipper
    final ovalWidth = size.width * 0.65;
    final ovalHeight = ovalWidth * 1.25;

    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.40),
      width: ovalWidth,
      height: ovalHeight,
    );

    // Oval border only
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawOval(ovalRect, borderPaint);
  }

  @override
  bool shouldRepaint(_OvalBorderPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor;
}
