import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../constants/spacing.dart';

/// Custom list tile for JagoGaji
class JagoListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool showChevron;
  final EdgeInsets? padding;

  const JagoListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showDivider = false,
    this.showChevron = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
                if (showChevron && trailing == null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.secondary400,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: AppSpacing.lg,
            endIndent: AppSpacing.lg,
          ),
      ],
    );
  }
}

/// Menu item for settings/profile screens
class JagoMenuItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showDivider;
  final bool isDanger;

  const JagoMenuItem({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.onTap,
    this.trailing,
    this.showDivider = true,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = isDanger
        ? AppColors.danger
        : (iconColor ?? AppColors.primary600);
    final effectiveIconBgColor = isDanger
        ? AppColors.dangerLight
        : (iconBackgroundColor ?? AppColors.primary50);

    return JagoListTile(
      title: title,
      subtitle: subtitle,
      showDivider: showDivider,
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: effectiveIconBgColor,
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Icon(
          icon,
          color: effectiveIconColor,
          size: 20,
        ),
      ),
      trailing: trailing,
    );
  }
}

/// Attendance/Leave history item
class JagoHistoryItem extends StatelessWidget {
  final String title;
  final String date;
  final String? time;
  final String status;
  final Color statusColor;
  final String? description;
  final VoidCallback? onTap;

  const JagoHistoryItem({
    super.key,
    required this.title,
    required this.date,
    this.time,
    required this.status,
    required this.statusColor,
    this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    date.split(' ')[0],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                  Text(
                    date.split(' ').length > 1 ? date.split(' ')[1] : '',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: AppSpacing.borderRadiusSm,
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (time != null) ...[
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                      if (description != null) ...[
                        if (time != null) const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            description!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.secondary400,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

/// Payslip/Amount item with breakdown
class JagoAmountItem extends StatelessWidget {
  final String label;
  final String amount;
  final bool isAddition;
  final bool isTotal;
  final IconData? icon;

  const JagoAmountItem({
    super.key,
    required this.label,
    required this.amount,
    this.isAddition = true,
    this.isTotal = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: isTotal
                  ? AppColors.primary600
                  : AppColors.textTertiary,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 15 : 14,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
                color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            isTotal ? amount : (isAddition ? '+$amount' : '-$amount'),
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal
                  ? AppColors.primary600
                  : (isAddition ? AppColors.success : AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
