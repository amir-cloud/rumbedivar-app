#Requires -Version 5.1
<#
.SYNOPSIS
  Nightly store-health judge for rumbedivar (Flutter shopping app).
  Deterministic only: NEVER edits code. Exit 0 = green, 1 = red.
#>
param(
  [string]$FlutterBin = "D:\flutter\bin\flutter.bat",
  [string]$ReportDir = "docs/store-health/reports",
  [int]$MinTests = 22
)

$ErrorActionPreference = "Continue"
$failures = @()
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not (Test-Path (Join-Path $root "pubspec.yaml"))) { $root = Get-Location }
Set-Location $root

function Add-Fail([string]$m) { $script:failures += $m }

# 1. Boundary: no test deletions
$testStatus = (git status --short test/ 2>$null) -join "`n"
if ($testStatus -match "^D| D ") { Add-Fail "BOUNDARY: test file deleted in working tree" }

# 2. Analyzer: zero errors
$analyzeOut = (& $FlutterBin analyze --no-pub 2>&1) -join "`n"
$errCount = ([regex]::Matches($analyzeOut, " error -")).Count
if ($errCount -gt 0) { Add-Fail "ANALYZE: $errCount error(s)" }

# 3. Tests
$testOut = (& $FlutterBin test 2>&1) -join "`n"
if ($LASTEXITCODE -ne 0) { Add-Fail "TEST: flutter test exit $LASTEXITCODE" }
$passed = 0
$all = [regex]::Matches($testOut, "\+(\d+)")
if ($all.Count -gt 0) { $passed = [int]$all[$all.Count - 1].Groups[1].Value }
if ($testOut -notmatch "All tests passed!") { Add-Fail "TEST: not all green" }
if ($passed -lt $MinTests) { Add-Fail "TEST: passed=$passed below min=$MinTests (no weakening)" }

# 4. Store files
$checks = @{
  "ios/Runner/PrivacyInfo.xcprivacy" = $true
  "android/app/src/main/res/xml/backup_rules.xml" = $true
  "android/app/src/main/res/xml/data_extraction_rules.xml" = $true
}
foreach ($f in $checks.Keys) {
  if (-not (Test-Path $f)) { Add-Fail "STORE-FILE missing: $f" }
}
$manifest = Get-Content "android/app/src/main/AndroidManifest.xml" -Raw -ErrorAction SilentlyContinue
if ($manifest -notmatch "INTERNET") { Add-Fail "STORE: INTERNET permission missing" }
$dxr = Get-Content "android/app/src/main/res/xml/data_extraction_rules.xml" -Raw -ErrorAction SilentlyContinue
if ($dxr -notmatch "device-transfer") { Add-Fail "STORE: device-transfer block missing" }
$mainAct = Get-Content "android/app/src/main/kotlin/com/example/rumbedivar/MainActivity.kt" -Raw -ErrorAction SilentlyContinue
if ($mainAct -notmatch "FLAG_SECURE") { Add-Fail "STORE: FLAG_SECURE missing" }
$plist = Get-Content "ios/Runner/Info.plist" -Raw -ErrorAction SilentlyContinue
if ($plist -notmatch "ITSAppUsesNonExemptEncryption") { Add-Fail "STORE: ITSAppUsesNonExemptEncryption missing" }
if ($plist -notmatch "<string>fa</string>") { Add-Fail "STORE: fa localization missing" }
$pubspec = Get-Content "pubspec.yaml" -Raw -ErrorAction SilentlyContinue
if ($pubspec -notmatch "flutter_localizations") { Add-Fail "STORE: flutter_localizations missing" }

# 5. Report + state
$stamp = Get-Date -Format "yyyy-MM-dd_HHmm"
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null
$status = if ($failures.Count -eq 0) { "GREEN" } else { "RED" }
$report = Join-Path $ReportDir ("$stamp-$status.md")
$lines = @("# Store health $stamp - $status", "")
if ($failures.Count -eq 0) { $lines += "analyze-errors=0, tests green, store files ok." }
else { $lines += ($failures | ForEach-Object { "- FAIL: $_" }) }
$lines | Out-File -Encoding utf8 $report
@("last_run=$stamp", "status=$status", "failures=$($failures.Count)") | Out-File -Encoding utf8 "docs/store-health/STATE.md"

if ($failures.Count -eq 0) { Write-Output "GREEN: store health ok ($stamp)"; exit 0 }
else { $failures | ForEach-Object { Write-Output ("FAIL: " + $_) }; Write-Output ("Report: " + $report); exit 1 }
