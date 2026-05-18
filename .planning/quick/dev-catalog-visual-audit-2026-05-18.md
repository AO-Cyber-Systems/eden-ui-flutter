# Dev Catalog Visual Defect Audit — 2026-05-18

Audited `lib/dev_app/screens/*.dart` (40 files) for latent visual defects
similar to the just-fixed RenderFlex overflow in `scheduler_screen.dart`
month-view parity row.

**Audit scope:** Read-only static analysis. No code modified. No
`flutter analyze` or `flutter test` invoked. Cross-referenced
`Image.asset(...)` calls against actual files in `lib/dev_app/_assets/`.

## Section 1 — Defect inventory

| screen | line | defect_pattern | one_sentence_fix |
|---|---|---|---|
| `medical_screen.dart` | 1060–1067 | `SizedBox(width: 1200, height: 800)` rendering `EdenPatientChartScaffold` bare inside the page-level `ListView` — viewports below 1200pt produce horizontal RenderFlex overflow. | Wrap in `SingleChildScrollView(scrollDirection: Axis.horizontal, ...)` (matches `data_display_screen.dart:950` precedent). |
| `medical_screen.dart` | 1246–1271 | `SizedBox(width: 1200, height: 600)` rendering `EdenVisitEncounterScaffold` bare inside the page-level `ListView` — horizontal overflow below 1200pt. | Wrap in `SingleChildScrollView(scrollDirection: Axis.horizontal, ...)`. |
| `medical_screen.dart` | 1275–1300 | `SizedBox(width: 1200, height: 700)` rendering `EdenVisitEncounterScaffold` (URI variant) bare — horizontal overflow below 1200pt. | Wrap in `SingleChildScrollView(scrollDirection: Axis.horizontal, ...)`. |
| `retail_polish_screen.dart` | 105–108 | `SizedBox(width: 600, child: EdenLoyaltyMemberDetail(...))` bare inside ListView — horizontal overflow below 600pt (typical iPhone-narrow at 390pt). | Replace with `ConstrainedBox(constraints: BoxConstraints(maxWidth: 600))` OR wrap in horizontal-scroll. |
| `retail_polish_screen.dart` | 166 | `SizedBox(width: 800, child: EdenStoreCreditLedger(...))` bare inside ListView — horizontal overflow below 800pt (any viewport ≤ Medium tablet). | Replace with `ConstrainedBox(constraints: BoxConstraints(maxWidth: 800))` OR wrap in horizontal-scroll. |
| `retail_polish_screen.dart` | 225–228 | `const SizedBox(width: 600, child: EdenGiftCardBalanceLookup(...))` bare inside ListView — horizontal overflow below 600pt. | Replace with `ConstrainedBox(maxWidth: 600)` OR wrap in horizontal-scroll. |
| `scheduler_screen.dart` | 295 | `LayoutBuilder` uses non-canonical breakpoint `c.maxWidth < 900` for compact/expanded swap (canonical breakpoints in this codebase: 480 / 600 / 768 / 1100 / 1280; widget-level uses 480 narrow + 768 tablet). 900 is not on either list. | Change to `c.maxWidth < 1100` to align with EdenScheduler's documented 1100pt-toolbar-collapse breakpoint, OR `< 768` to match the widget-level `tabletBreakpoint`. Low priority — cosmetic only, no overflow. |
| `layouts_screen.dart` | 508 | `DropdownButton<String>` inside a `Row` without `isExpanded: true` — fine on wide viewports but on narrow widths the menu width is bounded only by content. Risk: if the Row gets squeezed under EdenAppMode narrow nav, the dropdown chevron sits flush against neighboring `Text`. | Add `isExpanded: true` and wrap in `Expanded(...)`, or accept as cosmetic. Low priority — only visible at <480pt viewport. |
| `chat_screen.dart` | 681 | Same dropdown-without-isExpanded pattern (in a `Row` with `'Vertical: '` leading text). | Same fix as above. Low priority. |
| `companion_screen.dart` | 108, 479, 502 | Same dropdown-without-isExpanded pattern (3 instances). | Same fix as above. Low priority. |
| `process_builder_screen.dart` | 102 | Same dropdown-without-isExpanded pattern inside `AppBar.actions` Padding — actions slot is bounded; if title pushes against it on narrow widths, dropdown text may clip. | Either constrain title with `Flexible` or add `isExpanded: true`. Cosmetic. |
| `template_builder_screen.dart` | 138 | Same dropdown-without-isExpanded pattern inside `AppBar.actions` Padding — already wrapped in `DropdownButtonHideUnderline`, but no width-expanding guard. | Same as process_builder. Cosmetic. |
| `fuel_screen.dart` | 484 | `SizedBox(height: 900, child: EdenRouteOptimizationResult(...))` — height 900 inside vertical ListView is fine for vertical axis, but inside a phone-narrow viewport (height 844pt on iPhone Pro Max) it forces a 900pt scrollable region. Not a defect per se; flag as UX-pressure point. | Optional: switch to `ConstrainedBox(maxHeight: 900)` so it can render shorter when child doesn't need full height. Polish only. |
| `medical_screen.dart` | 1581, 1582, 1607, 1637 | Network image URLs (`https://placehold.co/...`) — dev catalog renders fine when online but blank/error on offline first-load. No `loadingBuilder` / `errorBuilder` on the demo. | Accept (intentional; placehold.co stays up; matches commerce/retail picsum precedent). |
| `misc_screen.dart` | 248, 259, 273 | `https://images.example.invalid/...` URLs — labels correctly say "404 fallback", "Error fallback", "Async headersBuilder". | INTENTIONAL — demos the EdenAuthenticatedImage error/loading states. NOT a defect. |
| `fuel_screen.dart` | 120 | `https://via.placeholder.com/...` URL for photo capture demo — works in browser but slower load + flaky during outages. | Optional: swap to `picsum.photos/seed/...` for consistency with retail. Polish only. |

## Section 2 — Proposed quick-task batches

### Quick task 3 — `fix-medical-retail-polish-horizontal-overflow` — **priority 1**

**User-visible impact:** User opens medical or retail-polish dev-catalog
screen at any browser-narrow viewport (<1200pt for medical, <800pt for
retail-polish). Yellow-and-black RenderFlex overflow stripes appear
identical to the bug just fixed in scheduler. Highly likely to hit user
on first visual QA pass of either screen.

**Files (3):** `medical_screen.dart`, `retail_polish_screen.dart`,
`scheduler_screen.dart` (breakpoint tweak)

**Changes (≤80 LOC total):**
1. `medical_screen.dart`: wrap 3× `SizedBox(width: 1200, …)` in
   `SingleChildScrollView(scrollDirection: Axis.horizontal, …)` —
   matches `data_display_screen.dart:950` pattern.
2. `retail_polish_screen.dart`: change 3× `SizedBox(width: NNN, …)` →
   `ConstrainedBox(constraints: BoxConstraints(maxWidth: NNN))` so each
   widget renders at the natural narrower width on phone viewports and
   only honors the cap on wide ones.
3. `scheduler_screen.dart:295`: change `< 900` → `< 1100` to align with
   the documented `EdenScheduler` toolbar-collapse breakpoint
   (`Live EdenScheduler` section comment at line 145 says
   "responsive collapse to icon-only below 1100pt").

**Test strategy:** add a height-aware widget-test per screen (same
pattern as TRD-just-fixed `eden_scheduler_test.dart` overflow tests)
asserting `tester.takeException()` returns no `FlutterError` when
rendered at 390×844 (iPhone-narrow) and at 768×1024 (iPad-narrow).

### Quick task 4 — `dev-catalog-dropdown-isExpanded` — **priority 3**

**User-visible impact:** Cosmetic only. Dropdowns sit too close to
leading text on narrow viewports. Won't crash, won't trigger flutter
analyze warnings, only flagged because obj 021 had the same family of
issues.

**Files (5):** `layouts_screen.dart`, `chat_screen.dart`,
`companion_screen.dart`, `process_builder_screen.dart`,
`template_builder_screen.dart`

**Changes (≤40 LOC total):** Add `isExpanded: true` + wrap in
`Expanded(...)` for each of the 7 flagged DropdownButton usages.
Where the parent is an `AppBar.actions` Padding (process_builder,
template_builder), give the dropdown a `SizedBox(width: 180)` constraint
instead — actions slot can't usefully take Expanded.

**Test strategy:** none required — pure visual polish. Walk through
each screen at 390pt and 768pt browser widths to confirm.

## Section 3 — Files inventoried and found clean

Files audited that yielded no defects against the seven scan patterns:

- `avatars_screen.dart`
- `badges_alerts_screen.dart`
- `buttons_screen.dart`
- `cards_screen.dart`
- `colors_screen.dart`
- `commerce_screen.dart`
- `compliance_screen.dart`
- `composers_screen.dart`
- `compound_screen.dart`
- `data_display_screen.dart` *(uses correct `SingleChildScrollView(Axis.horizontal)` wrapper for wide-width children at lines 950 + 1031)*
- `devflow_infra_screen.dart`
- `devflow_project_screen.dart`
- `devflow_tools_screen.dart`
- `diagram_screen.dart`
- `eod_screen.dart`
- `field_screen.dart` *(several fixed-height containers but all wrap concrete bounded-content widgets like `EdenInspectionFormPage`)*
- `home_screen.dart`
- `inputs_screen.dart`
- `motion_screen.dart`
- `navigation_screen.dart`
- `overlays_screen.dart`
- `retail_screen.dart` *(picsum.photos URLs are fine; widths all ≤350pt)*
- `salon_screen.dart`
- `settings_screen.dart`
- `staff_screen.dart`
- `theme_profiles_screen.dart` *(width-320 in Wrap = safe)*
- `trades_screen.dart` *(width-480 in Wrap = safe; doc-page width 400 has `clipBehavior: Clip.hardEdge`)*
- `typography_screen.dart`
- `uswds_screen.dart`
- `workflow_designer_screen.dart`

## Asset audit — all clean

After the quick-task-2 fix, only **one** `Image.asset(...)` call remains
in the dev catalog:

- `scheduler_screen.dart:303` references
  `'lib/dev_app/_assets/trades_react_reference/qa-admin-scheduler.png'`
  which **exists** at that path and is correctly registered in
  `pubspec.yaml:26`.

No orphan asset references. The seven assets present in
`lib/dev_app/_assets/trades_react_reference/`
(`README.md`, `desktop-customer-detail.png`,
`mobile-forefront-team-expanded.png`, `mobile-forefront.png`,
`mobile-projects.png`, `qa-admin-forefront.png`,
`qa-admin-scheduler.png`) are now either (a) referenced correctly
or (b) unused — none are being misrepresented as "parity references"
for unrelated views, which was the second defect just fixed.

## Breakpoint vocabulary note

The codebase currently runs **three** semi-overlapping breakpoint
vocabularies, which is a latent source of inconsistency drift:

1. `EdenResponsive` class (`lib/src/utils/responsive.dart`):
   `mobileMax 768 / tabletMax 1024 / desktopMax 1280`
2. Widget-level parameters across `eden_detail_header`,
   `eden_detail_page_scaffold`, `eden_list_page_scaffold`,
   `eden_role_dashboard_shell`, `eden_phone_input`:
   `narrowBreakpoint 480 / tabletBreakpoint 768`
3. The user's CLAUDE.md mentions canonical `480 / 600 / 840 / 1100 / 1200`
   which does not match either of the above.

Scheduler screen's `< 900` and `EdenScheduler`'s "below 1100pt"
toolbar-collapse comment are additional one-offs.

**Recommendation:** out of scope for this audit — but worth a future
objective to consolidate into a single `EdenBreakpoints` constants file
(probably `480 / 768 / 1100 / 1280` to match the widely-used widget
defaults).
