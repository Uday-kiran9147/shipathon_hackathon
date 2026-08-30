# Overflow Prevention Cheatsheet: The 10 Commandments

## 1. Never Place Unbounded Text in a Horizontal `Row`
When a `Text` widget is inside a `Row`, wrap it in `Expanded` or `Flexible`. Otherwise, when the string is wider than the remaining horizontal space, Flutter will throw a `RenderFlex overflowed by X pixels` exception.

## 2. Replace Static Horizontal `Row`s with `Wrap` for Dynamic Chips
Whenever rendering a list of tags, badges, chips, or filters, use `Wrap` with `spacing: 8.w` and `runSpacing: 6.h`. This ensures chips gracefully flow onto line 2 on small screens (320px) rather than bursting out of the screen.

## 3. Scale Critical Numeric Metrics with `FittedBox`
When displaying KPI counters, prices, or multipliers, wrap them in:
```dart
FittedBox(
  fit: BoxFit.scaleDown,
  alignment: Alignment.centerLeft,
  child: Text(value, style: AppTypography.monoData),
)
```
This guarantees the numbers stay fully visible even under high accessibility font scaling.

## 4. Use `minHeight` / `minWidth` Constraints Instead of Fixed Dimensions
Instead of `Container(height: 48.h, child: ...)`, use:
```dart
Container(
  constraints: BoxConstraints(minHeight: 48.h),
  child: ...,
)
```
This allows the container to expand organically if the user's OS is configured with large text sizing (`TextScaler.linear(1.4x)`).

## 5. Enable Smooth Vertical Scrolling for Dialogs and Sheets
Always wrap bottom sheets and modals in a scrollable view:
```dart
SingleChildScrollView(
  physics: const BouncingScrollPhysics(),
  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [...],
  ),
)
```

## 6. Use `LayoutBuilder` for Breakpoint-Aware Components
```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 360) {
      return Column(children: [widgetA, SizedBox(height: 8.h), widgetB]);
    }
    return Row(children: [Expanded(child: widgetA), SizedBox(width: 12.w), Expanded(child: widgetB)]);
  },
)
```

## 7. Pair ScreenUtil with Intrinsic Safe Insets
Always use `.w`, `.h`, `.r`, and `.sp` alongside `SafeArea` to handle device notches, dynamic islands, and home indicators.

## 8. Never Restrict Card Titles to Single-Line
Titles should be allowed to wrap naturally:
```dart
Text(
  title,
  style: AppTypography.titleMedium,
  softWrap: true,
  // ❌ Do NOT add maxLines: 1 or overflow: TextOverflow.ellipsis
)
```

## 9. Only Use Ellipsis on Intentional Body Previews
Keep `TextOverflow.ellipsis` strictly reserved for multiline body paragraphs where tapping opens the complete modal or screen.

## 10. Audit Small Viewports in Widget Tests
Always test widgets on standard (390x844), compact (360x640), and ultra-narrow (320x568) viewport configurations before merging.
