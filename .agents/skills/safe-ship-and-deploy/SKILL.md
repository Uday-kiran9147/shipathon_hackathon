---
name: safe-ship-and-deploy
description: >-
  Pre-flight safety inspection, secret leak protection, and production shipping runbook.
  Use this skill before committing, creating pull requests, or preparing demo builds
  to verify that no secrets are exposed, all quality gates pass, and cross-platform builds succeed.
---

# Safe Refactoring, Secret Protection & Production Ship Gate

This skill enforces high-speed, safety-first protocols across the codebase. It guarantees that refactoring never breaks existing functionality, sensitive credentials are never committed, and release builds compile without errors.

## Pre-Flight Shipping Runbook

Before completing a major feature, milestone, or submission:

### 1. Run Automated Preflight Audit
```powershell
powershell -ExecutionPolicy Bypass -File .agents/skills/safe-ship-and-deploy/scripts/preflight_check.ps1
```

### 2. Secret Leak Scan
Ensure no `.env` files or API secrets are staged:
- Verify `.gitignore` contains `.env`, `*.key`, and build artifacts.
- Verify `git status` does not track any `.env` file containing live credentials.

### 3. Build Sanity Check
Test cross-platform compilation targets:
```bash
# Debug Web / Desktop build check
flutter build bundle
```

Refer to the complete [Safety Guardrails & Release Guide](./references/safety_guardrails.md).

---

## Safety Guardrails
- ⚠️ **Zero Secret Commits**: Never check in production RevenueCat or YouTube keys into source control.
- ⚠️ **Atomic Commits**: Group related changes logically with clear imperative commit messages.
- ⚠️ **Regression Prevention**: Always run `flutter test` after modifying core models or providers.
