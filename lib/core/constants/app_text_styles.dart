import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// AppColors import is intentionally removed — text styles must NOT bake in
// static colours. Colour comes from DefaultTextStyle / Theme.of(context).textTheme
// so that light ↔ dark switching works automatically.
// Use .copyWith(color: ...) at the call site for non-default colours.

class AppTextStyles {
  AppTextStyles._();

  // === Display / Hero ===
  static TextStyle displayLarge = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium = GoogleFonts.inter(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  // === Headlines ===
  static TextStyle headlineLarge = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static TextStyle headlineMedium = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static TextStyle headlineSmall = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // === Title ===
  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static TextStyle titleSmall = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  // === Body ===
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // bodySmall is intentionally muted — use .copyWith(color: ...) to override
  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  // === Label ===
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // === Caption ===
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  // === Monospace (for prices / numbers) ===
  static TextStyle mono = GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static TextStyle monoLarge = GoogleFonts.jetBrainsMono(
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  // === Button ===
  // buttonPrimary colour is always white (on teal bg) — intentionally kept.
  static TextStyle buttonPrimary = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: Colors.white,
  );

  // buttonSecondary colour is always brand teal — intentionally kept.
  static TextStyle buttonSecondary = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
}

