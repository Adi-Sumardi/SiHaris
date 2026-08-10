import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Utility class for showing snackbars with consistent styling
class SnackbarUtils {
  SnackbarUtils._();

  /// Default duration for snackbars
  static const Duration _defaultDuration = Duration(seconds: 3);

  /// Show a success snackbar (green)
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_rounded,
      duration: duration ?? _defaultDuration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Show an error snackbar (red)
  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.danger,
      icon: Icons.error_rounded,
      duration: duration ?? _defaultDuration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Show a warning snackbar (orange)
  static void showWarning(
    BuildContext context,
    String message, {
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.warning,
      icon: Icons.warning_rounded,
      duration: duration ?? _defaultDuration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Show an info snackbar (blue)
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.info,
      icon: Icons.info_rounded,
      duration: duration ?? _defaultDuration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Show a custom snackbar with specified color and icon
  static void showCustom(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    IconData? icon,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message: message,
      backgroundColor: backgroundColor,
      icon: icon,
      duration: duration ?? _defaultDuration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Hide the current snackbar
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Internal method to show snackbar
  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    IconData? icon,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Hide any existing snackbar first
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final snackBar = SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(16),
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction ?? () {},
            )
          : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
