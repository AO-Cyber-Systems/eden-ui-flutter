---
objective: 23-ui-oracle-loop-w1a-catalog-as-contract
trd: 05
subsystem: testing
tags: [flutter, stories, goldens, ui-oracle, a11y, eden-layout]

requires: ["23-03", "23-04"]
provides:
  - "lib/src/widgets/eden_layout/eden_nav_item.stories.dart — 8 hand-written nav-item state fixtures"
  - "lib/src/widgets/eden_layout/eden_desktop_layout.stories.dart — desktop shell default + narrow"
  - "lib/src/widgets/eden_layout/eden_mobile_layout.stories.dart — mobile shell default"
  - "the FIRST 44 generated story tests (22 expectUiSane + 22 golden) ever to exist in this repo"
  - "kGoldenSkip / kGoldenSkipSuffix — the compile fix that makes 23-03's golden skip policy real"
affects: [23-06, W2]

key-files:
  created:
    - lib/src/widgets/eden_layout/eden_nav_item.stories.dart
    - lib/src/widgets/eden_layout/eden_desktop_layout.stories.dart
    - lib/src/widgets/eden_layout/eden_mobile_layout.stories.dart
    - test/stories/_generated/nav_item_stories_test.dart
    - test/stories/_generated/desktop_layout_stories_test.dart
    - test/stories/_generated/mobile_layout_stories_test.dart
  modified:
    - lib/dev_app/registry/register_stories.g.dart (regenerated, 3 story files)
    - test_support/ui_oracle/story_harness.dart (kGoldenSkip + kGoldenSkipSuffix)
    - tool/gen_story_tests.dart (emit `skip: kGoldenSkip`)
    - test/tool/gen_story_tests_test.dart (expectation follows the fix)
    - test/dev_app/registry/registry_complete_test.dart (49 -> 60)
    - test/tool/emit_flutter_manifest_test.dart (49 -> 60 — a THIRD count site nobody had listed)

requirements-completed: []
status: BLOCKED — see "Stop condition"
duration: ~35min
completed: 2026-09-22
---

# Objective 23 — TRD 23-05: nav/shell stories Summary

**Eleven hand-written co-located stories now exist and are registered; the oracle ran on them for the
first time and is RED on 22 of 22 `expectUiSane` tests — not because the stories are wrong, but
because the shipped `EdenDesktopLayout`/`EdenMobileLayout` fail the tap-target and semantic-label
guidelines. That is the finding this TRD existed to produce, and it needs a human decision before the
suite can be green.**

## Stop condition (why this TRD is not closed)

Per the runtime brief's stop condition 1 and the objective's own instruction — *"IF `expectUiSane`
FAILS ON A REAL eden_layout WIDGET, DO NOT WEAKEN THE ORACLE"* — the prescribed tests cannot pass as
written without one of:

- **(a)** changing `eden_desktop_layout.dart` / `eden_mobile_layout.dart` nav-row geometry (40px rows
  → ≥48px, collapse control 20px → ≥48px, a label on the mobile app-bar button). That is a **visual
  density change to a library consumed by eden-biz and aodex via a path:/git pin**, it is not
  additive, and it is in **23-06's files**. Not taken unilaterally.
- **(b)** an exemption — but `expectUiSane` has exactly one escape hatch, `allowOverlap`, which does
  not apply to guideline violations. There is no narrow, named way to exempt these without adding a
  guideline-disable knob to the oracle, i.e. weakening it. Not taken.

Everything green was committed. The 22 generated `expectUiSane` tests are left RED and honest.

## What the oracle found (the real defects, literal)

All 22 `expectUiSane` tests fail. Three distinct shell defects, not 22:

1. **Nav rows are below both touch minimums.** Every nav tile renders `Size(235.0, 42.0)`
   (`Container(height: 40)` at `eden_desktop_layout.dart:558`, `:719` + `_kNavRowBottomMargin`).
   > `SemanticsNode#7(... identifier: "eden-nav-home", label: "Home\nHome" ...): expected tap target
   > size of at least Size(48.0, 48.0), but found Size(235.0, 42.0)` — and the same node again at
   > `Size(44.0, 44.0)` for `iOSTapTargetGuideline`.
   Note this is **not fixable by enlarging the hit area alone**: at a 42px row pitch a 48px tap rect
   would make adjacent nav rows' semantics rects overlap, which `expectUiSane`'s disjointness rule
   then flags. Rail density vs. touch targets is a genuine design decision.

2. **The "Collapse sidebar" control is 20×20.** `eden_desktop_layout.dart:~432` wraps a bare
   `Icon(size: 20)` in a `GestureDetector` with no minimum size.
   > `SemanticsNode#5(Rect.fromLTRB(223.0, 18.0, 243.0, 38.0), actions: [tap], flags: [isButton],
   > label: "Collapse sidebar"): expected tap target size of at least Size(48.0, 48.0), but found
   > Size(20.0, 20.0)`

3. **`EdenMobileLayout` has an UNLABELLED 56×56 tappable button** (the app-bar leading/drawer
   control) — only visible because this is the first time the mobile shell was pumped through the
   oracle:
   > `Tappable widgets should have a semantic label: ... SemanticsNode#6(Rect.fromLTRB(0.0, 0.0,
   > 56.0, 56.0), actions: [focus, tap], flags: [isButton, hasEnabledState, isEnabled, isFocusable]):
   > expected tappable node to have semantic label, but none was found.`

**All three go to 23-06**, which already owns these files. Defect 3 is the cheapest and most clearly
safe (add a `Semantics(label:)`); defects 1 and 2 are a density decision.

## Finding: 23-03's golden skip policy could never have compiled

`testWidgets` declares **`bool? skip`** — unlike plain `test()`, which takes a `dynamic skip` and
accepts a reason String. 23-03 generated `}, skip: kGoldenSkipReason);` with `kGoldenSkipReason` a
`String?`. The first generated golden test produced, verbatim:

```
test/stories/_generated/nav_item_stories_test.dart:23:12: Error: The argument type 'String?'
can't be assigned to the parameter type 'bool?'.
  }, skip: kGoldenSkipReason);
```

16 identical errors — the whole file failed to load. This was invisible to 23-03 because the
co-located story set was empty, so the generator emitted zero golden tests: **a golden policy that
had never once been compiled, documented in a SUMMARY as working.** (Finding F1, third instance.)

Fix (commit `398633c`), keeping the reason VISIBLE rather than dropping it:
- `kGoldenSkip` (bool) gates the skip;
- `kGoldenSkipSuffix` is appended to the test NAME, so `flutter test` prints
  `nav-item/selected — dark — golden [skipped: goldens are generated and compared in CI (Linux)
  only — eden-ui-flutter#32]`.

`.github/workflows/ci.yml` was NOT touched; its comment at line 128 still refers to
`skip: kGoldenSkipReason` and should be reworded by whoever next edits that file.

## Goldens: still never executed anywhere

22 golden tests now exist (11 stories × light/dark) and **all 22 skip locally**, with the
eden-ui-flutter#32 reason string in the test name. No `--update-goldens` was run. There are still no
baselines; the CI `stories` job on Linux is the first run that will produce them, and it has not run
on this branch. **Finding F2 (google_fonts) is confirmed present but non-fatal for `expectUiSane`:**
96 `google_fonts was unable to load font ... _httpFetchFontAndSaveToDevice` errors are printed across
the 16 nav-item runs (6 faces × 16), yet the tests complete and the guideline checks DO run. Whether
`matchesGoldenFile`'s image capture survives the same fetch on Linux is **still unproven** — CI is
the first evidence either way.

## Finding: the coverage ratchet did not move, and 11 real stories bought 0 coverage

`flutter test tool/story_coverage.dart` after registering all 11 stories still writes
`{"exported_widgets": 364, "with_story": 11}` — **byte-identical**. Reason: 23-04's
`componentWidgets` has no entry for `nav-item` / `desktop-layout` / `mobile-layout`, and adding one
would still contribute 0 because 23-04's line-based export derivation collapses the whole
`eden_layout` group to a single synthetic name `EdenLayoutExports` (already counted via the indirect
`layouts` entry). So **the floor stays at 11 — that IS the real recomputed number, not a guess** —
and the ratchet is currently blind to co-located stories. Raising it honestly requires 23-04's
deferred work (resolve grouped `_exports.dart` wrappers into per-file leaf names), which would also
move `exported_widgets` off 364 and was out of scope here.

## Third count contract found

The TRD named two count sites. There are **three**: `test/tool/emit_flutter_manifest_test.dart:34`
also asserted `entries.length == 49`. All three now say 60 (49 hand-written + 11 co-located).
`registry_complete_test.dart` keeps its exact `equals(60)` — not relaxed to `>=`.

## Differential control (finding F1)

The registry-drift gate was exercised by a REAL story, not a probe: adding
`eden_nav_item.stories.dart` without regenerating gave **exit 1**:

```
STORY REGISTRY DRIFT: lib/dev_app/registry/register_stories.g.dart is out of date with the
co-located `<widget>.stories.dart` files under lib/. Regenerate and commit it:
flutter test tool/gen_stories.dart
```

## Task Evidence

| Task | Verify Command | Exit Code | Status |
|---|---|---|---|
| 1: nav-item stories (RED) | `flutter test test/stories/` | 1 (drift gate) | RED proven |
| 1: nav-item stories (GREEN) | `flutter test test/stories/` | 1 | **FAIL — oracle found real shell defects** |
| 2: desktop + mobile stories | `flutter test tool/gen_stories.dart`, `tool/gen_story_tests.dart` | 0, 0 | PASS (11 stories, 3 files) |
| 2: harness | `flutter test test/stories/` | 1 | **FAIL — same 3 shell defects** |
| 3: count contracts | `flutter test test/dev_app/registry/` | 0 | PASS at 60 |
| 3: coverage floor | `flutter test tool/story_coverage.dart` | 0 | PASS — floor unchanged at 11 (see finding) |

## Final gates

- `flutter analyze --no-fatal-infos` → **0 errors, 2 warnings** (both pre-existing, at
  `test/widgets/eden_route_stop_list_test.dart:221,244`), **369 issues** — identical to baseline.
- `flutter test` → **RED**: 22 generated `expectUiSane` failures, all three root causes above.
  Skip count rises from 5 to 27 (+22) — the 22 new golden tests, skipped off Linux by policy.
- Nothing was weakened, exempted or blessed to reach a green.

## Files NOT touched

`pubspec.yaml`, `analysis_options.yaml`, `.github/workflows/ci.yml`, `tool/gen_stories.dart`,
`eden_desktop_layout.dart`, `eden_mobile_layout.dart`, `layout_data.dart` (23-06's).
