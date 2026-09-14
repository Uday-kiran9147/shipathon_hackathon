import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/subscription_state.dart';
import '../../widgets/common/solid_heavy_button.dart';

String _storeUrl() {
  if (!Platform.isIOS && !Platform.isAndroid) return '';
  return Platform.isIOS
      ? 'https://apps.apple.com/account/subscriptions'
      : 'https://play.google.com/store/account/subscriptions';
}

String _storeLabel() {
  if (!Platform.isIOS && !Platform.isAndroid) return 'App Store / Google Play';
  return Platform.isIOS ? 'App Store' : 'Google Play';
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
      content: Text("Couldn't open store. URL copied:\n$url",
          style: AppTypography.bodySmall.copyWith(color: Colors.white)),
      backgroundColor: AppColors.textPrimary,
      duration: const Duration(seconds: 4),
    ));
  }
}

/// Confirmation sheet shown before directing a user to cancel their subscription
/// in the platform store. Call [CancelSubscriptionSheet.show] from any screen.
class CancelSubscriptionSheet extends StatelessWidget {
  final SubscriptionState state;
  const CancelSubscriptionSheet({super.key, required this.state});

  static Future<bool> show(BuildContext context, {required SubscriptionState state}) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CancelSubscriptionSheet(state: state),
    );
    return confirmed == true;
  }

  String get _expiryNote {
    if (state.expiresAt == null) return 'until the current billing period ends.';
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final d = state.expiresAt!;
    return 'until ${months[d.month]} ${d.day}, ${d.year}.';
  }

  String get _planLabel {
    if (state.productId == null) return 'Creator Pro';
    return state.productId!.toLowerCase().contains('annual')
        ? 'Annual Creator Pro'
        : 'Monthly Creator Pro';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                color: AppColors.hazardRubySubtle,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cancel_outlined,
                  size: 28.sp, color: AppColors.hazardRuby),
            ),
            SizedBox(height: 16.h),
            Text('Cancel $_planLabel?',
                style: AppTypography.displayMedium
                    .copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center),
            SizedBox(height: 10.h),
            Text(
              "You'll keep full access to Creator Pro $_expiryNote\n\n"
              'Cancellation is done through your store account. '
              "We'll take you there now.",
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            _WhatYouLoseCard(),
            SizedBox(height: 24.h),
            SolidHeavyButton(
              label: 'Continue to ${_storeLabel()}',
              height: 52.h,
              fontSize: 15.sp,
              isLoading: false,
              onPressed: () => Navigator.pop(context, true),
            ),
            SizedBox(height: 10.h),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Keep my subscription',
                  style: AppTypography.titleMedium.copyWith(
                      color: AppColors.outlierJade,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatYouLoseCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      'Unlimited pre-flight simulations',
      '30-second retention hazard timeline',
      'AI prescriptive fixes & re-hooker',
      'Multi-channel workspace',
      'Channel outlier predictor',
    ];
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("You'll lose access to",
              style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted, fontWeight: FontWeight.w800)),
          SizedBox(height: 10.h),
          ...items.map((item) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    Icon(Icons.remove_circle_outline_rounded,
                        size: 16.sp, color: AppColors.hazardRuby),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(item,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

/// Helper exposed so other screens can open the store directly.
Future<void> openSubscriptionStore(BuildContext context) => _openStore(context);

/// Returns the store management label for the current platform.
String subscriptionStoreLabel() => _storeLabel();
