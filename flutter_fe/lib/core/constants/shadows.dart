import 'package:flutter/material.dart';
import 'colors.dart';

class AppShadows {
  // Card shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> cardShadowMd = [
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> cardShadowLg = [
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.1),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // Button shadows
  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: AppColors.primary600.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Bottom nav shadow
  static List<BoxShadow> bottomNavShadow = [
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, -2),
    ),
  ];

  // Modal shadow
  static List<BoxShadow> modalShadow = [
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.15),
      blurRadius: 32,
      offset: const Offset(0, 16),
    ),
  ];

  // Floating action button shadow
  static List<BoxShadow> fabShadow = [
    BoxShadow(
      color: AppColors.primary600.withValues(alpha: 0.4),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // Soft shadow
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}
