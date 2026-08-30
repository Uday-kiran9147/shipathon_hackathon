---
name: flutter-quality-gate
description: >-
  Fast automated quality verification and safety gate for Flutter/Dart codebases.
  Use this skill to execute fast lint analysis, automated unit/widget tests,
  formatting checks, and ScreenUtil compliance verification before committing or shipping.
---

# Flutter Quality Gate & Zero-Lint Enforcer

This skill provides an ultra-fast, automated quality verification pipeline for Prevue to ensure 100% clean builds, zero compiler/linter warnings, and strict ScreenUtil compliance.

## Quick Execution Runbook

Run the all-in-one verification script to perform static analysis, automated testing, and styling checks in seconds:

### On Windows (PowerShell)
```powershell
powershell -ExecutionPolicy Bypass -File .agents/skills/flutter-quality-gate/scripts/verify_quality.ps1
```

### On macOS / Linux (Bash)
```bash
bash .agents/skills/flutter-quality-gate/scripts/verify_quality.sh
```

---

## Step-by-Step Quality Protocol

### Step 1: Static Analysis & Zero-Lint Check
Ensure that the codebase satisfies all lint rules defined in `analysis_options.yaml` with zero warnings:
```bash
flutter analyze
```
- **Acceptance Criteria**: Output must state `No issues found!`.
- **Remediation**:
  - Remove unused imports and dead variables immediately.
  - Ensure all constructor invocations that can be `const` are marked `const`.
  - Fix all type annotations and avoid raw `dynamic` wherever possible.

### Step 2: Automated Test Suite Execution
Execute the entire widget and unit test matrix:
```bash
flutter test --no-pub
```
- **Acceptance Criteria**: All test suites in `test/` must pass (e.g. `widget_test.dart` containing 16-point creator intelligence and simulator engine tests).
- If running a single target during fast iteration:
  ```bash
  flutter test test/widget_test.dart
  ```

### Step 3: ScreenUtil Responsiveness & Token Check
Inspect newly edited UI widgets to ensure strict compliance with responsive tokens:
1. **Dimensions**: Verify that widths use `.w`, heights use `.h`, radii use `.r`, and fonts use `.sp`.
2. **Colors**: Prohibit raw hexadecimal `Color(0x...)` or `Colors.blue` in UI files; use `AppColors.*` tokens exclusively.
3. **Typography**: Prohibit raw `TextStyle(...)` instantiation; use `AppTypography.*` or `Theme.of(context).textTheme.*`.

Refer to the complete [Quality Checklist & Remediation Guide](./references/quality_checklist.md).

---

## Fast Verification Commands Cheatsheet

| Task | Fast Command | Time Target |
| :--- | :--- | :--- |
| **Lint Analysis** | `flutter analyze` | < 15s |
| **All Tests** | `flutter test --no-pub` | < 10s |
| **Single Test Group** | `flutter test --plain-name "Comment Demand"` | < 5s |
| **Format Check** | `dart format --output=none --set-exit-if-changed lib/ test/` | < 3s |
| **Dependency Audit** | `flutter pub deps --style=compact` | < 5s |

---

## Safety Guardrails
- ⚠️ **Never commit with open analyzer warnings**: Any warning in `flutter analyze` blocks deployment.
- ⚠️ **Never bypass tests with skip annotations**: Keep all unit and widget tests green.
- ⚠️ **Maintain const constructors**: Ensures maximum Flutter frame rendering performance (60/120 FPS).
