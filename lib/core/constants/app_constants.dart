import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application-wide constants & Environment-driven credentials
class AppConstants {
  static const String appName = 'TubeSimul8';
  static const String appTagline = 'YouTube Pre-Flight Intelligence';

  // Environment Configured Keys (from .env with safe uninitialized fallback)
  static String get youtubeApiKey =>
      dotenv.isInitialized ? (dotenv.env['YOUTUBE_API_KEY'] ?? '') : '';
  
  static String get revenueCatApiKeyApple =>
      dotenv.isInitialized
          ? (dotenv.env['REVENUECAT_APPLE_API_KEY'] ?? 'appl_mock_tubesimul8_apple_key')
          : 'appl_mock_tubesimul8_apple_key';

  static String get revenueCatApiKeyGoogle =>
      dotenv.isInitialized
          ? (dotenv.env['REVENUECAT_GOOGLE_API_KEY'] ?? 'goog_mock_tubesimul8_google_key')
          : 'goog_mock_tubesimul8_google_key';

  static String get geminiApiKey =>
      dotenv.isInitialized ? (dotenv.env['GEMINI_API_KEY'] ?? '') : '';

  // RevenueCat Configuration
  static const String entitlementPro = 'creator_pro_access';
  static const String offeringDefault = 'default_creator_offering';
  static const String packageMonthly = 'creator_pro_monthly';
  static const String packageAnnual = 'creator_pro_annual';

  // Pricing display fallbacks
  static const String priceMonthly = '\$19.99';
  static const String priceAnnual = '\$149.00';
  static const String priceAnnualMonthlyEquivalent = '\$12.41';
  static const String annualSavingsPercentage = '38%';

  // Free Tier Usage Limits
  static const int freeSimulationsPerMonth = 3;
}
