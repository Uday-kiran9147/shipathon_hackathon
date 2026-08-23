import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// ScreenUtil responsive typography with Plus Jakarta Sans & JetBrains Mono.
class AppTypography {
  // --- Editorial Sans Typography ---
  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
    fontSize: 30.sp,
    fontWeight: FontWeight.w800,
    color: AppColors.textInk,
    letterSpacing: -0.8,
    height: 1.2,
  );

  static TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
    fontSize: 24.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textInk,
    letterSpacing: -0.5,
    height: 1.25,
  );

  static TextStyle get headlineLarge => GoogleFonts.plusJakartaSans(
    fontSize: 20.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textInk,
    letterSpacing: -0.4,
    height: 1.3,
  );

  static TextStyle get headlineMedium => GoogleFonts.plusJakartaSans(
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.35,
  );

  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
    fontSize: 13.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  static TextStyle get labelLarge => GoogleFonts.plusJakartaSans(
    fontSize: 13.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
  );

  static TextStyle get labelMedium => GoogleFonts.plusJakartaSans(
    fontSize: 11.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.4,
  );

  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
    fontSize: 10.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );

  // --- Monospace Data & Score Typography ---
  static TextStyle get monoScoreLarge => GoogleFonts.jetBrainsMono(
    fontSize: 32.sp,
    fontWeight: FontWeight.w800,
    color: AppColors.textInk,
    letterSpacing: -1.0,
  );

  static TextStyle get monoScoreMedium => GoogleFonts.jetBrainsMono(
    fontSize: 22.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textInk,
    letterSpacing: -0.5,
  );

  static TextStyle get monoTimestamp => GoogleFonts.jetBrainsMono(
    fontSize: 11.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 0.2,
  );

  static TextStyle get monoMultiplier => GoogleFonts.jetBrainsMono(
    fontSize: 13.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.outlierJade,
    letterSpacing: 0.1,
  );
}
