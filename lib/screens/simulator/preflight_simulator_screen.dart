import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/daily_blueprint.dart';
import '../../models/simulation_result.dart';
import '../../providers/channel_provider.dart';
import '../../providers/simulator_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/solid_heavy_button.dart';
import '../../widgets/common/tactile_card.dart';
import '../../widgets/simulator/hook_score_gauge.dart';
import '../../widgets/simulator/prescriptive_fix_tile.dart';
import '../../widgets/simulator/retention_hazard_scrubber.dart';
import '../paywall/creator_pro_paywall_sheet.dart';

/// Pre-Flight Content Simulator Screen ("Will this work?")
class PreflightSimulatorScreen extends StatefulWidget {
  const PreflightSimulatorScreen({super.key});

  @override
  State<PreflightSimulatorScreen> createState() =>
      _PreflightSimulatorScreenState();
}

class _PreflightSimulatorScreenState extends State<PreflightSimulatorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _scriptController = TextEditingController();
  bool _isControllerInitialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _scriptController.dispose();
    super.dispose();
  }

  void _syncInputs() {
    final simProvider = context.read<SimulatorProvider>();
    if (_titleController.text != simProvider.titleInput) {
      _titleController.text = simProvider.titleInput;
    }
    if (_scriptController.text != simProvider.scriptInput) {
      _scriptController.text = simProvider.scriptInput;
    }
  }

  @override
  Widget build(BuildContext context) {
    final simProvider = context.watch<SimulatorProvider>();
    final channel = context.watch<ChannelProvider>().channel;
    final subProvider = context.watch<SubscriptionProvider>();

    if (!_isControllerInitialized) {
      _titleController.text = simProvider.titleInput;
      _scriptController.text = simProvider.scriptInput;
      _isControllerInitialized = true;
    }

    _syncInputs();

    final wordCount = _scriptController.text
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .length;

    final allFixesApplied = simProvider.currentResult != null &&
        simProvider.currentResult!.fixes.isNotEmpty &&
        simProvider.currentResult!.fixes.every((f) => f.isApplied);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const CustomAppBar(
        title: 'Test Retention',
        subtitle: 'Find drop-off spots before you film',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Sample Idea Loader & Format Selector
            Row(
              children: [
                Expanded(
                  child: _buildFormatTab(
                    label: 'Long Video (8–15m)',
                    icon: Icons.videocam_rounded,
                    isSelected:
                        simProvider.selectedFormat == BlueprintFormat.longForm,
                    onTap: () =>
                        simProvider.setFormat(BlueprintFormat.longForm),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildFormatTab(
                    label: 'Short (<60s)',
                    icon: Icons.electric_bolt_rounded,
                    isSelected:
                        simProvider.selectedFormat == BlueprintFormat.short,
                    onTap: () => simProvider.setFormat(BlueprintFormat.short),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Quick Demo Sample Button
            OutlinedButton.icon(
              onPressed: () {
                const sampleTitle =
                    'How 100 Hours of Learning Flutter Changed Everything';
                const sampleScript =
                    'Most people think Flutter is just for simple mobile apps, but I spent 100 hours building real-world projects and what I discovered completely changed my mind. Today, I will reveal the 3 crucial lessons every creator and developer needs to know before building their next app.';
                simProvider.setTitle(sampleTitle);
                simProvider.setScript(sampleScript);
                _titleController.text = sampleTitle;
                _scriptController.text = sampleScript;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✨ Sample video idea loaded! Tap "Test Retention" below.',
                      style: AppTypography.bodySmall
                          .copyWith(color: Colors.white),
                    ),
                    backgroundColor: AppColors.primaryDark,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: Icon(Icons.auto_awesome_rounded,
                  size: 16.sp, color: AppColors.primary),
              label: Text(
                '✨ Try a Sample Video Idea',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 42.h),
                side: const BorderSide(color: AppColors.primaryLight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                backgroundColor: AppColors.primarySubtle,
              ),
            ),
            SizedBox(height: 14.h),

            // Input Card
            TactileCard(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '1. VIDEO TITLE',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.sp,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${_titleController.text.length} chars',
                        style: AppTypography.monoTimestamp.copyWith(
                          fontSize: 11.5.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: _titleController,
                    onChanged: simProvider.setTitle,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textInk,
                    ),
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText:
                          'Enter your video title (or load an idea from the Ideas tab)...',
                    ),
                  ),
                  SizedBox(height: 16.h),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '2. FIRST 30 SECONDS SCRIPT',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.sp,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '$wordCount words (~${(wordCount / 2.5).round()}s read)',
                        style: AppTypography.monoTimestamp.copyWith(
                          color: wordCount > 75
                              ? AppColors.warningAmber
                              : AppColors.textSecondary,
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: _scriptController,
                    onChanged: simProvider.setScript,
                    maxLines: 5,
                    style: AppTypography.bodyMedium.copyWith(
                      height: 1.45,
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText:
                          'Paste the opening 3-5 sentences of your video script...',
                    ),
                  ),
                  SizedBox(height: 18.h),

                  // Run Simulation CTA Button
                  SolidHeavyButton(
                    label: 'Test Video Retention',
                    loadingText: 'Analyzing Retention Curve...',
                    icon: Icons.rocket_launch_rounded,
                    isLoading: simProvider.isAnalyzing,
                    height: 54.h,
                    onPressed: () async {
                      final title = _titleController.text.trim();
                      final script = _scriptController.text.trim();

                      if (title.isEmpty || script.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter both a video title and opening script to test.',
                            ),
                            backgroundColor: AppColors.hazardRuby,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      simProvider.setTitle(title);
                      simProvider.setScript(script);

                      // Check subscription simulation credit limit
                      final allowed =
                          subProvider.recordSimulationAttempt();
                      if (!allowed) {
                        CreatorProPaywallSheet.show(context);
                        return;
                      }

                      await simProvider.runSimulation(channel);
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Simulation Results View with Smooth Slide & Fade Transition
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                );
              },
              child: simProvider.currentResult != null
                  ? KeyedSubtree(
                      key: ValueKey<String>(
                          'results_${simProvider.currentResult!.performanceTier.name}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Animated Score Radar Gauge
                          HookScoreGauge(
                            score: simProvider.currentResult!.hookScore,
                            resonanceScore:
                                simProvider.currentResult!.resonanceScore,
                            tier: simProvider.currentResult!.performanceTier,
                          ),
                          SizedBox(height: 16.h),

                          // Projected Views Card (Anchored to Channel Baseline)
                          if (channel.medianViews > 0) ...[
                            _buildProjectedViewsCard(
                              simProvider.currentResult!.performanceTier,
                              channel.medianViews,
                            ),
                            SizedBox(height: 16.h),
                          ],

                          // Interactive 30s Retention Hazard Scrubber
                          RetentionHazardScrubber(
                            hazards: simProvider.currentResult!.hazards,
                            script: simProvider.scriptInput,
                          ),
                          SizedBox(height: 16.h),

                          // 3 Prescriptive Fixes Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.auto_fix_high_rounded,
                                      size: 18.sp, color: AppColors.primary),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'RECOMMENDED IMPROVEMENTS',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.textInk,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.sp,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                allFixesApplied ? 'All Applied ✓' : '1-Tap Apply',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.outlierJade,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),

                          if (allFixesApplied) ...[
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: AppColors.outlierJadeSubtle,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                    color: AppColors.outlierJadeBorder),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.verified_rounded,
                                      color: AppColors.outlierJade, size: 20.sp),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      'Script Fully Optimized! All drop-off risks resolved for high viewer retention.',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: const Color(0xFF065F46),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10.h),
                          ],

                          ...simProvider.currentResult!.fixes.map((fix) {
                            return PrescriptiveFixTile(
                              fix: fix,
                              onApply: () {
                                simProvider.applyFix(fix.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '⚡ Fix applied! Hook Score lifted to ${simProvider.currentResult!.hookScore.toStringAsFixed(1)}',
                                      style: AppTypography.bodyMedium
                                          .copyWith(color: Colors.white),
                                    ),
                                    backgroundColor: AppColors.outlierJade,
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectedViewsCard(
      PerformanceTier tier, int channelMedianViews) {
    double multiplier;
    switch (tier) {
      case PerformanceTier.topOutlier:
        multiplier = 3.2;
        break;
      case PerformanceTier.aboveMedian:
        multiplier = 1.6;
        break;
      case PerformanceTier.averageBaseline:
        multiplier = 1.0;
        break;
      case PerformanceTier.highFlopRisk:
        multiplier = 0.4;
        break;
    }

    final projectedViews = (channelMedianViews * multiplier).round();

    return TactileCard(
      backgroundColor: tier == PerformanceTier.topOutlier
          ? AppColors.outlierJadeSubtle
          : tier == PerformanceTier.highFlopRisk
              ? AppColors.hazardRubySubtle
              : AppColors.surface,
      border: Border.all(
        color: tier == PerformanceTier.topOutlier
            ? AppColors.outlierJadeBorder
            : tier == PerformanceTier.highFlopRisk
                ? AppColors.hazardRubyBorder
                : AppColors.borderLight,
      ),
      padding: EdgeInsets.all(14.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  tier == PerformanceTier.topOutlier
                      ? Icons.rocket_launch_rounded
                      : tier == PerformanceTier.highFlopRisk
                          ? Icons.warning_rounded
                          : Icons.insights_rounded,
                  color: tier == PerformanceTier.topOutlier
                      ? AppColors.outlierJade
                      : tier == PerformanceTier.highFlopRisk
                          ? AppColors.hazardRuby
                          : AppColors.primary,
                  size: 20.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESTIMATED VIEWS PROJECTION',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 9.sp,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${NumberFormat.compact().format(projectedViews)} views ($multiplier× Median)',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textInk,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              'Median: ${NumberFormat.compact().format(channelMedianViews)}',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 10.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF181A24) : AppColors.surface,
          borderRadius: BorderRadius.circular(100.r), // Solid Capsule
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  fontSize: 11.5.sp,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
