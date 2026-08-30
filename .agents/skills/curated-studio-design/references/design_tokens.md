# Curated Studio Design Tokens & Style Guide

## 1. Color Palette Tokens (`AppColors`)

| Token Name | Hex Code | Purpose |
| :--- | :--- | :--- |
| `AppColors.background` | `#FAFAFC` | App canvas background (Warm Alabaster) |
| `AppColors.cardSurface` | `#FFFFFF` | Elevated tactile cards and bottom sheets |
| `AppColors.cardBorder` | `#E4E4E7` | 1px subtle card outlines |
| `AppColors.primaryCobalt` | `#1E3A8A` | Deep brand cobalt (headings, primary accents) |
| `AppColors.electricCobalt` | `#2563EB` | Vibrant interaction cobalt (active states, links) |
| `AppColors.jadeGreen` | `#059669` | Conviction score, outlier lift, success status |
| `AppColors.rubyHazard` | `#E11D48` | Drop-off hazard scrubber, warnings, paywall badge |
| `AppColors.amberWarning` | `#D97706` | Medium vulnerability warnings, caution badges |
| `AppColors.textPrimary` | `#09090B` | Primary headings, title copy, high-contrast text |
| `AppColors.textSecondary` | `#71717A` | Subtitles, metadata labels, secondary copy |
| `AppColors.textMuted` | `#A1A1AA` | Disabled text, subtle timestamps, placeholders |
| `AppColors.shimmerBase` | `#F4F4F5` | Loading skeleton base color |
| `AppColors.shimmerHighlight`| `#FAFAFA` | Loading skeleton shimmer sweep |

---

## 2. Typography Tokens (`AppTypography`)

Prevue utilizes clean, legible, modern typography powered by `GoogleFonts.inter` and `GoogleFonts.jetBrainsMono` for numerical data:

| Style Token | Size / Weight | Intended Usage |
| :--- | :--- | :--- |
| `AppTypography.displayLarge` | `28.sp`, Bold (700) | Hero headers, primary screen titles |
| `AppTypography.headlineMedium` | `20.sp`, SemiBold (600) | Section titles, sheet headings |
| `AppTypography.titleMedium` | `16.sp`, SemiBold (600) | Blueprint card titles, feature labels |
| `AppTypography.bodyMedium` | `14.sp`, Regular (400) | Body copy, descriptions, hook scripts |
| `AppTypography.bodySmall` | `12.sp`, Regular (400) | Metadata footnotes, secondary explanations |
| `AppTypography.monoData` | `13.sp`, Medium (500) | Metric counts, timestamps, multiplier badges (`2.4x`) |

---

## 3. Elevation & Shadows

Tactile cards use subtle diffusion shadows rather than heavy black drop-shadows:
```dart
BoxShadow(
  color: Colors.black.withOpacity(0.04),
  blurRadius: 12.r,
  offset: Offset(0, 4.h),
)
```
