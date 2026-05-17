$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Full E2E Test + Reinstall Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`n[1/4] Running Part 1: Full E2E Flow Test..." -ForegroundColor Yellow
Set-Location e:\test\1\app
flutter test integration_test/full_flow_test.dart -d emulator-5554 2>&1 | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE -ne 0) {
    Write-Host "Part 1 FAILED!" -ForegroundColor Red
    exit 1
}
Write-Host "`nPart 1 PASSED!" -ForegroundColor Green

Write-Host "`n[2/4] Clearing app data (simulates uninstall)..." -ForegroundColor Yellow
$adbPath = "E:\Android_SDK\platform-tools\adb.exe"

# Install APK first (test may have uninstalled it)
Write-Host "  Installing APK..." -ForegroundColor Gray
& $adbPath -s emulator-5554 install e:\test\1\app\build\app\outputs\flutter-apk\app-debug.apk 2>&1 | ForEach-Object { Write-Host "  $_" }

$clearResult = & $adbPath -s emulator-5554 shell pm clear com.xhscreator.xhs_creator 2>&1
Write-Host "  Clear result: $clearResult" -ForegroundColor Gray
if ($clearResult -notmatch "Success") {
    Write-Host "Failed to clear app data: $clearResult" -ForegroundColor Red
    exit 1
}
Write-Host "App data cleared successfully!" -ForegroundColor Green

Write-Host "`n[3/4] Running Part 2: Reinstall Persistence Test..." -ForegroundColor Yellow
flutter test integration_test/reinstall_test.dart -d emulator-5554 2>&1 | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE -ne 0) {
    Write-Host "Part 2 FAILED!" -ForegroundColor Red
    exit 1
}
Write-Host "`nPart 2 PASSED!" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  ALL TESTS PASSED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
