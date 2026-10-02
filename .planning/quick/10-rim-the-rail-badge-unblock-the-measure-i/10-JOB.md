---
objective: 10-rim-the-rail-badge-unblock-the-measure-ink-guards
trd: 10
type: standard
wave: 1
depends_on: []
autonomous: false
stack: flutter
files_modified:
  - test_support/ui_oracle/measure_ink.dart
  - test/ui_oracle/measure_ink_guards_test.dart
  - lib/src/widgets/eden_layout/eden_desktop_layout.dart
  - lib/src/widgets/eden_layout/nav_selection_indicator.dart
  - lib/src/widgets/eden_layout/nav_ink.dart
  - lib/src/tokens/glyph_ink.dart
  - test/ui_oracle/desktop_rail_contrast_test.dart
  - lib/src/widgets/eden_layout/eden_desktop_layout.stories.dart
  - lib/dev_app/registry/register_stories.g.dart
  - test/stories/_generated/desktop_layout_stories_test.dart
  - test/stories/golden_uniqueness_test.dart
  - lib/src/widgets/eden_data_display/eden_appointment_list.dart
  - lib/src/widgets/eden_data_display/eden_appointment_list.stories.dart
  - test/ui_oracle/appointment_glyph_contrast_test.dart
  - test/design/design_md_fresh_test.dart
  - .planning/quick/10-rim-the-rail-badge-unblock-the-measure-i/deferred-items.md
must_haves:
  truths:
    - "In the COLLAPSED rail, a badge on the SELECTED row is distinguishable from the selection pill it is painted on top of. Today both are `colorScheme.primary` and the badge overlaps the pill on 15 of its 16 vertical pixels: 1.00:1, and only the near-black digit survives."
    - "The badge's boundary carries its shape on EVERY adjacency it actually has — on the pill (collapsed, selected) AND on the rail's own fill (expanded), in BOTH themes. Not just the one adjacency that prompted the fix. Fixing one adjacency and never measuring the others is how #58 produced this regression, and how its own fix produced two more."
    - "A glyph dimmed by an ancestor `IconTheme.opacity` can be MEASURED. Today `iconInk` deliberately returns translucent ink for exactly that case and `paintedBackgroundOf` throws on exactly that ink, so the case guard (a) exists for is the case the instrument refuses. A hard error where a correct measurement is available is still a check that does not check."
    - "The case that GENUINELY cannot be measured — a box that is entirely one translucent fill, where 'this is the surface' and 'this is the ink over an unseen surface' are indistinguishable — still fails loudly. Unblocking the measurable case must not blind the unmeasurable one."
    - "A story renders the collapsed rail with the selected row ALSO badged. That combination is the defect, no story renders it today, and that is why all seven CI checks are green on a 1.00:1 defect."
    - "A new story that has no committed baseline yet is NAMED as awaiting one, and the naming RETIRES ITSELF the moment CI commits the file. A story with no baseline is a comparison that never runs and, off Linux, never even reports a skip against a name."
    - "`_ExpandableNavHeader`'s selection pill does not paint over the chevron beside it. The vertical clearance argument transferred from `_NavTile` does not hold horizontally, because this row has a 4px gap and an 18px sibling where `_NavTile` has 12px of padding and nothing."
    - "Every ratio quoted in a comment in this PR is the ratio the formula actually yields for the tokens named. A comment that quotes a number nothing computes is documentation of a measurement that was never taken."
  artifacts:
    - path: test_support/ui_oracle/measure_ink.dart
      what: "surface resolved BEFORE translucent ink is rejected; the ink-vs-histogram exclusion blends over each candidate; the loud failure kept for the genuinely unmeasurable box"
    - path: test/ui_oracle/measure_ink_guards_test.dart
      what: "adds the (a)+(b) COMBINED case the file's own header describes as 'opposite failure modes on the same axis' without noticing they meet"
    - path: lib/src/widgets/eden_layout/eden_desktop_layout.dart
      what: "_Badge gains an edenNavOnFillInk rim; _ExpandableNavHeader's horizontal geometry fixed; keyed nav rows; dead colourless BoxDecorations resolved"
    - path: lib/src/widgets/eden_layout/eden_desktop_layout.stories.dart
      what: "the collapsed + badged-selection story — the fixture that would have caught HIGH-1"
    - path: test/stories/golden_uniqueness_test.dart
      what: "self-retiring kAwaitingCIBaseline allowance, so the new story's missing baseline is named rather than silently absent or the gate weakened"
  key_links:
    - "_Badge (eden_desktop_layout.dart ~:1034) is consumed by BOTH _NavTile branches — collapsed (~:972, on the pill) and expanded (~:1022, on the rail's own fill). The rim must be measured against BOTH surfaces in BOTH themes before it lands."
    - "paintedBackgroundOf's translucent-ink gate (~:78-89) is what makes expectInkContrast's `ink.a == 1.0 ? ink : Color.alphaBlend(ink, surface)` branch (~:276-277) dead code. Unblocking the gate is what makes that branch live; the new combined test is what proves it executes."
    - "The story must reach CI through tool/gen_stories.dart AND tool/gen_story_tests.dart. registry_drift_test.dart and generated_freshness_test.dart compare committed bytes against a fresh generation, so a hand-edited generated file is a red CI job."
    - "golden_uniqueness_test.dart's `_baselines()` (~:156) floors `files.length` against `expectedBaselineNames()`, which is built from the regenerated register_stories.g.dart. Registering a story without re-blessing trips that floor in cases 1, 2, 3 AND 4 — all four call `_baselines()`. Resolved by naming the pair and relaxing the floor by exactly that count, never by weakening a case."
  - "_Badge's two adjacencies are covered by two DIFFERENT assertions: collapsed (rim vs the pill) and expanded (rim-or-fill vs the rail's own painted fill). Neither substitutes for the other, and `wcagContrast(rim, colorScheme.primary)` is mathematically the badge's own fill in both branches — it can never read the rail-fill adjacency."
---

# Rim the rail badge, unblock the measure_ink guards, add the story that would have caught it

Branch `fix/55-icon-contrast`, worktree `/Users/markemerson/Source/eden-ui-contrast`, HEAD `b235194`.
**Work ONLY here. No push, no PR, no merge, no `gh`, no `--update-goldens`.**

## Read this before Task 1

#58 fixed a contrast defect. Reviewing that fix found a regression. Fixing THAT found two
more. All seven CI checks are green right now, on a badge that measures **1.00:1**. Green is
not evidence here; a computed number against the real tokens is.

**Every ratio below was re-derived with the WCAG sRGB formula against the tokens as they are
committed today, and every one of the brief's figures reproduced exactly. Re-derive them
yourself anyway — do not copy these into a comment you have not recomputed.** Token sources:
`colorScheme.primary` = `EdenColors.gold` `#D4A853` light / `gold[400]` `#E59A3C` dark
(`eden_theme.dart:33,75`); `onPrimaryContainer` = `gold[900]` `#6C5029` light / `gold[100]`
`#FAECD5` dark (`:36,78`); `edenNavOnFillInk` = `neutral[900]` `#18181B`; rail fill =
`Colors.white` light / `neutral[900]` dark.

---

## Task 1 — Unblock the instrument (HIGH-2)

**Type:** `auto`, `tdd="true"`

### files

- `test_support/ui_oracle/measure_ink.dart`
- `test/ui_oracle/measure_ink_guards_test.dart`

### Test list (write this list into the test file's header BEFORE any test code)

1. **(a)+(b) COMBINED.** `IconTheme(opacity: 0.6)` wrapping an `Icon` with an explicit colour,
   over an opaque coloured background. `iconInk` returns alpha 0.6 (guard (a) doing its job);
   `paintedBackgroundOf` returns the background colour and **does not throw**.
   *RED today with the guard-(b) `StateError`.*
2. **The dead branch executes.** The same tree through `expectInkContrast`: the ratio is
   computed against `Color.alphaBlend(ink, surface)`, i.e. `measure_ink.dart:276-277` — dead
   code today — actually runs. Assert the reported ink is the blended one, not the declared one.
   *RED today.*
3. **The unmeasurable case still fails loudly.** The existing `(b)` case — an 80x80 box that is
   ENTIRELY one translucent fill — still throws. There is no underlying surface visible in that
   box, so "this is the surface" and "this is the ink over an unseen surface" are
   indistinguishable, and answering either is a guess. *GREEN today; MUST STAY GREEN.*
4. `(a)` in isolation and `(c)` off-frame: unchanged, still GREEN.

Do them **one at a time**, RED then GREEN, per the TDD playbook. No batching.

### action

Guard (a) (`iconInk` ~:219-222) makes `iconInk` deliberately return translucent ink when an
ancestor `IconTheme.opacity < 1` — that is its entire purpose, and it is correct. Guard (b)
(`paintedBackgroundOf` ~:78-89) throws on any ink with `a < 1.0`. `expectInkContrast` (~:275)
calls `paintedBackgroundOf` FIRST. So the exact case guard (a) exists for cannot be measured:
it is converted from a silent false-pass into a hard error, and the error text instructs the
caller to `Color.alphaBlend(ink, background)` using a background **only the throwing function
can produce**.

Guard (b)'s real job is narrower than its position implies: it is stopping a translucent ink's
own composited pixels from winning the histogram mode. That is about the **exclusion test
inside the histogram**, not about refusing the call. Resolve the surface before rejecting.

**Implementation shape — this is a planning PROPOSAL, verify it by exit code rather than
assuming it (`trd-prescriptions-need-verifying`). Deviate and say why if it does not hold.**

- Remove the `ink.a < 1.0` entry gate. Build the histogram exactly as today.
- Make the exclusion ink-aware:
  - **opaque ink** — `_isNear(entry, inkArgb)`, byte-identical to today. This path must not move.
  - **translucent ink** — an entry `e` is excluded when some OTHER entry `b` in the same
    histogram satisfies `_isNear(Color.alphaBlend(ink, Color(b)).toARGB32(), e)`: `e` is
    explainable as the ink painted over a colour that is ALSO present in this box, so it is the
    ink's own composited appearance and not the surface.
- **Keep the loud failure for the genuinely unmeasurable box.** For translucent ink, if every
  histogram entry is `_isNear` the leading entry — the box is ONE colour up to rasteriser
  rounding — throw. This is what keeps test 3 green, and it is the honest boundary: with one
  colour present there is nothing to distinguish fill from surface.
- The file header at :13-19 already carries the argument this relies on (a 20px glyph's box is
  mostly background, so its mode is reliable). Point the new comment at it rather than
  restating it.
- Replace guard (b)'s comment block with the above reasoning. Say explicitly that
  `expectInkContrast:276-277` is now LIVE and which test proves it.
- Update `measure_ink_guards_test.dart`'s header (~:10-16): it calls (a) and (b) "opposite
  failure modes on the same axis" and never notices they meet. Say where they meet and name the
  new case.

### verify

Capture RED first, against **unmodified** `measure_ink.dart`, and keep the `StateError` text
verbatim for the summary. Then GREEN. Plain redirect, read `$?` directly — **never pipe
`flutter test` into `tail`/`head`/`grep`**; a pipeline returns the LAST stage's status and a
failing run reports success (that happened this session: exit 0 with 38 failures).

```
flutter analyze test_support/ui_oracle/measure_ink.dart test/ui_oracle/measure_ink_guards_test.dart
flutter test -j 2 test/ui_oracle/ test/design/ test/widgets/ test/stories/ > /tmp/o.txt 2>&1; echo "EXIT=$?"
```

Always `-j 2`. This machine is memory-constrained and full-concurrency runs were killed twice today.

### done

The combined case goes RED on current code with the guard-(b) `StateError` (captured verbatim)
and GREEN after. The solid-translucent-fill case still throws. `EXIT=0` on the full four-directory
run. Both the RED and the GREEN output are in the summary verbatim.

---

## Task 2 — Rim the badge; fix the rail's geometry and its prose (HIGH-1, lower 1/2/4/7/8)

**Type:** `auto`, `tdd="true"`. Run after Task 1 (same instrument, and the suite must be green
between them so a failure has one cause).

### files

- `lib/src/widgets/eden_layout/eden_desktop_layout.dart`
- `lib/src/widgets/eden_layout/nav_selection_indicator.dart`
- `lib/src/widgets/eden_layout/nav_ink.dart`
- `lib/src/tokens/glyph_ink.dart`
- `test/ui_oracle/desktop_rail_contrast_test.dart`

### Test list (write it before the test code)

1. **The overlap is real, not asserted from a comment.** In the COLLAPSED rail with the selected
   row badged, the badge's global rect overlaps the selection pill's global rect. This is what
   makes the rim a requirement rather than a preference; assert it so a future geometry change
   that separates them makes the requirement visibly obsolete instead of silently so.
2. **The rim clears 3:1 against the pill's fill**, in both themes, COMPUTED from the pumped
   theme (`wcagContrast(rim, theme.colorScheme.primary)`), not asserted as a hex. *RED today —
   `_Badge`'s decoration has no border at all.*
3. **The rim is `edenNavOnFillInk`**, the same token its digit already uses — identity, so the
   test cannot drift onto some other near-black and still pass.
4. **lower-2 re-point** (below) — a re-introduced selected-row background moves the number.
5. **The EXPANDED branch's adjacency is MEASURED, not documented.** `_Badge` is consumed by both
   `_NavTile` branches, and expanded (~:1022) it sits on the rail's own fill, not on a pill —
   a distinct adjacency with distinct numbers. Mirror this file's existing
   `for (final bool collapsed in <bool>[false, true])` loop and, in the **expanded** branch, read
   the rail's own **painted** fill and assert the badge's boundary is carried:
   `max(wcagContrast(rim, railFill), wcagContrast(badgeFill, railFill)) >= 3.0`, both themes.
   *RED today in LIGHT* — with no rim there is only the fill, at **2.20:1**. GREEN after, at
   17.72:1. Dark is 7.61:1 before and after, carried by the fill either way.

   `max` is the honest shape, not a weakening: the claim is that the boundary is carried by the
   rim **or** the fill, and the matrix shows the carrier SWAPS by theme (light -> rim 17.72 with
   fill at 2.20; dark -> fill 7.61 with rim at 1.00, the same token as the rail). Put BOTH
   computed numbers in the `reason` and assert which one carried per theme, so a swap is visible
   rather than absorbed by the `max`.

   **PROPOSAL — settle by exit code.** Source the rail fill the same way test-list item 4 sources
   the pill's adjacent colour: `paintedBackgroundOf(selectedRowFinder, badgeFill)` over the keyed
   selected row, excluding the badge's fill so the mode is the row's background. In the EXPANDED
   branch that box is ~236x40 = 9440px against ~1200px of pill and ~360px of badge, so the rail
   fill wins comfortably — unlike the collapsed branch's ~5% margin, which is why this item is
   expanded-only. Verify that, and sample the row rather than the unselected sibling for the same
   reason lower-2 gives.

**This item is the point of the whole task, not an extra.** `must_haves` truth #2 says fixing one
adjacency and never measuring the others is how #58 produced this regression. A comment is not a
measurement: comments are the mechanism that has already gone stale four times in this chain
(the three sites in lower-4, plus `eden_appointment_list.dart:648`'s 5.14 where the real value is
6.09). The matrix below belongs in the comment AND in an assertion.

`test/ui_oracle/desktop_rail_contrast_test.dart` already pumps the collapsed rail with a badged
selected row (`_railItems` at :94-99, `_rail(collapsed)` at :110). Extend that file; do not
start a new one.

### action

**(a) THE CHOSEN FIX IS OPTION C. The decision is made — do not re-litigate it.** Give `_Badge`
(`eden_desktop_layout.dart` ~:1034) a rim of `edenNavOnFillInk` (`neutral[900]` `#18181B`), the
same token its digit already uses, so the badge's BOUNDARY carries its shape exactly as the
pill's own `onPrimaryContainer` rim does. **Keep the geometry and keep the `primary` fill.**

Re-derive and put in the comment:

| adjacency | light | dark |
|---|---|---|
| rim vs pill fill (collapsed, selected) | 8.04:1 | 7.61:1 |
| rim vs badge fill (both branches) | 8.04:1 | 7.61:1 |
| digit vs badge fill (unchanged) | 8.04:1 | 7.61:1 |

**And the adjacency the brief did not name, which you must measure because `_Badge` is consumed
by BOTH branches — expanded (~:1022) paints it on the rail's own fill, not on a pill:**

| adjacency (EXPANDED rail) | light | dark |
|---|---|---|
| rim vs rail fill | 17.72:1 | **1.00:1** — same token |
| badge fill vs rail fill | **2.20:1** | 7.61:1 |

Read that pair together before you write the comment. The rim is a **net win and never a
regression**: in light-expanded it replaces a 2.20:1 badge-vs-white boundary with 17.72:1; in
dark-expanded it is inert (identical to the rail) but harmless, because the badge fill already
carries its shape there at 7.61:1. Every adjacency is covered by the rim or the fill in every
branch and theme. **Say this explicitly in the comment, and pin it with test-list item 5 — this
whole PR chain's failure mode is fixing the adjacency you were looking at and never measuring the
others, and a comment is how that failure survives.** The rim is therefore unconditional, not
gated on `isSelected`. Name the test in the comment so the number and the assertion that computes
it are one edit apart.

Two rejected alternatives, recorded so the comment can say why:
- `colorScheme.error` fill (the mobile bar's token): **1.71:1** light / **1.62:1** dark against
  the pill. The 3.76:1 figure that makes `error` look right is `error` against the rail's WHITE
  FILL — the wrong surface.
- a rim of `onPrimaryContainer`: **3.38:1** light but only **2.00:1** dark. Fails dark.

**Rim width.** The pill's is 1.5px. `Border` on a `BoxDecoration` grows a `Container`, so on an
~18x16 badge 1.5px yields 21x19 and makes 3/19 = **15.8%** of the badge's height rim, against
the pill's 3/30 = **10%**. 1px yields 20x18 and 2/18 = **11.1%**, which holds the pill's
proportion. **Recommendation: 1px, with that derivation in the comment.** Your call, but state
what you chose and why, and confirm the grown badge still fits the collapsed row (56x44, badge
`Positioned(top: 6, right: 10)`).

**(b) `nav_ink.dart:29` may now be inaccurate.** It claims "the bar, the drawer tile, the sheet
row, the rail tile and all four badges must move together". The desktop `_Badge` is private to
`eden_desktop_layout.dart`; the three mobile badges (`eden_mobile_layout.dart` ~:592, ~:749,
~:874) are separate widgets and are NOT gaining a rim, because only the desktop rail overlaps
its badge with the pill. Check the claim against the code and correct it — the shared thing is
the INK, not the treatment.

**(c) `nav_selection_indicator.dart:38-41`** justifies keying by saying the widget "is
library-private ... so a test cannot reach it with `find.byType` without exporting it". Both
halves are wrong: Dart library-privacy needs a `_` prefix, and 57 test files already import
`package:eden_ui_flutter/src/...` directly. **The key is fine; the reason is not.** Keep the key,
replace the reason (the honest one is cardinality: keying the pill's own `Container` and not the
outer `Stack` is what makes `findsOneWidget` mean something).

**(d) lower-1, `_ExpandableNavHeader` ~:795-818.** The new pill paints over the chevron. Row:
left pad 4, chevron 18 -> x in [4,22]; gap 4 -> [22,26]; icon [26,46]; pill inset horizontal 10
-> x in [16,56]. The pill's left 6px sit inside the chevron's box and paint over it (Row paints
the chevron first). The comment at :803-805 transfers `_NavTile`'s VERTICAL clearance argument
and never checks the horizontal, where this row differs.

The invariant, which holds whatever the left padding is:
`pill_left = leftPad + chevronSize + gap - inset.left`, `chevron_right = leftPad + chevronSize`,
so **non-overlap requires `gap >= inset.left`** — the left padding cancels. Two levers only: the
gap, or the inset. Dropping the inset to <= 4 would make a 28x30 pill around a 20px glyph and
diverge from the 40x30 pill every other surface uses; **raising `_kExpandableChevronGap` (:684)
from 4 is the better lever.** 12 gives 2px of clearance and is already this file's spacing
vocabulary. State the measured clearance in the comment and replace the transferred vertical
argument with the horizontal one.

**(e) lower-2, `desktop_rail_contrast_test.dart` ~:259-284.** The rim assertion measures against
`paintedBackgroundOf(find.byIcon(Icons.insert_chart_outlined), rim)` — the UNSELECTED row's box.
1.4.11 asks for 3:1 against the ADJACENT colour, and a re-introduced selected-row background
would not move that number at all, because it is sampled from a different row.

Re-point it at the SELECTED row's own box, and exclude the **pill fill** rather than the rim so
the histogram mode is the row's background:

```dart
final Color pillFill = decoration.color!;
final Color rim = decoration.border!.top.color;
final Color adjacent = await paintedBackgroundOf(tester, selectedRowFinder, pillFill);
expect(wcagContrast(rim, adjacent), greaterThanOrEqualTo(3.0), reason: ...);
```

`selectedRowFinder` needs a handle: add `key: ValueKey<String>('eden-nav-row-${item.id}')` to
`_NavTile`'s outer `Container` in BOTH branches. That same key is what test-list item 1 uses for
the overlap assertion. **PROPOSAL — verify the mode actually resolves to the row background in
BOTH branches.** In the expanded rail the row box is ~236x40 against a 40x30 pill, comfortable;
in the collapsed rail it is 56x44 = 2464px against 1200px of pill, which is a **margin of ~5%**.
If that turns out too thin to trust, say so and measure the expanded branch only, with the
collapsed case covered by test-list item 2 (rim vs pill) — but do not leave a marginal
histogram silently deciding a conformance number.

**(f) lower-4, ratio inconsistency inside this PR.** Band-vs-rail-fill is `primary@0.1`
composited over the rail fill: light `#FBF6EE` vs `#FFFFFF` = 1.0759 -> **1.08**; dark `#2C251E`
vs `#18181B` = 1.1731 -> **1.17**. `nav_selection_indicator.dart:14`, `eden_desktop_layout.dart:769`
and `:908` say "1.07 / 1.18" — wrong in both directions. `glyph_ink.dart:25` and
`desktop_rail_contrast_test.dart:73-74` are already correct. Make them agree on 1.08 / 1.17.

**(g) lower-8, dead decorations** at ~:950-951, ~:989-990 and ~:793-794: `BoxDecoration(borderRadius: ...)`
with the colour removed paints nothing (`BoxDecoration` does not clip; `Container.clipBehavior`
defaults to `Clip.none`). Remove them, or justify in a comment. **Warning:** removing a
`BoxDecoration` removes a `DecoratedBox` from the tree, and `decorationInk` walks to the first
`RenderDecoratedBox` while `tester.widget<Container>(...)` resolves by type — re-run the full
four-directory suite, not just the rail file, and read the whole output.

### verify

```
flutter analyze lib/src/widgets/eden_layout/eden_desktop_layout.dart lib/src/widgets/eden_layout/nav_selection_indicator.dart lib/src/widgets/eden_layout/nav_ink.dart lib/src/tokens/glyph_ink.dart test/ui_oracle/desktop_rail_contrast_test.dart
flutter test -j 2 test/ui_oracle/ test/design/ test/widgets/ test/stories/ > /tmp/o.txt 2>&1; echo "EXIT=$?"
```

Plain redirect, read `$?` directly. **Never pipe `flutter test` into `tail`/`head`/`grep`.**
Always `-j 2`.

Goldens SKIP on this macOS worktree (`story_harness.dart:43`), so `EXIT=0` here says nothing
about them. That is expected and is Task 3's handoff, not a reason to re-bless.

### done

The rim assertion goes RED on current code (no border) and GREEN after, with both outputs
verbatim. **The expanded-branch assertion (test-list item 5) goes RED in LIGHT on current code at
2.20:1 and GREEN at 17.72:1** — capture that pair verbatim too; it is a real pre-existing defect
the rim closes, and it is the half the brief did not name. The full adjacency matrix is reproduced
in the `_Badge` comment from your own derivation AND asserted by item 5, not only documented.
`_ExpandableNavHeader`'s measured horizontal clearance is stated. The three "1.07 / 1.18" sites
read 1.08 / 1.17. `EXIT=0`.

---

## Task 3 — The story that would have caught it, plus the remaining findings (lower 3/5/6/9)

**Type:** `checkpoint:human-verify`, `tdd="true"`. Run after Task 2 — the handoff list of moving
baselines is only correct once the pixels have settled.

### files

- `lib/src/widgets/eden_layout/eden_desktop_layout.stories.dart`
- `lib/dev_app/registry/register_stories.g.dart` *(generated — never hand-edit)*
- `test/stories/_generated/desktop_layout_stories_test.dart` *(generated — never hand-edit)*
- `test/stories/golden_uniqueness_test.dart`
- `lib/src/widgets/eden_data_display/eden_appointment_list.dart`
- `lib/src/widgets/eden_data_display/eden_appointment_list.stories.dart`
- `test/ui_oracle/appointment_glyph_contrast_test.dart`
- `test/design/design_md_fresh_test.dart`
- `.planning/quick/10-rim-the-rail-badge-unblock-the-measure-i/deferred-items.md`

### Test list

1. `EdenGlyphInk.of(context)` under a LIGHT theme with a DARK **platform** brightness returns the
   LIGHT member. Asserting `set.brightness` as well as the colour, so the test names WHICH
   brightness was resolved rather than merely that some colour came back.
2. The two migrated call sites resolve through `EdenGlyphInk.of(context)`.
3. `design_md_fresh_test.dart`'s token partition sees a file in a SUBDIRECTORY of
   `lib/src/tokens/` — RED on a hand-made probe subdir file, GREEN after, probe reverted with
   `git checkout --` (never `git stash`).

### action

**SIZE, stated rather than hidden.** This task spans 9 files across 6 unrelated sub-fixes — a
story addition, a golden-gate mechanism, a token migration, two dartdoc corrections and a
recursive-scan fix. It is kept as one task because the brief caps this plan at 3 focused tasks,
and it is `checkpoint:human-verify` typed so it does not land unreviewed. **Commit the sub-fixes
SEPARATELY, not as one blob** — one commit per lettered item below, in order:

    (a) feat(stories): collapsed rail with badged selection
    (b) test(stories): name the awaiting CI baselines; relax the floor by exactly that count
    (c) refactor(tokens): migrate the two glyph sites to EdenGlyphInk.of(context) + its test
    (d)+(e) docs(stories): correct the fixture dartdoc and the disclosure claim
    (f) test(design): close the non-recursive token partition
    (g) docs: record the three out-of-scope findings

Per `executor-smaller-commits`: a reviewer should be able to read (b) without (c) in the diff.

**(a) THE STORY.** No story renders a collapsed rail, which is why CI is green on a 1.00:1
defect. `_collapsed` is only ever `widget.initiallyCollapsed` (:251/:263); there is no width
breakpoint, so `desktop-layout/narrow` at 720px still renders the EXPANDED rail — its own header
at :107-111 says so.

`_shell()` (:83-90) already selects `'orders'`, and `'orders'` already carries `badge: '3'`
(:42-46), so the selected row is already badged. Give `_shell` a `{bool collapsed = false}`
parameter threading `initiallyCollapsed:`, and add one story beside the existing two. Follow the
file's conventions exactly: `inputModality: EdenInputModality.pointer` (the desktop shell is a
pointer surface), a dartdoc saying what it pins and why the combination is the point, and a
sentence naming the defect it exists to catch.

Then regenerate through the normal path — **both** tools, in this order:

```
flutter test tool/gen_stories.dart
flutter test tool/gen_story_tests.dart
```

`registry_drift_test.dart` and `generated_freshness_test.dart` compare committed bytes against a
fresh generation, so a hand-edited generated file is a red CI job.

Optionally add the new id to `tool/story_coverage.dart`'s mapping. The `.story-coverage.json`
floor counts covered EXPORTS, and this widget is already covered, so the floor does not move —
do not touch it.

**(b) THE BASELINE GATE — FOUR CASES GO RED, NOT ONE.** Registering a story without re-blessing
makes `golden_uniqueness_test.dart` RED locally. **That is the gate working. Do not weaken it and
do not re-bless.** But patch it in the right place:

`_baselines()` (~:132-166) carries an **UNCONDITIONAL floor** at ~:156:
`if (files.length < expected.length) fail(...)`. `expectedBaselineNames()` is built from
`_expectedByName` (~:70-86), which reads `coLocatedStories()` — i.e. the regenerated
`register_stories.g.dart`. So registering the story grows `expected` by 2 while the on-disk PNG
count does not move, and that `fail()` fires **before** case 4's `missing`-list logic is ever
reached. `_baselines()` is called by **case 1 (:185), case 4 (:194), case 2 (:255) and case 3
(:294)** — all four go RED, not just case 4. Subtracting the allowance from case 4's `missing`
list alone leaves Task 3's stated `EXIT=0` unreachable.

Resolve it by NAMING the pair, in the shape `kPermittedIdenticalGoldens` (:99-124) already
establishes — shrink-only, with a mechanism the reader can check:

- Add `kAwaitingCIBaseline`: the two new file names plus a reason naming this handoff.
- **Relax the floor in `_baselines()` by exactly that count** —
  `files.length < expected.length - kAwaitingCIBaseline.length` or equivalent — and rewrite the
  `fail()` message to name the allowance, so a reader is not handed two numbers that do not
  reconcile. Relaxing by *exactly* the awaiting count is what preserves the floor's purpose: any
  OTHER short baseline still trips it. The comment at :150-154 ("a floor a reader has to be told
  is wrong by the message beside it is not a floor") is the standard the new message must meet.
- Case 4 subtracts it from `missing`, but ALSO asserts every name in it **is** in `expected` —
  so a typo or an orphan cannot hide there.
- Add a case asserting every name in `kAwaitingCIBaseline` is **currently absent from disk**.
  The moment CI commits the PNG the entry goes stale and the test goes RED telling you to delete
  it. **Self-retiring, not a permanent hole** — the same discipline as obj 23-11's counted
  ratchet.
- Cases 2 and 3 compare bytes among the files that ARE present and need no further change — but
  **prove that by running them**, not by reasoning about them.

**(c) lower-3, `lib/src/tokens/glyph_ink.dart`.** `EdenGlyphInk.of` / `EdenGlyphInkSet` have ZERO
callers and zero tests; the foot-gun they close is still open. Migrate the two real sites —
`eden_appointment_list.dart:278` and `:654` — to `EdenGlyphInk.of(context)`. Both already bind
`final ThemeData theme = Theme.of(context)` (:249, :637), so the migration is **pixel-identical**
and moves no golden. Confirm that rather than assuming it. Then add the test from the test list
above.

**(d) lower-5, `eden_appointment_list.stories.dart:184`.** The dartdoc still says "FIXTURE 01.
The ordinary answer: five rows". It is six now. The provenance header at :16-26 was updated;
this dartdoc — which is what a story reader actually sees — was not.

**(e) lower-6, `eden_appointment_list.stories.dart:16-26`.** The disclosure claims the synthetic
row "is what makes that provable". It is the row PLUS the new per-tone identity assertion
(`key: ValueKey('eden-appointment-status-dot-${tone.name}')`, `eden_appointment_list.dart:680`):
`pending` -> `neutral` -> `palette.neutralFg` clears 3:1 comfortably, so a **ratio-only**
assertion would still pass on the new order. Correct the claim to name both halves.
**Note:** the brief and `eden_appointment_list.dart:648` both quote 5.14:1 for `#52525B` on
`surfaceContainerHigh`, but `surfaceContainerHigh` light is `neutral[200]` `#E4E4E7`
(`eden_theme.dart:53`) and that pair computes to **6.09:1**. Re-derive it; if 5.14 does not
reproduce, that is a fourth instance of lower-4 and should be corrected in the same pass, not
copied forward. The claim's substance holds either way — both clear 3:1.

**(f) lower-9, `test/design/design_md_fresh_test.dart:133-134`.** `Directory.listSync()` is
non-recursive, so `lib/src/tokens/<subdir>/x.dart` escapes the partition in BOTH directions — it
is neither scanned nor on the named skip list, and the gate stays green. Close it
(`listSync(recursive: true)` with paths made relative to the repo root so the partition keys
still match). Prove it RED with a probe file in a subdirectory, then revert the probe with
`git checkout --`.

**(g) OUT OF SCOPE — record, do not fix.** No `gh`, so these cannot be filed as GitHub issues.
Write them to `deferred-items.md` in this quick directory, one paragraph each with file and line,
and repeat them in the summary so they reach the tracker when the PR is next touched:
1. `_DisclosedChildren`'s hairline strikes through a selected child's pill (pre-existing,
   uncovered state).
2. `decorationInk` takes `.first` where its siblings use `.single`.
3. `measure_ink.dart:213-218`'s `base == null` throw is unreachable.

### verify

```
flutter analyze lib/src/widgets/eden_layout/eden_desktop_layout.stories.dart lib/src/widgets/eden_data_display/eden_appointment_list.dart lib/src/widgets/eden_data_display/eden_appointment_list.stories.dart test/ui_oracle/appointment_glyph_contrast_test.dart test/design/design_md_fresh_test.dart test/stories/golden_uniqueness_test.dart
flutter test -j 2 test/ui_oracle/ test/design/ test/widgets/ test/stories/ > /tmp/o.txt 2>&1; echo "EXIT=$?"
```

Plain redirect, read `$?` directly. **Never pipe `flutter test` into `tail`/`head`/`grep`.**
Always `-j 2`.

Then prove the baseline gate specifically, and read the whole file rather than trusting the exit
code alone — all four cases must be PASS, not just case 4:

```
flutter test -j 2 test/stories/golden_uniqueness_test.dart > /tmp/g.txt 2>&1; echo "EXIT=$?"
```

Quote the four case lines verbatim in the summary.

**You CANNOT re-bless goldens here.** `story_harness.dart:43` sets
`kGoldenSkipReason = Platform.isLinux ? null : ...`, so every golden SKIPS on this macOS
worktree and a green local run says NOTHING about them. **Do NOT run `gh`; do NOT dispatch the
stories workflow; do NOT run `--update-goldens`.** Confirm the story is registered
(`registry_drift_test.dart`, `coverage_test.dart` case 8) and that its non-golden half
(`expectUiSane`) passes locally, then STOP at the handoff below.

### done

`EXIT=0` on the full four-directory run. **`golden_uniqueness_test.dart` cases 1, 2, 3 AND 4 all
pass** — name all four in the summary, because the `_baselines()` floor fails all of them and a
patch that only addressed case 4 would leave three red. The story is registered and its
`expectUiSane` half passes in both themes. The generated files are regenerated, not hand-edited.
The `kAwaitingCIBaseline` entry is present and self-retiring. The handoff below is in the summary.

---

## HANDOFF — baselines CI must generate. Do not attempt these locally.

**New, must be generated** (file names derived by `story_harness.dart:105`,
`story.id.replaceAll('/', '_')`) in `test/stories/_generated/goldens/ci/`:

- `desktop-layout_<new-story-id>.light.png`
- `desktop-layout_<new-story-id>.dark.png`

**Expected to MOVE — badge rim** (every committed baseline that renders a desktop-rail badge;
the rim is unconditional, so both `_NavTile` branches are affected):

- `desktop-layout_default.light.png`, `desktop-layout_default.dark.png` — `'orders'` badge `'3'`
- `desktop-layout_narrow.light.png`, `desktop-layout_narrow.dark.png` — same shell at 720px
- `nav-item_badge.light.png`, `nav-item_badge.dark.png` — `eden_nav_item.stories.dart:240`

**Expected to MOVE — `_ExpandableNavHeader` chevron gap** (only if you took the gap lever; the
header's icon and label shift right by the delta). These stories select `'home'`, not the
expandable row, so the pill is not painted in them and only the spacing moves:

- `nav-item_expandable-collapsed.light.png`, `nav-item_expandable-collapsed.dark.png`
- `nav-item_expandable-expanded.light.png`, `nav-item_expandable-expanded.dark.png`

**Expected NOT to move**, stated so an unexpected diff is a signal rather than noise:
all `mobile-layout_*` (the three mobile badges are separate widgets and gain no rim), all
`list-appointments_*` (the `EdenGlyphInk.of` migration is pixel-identical — `theme` is already
`Theme.of(context)`, and the other changes there are comments), all `error-refusal_*`, and
`nav-item_{default,selected,caption,divider,long-label}` (no badge, no expandable header).

Report any diff outside these lists as a finding, not as churn.
