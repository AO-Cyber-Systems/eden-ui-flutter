---
objective: 23-ui-oracle-loop-w1a-catalog-as-contract
job: 01
subsystem: testing
tags: [flutter, semantics, accessibility, test-harness, geometry, fixtures]

requires: []
provides:
  - "test_support/ui_oracle/wrap.dart — one-call pump helper (width/height/themeMode/theme) with registered viewport teardown"
  - "test_support/ui_oracle/semantics_geometry.dart — identifiedNodes / globalRectOf / rectsOverlap, resolving a semantics node's OWN global rect"
  - "test_support/ui_oracle/_fixtures/geometry_fixtures.dart — three hand-built widget trees, including the pinned container:true fixture"
  - "A test pinning the container:true omission so 23-02 and 23-07 can require it"
affects: [23-02, 23-03, 23-07, 23-08]

tech-stack:
  added: []
  patterns:
    - "test_support/ is a top-level directory reached by RELATIVE import from test/ — no package: URI, nothing ships to consumers"
    - "Semantics geometry is composed FROM THE NODE ITSELF up the ancestor chain; node.rect is transformed, never an ancestor's"

key-files:
  created:
    - test_support/ui_oracle/wrap.dart
    - test_support/ui_oracle/semantics_geometry.dart
    - test_support/ui_oracle/_fixtures/geometry_fixtures.dart
    - test/ui_oracle/wrap_test.dart
    - test/ui_oracle/semantics_geometry_test.dart
  modified: []

key-decisions:
  - "SemanticsHandle is disposed INSIDE identifiedNodes (try/finally), not via addTearDown — flutter_test's end-of-test handle verification runs BEFORE addTearDown callbacks, so a deferred dispose fails every test that reads geometry."
  - "wrap() imports EdenTheme through the public barrel package:eden_ui_flutter/eden_ui.dart, not src/, to avoid an implementation-import info."
  - "Case 7 pins the behaviour actually observed on Flutter 3.41.9, which is one step more severe than the plan predicted (see Deviations)."

patterns-established:
  - "Pattern 1: wrap(tester, child, width:, height:, themeMode:, theme:) replaces raw MaterialApp boilerplate and always registers resetPhysicalSize/resetDevicePixelRatio teardown."
  - "Pattern 2: geometry assertions go through globalRectOf/rectsOverlap; callers never write matrix code and never read rects off RenderObjects."
  - "Pattern 3: fixtures are hand-written, one readable tree per getter, with a header forbidding regeneration."

requirements-completed: [W1A-1a-01]

verification:
  gates_defined: 3
  gates_passed: 3
  auto_fix_cycles: 0
  tdd_evidence: true
  test_pairing: true

duration: ~22min
completed: 2026-09-22
---

# Objective 23 — TRD 23-01: UI Oracle fixtures Summary

**`wrap()` + `SemanticsGeometry` land as the two primitives every later TRD in this objective stands on, and the `container: true` omission is now pinned by a test instead of silently corrupting geometry.**

## Performance

- **Duration:** ~22 min
- **Tasks:** 2 of 2
- **Files created:** 5 (0 modified; nothing under `lib/`)

## Accomplishments

- `wrap()` pumps any widget at a chosen width/height/theme-mode with one call, with viewport teardown registered so a leaked `physicalSize` cannot turn the next test's golden red.
- `globalRectOf()` composes the semantics ancestor chain root→node and transforms **the node's own rect last**, so a 40x40 control inside a 360-wide row answers 40 — proven by a differential control that answers 360 the moment the walk is replaced by the parent's rect.
- `rectsOverlap()` answers sibling disjointness without the caller writing matrix maths.
- The `container: true` bug is pinned, with the memory note `flutter-web-semantics-node-is-the-click-target` named in the test.

## Task Evidence

| Task | Verify Command | Exit Code | Status |
|---|---|---|---|
| 1: fixtures + `wrap()` (cases 1-4) | `flutter test test/ui_oracle/wrap_test.dart` | 0 | PASS |
| 2: `SemanticsGeometry` (cases 5-7) | `flutter test test/ui_oracle/` | 0 | PASS |

## Task Commits

1. **Fixtures** — `238ce8d` `test(23-01): hand-build UI Oracle geometry fixtures`
2. **Case 1 RED** — `10ac14f` `test(23-01): RED wrap() pumps child at requested width (exit 1, wrap.dart missing)`
3. **Case 1 GREEN** — `4a75bf9` `feat(23-01): GREEN wrap() pump helper with width + viewport teardown`
4. **Case 2 RED** — `8884bb7` `test(23-01): RED wrap() themeMode.dark resolves a dark Theme (exit 1, no named parameter 'themeMode')`
5. **Case 2 GREEN** — `21d4c51` `feat(23-01): GREEN wrap() themeMode + theme override knobs`
6. **Case 3** — `e777b86` `test(23-01): case 3 themeMode.light resolves a light Theme (differential control: forcing ThemeMode.dark -> exit 1)`
7. **Case 4** — `2ad98a8` `test(23-01): case 4 wrap() leaves takeException null (differential control: stripping the harness -> exit 1, No Directionality widget found)`
8. **Case 5 RED** — `10acee7` `test(23-01): RED globalRectOf returns the node's own 40-wide rect (exit 1, semantics_geometry.dart missing)`
9. **Case 5 GREEN** — `55252de` `feat(23-01): GREEN SemanticsGeometry globalRectOf walks node.transform up to the root`
10. **Case 6 RED** — `208dcc0` `test(23-01): RED sibling rects are disjoint (exit 1, Method not found: 'rectsOverlap')`
11. **Case 6 GREEN** — `9ca0636` `feat(23-01): GREEN rectsOverlap answers sibling disjointness without caller matrix maths`
12. **Case 7 RED** — `043e58d` `test(23-01): RED naive expectation that a nested Semantics without container:true reports its own 40x40 (exit 1, Bad state: no semantics node with identifier 'fx-nested-no-container'; Identifiers present: [fx-parent])`
13. **Case 7 pinned** — `adfc087` `test(23-01): pin the container:true bug - nested Semantics is swallowed by the parent node`
14. **Analyze baseline** — `36ba37d` `chore(23-01): keep analyze at baseline (drop redundant import, scope the deprecated pipelineOwner ignore)`

## Validation Gate Results

| Gate | Command | Exit Code | Status |
|---|---|---|---|
| lint | `flutter analyze` | 1 | BASELINE — 369 issues, identical to the pre-TRD baseline; 0 issues in any file this TRD created. The non-zero exit is pre-existing (2 `unnecessary_non_null_assertion` warnings in `test/widgets/eden_route_stop_list_test.dart:221,244` + 367 infos), not introduced here. |
| test | `flutter test test/ui_oracle/` | 0 | PASS — 7/7 |
| build | `flutter test` | 0 | PASS — `02:03 +4609 ~5: All tests passed!` (baseline 4602 + the 7 new cases; 5 skipped, 0 failed) |

## TDD Evidence

| Case | RED command | RED exit | RED message | GREEN exit |
|---|---|---|---|---|
| 1 width | `flutter test test/ui_oracle/wrap_test.dart` | 1 | `Error when reading 'test_support/ui_oracle/wrap.dart': No such file or directory` / `Method not found: 'wrap'` | 0 |
| 2 dark | same | 1 | `test/ui_oracle/wrap_test.dart:39:9: Error: No named parameter with the name 'themeMode'.` | 0 |
| 3 light | same, with `themeMode: themeMode` forced to `ThemeMode.dark` in wrap.dart (differential control) | 1 | `Expected: Brightness:<Brightness.light>  Actual: Brightness:<Brightness.dark>` | 0 (fix restored via `git checkout --`) |
| 4 no-throw | same, with the MaterialApp/Scaffold harness stripped to a bare `pumpWidget(child)` (differential control) | 1 | `Expected: null  Actual: FlutterError:<No Directionality widget found.` | 0 (fix restored) |
| 5 40-vs-360 | `flutter test test/ui_oracle/semantics_geometry_test.dart` | 1 | `Error when reading 'test_support/ui_oracle/semantics_geometry.dart': No such file or directory` / `Method not found: 'globalRectOf'` | 0 |
| 5 differential | same, with `MatrixUtils.transformRect(composed, node.rect)` replaced by `ancestors.last.rect` | 1 | `Expected: <40>  Actual: <360.0>` | 0 (restored) |
| 6 disjoint | same | 1 | `Error: Method not found: 'rectsOverlap'.` (x2) | 0 |
| 7 pinned bug | same, asserting the naive 40x40 expectation first | 1 | `Bad state: SemanticsGeometry: no semantics node with identifier "fx-nested-no-container". Identifiers present: [fx-parent]` | 0 after flipping the assertions to the observed (buggy) values |

An intermediate RED also surfaced the `addTearDown(handle.dispose)` trap: `A SemanticsHandle was active at the end of the test.` — see Deviations.

## Files Created

- `test_support/ui_oracle/wrap.dart` — pump helper; sets `tester.view.physicalSize`/`devicePixelRatio`, registers `resetPhysicalSize` + `resetDevicePixelRatio` teardown, pumps `MaterialApp(EdenTheme.light()/dark(), themeMode, Scaffold > Center > SizedBox(width))` and settles. Documents the `pump(Duration)` escape hatch for infinite animations.
- `test_support/ui_oracle/semantics_geometry.dart` — `SemanticsGeometryNode` (id / identifier / globalRect / actions), `identifiedNodes`, `globalRectOf`, `rectsOverlap`. Sorted by `(top, left, identifier)`; traversal order is never asserted on.
- `test_support/ui_oracle/_fixtures/geometry_fixtures.dart` — `narrowChildInWideRow`, `twoSiblingControls`, `nestedSemanticsWithoutContainer`, all hand-written with a no-regeneration header.
- `test/ui_oracle/wrap_test.dart` — cases 1-4.
- `test/ui_oracle/semantics_geometry_test.dart` — cases 5-7.

## Deviations from Plan

### 1. `SemanticsHandle` cannot be disposed via `addTearDown`

- **Found during:** Task 2, first GREEN attempt for case 5.
- **Issue:** The TRD prescribes `final handle = tester.ensureSemantics(); addTearDown(handle.dispose);`. That fails every test that reads geometry: flutter_test's `_verifySemanticsHandlesWereDisposed` runs during `_endOfTestVerifications`, i.e. **before** `addTearDown` callbacks. Exit 1, `A SemanticsHandle was active at the end of the test.`
- **Fix:** `identifiedNodes` acquires the handle and disposes it in a `finally` before returning. The semantics tree is available synchronously after `ensureSemantics()`, so no pump is needed and repeated calls within one test work (case 6 calls `globalRectOf` twice, case 7 three times).
- **Committed in:** `55252de`.

### 2. Case 7's real behaviour is one step more severe than the plan predicted

- **Plan:** "a nested `Semantics(identifier: ...)` WITHOUT `container: true` reports the parent's rect, not its own 40x40" — i.e. the identifier is still found, carrying the wrong rect.
- **Observed (Flutter 3.41.9):** the nested `Semantics` forms no boundary at all; its annotations merge into the enclosing node, whose own `identifier` (`fx-parent`) wins. The inner identifier is **not published**, so `globalRectOf(tester, 'fx-nested-no-container')` throws `Bad state: ... Identifiers present: [fx-parent]`.
- **Resolution:** the test pins what actually happens — identifiers are exactly `[fx-parent]`, that node carries the parent's 200x200 rect (which is the box a click on the 40x40 control lands in), and the natural lookup `throwsStateError`. The must_have's intent is preserved and strengthened: the bug is visible, named and un-fixable-by-accident. **23-02 and 23-07 should require `container: true` on the grounds that without it the identifier disappears entirely**, which is a cleaner rule than "the rect is wrong".
- **Committed in:** `043e58d` (RED) + `adfc087` (pin).

### 3. Fixture corrections found by the compiler/layout, not rewritten tests

- `Semantics` has no `const` generative constructor → the three fixture getters are non-const (`const` retained on the inner `SizedBox`es).
- `nestedSemanticsWithoutContainer` is wrapped in a `Center` so `wrap()`'s tight width does not stretch the 200x200 parent to 360 (this is what the first run of the pinned test caught: `Expected: <200> Actual: <360.0>`).

### 4. Analyze hygiene

Two new infos appeared (`unnecessary_import` for `package:flutter/semantics.dart`, `deprecated_member_use` for `PipelineOwner.semanticsOwner`). The import was dropped; the deprecation carries a scoped `// ignore:` with a comment explaining that `SemanticsBinding` exposes no root `SemanticsNode` and the root `PipelineOwner` does not own semantics. `flutter analyze` is back to the exact baseline count of 369.

## Issues Encountered

**Reported finding — the stated baseline of "0 warnings" is not accurate.** `flutter analyze` on this branch reports **2 pre-existing warnings**, both `unnecessary_non_null_assertion` in `test/widgets/eden_route_stop_list_test.dart:221` and `:244`, in a file this TRD never touched. They are inside the 369-issue baseline total. This TRD neither added nor removed a warning, but `flutter analyze --no-fatal-infos` cannot exit 0 on this branch until those two are fixed — worth knowing before any TRD in this objective wires analyze into a gate.

No golden test was written, so nothing needed local blessing.

## Next Objective Readiness

- 23-02 can move `semantics_geometry.dart` into `lib/testing/` and leave a re-export: these tests are written against the `test_support/` path, so the move is provable.
- 23-03's generated story tests inherit the relative-import convention, documented in a header comment in each helper.
- 23-07's `tree()` can reuse `identifiedNodes` directly — it already returns id / identifier / globalRect / actions.

---
*Objective: 23-ui-oracle-loop-w1a-catalog-as-contract*
*TRD: 23-01*
*Completed: 2026-09-22*
