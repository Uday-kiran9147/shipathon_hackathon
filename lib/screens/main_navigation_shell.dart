import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../providers/subscription_provider.dart';
import 'briefing/daily_briefing_screen.dart';
import 'channel/channel_graph_screen.dart';
import 'paywall/creator_pro_paywall_sheet.dart';
import 'simulator/preflight_simulator_screen.dart';

/// Main Navigation Shell with responsive bottom navigation bar
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  void _switchTab(int index) {
    if (index == 3) {
      // Direct Pro Paywall trigger
      CreatorProPaywallSheet.show(context);
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final subProvider = context.watch<SubscriptionProvider>();

    final screens = [
      DailyBriefingScreen(onNavigateTab: (idx) => _switchTab(idx)),
      const PreflightSimulatorScreen(),
      const ChannelGraphScreen(),
      const ChannelGraphScreen(), // Placeholder for Pro tab action
    ];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
            top: BorderSide(color: AppColors.borderLight, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            child: Row(
              children: [
                Expanded(
                  child: _buildNavItem(
                    index: 0,
                    icon: Icons.auto_awesome_rounded,
                    label: 'Briefing',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 1,
                    icon: Icons.speed_rounded,
                    label: 'Simulator',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 2,
                    icon: Icons.hub_rounded,
                    label: 'Channel',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 3,
                    icon: subProvider.isPro
                        ? Icons.workspace_premium_rounded
                        : Icons.bolt_rounded,
                    label: subProvider.isPro ? 'Pro Active' : 'Upgrade Pro',
                    isProTab: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    bool isProTab = false,
  }) {
    final isSelected = _currentIndex == index && !isProTab;

    return GestureDetector(
      onTap: () => _switchTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primarySubtle
              : (isProTab ? AppColors.proGoldSubtle : Colors.transparent),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: isProTab
                  ? AppColors.proGold
                  : (isSelected ? AppColors.primary : AppColors.textMuted),
            ),
            SizedBox(height: 3.h),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 10.sp,
                color: isProTab
                    ? AppColors.proGold
                    : (isSelected ? AppColors.primaryDark : AppColors.textMuted),
                fontWeight: (isSelected || isProTab)
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
