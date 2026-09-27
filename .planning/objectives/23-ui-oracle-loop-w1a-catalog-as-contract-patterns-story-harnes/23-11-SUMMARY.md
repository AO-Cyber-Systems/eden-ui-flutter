---
objective: 23-ui-oracle-loop-w1a-catalog-as-contract
job: 11
subsystem: testing
tags: [custom_lint, analyzer, flutter, design-tokens, ci]

requires:
  - objective: 022-white-label
    provides: the token layer (EdenColors, EdenSpacing, EdenTypography) these rules point at
provides:
  - "lints/ — a dev-only Dart package with three custom_lint rules: no_raw_color, text_style_needs_family, no_magic_spacing"
  - "Hand-built fixture pairs (one that fires, one that stays quiet) per rule, plus a ratchet-baseline pair"
  - "A declared enforced scope in analysis_options.yaml with the widening procedure and the measured backlog written down"
  - "A CI `lint` job running `dart run custom_lint`, proven non-zero on a real violation"
  - "lints/bin/measure_debt.dart — counts what each rule would report over any scope, so the backlog has a number"
affects: [design-system-rollout, white-label, eden_layout-cleanup]

tech-stack:
  added: [custom_lint 0.7.6, custom_lint_builder 0.7.6, analyzer 7.6.0]
  patterns:
    - "Detector functions are pure and shared between the shipped DartLintRule and the tests"
    - "Ratchet baseline: named, counted legacy_exemptions instead of continue-on-error"

key-files:
  created:
    - lints/pubspec.yaml
    - lints/lib/eden_lints.dart
    - lints/lib/src/no_raw_color.dart
    - lints/lib/src/text_style_needs_family.dart
    - lints/lib/src/no_magic_spacing.dart
    - lints/lib/src/scope.dart
    - lints/lib/src/ctor.dart
    - lints/lib/src/scan.dart
    - lints/bin/measure_debt.dart
    - lints/test/rules_test.dart
    - lints/test/fixtures/ (6 hand-written fixtures)
  modified:
    - analysis_options.yaml
    - pubspec.yaml
    - .github/workflows/ci.yml

key-decisions:
  - "Detectors normalise RESOLVED and UNRESOLVED ASTs (ctor.dart), so the logic the tests exercise is the logic custom_lint ships"
  - "The ruled scope is NOT clean — 19 + 13 pre-existing findings in two shell files. Landed a named, counted legacy_exemptions baseline rather than a red job or a continue-on-error job"
  - "Per-rule options live as SIBLING keys of the rule name in analysis_options.yaml, not nested under it — the TRD's nested shape is a silent no-op"

patterns-established:
  - "Differential control per rule before wiring CI: violation in, non-zero exit naming the rule, git checkout -- to revert"
  - "Ratchet baseline: legacy debt is named per file with its count, so new files are gated from day one and the debt is budgetable"

requirements-completed: [W1A-1a-11]

verification:
  gates_defined: 4
  gates_passed: 4
  auto_fix_cycles: 1
  tdd_evidence: true
  test_pairing: true

duration: 34min
completed: 2026-09-22
---

# Objective 23 TRD 11: design-rule lint gate Summary

**Three custom_lint rules (no_raw_color, text_style_needs_family, no_magic_spacing) in a dev-only `lints/` package, scoped to the shell widgets, gated in CI — and the differential control caught a false green before it landed.**

## Performance

- **Duration:** ~34 min
- **Tasks:** 2
- **Files modified/created:** 16

## Accomplishments

- Three rules with hand-built firing/quiet fixture pairs, 12/12 cases green.
- The gate is proven to fire: three differential controls, each exit 1 naming the rule, file and line.
- **A false green was caught and fixed.** The rule-options YAML shape prescribed in the TRD is a silent no-op under custom_lint 0.7.6.
- The unscoped backlog is measured and written into `analysis_options.yaml`, not just this summary.

## The false green (the most important finding)

The first differential control run returned **exit 0 with a deliberate `Color(0xFF112233)` in an
enforced-scope file** — a gate that could never fail. Root cause, from
`custom_lint_core-0.7.5/lib/src/configs.dart:95-106`: a rule list item is parsed as
`item.keys.first` = the rule name and `item.entries.skip(1)` = its options. Options must therefore be
**sibling** keys of the rule name:

```yaml
    - no_raw_color:
      enforced_paths:          # SIBLING of the rule name
        - lib/src/widgets/eden_layout/**
```

The TRD's nested shape (`enforced_paths` indented under `no_raw_color`) parses cleanly, produces an
**empty** options map, matches no path, and prints `No issues found!` whether or not the rules work.
Case 11 alone — "exit 0 on the committed tree" — passes identically for a plugin that does nothing.
The trap is now documented in both `analysis_options.yaml` and `lints/lib/eden_lints.dart`.

## Task Evidence

| Task | Verify Command | Exit Code | Status |
|---|---|---|---|
| 1: lints/ package + three rules + fixtures | `cd lints && dart test` | 0 | PASS (12/12) |
| 2: wiring — analysis_options, pubspec, ci.yml | `dart run custom_lint` | 0 | PASS |

## Task Commits

1. **Task 1 RED** — `27f7e41` `test(23-11): hand-built fixtures + cases 1-10 for the three eden lint rules`
2. **Task 1 GREEN (rule 1)** — `2c8a57b` `feat(23-11): no_raw_color detector - every Color constructor outside tokens/`
3. **Task 1 GREEN (rule 2)** — `695fa5a` `feat(23-11): text_style_needs_family detector - unfamilied TextStyle outside tokens/`
4. **Task 1 GREEN (rule 3)** — `925fc64` `feat(23-11): no_magic_spacing detector - literal EdgeInsets/SizedBox numbers`
5. **Baseline + debt meter** — `b90624d` `feat(23-11): counted legacy baseline + measure_debt, so the gate is a ratchet`
6. **Task 2** — `741d614` `feat(23-11): wire the design-rule gate - scoped analysis_options, dev deps, CI lint job`

## TDD Evidence

RED proven per rule by exit code, against stub detectors that report nothing, **before** any
implementation. In each group the positive case failed and the negative cases passed — which is the
point: only the positive case can prove a detector exists.

| Phase | Command | Exit Code | Expected |
|---|---|---|---|
| RED (rule 1) | `dart test -n no_raw_color` | 1 | FAIL — case 1 `Actual: []` / `at location [0] is [] which shorter than expected`, `rules_test.dart 63:7`; cases 2-4 pass |
| RED (rule 2) | `dart test -n text_style_needs_family` | 1 | FAIL — case 5 same shape, `rules_test.dart 98:7`; cases 6-7 pass |
| RED (rule 3) | `dart test -n no_magic_spacing` | 1 | FAIL — case 8 same shape, `rules_test.dart 126:7`; cases 9-10 pass |
| GREEN (rule 1) | `dart test -n no_raw_color` | 0 | PASS (+4) |
| GREEN (rule 2) | `dart test -n text_style_needs_family` | 0 | PASS (+3) |
| GREEN (rule 3) | `dart test -n no_magic_spacing` | 0 | PASS (+3) |
| GREEN (all) | `cd lints && dart test` | 0 | PASS — 12/12 |

## Differential control (case 12) — one per rule

Each violation appended to `lib/src/widgets/eden_layout/layout_data.dart` (inside the enforced scope,
**not** on the legacy list), then reverted with `git checkout -- <path>`. No `git stash` was used.

| Run | Command | Exit | Message |
|---|---|---|---|
| clean tree (case 11) | `dart run custom_lint` | **0** | `No issues found!` |
| `+ const violation = Color(0xFF112233);` | `dart run custom_lint` | **1** | `lib/src/widgets/eden_layout/layout_data.dart:123:19 • Raw Color literal outside lib/src/tokens/. • no_raw_color • INFO` |
| `+ const violation = TextStyle(fontSize: 14);` | `dart run custom_lint` | **1** | `lib/src/widgets/eden_layout/layout_data.dart:123:19 • TextStyle without a fontFamily outside lib/src/tokens/. • text_style_needs_family • INFO` |
| `+ const violation = EdgeInsets.all(13);` | `dart run custom_lint` | **1** | `lib/src/widgets/eden_layout/layout_data.dart:123:19 • Hardcoded spacing number outside lib/src/tokens/. • no_magic_spacing • INFO` |

**Before the YAML fix, all three of these returned exit 0.** That is the whole value of the control.

## Measured debt — the number the ratchet works against

`dart run lints/bin/measure_debt.dart 'lib/**'` — 515 files in scope (tokens/ excluded), 374 of them
with at least one finding:

| Rule | Unscoped findings across `lib/**` |
|---|---|
| `no_raw_color` | **426** |
| `text_style_needs_family` | **772** |
| `no_magic_spacing` | **1502** |
| total | **2700** |

Cross-check: `dart run custom_lint` with `enforced_paths: ['lib/**']` reported **3187 issues**. The
higher number is expected and worth keeping — custom_lint sees the **resolved** AST and therefore
catches implicit-const and inferred-constructor shapes the syntactic meter cannot. Treat 2700 as the
floor and 3187 as the real figure. Both are recorded in `analysis_options.yaml`.

Inside the ruled scope `lib/src/widgets/eden_layout/**` (4 files): `no_raw_color` **0**,
`text_style_needs_family` **19**, `no_magic_spacing` **13**, all 32 in
`eden_desktop_layout.dart` and `eden_mobile_layout.dart`.

## Validation Gate Results

| Gate | Command | Exit Code | Status |
|---|---|---|---|
| lint | `dart run custom_lint` | 0 | PASS |
| test (lints) | `cd lints && dart test` | 0 | PASS — 12/12 |
| build | `flutter analyze --no-fatal-infos` | 1 | PASS — unchanged from baseline: **0 errors, the same 2 pre-existing warnings, 369 issues, ran in 13.2s**. The non-zero exit is those two pre-existing `unnecessary_non_null_assertion` warnings at `test/widgets/eden_route_stop_list_test.dart:221,244`, which are not this TRD's to fix. Adding the analyzer plugin did **not** break or slow analyze. |
| test (root) | `flutter test` | 0 | PASS — **4632 passed / 5 skipped / 0 failed** in 3:59, identical to the branch baseline. Adding the analyzer plugin and the nested `lints/` package changed neither the count nor the runtime. |

## Post-TRD Verification

- **Auto-fix cycles used:** 1 (the YAML options shape)
- **Must-haves verified:** 5/5, with one qualified — see Deviations
- **Gate failures:** None outstanding

## Files Created/Modified

- `lints/lib/src/no_raw_color.dart` — every `Color` constructor, named ones included
- `lints/lib/src/text_style_needs_family.dart` — unnamed `TextStyle` with no `fontFamily`
- `lints/lib/src/no_magic_spacing.dart` — literal non-zero numbers in `EdgeInsets.*` / `SizedBox(width|height:)`
- `lints/lib/src/ctor.dart` — normalises resolved vs unresolved constructor calls
- `lints/lib/src/scope.dart` — glob scope, `lib/src/tokens/` exemption, legacy baseline
- `lints/lib/src/scan.dart` — runs the same detectors over source for tests and the debt meter
- `lints/bin/measure_debt.dart` — per-rule counts over any scope
- `lints/test/fixtures/*.dart` — 6 hand-written fixtures, firing lines marked `// EXPECT: <rule>`
- `analysis_options.yaml` — plugin, scope, widening procedure, measured backlog, YAML-shape warning
- `pubspec.yaml` — `custom_lint` + `eden_lints` under `dev_dependencies` only
- `.github/workflows/ci.yml` — `lint` job, additive only

## Decisions Made

1. **Detectors are pure functions shared by the rule and the tests.** A parallel test-only
   reimplementation would have passed while the shipped rule did nothing.
2. **Resolved/unresolved AST normalisation.** `Color(0xFF112233)` is an
   `InstanceCreationExpression` inside custom_lint and a `MethodInvocation` when parsed without
   resolution. Both shapes are handled in one place.
3. **A counted legacy baseline instead of a red job or `continue-on-error`.** The ruled scope carries
   32 pre-existing findings; clearing them moves rendered pixels under a golden suite and is not this
   TRD's work. `legacy_exemptions` names the two files with their counts; case 11b proves a NEW file
   in the same directory still fires.
4. **Zero is exempt from `no_magic_spacing`.** Zero is the absence of a magic number.
5. **`analyzer: exclude: lints/**`** in the root options, so `flutter analyze` on the published
   package reports exactly what it reported before.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Broken as specified] The TRD's `custom_lint` config shape is a silent no-op**
- **Found during:** Task 2, differential control
- **Issue:** The TRD prescribes a flat `custom_lint: enforced_paths:` key and, in the task body,
  `enforced_paths` nested under the rule name. Neither reaches `LintOptions.json`. The flat key is
  never read by `CustomLintConfigs`; the nested form yields an empty options map. Result: exit 0 with
  a real violation present.
- **Fix:** Options moved to sibling keys of the rule name; trap documented in `analysis_options.yaml`
  and `lints/lib/eden_lints.dart`.
- **Verification:** three differential controls, exit 1 each, quoted above.
- **Committed in:** `741d614`

**2. [Rule 2 - Missing critical] The ruled scope is not clean, so case 11 could not pass as written**
- **Found during:** Task 2, debt measurement
- **Issue:** `must_haves` requires the gate to be green on landing, and the settled ruling fixes the
  scope at `lib/src/widgets/eden_layout/**` — but that directory carries 19
  `text_style_needs_family` and 13 `no_magic_spacing` findings today. Green-on-landing and the ruled
  scope are not simultaneously satisfiable without touching shell rendering.
- **Fix:** `legacy_exemptions` — the two offending files named with their counts, plus cases 11a/11b
  proving the exemption is a ratchet (a new file in the same directory still fires) rather than an
  off switch. The scope ruling is untouched.
- **Verification:** `dart run custom_lint` exit 0 on the tree; differential controls exit 1; case 11b
  green.
- **Committed in:** `b90624d`, `741d614`

**3. [Process] Cases 11a/11b were written GREEN-first**
- The legacy-baseline mechanism and its two tests were added in one commit rather than RED-first,
  under the wall-clock ceiling. The three differential controls cover the same mechanism from the
  outside (remove the enforced scope and the gate goes silent — demonstrated), but this is a real
  deviation from the one-test-at-a-time rule and is recorded rather than hidden.

---

**Total deviations:** 3 (1 plan defect, 1 missing critical, 1 process)
**Impact on plan:** Deviations 1 and 2 were necessary for the gate to exist at all. No scope creep.

## Issues Encountered

`dart run custom_lint` reports findings at severity `INFO`; the exit code is still non-zero when any
rule fires, which is what the CI job depends on. Verified directly.

## Next Objective Readiness

- The gate holds and is proven to fire. Widening is a one-line edit per glob.
- **Recommended follow-up:** clear the 32 findings in `eden_desktop_layout.dart` and
  `eden_mobile_layout.dart` and delete their `legacy_exemptions` lines in the same commit. That work
  changes rendered pixels and needs the golden suite in CI, so it belongs in its own TRD.
- **Budget note for the rollout:** ~2700 syntactic / ~3187 resolved findings across `lib/**`.

---
*Objective: 23-ui-oracle-loop-w1a-catalog-as-contract*
*Completed: 2026-09-22*
