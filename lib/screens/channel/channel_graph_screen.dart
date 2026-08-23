import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/channel_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
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

  void _showApiKeyModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
            left: 20.w,
            right: 20.w,
            top: 20.h,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.key_rounded,
                          color: AppColors.primary, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'YouTube Data API v3 Key',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
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
              SizedBox(height: 8.h),
              Text(
                'Enter your Google Cloud YouTube Data API v3 key to enable live channel synchronization. You can also configure YOUTUBE_API_KEY in .env.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 14.h),
              TextField(
                controller: _apiKeyController,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textInk,
                ),
                decoration: const InputDecoration(
                  hintText: 'AIzaSy...',
                  prefixIcon: Icon(Icons.vpn_key_outlined, size: 18),
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final key = _apiKeyController.text.trim();
                    context.read<ChannelProvider>().setApiKey(
                          key.isNotEmpty ? key : null,
                        );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          key.isNotEmpty
                              ? '🔑 YouTube API Key configured!'
                              : 'YouTube API Key cleared.',
                          style: AppTypography.bodySmall
                              .copyWith(color: Colors.white),
                        ),
                        backgroundColor: key.isNotEmpty
                            ? AppColors.outlierJade
                            : AppColors.textInk,
                      ),
                    );
                  },
                  child: Text(
                    'Save Configuration',
                    style:
                        AppTypography.labelLarge.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
      appBar: CustomAppBar(
        title: 'Channel Graph',
        subtitle: 'Context Engine & Live YouTube Sync',
        actions: [
          IconButton(
            icon: Icon(
              channelProvider.hasApiKey
                  ? Icons.key_rounded
                  : Icons.key_off_rounded,
              color: channelProvider.hasApiKey
                  ? AppColors.outlierJade
                  : AppColors.textMuted,
              size: 20.sp,
            ),
            tooltip: 'Configure YouTube API Key',
            onPressed: () => _showApiKeyModal(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // YouTube Live Sync Input Box
            TactileCard(
              padding: EdgeInsets.all(14.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sync_rounded,
                              size: 16.sp, color: AppColors.youtubeRed),
                          SizedBox(width: 6.w),
                          Text(
                            'LIVE YOUTUBE CHANNEL SYNC',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textInk,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: channelProvider.hasApiKey
                              ? AppColors.outlierJadeSubtle
                              : AppColors.warningAmberSubtle,
                          borderRadius: BorderRadius.circular(4.r),
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
                                  : 'NO API KEY',
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
                      ElevatedButton(
                        onPressed: channelProvider.isSyncing
                            ? null
                            : () async {
                                final handle =
                                    _syncHandleController.text.trim();
                                if (handle.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Please enter a YouTube handle to sync.'),
                                    ),
                                  );
                                  return;
                                }

                                final success = await channelProvider
                                    .syncChannel(handle);
                                if (context.mounted) {
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '✓ Connected to ${channelProvider.channel.channelName} (${channelProvider.channel.handle})',
                                          style: AppTypography.bodySmall
                                              .copyWith(color: Colors.white),
                                        ),
                                        backgroundColor: AppColors.outlierJade,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } else if (channelProvider.syncError !=
                                      null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          channelProvider.syncError!,
                                          style: AppTypography.bodySmall
                                              .copyWith(color: Colors.white),
                                        ),
                                        backgroundColor: AppColors.hazardRuby,
                                        behavior: SnackBarBehavior.floating,
                                        action: SnackBarAction(
                                          label: 'Set API Key',
                                          textColor: Colors.white,
                                          onPressed: () =>
                                              _showApiKeyModal(context),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.youtubeRed,
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: channelProvider.isSyncing
                            ? SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cloud_download_rounded,
                                      size: 16.sp, color: Colors.white),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Sync',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
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

            // If No Channel is connected yet:
            if (!channel.isConfigured) ...[
              Container(
                padding: EdgeInsets.all(28.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: AppColors.cardElevation,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.primarySubtle,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sensors_off_rounded,
                        size: 36.sp,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      'No Channel Connected',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Enter your YouTube handle above to fetch your real channel statistics, median views, and audience topic clusters.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    if (!channelProvider.hasApiKey) ...[
                      OutlinedButton.icon(
                        onPressed: () => _showApiKeyModal(context),
                        icon: Icon(Icons.key_rounded,
                            size: 16.sp, color: AppColors.primary),
                        label: Text(
                          'Configure YouTube API Key',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              // Channel Details Card
              TactileCard(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48.w,
                          height: 48.w,
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
                                      size: 26.sp,
                                    ),
                                  )
                                : Icon(
                                    Icons.play_circle_fill_rounded,
                                    color: AppColors.youtubeRed,
                                    size: 26.sp,
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
                                      size: 14.sp, color: AppColors.primary),
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
                    SizedBox(height: 16.h),
                    const Divider(),
                    SizedBox(height: 14.h),

                    if (channel.niche.isNotEmpty) ...[
                      _buildInfoRow('Niche / Core Focus', channel.niche),
                      SizedBox(height: 10.h),
                    ],
                    if (channel.targetAudienceLevel.isNotEmpty) ...[
                      _buildInfoRow(
                          'Target Demographic', channel.targetAudienceLevel),
                      SizedBox(height: 10.h),
                    ],
                    _buildInfoRow('Primary Format', channel.topFormat),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Performance Baseline Metrics Grid
              Text(
                'HISTORICAL BASELINE METRICS',
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
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'MEDIAN VIEWS',
                      value: NumberFormat.compact().format(channel.medianViews),
                      icon: Icons.remove_red_eye_rounded,
                      color: AppColors.outlierJade,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'TOTAL UPLOADS',
                      value: NumberFormat.compact().format(channel.totalVideos),
                      icon: Icons.video_collection_rounded,
                      color: AppColors.studioCrimson,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Recent Synced Videos Section
              if (channel.recentVideos.isNotEmpty) ...[
                Text(
                  'RECENT SYNCED UPLOADS',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 8.h),
                TactileCard(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    children: channel.recentVideos.map((video) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 6.h),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Icon(Icons.play_arrow_rounded,
                                  size: 16.sp, color: AppColors.youtubeRed),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    video.title,
                                    style: AppTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textInk,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${NumberFormat.compact().format(video.views)} views',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.outlierJade,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 16.h),
              ],

              // Top Topic Clusters
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
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10.r),
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

            // Hackathon Judge Demo Controls Box
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
                      Text(
                        'HACKATHON DEMO & JUDGE CONTROLS',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.proGold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Instant toggle between Free Tier (3 sims limit) and Creator Pro (unlimited simulations) for testing RevenueCat flows.',
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
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

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontSize: 9.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
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
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: AppTypography.monoScoreMedium.copyWith(
              fontSize: 17.sp,
              color: AppColors.textInk,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 9.sp,
            ),
          ),
        ],
      ),
    );
  }
}
