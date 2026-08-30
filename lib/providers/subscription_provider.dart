import 'package:flutter/foundation.dart';
import '../core/services/revenue_cat_service.dart';
import '../models/subscription_state.dart';

class SubscriptionProvider extends ChangeNotifier {
  final RevenueCatService _revenueCatService = RevenueCatService();
  SubscriptionState _state = SubscriptionState.initialFree();
  bool _isPurchasing = false;

  SubscriptionState get state => _state;
  bool get isPro => _state.isPro;
  int get simulationsRemaining => _state.simulationsRemaining;
  bool get canSimulate => _state.canSimulate;
  bool get isPurchasing => _isPurchasing;

  SubscriptionProvider() {
    _initRevenueCat();
  }

  Future<void> _initRevenueCat() async {
    await _revenueCatService.initialize();
    final hasPro = await _revenueCatService.checkProEntitlement();
    if (hasPro) {
      _state = _state.copyWith(isPro: true);
      notifyListeners();
    }
  }

  /// Consume a simulation credit
  bool recordSimulationAttempt() {
    if (_state.isPro) return true;

    if (_state.simulationsUsedThisMonth >= _state.freeSimulationsLimit) {
      return false; // Limit reached, paywall required
    }

    _state = _state.copyWith(
      simulationsUsedThisMonth: _state.simulationsUsedThisMonth + 1,
    );
    notifyListeners();
    return true;
  }

  /// Purchase Creator Pro package
  Future<bool> purchasePackage({required bool isAnnual}) async {
    _isPurchasing = true;
    notifyListeners();

    try {
      final success = await _revenueCatService.purchaseProPackage(
        isAnnual: isAnnual,
      );
      if (success) {
        _state = _state.copyWith(
          isPro: true,
          activePackageId: isAnnual ? 'annual' : 'monthly',
          renewalDate: DateTime.now().add(Duration(days: isAnnual ? 365 : 30)),
        );
      }
      _isPurchasing = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isPurchasing = false;
      notifyListeners();
      return false;
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    _isPurchasing = true;
    notifyListeners();

    final success = await _revenueCatService.restorePurchases();
    if (success) {
      _state = _state.copyWith(isPro: true);
    }
    _isPurchasing = false;
    notifyListeners();
    return success;
  }

  /// Fast toggle for instant demo/judging testing
  void toggleProStatusDemo() {
    _state = _state.copyWith(
      isPro: !_state.isPro,
      simulationsUsedThisMonth: !_state.isPro ? 0 : 3,
    );
    notifyListeners();
  }

  /// Reset simulation count
  void resetSimulations() {
    _state = _state.copyWith(simulationsUsedThisMonth: 0);
    notifyListeners();
  }
}
