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
  semantics-rect disjointness, one tap action per control, and the accessibility guidelines
  (tap-target size, tappable label, text contrast). Also exports `SemanticsGeometryNode`,
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

**This release is not shippable as-is, and this section is the reason.** `flutter test` on this
tree is **4693 passed / 27 skipped / 22 FAILED**. The 22 failures are not flakes and must not be
suppressed — the oracle that produces them is the point of this work.

**What changed since the first draft of this section.** The rail-density question below got its
design ruling (see `EdenInputModality` under Added), and the collapse toggle got fixed. The same
22 tests still fail, but the reason is now item 3 alone for 16 of them: the oracle's tap-target
report went from 22 surfaces to 6.

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
   - **STILL OPEN, and newly visible: the top bar's search field is 21px tall.** With the 48/44
     report no longer drowning it out, `desktop-layout/default` and `desktop-layout/narrow` report
     `SemanticsNode(... label: "Search orders…"): expected tap target size of at least
     Size(24.0, 24.0), but found Size(813.1, 21.0)`. This is a real WCAG 2.5.8 failure on a
     pointer surface, and it is a top-bar geometry decision that has not been made yet.
2. **Golden baselines have never been generated, anywhere.** 22 golden tests exist; all of them
   **skip locally** (goldens are Linux/CI-only — see Notes below), and the CI `stories` job owns
   generating them. **They must still NOT be blessed.** Item 1's collapse-toggle fix moved the
   sidebar header's geometry, the search-field question is still open, and item 3 will change
   rasterisation when it is fixed. Blessing now bakes all three in as the expected appearance.
3. **No `EdenTheme` surface has a working accessibility gate — this is what all 22 failures now
   have in common.** Every generated `expectUiSane` test dies before its verdict is reported:
   constructing an `EdenTheme` makes `google_fonts` start a network fetch (Outfit, Plus Jakarta
   Sans), `textContrastGuideline`'s `runAsync` image capture is the first thing in a widget test
   that actually awaits it, and the uncaught async error completes the test directly — it never
   reaches `takeException()`, so it cannot be drained. 264 `Failed to load font` errors per full
   run, unchanged by any work in this release. `GoogleFonts.config.allowRuntimeFetching = false`
   does not help (the fonts are not bundled as assets either). The same root cause makes
   `textContrastGuideline` — and any image-based check — **unusable on every `EdenTheme` surface**.
   This is documented as a KNOWN LIMITATION in `expectUiSane`'s dartdoc. Geometry, structure and
   tap-target checks are unaffected and do run — that is how the modality ruling above could be
   measured at all. **The fix belongs in the test environment** (bundle the fonts, or stub the
   fetch in `test/flutter_test_config.dart`), and it will change what CI rasterises, so it must
   land before goldens are blessed, not after.
4. **The story coverage ratchet is currently blind to co-located stories.** Eleven real stories
   were added in this release and `.story-coverage.json` did not move off `{exported_widgets: 364,
   with_story: 11}`. The line-based export derivation collapses the whole `eden_layout` group to a
   single synthetic `EdenLayoutExports` name, so those stories bought zero measured coverage. The
   floor therefore holds, but it is not yet measuring what it claims to measure. Fixing it needs
   `_exports.dart` resolution, which will also move `exported_widgets` off 364.

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
