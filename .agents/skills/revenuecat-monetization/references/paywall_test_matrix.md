# RevenueCat Paywall & Entitlement Test Matrix

| Test Scenario | Input / Action | Expected Result | Pass Criteria |
| :--- | :--- | :--- | :--- |
| **New User Initialization** | App boots fresh | `isPro = false`, `simulationsUsed = 0`, `freeLimit = 3` | Free badge visible on simulator |
| **Simulations 1–3** | Trigger simulations 1 to 3 | Simulations run and decrement remaining count | Count updates (1/3, 2/3, 3/3) |
| **Simulation 4 Intercept** | Attempt 4th simulation | Paywall bottom sheet presents modally | Block simulator until upgraded |
| **Annual Package Select** | Tap Annual tier in Paywall | Selects Annual ($149.00/yr) with "Save 38%" badge highlighted | Highlight border shifts |
| **Monthly Package Select**| Tap Monthly tier in Paywall| Selects Monthly ($19.99/mo) | Highlight border shifts |
| **Simulated Purchase** | Tap "Start 7-Day Free Trial" | Purchase succeeds, `isPro = true`, sheet dismisses | Unlimited badge unlocks |
| **Restore Purchases** | Tap "Restore Purchases" | Restores entitlement status and displays confirmation | UI updates immediately |
| **Offline / No API Key** | Launch with empty `.env` | Mock offering loaded seamlessly without error crash | Demo runs flawlessly |

---

## Entitlement Mapping Table

```dart
// Entitlement constant
const String kCreatorProEntitlement = 'creator_pro_access';

// Offering constant
const String kDefaultOfferingId = 'default_creator_offering';
```
