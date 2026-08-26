# Prevue Development & Vibe Coding Guardrails

## 1. Core Architecture
- **Framework:** Flutter (Dart 3.x)
- **State Management:** Provider
- **Responsiveness:** `flutter_screenutil` is strictly required for all widths (`.w`), heights (`.h`), radii (`.r`), and fonts (`.sp`).
- **Theme:** Exclusively **Curated Studio Light** (#FAFAFC canvas, #FFFFFF tactile cards, #1E3A8A / #2563EB cobalt accents, #059669 jade outlier green, #E11D48 ruby hazard red).

## 2. Design System & Code Quality Rules
- **No hardcoded magic colors or raw TextStyles:** Always use `AppColors` and `AppTypography`.
- **Tactile UI:** Apply spring physics feedback (`TactileCard`) on interactive cards and buttons.
- **Robust SDK wrappers:** `RevenueCatService` handles live API calls with graceful mock fallback so app is 100% demo-ready.
- **Zero-Lint Standard:** Always run `flutter analyze` and maintain zero warnings.
