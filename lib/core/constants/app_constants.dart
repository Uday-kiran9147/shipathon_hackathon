import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application-wide constants & Environment-driven credentials
class AppConstants {
  static const String appName = 'Prevue';
  static const String appTagline = 'YouTube Pre-Flight Intelligence';

  // Environment Configured Keys (from .env with safe uninitialized fallback)
  static String get youtubeApiKey =>
      dotenv.isInitialized ? (dotenv.env['YOUTUBE_API_KEY'] ?? '') : '';

  static String get revenueCatApiKeyApple => dotenv.isInitialized
      ? (dotenv.env['REVENUECAT_APPLE_API_KEY'] ?? 'appl_mock_prevue_apple_key')
      : 'appl_mock_prevue_apple_key';

  static String get revenueCatApiKeyGoogle => dotenv.isInitialized
      ? (dotenv.env['REVENUECAT_GOOGLE_API_KEY'] ??
            'goog_mock_prevue_google_key')
      : 'goog_mock_prevue_google_key';

  static String get geminiApiKey =>
      dotenv.isInitialized ? (dotenv.env['GEMINI_API_KEY'] ?? '') : '';

  // Gemini Model Identifier (Single source of truth for Gemini Model)
  static String get geminiModel => dotenv.isInitialized
      ? (dotenv.env['GEMINI_MODEL'] ?? 'gemini-3.6-flash')
      : 'gemini-3.6-flash';

  // RevenueCat Configuration
  static const String entitlementPro = 'creator_pro_access';
  static const String offeringDefault = 'default';
  static const String packageMonthly = 'creator_pro_monthly';
  static const String packageAnnual = 'creator_pro_annual';

  // Pricing display fallbacks
  static const String priceMonthly = '\$19.99';
  static const String priceAnnual = '\$149.00';
  static const String priceAnnualMonthlyEquivalent = '\$12.41';
  static const String annualSavingsPercentage = '38%';

  // Free tier & trial settings
  static const int freeSimulationsPerMonth = 3;
  static const int freeTrialDays = 3;
  static const String freeTrialLabel = '3-Day Free Trial';
  static const int monthlyDurationDays = 30;
  static const int annualDurationDays = 365;
}
