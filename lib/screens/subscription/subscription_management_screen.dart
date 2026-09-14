import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/subscription_state.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/common/solid_heavy_button.dart';
import '../paywall/cancel_subscription_sheet.dart';
import '../paywall/creator_pro_paywall_sheet.dart';

/// Full-screen subscription management page.
///
/// Actions available:
///   • Pro users: plan details, Manage in Store, Cancel Subscription, Restore
///   • Free users: feature list, Upgrade, Restore
class SubscriptionManagementScreen extends StatelessWidget {
  const SubscriptionManagementScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<SubscriptionProvider>(),
          child: const SubscriptionManagementScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: Text('Subscription',
            style: AppTypography.titleLarge
                .copyWith(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18.sp, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: Consumer<SubscriptionProvider>(
          builder: (context, sub, _) {
            if (sub.status == SubscriptionStatus.unknown) {
              return const Center(child: CircularProgressIndicator());
            }
            return _Body(sub: sub);
          },
        ),
      ),
    );
  }
}

// ── Store URL helpers ─────────────────────────────────────────────────────────

String _storeUrl() {
  if (!Platform.isIOS && !Platform.isAndroid) return '';
  return Platform.isIOS
      ? 'https://apps.apple.com/account/subscriptions'
      : 'https://play.google.com/store/account/subscriptions';
}

String _storeLabel() {
  if (!Platform.isIOS && !Platform.isAndroid) return 'Manage Subscription';
  return Platform.isIOS ? 'Manage in App Store' : 'Manage in Google Play';
}

Future<void> _openStore(BuildContext context) async {
  final url = _storeUrl();
  if (url.isEmpty) return;
  final uri = Uri.parse(url);
  final messenger = context.mounted ? ScaffoldMessenger.of(context) : null;
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    await Clipboard.setData(ClipboardData(text: url));
    messenger?.showSnackBar(SnackBar(
      content: Text('Couldn\'t open store. URL copied:\n$url',
          style: AppTypography.bodySmall.copyWith(color: Colors.white)),
      backgroundColor: AppColors.textPrimary,
      duration: const Duration(seconds: 4),
    ));
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatefulWidget {
  final SubscriptionProvider sub;
  const _Body({required this.sub});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  bool _restoringPurchases = false;

  SubscriptionProvider get sub => widget.sub;
  SubscriptionState get state => sub.state;
  bool get isPro => sub.isPro;

  // Show cancel only when the subscription is still set to renew
  bool get _canCancel =>
      state.willRenew &&
      (state.status == SubscriptionStatus.active ||
          state.status == SubscriptionStatus.trial);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      children: [
        _StatusCard(state: state),
        SizedBox(height: 20.h),
        if (isPro) ...[
          _PlanDetailsCard(state: state),
          SizedBox(height: 20.h),
          _ManageButton(),
          SizedBox(height: 12.h),
          _RestoreButton(
            loading: _restoringPurchases,
            onPressed: _handleRestore,
          ),
          if (_canCancel) ...[
            SizedBox(height: 24.h),
            _SectionLabel('Danger Zone'),
            SizedBox(height: 10.h),
            _CancelButton(
              state: state,
              onConfirmed: _handleCancelConfirmed,
            ),
          ],
          if (state.status == SubscriptionStatus.cancelledButActive) ...[
            SizedBox(height: 16.h),
            _AlreadyCancelledBanner(expiresAt: state.expiresAt),
          ],
        ] else ...[
          _FreeFeatureList(),
          SizedBox(height: 20.h),
          SolidHeavyButton(
            label: 'Upgrade to Creator Pro',
            height: 56.h,
            fontSize: 16.sp,
            isLoading: false,
            onPressed: () => CreatorProPaywallSheet.present(context),
          ),
          SizedBox(height: 12.h),
          _RestoreButton(
            loading: _restoringPurchases,
            onPressed: _handleRestore,
          ),
        ],
        SizedBox(height: 24.h),
        _LegalNote(),
      ],
    );
  }

  Future<void> _handleRestore() async {
    setState(() => _restoringPurchases = true);
    final success = await sub.restorePurchases();
    if (!mounted) return;
    setState(() => _restoringPurchases = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? 'Purchases restored! Welcome back to Pro.'
          : 'No active subscription found to restore.'),
      backgroundColor: success ? AppColors.outlierJade : null,
    ));
  }

  // Called after the user taps "Yes, Cancel" in the confirmation sheet.
  // We open the store — the actual cancellation happens there.
  // The RC webhook fires CANCELLATION → EXPIRATION to update our state.
  Future<void> _handleCancelConfirmed() async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await _openStore(context);
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(
      content: Text(
        'Cancel in the store subscription screen. Your access continues until the current period ends.',
      ),
      duration: Duration(seconds: 6),
    ));
  }
}

// ── Status card ───────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final SubscriptionState state;
  const _StatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final isPro = state.hasAccess;
    final statusColor = _statusColor(state.status);
    final bgColor = _statusBgColor(state.status);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon(state.status), color: statusColor, size: 24.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isPro ? 'Creator Pro' : 'Free Plan',
                    style: AppTypography.titleLarge
                        .copyWith(fontWeight: FontWeight.w800)),
                SizedBox(height: 2.h),
                Text(state.status.displayLabel,
                    style: AppTypography.bodySmall
                        .copyWith(color: statusColor, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100.r),
            ),
            child: Text(isPro ? 'ACTIVE' : 'FREE',
                style: AppTypography.labelSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.sp)),
          ),
        ],
      ),
    );
  }

  Color _statusColor(SubscriptionStatus s) {
    switch (s) {
      case SubscriptionStatus.trial:          return AppColors.proGoldAccent;
      case SubscriptionStatus.active:         return AppColors.outlierJade;
      case SubscriptionStatus.cancelledButActive: return AppColors.warningAmber;
      case SubscriptionStatus.billingIssue:   return AppColors.hazardRuby;
      case SubscriptionStatus.expired:        return AppColors.textMuted;
      default:                                return AppColors.primary;
    }
  }

  Color _statusBgColor(SubscriptionStatus s) {
    switch (s) {
      case SubscriptionStatus.trial:          return AppColors.proGoldSubtle;
      case SubscriptionStatus.active:         return AppColors.outlierJadeSubtle;
      case SubscriptionStatus.cancelledButActive: return AppColors.warningAmberSubtle;
      case SubscriptionStatus.billingIssue:   return AppColors.hazardRubySubtle;
      default:                                return AppColors.surface;
    }
  }

  IconData _statusIcon(SubscriptionStatus s) {
    switch (s) {
      case SubscriptionStatus.trial:          return Icons.hourglass_top_rounded;
      case SubscriptionStatus.active:         return Icons.workspace_premium_rounded;
      case SubscriptionStatus.cancelledButActive: return Icons.timer_outlined;
      case SubscriptionStatus.billingIssue:   return Icons.warning_amber_rounded;
      case SubscriptionStatus.expired:        return Icons.lock_outline_rounded;
      default:                                return Icons.person_outline_rounded;
    }
  }
}

// ── Plan details ──────────────────────────────────────────────────────────────

class _PlanDetailsCard extends StatelessWidget {
  final SubscriptionState state;
  const _PlanDetailsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final rows = <_DetailRow>[];

    if (state.productId != null) {
      rows.add(_DetailRow(label: 'Plan', value: _formatProductId(state.productId!)));
    }
    if (state.store != null) {
      rows.add(_DetailRow(label: 'Billed via', value: _formatStore(state.store!)));
    }
    if (state.status == SubscriptionStatus.trial && state.trialEndsAt != null) {
      rows.add(_DetailRow(
        label: 'Trial ends',
        value: _fmtDate(state.trialEndsAt!),
        highlight: AppColors.proGoldAccent,
      ));
    }
    if (state.expiresAt != null) {
      final label = state.willRenew ? 'Renews on' : 'Access until';
      rows.add(_DetailRow(
        label: label,
        value: _fmtDate(state.expiresAt!),
        highlight: state.willRenew ? null : AppColors.warningAmber,
      ));
    }
    if (state.status == SubscriptionStatus.cancelledButActive) {
      rows.add(_DetailRow(
        label: 'Status note',
        value: 'Cancelled — access remains until expiry',
        highlight: AppColors.warningAmber,
      ));
    }
    if (state.status == SubscriptionStatus.billingIssue) {
      rows.add(_DetailRow(
        label: 'Action needed',
        value: 'Update payment method in the store',
        highlight: AppColors.hazardRuby,
      ));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: rows.map((r) => _buildRow(r, isLast: rows.last == r)).toList(),
      ),
    );
  }

  Widget _buildRow(_DetailRow row, {required bool isLast}) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(row.label,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              Flexible(
                child: Text(row.value,
                    textAlign: TextAlign.end,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: row.highlight ?? AppColors.textPrimary,
                    )),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: AppColors.borderSubtle),
      ],
    );
  }

  String _formatProductId(String id) {
    if (id.toLowerCase().contains('annual')) return 'Annual Plan';
    if (id.toLowerCase().contains('monthly')) return 'Monthly Plan';
    return id;
  }

  String _formatStore(String store) {
    switch (store.toLowerCase()) {
      case 'play_store':
      case 'google':   return 'Google Play';
      case 'app_store':
      case 'apple':    return 'Apple App Store';
      case 'stripe':   return 'Stripe';
      default:         return store;
    }
  }

  String _fmtDate(DateTime d) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }
}

class _DetailRow {
  final String label;
  final String value;
  final Color? highlight;
  const _DetailRow({required this.label, required this.value, this.highlight});
}

// ── Manage button ─────────────────────────────────────────────────────────────

class _ManageButton extends StatelessWidget {
  const _ManageButton();

  @override
  Widget build(BuildContext context) {
    return _OutlinedAction(
      icon: Icons.open_in_new_rounded,
      label: _storeLabel(),
      subtitle: 'Change plan, update payment method',
      onTap: () => _openStore(context),
    );
  }
}

// ── Cancel subscription ───────────────────────────────────────────────────────

class _CancelButton extends StatelessWidget {
  final SubscriptionState state;
  final VoidCallback onConfirmed;
  const _CancelButton({required this.state, required this.onConfirmed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCancelSheet(context),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.hazardRubySubtle,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.hazardRubyBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppColors.hazardRuby.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.cancel_outlined,
                  size: 20.sp, color: AppColors.hazardRuby),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cancel Subscription',
                      style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.hazardRuby)),
                  Text('You keep access until the period ends',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.hazardRuby.withValues(alpha: 0.75))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20.sp, color: AppColors.hazardRuby),
          ],
        ),
      ),
    );
  }

  Future<void> _showCancelSheet(BuildContext context) async {
    final confirmed = await CancelSubscriptionSheet.show(context, state: state);
    if (confirmed) onConfirmed();
  }
}

// ── Already cancelled banner ──────────────────────────────────────────────────

class _AlreadyCancelledBanner extends StatelessWidget {
  final DateTime? expiresAt;
  const _AlreadyCancelledBanner({this.expiresAt});

  @override
  Widget build(BuildContext context) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = expiresAt != null
        ? '${months[expiresAt!.month]} ${expiresAt!.day}, ${expiresAt!.year}'
        : 'end of billing period';

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.warningAmberSubtle,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.warningAmberBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18.sp, color: AppColors.warningAmber),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Your subscription is cancelled. You have full Pro access until $dateStr.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.warningAmber, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Restore button ────────────────────────────────────────────────────────────

class _RestoreButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  const _RestoreButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return _OutlinedAction(
      icon: Icons.restore_rounded,
      label: loading ? 'Restoring…' : 'Restore Purchases',
      subtitle: 'Re-link a previous subscription to this account',
      onTap: loading ? null : onPressed,
    );
  }
}

// ── Shared outlined action row ────────────────────────────────────────────────

class _OutlinedAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  const _OutlinedAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, size: 20.sp, color: AppColors.textSecondary),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20.sp, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted, fontWeight: FontWeight.w700),
      );
}

// ── Free feature list ─────────────────────────────────────────────────────────

class _FreeFeatureList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final features = [
      '${AppConstants.freeSimulationsPerMonth} pre-flight simulations per month',
      'Basic retention score',
      'Single channel workspace',
    ];
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Included in Free',
              style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          SizedBox(height: 10.h),
          ...features.map((f) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 16.sp, color: AppColors.textMuted),
                    SizedBox(width: 8.w),
                    Text(f, style: AppTypography.bodySmall),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Legal note ────────────────────────────────────────────────────────────────

class _LegalNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Subscriptions automatically renew unless cancelled at least 24 hours '
      'before the end of the current period. You can manage or cancel at any '
      'time in your store account settings.',
      textAlign: TextAlign.center,
      style: AppTypography.bodySmall
          .copyWith(color: AppColors.textMuted, fontSize: 11.5.sp, height: 1.5),
    );
  }
}
