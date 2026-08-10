import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';

class ClockButton extends StatefulWidget {
  final bool hasClockedIn;
  final bool hasClockedOut;
  final VoidCallback? onClockIn;
  final VoidCallback? onClockOut;

  const ClockButton({
    super.key,
    this.hasClockedIn = false,
    this.hasClockedOut = false,
    this.onClockIn,
    this.onClockOut,
  });

  @override
  State<ClockButton> createState() => _ClockButtonState();
}

class _ClockButtonState extends State<ClockButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canClockIn => !widget.hasClockedIn;
  bool get _canClockOut => widget.hasClockedIn && !widget.hasClockedOut;
  bool get _isCompleted => widget.hasClockedIn && widget.hasClockedOut;

  String get _buttonText {
    if (_canClockIn) return 'Clock In';
    if (_canClockOut) return 'Clock Out';
    return 'Selesai';
  }

  IconData get _buttonIcon {
    if (_canClockIn) return Icons.fingerprint_rounded;
    if (_canClockOut) return Icons.logout_rounded;
    return Icons.check_circle_rounded;
  }

  Color get _buttonColor {
    if (_isCompleted) return AppColors.success;
    if (_canClockOut) return AppColors.accent500;
    return AppColors.textOnPrimary;
  }

  Color get _iconColor {
    if (_isCompleted) return AppColors.textOnDark;
    if (_canClockOut) return AppColors.textOnDark;
    return AppColors.primary600;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _isCompleted ? null : (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: _isCompleted ? null : (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        _handleTap();
      },
      onTapCancel: _isCompleted ? null : () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _buttonColor,
            boxShadow: _isCompleted
                ? []
                : [
                    BoxShadow(
                      color: (_canClockOut ? AppColors.accent500 : AppColors.textOnPrimary)
                          .withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _buttonIcon,
                color: _iconColor,
                size: 32,
              ),
              const SizedBox(height: 2),
              Text(
                _buttonText,
                style: AppTextStyles.labelMedium.copyWith(
                  color: _iconColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap() {
    if (_canClockIn) {
      widget.onClockIn?.call();
    } else if (_canClockOut) {
      widget.onClockOut?.call();
    }
  }
}

/// Animated pulse effect around the clock button
class ClockButtonPulse extends StatefulWidget {
  final Widget child;
  final bool isActive;

  const ClockButtonPulse({
    super.key,
    required this.child,
    this.isActive = true,
  });

  @override
  State<ClockButtonPulse> createState() => _ClockButtonPulseState();
}

class _ClockButtonPulseState extends State<ClockButtonPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _animation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ClockButtonPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (widget.isActive)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                width: 100 * _animation.value,
                height: 100 * _animation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textOnPrimary
                      .withValues(alpha: (1 - (_animation.value - 1) / 0.3) * 0.2),
                ),
              );
            },
          ),
        widget.child,
      ],
    );
  }
}
