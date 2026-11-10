# Store Health Loop

Nightly regulator for Play + App Store readiness. Acts only on change. Fixes + verifies. Human merges.

## Usage

`/store-health` — run one judge iteration now.
`./scripts/store_health_check.ps1` — same judge as a script (CI/cron friendly).

## One iteration

1. Run the judge: `powershell -ExecutionPolicy Bypass -File scripts/store_health_check.ps1`
2. Exit 0 = green, do nothing. Exit 1 = red, fix only the listed failures.
3. Fix budget: max 3 edit-verify rounds per night, then stop and escalate to human.
4. Re-run the judge after each fix round. Stop when green.
5. Never commit. Leave the diff for human review.

## Judge (deterministic, independent)

- `flutter analyze --no-pub`: 0 lines matching ` error -` required.
- `flutter test`: exit 0 required, test count must not drop below 22.
- Store files present: `PrivacyInfo.xcprivacy`, `backup_rules.xml` + `data_extraction_rules.xml` (with `device-transfer`), `INTERNET` permission, `FLAG_SECURE`, `ITSAppUsesNonExemptEncryption=false`, `fa` locale, `flutter_localizations` + `intl ^0.20.3`.
- Boundary: no `test/` file may be deleted or weakened to pass. `git status --short test/` showing `D` = instant fail.

## Dead-band

Green runs produce no diff, no report noise — only `docs/store-health/STATE.md` timestamp update. Act only on red.

## Arguments

$ARGUMENTS:
- `--fix` optional (allow up to 3 fix-verify rounds this run)
- `--strict` optional (also fail on new analyzer infos vs baseline)
