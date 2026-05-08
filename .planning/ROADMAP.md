# eden-ui-flutter — Roadmap

## Active Objectives

### Objective 1: EdenPageHeader iPhone-narrow Wrap fix

**Goal:** `EdenPageHeader` widget no longer overflows its outer `Row` layout on iPhone-narrow viewports (≥390pt logical width). Currently the outer `Row` places `title-Column` + `actions-Row` side-by-side via the title's `Expanded`; on narrow viewports with 2-3 action buttons, the actions Row consumes more horizontal space than the leftover, causing `RenderFlex overflowed by N pixels`. Fix: wrap the build output in a `LayoutBuilder` that stacks actions below the title block on viewports `< 480pt` logical width while preserving the original side-by-side layout on wide.

**Requirements:** RESP-01, RESP-02, RESP-03.

**Why:** Surfaced by the downstream `eden-biz-flutter` Objective 12 iOS sentinel (commit `f9a9941` in eden-biz-flutter). 4 deferred iOS sentinel tests in eden-biz-flutter sit behind a `_kSchedulingScreenSkipped` flag awaiting this fix. Reference: `eden-biz-flutter/.planning/objectives/12-ui-e2e-coverage/12-04-SUMMARY.md` § Deferred Items, `12-PROJECT.md` § Wave 0a.

**Branch:** `fix/eden-page-header-iphone-narrow-overflow` (already cut from `origin/main` `e081038`).

**TRDs:** TBD (planner decides — likely 1 type=tdd TRD with RED→GREEN cycle: failing iPhone-narrow widget test → LayoutBuilder fix → wide-viewport regression test).

**Success Criteria:**
1. `EdenPageHeader` rendered at 390pt logical width with 3 actions: NO `RenderFlex overflowed` exception, NO yellow-and-black overflow indicators (RESP-01).
2. New widget test file `test/widgets/eden_page_header_test.dart` exists with at least: (a) iPhone-narrow render passes, (b) wide-viewport (≥1024pt) side-by-side layout preserved, (c) actions wrap below title-block at narrow widths (RESP-02, RESP-03).
3. Wide-viewport behavior unchanged: existing downstream consumers (eden-biz-flutter, etc.) see identical layout on iPad/desktop.
4. `flutter analyze` clean for the modified widget.
5. Downstream verification (manual, not gating this objective): re-run `eden-biz-flutter`'s iOS sentinel after this lands + `flutter pub get` + flip `_kSchedulingScreenSkipped` to `false`. The 4 deferred iOS sentinel tests should pass without the spike's viewport-widening kludge.

**Out of scope:**
- Other widgets that may overflow at iPhone-narrow (cross-cutting responsive audit) — separate v2 objective when surfaced
- Visual regression baselines (deferred to v2 VRT-01)
- Real-device iOS testing (downstream concern)
- Cross-platform render gates (deferred to v2 XPL-01)

**Reference docs:**
- `eden-biz-flutter/.planning/objectives/12-ui-e2e-coverage/12-04-SUMMARY.md` — iOS sentinel that surfaced this bug
- `eden-biz-flutter/.planning/objectives/12-ui-e2e-coverage/12-PROJECT.md` § Wave 0a — original cross-repo prerequisite framing
- Reference fix shape (spike-suggested, applied to eden-biz-flutter's `_GlobalTopBar` already): wrap in `LayoutBuilder`, conditional rendering of side-by-side widgets above breakpoint
