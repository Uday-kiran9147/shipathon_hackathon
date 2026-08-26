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
        subtitle: 'Proven video ideas ready to film',
        actions: [
          IconButton(
            icon: briefingProvider.isGeneratingFresh
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 22.sp,
                  ),
            tooltip: 'Generate Fresh AI Ideas',
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
                              '✨ Generated fresh idea: ${newBp.title}',
                              style: AppTypography.bodyMedium
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
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Friendly "How It Works" 3-Step Banner
              _buildHowItWorksCard(),
              SizedBox(height: 14.h),

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
                      label: 'Long Videos (8–15m)',
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
                      label: 'Saved (${briefingProvider.savedCount})',
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

              // Blueprints Feed List with Smooth Transition
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey<String>(
                      '${briefingProvider.currentFilter.name}_${briefingProvider.blueprints.length}_${briefingProvider.isLoading}'),
                  child: Column(
                    children: [
                      if (briefingProvider.isLoading) ...[
                        _buildLoadingState(),
                      ] else if (briefingProvider.blueprints.isEmpty) ...[
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
              Icon(Icons.tips_and_updates_rounded,
                  size: 16.sp, color: AppColors.primary),
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

    return Container(
      padding: EdgeInsets.all(16.w),
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
                radius: 22.r,
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
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.verified_rounded,
                          color: AppColors.primary,
                          size: 16.sp,
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${channel.handle} • ${channel.niche}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(100.r), // Capsule stats pill
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Icon(Icons.insights_rounded,
                    size: 16.sp, color: AppColors.outlierJade),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    '${NumberFormat.compact().format(channel.subscribers)} Subscribers • ~${NumberFormat.compact().format(channel.medianViews)} Avg Views',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textInk,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.sp,
                    ),
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF181A24) : AppColors.surface,
          borderRadius: BorderRadius.circular(100.r), // True Solid Capsule Pill
          border: Border.all(
            color: isSelected ? const Color(0xFF181A24) : const Color(0xFFCBD5E1),
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
}
