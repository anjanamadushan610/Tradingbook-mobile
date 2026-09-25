import 'package:flutter/material.dart';

// AppColors import is intentionally removed — text styles must NOT bake in
// static colours. Colour comes from DefaultTextStyle / Theme.of(context).textTheme
// so that light ↔ dark switching works automatically.
// Use .copyWith(color: ...) at the call site for non-default colours.

class AppTextStyles {
  AppTextStyles._();

  // === Display / Hero ===
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  // === Headlines ===
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // === Title ===
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  // === Body ===
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // bodySmall is intentionally muted — use .copyWith(color: ...) to override
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  // === Label ===
  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // === Caption ===
  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  // === Monospace (for prices / numbers) ===
  static const TextStyle mono = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle monoLarge = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  // === Button ===
  // buttonPrimary colour is always white (on teal bg) — intentionally kept.
  static const TextStyle buttonPrimary = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: Colors.white,
  );

  // buttonSecondary colour is always brand teal — intentionally kept.
  static const TextStyle buttonSecondary = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
}

