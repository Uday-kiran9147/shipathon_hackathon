import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/simulation_result.dart';
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    fix.isApplied
                        ? Icons.check_circle_rounded
                        : Icons.auto_fix_high_rounded,
                    size: 15.sp,
                    color: fix.isApplied
                        ? AppColors.outlierJade
                        : AppColors.primary,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    fix.fixType,
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textInk,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.outlierJadeSubtle,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: AppColors.outlierJadeBorder),
                ),
                child: Text(
                  '+${fix.scoreLift.toStringAsFixed(1)} SCORE LIFT',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.outlierJade,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            fix.description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 10.h),

          // Before & After Diff Box
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Replacement line
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FIX: ',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.outlierJade,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        fix.replacementSnippet,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: fix.isApplied ? null : onApply,
              icon: Icon(
                fix.isApplied
                    ? Icons.done_all_rounded
                    : Icons.bolt_rounded,
                size: 16.sp,
              ),
              label: Text(
                fix.isApplied ? 'Prescription Applied' : 'Apply 1-Click Fix',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: fix.isApplied
                    ? AppColors.outlierJade
                    : AppColors.primary,
                disabledBackgroundColor: AppColors.outlierJade.withValues(alpha: 0.8),
                disabledForegroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
