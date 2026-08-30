# Prevue - Fast Pre-Flight Ship & Safety Audit (PowerShell)
# Usage: powershell -ExecutionPolicy Bypass -File .agents/skills/safe-ship-and-deploy/scripts/preflight_check.ps1

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  🛡️ PREVUE PRE-FLIGHT SHIP & SAFETY AUDIT            " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

# 1. Check for .env exclusion in Git
Write-Host "`n[1/4] Checking .gitignore and secret protection..." -ForegroundColor Yellow
$gitIgnore = Get-Content .gitignore -Raw -ErrorAction SilentlyContinue
if ($gitIgnore -match "^\.env" -or $gitIgnore -match "\n\.env") {
    Write-Host "✅ .env is safely ignored in .gitignore" -ForegroundColor Green
} else {
    Write-Host "⚠️ WARNING: .env might not be ignored in .gitignore!" -ForegroundColor Yellow
}

# 2. Run Quality Gate (flutter analyze)
Write-Host "`n[2/4] Verifying static analysis..." -ForegroundColor Yellow
$analyzeOutput = & flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Static analysis failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ 0 analyzer warnings found." -ForegroundColor Green

# 3. Run Automated Tests
Write-Host "`n[3/4] Running automated tests..." -ForegroundColor Yellow
$testOutput = & flutter test --no-pub
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Tests failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ All tests passed." -ForegroundColor Green

# 4. Check Assets and Build Bundle
Write-Host "`n[4/4] Verifying Flutter build bundle..." -ForegroundColor Yellow
$bundleOutput = & flutter build bundle
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build bundle failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Flutter asset bundle built cleanly." -ForegroundColor Green

Write-Host "`n====================================================" -ForegroundColor Cyan
Write-Host "🚀 SHIP READY: All pre-flight safety gates passed!" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Cyan
exit 0
