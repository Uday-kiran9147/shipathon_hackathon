import '../core/constants/app_constants.dart';

/// Subscription & Entitlement State Model
class SubscriptionState {
  final bool isPro;
  final int simulationsUsedThisMonth;
  final int freeSimulationsLimit;
  final String? activePackageId;
  final DateTime? renewalDate;

  const SubscriptionState({
    required this.isPro,
    required this.simulationsUsedThisMonth,
    this.freeSimulationsLimit = AppConstants.freeSimulationsPerMonth,
    this.activePackageId,
    this.renewalDate,
  });

  bool get canSimulate =>
      isPro || simulationsUsedThisMonth < freeSimulationsLimit;

  int get simulationsRemaining {
    if (isPro) return 999;
    final remaining = freeSimulationsLimit - simulationsUsedThisMonth;
    return remaining > 0 ? remaining : 0;
  }

  SubscriptionState copyWith({
    bool? isPro,
    int? simulationsUsedThisMonth,
    int? freeSimulationsLimit,
    String? activePackageId,
    DateTime? renewalDate,
  }) {
    return SubscriptionState(
      isPro: isPro ?? this.isPro,
      simulationsUsedThisMonth:
          simulationsUsedThisMonth ?? this.simulationsUsedThisMonth,
      freeSimulationsLimit: freeSimulationsLimit ?? this.freeSimulationsLimit,
      activePackageId: activePackageId ?? this.activePackageId,
      renewalDate: renewalDate ?? this.renewalDate,
    );
  }

  factory SubscriptionState.initialFree() {
    return const SubscriptionState(
      isPro: false,
      simulationsUsedThisMonth: 0,
      freeSimulationsLimit: AppConstants.freeSimulationsPerMonth,
    );
  }
}
