---
objective: 23-ui-oracle-loop-w1a-catalog-as-contract
kind: ui-lib
work: feature
tdd: tdd
status: planned
overrides:
  tdd: tdd
---

# Objective 23 — UI Oracle Loop W1a — Catalog as contract: patterns, story harness, expectUiSane, probe bridge, shell API

Wave 1a of the UI Oracle Loop program. The spec and plan live in the **devflow-claude** repo at
`docs/PROPOSAL-ui-oracle-loop.md` (§5 design references, §6 catalog as contract, §7 the probe) and
`docs/IMPLEMENTATION-PLAN-ui-oracle-loop.md` Part 3 → "W1a — eden-ui-flutter: `df/ui-oracle-library`"
(TRDs 1a-01 … 1a-12). Read both from `/Users/markemerson/Source/devflow-claude/docs/` — that table
is the requirements, with each TRD's deliverable, files, RED test list and gate.

## Goal

The library can describe, render, assert and probe its own widgets — so a consumer's screen test
and a machine oracle both have something to hold a UI against:

- **Stories**: co-located `<widget>.stories.dart`, one story per meaningful state, registry
  generated (drift fails CI), coverage ratcheted. Wave-1 scope is the shell widgets (layout, nav,
  buttons, inputs, data grid) plus anything an objective touches — not all 509 files.
- **Harness**: every story is a `flutter test` asserting (1) a golden in light and dark,
  (2) `meetsGuideline` tap-target / contrast / labelled-tap-target, (3) **semantics geometry** —
  every node carrying an `identifier` has its rect inside the viewport, sibling control rects are
  disjoint, exactly one tap action is declared per control, and `tester.takeException()` is null.
- **`expectUiSane(tester)`**: those three assertions shipped as `package:eden_ui_flutter/testing.dart`
  so the 600+ consumer screen tests can call them.
- **Probe bridge**: `lib/src/probe/`, compiled in ONLY under
  `const bool.fromEnvironment('EDEN_PROBE')`, exposing `window.__edenProbe.{find,tree,settled,state}`
  — real widget rects, the semantics summary, and a settled signal. Tree-shaken otherwise, and a
  guard proves the shipped release bundle contains no `__edenProbe`.
- **Patterns**: `design/patterns/<id>.md` — the ~10 recurring interaction patterns, rules written
  in the `must_not` vocabulary so Surface Specs inherit them; indexed from DevFlow's
  `design-stack-flutter.md`.
- **Shell API**: `EdenDesktopLayout` gains composition slots (item/section builders) so a consumer
  expresses new rail behaviour without a library change and a pin bump.

## Fold in: issue #33 (real production bug, this repo owns it)

`eden_desktop_layout.dart:58` defaults `selectableBody = true`, wrapping the body in a
`SelectionArea`. When the body contains a Navigator (every go_router shell app), deep-linking into
a nested route asserts — `_compareScreenOrder → getTransformTo` through a never-laid-out covered
page (flutter#151536, fix #184900 unmerged). Measured in aodex#611: six routing tests red; aodex
took the `selectableBody: false` opt-out. eden-biz is one nested route away from the same failure.
**Flip the default to opt-in** as part of the shell-API TRD (1a-06), document why, and add a
regression test that pumps a Navigator body and deep-links into a nested route. Per-page
`EdenSelectableRegion`s and the `MaterialApp.builder` recipe in the docs share the exposure — carry
the same caveat.

## Runtime model (binding — every TRD and reviewer brief repeats it)

- This is a **library**, consumed by `path:`/git pin from eden-biz and aodex. Anything added to the
  public surface is an additive minor; breaking a constructor breaks two apps on the next pin bump.
- **Goldens are generated in CI (Linux) and compared with platform tagging** — never blessed from a
  macOS workstation, or they churn on font rasterisation. eden-ui-flutter#32 is exactly that class:
  `chat_screen_test`'s 390pt overflow assertion passes CI and fails locally by 8.5px.
- The probe bridge is web-only JS interop behind a conditional import; on non-web it is a no-op
  stub. Never the VM service: the working browser recipe is `flutter build web --release` + a
  static server (`flutter run`'s DWDS wedges into a silent blank page), and the DTD path for web is
  broken upstream (dart-lang/ai#356).
- Under `EDEN_PROBE` the app disables animations and uses bundled fonts — no `google_fonts` runtime
  fetch — so a capture is deterministic.
- Flutter floor is 3.27.0 (raised at v2.1.0). Tests run `flutter test`; `flutter analyze` must stay
  at 0 errors.

## TDD contract

Every feature TRD is `type=tdd`, `stack=flutter`. Test list first, in the TRD. One test at a time,
RED proven by exit code. Hand-built fixtures and story data — never generated lists of state names.
For 1a-02 (`expectUiSane`) the RED cases are concrete and each needs its own broken fixture: a
215px RenderFlex overflow from long text in an unbounded `Row` slot; two identified controls with
overlapping rects; one control declaring two tap actions (`ExcludeSemantics` outside plus
`Semantics(onTap:)`); a sub-24px tap target; dark-on-dark contrast. Prove each RED by stashing the
fix, not by asserting the assertion exists.

## Definition of done

`flutter test` green including the generated story tests; the registry-drift test fails when a
co-located story is added without regenerating; coverage ratchet holds; `expectUiSane` fails, with
the widget named, on each of the five broken fixtures; `EDEN_PROBE=true` release build exposes
`__edenProbe.find()` returning real rects and a production build contains no `__edenProbe` (CI job);
the ten pattern files exist with their seven required headings and every story id they cite is
registered; `EdenDesktopLayout` renders unchanged for a consumer that passes no builders (the
existing layout tests pass UNMODIFIED as the proof), `selectableBody` defaults to opt-in with a
Navigator-body regression test; `DESIGN.md`'s token block is generated and CI-diffed; tagged v2.2.0.

## Out of scope

The Surface Spec schema, review sheet and look-lock (W1b, devflow-claude); the e2e seed/identity/
fault stubs (W1c, consumers); `ui probe`'s CDP driver and the checks over `ProbeResult` (W2 — this
objective ships only the in-app bridge the driver talks to); porting any Trades feature (W3).
