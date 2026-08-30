# Safe Shipping & Production Guardrails

## 1. Secrets & Privacy Rules
- Never push `.env` files containing live API keys (`YOUTUBE_API_KEY`, `REVENUECAT_API_KEY`, `GEMINI_API_KEY`).
- Always maintain `.env.example` with sanitized placeholder keys for new contributors.
- Do not log user data, auth tokens, or private metadata in production output.

---

## 2. Refactoring Safety Protocol
- Before modifying any shared service (e.g. `RevenueCatService`, `BlueprintGeneratorService`, `YouTubeApiService`):
  1. Inspect existing unit tests in `test/widget_test.dart`.
  2. Implement changes while maintaining backward compatibility with data models.
  3. Execute `flutter test` immediately.
  4. Ensure zero warnings in `flutter analyze`.

---

## 3. Demo & Hackathon Preparedness
- Guarantee that all screens render properly offline without network connectivity.
- Verify that bottom navigation switches tabs with sub-100ms response time.
- Verify that Paywall and Configuration sheets open smoothly with tactile spring animation.
