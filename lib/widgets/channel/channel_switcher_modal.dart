import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/channel_provider.dart';
import '../../providers/subscription_provider.dart';
import '../auth/auth_modal_sheet.dart';
import '../common/solid_heavy_button.dart';
import '../common/tactile_card.dart';

/// Modal Sheet for Multi-Channel Workspace Switching & Management
class ChannelSwitcherModal extends StatefulWidget {
  const ChannelSwitcherModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ChannelSwitcherModal(),
    );
  }

  @override
  State<ChannelSwitcherModal> createState() => _ChannelSwitcherModalState();
}

class _ChannelSwitcherModalState extends State<ChannelSwitcherModal> {
  final TextEditingController _newHandleController = TextEditingController();
  bool _isAddingChannel = false;

  @override
  void dispose() {
    _newHandleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final channelProvider = context.watch<ChannelProvider>();
    final subProvider = context.watch<SubscriptionProvider>();
    final user = authProvider.user;

    if (user == null) {
      return Container(
        height: 200.h,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Center(
          child: Text(
            'Please sign in to manage channels.',
            style: AppTypography.bodyMedium,
          ),
        ),
      );
    }

    return Container(
      height: 680.h,
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

            // Top Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 6.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.hub_rounded,
                        size: 18.sp,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'CHANNEL WORKSPACE',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textInk,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
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
            const Divider(),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Account Identity Card
                    TactileCard(
                      padding: EdgeInsets.all(12.w),
                      child: Row(
                        children: [
                          Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primarySubtle,
                            ),
                            child: ClipOval(
                              child: user.photoUrl != null
                                  ? Image.network(
                                      user.photoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Center(
                                                child: Text(
                                                  user.displayName.isNotEmpty
                                                      ? user.displayName[0]
                                                            .toUpperCase()
                                                      : 'C',
                                                  style: TextStyle(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 16.sp,
                                                  ),
                                                ),
                                              ),
                                    )
                                  : Center(
                                      child: Text(
                                        user.displayName.isNotEmpty
                                            ? user.displayName[0].toUpperCase()
                                            : 'C',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16.sp,
                                        ),
                                      ),
                                    ),
                            ),
                          ),

                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        user.displayName,
                                        style: AppTypography.titleMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14.5.sp,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                    if (subProvider.isPro) ...[
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6.w,
                                          vertical: 2.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.proGoldSubtle,
                                          borderRadius: BorderRadius.circular(
                                            100.r,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFFDE68A),
                                          ),
                                        ),
                                        child: Text(
                                          'PRO',
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                                color: AppColors.proGold,
                                                fontSize: 8.5.sp,
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  user.isGuest
                                      ? 'Guest Session (Temporary)'
                                      : user.email,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 11.5.sp,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (user.isGuest) ...[
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                AuthModalSheet.show(context);
                              },
                              child: Text(
                                'Sign In',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ] else ...[
                            IconButton(
                              tooltip: 'Sign Out',
                              onPressed: () async {
                                await authProvider.signOut();
                                if (!context.mounted) return;
                                channelProvider.resetToDefault();
                                Navigator.pop(context);
                              },
                              icon: Icon(
                                Icons.logout_rounded,
                                size: 18.sp,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Section Title: Connected Channels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'CONNECTED CHANNELS (${user.connectedChannels.length}/5)',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!subProvider.isPro) ...[
                          SizedBox(width: 6.w),
                          Text(
                            'Free: 1 Slot',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ],
                    ),

                    SizedBox(height: 10.h),

                    // List of Connected Channels
                    ...user.connectedChannels.map((handle) {
                      final isActive =
                          channelProvider.channel.handle.toLowerCase() ==
                          handle.toLowerCase();
                      final cached = channelProvider.cachedChannels[handle];

                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: TactileCard(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 10.h,
                          ),
                          backgroundColor: isActive
                              ? AppColors.primarySubtle
                              : AppColors.canvas,
                          border: Border.all(
                            color: isActive
                                ? AppColors.primary.withValues(alpha: 0.35)
                                : AppColors.borderLight,
                          ),
                          onTap: () async {
                            if (!isActive) {
                              await authProvider.switchActiveChannel(handle);
                              await channelProvider.switchChannel(handle);
                            }
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 38.w,
                                height: 38.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surface,
                                  border: Border.all(
                                    color: isActive
                                        ? AppColors.primary
                                        : AppColors.borderLight,
                                  ),
                                ),
                                child: ClipOval(
                                  child:
                                      (cached?.avatarUrl != null &&
                                          cached!.avatarUrl!.startsWith('http'))
                                      ? Image.network(
                                          cached.avatarUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Icon(
                                                Icons.play_circle_fill_rounded,
                                                color: AppColors.youtubeRed,
                                                size: 20.sp,
                                              ),
                                        )
                                      : Icon(
                                          Icons.play_circle_fill_rounded,
                                          color: AppColors.youtubeRed,
                                          size: 20.sp,
                                        ),
                                ),
                              ),

                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            cached?.channelName.isNotEmpty ==
                                                    true
                                                ? cached!.channelName
                                                : handle,
                                            style: AppTypography.titleMedium
                                                .copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 13.5.sp,
                                                  color: AppColors.textInk,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isActive) ...[
                                          SizedBox(width: 6.w),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6.w,
                                              vertical: 2.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius:
                                                  BorderRadius.circular(100.r),
                                            ),
                                            child: Text(
                                              'ACTIVE',
                                              style: AppTypography.labelSmall
                                                  .copyWith(
                                                    color: Colors.white,
                                                    fontSize: 8.sp,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      handle,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textMuted,
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (user.connectedChannels.length > 1) ...[
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18.sp,
                                    color: AppColors.textMuted,
                                  ),
                                  onPressed: () async {
                                    await authProvider.removeChannel(handle);
                                    if (isActive && context.mounted) {
                                      await channelProvider.syncChannel(
                                        authProvider.activeHandle,
                                      );
                                    }
                                  },
                                ),
                              ],
                              if (isActive) ...[
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 20.sp,
                                  color: AppColors.primary,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                    SizedBox(height: 12.h),

                    // Add Channel Action or Pro Paywall Trigger
                    if (_isAddingChannel) ...[
                      TactileCard(
                        padding: EdgeInsets.all(12.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CONNECT YOUTUBE CHANNEL',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _newHandleController,
                                    decoration: const InputDecoration(
                                      hintText: 'e.g. @MrBeast, @Telusko',
                                      prefixIcon: Icon(
                                        Icons.alternate_email_rounded,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                SizedBox(
                                  width: 80.w,
                                  child: SolidHeavyButton(
                                    label: 'Add',
                                    height: 46.h,
                                    onPressed: () async {
                                      final handle = _newHandleController.text
                                          .trim();
                                      if (handle.isNotEmpty) {
                                        final success = await authProvider
                                            .addChannel(
                                              handle,
                                              isPro: subProvider.isPro,
                                            );
                                        if (success && context.mounted) {
                                          await channelProvider.syncChannel(
                                            handle,
                                          );
                                          setState(() {
                                            _isAddingChannel = false;
                                            _newHandleController.clear();
                                          });
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _isAddingChannel = false),
                              child: Text(
                                'Cancel',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      SolidHeavyButton(
                        label: subProvider.isPro
                            ? '+ Connect Another Channel'
                            : '+ Connect Another Channel (Pro)',
                        icon: subProvider.isPro
                            ? Icons.add_circle_outline_rounded
                            : Icons.lock_rounded,
                        height: 48.h,
                        backgroundColor: subProvider.isPro
                            ? AppColors.canvas
                            : AppColors.surface,
                        foregroundColor: subProvider.isPro
                            ? AppColors.textInk
                            : AppColors.proGold,
                        borderColor: subProvider.isPro
                            ? AppColors.borderLight
                            : const Color(0xFFFDE68A),
                        shadowColor: const Color(0xFFE2E8F0),
                        onPressed: () {
                          if (!subProvider.isPro &&
                              user.connectedChannels.isNotEmpty) {
                            Navigator.pop(context);
                            subProvider.presentPaywall(context);
                          } else {
                            setState(() => _isAddingChannel = true);
                          }
                        },
                      ),
                    ],

                    SizedBox(height: 16.h),

                    // Quick Switch Suggestions
                    Text(
                      'PRESET CREATOR CHANNELS',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 6.h,
                      children: [
                        _buildPresetChip(
                          '@RevenueCat',
                          authProvider,
                          channelProvider,
                          subProvider,
                        ),
                        _buildPresetChip(
                          '@Telusko',
                          authProvider,
                          channelProvider,
                          subProvider,
                        ),
                        _buildPresetChip(
                          '@Fireship',
                          authProvider,
                          channelProvider,
                          subProvider,
                        ),
                        _buildPresetChip(
                          '@mkbhd',
                          authProvider,
                          channelProvider,
                          subProvider,
                        ),
                        _buildPresetChip(
                          '@MrBeast',
                          authProvider,
                          channelProvider,
                          subProvider,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(
    String handle,
    AuthProvider authProvider,
    ChannelProvider channelProvider,
    SubscriptionProvider subProvider,
  ) {
    return GestureDetector(
      onTap: () async {
        await authProvider.addChannel(handle, isPro: subProvider.isPro);
        if (mounted) {
          await channelProvider.syncChannel(handle);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 12.sp, color: AppColors.primary),
            SizedBox(width: 4.w),
            Text(
              handle,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textInk,
                fontWeight: FontWeight.w700,
                fontSize: 11.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
