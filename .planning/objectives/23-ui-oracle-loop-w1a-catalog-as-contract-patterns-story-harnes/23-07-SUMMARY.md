---
objective: 23-ui-oracle-loop-w1a-catalog-as-contract
job: 07
subsystem: testing
tags: [flutter, js-interop, web, probe, cdp, tree-shaking, ci-gate, semantics]

requires: []
provides:
  - "package:eden_ui_flutter/probe.dart — EdenProbe.install() and kEdenProbe, opt-in by import (NOT exported from eden_ui.dart)"
  - "lib/src/probe/probe_api.dart — EdenProbeApi.find/tree/settled/state in pure VM-testable Dart, returning JSON-shaped plain maps"
  - "lib/src/probe/probe_bridge.dart — const kEdenProbe gate + conditional export on dart.library.js_interop"
  - "lib/src/probe/probe_bridge_web.dart — thin dart:js_interop shim installing window.__edenProbe"
  - "lib/src/probe/probe_bridge_stub.dart — no-op on every non-js_interop platform"
  - "tool/probe_guard.sh + tool/probe_guard_assert.sh — two-direction bundle guard, parameterised by app dir for W1c reuse"
  - ".github/workflows/probe-guard.yml — its own workflow, ci.yml untouched"
  - "example/probe_smoke/ — the release-web app the guard actually builds and greps"
affects: [23-08, 23-12, W1c, W2-df-tools-ui-probe]

tech-stack:
  added: []
  patterns:
    - "Compile-time gate, never a runtime one: conditional import on dart.library.js_interop + const bool.fromEnvironment, so the tree shaker CAN remove the bridge and the guard script PROVES it did"
    - "All probe logic lives in the VM-testable file; the web file is conversion-only, so a green widget test is evidence about the shipped bridge rather than a parallel code path"
    - "A gate's judgement is split from its slow build step (probe_guard_assert.sh) so the judgement itself has tests that watch it go red"

key-files:
  created:
    - lib/probe.dart
    - lib/src/probe/probe_api.dart
    - lib/src/probe/probe_bridge.dart
    - lib/src/probe/probe_bridge_web.dart
    - lib/src/probe/probe_bridge_stub.dart
    - test/probe/probe_api_test.dart
    - test/probe/probe_bridge_test.dart
    - test/probe/probe_guard_test.dart
    - test/probe/_fixtures/probe_surfaces.dart
    - example/probe_smoke/lib/main.dart
    - example/probe_smoke/pubspec.yaml
    - example/probe_smoke/web/index.html
    - tool/probe_guard.sh
    - tool/probe_guard_assert.sh
    - .github/workflows/probe-guard.yml
  modified: []

key-decisions:
  - "inFlightRequests STORAGE lives on EdenProbeApi, with EdenProbe.inFlightRequests forwarding to it. The web shim imports probe_api.dart, so storing it on EdenProbe would make probe_api -> probe_bridge -> probe_bridge_web -> probe_api a cycle. The TRD's public name is preserved exactly."
  - "Added EdenProbe.debugInstallCount. Without it, 'install() registers nothing observable' is UNOBSERVABLE on the VM (the stub bridge is a no-op), so the test for case 10 could never fail — the exact failure mode the runtime brief names. The counter is what made the differential control possible."
  - "Semantics rects are normalised by devicePixelRatio. The root semantics node's transform IS the dpr scale, so a raw composition reports a 100x48 control as 300x144 at dpr 3. Every other rect the probe returns is a logical render-box rect and a driver compares the two; on web, logical pixels are CSS pixels, which is what a CDP driver works in."
  - "tool/probe_guard.sh was split: the two slow builds stay there, every judgement moved to tool/probe_guard_assert.sh, which test/probe/probe_guard_test.dart drives against hand-built fixture bundles. The guard is now proven to go red in all three ways it should."

patterns-established:
  - "Conditional import over kIsWeb: a runtime branch keeps dart:js_interop in the mobile bundle and keeps __edenProbe in a production web bundle"
  - "Bundle guards assert BOTH directions in one script — a one-sided check passes identically for a tree-shaken bridge and for a bridge that was never written"

requirements-completed: [W1A-1a-07]

verification:
  gates_defined: 3
  gates_passed: 3
  auto_fix_cycles: 0
  tdd_evidence: true
  test_pairing: true

duration: 38min
completed: 2026-09-22
---

# Objective 23 TRD 07: Probe Bridge Summary

**`window.__edenProbe.{find,tree,settled,state}` behind a compile-time `EDEN_PROBE` gate, with all four answers computed in VM-testable Dart over real render-box and semantics rects, and a two-direction bundle guard that measured 0 hits in a production release bundle and 1 with the define.**

## Performance

- **Duration:** ~38 min
- **Tasks:** 3
- **Files created:** 15

## Accomplishments

- `EdenProbeApi.find/tree/settled/state` implemented in pure Dart with no JS types, so `flutter test` exercises the same entry the JS shim calls.
- `find({key:})` returns the matched element's OWN render-box global rect — asserted equal to `tester.getRect` AND asserted NOT equal to its 360x200 parent's, which is the differential that makes it a geometry test rather than an existence test.
- `find({text:})` matches `Text.data` and `InlineSpan.toPlainText()`, so a `Text.rich` span a user reads is findable.
- `tree()` reports two overlapping nodes that both advertise `tap` for a double-declared control — the double-fire made visible from outside the app.
- The bundle guard was RUN, not described: **production bundle 0 hits, probe bundle 1 hit, exit 0** on a real `flutter build web --release` pair.

## Task Evidence

| Task | Verify Command | Exit Code | Status |
|---|---|---|---|
| 1: EdenProbeApi core (cases 1-8) | `flutter test test/probe/probe_api_test.dart` | 0 | PASS |
| 2: kEdenProbe gate, conditional import, shim, probe.dart (cases 9-10) | `flutter test test/probe/ && flutter analyze --no-fatal-infos` | 0 | PASS |
| 3: example, guard script, probe-guard workflow (cases 11-12) | `bash tool/probe_guard.sh example/probe_smoke` | 0 | PASS |

## Task Commits

1. **Task 1** — `fb2617c` test / `ba1b456` feat / `d10351e` test / `4ce8a8c` feat / `b9c10ca` test / `a403585` feat / `2dbd820` test / `bf58d0d` feat / `a027871` test / `e93a951` feat / `da14be8` test / `7571b4d` feat / `e3106aa` test / `475494d` feat
2. **Task 2** — `0e1a783` test / `b44819f` feat / `edcc377` chore (analyze baseline)
3. **Task 3** — `970fa02` feat / `b27611d` test (guard judgement split + fixture-bundle tests) / `1f6500d` chore

## Validation Gate Results

| Gate | Command | Exit Code | Status |
|---|---|---|---|
| lint | `flutter analyze --no-fatal-infos` | 1 (infos only) | PASS — 0 errors, 2 pre-existing warnings, 369 issues = exact baseline |
| test | `flutter test test/probe/` | 0 | PASS — 14 tests |
| build | `bash tool/probe_guard.sh example/probe_smoke` | 0 | PASS — `production bundle: 0   probe bundle: 1` |

Full suite, run once at the end: `flutter test` → **exit 0**, `02:47 +4623 ~5: All tests passed!`
(baseline on this branch was 4609 passed / 5 skipped / 0 failed; +14 is exactly this TRD's
`test/probe/` additions, and no existing test changed).

## TDD Evidence

Every case RED-proven by exit code before implementation. Literal captures:

| Case | RED command | Exit | Failure message |
|---|---|---|---|
| 1 find({key:}) own rect | `flutter test test/probe/probe_api_test.dart` | 1 | `Expected: an object with length of <1>` / `Actual: []` |
| 2 find({text:}) Text | `--plain-name "find({text:}) matches"` | 1 | `Expected: not contains Rect:<Rect.fromLTRB(42.8, 310.0, 142.5, 330.0)>` (the unfiltered walk swept 'Goodbye' in) |
| 3 find({text:}) RichText | `--plain-name "Text.rich span"` | 1 | `Expected: contains Rect:<Rect.fromLTRB(0.0, 290.0, 185.3, 310.0)>` |
| 4-5 identifier / empty | `--plain-name "semantics identifier"` | 1 | `Expected: an object with length of <1>` |
| 6 tree() | `--plain-name "double-declared"` | 1 | `Expected: '/'` / `Actual: <null>` |
| 7 settled() | `--plain-name "AnimationController runs"` | 1 | `Expected: true` / `Actual: <false>` |
| 8 state() | `--plain-name "theme brightness, viewport"` | 1 | `Expected: '/'` / `Actual: <null>` |
| 9-10 gate | `flutter test test/probe/probe_bridge_test.dart` | 1 | `Error when reading 'lib/probe.dart': No such file or directory`; `Undefined name 'kEdenProbe'`; `Undefined name 'EdenProbe'` |

**Case 10's prescribed differential control — gate REMOVED, run, restored:**

Deleting `if (!kEdenProbe) { return; }` from `EdenProbe.install()` and re-running
`flutter test test/probe/probe_bridge_test.dart` gave **exit 1**, `Expected: <0>` / `Actual: <1>`.
The gate was restored by re-editing in place (the file is new and untracked at that point, so
`git checkout --` had nothing to restore from — no `git stash` was used, per the runtime brief).

**Case 1's geometry differential:** the returned rect is asserted equal to
`tester.getRect(find.byKey('probe-target'))` (120x40) and `isNot` the 360x200
`probe-parent` rect — a probe that walked up to the nearest sized ancestor is caught.

**Guard differential (cases 11-12), ACTUALLY EXECUTED locally:**

```
Compiling lib/main.dart for the Web...  13.9s
✓ Built build/web
production bundle: 0   probe bundle: 1
OK: bridge present under the define, absent without it
GUARD_EXIT=0
```

Both `flutter build web --release` runs were real, on the local toolchain (3.41.9).
CI pins 3.47.4 and is the authority if the numbers ever differ; the local numbers are recorded
here as required.

**Guard judgement has its own tests** (`test/probe/probe_guard_test.dart`, 4 cases, all green):
the assert script exits non-zero when `__edenProbe` leaks into the production bundle, when the
probe bundle ALSO has none (the inert-guard case), and when a build produced no bundle at all.

## Post-TRD Verification

- **Auto-fix cycles used:** 0
- **Must-haves verified:** 5/5
- **Gate failures:** None

Must-have checks:
1. Real global rect from the render box, not a DOM guess — case 1, asserted against `tester.getRect` and against the parent.
2. `find({text:})` across `Text` and `RichText` — cases 2 and 3.
3. `tree()` lists identified nodes with rect + actions, double tap visible — case 6.
4. `settled()` false while animating, true after — case 7.
5. No `__edenProbe` in a production bundle, proven by grepping a real build — guard exit 0, `production bundle: 0`.

Contract checks from the TRD's `<verification>`:
- `grep -n "probe" lib/eden_ui.dart` → empty. The bridge is opt-in by import.
- `git diff pubspec.yaml` → empty. No new package dependency; `dart:js_interop` and
  `dart:js_interop_unsafe` are SDK libraries.
- `.github/workflows/ci.yml` → untouched; the job ships in `.github/workflows/probe-guard.yml`.

## Files Created/Modified

- `lib/probe.dart` — public opt-in entry, exports `EdenProbe` and `kEdenProbe` only.
- `lib/src/probe/probe_api.dart` — the four probe answers; element walk, semantics walk with
  root-to-node transform composition, dpr normalisation, scheduler-based `settled()`.
- `lib/src/probe/probe_bridge.dart` — `const kEdenProbe`, conditional import/export,
  `EdenProbe.install()`, `inFlightRequests` forwarder, `debugInstallCount`.
- `lib/src/probe/probe_bridge_web.dart` — conversion-only shim; `setProperty` on `window`.
- `lib/src/probe/probe_bridge_stub.dart` — no-op.
- `test/probe/_fixtures/probe_surfaces.dart` — four hand-built surfaces, each with a header
  naming the one question it lets the probe be asked.
- `test/probe/probe_api_test.dart` — cases 1-8. `test/probe/probe_bridge_test.dart` — cases 9-10.
- `test/probe/probe_guard_test.dart` — the guard's judgement, against fixture bundles.
- `tool/probe_guard.sh` / `tool/probe_guard_assert.sh` — build, then judge.
- `.github/workflows/probe-guard.yml` — own workflow, `flutter-version: '3.47.4'` with ci.yml's
  pin comment copied verbatim.
- `example/probe_smoke/` — pubspec (path pin to `../..`), main.dart, generated `web/`.

## Decisions Made

See `key-decisions` in the frontmatter. In short: `inFlightRequests` storage moved to
`EdenProbeApi` to avoid an import cycle (the TRD's public name `EdenProbe.inFlightRequests` is
preserved by a forwarder); `EdenProbe.debugInstallCount` added so case 10 CAN fail; semantics
rects normalised by dpr so they share one coordinate system with render-box rects; the guard's
judgement split out so it is itself testable.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 — Missing Critical] `EdenProbe.debugInstallCount`**
- **Found during:** Task 2 (case 10)
- **Issue:** The TRD asks case 10 to prove `install()` "registers nothing observable" and to
  RED-prove it by making `install()` unconditional. On the VM the conditional export resolves to
  the STUB, whose `installProbeBridge()` is a no-op — so removing the gate changes nothing
  observable and the test could not fail. That is exactly the
  `trd-prescriptions-need-verifying` failure mode.
- **Fix:** Added a public `EdenProbe.debugInstallCount`, incremented only past the gate.
- **Verification:** Gate removed → exit 1, `Expected: <0>` / `Actual: <1>`; restored → exit 0.
- **Committed in:** `b44819f`

**2. [Rule 1 — Correctness] Semantics rects normalised by devicePixelRatio**
- **Found during:** Task 1 (case 4)
- **Issue:** The composed semantics transform includes the root view's dpr scale, so a 100x48
  control reported as `Size(300.0, 144.0)`. A driver comparing a `find({identifier:})` rect with a
  `find({key:})` rect would have been comparing physical with logical pixels.
- **Fix:** Divide the composed rect by `implicitView.devicePixelRatio`, documented in place.
- **Committed in:** `bf58d0d`

**3. [Rule 2 — Missing Critical] `tool/probe_guard_assert.sh` + `test/probe/probe_guard_test.dart`**
- **Found during:** Task 3
- **Issue:** As written, the guard's grep logic had no test and nobody had watched it go red —
  the `edenbiz-migration-gate-is-dead` shape.
- **Fix:** Split every judgement into `probe_guard_assert.sh` (probe_guard.sh still does the two
  builds and calls it) and added four fixture-bundle tests, three of which require a non-zero exit.
- **Committed in:** `b27611d`
- **Note:** these four tests were written AFTER the script rather than RED-first — they are a
  retrofitted control on an existing script, not a new behaviour. Their red-ness is established by
  construction: three of the four assert `exitCode, isNot(0)` against deliberately wrong bundles.

**4. [Rule 3 — Environmental] `flutter create . --platforms web` in the example**
- **Found during:** Task 3
- **Issue:** First real guard run died with `This project is not configured for the web.` —
  a hand-written pubspec has no `web/index.html`.
- **Fix:** Ran `flutter create . --platforms web`, kept `web/`, `.gitignore`, `.metadata` and
  `analysis_options.yaml`, deleted the generated `test/`, `README.md` and `.iml`. The generated
  `pubspec.yaml` did not replace the hand-written one. Also had to un-`const` the example's
  `MaterialApp` because `Semantics` is not a const constructor.
- **Committed in:** `b27611d`

---

**Total deviations:** 4 auto-fixed (2 missing critical, 1 correctness, 1 environmental)
**Impact on plan:** No scope creep. Two of the four exist specifically to stop a gate that
cannot fail from shipping.

## Issues Encountered

- `setProperty` on `JSObject` needed `dart:js_interop_unsafe`, not `dart:js_interop` — caught by
  `flutter analyze` (1 error), fixed in `edcc377`.
- `package:path` is not a declared dev dependency; the guard test now builds paths with string
  interpolation (bash is the shell under test and only macOS/ubuntu run it).

## Notes for 23-08

`kEdenProbe` is exported from `package:eden_ui_flutter/probe.dart` (`export
'src/probe/probe_bridge.dart' show EdenProbe, kEdenProbe;`). `EdenProbeScope` is 23-08's to add;
`EdenProbe.inFlightRequests` is already public and settable, and `EdenProbeApi.settled()` already
consults it.

## User Setup Required

None.

## Next Objective Readiness

- 23-08 can consume `kEdenProbe` and `EdenProbe` as exported.
- W1c can call `tool/probe_guard.sh <app-dir>` against a consumer app without copying it.
- W2's `df-tools ui probe` has the four JS entries and their JSON shapes to talk to.

---
*Objective: 23-ui-oracle-loop-w1a-catalog-as-contract*
*Completed: 2026-09-22*
