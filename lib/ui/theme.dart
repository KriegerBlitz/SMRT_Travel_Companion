import 'package:flutter/material.dart';

/// Design tokens and styling exact to the design specifications.
class AppTheme {
  // Backgrounds
  static const Color bgDark = Color(0xFF121316);
  static const Color cardBg = Color(0xFF1F2127);
  static const Color cardBgSecondary = Color(0xFF18191E);
  static const Color cardBorder = Color(0xFF2D313A);

  // Accents
  static const Color purplePrimary = Color(0xFF7C3AED);
  static const Color purpleLight = Color(0xFF8B5CF6);
  static const Color purplePillBg = Color(0xFF2E244D);

  static const Color coralCTA = Color(0xFFFF6B4A);
  static const Color coralLight = Color(0xFFFB923C);

  static const Color amberWarning = Color(0xFFF59E0B);
  static const Color amberDark = Color(0xFF78350F);
  static const Color amberBannerBg = Color(0xFF2E1F0F);

  static const Color greenSuccess = Color(0xFF10B981);
  static const Color greenDark = Color(0xFF064E3B);
  static const Color greenBannerBg = Color(0xFF0D2818);

  static const Color redDisruption = Color(0xFFEF4444);
  static const Color redDark = Color(0xFF7F1D1D);

  // Text
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Card Decoration
  static BoxDecoration cardDecoration({
    Color? borderColor,
    Color? bgColor,
    double radius = 16,
  }) {
    return BoxDecoration(
      color: bgColor ?? cardBg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? cardBorder, width: 1.2),
    );
  }
}
