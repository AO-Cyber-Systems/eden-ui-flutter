# Changelog

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
