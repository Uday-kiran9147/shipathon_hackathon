import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/channel_graph.dart';
import '../../providers/briefing_provider.dart';
import '../../providers/channel_provider.dart';
import '../../widgets/briefing/blueprint_card.dart';
import '../../widgets/common/custom_app_bar.dart';

/// Daily Prescriptive Briefing Screen ("What to Film Tomorrow")
class DailyBriefingScreen extends StatefulWidget {
  final Function(int targetTabIndex)? onNavigateTab;

  const DailyBriefingScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<DailyBriefingScreen> createState() => _DailyBriefingScreenState();
}

class _DailyBriefingScreenState extends State<DailyBriefingScreen> {
  ChannelGraph? _lastSyncedChannel;

  @override
  Widget build(BuildContext context) {
    final briefingProvider = context.watch<BriefingProvider>();
    final channel = context.watch<ChannelProvider>().channel;

    // Check if channel changed (e.g. user selected different archetype in Channel tab)
    if (_lastSyncedChannel == null ||
        _lastSyncedChannel!.handle != channel.handle ||
        _lastSyncedChannel!.channelName != channel.channelName) {
      _lastSyncedChannel = channel;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        briefingProvider.updateForChannel(channel);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: CustomAppBar(
        title: 'Daily Briefing',
        subtitle: 'High-Conviction Video Blueprints',
        actions: [
          IconButton(
            icon: briefingProvider.isGeneratingFresh
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 20.sp,
                  ),
            tooltip: 'Generate Fresh AI Blueprint',
            onPressed: briefingProvider.isGeneratingFresh
                ? null
                : () async {
                    try {
                      final newBp = await briefingProvider
                          .generateFreshBlueprint(channel);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✨ Generated fresh blueprint: ${newBp.title}',
                              style: AppTypography.bodySmall
                                  .copyWith(color: Colors.white),
                            ),
                            backgroundColor: AppColors.primaryDark,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (_) {}
                  },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => briefingProvider.refreshBriefing(channel),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Creator Studio Persona Card
              _buildCreatorPersonaCard(context, channel),
              SizedBox(height: 16.h),

              // Format & Saved Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'All Blueprints',
                      isSelected: briefingProvider.currentFilter ==
                          BriefingFilter.all,
                      onTap: () =>
                          briefingProvider.setFilter(BriefingFilter.all),
                    ),
                    SizedBox(width: 8.w),
                    _buildFilterChip(
                      label: 'Long-Form (8–15m)',
                      icon: Icons.videocam_rounded,
                      isSelected: briefingProvider.currentFilter ==
                          BriefingFilter.longForm,
                      onTap: () =>
                          briefingProvider.setFilter(BriefingFilter.longForm),
                    ),
                    SizedBox(width: 8.w),
                    _buildFilterChip(
                      label: 'Shorts (<60s)',
                      icon: Icons.electric_bolt_rounded,
                      isSelected: briefingProvider.currentFilter ==
                          BriefingFilter.short,
                      onTap: () =>
                          briefingProvider.setFilter(BriefingFilter.short),
                    ),
                    SizedBox(width: 8.w),
                    _buildFilterChip(
                      label: 'Bookmarked (${briefingProvider.savedCount})',
                      icon: Icons.bookmark_rounded,
                      isSelected: briefingProvider.currentFilter ==
                          BriefingFilter.saved,
                      onTap: () =>
                          briefingProvider.setFilter(BriefingFilter.saved),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),

              // Blueprints Feed List
              if (briefingProvider.blueprints.isEmpty) ...[
                _buildEmptyState(),
              ] else ...[
                ...briefingProvider.blueprints.asMap().entries.map((entry) {
                  final index = entry.key;
                  final blueprint = entry.value;
                  final isHero = index == 0 &&
                      briefingProvider.currentFilter == BriefingFilter.all;

                  return Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: BlueprintCard(
                      blueprint: blueprint,
                      isHero: isHero,
                      onSimulatePressed: () {
                        if (widget.onNavigateTab != null) {
                          widget.onNavigateTab!(1); // Jump to Pre-Flight Simulator Tab
                        }
                      },
                    ),
                  );
                }),
              ],
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreatorPersonaCard(BuildContext context, ChannelGraph channel) {
    if (!channel.isConfigured) {
      return Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.warningAmberBorder),
          boxShadow: AppColors.cardElevation,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.warningAmberSubtle,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.link_off_rounded,
                color: AppColors.warningAmber,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Channel Connected',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Sync your YouTube handle in the Channel tab to generate authentic, persona-driven blueprints.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20.r,
                backgroundColor: AppColors.primarySubtle,
                backgroundImage: (channel.avatarUrl != null &&
                        channel.avatarUrl!.isNotEmpty)
                    ? NetworkImage(channel.avatarUrl!)
                    : null,
                child: (channel.avatarUrl == null || channel.avatarUrl!.isEmpty)
                    ? Text(
                        channel.channelName.isNotEmpty
                            ? channel.channelName[0].toUpperCase()
                            : 'Y',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            channel.channelName,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.verified_rounded,
                          color: AppColors.primary,
                          size: 15.sp,
                        ),
                      ],
                    ),
                    Text(
                      '${channel.handle} • ${channel.niche}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 10.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Icon(Icons.insights_rounded,
                    size: 14.sp, color: AppColors.outlierJade),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    '${NumberFormat.compact().format(channel.subscribers)} Subs • ${NumberFormat.compact().format(channel.medianViews)} Median Views • ${channel.recentVideos.isNotEmpty ? channel.recentVideos.length : 6} Uploads Mined',
                    style: AppTypography.monoTimestamp.copyWith(
                      color: AppColors.textInk,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textInk : AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColors.textInk : AppColors.borderLight,
          ),
          boxShadow: isSelected ? AppColors.cardElevation : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13.sp,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              SizedBox(width: 5.w),
            ],
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 11.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 36.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 40.sp,
            color: AppColors.primary,
          ),
          SizedBox(height: 12.h),
          Text(
            'No Live Uploads Mined Yet',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textInk,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Sync your YouTube channel handle in the Channel tab to fetch your recent uploads and generate 100% authentic video blueprints.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: 14.h),
          ElevatedButton.icon(
            onPressed: () {
              if (widget.onNavigateTab != null) {
                widget.onNavigateTab!(2); // Go to Channel Graph Tab
              }
            },
            icon: Icon(Icons.cloud_sync_rounded, size: 16.sp),
            label: const Text('Go to Channel Sync'),
          ),
        ],
      ),
    );
  }
}
