// Example Reference: Adaptive Flowing Badge Row (Zero Overflows)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shipathon_hackathon/core/theme/app_colors.dart';
import 'package:shipathon_hackathon/widgets/common/responsive_badge.dart';

class AdaptiveBadgeRowExample extends StatelessWidget {
  final List<String> tags;
  final String convictionLabel;
  final bool isTopOutlier;

  const AdaptiveBadgeRowExample({
    super.key,
    required this.tags,
    required this.convictionLabel,
    this.isTopOutlier = false,
  });

  @override
  Widget build(BuildContext context) {
    // Using Wrap instead of Row ensures zero RenderFlex overflows
    return Wrap(
      spacing: 8.w,
      runSpacing: 6.h,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ResponsiveBadge(
          label: convictionLabel,
          backgroundColor: isTopOutlier
              ? AppColors.jadeGreen.withOpacity(0.12)
              : AppColors.primaryCobalt.withOpacity(0.08),
          textColor: isTopOutlier ? AppColors.jadeGreen : AppColors.primaryCobalt,
          icon: isTopOutlier ? Icons.verified_rounded : Icons.trending_up_rounded,
        ),
        ...tags.map((tag) => ResponsiveBadge(
              label: tag.toUpperCase(),
              backgroundColor: AppColors.cardBorder.withOpacity(0.5),
              textColor: AppColors.textSecondary,
            )),
      ],
    );
  }
}
