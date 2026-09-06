import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Octagonal performance radar chart — 8 evaluation dimensions, animated
/// polygon growth with easeOutBack, gradient fill keyed to score tier.
class PerformanceRadar extends StatefulWidget {
  final double hookStrength;
  final double audienceResonance;
  final double novelty;
  final double topicMomentum;
  final double clarity;
  final double pacing;
  final double creatorFit;
  final double authenticityScore;
  final Color tierColor;

  const PerformanceRadar({
    super.key,
    required this.hookStrength,
    required this.audienceResonance,
    required this.novelty,
    required this.topicMomentum,
    required this.clarity,
    required this.pacing,
    required this.creatorFit,
    this.authenticityScore = 0.0,
    required this.tierColor,
  });

  @override
  State<PerformanceRadar> createState() => _PerformanceRadarState();
}

class _PerformanceRadarState extends State<PerformanceRadar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant PerformanceRadar old) {
    super.didUpdateWidget(old);
    _controller
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scores = [
      widget.hookStrength / 10.0,
      widget.audienceResonance / 10.0,
      widget.novelty / 10.0,
      widget.topicMomentum / 10.0,
      widget.clarity / 10.0,
      widget.pacing / 10.0,
      widget.creatorFit / 10.0,
      (widget.authenticityScore > 0 ? widget.authenticityScore : 7.5) / 10.0,
    ];

    const labels = [
      'HOOK',
      'RESONANCE',
      'NOVELTY',
      'MOMENTUM',
      'CLARITY',
      'PACING',
      'CREATOR FIT',
      'AUTHENTICITY',
    ];

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return CustomPaint(
          painter: _RadarPainter(
            scores: scores,
            labels: labels,
            progress: _anim.value.clamp(0.0, 1.08),
            tierColor: widget.tierColor,
          ),
          size: Size(double.infinity, 250.h),
        );
      },
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<double> scores;
  final List<String> labels;
  final double progress;
  final Color tierColor;

  const _RadarPainter({
    required this.scores,
    required this.labels,
    required this.progress,
    required this.tierColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final maxRadius = math.min(size.width / 2, size.height / 2) * 0.60;
    const n = 8;
    const startAngle = -math.pi / 2; // top

    // --- Grid rings ---
    for (int ring = 1; ring <= 4; ring++) {
      final r = maxRadius * ring / 4;
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring == 4 ? 1.2 : 0.8
        ..color = ring == 4
            ? const Color(0xFFCBD5E1).withValues(alpha: 0.95)
            : const Color(0xFFE2E8F0).withValues(alpha: 0.6);
      final pts = _axisPoints(center, r, n, startAngle);
      canvas.drawPath(_closedPath(pts), ringPaint);
    }

    // --- Axis lines ---
    final axisPaint = Paint()
      ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.5)
      ..strokeWidth = 1.0;
    for (int i = 0; i < n; i++) {
      final angle = startAngle + 2 * math.pi * i / n;
      canvas.drawLine(
        center,
        Offset(cx + maxRadius * math.cos(angle), cy + maxRadius * math.sin(angle)),
        axisPaint,
      );
    }

    // --- Data polygon ---
    final dataPts = List.generate(n, (i) {
      final angle = startAngle + 2 * math.pi * i / n;
      final rClamped = maxRadius * (scores[i].clamp(0.0, 1.0) * progress).clamp(0.0, 1.0);
      return Offset(cx + rClamped * math.cos(angle), cy + rClamped * math.sin(angle));
    });

    final fillPath = _closedPath(dataPts);

    // Glow under polygon
    canvas.drawPath(
      fillPath,
      Paint()
        ..color = tierColor.withValues(alpha: 0.16)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Gradient fill — always red-tinted regardless of semantic tier
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = RadialGradient(
          colors: [
            tierColor.withValues(alpha: 0.40),
            tierColor.withValues(alpha: 0.05),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
        ..style = PaintingStyle.fill,
    );

    // Stroke outline
    canvas.drawPath(
      fillPath,
      Paint()
        ..color = tierColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round,
    );

    // Dot markers — white ring + brand color center
    for (final pt in dataPts) {
      canvas.drawCircle(pt, 7.0, Paint()
        ..color = tierColor.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      canvas.drawCircle(pt, 5.0, Paint()..color = Colors.white);
      canvas.drawCircle(pt, 3.5, Paint()..color = tierColor);
    }

    // --- Axis labels with score values ---
    for (int i = 0; i < n; i++) {
      final angle = startAngle + 2 * math.pi * i / n;
      final labelR = maxRadius + 22.0;
      final lx = cx + labelR * math.cos(angle);
      final ly = cy + labelR * math.sin(angle);

      // Dimension name
      final namePainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: const Color(0xFF64748B),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 66);

      namePainter.paint(canvas, Offset(lx - namePainter.width / 2, ly - namePainter.height / 2));
    }
  }

  List<Offset> _axisPoints(Offset center, double r, int n, double startAngle) {
    return List.generate(n, (i) {
      final a = startAngle + 2 * math.pi * i / n;
      return Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
    });
  }

  Path _closedPath(List<Offset> pts) {
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.progress != progress || old.tierColor != tierColor || old.scores != scores;
}
