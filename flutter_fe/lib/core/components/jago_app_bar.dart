import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../constants/spacing.dart';
import 'jago_avatar.dart';

/// Custom AppBar for JagoGaji
class JagoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool showBackButton;
  final bool centerTitle;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final bool isTransparent;
  final double elevation;

  const JagoAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.showBackButton = true,
    this.centerTitle = false,
    this.actions,
    this.onBackPressed,
    this.backgroundColor,
    this.isTransparent = false,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: elevation,
      scrolledUnderElevation: 1,
      backgroundColor: isTransparent
          ? Colors.transparent
          : (backgroundColor ?? AppColors.surface),
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: isTransparent
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isTransparent ? Colors.white : AppColors.textPrimary,
                size: 20,
              ),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : null,
      automaticallyImplyLeading: showBackButton,
      centerTitle: centerTitle,
      title: titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isTransparent ? Colors.white : AppColors.textPrimary,
                  ),
                )
              : null),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.appBarHeight);
}

/// Home screen app bar with greeting and user info
class JagoHomeAppBar extends StatelessWidget {
  final String userName;
  final String? greeting;
  final String? imageUrl;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;
  final int notificationCount;

  const JagoHomeAppBar({
    super.key,
    required this.userName,
    this.greeting,
    this.imageUrl,
    this.onProfileTap,
    this.onNotificationTap,
    this.notificationCount = 0,
  });

  String get _greeting {
    if (greeting != null) return greeting!;
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onProfileTap,
              child: JagoAvatar(
                imageUrl: imageUrl,
                name: userName,
                size: JagoAvatarSize.md,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _greeting,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    userName,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Stack(
              children: [
                IconButton(
                  onPressed: onNotificationTap,
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textPrimary,
                    size: 26,
                  ),
                ),
                if (notificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        notificationCount > 9 ? '9+' : '$notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Section header with optional action
class JagoSectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;
  final EdgeInsets? padding;

  const JagoSectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          if (actionText != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionText!,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
