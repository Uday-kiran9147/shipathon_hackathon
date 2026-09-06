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
          // Header: High Impact + Fix Type + Score Lift Badge
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 8.w,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.hazardRubySubtle,
                        borderRadius: BorderRadius.circular(4.r),
                        border: Border.all(color: AppColors.hazardRubyBorder),
                      ),
                      child: Text(
                        'HIGH IMPACT',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.hazardRuby,
                          fontWeight: FontWeight.w800,
                          fontSize: 9.5.sp,
                        ),
                      ),
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
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.outlierJadeSubtle,
                    borderRadius: BorderRadius.circular(100.r), // Capsule pill
                    border: Border.all(color: AppColors.outlierJadeBorder),
                  ),
                  child: Text(
                    '+${fix.scoreLift.toStringAsFixed(1)} HOOK LIFT',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.outlierJade,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            fix.problem,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 10.h),

          // BEFORE & AFTER Side-by-Side / Diff Block
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BEFORE: ',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.hazardRuby,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.sp,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '"${fix.originalSnippet}"',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AFTER:   ',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.outlierJade,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.sp,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '"${fix.replacementSnippet}"',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textInk,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),

          // Projected Score Lift Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Projected score after applying: ${fix.projectedScoreAfter.toStringAsFixed(1)}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.outlierJade,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.sp,
                ),
              ),
              if (fix.isApplied)
                Text(
                  'Applied ✓',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.outlierJade,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.sp,
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),

          // Action Button
          SolidHeavyButton(
            label: fix.isApplied
                ? 'Improvement Applied ✓'
                : 'Apply 1-Tap Improvement',
            icon: fix.isApplied ? Icons.done_all_rounded : Icons.bolt_rounded,
            height: 46.h,
            backgroundColor: fix.isApplied
                ? AppColors.outlierJade
                : AppColors.primary,
            shadowColor: fix.isApplied
                ? const Color(0xFF065F46)
                : const Color(0xFF990014),
            borderColor: fix.isApplied
                ? const Color(0xFF047857)
                : const Color(0xFFCC0018),
            onPressed: fix.isApplied ? null : onApply,
          ),
        ],
      ),
    );
  }
}
