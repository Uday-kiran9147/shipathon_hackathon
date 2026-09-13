import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/simulation_result.dart';
import 'performance_radar.dart';

/// Pre-Flight Score Card
/// Prevue brand: Red × Black × White
/// Design language: large stat-number hero · editorial grid · dark pill badge
class HookScoreGauge extends StatefulWidget {
  final double score;
  final double resonanceScore;
  final double noveltyScore;
  final double topicMomentumScore;
  final double clarityScore;
  final double pacingScore;
  final double creatorFitScore;
  final double authenticityScore;
  final PerformanceTier tier;

  const HookScoreGauge({
    super.key,
    required this.score,
    required this.resonanceScore,
    this.noveltyScore = 7.9,
    this.topicMomentumScore = 8.6,
    this.clarityScore = 8.9,
    this.pacingScore = 7.8,
    this.creatorFitScore = 9.0,
    this.authenticityScore = 0.0,
    required this.tier,
  });

  @override
  State<HookScoreGauge> createState() => _HookScoreGaugeState();
}

class _HookScoreGaugeState extends State<HookScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scoreAnim;
  late Animation<double> _arcAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scoreAnim = Tween<double>(begin: 0.0, end: widget.score)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _arcAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant HookScoreGauge old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _scoreAnim = Tween<double>(begin: old.score, end: widget.score)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
      _ctrl..reset()..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Semantic color only for the tier label text — not for the arc
  Color _tierColor(double s) {
    if (s >= 8.0) return AppColors.outlierJade;
    if (s >= 6.0) return AppColors.warningAmber;
    return AppColors.hazardRuby;
  }

  String _tierEmoji(double s) {
    if (s >= 8.5) return '🚀';
    if (s >= 7.0) return '📈';
    if (s >= 5.0) return '⚖️';
    return '⚠️';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final current = _scoreAnim.value.clamp(0.0, 10.0);
        final tc = _tierColor(current);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: AppColors.cardElevation,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Red accent header bar ────────────────────────────────
              Container(
                padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 12.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(19.r)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.w,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'VIRALITY SCORE',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.sp,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'PRE-FLIGHT SIMULATOR',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w600,
                        fontSize: 9.5.sp,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 22.h),

                    // ── Hero score + 270° red arc ──────────────────────
                    Center(
                      child: SizedBox(
                        width: 190.w,
                        height: 190.w,
                        child: CustomPaint(
                          painter: _ArcPainter(
                            score: current,
                            progress: _arcAnim.value.clamp(0.0, 1.0),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: 14.h),
                                // Big black score number — editorial hero
                                Text(
                                  current.toStringAsFixed(1),
                                  style: AppTypography.monoScoreLarge.copyWith(
                                    color: AppColors.textInk,
                                    fontSize: 64.sp,
                                    height: 1.0,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'OUT OF 10',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 14.h),

                    // ── Dark pill tier badge (Twinkle-inspired dark CTA) ─
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(100.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _tierEmoji(current),
                              style: TextStyle(fontSize: 13.sp),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              widget.tier.title,
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12.sp,
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Container(
                              width: 1,
                              height: 11.h,
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                            SizedBox(width: 6.w),
                            Flexible(
                              child: Text(
                                widget.tier.multiplierLabel,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10.5.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 22.h),

                    // Divider
                    Container(height: 1, color: const Color(0xFFEEF1F6)),

                    SizedBox(height: 18.h),

                    // ── Dimension breakdown — editorial stat table ───────
                    // Inspired by Twinkle "5x | 96% | 2.5x" pattern
                    Row(
                      children: [
                        Container(
                          width: 2.5.w,
                          height: 13.h,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'BREAKDOWN',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.sp,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '8 DIMENSIONS',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    // Stat grid — 4 columns, 2 rows, table borders
                    _buildStatTable(tc),

                    SizedBox(height: 20.h),

                    // Divider
                    Container(height: 1, color: const Color(0xFFEEF1F6)),

                    SizedBox(height: 18.h),

                    // ── Performance Radar ────────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 2.5.w,
                          height: 13.h,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'PERFORMANCE RADAR',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.sp,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8.h),

                    PerformanceRadar(
                      hookStrength: widget.score,
                      audienceResonance: widget.resonanceScore,
                      novelty: widget.noveltyScore,
                      topicMomentum: widget.topicMomentumScore,
                      clarity: widget.clarityScore,
                      pacing: widget.pacingScore,
                      creatorFit: widget.creatorFitScore,
                      authenticityScore: widget.authenticityScore,
                      tierColor: AppColors.primary,
                    ),

                    SizedBox(height: 18.h),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatTable(Color tc) {
    final dims = [
      ('HOOK', widget.score),
      ('RESONANCE', widget.resonanceScore),
      ('NOVELTY', widget.noveltyScore),
      ('MOMENTUM', widget.topicMomentumScore),
      ('CLARITY', widget.clarityScore),
      ('PACING', widget.pacingScore),
      ('CREATOR FIT', widget.creatorFitScore),
      if (widget.authenticityScore > 0) ('AUTHENTICITY', widget.authenticityScore)
      else ('AUTH.', 7.5),
    ];

    const cols = 4;
    final rows = (dims.length / cols).ceil();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E9F0)),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: List.generate(rows, (row) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(cols, (col) {
                  final idx = row * cols + col;
                  final isLast = idx >= dims.length;
                  final dim = isLast ? null : dims[idx];
                  final isTopRow = row == 0;
                  final isLeftCol = col == 0;
                  final isHero = idx == 0;

                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isHero
                            ? AppColors.primaryDark
                            : AppColors.surface,
                        border: Border(
                          top: isTopRow
                              ? BorderSide.none
                              : const BorderSide(color: Color(0xFFE5E9F0)),
                          left: isLeftCol
                              ? BorderSide.none
                              : const BorderSide(color: Color(0xFFE5E9F0)),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 12.h,
                        horizontal: 6.w,
                      ),
                      child: dim == null
                          ? const SizedBox()
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dim.$2.toStringAsFixed(1),
                                  style: AppTypography.monoScoreLarge.copyWith(
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.w900,
                                    color: isHero
                                        ? Colors.white
                                        : AppColors.textInk,
                                    height: 1.0,
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                Text(
                                  dim.$1,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 8.sp,
                                    color: isHero
                                        ? Colors.white.withValues(alpha: 0.55)
                                        : AppColors.textMuted,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// 270° arc: Prevue Red fill on light grey track
class _ArcPainter extends CustomPainter {
  final double score;
  final double progress;

  const _ArcPainter({required this.score, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final radius = math.min(cx, cy) - 14;
    const strokeW = 14.0;

    // 270° gauge: 7-o'clock → 5-o'clock clockwise
    const startRad = 135.0 * math.pi / 180.0;
    const sweepRad = 270.0 * math.pi / 180.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    canvas.drawArc(
      rect, startRad, sweepRad, false,
      Paint()
        ..color = const Color(0xFFEEF1F6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );

    // Tick marks at 25/50/75
    final tickPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5;
    for (final frac in [0.25, 0.5, 0.75]) {
      final a = startRad + sweepRad * frac;
      canvas.drawLine(
        Offset(cx + (radius - strokeW - 2) * math.cos(a), cy + (radius - strokeW - 2) * math.sin(a)),
        Offset(cx + (radius + 0) * math.cos(a), cy + (radius + 0) * math.sin(a)),
        tickPaint,
      );
    }

    // Filled arc — Prevue Red
    final filledSweep = sweepRad * (score / 10.0).clamp(0.0, 1.0) * progress;
    if (filledSweep > 0.02) {
      canvas.drawArc(
        rect, startRad, filledSweep, false,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );

      // Tip glow
      final tipAngle = startRad + filledSweep;
      final tip = Offset(cx + radius * math.cos(tipAngle), cy + radius * math.sin(tipAngle));
      canvas.drawCircle(tip, 12, Paint()
        ..color = AppColors.primary.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawCircle(tip, 7, Paint()..color = Colors.white);
      canvas.drawCircle(tip, 5, Paint()..color = AppColors.primary);
    }

    // 0 and 10 end labels
    _label(canvas, '0', Offset(
      cx + (radius + 22) * math.cos(startRad),
      cy + (radius + 22) * math.sin(startRad),
    ));
    _label(canvas, '10', Offset(
      cx + (radius + 22) * math.cos(startRad + sweepRad),
      cy + (radius + 22) * math.sin(startRad + sweepRad),
    ));
  }

  void _label(Canvas canvas, String t, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(
        text: t,
        style: const TextStyle(
          color: Color(0xFF8592A6),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.score != score || old.progress != progress;
}
