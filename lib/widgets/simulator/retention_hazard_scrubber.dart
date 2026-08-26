import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/simulation_result.dart';
import '../common/tactile_card.dart';

/// Interactive 30-Second Retention Hazard Timeline Scrubber
class RetentionHazardScrubber extends StatefulWidget {
  final List<RetentionHazard> hazards;
  final String script;

  const RetentionHazardScrubber({
    super.key,
    required this.hazards,
    required this.script,
  });

  @override
  State<RetentionHazardScrubber> createState() => _RetentionHazardScrubberState();
}

class _RetentionHazardScrubberState extends State<RetentionHazardScrubber> {
  int _currentSecond = 14; // Default to first flagged hazard point

  @override
  Widget build(BuildContext context) {
    // Find if current second falls in any hazard
    RetentionHazard? activeHazard;
    for (final h in widget.hazards) {
      if (_currentSecond >= h.startSeconds && _currentSecond <= h.endSeconds) {
        activeHazard = h;
        break;
      }
    }

    return TactileCard(
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Safely constrained)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.timer_rounded,
                        size: 18.sp, color: AppColors.hazardRuby),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        '30-SEC DROP-OFF CHECK',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textInk,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.sp,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: widget.hazards.isEmpty
                      ? AppColors.outlierJadeSubtle
                      : AppColors.hazardRubySubtle,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: widget.hazards.isEmpty
                        ? AppColors.outlierJadeBorder
                        : AppColors.hazardRubyBorder,
                  ),
                ),
                child: Text(
                  widget.hazards.isEmpty
                      ? '✓ NO DROP-OFF'
                      : '${widget.hazards.length} DROP-OFF RISKS',
                  style: AppTypography.labelSmall.copyWith(
                    color: widget.hazards.isEmpty
                        ? AppColors.outlierJade
                        : AppColors.hazardRuby,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Custom Timeline Scrubber
          Column(
            children: [
              // Waveform / Retention Bars
              SizedBox(
                height: 48.h,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totalWidth = constraints.maxWidth;
                    const totalSeconds = 30;

                    return Stack(
                      children: [
                        // Background retention baseline curve
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(totalSeconds, (sec) {
                            final inHazard = widget.hazards.any(
                                (h) => sec >= h.startSeconds && sec <= h.endSeconds);

                            // Retention curve calculation (drops off during hazard)
                            double heightRatio = 0.85 - (sec * 0.012);
                            if (inHazard) {
                              heightRatio -= 0.35; // Visual drop-off dip
                            }
                            heightRatio = heightRatio.clamp(0.2, 0.95);

                            final isCurrent = sec == _currentSecond;

                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _currentSecond = sec),
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 1.w),
                                  height: 48.h * heightRatio,
                                  decoration: BoxDecoration(
                                    color: inHazard
                                        ? AppColors.hazardRuby.withValues(
                                            alpha: isCurrent ? 1.0 : 0.6)
                                        : AppColors.primary.withValues(
                                            alpha: isCurrent ? 1.0 : 0.3),
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        // Current Scrubber Pointer
                        Positioned(
                          left: (_currentSecond / 30.0) * totalWidth - 6.w,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 12.w,
                            decoration: BoxDecoration(
                              color: AppColors.textInk,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 8.h),
              // Time Labels (Responsive & readable)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0:00 (Hook)',
                      style: AppTypography.monoTimestamp.copyWith(fontSize: 11.sp)),
                  Text(
                    '0:${_currentSecond.toString().padLeft(2, '0')}',
                    style: AppTypography.monoTimestamp.copyWith(
                      color: activeHazard != null
                          ? AppColors.hazardRuby
                          : AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.sp,
                    ),
                  ),
                  Text('0:30 (Cutoff)',
                      style: AppTypography.monoTimestamp.copyWith(fontSize: 11.sp)),
                ],
              ),
              // Slider for continuous touch scrub
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3.h,
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.borderLight,
                  thumbColor: AppColors.textInk,
                  overlayColor: AppColors.primary.withValues(alpha: 0.1),
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
                ),
                child: Slider(
                  value: _currentSecond.toDouble(),
                  min: 0,
                  max: 30,
                  divisions: 30,
                  onChanged: (val) => setState(() => _currentSecond = val.round()),
                ),
              ),
            ],
          ),

          // Active Hazard Breakdown Card
          if (activeHazard != null) ...[
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.hazardRubySubtle,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.hazardRubyBorder, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 16.sp, color: AppColors.hazardRuby),
                            SizedBox(width: 6.w),
                            Flexible(
                              child: Text(
                                'DROP-OFF SPOT: ${activeHazard.timestampRange}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.hazardRuby,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11.sp,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.hazardRuby,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          '${activeHazard.dropOffRiskPercentage}% DROP-OFF',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    activeHazard.title,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textInk,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    activeHazard.explanation,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                      fontSize: 12.5.sp,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.outlierJadeSubtle,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.outlierJadeBorder, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 15.sp, color: AppColors.outlierJade),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Pacing at 0:${_currentSecond.toString().padLeft(2, '0')} maintains strong viewer retention.',
                      style: AppTypography.bodySmall.copyWith(
                        color: const Color(0xFF065F46),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
