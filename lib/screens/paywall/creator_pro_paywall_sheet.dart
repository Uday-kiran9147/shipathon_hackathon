import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/revenue_cat_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/subscription_state.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/common/solid_heavy_button.dart';
import '../subscription/subscription_management_screen.dart';
import 'cancel_subscription_sheet.dart';
import 'subscription_success_sheet.dart';

/// Paywall sheet — free → Pro conversion.
///
/// Priorities:
/// 1. Native RevenueCat paywall when a live offering with packages exists.
/// 2. Custom sheet (this widget) otherwise (mock/demo/no packages yet).
///
/// Prices come from [Package.storeProduct.priceString] when available,
/// falling back to the [AppConstants] display strings.
class CreatorProPaywallSheet extends StatefulWidget {
  const CreatorProPaywallSheet({super.key});

  /// Show the custom sheet directly.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<SubscriptionProvider>(),
        child: const CreatorProPaywallSheet(),
      ),
    );
  }

  /// Entry point for the PRO badge tap.
  ///
  /// - Already subscribed → custom sheet (already-subscribed view with manage/cancel).
  /// - Not subscribed, live RC offering → native RC paywall; success sheet only if
  ///   the user went from free → Pro during this session.
  /// - Not subscribed, no live offering → custom paywall sheet.
  static Future<void> present(BuildContext context) async {
    final sub = context.read<SubscriptionProvider>();
    // Already Pro → show the manage/cancel sheet, never the purchase paywall.
    if (sub.isPro) {
      await CreatorProPaywallSheet.show(context);
      return;
    }

    final rc = RevenueCatService();
    final hasLive = await rc.hasValidLiveOffering();
    if (!context.mounted) return;

    if (hasLive) {
      await rc.presentPaywall();
      if (!context.mounted) return;
      // Only show the success sheet if the purchase actually happened.
      await sub.refreshFromRevenueCat();
      if (!context.mounted) return;
      if (sub.isPro) {
        await SubscriptionSuccessSheet.show(context);
      }
    } else {
      await CreatorProPaywallSheet.show(context);
    }
  }

  @override
  State<CreatorProPaywallSheet> createState() => _CreatorProPaywallSheetState();
}

class _CreatorProPaywallSheetState extends State<CreatorProPaywallSheet> {
  bool _isAnnual = true;
  Package? _annualPkg;
  Package? _monthlyPkg;
  bool _loadingOfferings = true;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final offerings = await RevenueCatService().getOfferings();
    if (!mounted) return;
    setState(() {
      _annualPkg = _findPackage(offerings, annual: true);
      _monthlyPkg = _findPackage(offerings, annual: false);
      _loadingOfferings = false;
    });
  }

  Package? _findPackage(Offerings? offerings, {required bool annual}) {
    if (offerings == null) return null;
    final current = offerings.current;
    final ids = annual
        ? ['annual', r'$rc_annual', AppConstants.packageAnnual, 'creator_pro_annual', 'sub_annual']
        : ['monthly', r'$rc_monthly', AppConstants.packageMonthly, 'creator_pro_monthly', 'sub_monthly'];

    if (annual && current?.annual != null) return current!.annual;
    if (!annual && current?.monthly != null) return current!.monthly;

    for (final offering in offerings.all.values) {
      for (final pkg in offering.availablePackages) {
        if (ids.contains(pkg.identifier) ||
            ids.contains(pkg.packageType.name) ||
            ids.contains(pkg.storeProduct.identifier)) {
          return pkg;
        }
      }
    }
    return null;
  }

  String get _annualPrice =>
      _annualPkg?.storeProduct.priceString ?? AppConstants.priceAnnual;
  String get _monthlyPrice =>
      _monthlyPkg?.storeProduct.priceString ?? AppConstants.priceMonthly;

  String get _annualPerMonth {
    final annual = _annualPkg?.storeProduct.price;
    if (annual != null) {
      final pm = annual / 12;
      return '\$${pm.toStringAsFixed(2)}/mo';
    }
    return '${AppConstants.priceAnnualMonthlyEquivalent}/mo';
  }

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();
    final alreadyPro = sub.isPro;

    return Container(
      constraints: BoxConstraints(maxHeight: 0.92.sh),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HandleBar(),
            _CloseRow(),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: alreadyPro
                    ? _AlreadySubscribedBody(state: sub.state)
                    : _PurchaseBody(
                        isAnnual: _isAnnual,
                        onToggle: (v) => setState(() => _isAnnual = v),
                        annualPrice: _annualPrice,
                        monthlyPrice: _monthlyPrice,
                        annualPerMonth: _annualPerMonth,
                        annualSavings: AppConstants.annualSavingsPercentage,
                        loadingOfferings: _loadingOfferings,
                        subProvider: sub,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _HandleBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.only(top: 10.h, bottom: 4.h),
        width: 36.w,
        height: 4.h,
        decoration: BoxDecoration(
          color: AppColors.borderLight,
          borderRadius: BorderRadius.circular(2.r),
        ),
      );
}

class _CloseRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close_rounded, size: 20.sp, color: AppColors.textMuted),
            ),
          ],
        ),
      );
}

class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF0022).withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18.r),
              child: Image.asset(
                'assets/images/prevue_logo_v6.png',
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  color: const Color(0xFFFF0022),
                  child: const Center(
                    child: Icon(Icons.play_arrow_rounded, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -4.w,
            top: -4.h,
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                gradient: AppColors.proShimmerGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.proGoldAccent.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.workspace_premium_rounded,
                  color: Colors.white, size: 14.sp),
            ),
          ),
        ],
      );
}

// ─── Already subscribed state ────────────────────────────────────────────────

class _AlreadySubscribedBody extends StatelessWidget {
  final SubscriptionState state;
  const _AlreadySubscribedBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 8.h),
        _LogoBadge(),
        SizedBox(height: 16.h),
        Text('You\'re on Creator Pro',
            style: AppTypography.displayMedium
                .copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        SizedBox(height: 8.h),
        Text(
          _statusDescription(state),
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        SizedBox(height: 20.h),
        if (state.expiresAt != null) _RenewalRow(state: state),
        SizedBox(height: 20.h),
        SolidHeavyButton(
          label: 'Manage Subscription',
          height: 52.h,
          fontSize: 15.sp,
          isLoading: false,
          onPressed: () {
            Navigator.pop(context);
            SubscriptionManagementScreen.show(context);
          },
        ),
        SizedBox(height: 12.h),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close',
              style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted)),
        ),
        if (state.willRenew) ...[
          SizedBox(height: 4.h),
          TextButton(
            onPressed: () async {
              final confirmed = await CancelSubscriptionSheet.show(
                context,
                state: state,
              );
              if (!context.mounted) return;
              if (confirmed) await openSubscriptionStore(context);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text('Cancel Subscription',
                style: AppTypography.labelSmall.copyWith(
                    color: AppColors.hazardRuby)),
          ),
        ],
        SizedBox(height: 12.h),
      ],
    );
  }

  String _statusDescription(SubscriptionState s) {
    switch (s.status) {
      case SubscriptionStatus.trial:
        final d = s.trialEndsAt;
        return d != null
            ? 'Your free trial is active until ${_fmtDate(d)}.'
            : 'Your free trial is active.';
      case SubscriptionStatus.cancelledButActive:
        final d = s.expiresAt;
        return d != null
            ? 'Your subscription is cancelled and remains active until ${_fmtDate(d)}.'
            : 'Your subscription is cancelled but still active.';
      case SubscriptionStatus.billingIssue:
        return 'There\'s a billing issue with your subscription. Please update your payment method.';
      default:
        final d = s.expiresAt;
        return d != null && s.willRenew
            ? 'Your subscription renews automatically on ${_fmtDate(d)}.'
            : 'You have full access to all Pro features.';
    }
  }

  String _fmtDate(DateTime d) =>
      '${_month(d.month)} ${d.day}, ${d.year}';

  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

class _RenewalRow extends StatelessWidget {
  final SubscriptionState state;
  const _RenewalRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final d = state.expiresAt!;
    final label = state.willRenew ? 'Renews' : 'Expires';
    final dateStr =
        '${d.day} ${_month(d.month)} ${d.year}';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          Text(dateStr,
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

// ─── Purchase state ──────────────────────────────────────────────────────────

class _PurchaseBody extends StatelessWidget {
  final bool isAnnual;
  final void Function(bool) onToggle;
  final String annualPrice;
  final String monthlyPrice;
  final String annualPerMonth;
  final String annualSavings;
  final bool loadingOfferings;
  final SubscriptionProvider subProvider;

  const _PurchaseBody({
    required this.isAnnual,
    required this.onToggle,
    required this.annualPrice,
    required this.monthlyPrice,
    required this.annualPerMonth,
    required this.annualSavings,
    required this.loadingOfferings,
    required this.subProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 8.h),
        _LogoBadge(),
        SizedBox(height: 12.h),
        Text('Unlock Creator Pro',
            style: AppTypography.displayMedium.copyWith(
                fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        SizedBox(height: 4.h),
        Text(
          'Stop wasting 15 hours on flop videos. Simulate retention curves before hitting record.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        SizedBox(height: 20.h),
        _FeatureItem(
          icon: Icons.all_inclusive_rounded,
          title: 'Unlimited Pre-Flight Simulations',
          subtitle: 'Stress-test all weekly long-form & Shorts scripts.',
        ),
        _FeatureItem(
          icon: Icons.hub_rounded,
          title: 'Multi-Channel Workspace',
          subtitle: 'Seamlessly switch between all your YouTube channels.',
        ),
        _FeatureItem(
          icon: Icons.timeline_rounded,
          title: '30-Second Retention Hazard Timeline',
          subtitle: 'Pinpoint exact drop-off moments before recording.',
        ),
        _FeatureItem(
          icon: Icons.auto_fix_high_rounded,
          title: '3 Prescriptive AI Fixes & Re-Hooker',
          subtitle: '1-Click intro cuts and contrast hooks to lift score.',
        ),
        _FeatureItem(
          icon: Icons.trending_up_rounded,
          title: 'Channel Outlier Predictor (3.0× Views)',
          subtitle: 'Benchmark against your historical audience graph.',
        ),
        SizedBox(height: 20.h),
        _PricingToggle(
          isAnnual: isAnnual,
          onToggle: onToggle,
          annualPrice: annualPrice,
          monthlyPrice: monthlyPrice,
          annualPerMonth: annualPerMonth,
          annualSavings: annualSavings,
          loading: loadingOfferings,
        ),
        SizedBox(height: 20.h),
        SolidHeavyButton(
          label: 'Start ${AppConstants.freeTrialLabel}',
          height: 56.h,
          fontSize: 16.sp,
          isLoading: subProvider.isPurchasing,
          loadingText: 'Activating Creator Pro…',
          onPressed: () async {
            final success =
                await subProvider.purchasePackage(isAnnual: isAnnual);
            if (!context.mounted) return;
            if (success) {
              Navigator.pop(context);
              await SubscriptionSuccessSheet.show(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Purchase was cancelled or could not be completed.'),
              ));
            }
          },
        ),
        SizedBox(height: 12.h),
        Center(
          child: TextButton(
            onPressed: () async {
              final success = await subProvider.restorePurchases();
              if (!context.mounted) return;
              Navigator.pop(context);
              if (success) {
                await SubscriptionSuccessSheet.show(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('No active subscription found to restore.'),
                ));
              }
            },
            child: Text('Restore Purchases',
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.textMuted)),
          ),
        ),
        SizedBox(height: 10.h),
      ],
    );
  }
}

class _PricingToggle extends StatelessWidget {
  final bool isAnnual;
  final void Function(bool) onToggle;
  final String annualPrice;
  final String monthlyPrice;
  final String annualPerMonth;
  final String annualSavings;
  final bool loading;

  const _PricingToggle({
    required this.isAnnual,
    required this.onToggle,
    required this.annualPrice,
    required this.monthlyPrice,
    required this.annualPerMonth,
    required this.annualSavings,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SizedBox(
        height: 80.h,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return Row(
      children: [
        Expanded(child: _PlanCard(
          label: 'ANNUAL',
          price: annualPrice,
          sub: '$annualPerMonth billed yearly',
          badge: 'SAVE $annualSavings',
          selected: isAnnual,
          onTap: () => onToggle(true),
        )),
        SizedBox(width: 10.w),
        Expanded(child: _PlanCard(
          label: 'MONTHLY',
          price: monthlyPrice,
          sub: 'Billed monthly',
          selected: !isAnnual,
          onTap: () => onToggle(false),
        )),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String label;
  final String price;
  final String sub;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.label,
    required this.price,
    required this.sub,
    this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySubtle : AppColors.canvas,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: AppTypography.labelSmall.copyWith(
                        color: selected ? AppColors.primary : AppColors.textMuted,
                        fontWeight: FontWeight.w800)),
                if (badge != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: AppColors.outlierJade,
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                    child: Text(badge!,
                        style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(price,
                style: AppTypography.titleLarge
                    .copyWith(fontWeight: FontWeight.w800)),
            Text(sub,
                style: AppTypography.bodySmall
                    .copyWith(fontSize: 11.sp, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: const BoxDecoration(
                color: AppColors.outlierJadeSubtle, shape: BoxShape.circle),
            child: Icon(icon, size: 18.sp, color: AppColors.outlierJade),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5.sp,
                        color: AppColors.textInk)),
                SizedBox(height: 2.h),
                Text(subtitle,
                    style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary, fontSize: 12.5.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
