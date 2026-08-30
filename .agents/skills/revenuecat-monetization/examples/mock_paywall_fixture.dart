// Example Reference: Mock RevenueCat Offerings & Entitlement State Fixture
import 'package:shipathon_hackathon/models/subscription_state.dart';

class MockRevenueCatFixture {
  static SubscriptionState createFreeState({int simulationsUsed = 0}) {
    return SubscriptionState(
      isPro: false,
      simulationsUsedThisMonth: simulationsUsed,
      maxFreeSimulationsPerMonth: 3,
      activeEntitlement: null,
      expirationDate: null,
    );
  }

  static SubscriptionState createProState() {
    return SubscriptionState(
      isPro: true,
      simulationsUsedThisMonth: 12,
      maxFreeSimulationsPerMonth: 3,
      activeEntitlement: 'creator_pro_access',
      expirationDate: DateTime.now().add(const Duration(days: 365)),
    );
  }
}
