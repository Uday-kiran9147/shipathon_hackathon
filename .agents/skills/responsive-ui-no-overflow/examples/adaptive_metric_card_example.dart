// Example Reference: Zero-Overflow Adaptive Metric Card
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shipathon_hackathon/core/theme/app_colors.dart';
import 'package:shipathon_hackathon/core/theme/app_typography.dart';
import 'package:shipathon_hackathon/widgets/common/tactile_card.dart';

class AdaptiveMetricCardExample extends StatelessWidget {
  final String title;
  final String metricValue;
  final String deltaText;
  final String longDescription;
  final VoidCallback? onTap;

  const AdaptiveMetricCardExample({
    super.key,
    required this.title,
    required this.metricValue,
    required this.deltaText,
    required this.longDescription,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TactileCard(
      onTap: onTap,
      padding: EdgeInsets.all(16.r),
      borderRadius: BorderRadius.circular(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with Expanded text: Never clips or throws RenderFlex error
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  softWrap: true, // Naturally wraps onto line 2 without ellipsis
                ),
              ),
              SizedBox(width: 8.w),
              // Delta pill using FittedBox instead of ellipsis
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.jadeGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    deltaText,
                    style: AppTypography.monoData.copyWith(
                      color: AppColors.jadeGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Metric Number wrapped in FittedBox for bulletproof scale-down
          SizedBox(
            height: 36.h,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                metricValue,
                style: AppTypography.displayLarge.copyWith(
                  color: AppColors.primaryCobalt,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          // Long description: Explicitly intentional 2-line ellipsis preview
          Text(
            longDescription,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            maxLines: 2, // Intentional for long body descriptions only
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
