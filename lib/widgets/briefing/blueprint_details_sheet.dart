import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/daily_blueprint.dart';
import '../../providers/simulator_provider.dart';
import '../common/responsive_badge.dart';
import '../common/solid_heavy_button.dart';
import '../common/tactile_card.dart';
import 'thumbnail_concept_box.dart';

/// Comprehensive Production Brief & Runbook BottomSheet
class BlueprintDetailsSheet extends StatelessWidget {
  final DailyBlueprint blueprint;
  final VoidCallback? onSimulatePressed;

  const BlueprintDetailsSheet({
    super.key,
    required this.blueprint,
    this.onSimulatePressed,
  });

  static Future<void> show(
    BuildContext context, {
    required DailyBlueprint blueprint,
    VoidCallback? onSimulatePressed,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlueprintDetailsSheet(
        blueprint: blueprint,
        onSimulatePressed: onSimulatePressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 720.h,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle Bar
            Container(
              margin: EdgeInsets.only(top: 10.h, bottom: 8.h),
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            // Header Row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.video_library_rounded,
                          color: AppColors.primary, size: 18.sp),
                      SizedBox(width: 6.w),
                      Text(
                        'PRODUCTION RUNBOOK',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded,
                        size: 20.sp, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Divider(),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: [
                        ResponsiveBadge(
                          text: blueprint.formatLabel,
                          icon: blueprint.format == BlueprintFormat.longForm
                              ? Icons.videocam_rounded
                              : Icons.electric_bolt_rounded,
                          variant: BadgeVariant.primary,
                        ),
                        ResponsiveBadge(
                          text:
                              '${blueprint.predictedMultiplier}× OUTLIER PROJECTION (${blueprint.confidenceIntervalMin}×–${blueprint.confidenceIntervalMax}× Range)',
                          icon: Icons.trending_up_rounded,
                          variant: BadgeVariant.outlier,
                        ),
                        ResponsiveBadge(
                          text: '${blueprint.convictionScore}/10 CONVICTION',
                          icon: Icons.auto_awesome_rounded,
                          variant: BadgeVariant.neutral,
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // Title
                    Text(
                      blueprint.title,
                      style: AppTypography.headlineLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Section 1: Pre-Engineered Hook
                    _buildSectionHeader(
                      icon: Icons.auto_awesome_rounded,
                      title: 'OPENING 5-SECOND HOOK SCRIPT',
                    ),
                    SizedBox(height: 8.h),
                    TactileCard(
                      backgroundColor: AppColors.canvas,
                      padding: EdgeInsets.all(14.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            blueprint.hookText,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textInk,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Est. speaking time: 4.8s • 0% filler words',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.outlierJade,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                      ClipboardData(text: blueprint.hookText));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Hook copied to clipboard!',
                                        style: AppTypography.bodySmall
                                            .copyWith(color: Colors.white),
                                      ),
                                      backgroundColor: AppColors.textInk,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.copy_rounded,
                                        size: 13.sp, color: AppColors.primary),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Copy Hook',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Section 2: Thumbnail Concept Blueprint
                    _buildSectionHeader(
                      icon: Icons.image_outlined,
                      title: 'THUMBNAIL CONCEPT SPLIT-BOX',
                    ),
                    SizedBox(height: 8.h),
                    ThumbnailConceptBox(
                      conceptLeft: blueprint.thumbnailConceptLeft,
                      conceptRight: blueprint.thumbnailConceptRight,
                      tag: blueprint.thumbnailTag,
                    ),
                    SizedBox(height: 16.h),

                    // Section 3: 4-Step Narrative Structure & Tailored Retention Anchors
                    _buildSectionHeader(
                      icon: Icons.list_alt_rounded,
                      title: 'PRE-ENGINEERED RETENTION ANCHORS & PACING',
                    ),
                    SizedBox(height: 8.h),
                    ...blueprint.preEngineeredRetentionAnchors.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final anchor = entry.value;
                      final parts = anchor.split(': ');
                      final timestamp = parts.isNotEmpty ? parts.first : '0:00';
                      final desc = parts.length > 1 ? parts.sublist(1).join(': ') : anchor;

                      Color stepColor;
                      switch (idx % 4) {
                        case 0:
                          stepColor = AppColors.primary;
                          break;
                        case 1:
                          stepColor = AppColors.warningAmber;
                          break;
                        case 2:
                          stepColor = AppColors.outlierJade;
                          break;
                        default:
                          stepColor = AppColors.indigoAccent;
                      }

                      return _buildPacingStep(
                        timestamp: timestamp,
                        title: 'Phase ${idx + 1}',
                        desc: desc,
                        color: stepColor,
                      );
                    }),
                    SizedBox(height: 16.h),

                    // Section 4: Data-Backed "Why" Proof & Mathematical Conviction
                    _buildSectionHeader(
                      icon: Icons.insights_rounded,
                      title: 'AUDIENCE DEMAND PROOF & CONVICTION BREAKDOWN',
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.outlierJadeSubtle,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.outlierJadeBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'MATHEMATICAL CONVICTION',
                                style: AppTypography.labelSmall.copyWith(
                                  color: const Color(0xFF065F46),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9.sp,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4.r),
                                  border: Border.all(
                                      color: AppColors.outlierJadeBorder),
                                ),
                                child: Text(
                                  '${blueprint.convictionScore}/10 High Conviction',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.outlierJade,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            blueprint.dataProofReason,
                            style: AppTypography.bodyMedium.copyWith(
                              color: const Color(0xFF065F46),
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Section 5: Demand Cluster & Comment Evidence
                    if (blueprint.demandCluster != null ||
                        blueprint.audienceCommentSource != null) ...[
                      SizedBox(height: 16.h),
                      _buildSectionHeader(
                        icon: Icons.forum_rounded,
                        title: 'COMMUNITY DEMAND EVIDENCE',
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColors.primarySubtle,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.primaryBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (blueprint.demandCluster != null) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'CLUSTER: ${blueprint.demandCluster!.topicKeyword.toUpperCase()}',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 9.5.sp,
                                    ),
                                  ),
                                  Text(
                                    'DVI ${blueprint.demandCluster!.demandVelocityIndex} • ${blueprint.demandCluster!.totalUpvotes} Upvotes',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 9.sp,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              ...blueprint.demandCluster!.sampleComments.map((c) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 6.h),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 8.r,
                                        backgroundColor: AppColors.primary,
                                        child: Text(
                                          c.authorDisplayName.isNotEmpty
                                              ? c.authorDisplayName[0]
                                                  .toUpperCase()
                                              : 'V',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 7.sp,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      SizedBox(width: 6.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${c.authorDisplayName}${c.likeCount > 0 ? ' • 👍 ${c.likeCount} likes' : ''}',
                                              style: AppTypography.labelSmall
                                                  .copyWith(
                                                color: AppColors.primaryDark,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 9.5.sp,
                                              ),
                                            ),
                                            Text(
                                              '"${c.text}"',
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                color: AppColors.textInk,
                                                fontStyle: FontStyle.italic,
                                                height: 1.35,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ] else if (blueprint.audienceCommentSource != null) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 10.r,
                                        backgroundColor: AppColors.primary,
                                        child: Text(
                                          blueprint.audienceCommentSource!
                                                  .authorDisplayName.isNotEmpty
                                              ? blueprint.audienceCommentSource!
                                                  .authorDisplayName[0]
                                                  .toUpperCase()
                                              : 'V',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.sp,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        blueprint.audienceCommentSource!
                                            .authorDisplayName,
                                        style:
                                            AppTypography.labelMedium.copyWith(
                                          color: AppColors.primaryDark,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (blueprint.audienceCommentSource!.likeCount >
                                      0)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 6.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(6.r),
                                        border: Border.all(
                                            color: const Color(0xFFBFDBFE)),
                                      ),
                                      child: Text(
                                        '👍 ${blueprint.audienceCommentSource!.likeCount} Likes',
                                        style:
                                            AppTypography.labelSmall.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10.sp,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                '"${blueprint.audienceCommentSource!.text}"',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textInk,
                                  fontStyle: FontStyle.italic,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    // Section 6: Creator Authenticity Match (if available)
                    if (blueprint.creatorAuthenticityProof.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      _buildSectionHeader(
                        icon: Icons.verified_user_rounded,
                        title: 'CREATOR AUTHENTICITY & VOICE MATCH',
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 16.sp, color: AppColors.outlierJade),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                blueprint.creatorAuthenticityProof,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textInk,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 24.h),

                    // Action Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final text = '''
# Video Production Brief: ${blueprint.title}
Format: ${blueprint.formatLabel}
Projected Outlier Multiplier: ${blueprint.predictedMultiplier}x

## 5-Second Hook:
"${blueprint.hookText}"

## Thumbnail Concept:
- Left: ${blueprint.thumbnailConceptLeft}
- Right: ${blueprint.thumbnailConceptRight}
- Text Tag: ${blueprint.thumbnailTag}

## Data Proof:
${blueprint.dataProofReason}
''';
                              Clipboard.setData(ClipboardData(text: text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Full Production Runbook copied to clipboard!',
                                    style: AppTypography.bodySmall
                                        .copyWith(color: Colors.white),
                                  ),
                                  backgroundColor: AppColors.textInk,
                                ),
                              );
                            },
                            icon: Icon(Icons.share_outlined, size: 16.sp),
                            label: Text(
                              'Export Brief',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: SolidHeavyButton(
                            label: 'Run Simulator',
                            icon: Icons.speed_rounded,
                            height: 48.h,
                            onPressed: () {
                              final simProvider =
                                  context.read<SimulatorProvider>();
                              simProvider.loadBlueprint(blueprint);
                              Navigator.pop(context);
                              if (onSimulatePressed != null) {
                                onSimulatePressed!();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: AppColors.textMuted),
        SizedBox(width: 6.w),
        Text(
          title,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildPacingStep({
    required String timestamp,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100.r), // Capsule timestamp
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              timestamp,
              style: AppTypography.monoTimestamp.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 10.sp,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                  ),
                ),
                Text(
                  desc,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
