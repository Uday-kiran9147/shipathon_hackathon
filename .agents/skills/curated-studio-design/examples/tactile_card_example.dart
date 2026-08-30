// Example Reference: Curated Studio Tactile Card Component
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shipathon_hackathon/core/theme/app_colors.dart';
import 'package:shipathon_hackathon/core/theme/app_typography.dart';
import 'package:shipathon_hackathon/widgets/common/responsive_badge.dart';
import 'package:shipathon_hackathon/widgets/common/tactile_card.dart';

class ExampleBlueprintCard extends StatelessWidget {
  final String title;
  final String category;
  final double convictionScore;
  final VoidCallback onTap;

  const ExampleBlueprintCard({
    super.key,
    required this.title,
    required this.category,
    required this.convictionScore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTopOutlier = convictionScore >= 9.0;

    return TactileCard(
      onTap: onTap,
      padding: EdgeInsets.all(16.r),
      borderRadius: BorderRadius.circular(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ResponsiveBadge(
                label: category.toUpperCase(),
                backgroundColor: AppColors.electricCobalt.withOpacity(0.08),
                textColor: AppColors.electricCobalt,
              ),
              ResponsiveBadge(
                label: '${convictionScore.toStringAsFixed(1)} CONVICTION',
                backgroundColor: isTopOutlier
                    ? AppColors.jadeGreen.withOpacity(0.12)
                    : AppColors.primaryCobalt.withOpacity(0.08),
                textColor: isTopOutlier ? AppColors.jadeGreen : AppColors.primaryCobalt,
                icon: isTopOutlier ? Icons.verified_rounded : Icons.trending_up_rounded,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.touch_app_rounded, size: 14.sp, color: AppColors.textSecondary),
              SizedBox(width: 4.w),
              Text(
                'Tap to inspect runbook',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
