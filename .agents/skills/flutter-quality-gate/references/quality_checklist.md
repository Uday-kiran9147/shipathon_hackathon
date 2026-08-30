# Flutter Quality & Zero-Lint Reference Checklist

## 1. Zero-Lint & Clean Architecture Rules
- [ ] **No Unused Imports / Variables**: Check `flutter analyze` output before every push.
- [ ] **Always Prefer `const` Constructors**: Add `const` to static widgets, insets (`EdgeInsets.symmetric(...)`), and decorations.
- [ ] **Safe Null-Aware Access**: Never use force unwrap `!` unless preceded by a proven null assertion.
- [ ] **Strict Typing**: Specify generic types for Futures, Streams, Providers, and Collections (`List<DailyBlueprint>` instead of `List`).

## 2. ScreenUtil Responsive Standards
- [ ] **Widths & Horizontal Insets**: Must use `.w` (e.g. `16.w`, `24.w`, `SizedBox(width: 8.w)`).
- [ ] **Heights & Vertical Insets**: Must use `.h` (e.g. `20.h`, `12.h`, `SizedBox(height: 16.h)`).
- [ ] **Border Radii**: Must use `.r` (e.g. `BorderRadius.circular(16.r)`).
- [ ] **Font Sizes**: Must use `.sp` (e.g. `14.sp`, `20.sp`).
- [ ] **EdgeInsets.all / symmetric**: Must apply `.r`, `.w`, or `.h` appropriately (e.g. `EdgeInsets.all(16.r)`).

## 3. Provider & State Lifecycle Safety
- [ ] **Context Mount Checks**: Check `if (!mounted) return;` before calling `notifyListeners()`, `Navigator.pop()`, or `ScaffoldMessenger.showSnackBar()` inside async methods.
- [ ] **Clean Disposal**: Dispose all `TextEditingController`, `AnimationController`, and `ScrollController` instances in `dispose()`.
- [ ] **Efficient Rebuilds**: Use `Selector` or `context.select(...)` for granular state listening when full widget rebuilds are unnecessary.

## 4. Test Integrity Rules
- [ ] **Smoke Tests**: App root `PrevueAPP` must boot cleanly without rendering overflows across 390x844 (standard) and 360x640 (narrow) viewports.
- [ ] **Calculation Verification**: Unit tests must verify boundary conditions for numeric calculations (e.g., predicted performance ladders, conviction scores 0-10, cosine similarities).
