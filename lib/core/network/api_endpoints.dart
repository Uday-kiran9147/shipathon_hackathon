import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Prevue Backend API Route Constants
class ApiEndpoints {
  // Base URLs
  static String get baseUrl => dotenv.isInitialized
      ? (dotenv.env['BACKEND_API_BASE_URL'] ??
            'https://api.prevue.studio/api/v1')
      : 'https://api.prevue.studio/api/v1';

  // Auth Routes
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authGoogle = '/auth/google';
  static const String authLogout = '/auth/logout';

  // User & Workspace Routes
  static const String userProfile = '/user/profile';
  static const String userChannels = '/user/channels';
  static const String userActiveChannel = '/user/channels/active';

  // Prescriptive Briefings & Creator Intelligence
  static const String briefingsDaily = '/briefings/daily';
  static const String briefingsGenerate = '/briefings/generate';

  // Pre-Flight Simulator Engine
  static const String simulatorRun = '/simulator/run';
  static const String simulatorApplyFix = '/simulator/apply-fix';

  // Subscriptions & RevenueCat
  static const String subscriptionsStatus = '/subscriptions/status';
}
