import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../constants/app_constants.dart';
import 'dart:developer' show log;
/// RevenueCat SDK wrapper.
///
/// Dual-mode:
///   live — real SDK calls via [purchases_flutter]
///   mock — in-memory simulation for non-mobile / test environments
class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  bool _isInitialized = false;
  bool _mockMode = false;

  bool get isMockMode => _mockMode;

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> initialize({String? customApiKey, bool forceMock = false}) async {
    if (_isInitialized) return;
    _mockMode = forceMock;

    if (_mockMode) {
      log('[RevenueCat] Mock mode active');
      _isInitialized = true;
      return;
    }

    if (kIsWeb || !(Platform.isIOS || Platform.isAndroid || Platform.isMacOS)) {
      log('[RevenueCat] Non-mobile platform → mock mode');
      _mockMode = true;
      _isInitialized = true;
      return;
    }

    try {
      final isApple = Platform.isIOS || Platform.isMacOS;
      final apiKey = customApiKey ??
          (isApple
              ? AppConstants.revenueCatApiKeyApple
              : AppConstants.revenueCatApiKeyGoogle);

      if (_isPlaceholderKey(apiKey)) {
        log('[RevenueCat] Placeholder key detected → mock mode');
        _mockMode = true;
        _isInitialized = true;
        return;
      }

      await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(PurchasesConfiguration(apiKey));
      _isInitialized = true;
      log('[RevenueCat] Configured with live API key');
    } catch (e) {
      log('[RevenueCat] Init failed → mock mode: $e');
      _mockMode = true;
      _isInitialized = true;
    }
  }

  bool _isPlaceholderKey(String key) =>
      key.isEmpty || key.contains('YOUR_') || key.contains('mock_') ||
      key == 'appl_mock_prevue_apple_key' ||
      key == 'goog_mock_prevue_google_key';

  // ── CustomerInfo & listener ────────────────────────────────────────────────

  /// Returns the current [CustomerInfo] from the SDK, or null in mock mode.
  Future<CustomerInfo?> getCustomerInfo() async {
    if (!_isInitialized) await initialize();
    if (_mockMode) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      log('[RevenueCat] getCustomerInfo failed: $e');
      return null;
    }
  }

  /// Register a listener that fires every time RevenueCat emits updated
  /// [CustomerInfo] (renewals, cancellations, billing events, etc.).
  /// No-op in mock mode.
  void addCustomerInfoUpdateListener(CustomerInfoUpdateListener listener) {
    if (_mockMode) return;
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  /// Remove a previously registered listener. No-op in mock mode.
  void removeCustomerInfoUpdateListener(CustomerInfoUpdateListener listener) {
    if (_mockMode) return;
    Purchases.removeCustomerInfoUpdateListener(listener);
  }

  // ── Entitlement helpers ────────────────────────────────────────────────────

  /// Check the [prevue_pro] entitlement on the latest [CustomerInfo].
  Future<bool> checkProEntitlement() async {
    if (!_isInitialized) await initialize();
    if (_mockMode) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(AppConstants.entitlementPro);
    } catch (e) {
      log('[RevenueCat] checkProEntitlement error: $e');
      return false;
    }
  }

  // ── Offerings ──────────────────────────────────────────────────────────────

  Future<Offerings?> getOfferings() async {
    if (!_isInitialized) await initialize();
    if (_mockMode) return null;
    try {
      return await Purchases.getOfferings();
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.configurationError) {
        log('[RevenueCat] No products attached to offering yet (ConfigurationError)');
      } else if (code == PurchasesErrorCode.storeProblemError) {
        log('[RevenueCat] Store unavailable (BILLING_UNAVAILABLE)');
      } else {
        log('[RevenueCat] getOfferings error: $e');
      }
      return null;
    } catch (e) {
      log('[RevenueCat] getOfferings error: $e');
      return null;
    }
  }

  Future<bool> hasValidLiveOffering() async {
    if (!_isInitialized) await initialize(forceMock: false);
    if (_mockMode || kIsWeb || !(Platform.isIOS || Platform.isAndroid)) {
      return false;
    }
    try {
      final offerings = await getOfferings();
      return offerings != null &&
          offerings.current != null &&
          offerings.current!.availablePackages.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── Purchase ───────────────────────────────────────────────────────────────

  /// Returns `true` if the purchase succeeded (real or mock demo).
  /// Returns `false` on cancellation or any unrecoverable error.
  Future<bool> purchaseProPackage({required bool isAnnual}) async {
    if (!_isInitialized) await initialize();

    if (_mockMode) {
      await Future.delayed(const Duration(milliseconds: 900));
      return true;
    }

    try {
      final offerings = await getOfferings();
      final pkg = _resolvePackageForPlan(offerings, isAnnual);
      if (pkg == null) {
        log('[RevenueCat] No package found for isAnnual=$isAnnual');
        return false;
      }
      final result = await Purchases.purchase(PurchaseParams.package(pkg));
      return result.customerInfo.entitlements.active
          .containsKey(AppConstants.entitlementPro);
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        log('[RevenueCat] Purchase cancelled by user');
        return false;
      }
      if (code == PurchasesErrorCode.storeProblemError) {
        log('[RevenueCat] Store unavailable');
        return false;
      }
      log('[RevenueCat] Purchase error ($code): $e');
      return false;
    } catch (e) {
      if (e.toString().contains('MissingPluginException')) {
        log('[RevenueCat] Purchase plugin unavailable');
        return false;
      }
      log('[RevenueCat] Purchase error: $e');
      return false;
    }
  }

  // ── Restore ────────────────────────────────────────────────────────────────

  Future<bool> restorePurchases() async {
    if (!_isInitialized) await initialize();
    if (_mockMode) {
      await Future.delayed(const Duration(milliseconds: 800));
      return true;
    }
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.containsKey(AppConstants.entitlementPro);
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      log('[RevenueCat] Restore failed ($code): $e');
      return false;
    } catch (e) {
      log('[RevenueCat] Restore error: $e');
      return false;
    }
  }

  // ── Identity ───────────────────────────────────────────────────────────────

  Future<void> logIn(String appUserId) async {
    if (!_isInitialized) await initialize();
    if (_mockMode) return;
    try {
      await Purchases.logIn(appUserId);
      log('[RevenueCat] Logged in: $appUserId');
    } catch (e) {
      log('[RevenueCat] logIn error: $e');
    }
  }

  Future<void> logOut() async {
    if (!_isInitialized) await initialize();
    if (_mockMode) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      log('[RevenueCat] logOut error: $e');
    }
  }

  Future<void> setUserAttributes({
    String? email,
    String? displayName,
    String? activeChannel,
    int? channelCount,
  }) async {
    if (!_isInitialized) await initialize();
    if (_mockMode) return;
    try {
      if (email?.isNotEmpty == true) await Purchases.setEmail(email!);
      if (displayName?.isNotEmpty == true) {
        await Purchases.setDisplayName(displayName!);
      }
      final custom = <String, String>{};
      if (activeChannel?.isNotEmpty == true) {
        custom['active_channel'] = activeChannel!;
      }
      if (channelCount != null) {
        custom['connected_channels_count'] = channelCount.toString();
      }
      if (custom.isNotEmpty) await Purchases.setAttributes(custom);
    } catch (e) {
      log('[RevenueCat] setUserAttributes error: $e');
    }
  }

  // ── Native paywall UI ──────────────────────────────────────────────────────

  Future<PaywallResult?> presentPaywall({Offering? offering}) async {
    if (!_isInitialized) await initialize(forceMock: false);
    if (kIsWeb || !(Platform.isIOS || Platform.isAndroid)) return null;
    try {
      Offering? target = offering;
      if (target == null) {
        final offerings = await getOfferings();
        target = offerings?.current ??
            (offerings?.all.isNotEmpty == true
                ? offerings!.all.values.first
                : null);
      }
      if (target != null) {
        return await RevenueCatUI.presentPaywall(
          offering: target,
          displayCloseButton: true,
        );
      }
      return await RevenueCatUI.presentPaywall(displayCloseButton: true);
    } catch (e) {
      log('[RevenueCat] presentPaywall error: $e');
      return null;
    }
  }

  Future<PaywallResult?> presentPaywallIfNeeded() async {
    if (!_isInitialized) await initialize(forceMock: false);
    if (kIsWeb || !(Platform.isIOS || Platform.isAndroid)) return null;
    try {
      return await RevenueCatUI.presentPaywallIfNeeded(
        AppConstants.entitlementPro,
        displayCloseButton: true,
      );
    } catch (e) {
      log('[RevenueCat] presentPaywallIfNeeded error: $e');
      return null;
    }
  }

  // ── Package resolution ─────────────────────────────────────────────────────

  Package? _resolvePackageForPlan(Offerings? offerings, bool isAnnual) {
    if (offerings == null) return null;
    final current = offerings.current;
    final candidate = isAnnual
        ? current?.annual ??
            _findByIdentifiers(offerings, [
              'annual',
              r'$rc_annual',
              AppConstants.packageAnnual,
              'creator_pro_annual',
              'sub_annual',
            ])
        : current?.monthly ??
            _findByIdentifiers(offerings, [
              'monthly',
              r'$rc_monthly',
              AppConstants.packageMonthly,
              'creator_pro_monthly',
              'sub_monthly',
            ]);
    return candidate ??
        current?.availablePackages.firstOrNull ??
        offerings.all.values
            .expand((o) => o.availablePackages)
            .firstOrNull;
  }

  Package? _findByIdentifiers(Offerings offerings, List<String> ids) {
    for (final offering in offerings.all.values) {
      for (final pkg in offering.availablePackages) {
        if (ids.contains(pkg.identifier) ||
            ids.contains(pkg.packageType.name) ||
            ids.contains(pkg.storeProduct.identifier)) {
          return pkg;
        }
      }
    }
    return null;
  }
}

