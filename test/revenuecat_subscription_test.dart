import 'package:flutter_test/flutter_test.dart';
import 'package:shipathon_hackathon/core/constants/app_constants.dart';
import 'package:shipathon_hackathon/core/services/revenue_cat_service.dart';
import 'package:shipathon_hackathon/models/subscription_state.dart';
import 'package:shipathon_hackathon/providers/subscription_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RevenueCat Service & Subscription Integration Tests', () {
    late RevenueCatService revenueCatService;

    setUp(() {
      revenueCatService = RevenueCatService();
    });

    test('RevenueCatService initializes in mock/fallback mode seamlessly', () async {
      await revenueCatService.initialize(forceMock: true);
      expect(revenueCatService.isMockMode, isTrue);
    });

    test('SubscriptionState model defaults and limit checks', () {
      final state = SubscriptionState.initialFree();
      expect(state.isPro, isFalse);
      expect(state.simulationsUsedThisMonth, 0);
      expect(state.freeSimulationsLimit, AppConstants.freeSimulationsPerMonth);
      expect(state.simulationsRemaining, 3);
      expect(state.canSimulate, isTrue);

      final usedUp = state.copyWith(simulationsUsedThisMonth: 3);
      expect(usedUp.canSimulate, isFalse);
      expect(usedUp.simulationsRemaining, 0);

      final proState = state.copyWith(isPro: true);
      expect(proState.canSimulate, isTrue);
      expect(proState.simulationsRemaining, 999);
    });

    test('SubscriptionProvider gates simulations at 3 free limit and triggers paywall state', () async {
      final provider = SubscriptionProvider();
      provider.resetSimulations();

      // Free simulation 1
      expect(provider.recordSimulationAttempt(), isTrue);
      expect(provider.state.simulationsUsedThisMonth, 1);
      expect(provider.simulationsRemaining, 2);

      // Free simulation 2
      expect(provider.recordSimulationAttempt(), isTrue);
      expect(provider.state.simulationsUsedThisMonth, 2);
      expect(provider.simulationsRemaining, 1);

      // Free simulation 3
      expect(provider.recordSimulationAttempt(), isTrue);
      expect(provider.state.simulationsUsedThisMonth, 3);
      expect(provider.simulationsRemaining, 0);

      // Attempt 4 (Exceeds free limit -> Gated, paywall required)
      expect(provider.recordSimulationAttempt(), isFalse);
      expect(provider.canSimulate, isFalse);

      // Upgrade to Pro
      final purchaseSuccess = await provider.purchasePackage(isAnnual: true);
      expect(purchaseSuccess, isTrue);
      expect(provider.isPro, isTrue);
      expect(provider.canSimulate, isTrue);
      expect(provider.simulationsRemaining, 999);

      // Subsequent simulations allowed unlimited
      expect(provider.recordSimulationAttempt(), isTrue);
    });

    test('SubscriptionProvider purchase and restore packages', () async {
      final provider = SubscriptionProvider();
      
      // Monthly purchase
      final monthlySuccess = await provider.purchasePackage(isAnnual: false);
      expect(monthlySuccess, isTrue);
      expect(provider.isPro, isTrue);
      expect(provider.state.activePackageId, 'monthly');

      // Demo toggle
      provider.toggleProStatusDemo();
      expect(provider.isPro, isFalse);

      // Restore purchases
      final restoreSuccess = await provider.restorePurchases();
      expect(restoreSuccess, isTrue);
      expect(provider.isPro, isTrue);
    });

    test('Three day free trial is modeled for monthly and annual packages', () async {
      final monthlyProvider = SubscriptionProvider();
      final annualProvider = SubscriptionProvider();

      final monthlySuccess = await monthlyProvider.purchasePackage(isAnnual: false);
      final annualSuccess = await annualProvider.purchasePackage(isAnnual: true);

      expect(monthlySuccess, isTrue);
      expect(annualSuccess, isTrue);
      expect(AppConstants.freeTrialDays, 3);
      expect(monthlyProvider.state.activePackageId, 'monthly');
      expect(annualProvider.state.activePackageId, 'annual');
      expect(monthlyProvider.state.trialEndsAt != null, isTrue);
      expect(annualProvider.state.trialEndsAt != null, isTrue);
      expect(
        monthlyProvider.state.trialEndsAt!.difference(DateTime.now()).inDays,
        inInclusiveRange(2, 3),
      );
      expect(
        annualProvider.state.trialEndsAt!.difference(DateTime.now()).inDays,
        inInclusiveRange(2, 3),
      );
    });
  });
}
