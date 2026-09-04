import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shipathon_hackathon/core/services/revenue_cat_service.dart';
import 'core/services/auth_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';
import 'models/user_profile.dart';
import 'providers/auth_provider.dart';
import 'providers/briefing_provider.dart';
import 'providers/channel_provider.dart';
import 'providers/simulator_provider.dart';
import 'providers/subscription_provider.dart';
import 'screens/auth/auth_gate_screen.dart';
import 'screens/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('[Environment] .env not found or failed to load: $e');
  }
  // Pre-load persisted session before booting widget tree
  UserProfile? initialUser;
  try {
    initialUser = await AuthService().initialize();
    debugPrint('[Main] Initial user preloaded: ${initialUser?.email}');
  } catch (e) {
    debugPrint('[Main] Could not pre-load initial user: $e');
  }

  RevenueCatService revenueCatService = RevenueCatService();
  await revenueCatService.initialize(forceMock: false); // Force mock mode for testing
  runApp(PrevueAPP(initialUser: initialUser));
}

class PrevueAPP extends StatelessWidget {
  final UserProfile? initialUser;

  const PrevueAPP({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(initialUser: initialUser),
        ),
        ChangeNotifierProvider(
          create: (_) => ChannelProvider(
            initialHandle: initialUser?.activeChannelHandle,
          ),
        ),
        ChangeNotifierProvider(create: (_) => BriefingProvider()),
        ChangeNotifierProvider(create: (_) => SimulatorProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],

      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            title: 'Prevue',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (!auth.isInitialized) {
                  return const _AuthInitializationSplash();
                }
                if (!auth.isAuthenticated) {
                  return const AuthGateScreen();
                }
                return const _AuthenticatedBootstrap(
                  child: MainNavigationShell(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Branded Curated Studio splash screen shown while restoring local session
class _AuthInitializationSplash extends StatelessWidget {
  const _AuthInitializationSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68.w,
              height: 68.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF0022).withValues(alpha: 0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.r),
                child: Image.asset(
                  'assets/images/prevue_logo_v6.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFFF0022),
                    child: Center(
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 36.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'PREVUE STUDIO',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textInk,
                fontSize: 11.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: 18.w,
              height: 18.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Seamless bootstrap ensuring the active channel is synchronized on boot
class _AuthenticatedBootstrap extends StatefulWidget {
  final Widget child;
  const _AuthenticatedBootstrap({required this.child});

  @override
  State<_AuthenticatedBootstrap> createState() =>
      _AuthenticatedBootstrapState();
}

class _AuthenticatedBootstrapState extends State<_AuthenticatedBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final channelProvider = context.read<ChannelProvider>();
      final subProvider = context.read<SubscriptionProvider>();
      if (auth.user != null) {
        subProvider.syncWithUser(auth.user);
      }
      if (channelProvider.channel.handle.toLowerCase() !=
          auth.activeHandle.toLowerCase()) {
        channelProvider.syncChannel(auth.activeHandle);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
