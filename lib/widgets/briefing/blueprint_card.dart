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
import '../common/solid_heavy_button.dart';
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

    void openDetails() {
      BlueprintDetailsSheet.show(
        context,
        blueprint: blueprint,
        onSimulatePressed: onSimulatePressed,
      );
    }

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
                      text: blueprint.format == BlueprintFormat.longForm
                          ? 'Long Video'
                          : 'Short',
                      icon: blueprint.format == BlueprintFormat.longForm
                          ? Icons.videocam_rounded
                          : Icons.electric_bolt_rounded,
                      variant: BadgeVariant.primary,
                    ),
                    ResponsiveBadge(
                      text: '${blueprint.predictedMultiplier}× Projected Views',
                      icon: Icons.trending_up_rounded,
                      variant: BadgeVariant.outlier,
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.all(8.w),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () {
                  briefingProvider.toggleBookmark(blueprint.id);
                },
                icon: Icon(
                  blueprint.isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: blueprint.isBookmarked
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 24.sp,
                ),
              ),
            ],
          ),

          // Live Audience Demand & Comment Source Callout
          if (blueprint.demandCluster != null ||
              blueprint.audienceCommentSource != null) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.primaryBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 15.sp,
                              color: AppColors.youtubeRed,
                            ),
                            SizedBox(width: 6.w),
                            Flexible(
                              child: Text(
                                '🔥 HIGH AUDIENCE DEMAND',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textInk,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11.sp,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (blueprint.demandCluster != null) ...[
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              100.r,
                            ), // Capsule
                            border: Border.all(color: AppColors.primaryBorder),
                          ),
                          child: Text(
                            '👍 ${blueprint.demandCluster!.totalUpvotes} Upvotes',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5.sp,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  if (blueprint.audienceCommentSource != null) ...[
                    SizedBox(height: 8.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 10.r,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            blueprint
                                    .audienceCommentSource!
                                    .authorDisplayName
                                    .isNotEmpty
                                ? blueprint
                                      .audienceCommentSource!
                                      .authorDisplayName[0]
                                      .toUpperCase()
                                : 'V',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                blueprint
                                    .audienceCommentSource!
                                    .authorDisplayName,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.sp,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                '"${blueprint.audienceCommentSource!.text}"',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textInk,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12.sp,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
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
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 15.sp,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              'FIRST 5 SECONDS HOOK',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 11.sp,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8.r),
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: blueprint.hookText),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Hook copied to clipboard!',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white,
                              ),
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
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              size: 14.sp,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Copy',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  blueprint.hookText,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13.5.sp,
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
            padding: EdgeInsets.all(12.w),
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
                  size: 16.sp,
                  color: AppColors.outlierJade,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    blueprint.dataProofReason,
                    style: AppTypography.bodySmall.copyWith(
                      color: const Color(0xFF065F46),
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Action Button: Simulate in Pre-Flight
          SolidHeavyButton(
            label: 'Test Video Retention in Simulator',
            icon: Icons.speed_rounded,
            height: 52.h,
            onPressed: () {
              final simProvider = context.read<SimulatorProvider>();
              simProvider.loadBlueprint(blueprint);
              if (onSimulatePressed != null) {
                onSimulatePressed!();
              }
            },
          ),
        ],
      ),
    );

    if (isHero) {
      return GestureDetector(
        onTap: openDetails,
        child: ShimmerBorder(borderRadius: 18.r, child: cardContent),
      );
    }

    return TactileCard(
      padding: EdgeInsets.zero,
      onTap: openDetails,
      child: cardContent,
    );
  }
}
