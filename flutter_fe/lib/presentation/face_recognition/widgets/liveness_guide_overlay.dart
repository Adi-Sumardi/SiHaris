import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/colors.dart';
import '../../../core/ml/active_liveness_detector.dart';

/// Overlay panduan interaktif Liveness Detection dengan animasi oval dan challenge HUD
class LivenessGuideOverlay extends StatefulWidget {
  final LivenessFrameResult result;
  final VoidCallback? onRetry;

  const LivenessGuideOverlay({
    super.key,
    required this.result,
    this.onRetry,
  });

  @override
  State<LivenessGuideOverlay> createState() => _LivenessGuideOverlayState();
}

class _LivenessGuideOverlayState extends State<LivenessGuideOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  LivenessStatus? _previousStatus;
  int? _previousStep;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant LivenessGuideOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Haptic feedback saat step selesai atau semua selesai
    if (widget.result.status == LivenessStatus.stepCompleted &&
        _previousStatus != LivenessStatus.stepCompleted) {
      HapticFeedback.mediumImpact();
    } else if (widget.result.status == LivenessStatus.allCompleted &&
        _previousStatus != LivenessStatus.allCompleted) {
      HapticFeedback.heavyImpact();
    }

    _previousStatus = widget.result.status;
    _previousStep = widget.result.currentStep;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getBorderColor() {
    switch (widget.result.status) {
      case LivenessStatus.allCompleted:
      case LivenessStatus.stepCompleted:
        return const Color(0xFF00E676); // Vibrant Green
      case LivenessStatus.challenging:
        return const Color(0xFF00B0FF); // Cyan Blue
      case LivenessStatus.faceInvalid:
        return const Color(0xFFFFAB00); // Amber Warning
      case LivenessStatus.failed:
        return AppColors.danger;
      case LivenessStatus.waitingForFace:
        return Colors.white70;
    }
  }

  IconData _getChallengeIcon(LivenessChallengeType? type) {
    if (type == null) return Icons.face_rounded;
    switch (type) {
      case LivenessChallengeType.blink:
        return Icons.remove_red_eye_rounded;
      case LivenessChallengeType.turnLeft:
        return Icons.turn_left_rounded;
      case LivenessChallengeType.turnRight:
        return Icons.turn_right_rounded;
      case LivenessChallengeType.smile:
        return Icons.sentiment_very_satisfied_rounded;
      case LivenessChallengeType.nod:
        return Icons.arrow_downward_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _getBorderColor();
    final challenge = widget.result.currentChallenge;
    final isDone = widget.result.status == LivenessStatus.allCompleted;
    final isStepDone = widget.result.status == LivenessStatus.stepCompleted;

    return Stack(
      children: [
        // 1. Dark background with oval cutout
        ClipPath(
          clipper: _OvalHoleClipper(),
          child: Container(
            color: Colors.black.withValues(alpha: 0.55),
          ),
        ),

        // 2. Oval Border & Animated Progress Arc
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return CustomPaint(
              painter: _LivenessOvalPainter(
                borderColor: borderColor,
                progress: widget.result.progress,
                pulseValue: _pulseController.value,
                isCompleted: isDone || isStepDone,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),

        // 3. Top Header: Step Indicator & Status Badge
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Step Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDone
                            ? Icons.verified_user_rounded
                            : Icons.security_rounded,
                        color: isDone ? const Color(0xFF00E676) : const Color(0xFF00B0FF),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isDone
                            ? 'Liveness Terverifikasi'
                            : 'Langkah ${widget.result.currentStep} dari ${widget.result.totalSteps}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Step progress dots
                Row(
                  children: List.generate(widget.result.totalSteps, (index) {
                    final isPassed = index < widget.result.currentStep - 1 ||
                        (index == widget.result.currentStep - 1 && (isStepDone || isDone));
                    final isCurrent = index == widget.result.currentStep - 1 && !isStepDone && !isDone;

                    return Container(
                      margin: const EdgeInsets.only(left: 6),
                      width: isCurrent ? 20 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isPassed
                            ? const Color(0xFF00E676)
                            : isCurrent
                                ? const Color(0xFF00B0FF)
                                : Colors.white24,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),

        // 4. Bottom HUD: Challenge Instruction & Animated Card
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: SafeArea(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: borderColor.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon + Instruction
                  Row(
                    children: [
                      // Challenge Icon with animated pulse
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: borderColor.withValues(alpha: 0.15),
                          border: Border.all(color: borderColor, width: 2),
                        ),
                        child: Center(
                          child: Icon(
                            isDone
                                ? Icons.check_circle_rounded
                                : _getChallengeIcon(challenge?.type),
                            color: borderColor,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Instruction Texts
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isDone
                                  ? 'Selesai!'
                                  : (challenge?.title ?? 'Posisikan Wajah'),
                              style: TextStyle(
                                color: borderColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.result.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Progress Bar for current challenge
                  if (!isDone && widget.result.status == LivenessStatus.challenging) ...[
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: widget.result.progress.clamp(0.0, 1.0),
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(borderColor),
                        minHeight: 5,
                      ),
                    ),
                  ],

                  // Retry button if failed
                  if (widget.result.status == LivenessStatus.failed && widget.onRetry != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Coba Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Oval cutout clipper
class _OvalHoleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final ovalWidth = size.width * 0.68;
    final ovalHeight = ovalWidth * 1.30;

    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.38),
      width: ovalWidth,
      height: ovalHeight,
    );

    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final ovalPath = Path()..addOval(ovalRect);

    return Path.combine(PathOperation.difference, outerPath, ovalPath);
  }

  @override
  bool shouldReclip(_OvalHoleClipper oldClipper) => false;
}

/// Custom painter for glowing oval border and progress arc
class _LivenessOvalPainter extends CustomPainter {
  final Color borderColor;
  final double progress;
  final double pulseValue;
  final bool isCompleted;

  const _LivenessOvalPainter({
    required this.borderColor,
    required this.progress,
    required this.pulseValue,
    required this.isCompleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final ovalWidth = size.width * 0.68;
    final ovalHeight = ovalWidth * 1.30;

    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.38),
      width: ovalWidth,
      height: ovalHeight,
    );

    // 1. Background oval border
    final baseBorderPaint = Paint()
      ..color = borderColor.withValues(alpha: isCompleted ? 0.9 : 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawOval(ovalRect, baseBorderPaint);

    // 2. Pulse glow effect when challenging or completed
    if (isCompleted || progress > 0.1) {
      final glowPaint = Paint()
        ..color = borderColor.withValues(alpha: 0.15 + (0.15 * pulseValue))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0 + (3.0 * pulseValue)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawOval(ovalRect, glowPaint);
    }

    // 3. Progress arc around the oval
    if (progress > 0.0 && !isCompleted) {
      final progressPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4.5;

      final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
      canvas.drawArc(ovalRect, -math.pi / 2, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(_LivenessOvalPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.progress != progress ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.isCompleted != isCompleted;
  }
}
