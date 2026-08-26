import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/simulation_result.dart';

/// Animated Radial Hook Score Gauge
class HookScoreGauge extends StatefulWidget {
  final double score; // 0.0 to 10.0
  final double resonanceScore;
  final PerformanceTier tier;

  const HookScoreGauge({
    super.key,
    required this.score,
    required this.resonanceScore,
    required this.tier,
  });

  @override
  State<HookScoreGauge> createState() => _HookScoreGaugeState();
}

class _HookScoreGaugeState extends State<HookScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnimation = Tween<double>(begin: 0.0, end: widget.score).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant HookScoreGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _scoreAnimation = Tween<double>(
        begin: oldWidget.score,
        end: widget.score,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getScoreColor(double score) {
    if (score >= 8.0) return AppColors.outlierJade;
    if (score >= 6.0) return AppColors.warningAmber;
    return AppColors.hazardRuby;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scoreAnimation,
      builder: (context, child) {
        final currentScore = _scoreAnimation.value;
        final scoreColor = _getScoreColor(currentScore);

        String ratingText;
        if (currentScore >= 8.5) {
          ratingText = '🌟 Excellent Retention (Top Outlier)';
        } else if (currentScore >= 7.0) {
          ratingText = '👍 Good Hook (Above Average)';
        } else if (currentScore >= 5.0) {
          ratingText = '⚖️ Average (Some Drop-off Expected)';
        } else {
          ratingText = '⚠️ High Drop-off Risk (Needs Fixes)';
        }

        return Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: AppColors.borderLight, width: 1),
            boxShadow: AppColors.cardElevation,
          ),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: ratingText.length > 30
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.spaceBetween,
                  spacing: 8.w,
                  children: [
                    Text(
                      'RETENTION STRENGTH',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.sp,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(100.r), // Capsule pill
                        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        widget.tier.multiplierLabel,
                        style: AppTypography.labelSmall.copyWith(
                          color: scoreColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              // Gauge Circular Dial
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140.w,
                    height: 140.w,
                    child: CircularProgressIndicator(
                      value: currentScore / 10.0,
                      strokeWidth: 12.w,
                      strokeCap: StrokeCap.round,
                      backgroundColor: AppColors.surfaceSubtle,
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentScore.toStringAsFixed(1),
                        style: AppTypography.monoScoreLarge.copyWith(
                          color: AppColors.textInk,
                          fontSize: 36.sp,
                        ),
                      ),
                      Text(
                        'HOOK SCORE / 10',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                ratingText,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scoreColor,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 14.h),
              // Secondary Metric Bars: Audience Resonance & Tier
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AUDIENCE INTEREST',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${widget.resonanceScore.toStringAsFixed(1)} / 10.0',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PERFORMANCE TIER',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            widget.tier.title,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scoreColor,
                              fontSize: 12.5.sp,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
