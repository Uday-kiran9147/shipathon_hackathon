import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/common/solid_heavy_button.dart';

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
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    // Pro Prevue Logo Badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 64.w,
                          height: 64.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFF0022,
                                ).withValues(alpha: 0.25),
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
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: const Color(0xFFFF0022),
                                    child: const Center(
                                      child: Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                      ),
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
                                  color: AppColors.proGoldAccent.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.workspace_premium_rounded,
                              color: Colors.white,
                              size: 14.sp,
                            ),
                          ),
                        ),
                      ],
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
                      subtitle:
                          'Stress-test all weekly long-form & Shorts scripts.',
                    ),
                    _buildFeatureItem(
                      icon: Icons.hub_rounded,
                      title: 'Multi-Channel Workspace (Up to 5 Channels)',
                      subtitle:
                          'Seamlessly switch and calibrate between all your YouTube channels.',
                    ),
                    _buildFeatureItem(
                      icon: Icons.timeline_rounded,
                      title: '30-Second Retention Hazard Timeline',
                      subtitle:
                          'Pinpoint exact drop-off moments before recording.',
                    ),
                    _buildFeatureItem(
                      icon: Icons.auto_fix_high_rounded,
                      title: '3 Prescriptive AI Fixes & Re-Hooker',
                      subtitle:
                          '1-Click intro cuts and contrast hooks to lift score.',
                    ),
                    _buildFeatureItem(
                      icon: Icons.trending_up_rounded,
                      title: 'Channel Outlier Predictor (3.0×+ Views)',
                      subtitle:
                          'Benchmark against your historical audience graph.',
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
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                              color: _isAnnual
                                                  ? AppColors.primary
                                                  : AppColors.textMuted,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                          vertical: 3.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.outlierJade,
                                          borderRadius: BorderRadius.circular(
                                            100.r,
                                          ),
                                        ),
                                        child: Text(
                                          'SAVE ${AppConstants.annualSavingsPercentage}',
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                                color: Colors.white,
                                                fontSize: 8.5.sp,
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
                    SolidHeavyButton(
                      label: 'Start 7-Day Free Trial',
                      height: 56.h,
                      fontSize: 16.sp,
                      isLoading: subProvider.isPurchasing,
                      loadingText: 'Activating Creator Pro...',
                      onPressed: () async {
                        final success = await subProvider.purchasePackage(
                          isAnnual: _isAnnual,
                        );
                        if (context.mounted && success) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '🚀 Welcome to Creator Pro! Unlimited simulations unlocked.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: AppColors.outlierJade,
                            ),
                          );
                        }
                      },
                    ),
                    SizedBox(height: 12.h),

                    // Restore Purchases & Terms
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () async {
                            final success = await subProvider
                                .restorePurchases();
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
                        Text('•', style: TextStyle(color: AppColors.textMuted)),
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
      padding: EdgeInsets.only(bottom: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: const BoxDecoration(
              color: AppColors.outlierJadeSubtle,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18.sp, color: AppColors.outlierJade),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5.sp,
                    color: AppColors.textInk,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.5.sp,
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
