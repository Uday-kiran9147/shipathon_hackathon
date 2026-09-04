import '../core/constants/app_constants.dart';

/// Subscription & Entitlement State Model
class SubscriptionState {
  final bool isPro;
  final int simulationsUsedThisMonth;
  final int freeSimulationsLimit;
  final String? activePackageId;
  final DateTime? renewalDate;
  final DateTime? trialEndsAt;

  const SubscriptionState({
    required this.isPro,
    required this.simulationsUsedThisMonth,
    this.freeSimulationsLimit = AppConstants.freeSimulationsPerMonth,
    this.activePackageId,
    this.renewalDate,
    this.trialEndsAt,
  });

  bool get canSimulate =>
      isPro || simulationsUsedThisMonth < freeSimulationsLimit;

  int get simulationsRemaining {
    if (isPro) return 999;
    final remaining = freeSimulationsLimit - simulationsUsedThisMonth;
    return remaining > 0 ? remaining : 0;
  }

  bool get hasActiveFreeTrial =>
      trialEndsAt != null && trialEndsAt!.isAfter(DateTime.now());

  SubscriptionState copyWith({
    bool? isPro,
    int? simulationsUsedThisMonth,
    int? freeSimulationsLimit,
    String? activePackageId,
    DateTime? renewalDate,
    DateTime? trialEndsAt,
  }) {
    return SubscriptionState(
      isPro: isPro ?? this.isPro,
      simulationsUsedThisMonth:
          simulationsUsedThisMonth ?? this.simulationsUsedThisMonth,
      freeSimulationsLimit: freeSimulationsLimit ?? this.freeSimulationsLimit,
      activePackageId: activePackageId ?? this.activePackageId,
      renewalDate: renewalDate ?? this.renewalDate,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
    );
  }

  factory SubscriptionState.initialFree() {
    return const SubscriptionState(
      isPro: false,
      simulationsUsedThisMonth: 0,
      freeSimulationsLimit: AppConstants.freeSimulationsPerMonth,
    );
  }

  factory SubscriptionState.fromUserProfile(dynamic user) {
    if (user == null) return SubscriptionState.initialFree();
    return SubscriptionState(
      isPro: user.isPro as bool? ?? false,
      simulationsUsedThisMonth: user.simulationsUsedThisMonth as int? ?? 0,
      freeSimulationsLimit: user.freeSimulationsLimit as int? ??
          AppConstants.freeSimulationsPerMonth,
      trialEndsAt: user.trialEndsAt as DateTime?,
    );
  }

  factory SubscriptionState.fromJson(Map<String, dynamic> json) {
    return SubscriptionState(
      isPro: json['isPro'] as bool? ?? json['is_pro'] as bool? ?? false,
      simulationsUsedThisMonth:
          (json['simulationsUsedThisMonth'] ??
                  json['simulations_used_this_month']) as int? ??
              0,
      freeSimulationsLimit:
          (json['freeSimulationsLimit'] ?? json['free_simulations_limit'])
              as int? ??
              AppConstants.freeSimulationsPerMonth,
      activePackageId: json['activePackageId'] as String?,
      renewalDate: json['renewalDate'] != null
          ? DateTime.tryParse(json['renewalDate'].toString())
          : null,
      trialEndsAt: json['trialEndsAt'] != null
          ? DateTime.tryParse(json['trialEndsAt'].toString())
          : null,
    );
  }
}
