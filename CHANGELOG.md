# Changelog

## Unreleased

Password-manager autofill and universal copy/paste. Consumer setup guide:
[docs/autofill-and-selection.md](docs/autofill-and-selection.md).

No version number is claimed here. `release.yml` tags from `pubspec.yaml`'s `version:` field,
which this change deliberately leaves at `2.0.0` — picking the next number is a release decision,
and coupling it to a floor raise would make a bisect ambiguous. Whoever cuts the release renames
this heading and bumps the pubspec in the same commit. The deprecations below make it a minor,
not a patch.

### Changed

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
