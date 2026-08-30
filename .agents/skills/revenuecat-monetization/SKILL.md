---
name: revenuecat-monetization
description: >-
  Monetization architecture, paywall simulation, and RevenueCat integration skill.
  Use this skill to configure, test, and verify in-app purchases, entitlement states
  (creator_pro_access), free simulation limit enforcement (3 free / month),
  paywall trigger sheets, and offline mock fallbacks.
---

# RevenueCat Monetization & Paywall Simulator

This skill manages the monetization layer for Prevue, handling in-app purchases via RevenueCat SDK, entitlement lifecycle verification, paywall modal presentations, and deterministic offline mock fallbacks.

## Monetization Configuration Specification

- **Entitlement ID**: `creator_pro_access`
- **Offering ID**: `default_creator_offering`
- **Packages**:
  - **Monthly Pro**: `$19.99 / month` (`PackageType.monthly`)
  - **Annual Pro (Best Value)**: `$149.00 / year` (`PackageType.annual` • Save 38% + 7-Day Free Trial)
- **Free Tier Policy**:
  - Free users are granted **3 simulations per month**.
  - Initiating the 4th simulation triggers `CreatorProPaywallSheet`.
  - Upgrading to `creator_pro_access` grants unlimited simulations and advanced retention diagnostics.

---

## Testing & Verification Workflow

### 1. Free Limit Gating Verification
Verify that the `SubscriptionProvider` accurately tracks simulation counts:
1. Initialize a new session. `simulationsUsed` should start at `0 / 3`.
2. Run Simulation 1, 2, and 3: Verify simulator executes normally.
3. Attempt Simulation 4: The system must intercept the action and display `CreatorProPaywallSheet`.

### 2. Live vs. Mock Fallback Resilience
`RevenueCatService` is architected with zero-crash fallback:
- When a valid `REVENUECAT_API_KEY` (e.g. `appl_...` or `goog_...`) is provided in `.env`, the live SDK initializes.
- If no key is set or the device is offline, `RevenueCatService` gracefully serves mock offerings with simulated purchase confirmation.
- **Safety Rule**: App must NEVER crash or hang due to RevenueCat network timeouts or missing API keys.

### 3. Paywall Sheet Micro-Interactions
Inspect `CreatorProPaywallSheet`:
- Visual hierarchy: High-converting hero badge, trial countdown indicator, package toggle (Annual vs. Monthly).
- Restore Purchases button: Calls `SubscriptionProvider.restorePurchases()` with immediate feedback snackbar.
- Terms & Privacy policy links: Accessible and compliant with App Store / Google Play guidelines.

Refer to the complete [Paywall Test Matrix](./references/paywall_test_matrix.md) and [Mock Paywall Fixture Example](./examples/mock_paywall_fixture.dart).

---

## Safety Guardrails
- ⚠️ **Zero Raw Purchase Calls**: Always invoke purchases through `SubscriptionProvider.purchasePackage()` to ensure state synchronization across all UI tabs.
- ⚠️ **Guard Offline Demos**: Ensure offline mock fallback responds in < 300ms so hackathon judges and demo presentations are uninterrupted.
- ⚠️ **Never Hardcode Secrets**: Store all RevenueCat API keys in `.env` and load through `flutter_dotenv`.
