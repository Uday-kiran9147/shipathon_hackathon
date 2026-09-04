import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'tactile_card.dart';

/// Clean, responsive Coming Soon card with smooth animated text, title, and description.
/// Simple and zero-clutter: purely responsive and tactile with no extra buttons.
class ComingSoonCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const ComingSoonCard({
    super.key,
    this.title = 'Creator Pro',
    this.description =
        'Exciting new intelligence features are on the way. Stay tuned for our next major release!',
    this.icon = Icons.auto_awesome_rounded,
    this.padding,
    this.margin,
  });

  /// Displays the clean Coming Soon modal bottom sheet
  static Future<void> show(
    BuildContext context, {
    String title = 'Creator Pro',
    String description =
        'Exciting new intelligence features are on the way. Stay tuned for our next major release!',
    IconData icon = Icons.auto_awesome_rounded,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F0F172A),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    margin: EdgeInsets.only(bottom: 16.h),
                    width: 36.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                  ),
                ),
                ComingSoonCard(
                  title: title,
                  description: description,
                  icon: icon,
                ),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Displays the Limit Reached Coming Soon modal bottom sheet
  static Future<void> showLimitReached(BuildContext context) {
    return show(
      context,
      title: 'Simulation Limit Reached',
      description:
          'You have reached your 3 free simulations for this month. Pro subscriptions with unlimited simulations are coming soon!',
      icon: Icons.rocket_launch_rounded,
    );
  }

  /// Alias for showing the Pro Coming Soon modal
  static Future<void> showProShowcaseModal(BuildContext context) => show(context);

  @override
  State<ComingSoonCard> createState() => _ComingSoonCardState();
}

class _ComingSoonCardState extends State<ComingSoonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin ?? EdgeInsets.zero,
      child: TactileCard(
        borderRadius: 20.r,
        padding: widget.padding ?? EdgeInsets.all(20.w),
        backgroundColor: AppColors.surface,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.4),
        shadows: AppColors.cardElevation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  color: AppColors.primary,
                  size: 26.sp,
                ),
              ),
            ),
            SizedBox(height: 14.h),

            // Animated Shimmer "COMING SOON" text badge with crisp white text
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final shimmerVal = _controller.value * 2.0 - 0.5;
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181A24), // Solid Studio Ink Black
                    borderRadius: BorderRadius.circular(100.r),
                    border: Border.all(
                      color: const Color(0xFF2E3245),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: [
                          (shimmerVal - 0.35).clamp(0.0, 1.0),
                          shimmerVal.clamp(0.0, 1.0),
                          (shimmerVal + 0.35).clamp(0.0, 1.0),
                        ],
                        colors: const [
                          Color(0xFFCBD5E1),
                          Colors.white,
                          Color(0xFFCBD5E1),
                        ],
                      ).createShader(bounds);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13.sp,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'COMING SOON',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 14.h),

            // Title
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 17.5.sp,
                letterSpacing: -0.3,
                color: AppColors.textInk,
              ),
              softWrap: true,
            ),

            SizedBox(height: 8.h),

            // Description
            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13.5.sp,
                height: 1.45,
              ),
              softWrap: true,
            ),
          ],
        ),
      ),
    );
  }
}
