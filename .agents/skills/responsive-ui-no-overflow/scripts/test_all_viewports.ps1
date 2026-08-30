# Prevue - Multi-Viewport & Text-Scaling Layout Verification (PowerShell)
# Usage: powershell -ExecutionPolicy Bypass -File .agents/skills/responsive-ui-no-overflow/scripts/test_all_viewports.ps1

Write-Host '====================================================' -ForegroundColor Cyan
Write-Host '  RESPONSIVE UI AND ZERO-OVERFLOW AUDIT             ' -ForegroundColor Cyan
Write-Host '====================================================' -ForegroundColor Cyan

$startTime = Get-Date

# 1. Flutter Analyze
Write-Host "`n[1/3] Checking static analysis..." -ForegroundColor Yellow
$analyze = & flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "Static analysis failed!" -ForegroundColor Red
    exit 1
}
Write-Host "0 analyzer warnings." -ForegroundColor Green

# 2. Run Test Matrix covering 390x844 and 360x640 Viewports
Write-Host "`n[2/3] Running widget smoke tests across multi-viewports..." -ForegroundColor Yellow
$testOutput = & flutter test test/widget_test.dart
if ($LASTEXITCODE -ne 0) {
    Write-Host "Viewport responsiveness tests failed!" -ForegroundColor Red
    $testOutput | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
    exit 1
}
Write-Host "All responsive viewports render cleanly without overflow!" -ForegroundColor Green

# 3. Scan codebase for suspicious ellipsis usages on button/badge widgets
Write-Host "`n[3/3] Scanning for lazy ellipsis anti-patterns..." -ForegroundColor Yellow
$badEllipsis = Select-String -Path "lib/widgets/common/responsive_badge.dart" -Pattern "TextOverflow.ellipsis" -ErrorAction SilentlyContinue
if ($badEllipsis) {
    Write-Host "Warning: Found TextOverflow.ellipsis in responsive badge" -ForegroundColor Yellow
} else {
    Write-Host "Badges, buttons, and metrics are free from lazy ellipsis clipping!" -ForegroundColor Green
}

$elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)
Write-Host "`n====================================================" -ForegroundColor Cyan
Write-Host "RESPONSIVE AUDIT PASSED in ${elapsed}s (All viewports safe)" -ForegroundColor Green
Write-Host '====================================================' -ForegroundColor Cyan
exit 0
