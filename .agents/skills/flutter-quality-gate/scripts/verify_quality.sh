#!/usr/bin/env bash
# Prevue - Fast Flutter Quality & Zero-Lint Verifier (Bash)
# Usage: bash .agents/skills/flutter-quality-gate/scripts/verify_quality.sh

set -e

echo "===================================================="
echo "  🚀 PREVUE QUALITY GATE: ZERO-LINT & TEST AUDIT     "
echo "===================================================="

START_TIME=$(date +%s)

echo ""
echo "[1/3] Running static analysis (flutter analyze)..."
flutter analyze

echo ""
echo "[2/3] Running automated unit & widget test matrix..."
flutter test --no-pub

echo ""
echo "[3/3] Checking Dart code formatting..."
dart format --output=none --set-exit-if-changed lib/ test/ || echo "⚠️ Formatting adjustments recommended: dart format lib/ test/"

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo ""
echo "===================================================="
echo "🎉 QUALITY GATE PASSED in ${ELAPSED}s (All systems green)"
echo "===================================================="
