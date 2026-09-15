import 'dart:async';
import 'dart:developer' show log;
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../core/constants/app_constants.dart';
import '../core/services/revenue_cat_service.dart';
import '../models/subscription_state.dart';

/// Manages the user's subscription state.
///
/// Source of truth: RevenueCat [CustomerInfo].
/// The SDK's customer-info listener keeps this up-to-date in real time
/// (renewals, cancellations, billing events, etc.).
class SubscriptionProvider extends ChangeNotifier {
  final RevenueCatService _rc = RevenueCatService();

  SubscriptionState _state = SubscriptionState.loading();
  bool _isPurchasing = false;
  CustomerInfoUpdateListener? _listener;

  SubscriptionState get state => _state;

  /// True when the user currently has access to Pro features.
  bool get isPro => _state.hasAccess;

  bool get canSimulate => _state.canSimulate;
  int get simulationsRemaining => _state.simulationsRemaining;
  bool get isPurchasing => _isPurchasing;
  SubscriptionStatus get status => _state.status;

  SubscriptionProvider() {
    _init();
  }

  @override
  void dispose() {
    if (_listener != null) {
      _rc.removeCustomerInfoUpdateListener(_listener!);
    }
    super.dispose();
  }

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    await _rc.initialize();

    // Real-time listener: fires whenever RC emits a CustomerInfo update
    // (renewal, cancellation, billing issue, etc.) without needing a restart.
    _listener = (CustomerInfo info) {
      _applyCustomerInfo(info);
    };
    _rc.addCustomerInfoUpdateListener(_listener!);

    await refreshFromRevenueCat();
  }

  // ── State derivation ───────────────────────────────────────────────────────

  void _applyCustomerInfo(CustomerInfo info) {
    _state = SubscriptionState.fromCustomerInfo(
      info,
      simulationsUsed: _state.simulationsUsedThisMonth,
      limit: _state.freeSimulationsLimit,
    );
    notifyListeners();
  }

  /// Fetch the latest [CustomerInfo] from RevenueCat and update state.
  /// Preserves existing simulation counters.
  Future<void> refreshFromRevenueCat() async {
    try {
      final info = await _rc.getCustomerInfo();
      if (info != null) {
        _applyCustomerInfo(info);
      } else if (_state.status == SubscriptionStatus.unknown) {
        // Mock mode — default to free
        _state = SubscriptionState.initialFree();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[SubscriptionProvider] refreshFromRevenueCat error: $e');
      if (_state.status == SubscriptionStatus.unknown) {
        _state = SubscriptionState.initialFree();
        notifyListeners();
      }
    }
  }

  // ── Simulation tracking ────────────────────────────────────────────────────

  bool recordSimulationAttempt() {
    if (_state.hasAccess) return true;
    if (_state.simulationsUsedThisMonth >= _state.freeSimulationsLimit) {
      return false;
    }
    _state = _state.copyWith(
      simulationsUsedThisMonth: _state.simulationsUsedThisMonth + 1,
    );
    notifyListeners();
    return true;
  }

  void updateSimulationUsage({
    required int simulationsUsedThisMonth,
    int? freeSimulationsLimit,
    bool? isPro,
  }) {
    _state = _state.copyWith(
      simulationsUsedThisMonth: simulationsUsedThisMonth,
      freeSimulationsLimit: freeSimulationsLimit ?? _state.freeSimulationsLimit,
      status: isPro == null
        ? null
        : isPro
          ? SubscriptionStatus.active
          : SubscriptionStatus.free,
    );
    notifyListeners();
  }

  /// Sync initial state from a locally-cached UserProfile on boot,
  /// then log the user into RevenueCat and fetch authoritative state.
  ///
  /// The local profile is only used as a placeholder until RC responds —
  /// it must never override an already-confirmed RC subscription state.
  Future<void> syncWithUser(dynamic user) async {
    if (user == null) return;
    final bool isPro = user.isPro as bool? ?? false;
    final int used = user.simulationsUsedThisMonth as int? ?? 0;
    final int limit = user.freeSimulationsLimit as int? ??
        AppConstants.freeSimulationsPerMonth;

    // Only apply local state if RC hasn't confirmed the user as Pro yet.
    // This prevents stale backend data from overwriting a live RC entitlement.
    if (!_state.hasAccess) {
      _state = _state.copyWith(
        status: isPro ? SubscriptionStatus.active : SubscriptionStatus.free,
        simulationsUsedThisMonth: used,
        freeSimulationsLimit: limit,
      );
      notifyListeners();
    }

    // Identify this user in RevenueCat so purchases are tied to their account
    // and can be restored after reinstall or across devices.
    final String? userId = user.id as String?;
    if (userId != null && userId.isNotEmpty && !userId.startsWith('guest_')) {
      await _rc.logIn(userId);
    }

    // Always fetch authoritative state from RC after establishing user identity.
    await refreshFromRevenueCat();
  }

  // ── Purchase ───────────────────────────────────────────────────────────────

  Future<bool> purchasePackage({required bool isAnnual}) async {
    if (_isPurchasing) return false;
    _isPurchasing = true;
    notifyListeners();

    try {
      final success = await _rc.purchaseProPackage(isAnnual: isAnnual);
      if (success) {
        if (_rc.isMockMode) {
          // In mock mode the SDK cannot verify entitlements — apply demo Pro state.
          _state = _state.copyWith(
            status: SubscriptionStatus.active,
            willRenew: true,
            trialEndsAt: DateTime.now()
                .add(Duration(days: AppConstants.freeTrialDays)),
          );
          notifyListeners();
        } else {
          // Live mode: RC is authoritative — fetch fresh CustomerInfo.
          // The backend receives the canonical update via webhook.
          await refreshFromRevenueCat();
        }
      }
      return success;
    } catch (e) {
      debugPrint('[SubscriptionProvider] purchasePackage error: $e');
      return false;
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  Future<bool> restorePurchases() async {
    _isPurchasing = true;
    notifyListeners();
    try {
      final success = await _rc.restorePurchases();
      if (_rc.isMockMode && success) {
        _state = _state.copyWith(
          status: SubscriptionStatus.active,
          willRenew: true,
        );
        notifyListeners();
      } else {
        await refreshFromRevenueCat();
      }
      return success;
    } catch (e) {
      debugPrint('[SubscriptionProvider] restorePurchases error: $e');
      return false;
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  // ── Paywall ────────────────────────────────────────────────────────────────

  /// Try the native RevenueCat paywall; callers that need the custom-sheet
  /// fallback should use [CreatorProPaywallSheet.present(context)] directly.
  Future<void> presentPaywall(BuildContext context) async {
    log('[SubscriptionProvider] Presenting paywall…');
    if (!context.mounted) return;
    final hasLive = await _rc.hasValidLiveOffering();
    if (hasLive) await _rc.presentPaywall();
  }

  // ── Demo / test helpers ────────────────────────────────────────────────────

  void toggleProStatusDemo() {
    final newStatus = _state.hasAccess
        ? SubscriptionStatus.free
        : SubscriptionStatus.active;
    _state = _state.copyWith(
      status: newStatus,
      simulationsUsedThisMonth: newStatus == SubscriptionStatus.free ? 3 : 0,
    );
    notifyListeners();
  }

  void resetSimulations() {
    _state = _state.copyWith(simulationsUsedThisMonth: 0);
    notifyListeners();
  }
}
