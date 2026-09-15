import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
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
      await sub.presentPaywall(context);
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

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();

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
                child: sub.isPro
                    ? _AlreadySubscribedBody(state: sub.state)
                    : _PurchaseBody(
                        isAnnual: _isAnnual,
                        onPlanChanged: (value) =>
                            setState(() => _isAnnual = value),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseBody extends StatelessWidget {
  final bool isAnnual;
  final ValueChanged<bool> onPlanChanged;

  const _PurchaseBody({
    required this.isAnnual,
    required this.onPlanChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();

    return Column(
      children: [
        SizedBox(height: 8.h),
        _LogoBadge(),
        SizedBox(height: 16.h),
        Text(
          'Unlock Creator Pro',
          textAlign: TextAlign.center,
          style: AppTypography.displayMedium.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Unlimited simulations and advanced creator intelligence.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 20.h),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(value: true, label: Text('Annual')),
            ButtonSegment<bool>(value: false, label: Text('Monthly')),
          ],
          selected: {isAnnual},
          onSelectionChanged: (selection) => onPlanChanged(selection.first),
        ),
        SizedBox(height: 16.h),
        Text(
          isAnnual ? AppConstants.priceAnnual : AppConstants.priceMonthly,
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 16.h),
        SolidHeavyButton(
          label: isAnnual ? 'Start Annual Plan' : 'Start Monthly Plan',
          height: 52.h,
          fontSize: 15.sp,
          isLoading: sub.isPurchasing,
          onPressed: sub.isPurchasing
              ? null
              : () async {
                  final success = await sub.purchasePackage(isAnnual: isAnnual);
                  if (!context.mounted) return;
                  if (success) {
                    Navigator.pop(context);
                    await SubscriptionSuccessSheet.show(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Purchase could not be completed.'),
                      ),
                    );
                  }
                },
        ),
        SizedBox(height: 8.h),
        TextButton(
          onPressed: sub.isPurchasing
              ? null
              : () async {
                  final success = await sub.restorePurchases();
                  if (!context.mounted) return;
                  if (success) {
                    Navigator.pop(context);
                    await SubscriptionSuccessSheet.show(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No active subscription found.'),
                      ),
                    );
                  }
                },
          child: const Text('Restore Purchases'),
        ),
        SizedBox(height: 12.h),
      ],
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
