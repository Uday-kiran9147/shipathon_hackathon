import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/channel_graph.dart';
import '../../providers/channel_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/solid_heavy_button.dart';
import '../../widgets/common/tactile_card.dart';
import '../paywall/creator_pro_paywall_sheet.dart';

/// Channel Graph Baseline & YouTube API Integration Screen
class ChannelGraphScreen extends StatefulWidget {
  const ChannelGraphScreen({super.key});

  @override
  State<ChannelGraphScreen> createState() => _ChannelGraphScreenState();
}

class _ChannelGraphScreenState extends State<ChannelGraphScreen> {
  final TextEditingController _syncHandleController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isControllerInitialized = false;

  @override
  void dispose() {
    _syncHandleController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }


  void _showVideoDetailsModal(BuildContext context, ChannelRecentVideo video) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: 640.h,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: EdgeInsets.only(top: 10.h, bottom: 8.h),
                    width: 36.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.video_camera_back_rounded,
                              color: AppColors.youtubeRed, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'VIDEO DEEP TEARDOWN',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textInk,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Video Thumbnail
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: _buildVideoThumbnail(
                            video,
                            borderRadius: 14,
                            isHero: true,
                          ),
                        ),
                        SizedBox(height: 14.h),
                        Text(
                          video.title,
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 6.h,
                          children: [
                            _buildStatChip(
                                Icons.remove_red_eye_rounded,
                                '${NumberFormat.compact().format(video.views)} Views',
                                AppColors.primary),
                            _buildStatChip(
                                Icons.thumb_up_rounded,
                                '${NumberFormat.compact().format(video.likes)} Likes',
                                AppColors.outlierJade),
                            _buildStatChip(
                                Icons.comment_rounded,
                                '${video.commentCount} Comments',
                                AppColors.studioCrimson),
                            _buildStatChip(
                                Icons.timer_rounded,
                                video.durationFormatted,
                                AppColors.textSecondary),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'VIDEO DESCRIPTION & CONTEXT',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.canvas,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Text(
                            video.description.isNotEmpty
                                ? video.description
                                : 'No description provided.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textInk,
                              height: 1.45,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        if (video.tags.isNotEmpty) ...[
                          Text(
                            'TAGS & SEARCH CLUSTERS',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Wrap(
                            spacing: 6.w,
                            runSpacing: 6.h,
                            children: video.tags.map((tag) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(6.r),
                                  border:
                                      Border.all(color: AppColors.borderLight),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 10.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 16.h),
                        ],
                        Text(
                          'TOP AUDIENCE COMMENTS & REQUESTS (${video.topComments.length})',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        if (video.topComments.isEmpty) ...[
                          Text(
                            'No comments synced yet or comments disabled for this video.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ] else ...[
                          ...video.topComments.map((c) => _buildCommentTile(c)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(ChannelComment comment) {
    Color badgeColor;
    String badgeText;
    switch (comment.intentCategory) {
      case ChannelCommentIntent.request:
        badgeColor = AppColors.primary;
        badgeText = '💡 VIDEO REQUEST';
        break;
      case ChannelCommentIntent.question:
        badgeColor = AppColors.warningAmber;
        badgeText = '❓ QUESTION';
        break;
      case ChannelCommentIntent.praise:
        badgeColor = AppColors.outlierJade;
        badgeText = '🔥 TOP PRAISE';
        break;
      case ChannelCommentIntent.feedback:
        badgeColor = AppColors.studioCrimson;
        badgeText = '📝 FEEDBACK';
        break;
      case ChannelCommentIntent.discussion:
        badgeColor = AppColors.textSecondary;
        badgeText = '💬 DISCUSSION';
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 9.r,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      comment.authorDisplayName.isNotEmpty
                          ? comment.authorDisplayName[0].toUpperCase()
                          : 'V',
                      style: TextStyle(color: Colors.white, fontSize: 8.sp),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    comment.authorDisplayName,
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textInk,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4.r),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  badgeText,
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            comment.text,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textInk,
              height: 1.35,
            ),
          ),
          if (comment.likeCount > 0) ...[
            SizedBox(height: 4.h),
            Text(
              '👍 ${comment.likeCount} likes',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 9.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final channelProvider = context.watch<ChannelProvider>();
    final channel = channelProvider.channel;
    final subProvider = context.watch<SubscriptionProvider>();

    if (!_isControllerInitialized) {
      _syncHandleController.text = channel.handle;
      _apiKeyController.text = channelProvider.configuredApiKey ?? '';
      _isControllerInitialized = true;
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const CustomAppBar(
        title: 'My Channel',
        subtitle: 'Connect your channel for personalized ideas',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TactileCard(
              padding: EdgeInsets.all(14.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sync_rounded,
                                size: 16.sp, color: AppColors.youtubeRed),
                            SizedBox(width: 6.w),
                            Flexible(
                              child: Text(
                                'YOUTUBE SYNC',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textInk,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: channelProvider.hasApiKey
                              ? AppColors.outlierJadeSubtle
                              : AppColors.warningAmberSubtle,
                          borderRadius: BorderRadius.circular(100.r), // Capsule pill
                          border: Border.all(
                            color: channelProvider.hasApiKey
                                ? AppColors.outlierJadeBorder
                                : AppColors.warningAmberBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6.w,
                              height: 6.w,
                              decoration: BoxDecoration(
                                color: channelProvider.hasApiKey
                                    ? AppColors.outlierJade
                                    : AppColors.warningAmber,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              channelProvider.hasApiKey
                                  ? 'API KEY READY'
                                  : 'OFFLINE / DEMO',
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w800,
                                color: channelProvider.hasApiKey
                                    ? AppColors.outlierJade
                                    : AppColors.warningAmber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _syncHandleController,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textInk,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Enter channel handle (e.g. @Telusko)',
                            prefixIcon: Icon(Icons.alternate_email_rounded,
                                size: 18),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      SizedBox(
                        width: 105.w,
                        child: SolidHeavyButton(
                          label: 'Sync',
                          icon: Icons.cloud_download_rounded,
                          height: 48.h,
                          isLoading: channelProvider.isSyncing,
                          backgroundColor: AppColors.youtubeRed,
                          onPressed: () async {
                            final handle =
                                _syncHandleController.text.trim();
                            if (handle.isNotEmpty) {
                              final success = await context
                                  .read<ChannelProvider>()
                                  .syncChannel(handle);
                              if (!context.mounted) return;
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '✅ Synced YouTube Channel and Audience Intelligence!',
                                      style: AppTypography.bodySmall
                                          .copyWith(color: Colors.white),
                                    ),
                                    backgroundColor: AppColors.outlierJade,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      channelProvider.syncError ??
                                          'Failed to sync YouTube channel.',
                                      style: AppTypography.bodySmall
                                          .copyWith(color: Colors.white),
                                    ),
                                    backgroundColor: AppColors.studioCrimson,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 6.w,
                    children: [
                      _buildPresetChip('@MrBeast'),
                      _buildPresetChip('@Telusko'),
                      _buildPresetChip('@mkbhd'),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            if (channel.isConfigured) ...[
              TactileCard(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52.w,
                          height: 52.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primarySubtle,
                            border: Border.all(
                              color: AppColors.borderLight,
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: (channel.avatarUrl != null &&
                                    channel.avatarUrl!.startsWith('http'))
                                ? Image.network(
                                    channel.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                      Icons.play_circle_fill_rounded,
                                      color: AppColors.youtubeRed,
                                      size: 28.sp,
                                    ),
                                  )
                                : Icon(
                                    Icons.play_circle_fill_rounded,
                                    color: AppColors.youtubeRed,
                                    size: 28.sp,
                                  ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      channel.channelName,
                                      style: AppTypography.titleLarge.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Icon(Icons.check_circle_rounded,
                                      size: 15.sp, color: AppColors.primary),
                                ],
                              ),
                              Text(
                                channel.handle,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (channel.channelDescription.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CHANNEL ABOUT & MISSION',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              channel.channelDescription,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textInk,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (channel.signatureCreatorStyle.isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: AppColors.outlierJadeSubtle,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: AppColors.outlierJadeBorder),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.auto_awesome_rounded,
                                size: 14.sp, color: AppColors.outlierJade),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                'MINED CREATOR VOICE: ${channel.signatureCreatorStyle}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: const Color(0xFF065F46),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 14.h),
                    const Divider(),
                    SizedBox(height: 12.h),
                    if (channel.niche.isNotEmpty) ...[
                      _buildInfoRow('Niche / Core Focus', channel.niche),
                      SizedBox(height: 8.h),
                    ],
                    _buildInfoRow('Primary Format', channel.topFormat),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'CHANNEL ENGAGEMENT & BASELINE',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'SUBSCRIBERS',
                      value: NumberFormat.compact().format(channel.subscribers),
                      icon: Icons.people_alt_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'MEDIAN VIEWS',
                      value: NumberFormat.compact().format(channel.medianViews),
                      icon: Icons.remove_red_eye_rounded,
                      color: AppColors.outlierJade,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'AVG LIKES',
                      value: NumberFormat.compact().format(channel.averageLikes),
                      icon: Icons.thumb_up_rounded,
                      color: AppColors.studioCrimson,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // CREATOR AUTHENTICITY & AUTHORITY PROFILE
              Text(
                'CREATOR DNA & AUTHENTICITY METRICS',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              SizedBox(height: 8.h),
              TactileCard(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              color: AppColors.primarySubtle,
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.psychology_rounded,
                                        size: 14.sp, color: AppColors.primary),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'AUTHORITY TRUST',
                                      style: AppTypography.labelSmall.copyWith(
                                        fontSize: 8.5.sp,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  '${channel.authenticityProfile.questionToPraiseRatio}× Ratio',
                                  style: AppTypography.monoScoreMedium.copyWith(
                                    fontSize: 15.sp,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                Text(
                                  'Tech Questions vs Praise',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 8.5.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              color: AppColors.outlierJadeSubtle,
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                  color: AppColors.outlierJadeBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.bolt_rounded,
                                        size: 14.sp,
                                        color: AppColors.outlierJade),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'DEMAND VELOCITY',
                                      style: AppTypography.labelSmall.copyWith(
                                        fontSize: 8.5.sp,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF065F46),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  '${channel.authenticityProfile.engagementVelocity} Velocity',
                                  style: AppTypography.monoScoreMedium.copyWith(
                                    fontSize: 15.sp,
                                    color: const Color(0xFF065F46),
                                  ),
                                ),
                                Text(
                                  'Interactions per 1K Views',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 8.5.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'SIGNATURE HOOK ARCHETYPE',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      channel.authenticityProfile.signatureHookStyle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textInk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: AppColors.hazardRubySubtle,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: AppColors.hazardRubyBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 14.sp, color: AppColors.hazardRuby),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NICHE RETENTION VULNERABILITY ALERT',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.hazardRuby,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 8.5.sp,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  channel.authenticityProfile
                                      .retentionVulnerabilityArea,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.hazardRuby,
                                    fontSize: 10.5.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // AUDIENCE VOICE & LIVE COMMENTS HUB WITH DEMAND CLUSTERS
              if (channel.audienceInsight.topDemandClusters.isNotEmpty ||
                  channel.audienceRequests.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AUDIENCE DEMAND CLUSTERS & INTEL',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppColors.primarySubtle,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        '${channel.allRecentComments.length} Comments Mined',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                if (channel.audienceInsight.topDemandClusters.isNotEmpty) ...[
                  ...channel.audienceInsight.topDemandClusters.map((cluster) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: TactileCard(
                        padding: EdgeInsets.all(12.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(Icons.local_fire_department_rounded,
                                          size: 15.sp,
                                          color: AppColors.youtubeRed),
                                      SizedBox(width: 6.w),
                                      Flexible(
                                        child: Text(
                                          cluster.topicKeyword,
                                          style:
                                              AppTypography.titleMedium.copyWith(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12.5.sp,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.outlierJadeSubtle,
                                    borderRadius: BorderRadius.circular(4.r),
                                    border: Border.all(
                                        color: AppColors.outlierJadeBorder),
                                  ),
                                  child: Text(
                                    'DVI ${cluster.demandVelocityIndex} • ${cluster.totalUpvotes} Upvotes',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.outlierJade,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 8.5.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (cluster.sampleComments.isNotEmpty) ...[
                              SizedBox(height: 8.h),
                              ...cluster.sampleComments.take(2).map((c) {
                                return Container(
                                  margin: EdgeInsets.only(bottom: 4.h),
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.canvas,
                                    borderRadius: BorderRadius.circular(6.r),
                                    border:
                                        Border.all(color: AppColors.borderLight),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '💬',
                                        style: TextStyle(fontSize: 10.sp),
                                      ),
                                      SizedBox(width: 6.w),
                                      Expanded(
                                        child: Text(
                                          '${c.authorDisplayName}: "${c.text}" (${c.likeCount} likes)',
                                          style:
                                              AppTypography.bodySmall.copyWith(
                                            fontSize: 10.sp,
                                            color: AppColors.textInk,
                                            height: 1.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ] else ...[
                  TactileCard(
                    padding: EdgeInsets.all(12.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top Recurring Viewer Demands',
                          style: AppTypography.labelSmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textInk,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        ...channel.audienceInsight.topViewerRequests.map((req) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 6.h),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.lightbulb_rounded,
                                    size: 14.sp, color: AppColors.warningAmber),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Text(
                                    req,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textInk,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 16.h),
              ],

              if (channel.recentVideos.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RECENT UPLOADS & ENGAGEMENT',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      'Tap video for full teardown',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                TactileCard(
                  padding: EdgeInsets.all(8.w),
                  child: Column(
                    children: channel.recentVideos.map((video) {
                      return InkWell(
                        onTap: () => _showVideoDetailsModal(context, video),
                        borderRadius: BorderRadius.circular(8.r),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 8.h, horizontal: 6.w),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildVideoThumbnail(
                                video,
                                width: 90.w,
                                height: 52.h,
                                borderRadius: 8,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      video.title,
                                      style: AppTypography.bodySmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textInk,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 2.h),
                                    Wrap(
                                      spacing: 4.w,
                                      children: [
                                        Text(
                                          '${NumberFormat.compact().format(video.views)} views',
                                          style:
                                              AppTypography.labelSmall.copyWith(
                                            color: AppColors.outlierJade,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10.sp,
                                          ),
                                        ),
                                        if (video.likes > 0) ...[
                                          Text(
                                            '• 👍 ${NumberFormat.compact().format(video.likes)}',
                                            style: AppTypography.labelSmall
                                                .copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 10.sp,
                                            ),
                                          ),
                                        ],
                                        if (video.commentCount > 0) ...[
                                          Text(
                                            '• 💬 ${video.commentCount}',
                                            style: AppTypography.labelSmall
                                                .copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 10.sp,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded,
                                  size: 18.sp, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 16.h),
              ],
              if (channel.topTopicClusters.isNotEmpty) ...[
                Text(
                  'PROVEN TOPIC CLUSTERS',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: channel.topTopicClusters.map((topic) {
                    return Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(100.r), // Capsule topic pill
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bubble_chart_rounded,
                              size: 13.sp, color: AppColors.primary),
                          SizedBox(width: 6.w),
                          Text(
                            topic,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20.h),
              ],
            ],
            TactileCard(
              backgroundColor: AppColors.proGoldSubtle,
              border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.build_circle_rounded,
                          color: AppColors.proGold, size: 18.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'HACKATHON DEMO & REVENUECAT',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.proGold,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Instant toggle between Free Tier and Creator Pro to test RevenueCat access gates.',
                    style: AppTypography.bodySmall.copyWith(
                      color: const Color(0xFF92400E),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: subProvider.toggleProStatusDemo,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFF59E0B)),
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            shape: const StadiumBorder(
                              side: BorderSide(color: Color(0xFFF59E0B)),
                            ),
                          ),
                          child: Text(
                            subProvider.isPro
                                ? 'Switch to Free Tier'
                                : 'Switch to Pro Access',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.proGold,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => CreatorProPaywallSheet.show(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            shape: const StadiumBorder(), // Capsule CTA
                          ),
                          child: Text(
                            'Open Paywall',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String handle) {
    return ActionChip(
      label: Text(
        handle,
        style: AppTypography.labelMedium.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF181A24),
          fontSize: 12.sp,
        ),
      ),
      shape: const StadiumBorder(
        side: BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
      ),
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      onPressed: () {
        _syncHandleController.text = handle;
        context.read<ChannelProvider>().syncChannel(handle);
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: AppColors.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: AppTypography.monoScoreMedium.copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.textInk,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoThumbnail(
    ChannelRecentVideo video, {
    double? width,
    double? height,
    double borderRadius = 8,
    bool isHero = false,
  }) {
    String? resolvedUrl = video.thumbnailUrl;
    if ((resolvedUrl == null || resolvedUrl.isEmpty) &&
        video.id.isNotEmpty &&
        !video.id.startsWith('demo_') &&
        !video.id.startsWith('mock_')) {
      resolvedUrl = 'https://i.ytimg.com/vi/${video.id}/hqdefault.jpg';
    }

    final placeholder = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(borderRadius.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Center(
        child: Icon(
          Icons.play_circle_fill_rounded,
          color: AppColors.youtubeRed,
          size: isHero ? 36.sp : 22.sp,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius.r),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(borderRadius.r),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (resolvedUrl != null && resolvedUrl.isNotEmpty)
              Image.network(
                resolvedUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => placeholder,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return placeholder;
                },
              )
            else
              placeholder,
            if (isHero)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28.sp,
                      ),
                    ),
                  ),
                ),
              ),
            if (video.durationFormatted.isNotEmpty)
              Positioned(
                right: 4.w,
                bottom: 4.h,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  child: Text(
                    video.durationFormatted,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isHero ? 11.sp : 8.5.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
