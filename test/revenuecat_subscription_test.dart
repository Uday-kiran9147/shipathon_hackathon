import 'package:flutter_test/flutter_test.dart';
import 'package:shipathon_hackathon/core/constants/app_constants.dart';
import 'package:shipathon_hackathon/core/services/revenue_cat_service.dart';
import 'package:shipathon_hackathon/models/subscription_state.dart';
import 'package:shipathon_hackathon/providers/subscription_provider.dart';

class _SubscriptionUserStub {
  final bool isPro;
  final int simulationsUsedThisMonth;
  final int freeSimulationsLimit;

  const _SubscriptionUserStub({
    required this.isPro,
    this.simulationsUsedThisMonth = 0,
    this.freeSimulationsLimit = 3,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubscriptionStatus enum', () {
    test('hasAccess is true for paying/trial/grace states only', () {
      expect(SubscriptionStatus.trial.hasAccess, isTrue);
      expect(SubscriptionStatus.active.hasAccess, isTrue);
      expect(SubscriptionStatus.cancelledButActive.hasAccess, isTrue);
      expect(SubscriptionStatus.billingIssue.hasAccess, isTrue);

      expect(SubscriptionStatus.free.hasAccess, isFalse);
      expect(SubscriptionStatus.expired.hasAccess, isFalse);
      expect(SubscriptionStatus.unknown.hasAccess, isFalse);
    });

    test('displayLabel returns a non-empty string for every value', () {
      for (final s in SubscriptionStatus.values) {
        expect(s.displayLabel.isNotEmpty, isTrue,
            reason: 'Missing displayLabel for $s');
      }
    });
  });

  group('SubscriptionState model', () {
    test('initialFree has correct defaults', () {
      final state = SubscriptionState.initialFree();
      expect(state.status, SubscriptionStatus.free);
      expect(state.isPro, isFalse);
      expect(state.hasAccess, isFalse);
      expect(state.simulationsUsedThisMonth, 0);
      expect(state.freeSimulationsLimit, AppConstants.freeSimulationsPerMonth);
      expect(state.simulationsRemaining, AppConstants.freeSimulationsPerMonth);
      expect(state.canSimulate, isTrue);
    });

    test('canSimulate becomes false when free limit is reached', () {
      final state = SubscriptionState.initialFree()
          .copyWith(simulationsUsedThisMonth: 3);
      expect(state.canSimulate, isFalse);
      expect(state.simulationsRemaining, 0);
    });

    test('Pro status gives unlimited simulations', () {
      final state = SubscriptionState(status: SubscriptionStatus.active);
      expect(state.canSimulate, isTrue);
      expect(state.simulationsRemaining, 999);
      expect(state.isPro, isTrue);
    });

    test('copyWith(isPro: true) upgrades status to active', () {
      final state = SubscriptionState.initialFree().copyWith(isPro: true);
      expect(state.hasAccess, isTrue);
    });

    test('fromJson round-trips status field', () {
      for (final s in SubscriptionStatus.values) {
        final json = {'status': s.name};
        final state = SubscriptionState.fromJson(json);
        expect(state.status, s,
            reason: 'fromJson failed for status ${s.name}');
      }
    });

    test('fromJson falls back to isPro boolean when status field missing', () {
      final proState = SubscriptionState.fromJson({'isPro': true});
      expect(proState.hasAccess, isTrue);

      final freeState = SubscriptionState.fromJson({'isPro': false});
      expect(freeState.hasAccess, isFalse);
    });

    test('loading state uses unknown status', () {
      final state = SubscriptionState.loading();
      expect(state.status, SubscriptionStatus.unknown);
      expect(state.hasAccess, isFalse);
    });

    test('hasActiveFreeTrial is true only when trial + trialEndsAt is future', () {
      final future = DateTime.now().add(const Duration(days: 2));
      final past = DateTime.now().subtract(const Duration(days: 1));

      final activeTrial = SubscriptionState(
        status: SubscriptionStatus.trial,
        trialEndsAt: future,
      );
      expect(activeTrial.hasActiveFreeTrial, isTrue);

      final expiredTrial = SubscriptionState(
        status: SubscriptionStatus.trial,
        trialEndsAt: past,
      );
      expect(expiredTrial.hasActiveFreeTrial, isFalse);

      final noDate = SubscriptionState(status: SubscriptionStatus.trial);
      expect(noDate.hasActiveFreeTrial, isFalse);
    });
  });

  group('RevenueCatService mock mode', () {
    late RevenueCatService rc;

    setUp(() {
      rc = RevenueCatService();
    });

    test('initializes in mock mode when forceMock=true', () async {
      await rc.initialize(forceMock: true);
      expect(rc.isMockMode, isTrue);
    });

    test('getCustomerInfo returns null in mock mode', () async {
      await rc.initialize(forceMock: true);
      final info = await rc.getCustomerInfo();
      expect(info, isNull);
    });

    test('purchaseProPackage returns true in mock mode', () async {
      await rc.initialize(forceMock: true);
      final result = await rc.purchaseProPackage(isAnnual: true);
      expect(result, isTrue);
    });

    test('restorePurchases returns true in mock mode', () async {
      await rc.initialize(forceMock: true);
      final result = await rc.restorePurchases();
      expect(result, isTrue);
    });
  });

  group('SubscriptionProvider (mock mode)', () {
    test('starts in loading/unknown state then resolves to free', () async {
      final provider = SubscriptionProvider();
      // Wait for async init to settle
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.status == SubscriptionStatus.free ||
          provider.status == SubscriptionStatus.unknown, isTrue);
    });

    test('recordSimulationAttempt gates at free limit', () async {
      final provider = SubscriptionProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      provider.resetSimulations();

      // 3 free simulations succeed
      for (int i = 1; i <= 3; i++) {
        expect(provider.recordSimulationAttempt(), isTrue,
            reason: 'Simulation $i should be allowed');
        expect(provider.state.simulationsUsedThisMonth, i);
      }

      // 4th is blocked
      expect(provider.recordSimulationAttempt(), isFalse);
      expect(provider.canSimulate, isFalse);
    });

    test('purchasePackage in mock mode grants Pro status', () async {
      final provider = SubscriptionProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      provider.resetSimulations();

      final success = await provider.purchasePackage(isAnnual: true);
      expect(success, isTrue);
      expect(provider.isPro, isTrue);
      expect(provider.canSimulate, isTrue);
      expect(provider.simulationsRemaining, 999);
      expect(provider.status.hasAccess, isTrue);
    });

    test('purchasePackage monthly also grants Pro status', () async {
      final provider = SubscriptionProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      final success = await provider.purchasePackage(isAnnual: false);
      expect(success, isTrue);
      expect(provider.isPro, isTrue);
    });

    test('restorePurchases in mock mode grants Pro status', () async {
      final provider = SubscriptionProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      final success = await provider.restorePurchases();
      expect(success, isTrue);
      expect(provider.isPro, isTrue);
    });

    test('toggleProStatusDemo flips Pro status', () async {
      final provider = SubscriptionProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      final initial = provider.isPro;
      provider.toggleProStatusDemo();
      expect(provider.isPro, !initial);
      provider.toggleProStatusDemo();
      expect(provider.isPro, initial);
    });

    test('Pro user gets unlimited simulations after purchase', () async {
      final provider = SubscriptionProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      provider.resetSimulations();

      // Use up all free slots
      for (int i = 0; i < 3; i++) {
        provider.recordSimulationAttempt();
      }
      expect(provider.canSimulate, isFalse);

      // Purchase Pro
      await provider.purchasePackage(isAnnual: true);
      expect(provider.canSimulate, isTrue);

      // Additional simulations are allowed
      expect(provider.recordSimulationAttempt(), isTrue);
    });

    test('backend downgrade clears local Pro access', () async {
      final provider = SubscriptionProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      await provider.purchasePackage(isAnnual: true);

      provider.updateSimulationUsage(
        simulationsUsedThisMonth: 3,
        isPro: false,
      );

      expect(provider.isPro, isFalse);
      expect(provider.canSimulate, isFalse);
    });

    test('syncing a free account clears the previous Pro account state', () async {
      final provider = SubscriptionProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      await provider.purchasePackage(isAnnual: true);

      provider.syncWithUser(const _SubscriptionUserStub(isPro: false));

      expect(provider.isPro, isFalse);
      expect(provider.status, SubscriptionStatus.free);
    });

    test('freeTrialDays constant is 3', () {
      expect(AppConstants.freeTrialDays, 3);
    });

    test('entitlementPro constant is prevue_pro', () {
      expect(AppConstants.entitlementPro, 'prevue_pro');
    });
  });
}
