---
objective: 016-salon-specific-commerce
kind: ui-lib
work: feature
github_repo: AO-Cyber-Systems/eden-libs
---

# Objective 016 — Salon-Specific Commerce

## Why

Ship the salon-vertical primitives that close the launch-completeness gap surfaced in `.planning/USE_CASES_SALON_2026-05-17.md` (verdict: NOT launch-ready, 16/34 must-launch BLOCKED). After this objective ships, downstream `eden-biz/flutter` salon admin + `eden-biz/mobile` consumer booking flows compose:

1. **Service catalog browsing + booking** — `EdenServiceCatalogTile` is the salon backbone (price + duration + capable staff + customizations); `EdenTimeSlotPicker` is the customer-facing booking widget primitive distinct from admin-side `EdenScheduler`.
2. **Membership + package lifecycle** — `EdenMembershipManager` surfaces tier billing + benefits status; `EdenPackageRedeem` applies multi-visit credits at checkout. Composes existing `EdenMembershipTierBadge` (obj 001-06).
3. **Intake-form authoring** — `EdenIntakeFormBuilder` is the template-authoring counterpart to existing `EdenIntakeForm` (obj 001-10) RUNNER. Drag-to-place field palette + conditional logic; salon owners can build their own consent + intake schemas.
4. **Two-way SMS thread** — `EdenClientSmsThread` is the plain-tenant variant (HIPAA-aware variant deferred to obj 017). Composes existing `EdenMessageBubble` + `EdenMessageInput`.
5. **Staff scheduling + capability matrix** — `EdenStaffSchedule` is the per-week template editor (distinct from `EdenScheduler` day-grid); `EdenStaffCapabilityMatrix` is the staff × service "can perform" toggle grid feeding the booking widget's filter logic.

These six widgets unblock SALON-001, SALON-002, SALON-008, SALON-015, SALON-021, SALON-022, SALON-030, SALON-044, SALON-046, SALON-049, SALON-060 — i.e. **11 of the 16 BLOCKED must-launch use cases** plus tightens 8 of the PARTIAL ones to FULL.

## What ships

Six TRDs across three waves:

| Wave | TRDs | Widgets |
|---|---|---|
| 1 | 016-01, 016-04, 016-05 | EdenServiceCatalogTile · EdenIntakeFormBuilder · EdenClientSmsThread |
| 2 | 016-02, 016-06 | EdenTimeSlotPicker · EdenStaffSchedule + EdenStaffCapabilityMatrix |
| 3 | 016-03 | EdenMembershipManager + EdenPackageRedeem |

## Dependencies

- **Obj 001 EdenMembershipTierBadge (001-06)** — shipped; composed by 016-03.
- **Obj 001 EdenIntakeForm (001-10)** — shipped; 016-04 builder outputs a schema this runner consumes; complementary, not co-modified.
- **Obj 001 EdenFormWizard** — shipped; 016-04 composes for the builder's multi-step authoring flow.
- **Obj 004 EdenScheduler (004-01..16)** — shipped; 016-02 reuses `EdenSchedulerEvent` value class shape for time-slot rendering; 016-06 composes a small `EdenScheduler` for the weekly template preview.
- **Obj 015 (not yet shipped — commerce completer)** — `EdenTippingSelector` would compose into 016-03 membership-billing tipping preview. Plan with graceful fallback: 016-03 uses a private `_TippingFallback` shim when `EdenTippingSelector` is not yet exported.

## Constraints (locked)

- **Theme-profile aware.** Read `EdenThemeProfileScope.of(context)` if present; default to `EdenThemeProfile.commercialWarm`. When `salonVibrant` is later added to the enum, widgets pick up the palette automatically without code changes here.
- **Transport-agnostic.** No Connect/HTTP/Dio. All persistence + send actions surface as callbacks (`onSend`, `onPublish`, `onBook`, `onRedeem`). Consumer wires backends.
- **Generic types.** Value classes don't bind to salon-only fields. `EdenServiceCatalogEntry` works for trades labor catalog, medical procedure catalog, fuel delivery service catalog. `EdenMembership` value class works for trades-maintenance memberships, gym memberships, retail loyalty tiers.
- **iPhone-narrow ≥390pt baseline.** Every widget tested at 390pt; no `RenderFlex overflowed` warnings. Layout collapses (avatar strip wraps, columns stack).
- **TDD strict per user playbook + defaults table (ui-lib, feature).** Test list FIRST per TRD. Hand-built fixtures only (no LLM-generated test data). Outside-in for the page-shape primitives (`EdenMembershipManager`, `EdenStaffSchedule`); inner-out for pure value-class widgets.
- **Salon scope only.** Per the salon use-case doc §1, multi-staff couples bookings (SALON-009), softphone (SALON-031), web-chat embed (SALON-032), cash-drawer close (SALON-053) are deferred to v2 or other objectives.
