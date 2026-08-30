import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// ScreenUtil responsive typography with Roboto & JetBrains Mono.
class AppTypography {
  // --- Roboto Typography ---
  static TextStyle get displayLarge => GoogleFonts.roboto(
    fontSize: 30.sp,
    fontWeight: FontWeight.w800,
    color: AppColors.textInk,
    letterSpacing: -0.8,
    height: 1.2,
  );

  static TextStyle get displayMedium => GoogleFonts.roboto(
    fontSize: 24.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textInk,
    letterSpacing: -0.5,
    height: 1.25,
  );

  static TextStyle get headlineLarge => GoogleFonts.roboto(
    fontSize: 21.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textInk,
    letterSpacing: -0.4,
    height: 1.3,
  );

  static TextStyle get headlineMedium => GoogleFonts.roboto(
    fontSize: 19.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.35,
  );

  static TextStyle get titleLarge => GoogleFonts.roboto(
    fontSize: 17.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static TextStyle get titleMedium => GoogleFonts.roboto(
    fontSize: 15.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyLarge => GoogleFonts.roboto(
    fontSize: 15.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.roboto(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static TextStyle get bodySmall => GoogleFonts.roboto(
    fontSize: 13.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle get labelLarge => GoogleFonts.roboto(
    fontSize: 14.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
  );

  static TextStyle get labelMedium => GoogleFonts.roboto(
    fontSize: 12.5.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
  );

  static TextStyle get labelSmall => GoogleFonts.roboto(
    fontSize: 11.5.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
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
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );

  static TextStyle get monoMultiplier => GoogleFonts.jetBrainsMono(
    fontSize: 14.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.outlierJade,
    letterSpacing: 0.1,
  );
}
