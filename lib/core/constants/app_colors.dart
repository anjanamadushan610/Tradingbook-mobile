import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // === Primary Brand ===
  static const Color primary = Color(0xFF00647C);
  static const Color primaryDark = Color(0xFF065F6B);
  static const Color primaryLight = Color(0xFF1AA3B5);
  static const Color primarySurface = Color(0xFFE8F7F9);

  // === Background & Surface ===
  static const Color background = Color(0xFFF2F5F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8FAFB);
  static const Color cardBorder = Color(0xFFE5EAF0);

  // === Dark Mode ===
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkSurfaceVariant = Color(0xFF21262D);
  static const Color darkCardBorder = Color(0xFF30363D);

  // === Text ===
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color postTextLight = Color(0xFFD9D9D9);

  // === Profile ===
  static const Color profileFeedBackground = Color(0xFFF6FBFD);

  // === Dark Text ===
  static const Color darkTextPrimary = Color(0xFFE6EDF3);
  static const Color darkTextSecondary = Color(0xFF8B949E);
  static const Color darkTextTertiary = Color(0xFF6E7681);

  // === Trading Semantic Colors ===
  static const Color bullish = Color(0xFF16A34A);
  static const Color bullishLight = Color(0xFFDCFCE7);
  static const Color bearish = Color(0xFFDC2626);
  static const Color bearishLight = Color(0xFFFEE2E2);
  static const Color longBadge = Color(0xFF059669);
  static const Color shortBadge = Color(0xFFDC2626);

  // === Status ===
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF3B82F6);

  // === Dividers & Borders ===
  static const Color divider = Color(0xFFE5EAF0);
  static const Color darkDivider = Color(0xFF30363D);

  // === Notification Badge ===
  static const Color badge = Color(0xFFEF4444);

  // === Gradients ===
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00647C), Color(0xFF065F6B)],
  );

  static const LinearGradient coverGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xCC000000)],
  );
}
