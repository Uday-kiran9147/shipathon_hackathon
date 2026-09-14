import 'package:purchases_flutter/purchases_flutter.dart';
import '../core/constants/app_constants.dart';

/// Lifecycle states a subscription can be in.
/// HasAccess is true for trial / active / cancelledButActive / billingIssue.
enum SubscriptionStatus {
  unknown,            // initial / loading
  free,               // never subscribed or fully expired
  trial,              // in free-trial period
  active,             // paid, auto-renewing
  cancelledButActive, // cancelled, access until expiresAt
  billingIssue,       // payment failed, grace-period access
  expired,            // entitlement ended
}

extension SubscriptionStatusX on SubscriptionStatus {
  bool get hasAccess => const {
    SubscriptionStatus.trial,
    SubscriptionStatus.active,
    SubscriptionStatus.cancelledButActive,
    SubscriptionStatus.billingIssue,
  }.contains(this);

  String get displayLabel {
    switch (this) {
      case SubscriptionStatus.unknown:   return 'Loading…';
      case SubscriptionStatus.free:      return 'Free';
      case SubscriptionStatus.trial:     return 'Free Trial';
      case SubscriptionStatus.active:    return 'Pro Active';
      case SubscriptionStatus.cancelledButActive: return 'Cancelled';
      case SubscriptionStatus.billingIssue: return 'Billing Issue';
      case SubscriptionStatus.expired:   return 'Expired';
    }
  }
}

class SubscriptionState {
  final SubscriptionStatus status;
  final int simulationsUsedThisMonth;
  final int freeSimulationsLimit;

  // RC-sourced metadata
  final String? productId;
  final String? store;
  final DateTime? expiresAt;
  final DateTime? purchasedAt;
  final bool willRenew;

  // Retained for backward compat / trial display
  final DateTime? trialEndsAt;

  const SubscriptionState({
    this.status = SubscriptionStatus.unknown,
    this.simulationsUsedThisMonth = 0,
    this.freeSimulationsLimit = AppConstants.freeSimulationsPerMonth,
    this.productId,
    this.store,
    this.expiresAt,
    this.purchasedAt,
    this.willRenew = false,
    this.trialEndsAt,
  });

  // ── Convenience getters ────────────────────────────────────────────────────

  /// True when the user currently has access to Pro features.
  bool get hasAccess => status.hasAccess;

  /// Backward-compat alias used throughout the codebase.
  bool get isPro => hasAccess;

  bool get canSimulate => hasAccess || simulationsUsedThisMonth < freeSimulationsLimit;

  int get simulationsRemaining {
    if (hasAccess) return 999;
    final r = freeSimulationsLimit - simulationsUsedThisMonth;
    return r > 0 ? r : 0;
  }

  bool get hasActiveFreeTrial =>
      status == SubscriptionStatus.trial &&
      trialEndsAt != null &&
      trialEndsAt!.isAfter(DateTime.now());

  // ── Factories ──────────────────────────────────────────────────────────────

  factory SubscriptionState.initialFree() => const SubscriptionState(
        status: SubscriptionStatus.free,
        simulationsUsedThisMonth: 0,
        freeSimulationsLimit: AppConstants.freeSimulationsPerMonth,
      );

  factory SubscriptionState.loading() =>
      const SubscriptionState(status: SubscriptionStatus.unknown);

  /// Derive subscription state from a RevenueCat [CustomerInfo] object.
  /// Preserves simulation usage counters from the previous state.
  factory SubscriptionState.fromCustomerInfo(
    CustomerInfo info, {
    int simulationsUsed = 0,
    int limit = AppConstants.freeSimulationsPerMonth,
  }) {
    final entitlement = info.entitlements.active[AppConstants.entitlementPro];

    if (entitlement == null) {
      // Was ever subscribed but now lapsed?
      final previous = info.entitlements.all[AppConstants.entitlementPro];
      return SubscriptionState(
        status: previous != null
            ? SubscriptionStatus.expired
            : SubscriptionStatus.free,
        simulationsUsedThisMonth: simulationsUsed,
        freeSimulationsLimit: limit,
      );
    }

    final SubscriptionStatus status;
    if (entitlement.periodType == PeriodType.trial ||
        entitlement.periodType == PeriodType.intro) {
      status = SubscriptionStatus.trial;
    } else if (!entitlement.willRenew) {
      status = SubscriptionStatus.cancelledButActive;
    } else {
      status = SubscriptionStatus.active;
    }

    final expiresAt = entitlement.expirationDate != null
        ? DateTime.tryParse(entitlement.expirationDate!)
        : null;
    return SubscriptionState(
      status: status,
      simulationsUsedThisMonth: simulationsUsed,
      freeSimulationsLimit: limit,
      productId: entitlement.productIdentifier,
      store: entitlement.store.name,
      expiresAt: expiresAt,
      willRenew: entitlement.willRenew,
      trialEndsAt: status == SubscriptionStatus.trial ? expiresAt : null,
    );
  }

  factory SubscriptionState.fromUserProfile(dynamic user) {
    if (user == null) return SubscriptionState.initialFree();
    final bool pro = user.isPro as bool? ?? false;
    return SubscriptionState(
      status: pro ? SubscriptionStatus.active : SubscriptionStatus.free,
      simulationsUsedThisMonth: user.simulationsUsedThisMonth as int? ?? 0,
      freeSimulationsLimit: user.freeSimulationsLimit as int? ??
          AppConstants.freeSimulationsPerMonth,
      trialEndsAt: user.trialEndsAt as DateTime?,
    );
  }

  factory SubscriptionState.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String?;
    SubscriptionStatus status;
    if (statusStr != null) {
      status = SubscriptionStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => SubscriptionStatus.free,
      );
    } else {
      final isPro = json['isPro'] as bool? ?? json['is_pro'] as bool? ?? false;
      status = isPro ? SubscriptionStatus.active : SubscriptionStatus.free;
    }

    return SubscriptionState(
      status: status,
      simulationsUsedThisMonth:
          (json['simulationsUsedThisMonth'] ?? json['simulations_used_this_month'])
              as int? ?? 0,
      freeSimulationsLimit:
          (json['freeSimulationsLimit'] ?? json['free_simulations_limit'])
              as int? ?? AppConstants.freeSimulationsPerMonth,
      productId: json['productId'] as String?,
      store: json['store'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
      willRenew: json['willRenew'] as bool? ?? false,
      trialEndsAt: json['trialEndsAt'] != null
          ? DateTime.tryParse(json['trialEndsAt'].toString())
          : null,
    );
  }

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    int? simulationsUsedThisMonth,
    int? freeSimulationsLimit,
    String? productId,
    String? store,
    DateTime? expiresAt,
    DateTime? purchasedAt,
    bool? willRenew,
    DateTime? trialEndsAt,
    // ignored — kept for source compat with callers that pass these
    bool? isPro,
    String? activePackageId,
    DateTime? renewalDate,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      simulationsUsedThisMonth:
          simulationsUsedThisMonth ?? this.simulationsUsedThisMonth,
      freeSimulationsLimit: freeSimulationsLimit ?? this.freeSimulationsLimit,
      productId: productId ?? this.productId,
      store: store ?? this.store,
      expiresAt: expiresAt ?? this.expiresAt,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      willRenew: willRenew ?? this.willRenew,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
    );
  }
}
