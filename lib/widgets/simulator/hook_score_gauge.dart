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
    this.noveltyScore = 7.9,
    this.topicMomentumScore = 8.6,
    this.pacingScore = 7.8,
    this.creatorFitScore = 9.0,
    required this.tier,
  });

  final double noveltyScore;
  final double topicMomentumScore;
  final double pacingScore;
  final double creatorFitScore;

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
    _scoreAnimation = Tween<double>(
      begin: 0.0,
      end: widget.score,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant HookScoreGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _scoreAnimation = Tween<double>(begin: oldWidget.score, end: widget.score)
          .animate(
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
          ratingText = '🌟 Top Outlier (High Retention)';
        } else if (currentScore >= 7.0) {
          ratingText = '👍 Strong Hook (Above Median)';
        } else if (currentScore >= 5.0) {
          ratingText = '⚖️ Average (Some Drop-off Expected)';
        } else {
          ratingText = '⚠️ High Drop-off Risk (Needs Fixes)';
        }

        return Container(
          padding: EdgeInsets.all(18.w),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PRE-FLIGHT SIMULATOR RADAR',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.sp,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          100.r,
                        ), // Capsule pill
                        border: Border.all(
                          color: scoreColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        widget.tier.multiplierLabel,
                        style: AppTypography.labelSmall.copyWith(
                          color: scoreColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              // Gauge Circular Dial
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 130.w,
                    height: 130.w,
                    child: CircularProgressIndicator(
                      value: currentScore / 10.0,
                      strokeWidth: 11.w,
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
                          fontSize: 34.sp,
                        ),
                      ),
                      Text(
                        'OVERALL SCORE / 10',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                ratingText,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scoreColor,
                  fontSize: 13.5.sp,
                ),
              ),
              SizedBox(height: 14.h),

              // Multi-Dimensional Radar Dimensions Grid (Section 7)
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    _buildDimensionRow(
                      'Hook Strength',
                      currentScore,
                      scoreColor,
                    ),
                    SizedBox(height: 6.h),
                    _buildDimensionRow(
                      'Audience Resonance',
                      widget.resonanceScore,
                      AppColors.primary,
                    ),
                    SizedBox(height: 6.h),
                    _buildDimensionRow(
                      'Novelty',
                      widget.noveltyScore,
                      AppColors.primaryDark,
                    ),
                    SizedBox(height: 6.h),
                    _buildDimensionRow(
                      'Pacing',
                      widget.pacingScore,
                      AppColors.warningAmber,
                    ),
                    SizedBox(height: 6.h),
                    _buildDimensionRow(
                      'Creator Fit',
                      widget.creatorFitScore,
                      AppColors.outlierJade,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDimensionRow(String label, double val, Color barColor) {
    return Row(
      children: [
        SizedBox(
          width: 110.w,
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 11.sp,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: (val / 10.0).clamp(0.0, 1.0),
              minHeight: 6.h,
              backgroundColor: AppColors.surfaceSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        SizedBox(
          width: 28.w,
          child: Text(
            val.toStringAsFixed(1),
            textAlign: TextAlign.end,
            style: AppTypography.monoScoreMedium.copyWith(
              fontSize: 11.5.sp,
              color: AppColors.textInk,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
