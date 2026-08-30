# Ellipsis Decision Matrix: Strict UI Rules

## The Anti-Pattern: "Lazy Ellipsis"
Applying `overflow: TextOverflow.ellipsis` to short text strings (like titles, buttons, badges, metrics, or table headers) is an anti-pattern. It creates frustrating user experiences where essential information is obscured (e.g. `$14...`, `Start Free...`, `Daily Br...`, `CONVICTION...`).

---

## Component Decision Guide

| UI Component | Ellipsis Permitted? | Recommended Alternative Pattern | Example Snippet |
| :--- | :---: | :--- | :--- |
| **App Bar Titles** | ❌ **NO** | `Expanded` + `softWrap: true` or responsive font size with `FittedBox` | `FittedBox(fit: BoxFit.scaleDown, child: Text(title))` |
| **Card Primary Titles** | ❌ **NO** | Multi-line wrap (`softWrap: true`) without artificial `maxLines: 1` limits | `Expanded(child: Text(title, softWrap: true))` |
| **Action Buttons / CTAs** | ❌ **NO** | `FittedBox(fit: BoxFit.scaleDown)` + minimum padding | `FittedBox(fit: BoxFit.scaleDown, child: Text(label))` |
| **Badges / Status Pills** | ❌ **NO** | Wrap chips in `Wrap(spacing: 8.w, runSpacing: 6.h)` | `Wrap(children: badges)` |
| **Currency & Numbers** | ❌ **NO** | `FittedBox(fit: BoxFit.scaleDown)` with mono font | `FittedBox(fit: BoxFit.scaleDown, child: Text('\$149/yr'))` |
| **Metric Multipliers** | ❌ **NO** | `FittedBox` or flex container with `JetBrainsMono` | `FittedBox(child: Text('2.4x Multiplier'))` |
| **Navigation Tab Labels** | ❌ **NO** | Compact label strings + responsive icon alignment | `FittedBox(fit: BoxFit.scaleDown, child: Text(tabLabel))` |
| **Retention Hazards (Timestamps)**| ❌ **NO** | Explicit width or `IntrinsicWidth` | `Text('0:12 - 0:24', style: AppTypography.monoData)` |
| **Long Descriptions / Body** | ✅ **YES** | Multi-line paragraph preview with `maxLines: 2` or `3` | `Text(desc, maxLines: 3, overflow: TextOverflow.ellipsis)` |
| **Comment Quote Snippets** | ✅ **YES** | Multi-line excerpt with `maxLines: 2` and link to full modal | `Text(comment, maxLines: 2, overflow: TextOverflow.ellipsis)` |
| **Thumbnail Concept Summaries** | ✅ **YES** | Preview card with `maxLines: 2` | `Text(concept, maxLines: 2, overflow: TextOverflow.ellipsis)` |

---

## Golden Rules for Code Reviews
1. **Audit every `TextOverflow.ellipsis`**: If the target widget is a button, badge, header, or metric, **reject the edit** and replace it with `Expanded`, `Wrap`, or `FittedBox`.
2. **Never wrap `Text` in fixed-width `SizedBox` without `Expanded`**: Avoid `SizedBox(width: 80.w, child: Text('...'))` which forces premature clipping on varying fonts.
