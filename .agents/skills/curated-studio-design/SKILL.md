---
name: curated-studio-design
description: >-
  Design system and tactile UI accelerator for Prevue's Curated Studio Light theme.
  Use this skill whenever creating or editing UI screens, cards, buttons, badges,
  gauges, or responsive layouts to guarantee consistent visual hierarchy and spring-physics polish.
---

# Curated Studio Design System & Tactile UI Accelerator

This skill guides the creation and refactoring of user interface components in Prevue, adhering strictly to the **Curated Studio Light** aesthetic and tactile micro-interaction patterns.

## Core Visual Palette

The app features an editorial studio light aesthetic:
- **Canvas / Background**: Warm Alabaster (`AppColors.background` = `#FAFAFC`)
- **Cards & Surfaces**: Pure White (`AppColors.cardSurface` = `#FFFFFF`) with subtle 1px border (`#E4E4E7`)
- **Primary Cobalt**: `#1E3A8A` (Deep Cobalt) and `#2563EB` (Electric Cobalt)
- **Conviction Jade (Success/Outlier)**: `#059669` (Jade Green)
- **Retention Ruby (Hazard/Alert)**: `#E11D48` (Ruby Red)
- **Editorial Gray Palette**: `#09090B` (Text Primary), `#71717A` (Text Secondary), `#A1A1AA` (Muted)

Refer to the complete [Design Tokens Reference](./references/design_tokens.md).

---

## Tactile UI Principles

All interactive cards, buttons, and badges must provide micro-sensory spring physics:

### 1. TactileCard Wrapper
Always wrap actionable cards in `TactileCard`:
```dart
TactileCard(
  onTap: () => _handleCardSelection(blueprint),
  padding: EdgeInsets.all(16.r),
  borderRadius: BorderRadius.circular(16.r),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Card content
    ],
  ),
)
```

### 2. Spring Physics Buttons (`SolidHeavyButton`)
Primary call-to-actions (CTAs) should use `SolidHeavyButton` with an optional icon and loading spinner support:
```dart
SolidHeavyButton(
  label: 'Simulate Pre-Flight',
  icon: Icons.rocket_launch_rounded,
  onPressed: () => _runSimulation(),
  isLoading: isSimulating,
)
```

### 3. Responsive Badges (`ResponsiveBadge`)
Use `ResponsiveBadge` for pill tags, category tags, conviction scores, and format chips:
```dart
ResponsiveBadge(
  label: 'CONVICTION 9.4',
  backgroundColor: AppColors.jadeGreen.withOpacity(0.12),
  textColor: AppColors.jadeGreen,
  icon: Icons.verified_rounded,
)
```

See the complete working snippet in [Tactile Card Reference Example](./examples/tactile_card_example.dart).

---

## ScreenUtil Rules of Engagement

To support all device sizes without rendering pixel overflow:
1. **Never hardcode raw double values for sizing**:
   - ❌ `padding: EdgeInsets.all(16)`
   - ✅ `padding: EdgeInsets.all(16.r)`
2. **Horizontal Spacing**:
   - ❌ `SizedBox(width: 12)`
   - ✅ `SizedBox(width: 12.w)`
3. **Vertical Spacing**:
   - ❌ `SizedBox(height: 24)`
   - ✅ `SizedBox(height: 24.h)`
4. **Font Sizing**:
   - ❌ `fontSize: 18`
   - ✅ `fontSize: 18.sp`

---

## Safety & Quality Checks
- ⚠️ **Zero Magic Numbers**: Use standard spacing constants (`8.r`, `12.r`, `16.r`, `20.r`, `24.r`).
- ⚠️ **Zero Dark Theme Artifacts**: Ensure text remains high-contrast `#09090B` on white cards and `#FAFAFC` canvas.
- ⚠️ **No Raw Container Gestures**: Use `TactileCard` or `InkWell` with ripple over raw `GestureDetector` to provide responsive tactile feedback.
