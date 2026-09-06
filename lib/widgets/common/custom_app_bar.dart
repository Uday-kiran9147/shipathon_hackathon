import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/channel_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../screens/history/history_screen.dart';
import '../channel/channel_switcher_modal.dart';
import 'coming_soon_card.dart';

/// Prevue Curated Studio Custom App Bar
/// Features razor-sharp branding, tactile spring-physics pills, live intelligence status,
/// and responsive layout across all device viewports.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showLiveDot;
  final bool showChannelSwitcher;
  final bool showProBadge;
  final bool showHistoryButton;
  final VoidCallback? onHistoryPressed;
  final VoidCallback? onLogoPressed;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showLiveDot = false,
    this.showChannelSwitcher = true,
    this.showProBadge = true,
    this.showHistoryButton = false,
    this.onHistoryPressed,
    this.onLogoPressed,
    this.actions,
  });

  @override
  Size get preferredSize => Size.fromHeight(62.h);

  @override
  Widget build(BuildContext context) {
    final subProvider = context.watch<SubscriptionProvider>();
    final channelProvider = context.watch<ChannelProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final channel = channelProvider.channel;

    return AppBar(
      backgroundColor: AppColors.canvas,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16.w,
      toolbarHeight: 61.h,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.h),
        child: Container(
          color: AppColors.borderLight.withValues(alpha: 0.7),
          height: 1.h,
        ),
      ),
      title: Row(
        children: [
          // Prevue Logo Mark with spring tactile feedback
          _TactilePill(
            onTap: onLogoPressed ?? () => ChannelSwitcherModal.show(context),
            child: Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF0022).withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9.r),
                child: Image.asset(
                  'assets/images/prevue_logo_v6.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFFF0022),
                    child: Center(
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),

          // Header Title & Dynamic Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 16.5.sp,
                    letterSpacing: -0.4,
                    color: AppColors.textInk,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 1.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showLiveDot) ...[
                        Container(
                          width: 6.w,
                          height: 6.w,
                          decoration: BoxDecoration(
                            color: AppColors.outlierJade,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.outlierJade.withValues(
                                  alpha: 0.45,
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 5.w),
                      ],
                      Flexible(
                        child: Text(
                          subtitle!,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Active Channel Chip with Switcher dropdown
        if (showChannelSwitcher)
          Padding(
            padding: EdgeInsets.only(right: 6.w),
            child: _TactilePill(
              onTap: () => ChannelSwitcherModal.show(context),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.5.h),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(100.r),
                  border: Border.all(
                    color: AppColors.borderLight,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18.w,
                      height: 18.w,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primarySubtle,
                      ),
                      child: ClipOval(
                        child: user?.photoUrl != null
                            ? Image.network(
                                user!.photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                      child: Text(
                                        channel.handle.isNotEmpty
                                            ? channel.handle
                                                  .replaceFirst('@', '')[0]
                                                  .toUpperCase()
                                            : 'C',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                              )
                            : Center(
                                child: Text(
                                  channel.handle.isNotEmpty
                                      ? channel.handle
                                            .replaceFirst('@', '')[0]
                                            .toUpperCase()
                                      : 'C',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 62.w),
                      child: Text(
                        channel.handle.isNotEmpty
                            ? channel.handle
                            : '@RevenueCat',
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5.sp,
                          color: AppColors.textInk,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 14.sp,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Pro Badge / Simulations Remaining Pill
        if (showProBadge)
          Padding(
            padding: EdgeInsets.only(right: showHistoryButton ? 6.w : 14.w),
            child: _TactilePill(
              onTap: () {
                ComingSoonCard.showProShowcaseModal(context);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.5.h),
                decoration: BoxDecoration(
                  color: subProvider.isPro
                      ? AppColors.proGoldSubtle
                      : AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(100.r),
                  border: Border.all(
                    color: subProvider.isPro
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFFBFDBFE),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      subProvider.isPro
                          ? Icons.workspace_premium_rounded
                          : Icons.bolt_rounded,
                      size: 12.5.sp,
                      color: subProvider.isPro
                          ? AppColors.proGold
                          : AppColors.primary,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      subProvider.isPro
                          ? 'PRO'
                          : '${subProvider.simulationsRemaining} FREE',
                      style: AppTypography.labelSmall.copyWith(
                        color: subProvider.isPro
                            ? AppColors.proGold
                            : AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // History Tactile Button
        if (showHistoryButton)
          Padding(
            padding: EdgeInsets.only(right: 14.w),
            child: _TactilePill(
              onTap: onHistoryPressed ?? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              },
              child: Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.borderLight,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.history_rounded,
                    color: AppColors.textInk,
                    size: 17.sp,
                  ),
                ),
              ),
            ),
          ),

        ...?actions,
      ],
    );
  }
}

/// Spring-physics interactive pill / button wrapper with haptic feedback
class _TactilePill extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TactilePill({
    required this.child,
    this.onTap,
  });

  @override
  State<_TactilePill> createState() => _TactilePillState();
}

class _TactilePillState extends State<_TactilePill> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) {
              HapticFeedback.lightImpact();
              setState(() => _isPressed = true);
            }
          : null,
      onTapUp: widget.onTap != null
          ? (_) => setState(() => _isPressed = false)
          : null,
      onTapCancel: widget.onTap != null
          ? () => setState(() => _isPressed = false)
          : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
