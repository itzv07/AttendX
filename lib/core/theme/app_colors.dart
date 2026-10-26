import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Background colors - Cinematic dark palette
  static const Color background = Color(0xFF0A0E1A);
  static const Color primary = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceLight = Color(0xFF232B3E);
  static const Color card = Color(0xFF1C2333);
  static const Color cardElevated = Color(0xFF232B3E);
  static const Color navBar = Color(0xFF0D1120);

  // Input fields
  static const Color inputFill = Color(0xFF141C2E);
  static const Color border = Color(0xFF2A3348);
  static const Color divider = Color(0xFF1E2A3E);

  // Accent colors
  static const Color accentBlue = Color(0xFF3563E9);
  static const Color glowBlue = Color(0xFF60A5FA);
  static const Color accentBlueLight = Color(0xFF4B7BFF);
  static const Color accentPurple = Color(0xFF7C3AED);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color info = Color(0xFF06B6D4);

  // Text colors
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textHint = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF4B5563);

  // Gradient colors
  static const List<Color> primaryGradient = [
    Color(0xFF1E3A5F),
    Color(0xFF0A0E1A),
  ];

  static const List<Color> accentGradient = [
    Color(0xFF3563E9),
    Color(0xFF1E3A5F),
  ];

  static const List<Color> successGradient = [
    Color(0xFF10B981),
    Color(0xFF059669),
  ];

  static const List<Color> warningGradient = [
    Color(0xFFF59E0B),
    Color(0xFFD97706),
  ];

  static const List<Color> errorGradient = [
    Color(0xFFEF4444),
    Color(0xFFDC2626),
  ];

  // Glow colors (for box shadows)
  static const Color glowBlueColor = Color(0x553563E9);
  static const Color glowGreenColor = Color(0x5510B981);
  static const Color glowRedColor = Color(0x55EF4444);
  static const Color glowAmberColor = Color(0x55F59E0B);

  // Chart colors
  static const List<Color> chartColors = [
    Color(0xFF3563E9),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF7C3AED),
    Color(0xFF06B6D4),
    Color(0xFFEF4444),
  ];
}
