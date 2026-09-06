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
import '../../widgets/common/solid_heavy_button.dart';
import '../../widgets/common/tactile_card.dart';
import '../history/history_screen.dart';

/// Daily Prescriptive Briefing Screen ("What to Film Tomorrow")
class DailyBriefingScreen extends StatefulWidget {
  final Function(int targetTabIndex)? onNavigateTab;

  const DailyBriefingScreen({super.key, this.onNavigateTab});

  @override
  State<DailyBriefingScreen> createState() => _DailyBriefingScreenState();
}

class _DailyBriefingScreenState extends State<DailyBriefingScreen> {
  ChannelGraph? _lastSyncedChannel;

  @override
  Widget build(BuildContext context) {
    final briefingProvider = context.watch<BriefingProvider>();
    final channel = context.watch<ChannelProvider>().channel;

    // Check if channel changed (e.g. user selected different archetype in Channel
    // tab, or the app just booted). We only ever load an *already-generated*
    // briefing for this channel from persisted history here — a plain DB read,
    // never a Gemini call. Generating a brand-new briefing always waits for an
    // explicit tap (Generate Daily Briefing / Generate Fresh Idea / pull-to-refresh).
    if (_lastSyncedChannel == null ||
        _lastSyncedChannel!.handle != channel.handle ||
        _lastSyncedChannel!.channelName != channel.channelName) {
      _lastSyncedChannel = channel;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        briefingProvider.loadPersistedBriefing(channel);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: CustomAppBar(
        title: 'Daily Briefing',
        subtitle: 'Proven video ideas ready to film',
        actions: [
          IconButton(
            icon: briefingProvider.isGeneratingFresh
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  )
                : Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 22.sp,
                  ),
            tooltip: 'Generate Fresh AI Idea',
            onPressed:
                briefingProvider.isGeneratingFresh || !channel.isConfigured
                ? null
                : () async {
                    try {
                      final newBp = await briefingProvider
                          .generateFreshBlueprint(channel);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    '✨ Fresh AI Idea: ${newBp.title}',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: AppColors.primaryDark,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not generate idea: $e'),
                            backgroundColor: AppColors.hazardRuby,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
          ),
          IconButton(
            icon: Icon(
              Icons.history_rounded,
              color: AppColors.textInk,
              size: 22.sp,
            ),
            tooltip: 'History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => briefingProvider.refreshBriefing(channel),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Friendly "How It Works" 3-Step Banner
              _buildHowItWorksCard(),
              SizedBox(height: 14.h),

              // Creator Studio Persona Card
              _buildCreatorPersonaCard(context, channel),
              SizedBox(height: 14.h),

              // Dedicated AI Fresh Idea Action Card
              if (channel.isConfigured) ...[
                _buildAiIdeaBanner(context, briefingProvider, channel),
                SizedBox(height: 14.h),
              ],

              // Format & Saved Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'All Blueprints',
                      isSelected:
                          briefingProvider.currentFilter == BriefingFilter.all,
                      onTap: () =>
                          briefingProvider.setFilter(BriefingFilter.all),
                    ),
                    SizedBox(width: 8.w),
                    _buildFilterChip(
                      label: 'Long Videos (8–15m)',
                      icon: Icons.videocam_rounded,
                      isSelected:
                          briefingProvider.currentFilter ==
                          BriefingFilter.longForm,
                      onTap: () =>
                          briefingProvider.setFilter(BriefingFilter.longForm),
                    ),
                    SizedBox(width: 8.w),
                    _buildFilterChip(
                      label: 'Shorts (<60s)',
                      icon: Icons.electric_bolt_rounded,
                      isSelected:
                          briefingProvider.currentFilter ==
                          BriefingFilter.short,
                      onTap: () =>
                          briefingProvider.setFilter(BriefingFilter.short),
                    ),
                    SizedBox(width: 8.w),
                    _buildFilterChip(
                      label: 'Saved (${briefingProvider.savedCount})',
                      icon: Icons.bookmark_rounded,
                      isSelected:
                          briefingProvider.currentFilter ==
                          BriefingFilter.saved,
                      onTap: () =>
                          briefingProvider.setFilter(BriefingFilter.saved),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),

              // Blueprints Feed List with Smooth Transition
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey<String>(
                    '${briefingProvider.currentFilter.name}_${briefingProvider.blueprints.length}_${briefingProvider.isLoading}',
                  ),
                  child: Column(
                    children: [
                      if (briefingProvider.isLoading) ...[
                        _buildLoadingState(),
                      ] else if (briefingProvider.blueprints.isEmpty) ...[
                        _buildEmptyState(context, briefingProvider, channel),
                      ] else ...[
                        ...briefingProvider.blueprints.asMap().entries.map((
                          entry,
                        ) {
                          final index = entry.key;
                          final blueprint = entry.value;
                          final isHero =
                              index == 0 &&
                              briefingProvider.currentFilter ==
                                  BriefingFilter.all;

                          return Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: BlueprintCard(
                              blueprint: blueprint,
                              isHero: isHero,
                              onSimulatePressed: () {
                                if (widget.onNavigateTab != null) {
                                  widget.onNavigateTab!(
                                    1,
                                  ); // Jump to Pre-Flight Simulator Tab
                                }
                              },
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.primarySubtle,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tips_and_updates_rounded,
                size: 16.sp,
                color: AppColors.primary,
              ),
              SizedBox(width: 6.w),
              Text(
                '3-Step Quick Guide',
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 6.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildStepItem('1', 'Pick Idea'),
              _buildStepItem('2', 'Test Hook'),
              _buildStepItem('3', 'Film & Post'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String step, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100.r), // Capsule step pill
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16.w,
            height: 16.w,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 9.sp,
              ),
            ),
          ),
          SizedBox(width: 5.w),
          Text(
            text,
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorPersonaCard(BuildContext context, ChannelGraph channel) {
    if (!channel.isConfigured) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.warningAmberBorder),
          boxShadow: AppColors.cardElevation,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.warningAmberSubtle,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(
                Icons.account_circle_outlined,
                color: AppColors.warningAmber,
                size: 24.sp,
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
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Sync your YouTube channel in the Channel tab to get personalized ideas.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final medianFormatted = NumberFormat.compact().format(channel.medianViews);
    final subsFormatted = NumberFormat.compact().format(channel.subscribers);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Avatar + Name + Verified + Subscribers
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24.r,
                backgroundColor: AppColors.primarySubtle,
                backgroundImage:
                    (channel.avatarUrl != null && channel.avatarUrl!.isNotEmpty)
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
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            channel.channelName.isNotEmpty
                                ? channel.channelName
                                : channel.handle,
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16.5.sp,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.verified_rounded,
                          color: AppColors.primary,
                          size: 17.sp,
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${channel.handle} • $subsFormatted subscribers',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Row 2: Grid of Median Views & Upload Frequency
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Median views',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      medianFormatted,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textInk,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Upload frequency',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      channel.uploadFrequencyFormatted,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),

          // Divider & Bottom Row: Content analyzed + Top outlier
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.video_library_outlined,
                      size: 15.sp,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text.rich(
                        TextSpan(
                          text: 'Content analyzed: ',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '${channel.totalVideos > 0 ? channel.totalVideos : channel.recentVideos.length} videos',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textInk,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.outlierJadeSubtle,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: AppColors.outlierJadeBorder),
                  ),
                  child: Text(
                    'Top Outlier: ${channel.topOutlierMultiplier}× median',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.outlierJade,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Topic Performance Pill Indicators
          if (channel.topicPerformanceMultipliers.isNotEmpty) ...[
            SizedBox(height: 10.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: channel.topicPerformanceMultipliers.take(4).map((t) {
                  return Container(
                    margin: EdgeInsets.only(right: 6.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: t.multiple >= 1.5
                          ? AppColors.outlierJadeSubtle
                          : AppColors.canvas,
                      borderRadius: BorderRadius.circular(100.r),
                      border: Border.all(
                        color: t.multiple >= 1.5
                            ? AppColors.outlierJadeBorder
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          t.topic,
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textInk,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '→ ${t.multiple}×',
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w800,
                            color: t.multiple >= 1.5
                                ? AppColors.outlierJade
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF181A24) : AppColors.surface,
          borderRadius: BorderRadius.circular(100.r), // True Solid Capsule Pill
          border: Border.all(
            color: isSelected
                ? const Color(0xFF181A24)
                : const Color(0xFFCBD5E1),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15.sp,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 36.w,
            height: 36.w,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Creating Personalized Video Ideas...',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textInk,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Analyzing viewer requests, popular trends, and your channel style.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    BriefingProvider briefingProvider,
    ChannelGraph channel,
  ) {
    // Channel not connected yet: send the user to the Channel tab.
    if (!channel.isConfigured) {
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
              size: 44.sp,
              color: AppColors.primary,
            ),
            SizedBox(height: 14.h),
            Text(
              'No Channel Connected Yet',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textInk,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Sync your YouTube channel handle to get custom video ideas tailored for your audience.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 16.h),
            SolidHeavyButton(
              label: 'Connect YouTube Channel',
              icon: Icons.sync_rounded,
              height: 48.h,
              onPressed: () {
                if (widget.onNavigateTab != null) {
                  widget.onNavigateTab!(2); // Go to Channel Graph Tab
                }
              },
            ),
          ],
        ),
      );
    }

    // Channel is connected but no briefing has been generated yet — this
    // never fires automatically; it only runs when the button below is tapped.
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
            Icons.auto_awesome_rounded,
            size: 44.sp,
            color: AppColors.primary,
          ),
          SizedBox(height: 14.h),
          Text(
            'Ready to Generate Ideas',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textInk,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '${channel.channelName.isNotEmpty ? channel.channelName : channel.handle} is synced. Tap below to generate your Daily Briefing.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 16.h),
          SolidHeavyButton(
            label: 'Generate Daily Briefing',
            icon: Icons.auto_awesome_rounded,
            height: 48.h,
            onPressed: () async {
              try {
                await briefingProvider.updateForChannel(channel);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not generate briefing: $e'),
                      backgroundColor: AppColors.hazardRuby,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAiIdeaBanner(
    BuildContext context,
    BriefingProvider briefingProvider,
    ChannelGraph channel,
  ) {
    return TactileCard(
      onTap: briefingProvider.isGeneratingFresh
          ? null
          : () async {
              try {
                final newBp = await briefingProvider.generateFreshBlueprint(
                  channel,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              '✨ Fresh AI Idea: ${newBp.title}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: AppColors.primaryDark,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not generate idea: $e'),
                      backgroundColor: AppColors.hazardRuby,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
      backgroundColor: const Color(0xFFEFF6FF),
      border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: briefingProvider.isGeneratingFresh
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 18.sp,
                  ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  briefingProvider.isGeneratingFresh
                      ? 'Synthesizing Fresh AI Blueprint...'
                      : 'Generate Fresh AI Idea',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  briefingProvider.isGeneratingFresh
                      ? 'Mining live comments & creator DNA via Gemini AI'
                      : 'Tap to brainstorm a brand-new high-retention video concept',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.5.sp,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.primary,
            size: 20.sp,
          ),
        ],
      ),
    );
  }
}
