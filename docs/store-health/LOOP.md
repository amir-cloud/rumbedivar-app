# Store Health Loop — dispatch doc

**Type:** regulator (nightly). **Authority:** fix + verify, human merges. Never auto-commit.

## Goal (machine-decidable)

Judge script `scripts/store_health_check.ps1` exits 0:
- `flutter analyze --no-pub` → 0 ` error -` lines
- `flutter test` → exit 0, `All tests passed!`, passed count ≥ 22
- Store files present and wired (PrivacyInfo, backup rules + device-transfer, INTERNET, FLAG_SECURE, ITSAppUsesNonExemptEncryption, fa locale, flutter_localizations)

## Boundaries (anti-Goodhart)

- Must NOT delete or weaken any `test/` file to pass.
- Must NOT lower the 22-test floor.
- Must NOT commit, push, or publish. Human flips the done switch.
- Must NOT add tracking/ads SDKs or new permissions without updating Data Safety + Privacy Manifest in the same diff.

## Damping

- Max 3 fix-verify rounds per run, then escalate to human with the judge report.
- Dead-band: green runs change only `docs/store-health/STATE.md`. No noise.
- Cron (Windows Task Scheduler example): nightly `powershell -ExecutionPolicy Bypass -File scripts/store_health_check.ps1`.
  On RED, open the report under `docs/store-health/reports/` and run `/store-health --fix`.

## Human gate

The loop advances state only to "awaiting verification". Merge / submit to Play + App Store is human-only.

## Baseline (2026-11-10)

- analyze errors: 0 (70 info lints)
- tests: 22/22 pass
- store files: all present
