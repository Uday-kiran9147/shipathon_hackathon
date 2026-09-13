import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:shipathon_hackathon/core/services/revenue_cat_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../providers/subscription_provider.dart';
import '../widgets/common/coming_soon_card.dart';
import '../widgets/common/custom_app_bar.dart';
import 'briefing/daily_briefing_screen.dart';
import 'channel/channel_graph_screen.dart';
import 'simulator/preflight_simulator_screen.dart';

/// Main Navigation Shell — spring-physics pill indicator, smooth screen transitions
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _previousIndex = 0;
  int _pressedIndex = -1;

  // Spring-driven pill position: tracks fractional tab index (0.0–2.0 for 3 real tabs)
  late AnimationController _pillController;

  @override
  void initState() {
    super.initState();
    _pillController = AnimationController.unbounded(vsync: this, value: 0.0);
  }

  @override
  void dispose() {
    _pillController.dispose();
    super.dispose();
  }

  void _switchTab(int index) async{
    if (index == 3) {
      HapticFeedback.lightImpact();
      // ComingSoonCard.showProShowcaseModal(context);
      final paywallResult =await RevenueCatService().presentPaywall();
      if (paywallResult == null) {
        // Handle the case where the paywall is dismissed or fails
        // You can show a message or take any other action here
        // For example, you could show an error message or retry the operation
        // Disply a simple message for now
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paywall dismissed or failed.'),
            ),
          );
        }
      }
      return;
    }
    if (_currentIndex != index) {
      HapticFeedback.lightImpact();
      setState(() {
        _previousIndex = _currentIndex;
        _currentIndex = index;
      });
      _pillController.animateWith(
        SpringSimulation(
          const SpringDescription(mass: 1.0, stiffness: 300.0, damping: 28.0),
          _pillController.value,
          index.toDouble(),
          0.0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subProvider = context.watch<SubscriptionProvider>();

    final screens = [
      DailyBriefingScreen(onNavigateTab: (idx) => _switchTab(idx)),
      const PreflightSimulatorScreen(),
      const ChannelGraphScreen(),
      Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: const CustomAppBar(
          title: 'Creator Pro',
          subtitle: 'Upcoming AI Intelligence Studio',
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: const ComingSoonCard(
              title: 'Creator Pro',
              description:
                  'Exciting new creator intelligence and simulation features are currently in development. Stay tuned!',
            ),
          ),
        ),
      ),
    ];

    final isForward = _currentIndex >= _previousIndex;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
            ),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: Offset(isForward ? 0.05 : -0.05, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
        child: SafeArea(
          top: false,
          child: Container(
            height: 64.h,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(100.r), // Solid Stadium Dock
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.8),
              boxShadow: const [
                // Solid deep ground shadow
                BoxShadow(
                  color: Color(0x1A0F172A),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabCount = subProvider.isPro ? 3 : 4;
                final tabWidth = constraints.maxWidth / tabCount;

                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Spring-physics pill indicator
                    AnimatedBuilder(
                      animation: _pillController,
                      builder: (context, _) {
                        final pillLeft = _pillController.value.clamp(0.0, (tabCount - 1).toDouble()) * tabWidth;
                        return Positioned(
                          left: pillLeft,
                          width: tabWidth,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF181A24),
                              borderRadius: BorderRadius.circular(100.r),
                              border: Border.all(
                                color: const Color(0xFF0A0D14),
                                width: 1.5,
                              ),
                              boxShadow: [
                                const BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(0, 2),
                                  blurRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.22),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Interactive Tab Items
                    Row(
                      children: [
                        Expanded(
                          child: _buildNavItem(
                            index: 0,
                            icon: Icons.lightbulb_rounded,
                            label: 'Ideas',
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
                            icon: Icons.account_circle_rounded,
                            label: 'Channel',
                          ),
                        ),
                        if (!subProvider.isPro)
                          Expanded(
                            child: _buildNavItem(
                              index: 3,
                              icon: Icons.workspace_premium_rounded,
                              label: 'Go Pro',
                              isProTab: true,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
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
    final isPressed = _pressedIndex == index;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedIndex = index),
      onTapUp: (_) => setState(() => _pressedIndex = -1),
      onTapCancel: () => setState(() => _pressedIndex = -1),
      onTap: () => _switchTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutBack,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 4.h),
          decoration: isProTab
              ? BoxDecoration(
                  color: AppColors.proGoldSubtle,
                  borderRadius: BorderRadius.circular(100.r),
                  border: Border.all(
                    color: const Color(0xFFFDE68A),
                    width: 1.5,
                  ),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      icon,
                      size: 20.sp,
                      color: isProTab
                          ? AppColors.proGold
                          : (isSelected
                                ? Colors.white
                                : const Color(0xFF64748B)),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: isSelected ? 4.w : 0,
                    height: 5.w,
                  ),
                  AnimatedScale(
                    scale: isSelected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      opacity: isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 160),
                      child: Container(
                        width: 5.w,
                        height: 5.w,
                        decoration: const BoxDecoration(
                          color: AppColors
                              .primary, // Signature Logo Red glowing dot
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 10.5.sp,
                  color: isProTab
                      ? AppColors.proGold
                      : (isSelected ? Colors.white : const Color(0xFF64748B)),
                  fontWeight: (isSelected || isProTab)
                      ? FontWeight.w900
                      : FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
