import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (HR/Payroll theme - Blue)
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark = Color(0xFF0D47A1);

  // Primary Scale (untuk kompatibilitas dengan theme lama)
  static const Color primary50 = Color(0xFFE3F2FD);
  static const Color primary100 = Color(0xFFBBDEFB);
  static const Color primary200 = Color(0xFF90CAF9);
  static const Color primary300 = Color(0xFF64B5F6);
  static const Color primary400 = Color(0xFF42A5F5);
  static const Color primary500 = Color(0xFF2196F3);
  static const Color primary600 = Color(0xFF1565C0);
  static const Color primary700 = Color(0xFF0D47A1);
  static const Color primary800 = Color(0xFF0A3D91);
  static const Color primary900 = Color(0xFF072F70);

  // Secondary Colors
  static const Color secondary = Color(0xFF1E88E5);
  static const Color secondary50 = Color(0xFFF5F5F5);
  static const Color secondary100 = Color(0xFFEEEEEE);
  static const Color secondary200 = Color(0xFFE0E0E0);
  static const Color secondary300 = Color(0xFFBDBDBD);
  static const Color secondary400 = Color(0xFF9E9E9E);
  static const Color secondary500 = Color(0xFF757575);
  static const Color secondary600 = Color(0xFF616161);
  static const Color secondary700 = Color(0xFF424242);
  static const Color secondary800 = Color(0xFF303030);
  static const Color secondary900 = Color(0xFF212121);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  static const Color danger = Color(0xFFF44336);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color greyDark = Color(0xFF616161);
  static const Color background = Color(0xFFF5F5F5);
  static const Color scaffoldBackground = Color(0xFFF5F5F5);

  // Accent colors
  static const Color accent50 = Color(0xFFFFF3E0);
  static const Color accent100 = Color(0xFFFFE0B2);
  static const Color accent200 = Color(0xFFFFCC80);
  static const Color accent300 = Color(0xFFFFB74D);
  static const Color accent400 = Color(0xFFFFA726);
  static const Color accent500 = Color(0xFFFF9800);
  static const Color accent600 = Color(0xFFFB8C00);
  static const Color accent700 = Color(0xFFF57C00);

  // Card & Surface
  static const Color card = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFAFAFA);
  static const Color divider = Color(0xFFE0E0E0);

  // Border
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF0F0F0);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Special (HR/Payroll)
  static const Color attendance = Color(0xFF4CAF50);
  static const Color leave = Color(0xFFFF9800);
  static const Color payslip = Color(0xFF2196F3);
  static const Color overtime = Color(0xFF9C27B0);
  static const Color loan = Color(0xFFE91E63);
  static const Color reimbursement = Color(0xFF009688);

  // Light variants
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color dangerLight = Color(0xFFFFEBEE);
  static const Color infoLight = Color(0xFFE3F2FD);

  // Dark variants
  static const Color successDark = Color(0xFF2E7D32);
  static const Color warningDark = Color(0xFFF57C00);
  static const Color dangerDark = Color(0xFFC62828);
  static const Color infoDark = Color(0xFF1565C0);

  // Status colors
  static const Color statusPresent = Color(0xFF4CAF50);
  static const Color statusAbsent = Color(0xFFF44336);
  static const Color statusLate = Color(0xFFFF9800);
  static const Color statusLeave = Color(0xFF2196F3);
  static const Color statusPending = Color(0xFFFF9800);
  static const Color statusApproved = Color(0xFF4CAF50);
  static const Color statusRejected = Color(0xFFF44336);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary600, primary700],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary500, primary700],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary500, primary600],
  );

  /// Standard gradient for a screen's blue top header (used with
  /// [JagoHeaderBand] for the rounded-top transition into the grey body).
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary700, primary600],
  );
}
