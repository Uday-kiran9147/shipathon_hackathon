import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/daily_blueprint.dart';
import '../../providers/briefing_provider.dart';
import '../../providers/simulator_provider.dart';
import '../common/responsive_badge.dart';
import '../common/shimmer_border.dart';
import '../common/tactile_card.dart';
import 'blueprint_details_sheet.dart';
import 'thumbnail_concept_box.dart';

/// Full Prescription Blueprint Card Widget
class BlueprintCard extends StatelessWidget {
  final DailyBlueprint blueprint;
  final bool isHero;
  final VoidCallback? onSimulatePressed;

  const BlueprintCard({
    super.key,
    required this.blueprint,
    this.isHero = false,
    this.onSimulatePressed,
  });

  @override
  Widget build(BuildContext context) {
    final briefingProvider = context.read<BriefingProvider>();

    final cardContent = Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Badges (Wrapped) & Bookmark Action
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6.w,
                  runSpacing: 4.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ResponsiveBadge(
                      text: blueprint.formatLabel,
                      icon: blueprint.format == BlueprintFormat.longForm
                          ? Icons.videocam_rounded
                          : Icons.electric_bolt_rounded,
                      variant: BadgeVariant.primary,
                    ),
                    ResponsiveBadge(
                      text: '${blueprint.predictedMultiplier}× OUTLIER',
                      icon: Icons.trending_up_rounded,
                      variant: BadgeVariant.outlier,
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  briefingProvider.toggleBookmark(blueprint.id);
                },
                icon: Icon(
                  blueprint.isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: blueprint.isBookmarked
                      ? AppColors.primary
                      : AppColors.textMuted,
                  size: 20.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Title
          Text(
            blueprint.title,
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 12.h),

          // Pre-Engineered Hook Box
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.borderLight, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 13.sp, color: AppColors.primary),
                        SizedBox(width: 4.w),
                        Text(
                          '5-SEC HOOK',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: blueprint.hookText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Hook copied to clipboard!',
                              style: AppTypography.bodySmall.copyWith(color: Colors.white),
                            ),
                            backgroundColor: AppColors.textInk,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy_rounded,
                              size: 12.sp, color: AppColors.textMuted),
                          SizedBox(width: 4.w),
                          Text(
                            'Copy',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  blueprint.hookText,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          // Thumbnail Concept Split-Box
          ThumbnailConceptBox(
            conceptLeft: blueprint.thumbnailConceptLeft,
            conceptRight: blueprint.thumbnailConceptRight,
            tag: blueprint.thumbnailTag,
          ),
          SizedBox(height: 12.h),

          // Data-Backed "Why" Proof
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.outlierJadeSubtle,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.outlierJadeBorder, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.insights_rounded,
                  size: 15.sp,
                  color: AppColors.outlierJade,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    blueprint.dataProofReason,
                    style: AppTypography.bodySmall.copyWith(
                      color: const Color(0xFF065F46),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),

          // Action Button: Simulate in Pre-Flight
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final simProvider = context.read<SimulatorProvider>();
                simProvider.loadBlueprint(blueprint);
                if (onSimulatePressed != null) {
                  onSimulatePressed!();
                }
              },
              icon: Icon(Icons.speed_rounded, size: 18.sp),
              label: Text(
                'Run in Pre-Flight Simulator',
                style: AppTypography.labelLarge.copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 13.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    void openDetails() {
      BlueprintDetailsSheet.show(
        context,
        blueprint: blueprint,
        onSimulatePressed: onSimulatePressed,
      );
    }

    if (isHero) {
      return GestureDetector(
        onTap: openDetails,
        child: ShimmerBorder(
          borderRadius: 18.r,
          child: cardContent,
        ),
      );
    }

    return TactileCard(
      padding: EdgeInsets.zero,
      onTap: openDetails,
      child: cardContent,
    );
  }
}
