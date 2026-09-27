# eden_ui_flutter

Shared UI/design-system package for Eden Flutter apps.

It contains:

- theme and token definitions
- reusable widgets
- layout primitives
- a visual dev catalog under `lib/dev_app`
- a co-located story catalogue and a UI correctness oracle (see below)

## Contract for contributors

This package is consumed by `path:`/git pin from **eden-biz** and **aodex**. Anything added to the
public surface is an additive minor; changing or removing a constructor parameter breaks both apps
on their next pin bump. Treat that as the default constraint, not an edge case.

- **New capability → a new optional parameter** with a null/false default, or a new entry point.
  The nav composition slots are the worked example: `itemBuilder` and `sectionBuilder` are
  `Widget? Function(...)`, and **returning `null` declines the row** so the built-in renderer runs.
  A consumer passing no builders gets byte-identical rendering.
- **Changing a default is a documented `### Changed` entry in `CHANGELOG.md`, never a quiet edit.**
  `selectableBody` in 2.2.0 is the worked example — it flipped to `false`, and consumers who want
  the old behaviour pass `selectableBody: true`.
- **Test-only helpers live behind `package:eden_ui_flutter/testing.dart`; the probe behind
  `package:eden_ui_flutter/probe.dart`.** Neither is exported from `eden_ui.dart`, so
  `package:flutter_test` and `dart:js_interop` never reach a consumer's production graph. Keep it
  that way.
- **Goldens are generated in CI on Linux.** Never run `--update-goldens` from a workstation — local
  and CI Flutter versions differ, so a locally blessed baseline is churn (#32).

## Testing your screens

`expectUiSane` is a single assertion covering the failure modes a widget test normally cannot see:
escaped exceptions (including overflow), viewport containment, sibling semantics-rect
disjointness, one tap action per control, and the Material accessibility guidelines.

```dart
import 'package:eden_ui_flutter/testing.dart';

testWidgets('dashboard renders sanely', (tester) async {
  await tester.pumpWidget(const MyDashboard());
  await tester.pumpAndSettle();

  await expectUiSane(tester);           // or: allowOverlap: {'header', 'fab'}
});
```

Two things to know before adopting it:

- A control is only checked if it is addressable, so give every control you want checked
  **`container: true`**. What omitting it costs is SDK-dependent, and both ends are measured by
  `test/ui_oracle/semantics_geometry_test.dart` case 7: on Flutter 3.41.9 a nested `Semantics`
  without it published no node at all — its identifier vanished into the enclosing node — while on
  3.47.4, which this package's CI pins, it publishes its own node with its own rect. The rule holds
  either way: the declared floor (`flutter: ">=3.27.0"`) still spans versions with the old
  behaviour, and `container: true` states the boundary instead of inheriting whichever one a
  consumer's SDK gives it.
- **Contrast and other image-based checks do not currently work on any `EdenTheme` surface.**
  Constructing the theme starts a `google_fonts` network fetch, and the resulting uncaught async
  error completes the test before the check can run. Geometry and structure checks are unaffected.
  See `expectUiSane`'s dartdoc and the 2.2.0 "Known issues" section of `CHANGELOG.md`.

## Stories

Widgets declare their states in a co-located `<widget>.stories.dart` file beside the widget (e.g.
`lib/src/widgets/eden_layout/eden_desktop_layout.stories.dart`). `tool/gen_stories.dart` generates
the registry and `tool/gen_story_tests.dart` generates, per story, a light+dark golden test and an
`expectUiSane` test. A drift test fails when a story is added without regenerating, and
`tool/story_coverage.dart` holds a coverage floor in `.story-coverage.json`.

Interaction patterns — what each shell surface must and must not do — live in `design/patterns/`,
written against the closed vocabulary in `design/must_not_vocabulary.json`. Design tokens are
documented in `DESIGN.md`, which is generated from `lib/src/tokens/` by `tool/gen_design_md.dart`
and CI-diffed, so it cannot drift.

## Probe

`package:eden_ui_flutter/probe.dart` exposes a web JS-interop bridge for driving a running build
from a browser automation harness: `window.__edenProbe.{find, tree, settled, state}`.

```dart
import 'package:eden_ui_flutter/probe.dart';

void main() {
  EdenProbe.install();          // no-op without the define
  runApp(const EdenProbeScope(child: MyApp()));
}
```

It is compiled in **only** under the define, and tree-shaken out otherwise:

```bash
flutter build web --release --dart-define=EDEN_PROBE=true
```

`kEdenProbe` is the compile-time flag. A production build contains no `__edenProbe` at all —
enforced by the `probe-guard` CI job (`tool/probe_guard.sh`).

## Run The Catalog

```bash
flutter run -t lib/main.dart
```

## Autofill And Selection

Every text input resolves its autofill hints, keyboard type and obscure flag from a single
`EdenFieldPurpose`.

Rendered text selection is **opt-in**: `selectableBody` defaults to `false` on `EdenDesktopLayout`
and `EdenMobileLayout`, because a `SelectionArea` over a subtree containing a Navigator asserts on
deep-link to a nested route (flutter#151536). Pass `selectableBody: true` on surfaces whose body is
not a Navigator, or wrap a specific text subtree in an `EdenSelectableRegion`.

iOS needs an Associated Domains entitlement and a published AASA file before any of it works in a
real app — see [docs/autofill-and-selection.md](docs/autofill-and-selection.md).

## Boundaries

- Keep this package transport-agnostic.
- Backend contracts and generated API clients belong in `eden-platform-api-dart`.
- App/session orchestration belongs in `eden-platform-flutter`.
