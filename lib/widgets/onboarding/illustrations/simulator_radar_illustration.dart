import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Ultra-Craft Vector Illustration: Pre-Flight Radar HUD & Real-Time Stress Test
/// Shows 5-dimensional script stress-test with animated scanner beam, score telemetry, and hazard radar.
class SimulatorRadarIllustration extends StatefulWidget {
  final double hookScore;
  final bool isOptimized;

  const SimulatorRadarIllustration({
    super.key,
    this.hookScore = 8.9,
    this.isOptimized = true,
  });

  @override
  State<SimulatorRadarIllustration> createState() =>
      _SimulatorRadarIllustrationState();
}

class _SimulatorRadarIllustrationState extends State<SimulatorRadarIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHigh = widget.hookScore >= 7.5;
    final scoreColor = isHigh ? AppColors.outlierJade : AppColors.hazardRuby;
    final scoreBg =
        isHigh ? AppColors.outlierJadeSubtle : AppColors.hazardRubySubtle;
    final scoreBorder =
        isHigh ? AppColors.outlierJadeBorder : AppColors.hazardRubyBorder;

    return Container(
      width: double.infinity,
      height: 240.h,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.cardElevation,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: Stack(
          children: [
            // Radar Polygon Canvas with Sweeping Beam
            Positioned(
              left: 10.w,
              top: 14.h,
              bottom: 14.h,
              width: 190.w,
              child: AnimatedBuilder(
                animation: _scannerController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _RadarHudPainter(
                      sweepAngle: _scannerController.value * 2 * math.pi,
                      isOptimized: widget.isOptimized,
                    ),
                  );
                },
              ),
            ),

            // Telemetry Readout & Score Card (Right Side)
            Positioned(
              right: 14.w,
              top: 18.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Hook Score HUD Gauge
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: scoreBg,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: scoreBorder, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: scoreColor.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6.w,
                              height: 6.w,
                              decoration: BoxDecoration(
                                color: scoreColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              'HOOK CONVICTION',
                              style: AppTypography.labelSmall.copyWith(
                                color: scoreColor,
                                fontSize: 8.5.sp,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              widget.hookScore.toStringAsFixed(1),
                              style: AppTypography.monoScoreLarge.copyWith(
                                color: scoreColor,
                                fontSize: 28.sp,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              '/10',
                              style: AppTypography.monoTimestamp.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Dimension Metrics
                  _buildHudMetric(
                    label: 'Curiosity Gap',
                    value: widget.isOptimized ? '9.4' : '4.0',
                    color: isHigh ? AppColors.outlierJade : AppColors.hazardRuby,
                  ),
                  SizedBox(height: 5.h),
                  _buildHudMetric(
                    label: 'Speed to Value',
                    value: widget.isOptimized ? '8.8' : '3.8',
                    color: isHigh ? AppColors.outlierJade : AppColors.hazardRuby,
                  ),
                  SizedBox(height: 5.h),
                  _buildHudMetric(
                    label: 'Drop-off Risk',
                    value: widget.isOptimized ? 'Clear' : '0:14 Drop',
                    color: isHigh ? AppColors.outlierJade : AppColors.hazardRuby,
                  ),
                  SizedBox(height: 5.h),
                  _buildHudMetric(
                    label: 'Predicted Tier',
                    value: widget.isOptimized ? 'Top 10% Outlier' : 'Below Median',
                    color: isHigh ? AppColors.outlierJade : AppColors.hazardRuby,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHudMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 9.5.sp,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 6.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(5.r),
          ),
          child: Text(
            value,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontSize: 9.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _RadarHudPainter extends CustomPainter {
  final double sweepAngle;
  final bool isOptimized;

  _RadarHudPainter({
    required this.sweepAngle,
    required this.isOptimized,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.44;
    const int sides = 5;

    // 1. Concentric Background Rings
    final ringPaint = Paint()
      ..color = AppColors.borderSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int step = 1; step <= 3; step++) {
      final currentR = radius * (step / 3);
      canvas.drawCircle(center, currentR, ringPaint);
    }

    // 2. Sweeping Radar Beam
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          AppColors.primary.withValues(alpha: 0.0),
          AppColors.primary.withValues(alpha: 0.25),
        ],
        stops: const [0.0, 0.75, 1.0],
        transform: GradientRotation(sweepAngle),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, sweepPaint);

    // 3. 5-Axis Spokes
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * math.pi / sides) - (math.pi / 2);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), ringPaint);
    }

    // 4. Polygon Shape
    final targetValues = isOptimized
        ? [0.94, 0.88, 0.86, 0.96, 0.82]
        : [0.42, 0.38, 0.48, 0.36, 0.44];

    final polygonPath = Path();
    final color = isOptimized ? AppColors.outlierJade : AppColors.hazardRuby;

    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * math.pi / sides) - (math.pi / 2);
      final val = targetValues[i];
      final x = center.dx + (radius * val) * math.cos(angle);
      final y = center.dy + (radius * val) * math.sin(angle);
      if (i == 0) {
        polygonPath.moveTo(x, y);
      } else {
        polygonPath.lineTo(x, y);
      }
    }
    polygonPath.close();

    // Fill
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawPath(polygonPath, fillPaint);

    // Stroke
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2.w
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(polygonPath, strokePaint);

    // Vertex Nodes
    final nodeOuter = Paint()..color = color;
    final nodeInner = Paint()..color = Colors.white;
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * math.pi / sides) - (math.pi / 2);
      final val = targetValues[i];
      final x = center.dx + (radius * val) * math.cos(angle);
      final y = center.dy + (radius * val) * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 4.r, nodeOuter);
      canvas.drawCircle(Offset(x, y), 2.r, nodeInner);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarHudPainter oldDelegate) =>
      oldDelegate.sweepAngle != sweepAngle ||
      oldDelegate.isOptimized != isOptimized;
}
