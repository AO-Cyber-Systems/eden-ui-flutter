---
work: feature
overrides:
  tdd: per-feature
  depth: standard
---

# Objective 1: EdenPageHeader iPhone-narrow Wrap fix

Per-objective metadata. Authoritative description lives in [`../../ROADMAP.md`](../../ROADMAP.md) under "Objective 1: EdenPageHeader iPhone-narrow Wrap fix". Per-requirement detail lives in [`../../REQUIREMENTS.md`](../../REQUIREMENTS.md) under "Responsive Layout (RESP)".

## Why these overrides

- **`work: feature`** — net-new responsive-design behavior (LayoutBuilder + breakpoint-driven layout switch), even though it fixes an existing bug. The widget test for iPhone-narrow is also net-new (no test existed for this widget before — `test/widgets/eden_page_header_test.dart` doesn't exist).
- **`tdd: per-feature`** — RED→GREEN cycle for the responsive case: write the failing iPhone-narrow render test FIRST, then apply the LayoutBuilder fix. Wide-viewport regression test follows. This is the smallest TDD posture that still gives a real RED before the fix.
- **`depth: standard`** — single-widget scope, but the responsive pattern (LayoutBuilder + breakpoint) becomes the template for future RESP requirements (Wave 0a-style cross-repo issues). One TRD, two atomic commits expected (test: RED → feat: GREEN).

## Reference context (NOT a TRD; planner consumes)

- **Bug surfaced by:** `eden-biz-flutter` Objective 12 iOS sentinel run on 2026-05-07. Production code at `eden_page_header.dart:27` outer Row overflows on iPhone 16 Pro (390pt logical width) when consuming widgets pass 2-3 EdenButton actions. eden-biz-flutter's `scheduling_screen.dart` is the primary consumer that triggered the finding.
- **Spike-suggested fix shape:** `LayoutBuilder` wrapping the build output. Above 480pt: original Row layout. Below 480pt: stack actions below title-block in a Column. Pattern already applied (and verified) to `eden-biz-flutter`'s own `_GlobalTopBar` in commit `dea58e9` (eden-biz-flutter quick task 1).
- **No new external dependencies.** Just `LayoutBuilder` from `flutter/widgets.dart` (already imported via material).
- **Test pattern to follow:** existing `test/widgets/eden_alert_test.dart` shape — `wrap()` helper + `testWidgets()` blocks. Add `tester.view.physicalSize` + `tester.view.devicePixelRatio` for the iPhone-narrow case; reset in `tearDown`.

## Success criteria (from ROADMAP)

1. `EdenPageHeader` rendered at 390pt logical width with 3 actions: NO `RenderFlex overflowed` exception (RESP-01).
2. New `test/widgets/eden_page_header_test.dart` covers iPhone-narrow + wide-viewport + actions-stacking scenarios (RESP-02, RESP-03).
3. Wide-viewport behavior unchanged for existing downstream consumers.
4. `flutter analyze` clean.
5. Downstream verification (manual, not gating): `eden-biz-flutter` iOS sentinel re-runs after this lands + `flutter pub get`; 4 deferred tests behind `_kSchedulingScreenSkipped` flip green.

## Out of scope

- Other widgets that may overflow at iPhone-narrow (cross-cutting responsive audit) — separate future objective
- Visual regression / pixel-diff baselines — v2 (VRT-01)
- Cross-platform render gates — v2 (XPL-01)
- Real-device testing
