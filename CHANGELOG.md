# Changelog

## 2.2.0

Password-manager autofill and universal copy/paste, plus a UI correctness oracle, a co-located
story catalogue and a web runtime probe. Consumer setup guide for the first half:
[docs/autofill-and-selection.md](docs/autofill-and-selection.md).

**2.2.0, not 2.1.0.** `pubspec.yaml` read `2.0.0` up to this commit, but the tag `v2.1.0` already
exists (at `e719691`, whose pubspec also reads `2.0.0` — so `release.yml`, which derives the tag
from that field, cannot have cut it). `2.2.0` is the next value that is monotonic against the
highest existing tag. The deprecations below make this a minor, not a patch.

> **⚠️ Read "Known issues — not yet release-ready" at the end of this section before pinning.**
> The accessibility oracle added here currently fails on the shell this package ships, and those
> failures are real defects, not test noise.

### Added — UI correctness oracle, story catalogue, probe

- **`package:eden_ui_flutter/testing.dart`** — `Future<void> expectUiSane(WidgetTester tester,
  {EdenInputModality inputModality, Set<String> allowOverlap})`. One `await` after a screen test's
  final pump checks: escaped exceptions (including overflow), viewport containment, sibling
  semantics-rect disjointness, one tap action per control, the accessibility guidelines
  (tap-target size, tappable label) and **painted-text contrast** (WCAG 1.4.3 — see Changed).
  Also exports `SemanticsGeometryNode`,
  `globalRectOf`, `identifiedNodes`, `rectsOverlap`. Deliberately **not** exported from
  `eden_ui.dart` — it imports `package:flutter_test`, so it must never reach a consumer's
  production graph. Import it from `test/` only.
- **`EdenInputModality`** (`pointer` / `touch`), exported from **`eden_ui.dart`** as well as
  `testing.dart`, plus **`EdenStory.inputModality`**. The tap-target floor `expectUiSane` asserts
  depends on what the surface is DRIVEN WITH: `pointer` asserts WCAG 2.5.8 Target Size (Minimum),
  **24x24**; `touch` asserts `androidTapTargetGuideline` (48dp) **and** `iOSTapTargetGuideline`
  (44pt). 48dp and 44pt are touch guidance — on a pointer surface they are not a stricter
  standard, they are the wrong one, and the only pressure that creates is to weaken the oracle.
  This is a **state-conditional rule, not a suppression mechanism**: there is no value that waives
  the check, only a declaration of what input the surface takes, and both paths assert a real
  floor. The parameter is **optional and defaults to `touch`** (the stricter floor, per this
  package's additive-only contract), but every in-repo call site names it explicitly and
  `tool/gen_story_tests.dart` emits each story's declared modality verbatim into the generated
  test, so the standard a surface is held to is readable at the assertion. The enum lives in
  `lib/src/a11y/` rather than `lib/testing/` precisely so production code can declare it without
  dragging `package:flutter_test` into a release graph.
- **`package:eden_ui_flutter/probe.dart`** — `EdenProbe`, `kEdenProbe`, `EdenProbeScope`. A web
  JS-interop bridge exposing `window.__edenProbe.{find,tree,settled,state}`. Compiled in ONLY under
  `--dart-define=EDEN_PROBE=true`; tree-shaken out otherwise, enforced by the `probe-guard` CI job
  (`tool/probe_guard.sh`). Also not exported from `eden_ui.dart`, so `dart:js_interop` never reaches
  a consumer that does not ask for it.
- **Composition slots on the layout shells** — `itemBuilder` and `sectionBuilder` on both
  `EdenDesktopLayout` and `EdenMobileLayout`, with the typedefs `EdenNavItemBuilder`,
  `EdenNavSectionBuilder` and the value type `EdenNavItemState`. Both are
  `Widget? Function(...)`: **returning `null` declines the row**, and the built-in renderer runs
  instead. That is what makes them additive — a consumer passing no builders gets byte-identical
  rendering, and the existing layout tests pass unmodified. Existing flags (`expandable`,
  `isCaption`, `isDivider`, `badge`) still render through the default builder.
- **Story catalogue as a contract** — co-located `<widget>.stories.dart` files, a generated registry
  (`tool/gen_stories.dart`) with a drift test that fails when a story is added without
  regenerating, generated per-story golden (light + dark) and `expectUiSane` tests
  (`tool/gen_story_tests.dart`), and a coverage floor (`tool/story_coverage.dart`,
  `.story-coverage.json`).
- **`design/patterns/`** — ten interaction-pattern documents (navigation shell, disclosure group,
  section caption, list-detail, studio three-pane, density breakpoints, bulk-action bar,
  confirm-destructive dialog, form validation, empty/error/outage/loading states), each with seven
  fixed headings, against a closed `must_not` vocabulary at `design/must_not_vocabulary.json`.
- **`DESIGN.md`** — token tables generated from `lib/src/tokens/` by `tool/gen_design_md.dart` and
  CI-diffed, so the document cannot drift from the tokens.
- **`custom_lint` rules** (`lints/`) — `no_raw_color`, `text_style_needs_family`,
  `no_magic_spacing`. Shipped **scoped to `lib/src/widgets/eden_layout/**`**; the unscoped
  repo-wide debt is measured by `lints/bin/measure_debt.dart` and is not yet enforced.

### Changed

- **Contrast is measured from the widget tree, not the semantics tree.** `expectUiSane` no longer
  runs Flutter's `textContrastGuideline`; it measures every `Text` and `EditableText` itself,
  taking the INK from the resolved `TextStyle` and the SURFACE from the rendered pixels. The stock
  rule was replaced for two independent reasons, both measured on this package's own shell:
  - **It cannot see badge text at all.** It resolves a node's text with
    `find.text(<the node's label>)`, so a nav badge — which sits inside the row's
    `ExcludeSemantics` and is therefore nobody's label — was never contrast-checked anywhere in
    this library. Three badge defects on this shell were found by hand for exactly that reason.
    Publishing badge text into the semantics tree is not an alternative: `ExcludeSemantics` does
    not descend, a sibling node would put two click targets on one row, and folding the badge into
    the row's label makes the guideline look for a string no `Text` carries.
  - **It misreads small text.** It derives BOTH colours from a pixel histogram, and a 10px badge
    digit or an 11px nav label rasterises to antialiased stroke shades with no full-coverage core,
    so it reports a blend as the ink: the mobile bar's labels came back at 2.20–4.38:1 against a
    colour pair of 4.83:1, and the rail's badge at 2.52:1 against 8.04:1.

  The replacement computes the identical 1.16:1 on the oracle's own dark-on-dark fixture, which is
  what pins the two rules against each other. Text behind a modal barrier (`BlockSemantics` — an
  open drawer or a modal sheet) and text inside a disabled control are exempt, as they were under
  the stock rule and as WCAG 1.4.3 allows. **Known limit:** `Text.rich` spans are not measured.
- **Four WCAG 1.4.3 text-contrast defects fixed in the shells**, all of them shipped, all of them
  green on a 4778-test suite because no instrument in the suite could see them:
  - `EdenMobileLayout`'s **bottom-bar badge** was `Colors.white` on `colorScheme.error` at
    fontSize 9 — **3.76:1 in both themes** (`error` is `#EF4444` in each). It now takes the same
    near-black ink the drawer's and the sheet's badges take: **4.71:1**. The FILL is deliberately
    unchanged — darkening it to `red[700]` would clear 1.4.3 for white text and then fail 1.4.11
    against the dark theme's bar (2.74:1, where `colorScheme.error` is 4.71:1), and
    `colorScheme.error` is a semantic token two apps read.
  - `EdenDesktopLayout`'s **rail badge** was `Colors.white` on `colorScheme.primary` at fontSize
    10 — **2.20:1 light, 2.33:1 dark**, the identical defect the mobile drawer and "More" sheet
    carried. Now **8.04:1 / 7.61:1**.
  - The **rail's selected row label** was brand gold on the selected row's 10%-primary band at
    fontSize 13 — **2.05:1 in the light theme** (6.47:1 dark, which is why it survived a
    dark-theme reading). The brand moves off the text, exactly as it did on the bar and in the
    drawer: **16.49:1 / 13.72:1**.
  - The **sidebar user tile's initials** were brand gold on a 15%-primary circle — **1.98:1
    light**. Now `onSurface`: **15.89:1 / 12.45:1**. The person-glyph fallback moves with them; at
    1.98:1 it also failed 1.4.11's 3:1 for a meaningful icon.
- **The top-bar search field no longer paints over its own pill.** `_TopBar`'s `TextField`
  inherited `EdenTheme`'s `inputDecorationTheme` (`filled: true`, white in light / `neutral[800]`
  in dark) and drew an opaque rectangle on top of the `surfaceContainerHighest` pill the enclosing
  `Container` draws — and, because `_RenderDecoration` sizes that fill from the decorator's
  content height rather than from the 36px it is constrained to, the pill showed only as a ~16px
  band below the text. `filled: false` now. With the overpaint gone the hint sits on the pill's
  own fill, where `onSurfaceVariant` is **3.81:1** at 13px, so the hint moves to
  `colorScheme.secondary`: **6.09:1 light, 5.81:1 dark** (dark is unchanged — both roles are
  `neutral[400]` there). See known issue 6 for the pixel measurements.
- **One definition for the ink that sits on a coloured nav fill**
  (`lib/src/widgets/eden_layout/nav_ink.dart`, library-private). The bar, the drawer, the "More"
  sheet and the rail are four renderings of one nav row and had four separate `Colors.white`
  literals on coloured pills. They now share one value, so the next change to it is a change
  everywhere.
- **The sidebar collapse toggle has a real 44x44 hit area.** `EdenDesktopLayout`'s "Collapse
  sidebar" control was a bare `Icon(Icons.menu_open, size: 20)` inside a `GestureDetector`, giving
  a **20x20 hit target** — under even WCAG 2.5.8 Target Size (Minimum)'s 24x24 pointer floor. The
  glyph is unchanged at 20px; the box around it is now 44x44 with `HitTestBehavior.opaque` (the
  collapsed variant of the same header already had `opaque`; the expanded one did not, and without
  it the enlarged box is decoration — the semantics rect claims 44 while the real target stays 20).
  **This moves the sidebar header's geometry**, which is one more reason the golden baselines must
  not be blessed yet.
- **`selectableBody` now defaults to `false`** on `EdenDesktopLayout` and `EdenMobileLayout`.
  A `SelectionArea` over a subtree containing a Navigator asserts on deep-link to a nested route:
  `_compareScreenOrder` calls `getTransformTo` on a covered page that has never been laid out
  (flutter#151536; the fix, flutter#184900, is unmerged). Every go_router shell app has a
  Navigator in `body`. Measured in aodex#611: six routing tests red, and aodex took the
  `selectableBody: false` opt-out by hand — it can now drop that opt-out. eden-ui-flutter#33.

  **Migration — apps that want the old behaviour pass `selectableBody: true`.** That is safe when
  `body` is not a Navigator. When it is, wrap the specific text subtree in an
  `EdenSelectableRegion` instead. The same caveat applies to the per-page
  `EdenSelectableRegion`s and to the `MaterialApp.builder` recipe in
  [docs/autofill-and-selection.md](docs/autofill-and-selection.md) §6 — both install a region
  above a Navigator and share the exposure.

  Regression test: `test/widgets/eden_layout_navigator_body_test.dart`. Two cases in
  `test/widgets/eden_layout_selection_test.dart` inverted with the default, by design.

- **`EdenMobileLayout`'s default app-bar menu button now carries a semantic label**
  (`tooltip: 'Open navigation menu'`). It was a 56x56 tappable node with no label at all —
  unreachable by name for a screen reader, and flagged by `expectUiSane`'s tappable-label
  guideline the first time the mobile shell was pumped through the oracle.

### Added

- **`EdenFieldPurpose`** — a 26-member semantic enum. One value resolves `autofillHints` (in
  platform-correct ORDER), `keyboardType`, `obscureText`, `textInputAction`,
  `textCapitalization`, `autocorrect` and `enableSuggestions` as a single consistent set, so a
  hint can no longer disagree with its keyboard. `EdenFieldPurpose.none` is an explicit,
  greppable "no autofill purpose".
- **`EdenAutofillScope`** — an `AutofillGroup` plus `commit()`, which calls
  `TextInput.finishAutofillContext(shouldSave: true)`. That call appeared nowhere in this package
  before, which means no credential typed into an Eden form was ever savable on any platform.
  `EdenForm` and `EdenAsyncFormScaffold` now provide a scope ambiently (`autofillScope`, default
  true).
- **`EdenSelectableRegion`** — `SelectionArea` plus a once-per-process
  `BrowserContextMenu.disableContextMenu()` on web. The package previously contained zero
  `SelectionArea`, zero `SelectableRegion` and zero `contextMenuBuilder`: rendered text could not
  be selected anywhere.
- **`selectableBody`** on `EdenDesktopLayout` and `EdenMobileLayout`, and a region baked into all
  10 library pages. **It defaults to `false` — see `### Changed` below; it shipped as `true` and
  was flipped before release.** Opt in with `selectableBody: true`, and use
  `SelectionContainer.disabled` to exclude a subtree.
- **TSV copy** — `edenCopyTsv`, `edenRowsToTsv`, `edenTsvRow`, `edenTsvCell`,
  `edenExtractWidgetText`, plus `copyable` (default `false`) on `EdenDataTable`, `EdenDataGrid`,
  `EdenKeyValueTable`, `EdenProjectTable` and `EdenLabResultTable`. Drag-selection alone cannot
  copy a table: `SelectionArea` concatenates fragments in tree order with no cell delimiter, so
  a dragged table arrives as run-together text.
- A field-purpose regression guard (`test/tool/eden_field_purpose_guard_test.dart`) that fails
  when a new text field lands without a purpose or a written exemption.

### Changed

- All **136 text fields across 69 files** now carry an explicit `EdenFieldPurpose`. Zero
  exemptions.
  (Planning documents said 137/70. That census was produced with a token grep that also matched
  the words `TextField(` inside a dartdoc comment in `eden_scheduler.dart`, a file with no text
  input at all. A comment-aware recount gives 136/69; nothing built on the inflated figure was
  wrong.)
- The **13 ad-hoc `SelectableText` call sites across 8 files** are now plain `Text` under a
  selection region. Once a region wraps the page, a nested `SelectableText` is an un-draggable
  selection *island* that stops a drag dead at its boundary — the old code went from a partial
  win to actively harmful. There are now zero `SelectableText` widgets under `lib/`.

### Deprecated (not removed)

- `EdenInput.autofillHints`
- `EdenInput.keyboardType`
- `EdenInput.obscureText`

Use `purpose:` instead. All three still work; combining any of them with a non-`none` `purpose`
trips a debug assertion rather than applying a silent precedence rule.

**Why they were deprecated and not deleted.** This package has 4+ downstream consumers and the
constraint on this work was that a breaking change be *explicit* rather than incidental. Deleting
three constructor parameters in the same change that raises the Flutter floor would have produced
one commit that breaks consumers two different ways, and a consumer bisecting a build failure
could not tell which half did it. Removal is targeted at **4.0**.

The deprecation is not cosmetic. Passing `autofillHints` without the matching `keyboardType`
leaves iOS autofill broken while looking correct in review — `TextField` resolves `keyboardType`
in its own constructor initializer list (`material/text_field.dart:355`), so Flutter's
`_inferKeyboardType` fallback can never fire. And `obscureText` alone does not produce a web
password field: DOM `type="password"` derives from the hint string
(`web_ui/.../text_editing.dart:514-531`), never from `obscureText`, so an obscured field with no
password-family hint renders `type="text"` — plaintext in the DOM and invisible to 1Password.

### Flutter floor raised to `>=3.27.0`

Was `>=3.16.0`. `eden-experience-flutter` (`>=3.16.0`) and `eden-platform-flutter` (`>=1.17.0`,
the untouched `flutter create` default) move to the same floor in lockstep, so no sibling
advertises support it cannot deliver.

**This does NOT unlock an API.** Every API this work uses — `AutofillGroup`, `AutofillHints`,
`TextInput.finishAutofillContext`, `SelectionArea`, `SelectionContainer.disabled`,
`contextMenuBuilder`, `BrowserContextMenu` — exists in Flutter 3.16 already. The raise is purely
for toolchain consistency across the workspace and to stop carrying compat shims. A future reader
deciding whether the floor can be lowered again should know it was a consistency decision, not a
capability one.

Only the `flutter:` line moved. Every `sdk:` constraint and every dependency version is untouched,
so a bisect across this commit has one variable. The CI toolchain pin (`3.47.4` in `ci.yml` and
`release.yml`) is a separate decision and is **not** touched here.

### Consumer verification

- `justin-donnaruma-us-go` — `flutter: ^3.29.0`. **Compatible.**
- `justinforme` — Dart `^3.11.1` (= Flutter 3.41.x). **Compatible.**
- `eden-biz-dev` and `aodex-dev` — **not checked out locally, therefore UNVERIFIED.** They were
  not inspected and no claim is made about them. If either pins below 3.27, it will fail to
  resolve against this release.

### Known limitations

Correct hints, an autofill group and `finishAutofillContext` are the ceiling of what the
framework can deliver today. Some web password-manager flows remain broken **upstream**, notably
[flutter#174773](https://github.com/flutter/flutter/issues/174773) (P1, fix in flight) and
[flutter#61301](https://github.com/flutter/flutter/issues/61301) (open since 2020). Providing a
predefined hint does not guarantee a field is eligible for autofill — the active autofill service
decides (`services/autofill.dart:688-694`). Treat autofill as best-effort and never gate
functionality on it.

iOS Password AutoFill additionally requires an Associated Domains entitlement and a published
`apple-app-site-association` file that **this package cannot supply** — they belong to the
consumer app. Android autofill requires API 26+.

Full list, including what is untested rather than broken:
[docs/autofill-and-selection.md](docs/autofill-and-selection.md) section 8.

### Known issues — not yet release-ready

**This release is not shippable as-is, and this section is the reason** — but the reason is no
longer the test run. `flutter test` on this tree is **4840 tests / 27 skipped**, and every
oracle, story and layout test is green. The one red in the last full run was
`scheduler_performance_test.dart`'s "500 events layout completes within 200ms" — a wall-clock
budget that measured 571ms on a loaded machine and passes in isolation; the code it exercises
(`EdenSchedulerEventLayer.layoutWithCache`) is untouched by every commit on this branch. What
remains open is the 27 skipped goldens (item 2) and the questions below.

**What changed since the first draft of this section.** Every failure in the original 22 has been
either fixed or reclassified. The rail-density question got its design ruling (item 1), the
collapse toggle was fixed, the google_fonts fetch that made the accessibility gate unreachable was
fixed in `test/flutter_test_config.dart` (item 3), and the contrast rule that could not see badge
text was replaced (see Changed), which turned up four more shipped defects in the shells and
closed them. Items 5 and 6 were the two questions that had to be settled BEFORE golden baselines
are generated — the typeface every test rasterises in, and whether the search pill really painted
short — and both are now answered and fixed.

1. **The rail-density question is RESOLVED — the tap-target floor is modality-conditional.**
   The desktop rail's 40px nav rows (42px pitch) are correct on a **pointer** surface: WCAG 2.5.8
   Target Size (Minimum) is 24x24 and 40px clears it comfortably. The earlier reading — that the
   rail was in breach of Android 48dp / iOS 44pt — applied touch guidance to a pointer surface.
   The rail therefore keeps 40px and declares `EdenInputModality.pointer`; a mobile drawer or
   bottom bar declares `touch` and is still held to 48/44. Sixteen `nav-item` surfaces now report
   **zero** oracle violations.
   - **FIXED: the "Collapse sidebar" control was 20x20** (`found Size(20.0, 20.0)`) — a bare sized
     `Icon` inside a `GestureDetector`. That is under even WCAG 2.5.8's 24x24 pointer floor, so it
     was a defect under every reading and the ruling does not excuse it. The glyph stays 20px; the
     hit area is now **44x44** with `HitTestBehavior.opaque` (without `opaque` the enlarged box is
     decoration — the semantics rect claims 44 while the real target stays 20).
   - **FIXED: the top bar's search field was 21px tall.** `desktop-layout/default` and
     `desktop-layout/narrow` reported `expected tap target size of at least Size(24.0, 24.0), but
     found Size(813.1, 21.0)` — a real WCAG 2.5.8 failure on a pointer surface. The `TextField`
     is now constrained to the pill's own `_kTopBarSearchHeight` (36), so the published node and
     the tappable region are the same rect; enlarging a WRAPPER instead would have made the node
     claim area it cannot receive taps in, which is pinned by
     `test/ui_oracle/topbar_search_target_test.dart` case 2. What was still open about that pill
     — whether it really painted 16px tall — is settled in known issue 6.
2. **Golden baselines have never been generated, anywhere.** 22 golden tests exist; all of them
   **skip locally** (goldens are Linux/CI-only — see Notes below), and the CI `stories` job owns
   generating them. **They must still NOT be blessed.** Item 1's collapse-toggle fix moved the
   sidebar header's geometry, item 3's font fix changed what is rasterised, the search field was
   grown to a real 36px control, and the contrast fixes under Changed recoloured a badge in the
   mobile bar and three labels in the desktop rail. Blessing now bakes all of that in as the
   expected appearance.
   - **`mobile-layout/drawer-open` and `mobile-layout/more-sheet` are still NOT registered**, and
     deliberately. `tool/gen_story_tests.dart` emits a light golden, a dark golden AND an
     `expectUiSane` test for every story with no per-story opt-out, so registering them would
     emit four golden expectations with no baseline behind them. They also could not be expressed
     as stories today: `EdenStory.build` returns a widget and the harness only pumps it, while
     both overlays need a TAP between the pump and the assertion — which is why
     `test/ui_oracle/mobile_shell_open_surfaces_test.dart` exists instead. They belong in the same
     change that regenerates the mobile-layout baselines.
   - **Item 7 invalidates them once more, and is the last thing that does.** The ring is gone
     from seven widgets and four interiors changed colour; a baseline blessed before item 7 would
     bake a `colorScheme.outline` ring, drawn over its parent's chrome, in as the expected
     appearance. With item 7 landed, no known paint defect of this class remains in the ten
     widgets that carry a bare field, and the two checks that used to be hand-measurements are
     now guards that fail on their own. **Baselines are safe to generate from this tree**; item 8
     lists what stays open, and none of it is a paint defect the goldens would freeze incorrectly
     — the hint-contrast item is real, but it is an INK defect that the goldens will simply record
     and that the contrast rule already reports independently of any baseline.
3. **FIXED — the accessibility gate could not run on any `EdenTheme` surface.** Constructing an
   `EdenTheme` made `google_fonts` start a network fetch (Outfit, Plus Jakarta Sans); the oracle's
   `runAsync` image capture was the first thing in a widget test that actually awaited it, and the
   uncaught async error completed the test directly — it never reached `takeException()`, so no
   helper could drain it. 264 `Failed to load font` errors per full run. `allowRuntimeFetching =
   false` does not help on its own: the error text changes and the uncaught async error does not.
   `test/flutter_test_config.dart` now serves the Eden type families to `google_fonts` as ordinary
   assets from `test_support/fonts/`, through a mock handler on the `flutter/assets` channel that
   delegates everything it does not own back to the real bundle — deliberately NOT via
   `pubspec.yaml`'s `flutter: assets:`, which would ship the bytes in every consumer app. **This
   changes what CI rasterises**, so it is one more reason item 2's baselines must be generated
   after this release's work, not before it.
4. **The story coverage ratchet is currently blind to co-located stories.** Eleven real stories
   were added in this release and `.story-coverage.json` did not move off `{exported_widgets: 364,
   with_story: 11}`. The line-based export derivation collapses the whole `eden_layout` group to a
   single synthetic `EdenLayoutExports` name, so those stories bought zero measured coverage. The
   floor therefore holds, but it is not yet measuring what it claims to measure. Fixing it needs
   `_exports.dart` resolution, which will also move `exported_widgets` off 364.

5. **FIXED — the first test in every file rasterised in a different typeface from the rest.**
   `EdenTheme` fires its google_fonts loads UNAWAITED at theme-construction time, and the first
   thing in a widget test that lets such a future run is `runAsync` — which lives inside
   `expectUiSane`'s contrast phase. So the first test in a file laid out and painted with the
   FALLBACK face, the load completed during it, and every later test in the same file used the
   real one. Measured on the desktop shell: the top bar's search pill was **863.1** logical pixels
   wide in the first test of a file and **904.7** in the second — **41.6px** of layout movement
   caused by nothing but position in the file. `test/flutter_test_config.dart` now constructs both
   `EdenTheme` themes and awaits `GoogleFonts.pendingFonts()` in the per-file bootstrap, which is
   real async and therefore actually completes; every test now renders in the same face, and it is
   the face CI renders in. Pinned by `test/ui_oracle/font_warmup_order_test.dart` (case 1: no font
   load may still be pending when a test starts; case 2: the second test in a file lays the shell
   out identically to the first).
   - **It changed no verdict anywhere.** The full suite was re-run before and after: 4785 passed /
     27 skipped / 0 failed → 4787 (the two new cases) passed / 27 skipped / 0 failed. No geometry
     measurement crossed a threshold. The contrast rule was never exposed to it — it reads its ink
     from the `TextStyle` — but the GEOMETRY rules were, and they are now reading one layout
     rather than two.
   - **This is one more reason item 2's baselines must be generated after this work, not before**:
     a baseline blessed earlier would have baked in whichever face happened to have loaded.
   - The other symptom recorded here — the stock contrast guideline flipping the mobile bar's 11px
     label from 6.91:1 to 3.99:1 by test order — is no longer reproducible, because that guideline
     is no longer in the oracle (see Changed).

6. **FIXED — the top bar's search field painted an opaque box over its own pill.** The question
   recorded here was whether the pill really painted ~16px tall or whether the oracle's 4.83:1
   pixel reading was a capture artifact. It was **neither**: the pill is 36px and paints 36px, and
   the thing that is short is a white rectangle drawn **on top of** it. `_TopBar`'s `TextField`
   set `border: InputBorder.none`, `isDense: true` and `contentPadding: EdgeInsets.zero` but never
   turned the FILL off, so it inherited `EdenTheme`'s `inputDecorationTheme` — `filled: true`,
   `fillColor: Colors.white` in light, `neutral[800]` in dark — and `_RenderDecoration` sizes that
   fill from the decorator's CONTENT height (the ~20px line box) rather than from the 36px the
   enclosing `SizedBox` forces on it. Measured from the captured frame at 1280x800, light, dpr 1:

   | x | what is under it | pixels |
   |---|---|---|
   | 410 | the search icon — no decorator above the pill | `#e4e4e7` for y = 9..44 (the full 36px) |
   | 813 | the hint paragraph | `#ffffff` for y = 11..28, then `#e4e4e7` for y = 30..44 |

   The "~16px band below the text" is the part of the pill the overpaint did not reach. Fixed with
   `filled: false` — the pill IS the fill. **Light theme only as a visual defect**: in dark,
   `inputDecorationTheme.fillColor` and `surfaceContainerHighest` are both `neutral[800]`, so the
   overpaint is the same colour as what it covers.
   - **It was masking a real WCAG 1.4.3 failure.** With the overpaint gone the hint sits on the
     pill's own fill, and `onSurfaceVariant` on `surfaceContainerHighest` is **3.81:1** at
     fontSize 13 — which is exactly the token pair recorded here, now agreeing with the pixels.
     `desktop-layout/default` and `desktop-layout/narrow` both went red in the light theme naming
     it. The hint now takes `colorScheme.secondary` — this palette's muted neutral, `neutral[600]`
     light and `neutral[400]` dark — for **6.09:1 light, 5.81:1 dark**. The dark value does not
     move: dark `secondary` and dark `onSurfaceVariant` are the same `neutral[400]`.
   - The recorded limit of the contrast rule stands as written (it takes the background from the
     dominant colour inside the paragraph's own box), but this surface is no longer an instance of
     it: the rule was reporting the white it was genuinely painted on.
   - Both baselines are invalidated again by this — the pill's appearance changes materially in
     the light theme.

7. **FIXED — the CLASS behind items 6 and the fill fixes: `EdenBareFieldTheme`.** Turning the
   fill off in five widgets did not close anything. `border: InputBorder.none` does not stop
   `InputDecorationTheme.enabledBorder` resolving, so a `colorScheme.outline` ring was still being
   painted INSIDE the decorator's own box, over the parent's chrome, in **seven** widgets —
   `#dcdcdf` along the search pill's top edge where the pill is `#e4e4e7`; a `#d4d4d8` rounded
   rectangle drawn across the photograph in `EdenPhotoCapturePage`; a ring per cell per row in
   `EdenEnvEditor` and `EdenLineItemEditor`; a doubled border in `EdenMessageInput`, whose
   composer draws its own; a 1px frame rendered 2px thick in `EdenMarkdownEditor`; and a ring
   inside `EdenMapView`'s floating search card. `InputDecoration.applyDefaults` resolves **31**
   properties from the theme independently, so `focusedBorder`, `disabledBorder`, `errorBorder`,
   `focusedErrorBorder`, `contentPadding`, `hintStyle`, `constraints` and twenty more were all
   waiting behind the same door: a third round was guaranteed.
   - **`EdenBareFieldTheme`** (exported from `eden_ui.dart`) replaces the ambient
     `InputDecorationTheme` for its subtree with one built from scratch, so nothing `EdenTheme`
     declares can reach a field inside it — not the properties that leaked, and not one a future
     edit adds. `InputDecoration.collapsed` was **checked, not assumed**, and does not cover the
     set: it sets `filled = false` and `border = InputBorder.none` and nothing else
     (`input_decorator.dart:2872`), leaving `enabledBorder` — the slot that actually paints while
     a field sits there enabled — to the theme, and it has no `prefixIcon`/`suffixIcon`/`label`,
     which three of the ten sites need. A shared `const InputDecoration` cannot express "nothing"
     at all: null means "take the theme's".
   - **Adopted at all ten sites** that mean it, including `EdenRichTextEditor` and
     `EdenSecretField` (which had nulled four and three border slots by hand and still inherited
     the error/disabled ones) and `EdenCommandPalette` (three by hand). Each site's local
     `filled: false` / `border: InputBorder.none` opt-outs are gone; what a widget genuinely wants
     it still declares at the site, which still wins — `EdenSecretField` keeps its own
     `OutlineInputBorder`, and `EdenPhotoCapturePage` now declares the 16x12 padding it used to
     inherit so its caption's geometry does not move.
   - **No decorator rect moved.** Every `InputDecorator`'s box is identical before and after; the
     content inside it shifts by the 1px the phantom border used to reserve.
   - **Four interiors DID change**, because those widgets never declared a surface and were
     relying on the theme's fill for one: `EdenMessageInput` `#ffffff` -> `#fafafa` in light
     (1.04:1, dark unchanged); `EdenMarkdownEditor`'s edit pane and `EdenLineItemEditor`'s cells
     and `EdenCommandPalette`'s query row now take the host's surface — which is the surface the
     preview pane, the read-only cells and the results list beside them already took. Three
     seams closed; **all four are baseline changes**, see item 2.
   - **Guarded three ways** (`test/ui_oracle/bare_field_theme_guard_test.dart`, 28 cases): the
     mechanism, property-name driven from the theme's own diagnostics so a property added to
     `EdenTheme` tomorrow is covered without editing the test; the ten surfaces, where every
     `InputDecorator` must be inside the wrapper and resolve none of Eden's chrome; and a source
     census over `lib/` that fails when a NEW file declares a field bare without reaching for it.
     Differential controls, one edit each: making the wrapper a pass-through turns 34 cases red;
     making its `filled` true turns 22 red.

8. **Recorded, not fixed — what this pass measured and deliberately left.** Each of these is out
   of the leak class above, or out of reach of the suite, and none is a regression from it.
   - **The hint ink fails WCAG 1.4.3 in the bare fields, in both themes.** `neutral[400]` on a
     light card is **2.46:1** (`EdenEnvEditor`, `EdenMessageInput`, `EdenMarkdownEditor`,
     `EdenBarcodeScanner` — one ink, four widgets), and `neutral[500]` on a dark one is
     **4.10:1**. Pre-existing and NOT caused by the overpaint: the fix moved the light pairs from
     2.56:1 to 2.46:1 (both sides of the floor are the same side) and the dark markdown hint from
     3.08:1 to 4.10:1. It wants the same treatment `_TopBar`'s hint got — a `ColorScheme` role
     that clears the floor on the surface the glyph is actually painted on — across four widgets,
     which is its own pass.
   - **`EdenLineItemEditor`'s five cells** carry issues beyond the ring (their own pass, out of
     this class).
   - **`EdenDataGrid`'s filter input paints ~26px in a 30px slot.** Cosmetic; no contrast or
     target-size consequence.
   - **The `EdenProfileFonts` / `EdenAdaptiveTheme` second font path cannot reach the golden
     suite** — the generated story tests rasterise through `EdenTheme` only, so nothing in CI
     renders that path. It is untested rather than broken, and giving it coverage means giving it
     stories.
   - **`EdenMarkdownEditor` and `EdenCommandPalette` declare no surface of their own.** That is
     why their interiors changed above. If the library later wants either to be a self-contained
     surface, the fill belongs on the parent container — the pattern `EdenRichTextEditor` already
     uses — never back on the field.

### Notes

- Goldens are generated and compared in **CI (Linux) only**. Never run `--update-goldens` from a
  workstation — local Flutter here is 3.41.9 while CI pins 3.47.4, so a locally blessed baseline is
  pure churn. eden-ui-flutter#32.
- `testWidgets` takes `bool? skip`, not a reason string. The golden skip policy is `kGoldenSkip`
  (a bool) plus `kGoldenSkipSuffix` appended to the test **name** so the reason still prints.

## 2.0.0

The first stable tagged release. `v1.0.0-rc.1` (2026-04-23) was the only prior
tag; everything since has been consumed straight from `main`.

### Why 2.0.0 and not 1.2.0

`version: 1.1.1` sat in `pubspec.yaml` from the initial commit and was never
changed — no release ever corresponded to it, so 1.1.x is skipped rather than
retroactively invented.

The major is not ceremony. There is exactly one breaking change (below). Cutting
a minor over a known breaking change would make the version untrustworthy on the
first release, which would defeat the point of versioning this library at all.

### Breaking

- **`EdenMapMarker` is no longer exported from the barrel.**
  `export 'src/widgets/eden_map_view.dart' hide EdenMapMarker;` resolves a name
  collision with the map-provider `EdenMapMarker`, which *is* exported. The name
  still resolves from `package:eden_ui_flutter/eden_ui.dart` — **to a different
  type**. Code that compiled before may now compile differently rather than fail
  loudly, so check any use of `EdenMapMarker`.
  To keep the original, import the file directly:
  `package:eden_ui_flutter/src/widgets/eden_map_view.dart`.

  No known consumer references either `EdenMapMarker` or `EdenMapView`.

### Added

- Public API grew from **179 to 359 exports** (+181) across 602 commits and 225
  new widget files: the scheduler family, runtime brand tokens and swatch
  generation, diagram pan/zoom, template builder, map providers, and more.
- `EdenSelect` now uses Eden's own overlay menu instead of Material's
  `DropdownButton`, so it is themeable and no longer inherits Material's
  dropdown behaviour.
- Optional per-row `Key` on `EdenTableRow`; optional per-item `Key` on
  `EdenTabItem`.
- `EdenBadge` ellipsizes a long label instead of overflowing when given a
  constrained width.

### Release engineering

- `release.yml` no longer analyzes with `--fatal-infos`. It had failed on every
  merge to `main` since creation, so `Tag Release` never ran — which is why this
  is the first tag in five months.
- The toolchain is still **unpinned** (`channel: stable`, no `flutter-version`)
  and remains the standing hazard here. It is deliberately NOT fixed in this
  release: the tree's correctness is currently SDK-dependent. On
  `channel: stable`, `ReorderableListView.onReorder` is nullable so
  `rlv.onReorder!(...)` is required; on the older 3.41.4 the same `!` is an
  `unnecessary_non_null_assertion` warning. `dfe1698` removed it on the strength
  of the local warning and `30cb437` had to restore it after CI failed with
  `unchecked_use_of_nullable_value`. Pinning therefore forces a source decision,
  not just a config one, and belongs in its own change.

## 1.0.0-rc.1

Initial release candidate.
