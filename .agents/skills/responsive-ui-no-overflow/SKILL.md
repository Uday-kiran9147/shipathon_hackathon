---
name: responsive-ui-no-overflow
description: >-
  Design, build, and refactor Flutter UI/UX to be responsive, tactile, and completely free of
  overflow errors across all screen sizes and accessibility text scalers. Enforces the strict rule
  that TextOverflow.ellipsis is forbidden on headings, buttons, badges, and metrics, and only
  permitted on long multi-line descriptive text.
---

# Responsive UI & Zero-Overflow Architecture Skill

This skill provides comprehensive rules, layout patterns, and validation tools to build modern, beautiful, and tactile Flutter user interfaces that adapt gracefully across all device sizes (from 320px compact screens to tablets and foldables) with **ZERO layout overflows (`RenderFlex overflowed`)** and **NO lazy `.ellipsis` clipping**.

---

## 🛑 The "No Lazy Ellipsis" Golden Rule

> **Never use `TextOverflow.ellipsis` to patch layout overflow bugs on short text, titles, buttons, or badges.**

| UI Element | Ellipsis Allowed? | Correct Responsive Strategy |
| :--- | :---: | :--- |
| **Hero & Screen Titles** | ❌ **FORBIDDEN** | Wrap in `Flexible`, allow natural multi-line wrapping with `softWrap: true` and proper line height. |
| **Action Buttons & CTAs** | ❌ **FORBIDDEN** | Use `FittedBox(fit: BoxFit.scaleDown)` or flexible padding so the label is never truncated. |
| **Badges, Chips, Pills** | ❌ **FORBIDDEN** | Use `Wrap(spacing: ..., runSpacing: ...)` instead of horizontal `Row` to allow chips to flow to the next line. |
| **Numerical Metrics & Currency** | ❌ **FORBIDDEN** | Use `FittedBox(fit: BoxFit.scaleDown)` with `JetBrainsMono` to scale font down cleanly without clipping numbers. |
| **Navigation & Tab Labels** | ❌ **FORBIDDEN** | Auto-scale with `FittedBox` or adapt layout dynamically based on constraints. |
| **Long Descriptions / Body Scripts** | ✅ **ALLOWED** | Multi-line body text paragraphs (e.g. YouTube descriptions, long draft scripts) with explicit `maxLines: 2` or `3` and `TextOverflow.ellipsis`. |

Refer to the complete [Ellipsis Decision Matrix](./references/ellipsis_decision_matrix.md).

---

## 📐 The 7 Principles of Zero-Overflow Flutter Layouts

### 1. The Flexible Row Pattern
Whenever placing text inside a `Row` alongside icons, badges, or other widgets:
```dart
// ❌ WRONG: Unbounded Text causes RenderFlex overflow when title is long
Row(
  children: [
    Icon(Icons.bolt, size: 20.sp),
    SizedBox(width: 8.w),
    Text(title, style: AppTypography.titleMedium), // CRASHES on narrow screens!
  ],
)

// ✅ CORRECT: Flexible allows natural line-wrap or controlled fitting
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Icon(Icons.bolt, size: 20.sp),
    SizedBox(width: 8.w),
    Expanded(
      child: Text(
        title,
        style: AppTypography.titleMedium,
        softWrap: true, // Wraps cleanly to line 2 without overflow or ellipsis
      ),
    ),
  ],
)
```

### 2. The Wrap Pattern for Badges & Filters
Never place multiple dynamic badges or filter chips in a fixed `Row`:
```dart
// ❌ WRONG: Breaks on small devices or when labels are long
Row(
  children: [
    ResponsiveBadge(label: 'CONVICTION 9.4'),
    ResponsiveBadge(label: 'TOP OUTLIER'),
    ResponsiveBadge(label: 'BENCHMARK'),
  ],
)

// ✅ CORRECT: Flow badges onto multiple lines seamlessly
Wrap(
  spacing: 8.w,
  runSpacing: 6.h,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: [
    ResponsiveBadge(label: 'CONVICTION 9.4'),
    ResponsiveBadge(label: 'TOP OUTLIER'),
    ResponsiveBadge(label: 'BENCHMARK'),
  ],
)
```

### 3. Critical Metrics & Currency with `FittedBox`
Ensure important numbers and monetary values are never truncated or replaced with `...`:
```dart
// ✅ CORRECT: Fits cleanly into constrained KPI cards
SizedBox(
  height: 28.h,
  child: FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Text(
      '\$149.00 / yr',
      style: AppTypography.displayLarge.copyWith(color: AppColors.primaryCobalt),
    ),
  ),
)
```

### 4. Dynamic Vertical Scroll Containment
Never lock screens or bottom sheets into rigid vertical `Column`s with fixed heights:
```dart
// ❌ WRONG: Throws bottom overflow when keyboard opens or screen is <700px height
Container(
  height: 500.h,
  child: Column(children: [...]),
)

// ✅ CORRECT: Scrollable viewport with intrinsic min-height
SingleChildScrollView(
  physics: const BouncingScrollPhysics(),
  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [...],
  ),
)
```

### 5. Adaptive Layouts via `LayoutBuilder`
When building components that render on both compact phones (320px) and wide tablets (600px+):
```dart
LayoutBuilder(
  builder: (context, constraints) {
    final isCompact = constraints.maxWidth < 360;
    return isCompact ? _buildVerticalLayout() : _buildHorizontalLayout();
  },
)
```

### 6. Accessibility & Font Scale Safety (`TextScaler`)
Users with accessibility font scaling (`1.3x` - `2.0x`) should not experience broken cards. Always test UI with non-standard text scales.

### 7. Controlled Description Ellipsis
When showing multi-line previews where full text is available via a detail sheet or modal:
```dart
Text(
  longDescription,
  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
  maxLines: 2, // Explicitly intentional for preview card
  overflow: TextOverflow.ellipsis,
)
```

Refer to the full [Overflow Prevention Cheatsheet](./references/overflow_prevention_cheatsheet.md).

---

## 🧪 Multi-Viewport Automated Validation

Run the viewport verification suite to test the UI across multiple simulated screen widths (320px, 360px, 390px, 412px, 768px) and text scalers (1.0x, 1.3x, 1.5x):

```powershell
powershell -ExecutionPolicy Bypass -File .agents/skills/responsive-ui-no-overflow/scripts/test_all_viewports.ps1
```

---

## 🎨 Tactile Polish Guidelines

Pair responsiveness with Curated Studio tactile elegance:
1. **Dynamic Insets**: Use `EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h)` to ensure balanced breathing room.
2. **Min Heights over Fixed Heights**: Use `constraints: BoxConstraints(minHeight: 48.h)` instead of rigid `height: 48.h` on button containers so text expansion never clips.
3. **Inspect Examples**: Check out [Adaptive Metric Card Example](./examples/adaptive_metric_card_example.dart) and [Adaptive Badge Row Example](./examples/adaptive_badge_row_example.dart).
