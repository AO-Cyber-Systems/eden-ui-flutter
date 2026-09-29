---
generated: "2026-09-29"
profile: "flutter"
profile_source: file
components: ["lints/"]
counts: { gap: 4, weak: 4, info: 9 }
---

# Stack Report: eden-ui-flutter

Proposals only — nothing here has been applied. Review, then change CI/runners yourself.

## Gaps

| ID | Component | Finding | Evidence | Proposal |
|---|---|---|---|---|
| DART-FORMAT | (root) | CI has no Dart format check | pubspec.yaml | Fail CI on unformatted Dart. `dart format --output=none --set-exit-if-changed .` |
| LOCAL-MIRROR | (root) | gates run only in CI, with no local runner target: lint (flutter analyze --no-fatal-infos), test (flutter test) | .github/workflows/ci.yml:analyze: flutter analyze --no-fatal-infos; .github/workflows/ci.yml:test: flutter test | Add a task/make/just target per STACK.md key so each CI gate also runs locally. Keys: lint, test. |
| DART-FORMAT | lints/ | CI has no Dart format check | lints/pubspec.yaml | Fail CI on unformatted Dart. `dart format --output=none --set-exit-if-changed .` |
| LOCAL-MIRROR | lints/ | gates run only in CI, with no local runner target: lint (flutter analyze --no-fatal-infos), test (flutter test) | .github/workflows/ci.yml:analyze: flutter analyze --no-fatal-infos; .github/workflows/ci.yml:test: flutter test | Add a task/make/just target per STACK.md key so each CI gate also runs locally. Keys: lint, test. |

## Weak

| ID | Component | Finding | Evidence | Proposal |
|---|---|---|---|---|
| DART-ANALYZE | (root) | Dart analyzer runs in CI but is weakened: --no-fatal-infos | .github/workflows/ci.yml:analyze: flutter analyze --no-fatal-infos; .github/workflows/release.yml:test: flutter analyze --no-fatal-infos | Make analyzer infos and warnings fail the build. `flutter analyze` |
| FLUT-INTEG | (root) | `integration_test/` exists but CI never runs it | integration_test/ | Run the integration tests on a device or emulator in CI. `flutter test integration_test -d <device>` |
| FLUT-MAESTRO | (root) | UI flows exist (`.maestro/` / `patrol_test/`) but nothing runs them | pubspec.yaml | Add end-to-end UI flows and a runner target for them. `maestro test .maestro` |
| DART-ANALYZE | lints/ | Dart analyzer runs in CI but is weakened: --no-fatal-infos | .github/workflows/ci.yml:analyze: flutter analyze --no-fatal-infos; .github/workflows/release.yml:test: flutter analyze --no-fatal-infos | Make analyzer infos and warnings fail the build. `dart analyze --fatal-infos` |

## Info

| ID | Component | Finding | Evidence | Proposal |
|---|---|---|---|---|
| CI-HYGIENE | (root) | workflow hygiene: ci.yml (no permissions:, 10 actions not pinned to a commit SHA, no timeout-minutes, no concurrency); probe-guard.yml (no permissions:, 2 actions not pinned to a commit SHA, no timeout-minutes, no concurrency); release.yml (4 actions not pinned to a commit SHA, no timeout-minutes, no concurrency) | .github/workflows/ci.yml; .github/workflows/probe-guard.yml; .github/workflows/release.yml | Set a least-privilege `permissions:` block, pin actions by SHA, and add `timeout-minutes` and a `concurrency` group. |
| DART-COVER | (root) | CI runs the tests without coverage | pubspec.yaml | Record coverage; `flutter test --coverage` writes coverage/lcov.info. `flutter test --coverage` |
| DART-LOCK | (root) | an app with a committed `pubspec.lock`, resolved in CI without --enforce-lockfile | pubspec.yaml | Resolve exactly the committed lockfile in CI. `flutter pub get --enforce-lockfile` |
| DART-COVER | lints/ | CI runs the tests without coverage | lints/pubspec.yaml | Record coverage; `dart test --coverage=coverage` writes VM JSON under coverage/ (format it to lcov with package:coverage). `dart test --coverage=coverage` |

## Draft notes

| Key | Candidate | Status | Source |
|---|---|---|---|
| lint | `bash tool/lint_gate_assert.sh` | off_stack | ci |
| lint | `flutter analyze --no-fatal-infos` | resolved | ci |
| test | `flutter test test/stories/ --update-goldens` | narrow | ci |
| test | `flutter test test/stories/` | narrow | ci |
| test | `flutter test test/stories/registry_drift_test.dart test/stories/generated_freshness_test.dart` | narrow | ci |
