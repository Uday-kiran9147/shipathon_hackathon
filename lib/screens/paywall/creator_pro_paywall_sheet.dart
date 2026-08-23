import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/subscription_provider.dart';

/// High-Converting RevenueCat Creator Pro Paywall BottomSheet
class CreatorProPaywallSheet extends StatefulWidget {
  const CreatorProPaywallSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreatorProPaywallSheet(),
    );
  }

  @override
  State<CreatorProPaywallSheet> createState() => _CreatorProPaywallSheetState();
}

class _CreatorProPaywallSheetState extends State<CreatorProPaywallSheet> {
  bool _isAnnual = true;

  @override
  Widget build(BuildContext context) {
    final subProvider = context.watch<SubscriptionProvider>();

    return Container(
      height: 720.h,
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
          children: [
            // Handle Bar
            Container(
              margin: EdgeInsets.only(top: 10.h, bottom: 8.h),
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            // Close Button Row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded,
                        size: 20.sp, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    // Pro Crown Badge
                    Container(
                      width: 54.w,
                      height: 54.w,
                      decoration: BoxDecoration(
                        gradient: AppColors.proShimmerGradient,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.proGoldAccent.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 28.sp,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Headline
                    Text(
                      'Unlock Creator Pro',
                      style: AppTypography.displayMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Stop wasting 15 hours on flop videos. Simulate retention curves before hitting record.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Feature Checklist
                    _buildFeatureItem(
                      icon: Icons.all_inclusive_rounded,
                      title: 'Unlimited Pre-Flight Simulations',
                      subtitle: 'Stress-test all weekly long-form & Shorts scripts.',
                    ),
                    _buildFeatureItem(
                      icon: Icons.timeline_rounded,
                      title: '30-Second Retention Hazard Timeline',
                      subtitle: 'Pinpoint exact drop-off moments before recording.',
                    ),
                    _buildFeatureItem(
                      icon: Icons.auto_fix_high_rounded,
                      title: '3 Prescriptive AI Fixes & Re-Hooker',
                      subtitle: '1-Click intro cuts and contrast hooks to lift score.',
                    ),
                    _buildFeatureItem(
                      icon: Icons.trending_up_rounded,
                      title: 'Channel Outlier Predictor (3.0×+ Views)',
                      subtitle: 'Benchmark against your historical audience graph.',
                    ),
                    SizedBox(height: 20.h),

                    // Pricing Toggle (Annual vs Monthly)
                    Row(
                      children: [
                        // Annual Package
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isAnnual = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: EdgeInsets.all(14.w),
                              decoration: BoxDecoration(
                                color: _isAnnual
                                    ? AppColors.primarySubtle
                                    : AppColors.canvas,
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(
                                  color: _isAnnual
                                      ? AppColors.primary
                                      : AppColors.borderLight,
                                  width: _isAnnual ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'ANNUAL',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: _isAnnual
                                              ? AppColors.primary
                                              : AppColors.textMuted,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 6.w, vertical: 2.h),
                                        decoration: BoxDecoration(
                                          color: AppColors.outlierJade,
                                          borderRadius:
                                              BorderRadius.circular(4.r),
                                        ),
                                        child: Text(
                                          'SAVE ${AppConstants.annualSavingsPercentage}',
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                            color: Colors.white,
                                            fontSize: 8.sp,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    AppConstants.priceAnnual,
                                    style: AppTypography.titleLarge.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    '${AppConstants.priceAnnualMonthlyEquivalent}/mo billed yearly',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 11.sp,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        // Monthly Package
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isAnnual = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: EdgeInsets.all(14.w),
                              decoration: BoxDecoration(
                                color: !_isAnnual
                                    ? AppColors.primarySubtle
                                    : AppColors.canvas,
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(
                                  color: !_isAnnual
                                      ? AppColors.primary
                                      : AppColors.borderLight,
                                  width: !_isAnnual ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MONTHLY',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: !_isAnnual
                                          ? AppColors.primary
                                          : AppColors.textMuted,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    AppConstants.priceMonthly,
                                    style: AppTypography.titleLarge.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Billed monthly',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 11.sp,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),

                    // Primary CTA: Start Free Trial
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: subProvider.isPurchasing
                            ? null
                            : () async {
                                final success = await subProvider.purchasePackage(
                                    isAnnual: _isAnnual);
                                if (context.mounted && success) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '🚀 Welcome to Creator Pro! Unlimited simulations unlocked.',
                                        style: AppTypography.bodySmall
                                            .copyWith(color: Colors.white),
                                      ),
                                      backgroundColor: AppColors.outlierJade,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          shadowColor: AppColors.primary.withValues(alpha: 0.3),
                          elevation: 6,
                        ),
                        child: subProvider.isPurchasing
                            ? SizedBox(
                                height: 20.h,
                                width: 20.h,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Column(
                                children: [
                                  Text(
                                    'Start 7-Day Free Trial',
                                    style: AppTypography.labelLarge.copyWith(
                                      color: Colors.white,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'Then ${_isAnnual ? AppConstants.priceAnnual : AppConstants.priceMonthly} / ${_isAnnual ? 'year' : 'month'} • Cancel anytime',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Restore Purchases & Terms
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () async {
                            final success =
                                await subProvider.restorePurchases();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Subscriptions restored!'
                                        : 'No active subscription found.',
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text(
                            'Restore Purchases',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        Text('•',
                            style: TextStyle(color: AppColors.textMuted)),
                        TextButton(
                          onPressed: () {
                            subProvider.toggleProStatusDemo();
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Toggle Demo Pro',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: AppColors.outlierJadeSubtle,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14.sp, color: AppColors.outlierJade),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
