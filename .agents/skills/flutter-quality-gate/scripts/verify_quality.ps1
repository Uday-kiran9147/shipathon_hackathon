# Prevue - Fast Flutter Quality & Zero-Lint Verifier (PowerShell)
# Usage: powershell -ExecutionPolicy Bypass -File .agents/skills/flutter-quality-gate/scripts/verify_quality.ps1

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  🚀 PREVUE QUALITY GATE: ZERO-LINT & TEST AUDIT     " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

$startTime = Get-Date

# 1. Flutter Analyze
Write-Host "`n[1/3] Running static analysis (flutter analyze)..." -ForegroundColor Yellow
$analyzeOutput = & flutter analyze
$analyzeExitCode = $LASTEXITCODE

if ($analyzeExitCode -ne 0) {
    Write-Host "❌ Static analysis failed with issues:" -ForegroundColor Red
    $analyzeOutput | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
    exit 1
} else {
    Write-Host "✅ Static analysis passed! 0 issues found." -ForegroundColor Green
}

# 2. Flutter Test Matrix
Write-Host "`n[2/3] Running automated unit & widget test matrix..." -ForegroundColor Yellow
$testOutput = & flutter test --no-pub
$testExitCode = $LASTEXITCODE

if ($testExitCode -ne 0) {
    Write-Host "❌ Automated tests failed:" -ForegroundColor Red
    $testOutput | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
    exit 1
} else {
    Write-Host "✅ All tests passed successfully!" -ForegroundColor Green
}

# 3. Formatting Verification
Write-Host "`n[3/3] Checking Dart code formatting..." -ForegroundColor Yellow
$formatOutput = & dart format --output=none --set-exit-if-changed lib/ test/
$formatExitCode = $LASTEXITCODE

if ($formatExitCode -ne 0) {
    Write-Host "⚠️ Code formatting differences detected. Run 'dart format lib/ test/' to fix." -ForegroundColor Yellow
} else {
    Write-Host "✅ Code formatting is clean!" -ForegroundColor Green
}

$elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)
Write-Host "`n====================================================" -ForegroundColor Cyan
Write-Host "🎉 QUALITY GATE PASSED in ${elapsed}s (All systems green)" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Cyan
exit 0
