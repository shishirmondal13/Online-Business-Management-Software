import 'package:flutter/material.dart';

/// App color constants following Excel-style minimal design
class AppColors {
  AppColors._();

  // Primary Colors - Vibrant Indigo / Violet
  static const Color primary = Color(0xFF6366F1); // Modern Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color accent = Color(0xFFF43F5E); // Rose Accent

  // Background Colors - Modern Tinted Neutrals
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textHint = Color(0xFF94A3B8); // Slate 400
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status Colors - Vibrant
  static const Color success = Color(0xFF22C55E); // Green 500
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF0EA5E9); // Sky 500
  static const Color infoLight = Color(0xFFE0F2FE);

  // Sector Colors
  static const Color mobileSector = Color(0xFF6366F1);
  static const Color gadgetSector = Color(0xFF8B5CF6);

  // Table & Borders
  static const Color tableHeader = Color(0xFFF8FAFC);
  static const Color tableRowEven = Color(0xFFFFFFFF);
  static const Color tableRowOdd = Color(0xFFF8FAFC);
  static const Color tableBorder = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);

  // Card & Shadow
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x1A000000);

  // Icon Colors
  static const Color iconPrimary = Color(0xFF475569);
  static const Color iconSecondary = Color(0xFF94A3B8);

  // Gradients for Vibrancy
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFFFB7185)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF4ADE80)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [warning, Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient infoGradient = LinearGradient(
    colors: [info, Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Status Aliases (Restore for compatibility)
  static const Color paid = success;
  static const Color partialPaid = warning;
  static const Color unpaid = error;
  static const Color inStock = success;
  static const Color lowStock = warning;
  static const Color outOfStock = error;
}
