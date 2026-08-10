import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/spacing.dart';

enum JagoBadgeType { success, warning, danger, info, neutral, primary }
enum JagoBadgeSize { small, medium, large }

class JagoBadge extends StatelessWidget {
  final String label;
  final JagoBadgeType type;
  final JagoBadgeSize size;
  final IconData? icon;
  final bool outlined;

  const JagoBadge({
    super.key,
    required this.label,
    this.type = JagoBadgeType.primary,
    this.size = JagoBadgeSize.medium,
    this.icon,
    this.outlined = false,
  });

  Color get _backgroundColor {
    if (outlined) return Colors.transparent;
    switch (type) {
      case JagoBadgeType.success:
        return AppColors.successLight;
      case JagoBadgeType.warning:
        return AppColors.warningLight;
      case JagoBadgeType.danger:
        return AppColors.dangerLight;
      case JagoBadgeType.info:
        return AppColors.infoLight;
      case JagoBadgeType.neutral:
        return AppColors.secondary100;
      case JagoBadgeType.primary:
        return AppColors.primary50;
    }
  }

  Color get _textColor {
    switch (type) {
      case JagoBadgeType.success:
        return AppColors.successDark;
      case JagoBadgeType.warning:
        return AppColors.warningDark;
      case JagoBadgeType.danger:
        return AppColors.dangerDark;
      case JagoBadgeType.info:
        return AppColors.infoDark;
      case JagoBadgeType.neutral:
        return AppColors.secondary600;
      case JagoBadgeType.primary:
        return AppColors.primary600;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case JagoBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
      case JagoBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case JagoBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    }
  }

  double get _fontSize {
    switch (size) {
      case JagoBadgeSize.small:
        return 10;
      case JagoBadgeSize.medium:
        return 12;
      case JagoBadgeSize.large:
        return 14;
    }
  }

  double get _iconSize {
    switch (size) {
      case JagoBadgeSize.small:
        return 12;
      case JagoBadgeSize.medium:
        return 14;
      case JagoBadgeSize.large:
        return 16;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
        border: outlined
            ? Border.all(color: _textColor, width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: _iconSize, color: _textColor),
            SizedBox(width: size == JagoBadgeSize.small ? 2 : 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: _fontSize,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status badge with dot indicator
class JagoStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool showDot;

  const JagoStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.showDot = true,
  });

  factory JagoStatusBadge.present() {
    return const JagoStatusBadge(
      label: 'Hadir',
      color: AppColors.statusPresent,
    );
  }

  factory JagoStatusBadge.absent() {
    return const JagoStatusBadge(
      label: 'Tidak Hadir',
      color: AppColors.statusAbsent,
    );
  }

  factory JagoStatusBadge.late() {
    return const JagoStatusBadge(
      label: 'Terlambat',
      color: AppColors.statusLate,
    );
  }

  factory JagoStatusBadge.leave() {
    return const JagoStatusBadge(
      label: 'Cuti',
      color: AppColors.statusLeave,
    );
  }

  factory JagoStatusBadge.pending() {
    return const JagoStatusBadge(
      label: 'Pending',
      color: AppColors.statusPending,
    );
  }

  factory JagoStatusBadge.approved() {
    return const JagoStatusBadge(
      label: 'Disetujui',
      color: AppColors.statusApproved,
    );
  }

  factory JagoStatusBadge.rejected() {
    return const JagoStatusBadge(
      label: 'Ditolak',
      color: AppColors.statusRejected,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Notification badge (dot or count)
class JagoNotificationBadge extends StatelessWidget {
  final int? count;
  final Color? color;

  const JagoNotificationBadge({
    super.key,
    this.count,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (count == null) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color ?? AppColors.danger,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surface, width: 1.5),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      constraints: const BoxConstraints(minWidth: 18),
      decoration: BoxDecoration(
        color: color ?? AppColors.danger,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count! > 99 ? '99+' : '$count',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textOnPrimary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
