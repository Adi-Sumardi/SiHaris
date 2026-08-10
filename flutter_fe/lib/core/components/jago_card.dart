import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/spacing.dart';
import '../constants/shadows.dart';

/// Base card widget with JagoGaji styling
class JagoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool hasShadow;
  final bool hasBorder;
  final double? borderRadius;

  const JagoCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.gradient,
    this.onTap,
    this.hasShadow = true,
    this.hasBorder = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? AppColors.card) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.cardRadius),
        border: hasBorder ? Border.all(color: AppColors.border, width: 1) : null,
        boxShadow: hasShadow ? AppShadows.cardShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.cardRadius),
          child: Padding(
            padding: padding ?? AppSpacing.cardPadding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Gradient card with primary colors
class JagoGradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const JagoGradientCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return JagoCard(
      padding: padding,
      margin: margin,
      gradient: gradient ?? AppColors.cardGradient,
      onTap: onTap,
      child: child,
    );
  }
}

/// Info card with icon, title, and value
class JagoInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const JagoInfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return JagoCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBackgroundColor ?? AppColors.primary50,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Icon(
              icon,
              color: iconColor ?? AppColors.primary600,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Quick action card with icon and label
class JagoQuickActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool showBadge;
  final int? badgeCount;

  const JagoQuickActionCard({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.showBadge = false,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return JagoCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: backgroundColor ?? AppColors.primary50,
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.primary600,
                  size: 24,
                ),
              ),
              if (showBadge)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: badgeCount != null
                        ? Text(
                            badgeCount! > 99 ? '99+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Status card for attendance/leave status
class JagoStatusCard extends StatelessWidget {
  final String title;
  final String status;
  final String? time;
  final String? subtitle;
  final Color statusColor;
  final IconData icon;
  final VoidCallback? onTap;

  const JagoStatusCard({
    super.key,
    required this.title,
    required this.status,
    this.time,
    this.subtitle,
    required this.statusColor,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return JagoCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Icon(
              icon,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                    if (time != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        time!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.secondary400,
            size: 24,
          ),
        ],
      ),
    );
  }
}
