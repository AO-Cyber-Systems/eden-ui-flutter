---
objective: 10-rim-the-rail-badge-unblock-the-measure-ink-guards
trd: 10
subsystem: ui / testing-instrumentation
tags: [flutter, wcag-1.4.11, contrast, ui-oracle, golden-gate, eden_ui_flutter]
key-files:
  modified:
    - test_support/ui_oracle/measure_ink.dart
    - test/ui_oracle/measure_ink_guards_test.dart
    - lib/src/widgets/eden_layout/eden_desktop_layout.dart
    - lib/src/widgets/eden_layout/nav_selection_indicator.dart
    - lib/src/widgets/eden_layout/nav_ink.dart
    - test/ui_oracle/desktop_rail_contrast_test.dart
    - test/widgets/eden_desktop_layout_expandable_test.dart
    - lib/src/widgets/eden_layout/eden_desktop_layout.stories.dart
    - lib/dev_app/registry/register_stories.g.dart (unchanged — file-level registration already covered the list)
    - test/stories/_generated/desktop_layout_stories_test.dart
    - test/stories/golden_uniqueness_test.dart
    - lib/src/widgets/eden_data_display/eden_appointment_list.dart
    - lib/src/widgets/eden_data_display/eden_appointment_list.stories.dart
    - test/ui_oracle/appointment_glyph_contrast_test.dart
    - test/design/design_md_fresh_test.dart
  created:
    - .planning/quick/10-rim-the-rail-badge-unblock-the-measure-i/deferred-items.md
verification:
  narrow_tests_run: true
  full_suite_exit_code: 0
  full_suite_counts: "4531 passed / 37 skipped (goldens skip on macOS)"
completed: 2026-09-29
---

# Quick Job 10: Rim the rail badge, unblock the measure_ink guards, add the story that would have caught it — Summary

**Third remediation in the eden-ui-flutter#58 chain: unblocked `paintedBackgroundOf` for measurable translucent ink (making `expectInkContrast`'s alpha-blend branch live instead of dead code), rimmed the desktop-rail badge with `edenNavOnFillInk` (a real, pre-existing WCAG 1.4.11 defect at 2.20:1 that predates #58 and nobody had named), and closed the golden-uniqueness gate's `kAwaitingCIBaseline` gap for the new fixture story — 10 atomic commits, all narrow verification green, full four-directory suite EXIT=0.**

## Status: DONE

All three tasks executed and committed. All three RED/GREEN evidence pairs the plan asked for were actually observed and are reproduced verbatim below — none reconstructed from memory. One deviation from a plan PROPOSAL is flagged explicitly (Task 2, item 5's sourcing mechanism) — see "Flagged guesses" below.

## Commits, in order

| # | SHA | Type | What |
|---|---|---|---|
| 1 | `0126b17` | fix | T1 — unblock `paintedBackgroundOf` for a measurable translucent ink |
| 2 | `fe4d15b` | fix | T2 — rim the badge; fix chevron/pill overlap; correct stale ratio dartdocs |
| 3 | `d06ae23` | test | T2 — pin the badge's own boundary; update chevron-gap geometry baseline |
| 4 | `632a335` | feat | T3(a) — collapsed rail with badged-selection story |
| 5 | `28d82ad` | test | T3(b) — name the awaiting-CI baseline pair; relax the golden floor by exactly that count |
| 6 | `0efac67` | refactor | T3(c) — migrate the two `EdenGlyphInk` call sites to `.of(context)` |
| 7 | `26a2ccb` | test | T3(c) — pin `EdenGlyphInk.of` against the theme, not platform, brightness |
| 8 | `0a85d01` | docs | T3(d)+(e) — correct stale fixture dartdoc and disclosure claim |
| 9 | `907c8a7` | test | T3(f) — close the non-recursive token-file partition |
| 10 | `0a653e8` | docs | T3(g) — record three out-of-scope findings |

Base: `b235194` (tip of `fix/55-icon-contrast` at session start). All 10 commits are ahead of that on this worktree's own branch — nothing pushed, no PR touched, no `gh` run.

---

## The three RED captures — verbatim, as observed

### 1. Task 1 — the combined-guard case

**RED** (captured against unmodified `measure_ink.dart`, both new test cases in `measure_ink_guards_test.dart`'s "(a)+(b) combined" group failing on the exact same `StateError`):

```
Bad state: paintedBackgroundOf was asked to exclude a translucent ink (#112233, alpha 0.60). A
translucent ink's own composited pixels never match its raw (unblended) bytes in a rasterised frame,
so the exclusion cannot find them and they can win the histogram mode as "the background" — which
reports a spurious near-1.0:1 ratio once the caller blends the same ink over it a second time.
Composite the ink over its actual background (Color.alphaBlend) and pass that opaque colour instead.
```

Both new tests failed with this identical StateError (2 failures out of 4 total in the file; the
pre-existing "(b)" and "(c)" cases stayed green, exactly as the plan specified).

**GREEN** after the guard restructure — full four-directory run (`test/ui_oracle/ test/design/
test/widgets/ test/stories/`), `EXIT=0`, both new cases now passing:

```
(a)+(b) combined — where the two guards meet a dimmed icon over an opaque background is measured, not refused
(a)+(b) combined — where the two guards meet expectInkContrast computes against the alpha-blended ink (measure_ink.dart:276-277 goes live)
...
All tests passed!
```
(4520 passed / 35 skipped at that point in the session — skip count is goldens, which skip on this
macOS worktree.)

### 2. Task 2, item 5 — the EXPANDED-rail badge adjacency (the most valuable finding)

This is a **real, pre-existing WCAG 1.4.11 defect that predates #58 entirely** — the badge's fill
(`colorScheme.primary`, brand gold) sitting directly on the rail's own white fill in the light
theme, with nothing carrying its boundary. Nobody had named it because no test measured the badge's
own adjacency in the EXPANDED branch; every prior audit looked at the SELECTION carrier (the pill),
never the badge sitting on top of it.

**RED**, captured by temporarily stripping the rim border from `_Badge`'s `BoxDecoration` (product
code reverted to its committed, un-rimmed form for this one run, then restored — confirmed via
`git diff --stat` showing zero diff after restoration):

```
Expected: a value greater than or equal to <3.0>
  Actual: <2.2046389754678724>
   Which: is not a value greater than or equal to <3.0>
the EXPANDED badge's boundary against the rail's own fill (#FFFFFF) is carried by its fill: rim
0.00:1, fill 2.20:1. `_Badge` is consumed by BOTH `_NavTile` branches, and expanded it sits on the
rail's own fill, not a pill — a distinct adjacency from the collapsed case above, with distinct
numbers. Neither the rim nor the fill alone is required to carry it, but at least one MUST, and
today (before the rim) the fill alone is the only candidate.
```

Actual computed ratio: **2.2046389754678724 → 2.20:1**, matching the plan's stated figure exactly.
Dark theme did NOT fail at this point (fill alone was already 7.61:1 there — see below).

**GREEN** after restoring the rim, captured by temporarily forcing the assertion's floor to an
unreachable value (`3.0 + 1000`) so the passing computation's actual numbers would print, then
reverting the floor to `3.0`:

- **Light:** `Actual: <17.71676507806213>` → **17.72:1**, carried by the **rim** (message: `rim
  17.72:1, fill 2.20:1`) — matches the plan's stated 17.72:1 exactly.
- **Dark:** `Actual: <7.609006416465632>` → **7.61:1**, carried by the **fill**, rim inert at 1.00:1
  (message: `rim 1.00:1, fill 7.61:1` — the rim token `edenNavOnFillInk` IS the dark rail fill, so
  it vanishes into it rather than helping or hurting) — matches the plan's stated 7.61:1 exactly.

With the floor restored to `3.0`, the full `desktop_rail_contrast_test.dart` file: `EXIT=0`, all 31
tests passing (`All tests passed!`).

### 3. Task 3(b) — the golden-uniqueness floor, all four cases

**RED**, captured by temporarily reverting `golden_uniqueness_test.dart` to its pre-patch (committed
`b235194`) state — with the new story ALREADY registered and regenerated — then restoring the patch
afterward (`cp` from a scratchpad backup, confirmed identical to the patched version via `git diff
--stat`):

```
case 1: the baseline set can be computed, or this gate fails [E]
  golden uniqueness: test/stories/_generated/goldens/ci holds 34 PNG(s), and the story catalogue declares 36 (18 stories in 2 themes). A short directory means the baselines were not committed, so this gate would be comparing a fraction of the catalogue and reporting a pass about all of it. ...

case 4: every (story, theme) in the catalogue HAS a baseline [E]
  golden uniqueness: ... holds 34 PNG(s) ... declares 36 ... [identical message]

case 2: no two golden baselines are byte-identical [E]
  golden uniqueness: ... holds 34 PNG(s) ... declares 36 ... [identical message]

case 3: every allowlisted pair is STILL byte-identical [E]
  golden uniqueness: ... holds 34 PNG(s) ... declares 36 ... [identical message]

Some tests failed.
```

All FOUR cases failed via the identical unconditional-floor message from `_baselines()`, before
case 4's own missing/orphan/collision logic was ever reached — exactly as the plan predicted (34
existing PNGs = 17 stories × 2 themes; 36 expected = 18 stories × 2 themes after the new story;
short by exactly the 2 new, unblessed baselines).

**GREEN** after the patch (`kAwaitingCIBaseline` naming the pair, floor relaxed by exactly
`kAwaitingCIBaseline.length`, case 1's restated assertion relaxed the same way, case 4 asserting the
allowance is a subset of `expected` before subtracting it, plus a new self-retiring "case awaiting"):

```
case 1: the baseline set can be computed, or this gate fails
case 4: every (story, theme) in the catalogue HAS a baseline
case awaiting: every kAwaitingCIBaseline entry is STILL absent from disk
case 2: no two golden baselines are byte-identical
case 3: every allowlisted pair is STILL byte-identical
All tests passed!
```

All FIVE cases pass. Re-confirmed again at the very end of the session, independently, with an
identical result.

---

## Flagged guesses — what held, what I deviated from

The plan named three prescriptions to settle by exit code rather than by reasoning about them:

1. **Task 1's guard-(b) restructure "Implementation shape."** HELD, unmodified from the proposal:
   remove the entry gate, build the histogram identically, make the exclusion ink-aware (opaque path
   byte-identical to before; translucent path excludes an entry explainable as the ink composited
   over another histogram entry), keep a loud failure when every entry is near the leading one (the
   genuinely-one-colour box). RED then GREEN both matched exactly.

2. **Task 2, item 4 (lower-2)'s PROPOSAL** — whether sampling `paintedBackgroundOf(selectedRowFinder,
   pillFill)` actually resolves to the row's own background in BOTH the collapsed (~5% margin,
   56x44 box) and expanded (~236x40, comfortable) branches, or whether the collapsed case is too
   thin to trust and needs falling back to expanded-only. **HELD in both branches** — the modified
   test (now sampling the SELECTED row's own box, keyed `eden-nav-row-${item.id}`, excluding the
   pill fill) passed in all four (mode × railState) combinations, so no fallback to expanded-only
   was needed.

3. **Task 2, item 5's sourcing PROPOSAL** — the plan suggested sourcing `railFill` the same way item
   4 sources the pill's adjacent colour: `paintedBackgroundOf(selectedRowFinder, badgeFill)` over the
   keyed selected row. **I did not implement it this way.** I sourced `railFill` directly from the
   theme token (`theme.brightness == Brightness.dark ? EdenColors.neutral[900]! : Colors.white`),
   mirroring this same file's own pre-existing convention in the "no rail row paints a primary@0.1
   selection band" test a few lines above. This is a genuine deviation from the stated proposal, not
   a confirmation of it — I did not attempt the `paintedBackgroundOf`-based sourcing and cannot say
   whether it would also have worked. The numbers the simpler approach produced (2.20:1 RED, 17.72:1
   / 7.61:1 GREEN) matched the plan's independently-stated figures exactly, so the underlying
   PREDICTION held even though the specific sourcing MECHANISM I used was not the one proposed.

No assertion was loosened, widened, or bent to make a test pass. Where a test needed a genuinely new
expected value (the two chevron-gap geometry literals — see below), the new value was independently
derived from the same arithmetic the surrounding code comment already states, not reverse-engineered
from the test's own failure.

## One unplanned fix, applied under deviation Rule 1

Rimming the badge and widening `_kExpandableChevronGap` from 4 to 12 (job's action item (d), lower-1)
moved `eden_desktop_layout_expandable_test.dart` case 22's hardcoded header geometry literals
(`headerIconDx` 38→46, `headerLabelDx` 70→78 — a deterministic +8px consequence of the gap change,
independently re-derived: `12 (ListView pad) + 4 (leftPad) + 18 (chevron) + 12 (gap) = 46`). Caught
by the full four-directory suite run after Task 2's product changes (one failure, `[E]` on that exact
assertion). Fixed inline as an auto-fix (Rule 1 — the test was pinning a literal an intentional,
correctly-derived geometry change legitimately moves) and re-verified narrowly, then in the full
suite again (`EXIT=0`).

---

## Golden baseline handoff — CI must generate these; none of this is locally verified

`story_harness.dart:43` sets `kGoldenSkipReason = Platform.isLinux ? null : …`, so **every golden
comparison SKIPPED in every local run this session**, on every file, every time. A green local run —
including all the `EXIT=0`s quoted above — says nothing about pixels. No `--update-goldens`, no `gh`
workflow dispatch, no golden re-blessing was run or attempted.

**NEW baselines CI must generate** (file names per `story_harness.dart:105`,
`story.id.replaceAll('/', '_')`), in `test/stories/_generated/goldens/ci/`:

- `desktop-layout_collapsed-badged-selection.light.png`
- `desktop-layout_collapsed-badged-selection.dark.png`

(Named exactly in `kAwaitingCIBaseline`; self-retiring — the new "case awaiting" in
`golden_uniqueness_test.dart` will go RED the moment either file is committed, which is the signal to
delete the two `kAwaitingCIBaseline` entries in that same PR.)

**EXISTING baselines expected to MOVE**, with reasons:

- `desktop-layout_default.light.png`, `desktop-layout_default.dark.png` — the `'orders'` row is
  selected and carries `badge: '3'`; the badge is now rimmed unconditionally.
- `desktop-layout_narrow.light.png`, `desktop-layout_narrow.dark.png` — same shell at 720px, same
  badged selection.
- `nav-item_badge.light.png`, `nav-item_badge.dark.png` — the badge rim is unconditional (not gated
  on `isSelected`), so any story rendering a badge moves regardless of selection state.
- `nav-item_expandable-collapsed.light.png`, `nav-item_expandable-collapsed.dark.png` — the chevron
  gap widened from 4 to 12; these stories select `'home'`, not the expandable row, so only the
  chevron/icon/label spacing shifts, not any pill/badge colour.
- `nav-item_expandable-expanded.light.png`, `nav-item_expandable-expanded.dark.png` — same reason.

**Expected NOT to move**, stated so an unexpected diff in these is a signal rather than noise:
`mobile-layout_*` (the three mobile badges are separate widgets, gain no rim), `list-appointments_*`
(the `EdenGlyphInk.of` migration is pixel-identical — both sites already bound `theme =
Theme.of(context)`; the other changes there are comments), `error-refusal_*`, and
`nav-item_{default,selected,caption,divider,long-label}` (no badge, no expandable header, so neither
change reaches them).

Any diff outside these two lists is a finding to report, not churn to wave through.

---

## Deferred items (see `deferred-items.md` in this directory — no `gh`, so not filed as issues)

1. **`_DisclosedChildren`'s hairline strikes through a selected child's pill.** The rule paints AFTER
   (on top of) the child rows in its `Stack`, and its x-span (`[17, 18]`) falls inside a disclosed
   child's expanded-branch pill span (`~[14, 54]`) — pre-existing, no test pumps a disclosed group
   with a selected child to catch it.
2. **`decorationInk` takes `.first`** where every sibling resolver in `measure_ink.dart`
   (`paintedBackgroundOf`, `iconInk`, `textInk`) uses `.single`. Not observed to have caused a wrong
   measurement in this remediation; an inconsistency in the instrument's own cardinality contract.
3. **`iconInk`'s `base == null` throw is unreachable.** `IconTheme.of(context)` always falls back to
   a non-null colour (`IconThemeData.fallback()`), so `declared ?? inherited` can never actually be
   null. Confirmed by reading the Flutter SDK source, not executed as a repro.

---

## Task Evidence

| Task | Verify command (narrow) | Exit | Status |
|---|---|---|---|
| 1 | `flutter test -j 2 test/ui_oracle/measure_ink_guards_test.dart` (RED) | 1 | RED as expected |
| 1 | `flutter test -j 2 test/ui_oracle/ test/design/ test/widgets/ test/stories/` (GREEN) | 0 | PASS (4520/35 skip) |
| 2 | `flutter test -j 2 test/ui_oracle/desktop_rail_contrast_test.dart` (RED, rim stripped) | 1 | RED as expected |
| 2 | `flutter test -j 2 test/ui_oracle/desktop_rail_contrast_test.dart` (GREEN, restored) | 0 | PASS (31/31) |
| 2 | `flutter test -j 2 test/widgets/eden_desktop_layout_expandable_test.dart` (after geometry fix) | 0 | PASS |
| 2 | `flutter test -j 2 test/ui_oracle/ test/design/ test/widgets/ test/stories/` | 0 | PASS |
| 3(a) | `flutter test tool/gen_stories.dart` / `tool/gen_story_tests.dart` | 0 / 0 | PASS |
| 3(a) | `flutter test -j 2 test/stories/_generated/desktop_layout_stories_test.dart` | 0 | PASS |
| 3(a) | `flutter test -j 2 test/stories/registry_drift_test.dart test/stories/generated_freshness_test.dart test/stories/coverage_test.dart` | 0 | PASS |
| 3(b) | `flutter test -j 2 test/stories/golden_uniqueness_test.dart` (RED, pre-patch) | 1 | RED, all 4 cases |
| 3(b) | `flutter test -j 2 test/stories/golden_uniqueness_test.dart` (GREEN, patched) | 0 | PASS, all 5 cases |
| 3(c) | `flutter test -j 2 test/ui_oracle/appointment_glyph_contrast_test.dart` | 0 | PASS (5/5) |
| 3(d)+(e) | `flutter test -j 2 test/ui_oracle/appointment_glyph_contrast_test.dart` | 0 | PASS |
| 3(f) | `flutter test -j 2 test/design/design_md_fresh_test.dart` (RED, probe present) | 1 | RED as expected |
| 3(f) | `flutter test -j 2 test/design/design_md_fresh_test.dart` (GREEN, probe removed) | 0 | PASS |
| all | `flutter test -j 2 test/ui_oracle/ test/design/ test/widgets/ test/stories/` (final) | 0 | PASS (4531/37 skip) |

`flutter analyze` was run and clean (`No issues found!`) on every changed file, checked in after
each edit before running tests.

## Post-Job Verification

- Auto-fix cycles used: 1 (the chevron-gap geometry baseline — Rule 1, see above)
- Must-haves verified: all 8 `truths` in the job's `must_haves` frontmatter were exercised by the
  work above (guard restructure, both `_Badge` adjacencies measured in both branches/themes, the
  loud-failure boundary preserved, the collapsed+badged story, the self-retiring awaiting-baseline
  naming, the `_ExpandableNavHeader` horizontal fix, and every ratio in a touched comment re-derived
  against the committed tokens)
- Gate failures: None outstanding — the one geometry-baseline failure encountered mid-session was
  fixed and re-verified (see "One unplanned fix" above)

## Self-Check

- Every commit SHA above verified present via `git log --oneline b235194..HEAD`: FOUND, all 10, in
  the stated order.
- `deferred-items.md`: FOUND at
  `.planning/quick/10-rim-the-rail-badge-unblock-the-measure-i/deferred-items.md`.
- Final full four-directory suite re-run at the end of the session, independent of any per-task run:
  `EXIT=0`, 4531 passed / 37 skipped.

## Self-Check: PASSED
