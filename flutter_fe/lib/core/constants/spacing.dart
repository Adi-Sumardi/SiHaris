import 'package:flutter/material.dart';

class AppSpacing {
  // Base spacing units (8-point grid)
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Padding presets
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets paddingHorizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHorizontalXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets paddingVerticalXl = EdgeInsets.symmetric(vertical: xl);

  // Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.all(lg);
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(horizontal: lg);

  // Border radius
  static BorderRadius borderRadiusXs = BorderRadius.circular(4);
  static BorderRadius borderRadiusSm = BorderRadius.circular(8);
  static BorderRadius borderRadiusMd = BorderRadius.circular(12);
  static BorderRadius borderRadiusLg = BorderRadius.circular(16);
  static BorderRadius borderRadiusXl = BorderRadius.circular(24);
  static BorderRadius borderRadiusFull = BorderRadius.circular(999);

  // Special border radius
  static BorderRadius borderRadiusCard = BorderRadius.circular(12);
  static BorderRadius borderRadiusButton = BorderRadius.circular(8);
  static BorderRadius borderRadiusInput = BorderRadius.circular(8);
  static BorderRadius borderRadiusChip = BorderRadius.circular(20);

  // Button heights
  static const double buttonHeightSm = 36;
  static const double buttonHeightMd = 44;
  static const double buttonHeightLg = 52;

  // Input heights
  static const double inputHeight = 48;
  static const double inputHeightSm = 40;
  static const double inputHeightLg = 56;

  // Icon sizes
  static const double iconXs = 16;
  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 48;

  // Avatar sizes
  static const double avatarXs = 24;
  static const double avatarSm = 32;
  static const double avatarMd = 40;
  static const double avatarLg = 56;
  static const double avatarXl = 80;

  // Bottom nav height
  static const double bottomNavHeight = 64;

  // App bar height
  static const double appBarHeight = 56;

  // Card specific
  static const double cardRadius = 12;
  static const EdgeInsets cardPadding = EdgeInsets.all(16);

  // Badge specific
  static const double badgeRadius = 20;

  // Avatar XXL
  static const double avatarXxl = 96;
}
