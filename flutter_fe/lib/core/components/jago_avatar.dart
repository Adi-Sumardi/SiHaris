import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/spacing.dart';

enum JagoAvatarSize { xs, sm, md, lg, xl, xxl }

class JagoAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final JagoAvatarSize size;
  final bool hasBorder;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool isOnline;

  const JagoAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = JagoAvatarSize.md,
    this.hasBorder = false,
    this.borderColor,
    this.onTap,
    this.isOnline = false,
  });

  double get _size {
    switch (size) {
      case JagoAvatarSize.xs:
        return AppSpacing.avatarXs;
      case JagoAvatarSize.sm:
        return AppSpacing.avatarSm;
      case JagoAvatarSize.md:
        return AppSpacing.avatarMd;
      case JagoAvatarSize.lg:
        return AppSpacing.avatarLg;
      case JagoAvatarSize.xl:
        return AppSpacing.avatarXl;
      case JagoAvatarSize.xxl:
        return AppSpacing.avatarXxl;
    }
  }

  double get _fontSize {
    switch (size) {
      case JagoAvatarSize.xs:
        return 10;
      case JagoAvatarSize.sm:
        return 12;
      case JagoAvatarSize.md:
        return 14;
      case JagoAvatarSize.lg:
        return 20;
      case JagoAvatarSize.xl:
        return 28;
      case JagoAvatarSize.xxl:
        return 36;
    }
  }

  String get _initials {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary100,
              border: hasBorder
                  ? Border.all(
                      color: borderColor ?? AppColors.surface,
                      width: 2,
                    )
                  : null,
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null
                ? Center(
                    child: Text(
                      _initials,
                      style: TextStyle(
                        fontSize: _fontSize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary600,
                      ),
                    ),
                  )
                : null,
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: _size * 0.25,
                height: _size * 0.25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success,
                  border: Border.all(
                    color: AppColors.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Avatar group for showing multiple avatars stacked
class JagoAvatarGroup extends StatelessWidget {
  final List<String?> imageUrls;
  final List<String?> names;
  final int maxDisplay;
  final JagoAvatarSize size;
  final VoidCallback? onMoreTap;

  const JagoAvatarGroup({
    super.key,
    required this.imageUrls,
    required this.names,
    this.maxDisplay = 3,
    this.size = JagoAvatarSize.sm,
    this.onMoreTap,
  });

  double get _offset {
    switch (size) {
      case JagoAvatarSize.xs:
        return 16;
      case JagoAvatarSize.sm:
        return 22;
      case JagoAvatarSize.md:
        return 28;
      case JagoAvatarSize.lg:
        return 40;
      case JagoAvatarSize.xl:
        return 52;
      case JagoAvatarSize.xxl:
        return 68;
    }
  }

  double get _avatarSize {
    switch (size) {
      case JagoAvatarSize.xs:
        return AppSpacing.avatarXs;
      case JagoAvatarSize.sm:
        return AppSpacing.avatarSm;
      case JagoAvatarSize.md:
        return AppSpacing.avatarMd;
      case JagoAvatarSize.lg:
        return AppSpacing.avatarLg;
      case JagoAvatarSize.xl:
        return AppSpacing.avatarXl;
      case JagoAvatarSize.xxl:
        return AppSpacing.avatarXxl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayCount = imageUrls.length > maxDisplay ? maxDisplay : imageUrls.length;
    final remainingCount = imageUrls.length - maxDisplay;

    return SizedBox(
      height: _avatarSize,
      width: _offset * displayCount + (remainingCount > 0 ? _avatarSize : 0),
      child: Stack(
        children: [
          for (int i = 0; i < displayCount; i++)
            Positioned(
              left: i * _offset,
              child: JagoAvatar(
                imageUrl: imageUrls[i],
                name: names[i],
                size: size,
                hasBorder: true,
              ),
            ),
          if (remainingCount > 0)
            Positioned(
              left: displayCount * _offset,
              child: GestureDetector(
                onTap: onMoreTap,
                child: Container(
                  width: _avatarSize,
                  height: _avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary200,
                    border: Border.all(
                      color: AppColors.surface,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '+$remainingCount',
                      style: TextStyle(
                        fontSize: _avatarSize * 0.35,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
