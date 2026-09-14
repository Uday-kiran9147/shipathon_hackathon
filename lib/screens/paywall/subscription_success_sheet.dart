import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/subscription_state.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/common/solid_heavy_button.dart';

// ── Confetti ──────────────────────────────────────────────────────────────────

class _Particle {
  final double x;       // 0..1 horizontal start
  final double speed;   // relative fall speed
  final double size;
  final Color color;
  final double rotation;
  final bool isRect;    // rect or circle

  const _Particle({
    required this.x,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotation,
    required this.isRect,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;   // 0..1 from repeating animation
  final List<_Particle> particles;

  const _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      // Each particle falls at its own speed phase
      final t = ((progress * p.speed) % 1.0);
      final x = p.x * size.width + math.sin(t * math.pi * 2 + p.rotation) * 18;
      final y = t * (size.height + 40) - 20;
      final opacity = (1.0 - (t * t)).clamp(0.0, 1.0);

      paint.color = p.color.withValues(alpha: opacity * 0.85);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * math.pi * 4 * (p.isRect ? 1 : -1));

      if (p.isRect) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.size * 0.5, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

// ── Sheet ─────────────────────────────────────────────────────────────────────

class SubscriptionSuccessSheet extends StatefulWidget {
  const SubscriptionSuccessSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<SubscriptionProvider>(),
        child: const SubscriptionSuccessSheet(),
      ),
    );
  }

  @override
  State<SubscriptionSuccessSheet> createState() =>
      _SubscriptionSuccessSheetState();
}

class _SubscriptionSuccessSheetState extends State<SubscriptionSuccessSheet>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _confettiCtrl;
  late final AnimationController _pulseCtrl;

  // Entry animations (staggered)
  late final Animation<double> _badgeScale;
  late final Animation<double> _badgeFade;
  late final Animation<double> _headlineSlide;
  late final Animation<double> _headlineFade;
  late final Animation<double> _cardSlide;
  late final Animation<double> _cardFade;
  late final Animation<double> _ctaSlide;
  late final Animation<double> _ctaFade;

  // Badge glow pulse
  late final Animation<double> _glowPulse;

  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    // Entry: drives all staggered reveals
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));

    _badgeScale = CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.45, curve: Curves.elasticOut));
    _badgeFade = CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut));
    _headlineSlide = CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.25, 0.6, curve: Curves.easeOutCubic));
    _headlineFade = CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.25, 0.55, curve: Curves.easeOut));
    _cardSlide = CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.45, 0.8, curve: Curves.easeOutCubic));
    _cardFade = CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOut));
    _ctaSlide = CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOutCubic));
    _ctaFade = CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.65, 0.95, curve: Curves.easeOut));

    // Confetti: repeating loop
    _confettiCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat();

    // Badge glow pulse: repeating
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _glowPulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _particles = _buildParticles();
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _confettiCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  List<_Particle> _buildParticles() {
    final rng = math.Random(42);
    final colors = [
      AppColors.proGold,
      AppColors.outlierJade,
      const Color(0xFFFF6B6B),
      const Color(0xFFFFD93D),
      const Color(0xFF6BCB77),
      Colors.white,
      const Color(0xFFFF9F45),
    ];
    return List.generate(40, (i) => _Particle(
      x: rng.nextDouble(),
      speed: 0.4 + rng.nextDouble() * 0.6,
      size: 5 + rng.nextDouble() * 8,
      color: colors[rng.nextInt(colors.length)],
      rotation: rng.nextDouble() * math.pi * 2,
      isRect: rng.nextBool(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();
    final state = sub.state;
    final isTrial = state.status == SubscriptionStatus.trial;
    final planLabel = _planLabel(state);

    return Container(
      constraints: BoxConstraints(maxHeight: 0.93.sh),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Stack(
        children: [
          // ── Confetti overlay ────────────────────────────────────────────────
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confettiCtrl,
                  builder: (ctx, child) => CustomPaint(
                    painter: _ConfettiPainter(
                      progress: _confettiCtrl.value,
                      particles: _particles,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 20.h),
              child: Column(
                children: [
                  // Badge
                  ScaleTransition(
                    scale: _badgeScale,
                    child: FadeTransition(
                      opacity: _badgeFade,
                      child: AnimatedBuilder(
                        animation: _glowPulse,
                        builder: (_, child) => Container(
                          width: 96.w,
                          height: 96.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.proShimmerGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.proGoldAccent.withValues(
                                    alpha: 0.25 + _glowPulse.value * 0.45),
                                blurRadius: 20 + _glowPulse.value * 30,
                                spreadRadius: _glowPulse.value * 8,
                              ),
                            ],
                          ),
                          child: Icon(Icons.workspace_premium_rounded,
                              color: Colors.white, size: 48.sp),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 22.h),

                  // Headline
                  FadeTransition(
                    opacity: _headlineFade,
                    child: SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, 0.25), end: Offset.zero)
                          .animate(_headlineSlide),
                      child: Column(
                        children: [
                          Text(
                            isTrial
                                ? '🎉 Your Free Trial is Live!'
                                : '🚀 Welcome to Creator Pro!',
                            style: AppTypography.displayMedium.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            isTrial
                                ? '${AppConstants.freeTrialDays} days free, then $planLabel. '
                                  'Cancel anytime before your trial ends.'
                                : 'You now have unlimited pre-flight intelligence. '
                                  'Stop guessing, start knowing.',
                            style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary, height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Unlocked card
                  FadeTransition(
                    opacity: _cardFade,
                    child: SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, 0.3), end: Offset.zero)
                          .animate(_cardSlide),
                      child: _UnlockedCard(),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Trial countdown
                  if (isTrial && state.trialEndsAt != null) ...[
                    FadeTransition(
                      opacity: _cardFade,
                      child: SlideTransition(
                        position: Tween<Offset>(
                                begin: const Offset(0, 0.3), end: Offset.zero)
                            .animate(_cardSlide),
                        child: _TrialCountdownBanner(endsAt: state.trialEndsAt!),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],

                  // CTA
                  FadeTransition(
                    opacity: _ctaFade,
                    child: SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, 0.3), end: Offset.zero)
                          .animate(_ctaSlide),
                      child: Column(
                        children: [
                          SolidHeavyButton(
                            label: 'Start Creating',
                            height: 56.h,
                            fontSize: 16.sp,
                            isLoading: false,
                            onPressed: () => Navigator.pop(context),
                          ),
                          SizedBox(height: 10.h),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Go to subscription settings',
                                style: AppTypography.labelSmall
                                    .copyWith(color: AppColors.textMuted)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _planLabel(SubscriptionState s) {
    if (s.productId == null) return '${AppConstants.priceMonthly}/mo';
    if (s.productId!.toLowerCase().contains('annual')) {
      return '${AppConstants.priceAnnual}/yr';
    }
    return '${AppConstants.priceMonthly}/mo';
  }
}

// ── Unlocked features card ────────────────────────────────────────────────────

class _UnlockedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final features = [
      (Icons.all_inclusive_rounded, 'Unlimited Simulations',
          'Run as many pre-flights as you need'),
      (Icons.timeline_rounded, 'Retention Hazard Timeline',
          'See every drop-off moment before you record'),
      (Icons.auto_fix_high_rounded, 'AI Prescriptive Fixes',
          '3 targeted script improvements per simulation'),
      (Icons.hub_rounded, 'Multi-Channel Workspace',
          'Manage all your channels in one place'),
      (Icons.trending_up_rounded, 'Channel Outlier Predictor',
          '3× view benchmark against your history'),
    ];

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.proGoldSubtle, AppColors.outlierJadeSubtle],
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.proGoldAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_open_rounded,
                  size: 16.sp, color: AppColors.proGold),
              SizedBox(width: 6.w),
              Text('All unlocked for you',
                  style: AppTypography.labelSmall.copyWith(
                      color: AppColors.proGold, fontWeight: FontWeight.w800)),
            ],
          ),
          SizedBox(height: 14.h),
          ...features.map((f) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(7.w),
                      decoration: BoxDecoration(
                        color: AppColors.outlierJade.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(f.$1, size: 16.sp, color: AppColors.outlierJade),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.$2,
                              style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5.sp)),
                          Text(f.$3,
                              style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.sp)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Trial countdown banner ────────────────────────────────────────────────────

class _TrialCountdownBanner extends StatelessWidget {
  final DateTime endsAt;
  const _TrialCountdownBanner({required this.endsAt});

  @override
  Widget build(BuildContext context) {
    final daysLeft = endsAt.difference(DateTime.now()).inDays.clamp(0, 99);
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr = '${months[endsAt.month]} ${endsAt.day}';

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.proGoldSubtle,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.proGoldAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.proGoldAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.hourglass_top_rounded,
                size: 18.sp, color: AppColors.proGold),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$daysLeft day${daysLeft == 1 ? '' : 's'} left in your trial',
                    style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800, color: AppColors.proGold)),
                Text('Trial ends $dateStr. Cancel before then and pay nothing.',
                    style: AppTypography.bodySmall.copyWith(
                        color: AppColors.proGold.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
