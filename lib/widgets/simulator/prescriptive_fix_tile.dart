import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/simulation_result.dart';
import '../common/solid_heavy_button.dart';
import '../common/tactile_card.dart';

/// 1-Click Prescriptive Fix Action Tile
class PrescriptiveFixTile extends StatelessWidget {
  final PrescriptiveFix fix;
  final VoidCallback onApply;

  const PrescriptiveFixTile({
    super.key,
    required this.fix,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return TactileCard(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      border: Border.all(
        color: fix.isApplied
            ? AppColors.outlierJadeBorder
            : AppColors.borderLight,
        width: fix.isApplied ? 1.5 : 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Fix Type + Score Lift Badge
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      fix.isApplied
                          ? Icons.check_circle_rounded
                          : Icons.auto_fix_high_rounded,
                      size: 18.sp,
                      color: fix.isApplied
                          ? AppColors.outlierJade
                          : AppColors.primary,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      fix.fixType,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textInk,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.outlierJadeSubtle,
                    borderRadius: BorderRadius.circular(100.r), // Capsule pill
                    border: Border.all(color: AppColors.outlierJadeBorder),
                  ),
                  child: Text(
                    '+${fix.scoreLift.toStringAsFixed(1)} SCORE LIFT',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.outlierJade,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            fix.description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 10.h),

          // Before & After Diff Box
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FIX: ',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.outlierJade,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.sp,
                  ),
                ),
                Expanded(
                  child: Text(
                    fix.replacementSnippet,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),

          // Action Button
          SolidHeavyButton(
            label: fix.isApplied ? 'Improvement Applied ✓' : 'Apply 1-Tap Improvement',
            icon: fix.isApplied ? Icons.done_all_rounded : Icons.bolt_rounded,
            height: 48.h,
            backgroundColor: fix.isApplied ? AppColors.outlierJade : AppColors.primary,
            shadowColor: fix.isApplied ? const Color(0xFF065F46) : const Color(0xFF990014),
            borderColor: fix.isApplied ? const Color(0xFF047857) : const Color(0xFFCC0018),
            onPressed: fix.isApplied ? null : onApply,
          ),
        ],
      ),
    );
  }
}
