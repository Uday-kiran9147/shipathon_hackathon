import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Ultra-Craft Vector Illustration: Interactive Flop vs Pre-Flight Outlier Simulator
/// Allows creators to drag their finger across the 30-second timeline to see exact retention mechanics.
class FlopVsOutlierIllustration extends StatefulWidget {
  const FlopVsOutlierIllustration({super.key});

  @override
  State<FlopVsOutlierIllustration> createState() =>
      _FlopVsOutlierIllustrationState();
}

class _FlopVsOutlierIllustrationState extends State<FlopVsOutlierIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnim;
  double _scrubX = 0.46; // Scrubber position from 0.0 to 1.0 (approx 0:14)

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
    _progressAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scrubSec = (_scrubX * 30).clamp(0, 30).toInt();
    final timeStr = '0:${scrubSec.toString().padLeft(2, '0')}';

    // Calculate retention at scrub position
    final flopRetention = (100 - (_scrubX * 82) - (_scrubX > 0.4 ? 12 : 0))
        .clamp(14, 98)
        .toInt();
    final outlierRetention =
        (98 - (_scrubX * 14)).clamp(78, 98).toInt();

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
            // Ambient subtle mesh background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.surface,
                      AppColors.surfaceSubtle.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Background grid lines & timecode marks
            Positioned.fill(
              child: CustomPaint(
                painter: _GridBackgroundPainter(),
              ),
            ),

            // Animated retention curves with area gradients
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _progressAnim,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _RetentionCurvesPainter(
                      progress: _progressAnim.value,
                      scrubX: _scrubX,
                    ),
                  );
                },
              ),
            ),

            // Top Status Bar: Live Telemetry
            Positioned(
              left: 14.w,
              top: 12.h,
              right: 14.w,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: AppColors.primarySubtle,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Icon(Icons.touch_app_rounded,
                              size: 11.sp, color: AppColors.primary),
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            'DRAG TIMELINE TO AUDIT',
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMuted,
                              letterSpacing: 0.6,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: AppColors.textInk,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      'T: $timeStr',
                      style: AppTypography.monoTimestamp.copyWith(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Floating Dynamic Insight Bubble at Scrubber
            Positioned(
              left: (MediaQuery.of(context).size.width * _scrubX - 50.w)
                  .clamp(14.w, 200.w),
              top: 40.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: _scrubX > 0.4
                        ? AppColors.hazardRubyBorder
                        : AppColors.outlierJadeBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.w,
                          decoration: const BoxDecoration(
                            color: AppColors.outlierJade,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Prevue: $outlierRetention% retained',
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.outlierJade,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.w,
                          decoration: const BoxDecoration(
                            color: AppColors.hazardRuby,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Flop: $flopRetention% retained',
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.hazardRuby,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Badges: Flop vs Prevue
            Positioned(
              left: 14.w,
              bottom: 12.h,
              child: _buildBadge(
                icon: Icons.trending_down_rounded,
                label: '15h Wasted Flop',
                sub: '2.1% CTR • 0:14 Drop-off',
                color: AppColors.hazardRuby,
                bgColor: AppColors.hazardRubySubtle,
                borderColor: AppColors.hazardRubyBorder,
              ),
            ),

            Positioned(
              right: 14.w,
              bottom: 12.h,
              child: _buildBadge(
                icon: Icons.rocket_launch_rounded,
                label: 'Prevue Outlier',
                sub: '3.4x Velocity • 8.9 CTR',
                color: AppColors.outlierJade,
                bgColor: AppColors.outlierJadeSubtle,
                borderColor: AppColors.outlierJadeBorder,
              ),
            ),

            // Interactive Gesture Detector for scrubbing
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (details) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox != null) {
                    final local = details.localPosition;
                    setState(() {
                      _scrubX = (local.dx / renderBox.size.width)
                          .clamp(0.08, 0.92);
                    });
                  }
                },
                onTapDown: (details) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox != null) {
                    final local = details.localPosition;
                    setState(() {
                      _scrubX = (local.dx / renderBox.size.width)
                          .clamp(0.08, 0.92);
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: borderColor, width: 1.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14.sp),
          SizedBox(width: 6.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 10.sp,
                ),
              ),
              Text(
                sub,
                style: AppTypography.bodySmall.copyWith(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 8.5.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderSubtle
      ..strokeWidth = 1.0;

    // Horizontal grid lines
    const int rows = 4;
    for (int i = 1; i <= rows; i++) {
      final y = size.height * (i / (rows + 1));
      canvas.drawLine(Offset(14.w, y), Offset(size.width - 14.w, y), paint);
    }

    // Vertical timecode marks
    const int cols = 6;
    for (int i = 0; i <= cols; i++) {
      final x = 14.w + (size.width - 28.w) * (i / cols);
      canvas.drawLine(Offset(x, 30.h), Offset(x, size.height - 40.h), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RetentionCurvesPainter extends CustomPainter {
  final double progress;
  final double scrubX;

  _RetentionCurvesPainter({
    required this.progress,
    required this.scrubX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // 1. Red Flop Curve with Gradient Area Fill
    final flopPath = Path();
    flopPath.moveTo(14.w, height * 0.38);
    flopPath.cubicTo(
      width * 0.28,
      height * 0.40,
      width * 0.42,
      height * 0.82,
      width * progress.clamp(0.5, 0.94),
      height * 0.84,
    );

    final flopFillPath = Path.from(flopPath);
    flopFillPath.lineTo(width * progress.clamp(0.5, 0.94), height - 40.h);
    flopFillPath.lineTo(14.w, height - 40.h);
    flopFillPath.close();

    final flopFillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.hazardRuby.withValues(alpha: 0.12),
          AppColors.hazardRuby.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(flopFillPath, flopFillPaint);

    final flopPaint = Paint()
      ..color = AppColors.hazardRuby
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8.w
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(flopPath, flopPaint);

    // 2. Green Outlier Curve with Glow and Area Fill
    final outlierPath = Path();
    outlierPath.moveTo(14.w, height * 0.36);
    outlierPath.cubicTo(
      width * 0.3,
      height * 0.32,
      width * 0.6,
      height * 0.20,
      width * (progress * 0.94).clamp(0.2, 0.94),
      height * 0.16,
    );

    final outlierFillPath = Path.from(outlierPath);
    outlierFillPath.lineTo(
        width * (progress * 0.94).clamp(0.2, 0.94), height - 40.h);
    outlierFillPath.lineTo(14.w, height - 40.h);
    outlierFillPath.close();

    final outlierFillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.outlierJade.withValues(alpha: 0.18),
          AppColors.outlierJade.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(outlierFillPath, outlierFillPaint);

    final outlierGlow = Paint()
      ..color = AppColors.outlierJade.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.w
      ..strokeCap = StrokeCap.round;

    final outlierPaint = Paint()
      ..color = AppColors.outlierJade
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2.w
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(outlierPath, outlierGlow);
    canvas.drawPath(outlierPath, outlierPaint);

    // 3. Interactive Vertical Scrubber Line
    final scrubberX = (width * scrubX).clamp(14.w, width - 14.w);

    final scrubberPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1.8.w;

    canvas.drawLine(
        Offset(scrubberX, 28.h), Offset(scrubberX, height - 40.h), scrubberPaint);

    // Scrubber Knob
    final knobOuter = Paint()..color = AppColors.primary;
    final knobInner = Paint()..color = Colors.white;

    canvas.drawCircle(Offset(scrubberX, height - 40.h), 6.r, knobOuter);
    canvas.drawCircle(Offset(scrubberX, height - 40.h), 3.r, knobInner);
  }

  @override
  bool shouldRepaint(covariant _RetentionCurvesPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.scrubX != scrubX;
}
