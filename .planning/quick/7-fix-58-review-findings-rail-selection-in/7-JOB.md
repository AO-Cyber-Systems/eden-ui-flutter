---
objective: 7-fix-58-review-findings
trd: 7
type: standard
wave: 1
depends_on: []
autonomous: false
stack: flutter
files_modified:
  - lib/src/widgets/eden_layout/nav_selection_indicator.dart
  - lib/src/widgets/eden_layout/eden_desktop_layout.dart
  - lib/src/widgets/eden_layout/eden_mobile_layout.dart
  - lib/src/tokens/glyph_ink.dart
  - lib/src/widgets/eden_data_display/eden_appointment_list.dart
  - lib/src/widgets/eden_data_display/eden_appointment_list.stories.dart
  - test/ui_oracle/desktop_rail_contrast_test.dart
  - test/ui_oracle/appointment_glyph_contrast_test.dart
  - test/ui_oracle/measure_ink_guards_test.dart
  - test/design/design_md_fresh_test.dart
  - test_support/ui_oracle/measure_ink.dart
  - tool/gen_design_md.dart
  - DESIGN.md
must_haves:
  truths:
    - "A sighted user looking at the desktop rail — collapsed OR expanded, light OR dark — can tell which row is selected by something that measures at least 3:1 against the colour beside it. Today the only carrier is a 10%-primary band at 1.08:1 light / 1.17:1 dark, and in the collapsed rail there is no label and no weight change either, so nothing identifies the row at all."
    - "The desktop rail, the bottom bar, the drawer tile and the 'More' sheet row all say 'selected' the same way. One widget, four surfaces — a change to the indicator is a change everywhere."
    - "A glyph measured under an ancestor IconTheme that dims it is reported at the opacity it is PAINTED at, or the measurement refuses to answer. It never reports MORE opaque than the pixels."
    - "A translucent ink measured against a frame is compared against the surface it composites onto, not against its own painted pixels. A 10%-alpha band no longer reports ~1.0:1 against itself."
    - "A node whose paint bounds leave the view throws. It never silently reports the adjacent row's colour as its background."
    - "Reordering the appointment fixture so a non-confirmed row comes first makes the status-dot test FAIL. It cannot pass by measuring the wrong tone."
    - "A caller asking for a glyph tone from a BuildContext gets the tone for the brightness the THEME resolved, not the platform's."
    - "A new file in lib/src/tokens/ cannot land with the DESIGN.md freshness gate green and no documentation row. Either it is scanned, or it is on a named skip list with a reason."
  artifacts:
    - path: lib/src/widgets/eden_layout/nav_selection_indicator.dart
      what: "library-private EdenNavSelectionIndicator (pill + onPrimaryContainer rim), promoted out of eden_mobile_layout.dart, beside nav_ink.dart"
    - path: test/ui_oracle/desktop_rail_contrast_test.dart
      what: "adds the selection-CARRIER assertions the existing eight ink-vs-surface cases structurally cannot make"
    - path: test/ui_oracle/measure_ink_guards_test.dart
      what: "new: one regression test per measure_ink false-pass (2a IconTheme.opacity, 2b translucent ink, 2c off-frame node)"
    - path: lib/src/tokens/glyph_ink.dart
      what: "BuildContext-taking companions reading Theme.of(context).brightness; corrected rail doc row"
    - path: tool/gen_design_md.dart
      what: "token-file coverage is asserted, not assumed"
  key_links:
    - "eden_desktop_layout.dart _NavTile collapsed branch (~916) AND expanded branch (~948) both CONSUME EdenNavSelectionIndicator — not one of the two. The collapsed branch is the one with no label fallback."
    - "eden_mobile_layout.dart's three existing call sites (564, 704, 841) and three badge sites (571, 596, 711, 753, 848, 878) bind to the promoted widget with no behaviour change — the mobile goldens must come back byte-identical."
    - "appointment status dot: the resolved ink is asserted to BE EdenGlyphInk.success(brightness), so the test cannot drift onto neutralFg and still pass."
    - "design_md_fresh_test.dart asserts kScannedTokenFiles ∪ kUnscannedTokenFiles == glob(lib/src/tokens/*.dart)."
---

# Fix the /code-review findings on PR #58

Branch `fix/55-icon-contrast`, worktree `/Users/markemerson/Source/eden-ui-contrast`.
Work ONLY here. Do not push, do not run `gh`, do not open or merge a PR.

## Two prescriptions in the brief are red-on-a-correct-implementation. Read this first.

The brief asks Task 1's test for:

  (i)  selected ink vs UNSELECTED ink >= 3:1
  (ii) selection-indicator FILL vs the rail's own fill >= 3:1

Both fail against the fix they are meant to verify. The arithmetic:

  (i)  After adopting the shared indicator the selected glyph takes
       `edenNavOnFillInk` = `neutral[900]` #18181B — because it now sits ON the
       gold pill, where it measures 8.04:1 light / 7.61:1 dark. Unselected is
       unchanged at `onSurfaceVariant` #52525B. #18181B vs #52525B is **2.29:1**
       — the same number the review flags as the regression. The fix does not
       move it and is not supposed to.

  (ii) The pill fill is `colorScheme.primary`, gold #D4A853, on the rail's own
       fill (`Colors.white` light / `neutral[900]` dark — eden_desktop_layout
       .dart ~line 316). That is **2.20:1** light. The mobile ruling already
       states this outright (`_NavSelectionIndicator` dartdoc): *"in the light
       theme the gold fill never clears it (2.11:1 on the drawer, 2.20:1 on the
       bar). `onPrimaryContainer` does."*

So neither number can be a floor. Asserting either would make the suite red on
the correct implementation and green only on something the mobile shell already
rejected. **The state carrier is the RIM**, which is why the rim exists and why
its dartdoc calls it load-bearing: `onPrimaryContainer` measures 7.14:1 on the
light drawer (`surfaceContainerLow` #FAFAFA) and 15.21:1 on the dark one; on the
rail's own fill — pure `Colors.white` light, `neutral[900]` dark — it is
**7.45:1 light / 15.21:1 dark**. WCAG 1.4.11 asks 3:1 for the visual information
that identifies the state against the ADJACENT colour. Once the rim carries it
at 7.45:1, the ink delta is not load-bearing and does not have to clear
anything. The test computes these from the frame regardless; they are stated so
a reader can tell a wrong number from a moved surface.

The corrected assertions are in Task 1 below. The review's finding stands
unchanged: the rail's selected state is not identifiable today. Only the
instrument changes.

## Test list (behaviour cases, before any test code)

Task 1 — rail selection carrier (× light/dark × collapsed/expanded = 4 pumps):
  1. the selected row publishes exactly one selection indicator
  2. the indicator's RIM clears 3:1 against the rail's own painted fill
  3. the selected glyph clears 3:1 against the pill it is painted on
  4. the unselected glyph clears 3:1 against the rail's own fill (existing)
  5. NON-VACUITY: no rail row paints a `primary @ alpha 0.1` selection band —
     1.08:1 light / 1.17:1 dark against the rail's fill identifies nothing
  6. mobile parity: the three drawer/bar/sheet surfaces still render their
     indicator unchanged

Task 2 — oracle false-passes:
  7. an `Icon(color: X)` under `IconTheme(opacity: 0.5)` does not report X
  8. an `Icon(blendMode: ...)` does not report a colour it does not paint
  9. a translucent ink (alpha < 1) against a frame does not report ~1.0:1
  10. a node whose paintBounds leave the view throws
  11. reordering the appointment fixture to a non-confirmed first row FAILS

Task 3 — tokens/docs:
  12. `EdenGlyphInk.success(context)` under `ThemeMode.light` + dark platform
      brightness returns the LIGHT member
  13. a new file in `lib/src/tokens/` fails the freshness gate until classified

---

<task type="auto" tdd="true">
  <name>Promote the selection indicator to the rail, RED first</name>

  <files>
    lib/src/widgets/eden_layout/nav_selection_indicator.dart (CREATE)
    lib/src/widgets/eden_layout/eden_mobile_layout.dart (MODIFY)
    lib/src/widgets/eden_layout/eden_desktop_layout.dart (MODIFY)
    test/ui_oracle/desktop_rail_contrast_test.dart (MODIFY)
  </files>

  <action>
**Order matters. The test is written and demonstrated RED before the widget moves.**

STEP 1 — RED. Add the new cases to `test/ui_oracle/desktop_rail_contrast_test.dart`.
Keep all eight existing computed cases; they are correct as far as they look, and
the point of this task is that they look at the wrong axis. The file's header
already explains why each existing case exists — extend it with a paragraph
saying that every one of the eight measures ink-vs-SURFACE, that the axis that
regressed is what IDENTIFIES the selected row, and that a file which looks
straight at both colours and never compares them to the state carrier cannot see
that defect. Cite the numbers from the section above.

New cases, parameterised over `('light', ThemeMode.light)` / `('dark',
ThemeMode.dark)` × `collapsed: true` / `collapsed: false`:

  a. `expect(find.byKey(const ValueKey<String>('eden-nav-selection-indicator')),
     findsOneWidget)` — exact cardinality, not `findsWidgets`. One selected row,
     one indicator. An indicator on every row indicates nothing; an indicator on
     no row is the defect.

     BY KEY, NOT BY TYPE, and this is load-bearing for the RED. `find.byType`
     takes a `Type` LITERAL, so `find.byType(EdenNavSelectionIndicator)` against
     today's tree — where that class does not exist until Step 2 — is a Dart
     COMPILE ERROR, not a failing assertion. A compile error aborts the whole
     file: case (e) never runs, the existing eight computed cases never run, and
     nothing prints a ratio. That is a broken build wearing a RED's clothes, and
     this step's entire deliverable is the measured output. A key is a `String`
     and compiles against any tree. Step 2 attaches it to the widget.

     Same reasoning retires the privacy question: `EdenNavSelectionIndicator` is
     library-private and must NOT be exported from `eden_ui.dart` or
     `eden_layout_exports.dart` just to be findable. The key is how the test
     names it, exactly as `eden-appointment-status-dot` already works.
  b. the rim: read the rim colour off the resolved widget (or its
     `BoxDecoration.border.top.color`), measure it against the rail's own
     painted fill with `expectInkContrast`, floor 3.0. COMPUTE, do not pin.
  c. the selected glyph: `iconInk` against the pill it sits on, floor 3.0.
  d. the unselected glyph: unchanged, floor 3.0 (already present — keep).
  e. the non-vacuity guard: walk the rail's `BoxDecoration`s and assert none
     carries `colorScheme.primary.withValues(alpha: 0.1)` as a SELECTION band.
     Message must carry the computed ratio of that band against the rail fill
     (1.08:1 light / 1.17:1 dark) and say that a band at that ratio identifies
     nothing — so the reader learns why, not just that.

Run `flutter test test/ui_oracle/desktop_rail_contrast_test.dart` NOW, against
the unfixed tree. **The file must COMPILE and must FAIL.** Those are two
separate requirements and only the second one is evidence.

What RED must look like, so a real one is distinguishable from a build abort:

  - case (a) fails on all four pumps: `findsOneWidget` found ZERO — no widget
    in the rail carries `eden-nav-selection-indicator`, because no indicator
    exists there yet.
  - case (e) fails on all four pumps and PRINTS ITS RATIOS: the
    `primary @ alpha 0.1` band is live today at `eden_desktop_layout.dart:785`
    (`_ExpandableNavHeader`), `:927` (`_NavTile` collapsed) and `:956`
    (`_NavTile` expanded). Expect ~1.08:1 light and ~1.17:1 dark against the
    rail's own fill.
  - case (b) either fails or is unreachable — there is no rim to read.
  - cases (c) and (d) and the existing eight PASS. They measure ink against
    surface, which is correct today and is the whole point: the file looked
    straight at both colours and could not see the defect between them.

If instead the run reports a compile error, or if zero ratios are printed
anywhere, that is NOT the RED. Fix the test file and re-run before touching
product code. **Capture the actual output verbatim, with the measured ratios.**
A test that has only ever been seen green proves nothing about what it detects —
and one that has only ever been seen fail-to-compile proves less.

STEP 2 — GREEN. Create `lib/src/widgets/eden_layout/nav_selection_indicator.dart`.
Move `_NavSelectionIndicator` (eden_mobile_layout.dart:917) into it verbatim,
renamed `EdenNavSelectionIndicator` (library-private by not being exported from
`eden_ui.dart` / `eden_layout_exports.dart` — check both). Attach
`key: const ValueKey<String>('eden-nav-selection-indicator')` to the pill's
`Container`, with the comment `eden-appointment-status-dot` carries: the test
measures this by name, not by hunting for a rounded rect — and here also because
a private type cannot be named by `find.byType` from a test without exporting it
into every consumer's graph. Key the PILL, not the outer `Stack`: the stack is
present on unselected rows too (it wraps the glyph either way), so keying it
would match every row and case (a)'s cardinality check would assert nothing.
Carry the ENTIRE
dartdoc across; it is the ruling, not decoration. Amend its opening: it is now
ONE DEFINITION, FOUR SURFACES, matching `nav_ink.dart`'s header two files over —
the ink was unified across four surfaces and the indicator was not, and that gap
is how this regression got in. Say that.

`selectedGlyph` already delegates to `edenNavOnFillInk`; leave it.

Adopt in `_NavTile`, BOTH branches:

  - collapsed (~916): the tile is 44 high, full width, with a centred 20px glyph
    already inside a `Stack`. Replace `decoration: BoxDecoration(color:
    isSelected ? primary@0.1 : null, ...)` with the indicator wrapping the icon.
    Insets of 10 horizontal / 5 vertical give a 40x30 pill around the glyph —
    7px clear of the 44px row top and bottom, so it cannot collide with the
    adjacent row's tap target. VERIFY that clearance rather than trusting this
    number; the mobile bar's indicator overflowed its fixed 60px bar by 7px when
    it was sized by layout, which is why the pill is `Positioned` inside a
    `Clip.none` stack and takes no part in layout.
  - expanded (~948): same replacement. The mobile drawer tile (14px gap, 48
    high) is the closest precedent; the rail row is 40 high with 12px gap, so
    size the inset to the rail and state the clearance in the comment.

The selected glyph becomes `EdenNavSelectionIndicator.selectedGlyph`
(= `edenNavOnFillInk`, `neutral[900]`) in both branches, replacing
`theme.colorScheme.onSurface`. Rewrite the ~893-913 comment block: the claim
"The affordance is the band, which is unchanged and still brand gold" is now
false and was the defect — the band was 1.08:1 and never an affordance. State
what replaced it and why, with the rim's number.

The SELECTED LABEL stays `onSurface` (16.47:1 on the rail fill). Do not move it.

`_ExpandableNavHeader` (~line 766) carries the IDENTICAL `primary@0.1` band on
its own selected state. Leaving it makes the rail speak two selection languages
in one column — exactly what the indicator's dartdoc says a single widget exists
to prevent — and case (e) above will catch it. Adopt it there too, sizing the
inset to that row's 20px glyph after the chevron. If adoption there turns out to
be structurally impossible, STOP and say so rather than narrowing case (e).

Mobile: the three call sites (564, 704, 841) and the badge references (571, 596,
711, 753, 848, 878) rebind to the promoted type. No behaviour change — this is a
rename and a file move.

STEP 3 — capture GREEN. Re-run the file. Record both outputs in the summary.
  </action>

  <verify>
    flutter test test/ui_oracle/desktop_rail_contrast_test.dart   # RED at step 1, GREEN at step 3 — both captured verbatim
    flutter test test/ui_oracle/                                  # the oracle suite, incl. mobile_shell_open_surfaces_test.dart
    flutter analyze --no-fatal-infos
    flutter test                                                  # full suite, ~4778 tests

    Story goldens SKIP on this workstation (darwin) — `kGoldenSkipReason` is
    non-null off Linux (story_harness.dart:43). They are reported as skips, not
    passes. A green local `flutter test` therefore says NOTHING about the
    baselines this task moves. See the checkpoint below; do not read the skip as
    a pass.
  </verify>

  <done>
    RED output captured with its measured ratios, GREEN output captured, both in
    the summary. The rail's selected row — collapsed and expanded, both themes —
    publishes exactly one indicator whose rim clears 3:1 against the rail's own
    fill. No rail row paints a primary@0.1 selection band. The three mobile
    surfaces are unchanged in behaviour. `flutter analyze` clean; full suite
    green modulo the skipped goldens.
  </done>

  <recovery>
    If the collapsed pill overflows the 44px row or trips `expectUiSane`'s
    geometry phase, shrink the vertical inset before touching the row height —
    the row height is a tap-target decision (`androidTapTargetGuideline`), not a
    styling one, and the mobile drawer had to go 44 -> 48 for exactly that.
    If promoting the widget breaks a mobile golden, that is a real finding, not
    noise: the move is supposed to be byte-identical there. Stop and report it.
  </recovery>
</task>

<task type="auto" tdd="true">
  <name>Close the four oracle false-passes</name>

  <files>
    test_support/ui_oracle/measure_ink.dart (MODIFY)
    test/ui_oracle/measure_ink_guards_test.dart (CREATE)
    test/ui_oracle/appointment_glyph_contrast_test.dart (MODIFY)
    lib/src/widgets/eden_data_display/eden_appointment_list.dart (MODIFY)
    lib/src/widgets/eden_data_display/eden_appointment_list.stories.dart (MODIFY, fixture order only)
  </files>

  <action>
Each of (a)-(c) gets its regression test written FIRST, in the new
`test/ui_oracle/measure_ink_guards_test.dart`, and demonstrated red. These are
tests OF THE INSTRUMENT — the file's header should say that plainly, because an
instrument nobody tests is how three of these survived.

**(a) `iconInk` (measure_ink.dart:133) over-reports a dimmed glyph.**
`Icon.build` (flutter/lib/src/widgets/icon.dart:293-297) applies
`iconTheme.opacity` to the colour EVEN WHEN `Icon.color` is set explicitly, and
swaps to a `foreground` Paint when `blendMode` is set. `iconInk` returns
`icon.color` verbatim. Under an ancestor `IconTheme(opacity: <1)` — which
Material installs for disabled and secondary icon regions — the glyph is
measured MORE opaque than it is painted, the ratio reads HIGH, and the assertion
PASSES ON A FAILING GLYPH. That is the worst failure mode a conformance
instrument has: it is not blind, it is confidently wrong.

Resolve it the way Flutter does — apply `IconTheme.of(element).opacity` to the
declared colour — or THROW when `opacity != 1.0` / `blendMode != null`. Prefer
resolving for opacity (it is a closed-form transform Flutter already documents)
and throwing for `blendMode` (the painted result depends on the destination
pixels, so there is no single "ink" to return, and a check that answers anyway
is `check-whose-failure-is-its-success`). Whichever you pick, the reason goes in
the dartdoc with the framework line reference.

Test: `Icon(Icons.home, color: <opaque X>)` wrapped in `IconTheme(opacity: 0.5)`
— `iconInk` must not return X.

**(b) `_isNear` (measure_ink.dart:215) compares alpha.**
Note this is a DIFFERENT site from case (c) below: (b) is the exclusion helper
at the tail of the file, called from the histogram loop at :113; (c) is the
sampling loop's bounds arithmetic at :95-99. Two fixes, two places — do not
conflate them.
It walks all four bytes including the alpha channel, so a translucent ink
(`successBg`/`warningBg` are `0x1A` alpha; the rail band is `primary` at 0.1)
never matches any opaque frame pixel. The glyph's own composited pixels stay in
the histogram and win the mode, and `expectInkContrast` (~line 201) then reports
~1.0:1 against the wrong colour — a spurious FAILURE pointing at the wrong
thing. Note the asymmetry with (a): this one cries wolf, (a) stays silent. Both
are wrong; only one is dangerous.

Fix: blend the ink over the candidate before the near-test, or reject `ink.a <
1.0` at the entry point with a message naming the composite the caller should
pass instead. `expectInkContrast` already does `Color.alphaBlend(ink, surface)`
AFTER the background is found — the exclusion needs the same treatment BEFORE.

Test: a translucent ink over a known solid surface must report that surface, not
~1.0:1 against itself.

**(c) the sampling loop (measure_ink.dart:95-99) never clamps `x`.**
It guards `offset < 0` and
`offset + 3 >= lengthInBytes` — both of which are row-agnostic — but never
bounds `x` to `[0, width)`. A node whose `paintBounds` extend past the left or
right edge of the view silently reads pixels from the ADJACENT ROW, and the
histogram mode can be an unrelated region's colour. Throw on an off-frame node,
with the node's rect and the view's in the message. Do not clamp-and-continue:
a partially-measured node answers a number the caller would treat as a fact.

Test: a node deliberately positioned past the view edge must throw.

**(d) `appointment_glyph_contrast_test.dart:72` measures whichever dot is first.**
It uses `findsWidgets` (>= 1) then `dot.first`, but
`ValueKey('eden-appointment-status-dot')` is attached to EVERY dot regardless of
tone (eden_appointment_list.dart:670) and the switch at :651 has two arms —
`confirmed` -> `EdenGlyphInk.success`, `neutral` -> `palette.neutralFg`. All six
story fixtures are currently `status: 'confirmed'`, so it happens to measure the
changed ink. Reorder the fixture to put a non-confirmed appointment first and
the test measures `neutralFg` (5.14:1), PASSES, and reports nothing while the
confirmed dot regresses to 2.00:1. It is green by fixture accident.

Two changes, both needed:
  - Key the two tones distinctly at the source
    (`eden-appointment-status-dot-confirmed` / `-neutral`), with the comment
    saying why one key for two tones made the assertion fixture-ordered.
  - In the test, find the confirmed dot by its own key with exact cardinality
    (not `findsWidgets` + `.first`), and assert the resolved ink EQUALS
    `EdenGlyphInk.success(brightness)` alongside the computed ratio. The ratio
    alone cannot tell you which tone it measured; the identity alone is the
    spelling check this file exists to avoid. Both, together.

PROOF, and it is the deliverable: add a non-confirmed appointment to the
`list-appointments/populated` fixture and put it FIRST. Under the old test that
ordering is green; under the new one the confirmed dot is still found by key and
still asserted. Then temporarily revert the test to `findsWidgets` + `.first`
and show it goes green while measuring `neutralFg` — that is the demonstration —
and restore. Record it.

Changing the fixture moves `list-appointments/{populated,narrow}` goldens. See
the checkpoint.
  </action>

  <verify>
    flutter test test/ui_oracle/measure_ink_guards_test.dart        # red per case first, then green
    flutter test test/ui_oracle/appointment_glyph_contrast_test.dart
    flutter test test/ui_oracle/                                    # every existing consumer of measure_ink still passes
    flutter analyze --no-fatal-infos
    flutter test
  </verify>

  <done>
    Four defects closed, three with a regression test that was demonstrated red,
    and the fourth with a demonstration that the old assertion goes green on a
    reordered fixture while the new one does not. Every existing `measure_ink`
    consumer still passes — if tightening (a) or (b) turns an existing
    assertion red, that assertion was passing on a bad measurement and the
    finding is reported, not suppressed.
  </done>

  <recovery>
    If fixing (a) or (b) makes an existing contrast test red, do NOT loosen the
    guard to fit. Report which assertion, which ratio it reported before and
    after, and stop. A guard relaxed to keep a suite green is how the reported
    number stops meaning anything.
  </recovery>
</task>

<task type="auto">
  <name>Token and documentation corrections</name>

  <files>
    lib/src/tokens/glyph_ink.dart (MODIFY)
    lib/src/widgets/eden_data_display/eden_appointment_list.dart (MODIFY, 2 call sites)
    lib/src/widgets/eden_layout/eden_desktop_layout.dart (MODIFY, line 766)
    tool/gen_design_md.dart (MODIFY)
    test/design/design_md_fresh_test.dart (MODIFY)
    DESIGN.md (MODIFY, generated block and/or header prose)
  </files>

  <action>
**(a) `glyph_ink.dart:60` — the API invites the wrong brightness.**
Every member takes a bare `Brightness`. A caller reaching for
`MediaQuery.platformBrightnessOf(context)` — natural-looking, and WRONG whenever
the app pins `ThemeMode.light`/`.dark` or a subtree overrides `Theme` — gets the
dark member on a light surface: `emerald[500]` at 2.00:1. That is the exact
defect this PR fixes, reachable through the API the fix introduced, with no test
or lint able to see it.

Add `BuildContext`-taking companions reading `Theme.of(context).brightness`.
Both current call sites (`eden_appointment_list.dart:278` and `:653`) already
have the context — move them. Keep the `Brightness` form: the tests need to ask
for a specific member without pumping a theme, and the token doc's own table is
stated per brightness. Say that in the dartdoc, so the next reader does not
delete it as redundant.

Add a test: under `ThemeMode.light` with the platform brightness forced dark,
`EdenGlyphInk.success(context)` returns `emerald[700]`, not `emerald[500]`.
This is the only genuinely-new behaviour in this task and it is cheap to pin.

**(b) `glyph_ink.dart:13` — the rail row's hex and ratio disagree.**
The table labels it `primary #D4A853` and gives 2.05:1 light / 6.49:1 dark, but
6.49:1 is computed from `gold[400]` #E59A3C — the DARK theme's
`colorScheme.primary` — not from #D4A853, which is 6.85:1 on the dark band. The
row reads as one colour measured twice and is two colours measured once each.
Split the hex per brightness.

While editing: the surrounding prose describes the selected rail icon as sitting
on a "10% band". After Task 1 that band is gone. Update it to name the
indicator, or the token's founding example documents a surface that no longer
exists.

**(c) `eden_desktop_layout.dart:766` — stale ratios.** Says "16.49:1 light,
13.72:1 dark"; computed values are 16.4671 and 13.7403. The newer comment at
~897 says 16.47/13.74 and points readers at the stale one ("See `_NavTile` for
the measurement"), so the correct number cites the incorrect one. Correct line
766. (Task 1 rewrites the ~897 block; make sure these two land consistent.)

**(d) `tool/gen_design_md.dart:359` — the header's promise is false.**
DESIGN.md:4-5 says the reference is "generated straight from
`lib/src/tokens/*.dart` so it can never quietly drift from the code". The
generator scans a HARDCODED four-file list. `lib/src/tokens/glyph_ink.dart` is
invisible to it, so a new public token file landed with `design_md_fresh_test`
green and no documentation row — the exact drift the sentence rules out.

DO NOT make the generator glob `lib/src/tokens/*.dart`. It is not tractable and
the file says why: the schema is LOCKED to four groups (`TokenGroup` is a closed
enum of 4; `extractTokens` switches exhaustively on it), a declaration matching
no accepted or named-skip shape raises `UnrecognizedTokenDeclaration`, and
`durations.dart`, `shadows.dart` and `springs.dart` are deliberately unscanned
because they hold structured values. A glob would throw on four of the eight
files on the first run. `EdenGlyphInk`'s members are
`static Color success(Brightness)` — methods, not `static const Color` — so no
existing pattern matches them either, and inventing a fifth group to document
two-member brightness pairs as a scalar table is a bigger change than the defect.

Instead make the COVERAGE asserted, which is the generator's own stated
philosophy ("a stale/unnoticed token is exactly the bug row 1a-10 removes")
applied one level up. Add, beside `kScannedTokenFiles`:

    /// Token files deliberately NOT generated, each with the reason. Paired
    /// with kScannedTokenFiles this is a CLOSED partition of
    /// lib/src/tokens/*.dart, asserted by design_md_fresh_test — so a new
    /// token file cannot land documented-by-nobody with the gate green, which
    /// is how glyph_ink.dart did (#58 review).
    const Map<String, String> kUnscannedTokenFiles = {
      'lib/src/tokens/durations.dart': '...',
      'lib/src/tokens/shadows.dart':   'structured (non-scalar) values',
      'lib/src/tokens/springs.dart':   'structured (non-scalar) values',
      'lib/src/tokens/glyph_ink.dart': 'brightness-PAIRED semantic glyph tones;
          each member is a function of Brightness, not a scalar, so the locked
          four-group scalar schema cannot render it. Documented in prose at
          DESIGN.md#..., not in the generated table.',
    };

and a new case in `design_md_fresh_test.dart`: the union of the two collections
equals `Directory('lib/src/tokens').listSync()` filtered to `.dart`, with a
failure message naming the unclassified file and telling the reader to add it to
one list or the other. Follow the file's existing `_repoRoot()` resolution — it
resolves from `Directory.current` on purpose
(`edenbiz-website-tests-gated-on-absolute-paths`).

Then either add the glyph-ink prose row to DESIGN.md's HAND-WRITTEN section (and
note it in the "Not generated:" line at DESIGN.md:95, which today names only
shadows and springs), or narrow the DESIGN.md:4-5 promise to "the colour, type,
spacing and radii tables are generated from `lib/src/tokens/`; the remaining
token files are listed at line 95". Prefer doing both — the promise becomes true
AND the token gets its row. If DESIGN.md's generated block changes at all,
regenerate with `flutter test tool/gen_design_md.dart` and commit DESIGN.md with
the source in one commit, per DESIGN.md:101-104.
  </action>

  <verify>
    flutter test test/design/design_md_fresh_test.dart
    flutter test tool/gen_design_md.dart      # regenerates; only if the block changed
    flutter test test/tokens/
    flutter analyze --no-fatal-infos
    flutter test

    NON-VACUITY for (d): drop an empty `lib/src/tokens/_probe.dart` and confirm
    `design_md_fresh_test` FAILS naming it; delete it and confirm green. A
    coverage gate nobody has seen fail is a coverage gate nobody has tested.
  </verify>

  <done>
    `EdenGlyphInk` has context-taking members, both call sites use them, and the
    wrong-brightness path is pinned by a test. The rail doc row names one hex
    per brightness. Line 766 agrees with line ~897. A new file in
    `lib/src/tokens/` fails the freshness gate until it is classified —
    demonstrated, not asserted. DESIGN.md's header promise is true as written.
  </done>
</task>

---

## Checkpoint — goldens cannot be re-blessed in this worktree

**This is a hard stop, not a warning.** Tasks 1 and 2 both move story baselines,
and the constraints forbid pushing and forbid `gh`.

The repo has exactly one golden-writing path (`.github/workflows/ci.yml`, the
`stories` job): `flutter test test/stories/_generated/ --update-goldens`, gated
on `github.event_name == 'workflow_dispatch' && inputs.update_goldens`, on
ubuntu-latest at the pinned Flutter 3.47.5. README:30 and the job's own comment
both say never to bless from a workstation — local and CI engines rasterise
differently (#32). Off Linux the emitted golden tests carry
`skip: kGoldenSkipReason`, so a local `flutter test` reports them as SKIPS. A
green local suite is not evidence about the baselines.

So: complete all three tasks and commit them. Then STOP and hand back. The
re-bless needs a push and a `gh workflow run ... -f update_goldens=true`, both
out of scope here, and it lands in its OWN commit with the changed-pixel
analysis — the shape b506f39 used and the standard to match.

Baselines expected to move (the executor enumerates and classifies against the
CI log; this is the prediction, not the finding):

  desktop-layout/{default,narrow}        light+dark   pill + rim replace the
                                                      band; selected glyph
                                                      #18181B light and dark
  nav-item/{badge,caption,default,divider,expandable-collapsed,
            expandable-expanded,long-label,selected}  light+dark
  list-appointments/{populated,narrow}   light+dark   fixture reorder (Task 2d)
                                                      — ORDER change, so the
                                                      diff is NOT confined to
                                                      one glyph box, unlike
                                                      b506f39's
  mobile-layout/*                        MUST be byte-identical. Task 1 is a
                                         rename and a file move on that side.
                                         A moved mobile baseline is a finding.

State it in the summary as a deferred, named handoff. Do not describe the local
skip as a pass.

## Noted, filed separately — not fixed here

- **`eden_appointment_list.dart:651` mixes profile-blind and profile-aware ink.**
  `EdenGlyphInk.success` does not follow `EdenStatusPalette`, but its sibling
  `palette.neutralFg` does. Under `govFederal` the confirmed dot leaves USWDS
  `#00A91C` for `emerald[700]` while the neutral dot beside it still follows the
  profile — two colour authorities in one switch statement. No non-commercial
  profile has ANY test coverage. `glyph_ink.dart`'s dartdoc already records the
  tradeoff (govFederal's own `successFg` is 2.47:1 and its `warningFg` 1.59:1 on
  these light surfaces, so following the profile would ship a floor two profiles
  fail). Explicitly out of scope. File as an issue.

- **The rail's 10%-primary band appears in a third place.** Task 1 covers
  `_NavTile`'s two branches and `_ExpandableNavHeader`. If anything else in the
  rail paints `primary @ 0.1` as a selection cue, Task 1's case (e) will name it.
  `_UserTile`'s 15%-primary avatar circle is NOT a selection cue and is out of
  scope.

## Commits

Small and separable, per `executor-smaller-commits`:

  1. `test(a11y): measure what identifies the selected rail row, not just its ink`  (Task 1 RED)
  2. `fix(a11y): the desktop rail takes the shared selection indicator`             (Task 1 GREEN)
  3. `fix(oracle): close four false-passes in measure_ink and the dot assertion`    (Task 2)
  4. `fix(tokens): context-taking glyph ink, corrected ratios, asserted token coverage` (Task 3)

Do not put a golden re-bless in any of them. Watch the commit-message footguns:
no backticks or globs in an unquoted message, and no skip-ci marker in prose.
