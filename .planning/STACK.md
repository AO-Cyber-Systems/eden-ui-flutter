---
schema: 1
id: "eden-ui-flutter"
extends: "flutter"
components: [{ path: "lints/", profile: "dart" }]
commands:
  lint: { run: "flutter analyze --no-fatal-infos" }
  build: { run: "bash tool/probe_guard.sh example/probe_smoke" }
  e2e: { run: "maestro test .maestro" }
provenance:
  reviewed: "2026-09-29"
  sources: [".github/workflows/ci.yml", ".github/workflows/probe-guard.yml", ".github/workflows/release.yml", ".maestro/"]
---

# Stack Profile: eden-ui-flutter

<!-- Drafted by `df-tools stack init`. Add no `## ` heading below unless this project genuinely diverges from `flutter`: an empty section would replace the parent's. Recognized sections: Principles, Idioms, Avoid, Layout & architecture, Testing, Dependencies, Generated code, Security, UI. -->

<!-- stack init notes (see .planning/STACK-REPORT.md):
- root lint: bash tool/lint_gate_assert.sh — off_stack (tool stack unknown does not match extends flutter)
- root lint: flutter analyze --no-fatal-infos — resolved (weak gate kept verbatim: --no-fatal-infos)
- root test: flutter test test/stories/registry_drift_test.dart test/stories/generated_freshness_test.dart — narrow (not the repo-wide test (single-path: tests one package or path, not the whole repo))
- root test: flutter test test/stories/ — narrow (not the repo-wide test (single-path: tests one package or path, not the whole repo))
- root test: flutter test test/stories/ --update-goldens — narrow (not the repo-wide test (single-path: tests one package or path, not the whole repo))
-->
