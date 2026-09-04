import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/channel_provider.dart';
import '../../providers/subscription_provider.dart';
import '../channel/channel_switcher_modal.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Size get preferredSize => Size.fromHeight(60.h);

  @override
  Widget build(BuildContext context) {
    final subProvider = context.watch<SubscriptionProvider>();
    final channelProvider = context.watch<ChannelProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return AppBar(
      backgroundColor: AppColors.canvas,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16.w,
      toolbarHeight: 60.h,
      title: Row(
        children: [
          GestureDetector(
            onTap: () => ChannelSwitcherModal.show(context),
            child: Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF0022).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  Text(
                    subtitle!,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Active Channel Chip with Switcher dropdown
        Padding(
          padding: EdgeInsets.only(right: 6.w),
          child: GestureDetector(
            onTap: () => ChannelSwitcherModal.show(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(100.r),
                border: Border.all(color: AppColors.borderLight),
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
                                      channelProvider.channel.handle.isNotEmpty
                                          ? channelProvider.channel.handle
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
                                channelProvider.channel.handle.isNotEmpty
                                    ? channelProvider.channel.handle
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

                  SizedBox(width: 5.w),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 80.w),
                    child: Text(
                      channelProvider.channel.handle.isNotEmpty
                          ? channelProvider.channel.handle
                          : '@RevenueCat',
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5.sp,
                        color: AppColors.textInk,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 2.w),
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

        // Pro Badge / Simulations Remaining
        Padding(
          padding: EdgeInsets.only(right: 14.w),
          child: GestureDetector(
            onTap: () {
              subProvider.presentPaywall(context);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: subProvider.isPro
                    ? AppColors.proGoldSubtle
                    : AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(
                  100.r,
                ), // Capsule pill badge
                border: Border.all(
                  color: subProvider.isPro
                      ? const Color(0xFFFDE68A)
                      : const Color(0xFFBFDBFE),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    subProvider.isPro
                        ? Icons.workspace_premium_rounded
                        : Icons.bolt_rounded,
                    size: 13.sp,
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
        ...?actions,
      ],
    );
  }
}
