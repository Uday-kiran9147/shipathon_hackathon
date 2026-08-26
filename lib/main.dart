import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/briefing_provider.dart';
import 'providers/channel_provider.dart';
import 'providers/simulator_provider.dart';
import 'providers/subscription_provider.dart';
import 'screens/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('[Environment] .env not found or failed to load: $e');
  }
  runApp(const PrevueAPP());
}

class PrevueAPP extends StatelessWidget {
  const PrevueAPP({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChannelProvider()),
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
            home: const MainNavigationShell(),
          );
        },
      ),
    );
  }
}
