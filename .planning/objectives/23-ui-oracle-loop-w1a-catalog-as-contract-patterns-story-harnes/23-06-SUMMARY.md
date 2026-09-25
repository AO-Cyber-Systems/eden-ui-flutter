---
objective: 23-ui-oracle-loop-w1a-catalog-as-contract
trd: 06
subsystem: widgets
tags: [flutter, eden-layout, a11y, selection, issue-33, back-compat]

requires: ["23-05"]
provides:
  - "EdenDesktopLayout.itemBuilder / .sectionBuilder — composition slots, additive"
  - "EdenMobileLayout.itemBuilder / .sectionBuilder — the same slots, additive (cases 10-11)"
  - "EdenNavItemState / EdenNavItemBuilder / EdenNavSectionBuilder on the public surface"
  - "exactly ONE semantics node per rail row, published at a single emission point"
  - "selectableBody defaults to FALSE on both Eden layouts — the eden-ui-flutter#33 fix"
  - "test/widgets/eden_layout_navigator_body_test.dart — the #33 regression gate, RED-proven"
  - "EdenMobileLayout's default app-bar menu button now carries a semantic label (23-05 defect 3)"
  - "CHANGELOG ### Changed + a single Navigator caveat in docs/autofill-and-selection.md §6"
affects: [23-12, aodex#611, eden-biz]

key-files:
  created:
    - test/widgets/eden_layout_navigator_body_test.dart
    - test/widgets/eden_desktop_layout_builders_test.dart
    - test/widgets/eden_mobile_layout_builders_test.dart
  modified:
    - lib/src/widgets/eden_layout/layout_data.dart
    - lib/src/widgets/eden_layout/eden_desktop_layout.dart
    - lib/src/widgets/eden_layout/eden_mobile_layout.dart
    - test/widgets/eden_layout_selection_test.dart
    - test/widgets/eden_purpose_sweep_16_test.dart
    - CHANGELOG.md
    - docs/autofill-and-selection.md
  NOT-modified (the back-compat proof):
    - test/widgets/eden_desktop_layout_test.dart

requirements-completed: [ISSUE-33, W1A-1a-06]
requirements-incomplete: []
status: COMPLETE — Tasks 1 (desktop AND mobile), 2 and 3 done; all TRD cases 1-19 landed
duration: ~25min (run 1: Tasks 2-3) + ~20min (run 2: Task 1 desktop) + ~15min (run 3: cases 10-11)
completed: 2026-09-22
---

# Objective 23 — TRD 23-06 Summary

**TRD 23-06 is COMPLETE. The production bug is fixed and proved, and the composition API is built
on BOTH layouts — all 19 TRD cases landed.**

`selectableBody` now defaults to `false` on both Eden layouts, the Navigator-body regression test
was seen to fail with the real upstream assertion before the flip, and
`test/widgets/eden_desktop_layout_test.dart` is byte-unmodified and green. Task 1 — the
`itemBuilder`/`sectionBuilder` slots — landed in a second executor run after the controller ruled
on the semantics tension recorded below (desktop; see **Task 1 — built, and how the ruling was
applied**) and a third run (mobile, TRD cases 10-11; see **Task 1, mobile half**).

## Task 1, desktop half — built, and how the ruling was applied

`EdenDesktopLayout` now takes `itemBuilder` and `sectionBuilder` (both nullable, both defaulted to
null, both appended after the existing optionals — additive, no positional contract moved). The
public typedefs and `EdenNavItemState` live in `layout_data.dart`, which `eden_layout_exports.dart`
already re-exports wholesale.

**The ruling: one uniform wrapper at the emission point.** `_EdenDesktopLayoutState._navRow` is now
the ONLY place the desktop layout produces a nav row. It resolves
`widget.itemBuilder ?? (a builder that declines)`, takes the result or the default renderer's, and
wraps it in a single `Semantics(identifier: 'eden-nav-<id>', button:, label:, selected:, expanded:,
onTap:)`. The annotations were **stripped out of `_NavTile` (both branches) and
`_ExpandableNavHeader`** so there is no nested pair — per F5 a nested `Semantics` without
`container: true` is not published at all. `_navSection` does the same for captions and dividers,
which carry no identifier in either path, exactly as today.

Six call sites were rerouted through those two helpers: divider, caption, expandable header,
disclosed children (`depth: 1`), non-expandable group children, the collapsed-rail stand-in tile
(whose synthesized `EdenNavItem` was extracted to `_collapsedGroupRailItem` so the emission point
and the default renderer are handed the same object), and the leaf. Widget-tree depth is unchanged:
the `Semantics` widget and the private renderer simply swapped order.

**Deviation from the TRD's published typedef — and why.** The TRD specifies
`typedef EdenNavItemBuilder = Widget Function(...)`. That shape cannot satisfy the row's own
acceptance criterion (must_haves: *"replace the rendering of ONE nav item ... without touching the
other items"*) because the default renderer is private — a consumer would have to re-implement every
row it did not want to change. The typedef ships as `Widget? Function(...)`, where `null` means
"decline this row, keep the default". This is still ONE path, not a branch: every row goes through
`_navRow`, and the default builder is the fallback. The deviation is recorded in the typedef's own
dartdoc so it is not rediscovered.

## Task 1, mobile half — cases 10-11 (run 3)

`EdenMobileLayout` now takes the same two slots, on the same shape, appended after the existing
optionals: `itemBuilder` and `sectionBuilder`, both nullable, both defaulting to null, both reusing
the `EdenNavItemBuilder` / `EdenNavSectionBuilder` / `EdenNavItemState` types already published by
`layout_data.dart` for the desktop half. No new public types.

**The desktop ruling was copied, not reinvented.** `EdenMobileLayout._navRow` is now the ONLY place
the mobile layout produces a nav row. It resolves `itemBuilder ?? (a builder that declines)`, takes
the result or the default renderer's, and wraps it in a single
`Semantics(identifier: 'eden-nav-<id>', button:, label:, selected:, onTap:)`. The annotations were
**stripped out of `_BottomItem` and `_DrawerTile`** so there is no nested pair (F5: a nested
`Semantics` without `container: true` is not published at all). `_navSection` does the same for the
drawer's captions, dividers and group bands, which carry no identifier in either path — exactly as
today.

Four call sites were rerouted through those helpers: the bottom-bar tabs, the "More" overflow tab,
the drawer's tiles (group children at `depth: 1`, and leaves), and the "More" sheet's rows. The
drawer's decorations go through `_navSection`. `_BottomItem` also gave up its own `Expanded`, which
moved to the call site so the `Row` still sees a flex child directly — render-tree shape unchanged,
only the `Semantics` and the private renderer swapped order. The overflow tab's inline
`const EdenNavItem(id: '__more__', …)` was extracted to `_moreItem` so the emission point and the
default renderer are handed the same object (the desktop `_collapsedGroupRailItem` pattern).

**The exclusion is the layout's rule, and it sits BEFORE the emission point.** `_flatItems` already
drops every caption and divider, so `bottomItems` never contains one and a consumer `itemBuilder` is
never even offered one. That is what case 11 pins: the bar cannot be made to render a decoration by
supplying a builder, because the builder is downstream of the filter.

**One finding, corrected in the open.** Case 11's first draft asserted
`offeredIds == ['home', 'reports']`. It failed: `['home', 'reports', 'home', 'reports']`. The
Scaffold builds its `drawer:` widget eagerly even while the drawer is closed, so the drawer's tiles
go through the same emission point as the bar's tabs — each id is offered twice. That is the
intended "one path" behaviour, not a defect, so the assertion was changed to a SET (the count is not
load-bearing) plus two explicit `isNot(contains('__caption__'/'__divider__'))` checks. The weakening
is narrow and named rather than silent: the decoration assertions are the load-bearing half and they
were made STRONGER, not weaker.

### Cases 10-11 TDD evidence, literal

| Phase | Command | Exit | Result |
|---|---|---|---|
| RED | `flutter test test/widgets/eden_mobile_layout_builders_test.dart` | **1** | `Error: No named parameter with the name 'itemBuilder'.` at `test/widgets/eden_mobile_layout_builders_test.dart:85:9` |
| GREEN | same | **0** | `00:00 +2: All tests passed!` |
| Pre-existing layout suites | `flutter test .../eden_mobile_layout_test.dart .../eden_layout_selection_test.dart .../eden_layout_navigator_body_test.dart .../eden_desktop_layout_test.dart .../eden_desktop_layout_builders_test.dart` | **0** | `00:00 +29: All tests passed!` |

### The differential control for cases 10-11 (F1 — a gate never seen to fail is not a gate)

The guarded thing is the `_flatItems` exclusion. It was removed in place — the line
`if (item.isDivider || item.isCaption) continue;` deleted — and the pair re-run:

```
DIFFERENTIAL CONTROL exit: 1
Expected: no matching candidates
  Actual: _TextWidgetFinder:<Found 1 widget with text "Workspace": [
Expected: Set:['home', 'reports']
  Actual: Set:['home', 'reports', '__caption__', '__divider__']
00:00 +0 -2: Some tests failed.
```

Both cases went red — case 10 on the caption reaching the bar, case 11 on the caption and the
divider reaching the consumer builder. Restored with `git checkout -- <path>` (never `git stash`),
re-run green: `00:00 +2: All tests passed!`.

### Back-compat gate for the mobile half

Every pre-existing file that constructs an `EdenMobileLayout` is byte-unmodified:

```
$ git diff --stat test/widgets/eden_mobile_layout_test.dart \
    test/widgets/eden_layout_navigator_body_test.dart \
    test/widgets/eden_layout_selection_test.dart \
    test/widgets/eden_desktop_layout_test.dart
$                                    # empty — all four unmodified, all green
```

(`grep -rln EdenMobileLayout test/` finds exactly three: `eden_mobile_layout_test.dart`,
`eden_layout_navigator_body_test.dart`, `eden_layout_selection_test.dart`. The desktop spine file is
quoted alongside them because it is the TRD's non-negotiable gate.)

### Task 1 TDD evidence, literal

| Phase | Command | Exit | Result |
|---|---|---|---|
| RED (case 6) | `flutter test test/widgets/eden_desktop_layout_builders_test.dart` | **1** | `Error: No named parameter with the name 'itemBuilder'.` |
| GREEN | same | 0 | `00:00 +4: All tests passed!` (cases 6-9) |
| Spine | `flutter test test/widgets/eden_desktop_layout_test.dart` | 0 | `00:00 +5: All tests passed!` |
| Spine + expandable + builders | `flutter test .../eden_desktop_layout_test.dart .../eden_desktop_layout_expandable_test.dart .../eden_desktop_layout_builders_test.dart` | 0 | `00:00 +38: All tests passed!` |

### The hard gate, re-proved after Task 1

```
$ git diff --stat test/widgets/eden_desktop_layout_test.dart
$                                    # empty — the file is byte-unmodified
$ flutter test test/widgets/eden_desktop_layout_test.dart
00:00 +5: All tests passed!
```

### Semantics re-measured after stripping the private renderers

Required by the ruling. `flutter test test/stories/_generated/` = `+0 ~22 -22` **before and after** —
the 22 F6 failures neither grew nor shrank, and they are the same three defects (42px rows, the
20x20 collapse control, the F2 google_fonts pair). Case 9 pins the measurement in-suite: one node
per row, `identifier`, `isButton`, `isSelected` and a tap action all present.

One observation worth recording: the published label is `'Home\nHome'` — the wrapper's own label
plus the child `Text` merging upward. That is **pre-existing**, not new: the old tree was the same
`Semantics` → `GestureDetector` → `Text` shape. Case 9 asserts it verbatim rather than tidying it,
so a future change that alters it is visible rather than silent.

## Stop condition (run 1) — Task 1 not started at that time

The ~20 minute wall-clock ceiling was reached after Task 2, Task 3 and the 23-05 defect-3 fix.
Task 1 is a refactor of a 945-line layout file with **six** distinct `_NavTile`/`_NavSectionLabel`/
`_ExpandableNavHeader`/`_DisclosedChildren` call sites, the same again in the mobile layout, and six
new test cases (TRD cases 6-11). Starting it with minutes left would have produced a half-extracted
default builder on a branch whose only proof of neutrality is a golden run in CI. Per the runtime
brief ("commit what is green and say exactly where you stopped"), nothing was begun.

**Everything committed is green and self-consistent.** `W1A-1a-06` is untouched — no partial
public surface was shipped, so a follow-up starts from a clean constructor.

There is also a **design obstacle in Task 1 that the next executor must resolve before writing
code**, found while reading the call sites and recorded here so it is not rediscovered:

> The TRD says the `Semantics(identifier: 'eden-nav-<id>')` wrapper must sit **outside** the
> builder's result (case 7). It does not today — it lives **inside** `_NavTile`
> (`eden_desktop_layout.dart:694`, `:727`) and inside `_ExpandableNavHeader` (`:541`), fused with
> `button:`, `label:` and `selected:` on the same node. Hoisting it to the call site gives the
> default path a nested `Semantics` pair, and per finding **F5** a nested `Semantics` without
> `container: true` is not published at all — its annotations merge and the parent's identifier
> wins. So "wrap the result unconditionally" is not free: it changes the semantics tree the
> oracle and the E2E tooling both read. The two honest options are (a) strip the identifier out of
> `_NavTile`/`_ExpandableNavHeader` and publish it once at the call site — which needs the
> generated-story semantics re-measured, or (b) wrap only a consumer builder's result, which the
> TRD's anti-patterns forbid as "branching". **This is a real tension between the TRD's
> `key_links` and F5 and needs a controller ruling, not an executor's guess.**

## Task status

| Task | Status | Evidence |
|---|---|---|
| 1 — `itemBuilder`/`sectionBuilder` slots (desktop) | **DONE** | RED exit 1 -> GREEN 4/4; spine 5/5 unmodified |
| 1b — the same slots on `EdenMobileLayout` (cases 10-11) | **DONE** | RED exit 1 -> GREEN 2/2; differential control exit 1 then restored |
| 2 — issue #33, flip `selectableBody` to opt-in | **DONE** | RED exit 1 → GREEN 9/9 |
| 3 — invert the selection defaults, CHANGELOG + guide | **DONE** | 8/8 green, grep sweep clean |
| (23-05 defect 3) — unlabelled mobile button | **DONE** | additive `tooltip:` on the default leading |

## TDD evidence — the #33 RED, literal

`flutter test test/widgets/eden_layout_navigator_body_test.dart` with `this.selectableBody = true`
still in place: **exit 1**, `00:00 +0 -4: Some tests failed.` — all four cases, both layouts:

```
RenderBox was not laid out: RenderFractionalTranslation#f3390 NEEDS-LAYOUT NEEDS-PAINT
'package:flutter/src/rendering/box.dart':
Failed assertion: line 2251 pos 12: 'hasSize'
  #2  RenderBox.size (package:flutter/src/rendering/box.dart:2251:12)
  #3  RenderFractionalTranslation.applyPaintTransform (rendering/proxy_box.dart:3147:50)
  #4  RenderObject.getTransformTo (rendering/object.dart:3579:25)
  #5  _SelectionContainerState.getTransformTo (widgets/selection_container.dart:208:40)
  #6  MultiSelectableSelectionContainerDelegate._compareScreenOrder
      (widgets/selectable_region.dart:2566:52)
```

That is flutter#151536 reproduced verbatim, from this repo's own default, on both
`EdenDesktopLayout` and `EdenMobileLayout`. After the flip: `00:00 +9: All tests passed!`.

### The in-suite differential control had to change shape — and why

The TRD's case 13 asked for a `selectableBody: true` + Navigator-body case that **asserts the
exception**. That test cannot be written. Three routes were measured, not assumed:

1. `tester.takeException()` → **null**. The test body is already aborted; the trailing `expect`
   runs "after the test had completed".
2. `try { await tester.pumpWidget(...); } catch (e) {...}` → **the catch never fires**. FakeAsync
   hands the microtask error to the test zone's uncaught-error handler, not up the await chain.
3. Overriding `FlutterError.onError` to record and swallow → the handler **does** receive it
   (`captured=1`), but the test still fails on
   `binding.dart:1641 Failed assertion: '_pendingExceptionDetails != null': A test overrode
   FlutterError.onError but ... had unexpected additional errors that it could not handle.`

`TestWidgetsFlutterBinding` fails a test on an uncaught zone error, full stop. So the differential
control is **recorded, not shipped**: it was performed by hand (the RED above), the exact trace and
the re-run recipe are in the test file's header comment, and its place in the suite is taken by a
**structural control** that can still fail — `STRUCTURAL CONTROL: no SelectableRegion sits over the
body`, which goes red the moment the default is flipped back, before the assertion even gets a
chance to fire. This is a deviation from the TRD's literal case 13 and is called out rather than
papered over (F1).

## Deviation: the two "nav labels are NOT inside the region" cases MOVED

The TRD's case 19 said to leave them untouched. Left untouched they would have become **vacuous**:
with no region installed by default, `find.descendant(of: SelectableRegion, ...)` returns nothing
for the trivial reason that there is no `SelectableRegion` on the tree — the containment rule, which
the file's own header calls its load-bearing assertion, would silently stop being tested. Both cases
now pump an explicitly opted-in tree (`desktopOptedIn()` / `mobileOptedIn()`), with the reason in a
comment. Per F1, a gate that cannot fail is not a gate.

## Third-party consequence found by the FULL suite

`test/widgets/eden_purpose_sweep_16_test.dart:416` — *"TRD 40-06 guard: the body is still wrapped
and nav labels stay OUTSIDE it"* — asserted the old default from a **third** file the TRD did not
list. It went red on the flip and was caught only by the full run, not by the focused paths. It now
passes `selectableBody: true` explicitly, because it is a guard about **where** the region goes, not
about whether one exists by default. This is the `clean-merge-hides-moved-wiring` shape: the TRD
enumerated two selection-asserting test files and there were three.

## 23-05 defect 3 — fixed; defects 1 and 2 deliberately untouched

`EdenMobileLayout`'s default app-bar leading was a bare `IconButton(icon: Icon(Icons.menu))` — a
56x56 tappable node with **no semantic label at all**, and the drawer is the only route to every
overflow destination. Fixed additively with `tooltip: 'Open navigation menu'` on the **default**
leading only; a consumer-supplied `topBar.leading` is untouched.

**Caveat, stated plainly:** this fix is **not currently confirmed by the generated-story gate.**
Both `mobile-layout/default` `expectUiSane` tests now fail on **finding F2** —
`google_fonts was unable to load font Outfit-ExtraBold ... Failed to load font with url:
https://fonts.gstatic.com/...` — which completes the test before any guideline assertion runs. The
tap-target/label assertions never execute there. The fix is correct by inspection (the story does
set `topBar:`, so the AppBar and its leading button do render), but do not read the unchanged
failure count as confirmation.

Defects **1** (42px nav rows) and **2** (20x20 collapse control) were **not touched**: they are a
rail-density decision for two shipped apps, reserved for the controller. `expectUiSane` was not
weakened, no tolerance knob was added, no golden was blessed.

## Generated-story failure count: 22 → 22 (unchanged)

`flutter test test/stories/_generated/` before: `+0 ~22 -22`. After: `+0 ~22 -22`. Nothing grew.
Measured again at the end of run 3, after the mobile layout's semantics were restructured: still
`+0 ~22 -22`.

**Do NOT read that unchanged count as confirmation of the mobile work.** Per F2, the
`mobile-layout/*` `expectUiSane` tests die on a `google_fonts` network fetch for `Outfit-ExtraBold`
BEFORE any guideline assertion runs, so they cannot confirm or deny a change to the mobile shell's
semantics either way. The mobile evidence that IS real is in-suite: case 10 and case 11 assert
`find.bySemanticsIdentifier('eden-nav-<id>')` `findsOneWidget` per destination — one node per row,
not a nested pair — and the 29 pre-existing layout-test cases stayed green byte-unmodified.
`expectUiSane` was not weakened and no tolerance or disable knob was added.

## Consumer impact — neither repo edited from here

- **aodex** can drop its hand-rolled `selectableBody: false` opt-out (aodex#611, six routing tests).
- **eden-biz** gets the Navigator fix with no action; it was one nested route from the same failure.
- Any consumer that *wants* drag-selection must now pass `selectableBody: true`. Documented in
  `CHANGELOG.md`'s `### Changed` with the migration line, and in `docs/autofill-and-selection.md` §6
  as one Navigator caveat linked from all three mention sites — including the `MaterialApp.builder`
  recipe, which installs a region above the app's own Navigator and carries the identical exposure.

## Validation gates

| Gate | Command | Result |
|---|---|---|
| back-compat spine | `git diff --stat test/widgets/eden_desktop_layout_test.dart` | **EMPTY**, 5/5 green |
| #33 regression | `flutter test test/widgets/eden_layout_navigator_body_test.dart` | exit 0, 4/4 |
| selection defaults | `flutter test test/widgets/eden_layout_selection_test.dart` | exit 0, 8/8 |
| stale-default grep | `grep -rn selectableBody ... \| grep -i "defaults to true"` | only the two intentional "the default used to be `true`" history lines in the layout dartdocs |
| lint | `flutter analyze --no-fatal-infos` | **0 errors**, 2 pre-existing warnings, 369 issues — baseline exactly |
| full suite | `flutter test` | `+4675 ~27 -22` (baseline was `+4669 ~27 -22`) |

## Grep sweep result

The only surviving "`true`" mentions are the two deliberate history lines
(`eden_desktop_layout.dart:27`, `eden_mobile_layout.dart:27`): *"The default used to be `true`; it
was flipped because…"*. They are the record of the change, not a stale claim.

## Commits

| SHA | Subject |
|---|---|
| `ff390ee` | `test(23-06): RED — Navigator-body deep-link asserts under the selectableBody default` |
| `ca51933` | `fix(23-06): selectableBody is opt-in — eden-ui-flutter#33 / flutter#151536` |
| `af6af8c` | `docs(23-06): carry the selectableBody behaviour change into CHANGELOG, guide and tests` |
| `4286c49` | `fix(23-06): label EdenMobileLayout's app-bar menu button (23-05 defect 3)` |
| `e6e8cd7` | `test(23-06): state the opt-in in the TRD 40-06 region-placement guard` |
| `3ace3cf` | `test(23-06): RED — EdenDesktopLayout has no itemBuilder slot` |
| `7b1a04e` | `feat(23-06): EdenDesktopLayout composition slots, one semantics node per row` |
| `1d5954f` | `test(23-06): cases 7-9 — the identifier survives any consumer builder` |
| `4c6cc2d` | `refactor(23-06): read case 9's flags off SemanticsData, not deprecated hasFlag` |
| `8d48d06` | `test(23-06): RED — EdenMobileLayout has no itemBuilder slot (cases 10-11)` |
| `7d0aa6e` | `feat(23-06): EdenMobileLayout composition slots, one semantics node per row` |

### Gate tallies after Task 1

| Gate | Before Task 1 | After Task 1 |
|---|---|---|
| `flutter test` | 4675 passed / 27 skipped / 22 failed | **4679 passed / 27 skipped / 22 failed** (+4 = the new cases) |
| `flutter test test/stories/_generated/` | `+0 ~22 -22` | `+0 ~22 -22` |
| `flutter analyze` | 0 errors, 2 warnings, 369 issues | **0 errors, 2 warnings, 369 issues** |
| `git diff --stat test/widgets/eden_desktop_layout_test.dart` | empty | **empty** |

### Gate tallies after the mobile half (run 3)

The run-3 baseline is higher than the run-2 "after" column because 23-09 landed in between.

| Gate | Before (run-3 baseline) | After |
|---|---|---|
| `flutter test` | 4685 passed / 27 skipped / **22 failed** | **4687 passed / 27 skipped / 22 failed** (+2 = cases 10-11) |
| `flutter test test/stories/_generated/` | `+0 ~22 -22` | `+0 ~22 -22` |
| `flutter analyze --no-fatal-infos` | 0 errors, 2 warnings, 369 issues | **0 errors, 2 warnings, 369 issues** |
| `git diff --stat` on all 3 pre-existing `EdenMobileLayout` test files + the desktop spine | empty | **empty** |
| differential control (delete the `_flatItems` exclusion) | — | **exit 1**, both cases red, restored |

The 2 warnings are the pre-existing `unnecessary_non_null_assertion` pair at
`test/widgets/eden_route_stop_list_test.dart:221` and `:244` — not touched. The 22 failures are the
same F6 set (42px nav rows, the 20x20 collapse control, the F2 `google_fonts` pair); defects 1 and 2
remain the controller's rail-density decision and were not touched here.

## Follow-ups for the controller

1. ~~Task 1 desktop slots are built; the MOBILE half (TRD cases 10-11) is not.~~ **RESOLVED in run
   3** — `EdenMobileLayout` has the same `itemBuilder`/`sectionBuilder` pair, the same single
   emission point, and cases 10-11 green with a differential control. TRD 23-06 is fully complete.
1b. **The builder typedef is `Widget? Function(...)`, not the TRD's `Widget Function(...)`** — the
   nullable return is what makes per-item replacement expressible at all. Worth carrying back into
   IMPLEMENTATION-PLAN row 1a-06 so the two do not disagree.
2. The 22 generated-story failures stand. Two of them (`mobile-layout/*`) are **F2 google_fonts**
   failures, not a11y failures — worth separating in whatever closes out F6, because as long as they
   die on a font fetch the mobile shell has no working a11y gate at all.
3. `.github/workflows/ci.yml:128`'s comment still references `skip: kGoldenSkipReason` (stale since
   23-05). Not touched here — `ci.yml` is out of scope for this TRD.
