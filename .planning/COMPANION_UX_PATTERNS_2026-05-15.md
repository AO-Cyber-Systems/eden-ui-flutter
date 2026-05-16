---
title: Companion UX Patterns — Eden Biz
date: 2026-05-15
author: research session (mark + Claude Opus 4.7 1M)
parents:
  - /Users/markemerson/Source/eden-biz/go/.planning/VERTICAL_SKIN_ARCHITECTURE.md
  - /Users/markemerson/Source/eden-libs/eden-ui-flutter/.planning/VERTICAL_COVERAGE_ASSESSMENT_2026-05-15.md
  - /Users/markemerson/Source/eden-libs/eden-ui-flutter/.planning/TRADES_REMAP_DEEP_AUDIT_2026-05-15.md
  - /Users/markemerson/Source/eden-libs/eden-ui-flutter/.planning/ABSORPTION_RESEARCH_2026-05-15.md
siblings:
  - ./COMPANION_B2_SPEC_2026-05-15.md
  - ./COMPANION_USE_CASE_MATRIX_2026-05-15.md
primary_sources_mined:
  - trades/client/src/contexts/UXModeContext.tsx, FieldViewContext.tsx
  - trades/client/src/components/layout/{MobileBottomNav,UXModeToggle}.tsx
  - trades/client/src/components/{FieldViewGate,FieldViewBadge}.tsx
  - trades/client/src/config/routePermissions.ts (15 fieldViewAllowed routes)
  - trades-flutter/lib/features/{mobile_home,field_crew,dispatch,portal}/
  - trades-flutter/lib/features/schedule/presentation/schedule_mobile_view.dart
  - eden-ui-flutter/lib/src/widgets/eden_layout/{eden_mobile_layout,eden_desktop_layout}.dart
  - Wave A primitives at bcf7904 (15 components)
status: read-only research; library is the composition palette
---

# Companion UX Patterns — Eden Biz

> The library remains transport-agnostic (PROJECT.md). Every pattern in this
> doc composes Wave A primitives + existing eden-ui-flutter widgets;
> nothing here ships network or auth code.

---

## 0. Decisions locked through user discussion (2026-05-15)

Six architectural decisions locked with Mark in the inline Q/A session that
followed this doc's generation. These take precedence over any earlier
recommendation in the body text where they conflict.

| # | Decision | Locked rationale |
|---|---|---|
| **A — Mode discrimination** | **Hybrid**: screen-size auto-detect + JWT-claim override + always-on user toggle escape hatch. Default companion at `<600pt` logical width; JWT `app_mode` claim wins when present; toggle widget always visible. | Matches "simple on-the-go" UX target without locking out admins on a phone. Reuses trades-react's validated `UXModeToggle` semantics. |
| **B — Vertical-flavor strategy** | **One companion mode + per-vertical route registry**, BUT vertical variability happens at the **page level**, NOT in the shell or nav structure. | Shell + nav predictability across verticals (good for cross-vertical employees, simpler dev). Page CONTENT can be radically different per vertical (`TradesFieldDispatchPage` ≠ `SalonStylistAppointmentsPage`). Trade-off: consistent shell, vertical-flavored pages. |
| **C — Customer portal auth** | **Same AOID issuer + scope claim split** (`scope: staff.*` vs `scope: portal.*`). Customer portal is a **separate Flutter build target** of `eden-biz-flutter`, NOT a separate auth issuer. | Aligns with `eden-platform-go` PR #19 (merged 2026-05-15) which added `Scopes` claim to platform/auth. One auth surface to maintain; separate front-ends to ship. **Supersedes** the agent's "separate eden-portal-go issuer" recommendation. |
| **D — Offline expectations** | **Three different postures**: admin online-tolerant (optimistic UI + retry); employee companion offline-critical (write queue + reconcile via `EdenOfflineQueueViewer`); customer portal mostly-online with cached read-only fallback on disconnect via `EdenNetworkStatusBar`. | Matches 2026 user expectations: ServiceTitan/Housecall/Jobber set offline-first as field-service baseline; office expects optimistic + retry; customers expect online with clear status. |
| **E — Responsive strategy** | **Three Material 3 tiers locked**: Compact `<600pt`, Medium `600-840pt`, Expanded `≥840pt`. Use `LayoutBuilder.constraints.maxWidth` (logical pt, NOT raw pixels). **Companion mode pins to Compact at ALL widths** — a field user on a 12.9" iPad still wants thumb-reach bottom-nav. | Supersedes the five-breakpoint table in §3 of this doc — see Mark's pixel-resizing pain context. Three breakpoints, three rules: logical pt > raw pixel; mode trumps size for companion; M3 tier names not custom. |
| **F — Customer portal v1 scope** | **Vertical-specific minimum for v1**: pay invoice + see status + message, plus per-vertical minimum (salon = book; trades = approve quote; fuel = see tank + delivery; medical = intake + co-pay; gov = submit + see case). **v3 roadmap = deep market-parity** (MangoMint-equivalent for salon, ServiceTitan-equivalent for trades, etc.). | Ship narrow, validate, expand. v1 ships in 4-6 wk per vertical; v3 takes 6-12 mo per vertical to reach competitive depth. |

### B clarification — what "page-level vertical flavor" means in practice

The companion shell + nav structure is **consistent across verticals**:

| Layer | Cross-vertical? | Example |
|---|---|---|
| Shell (`EdenRoleDashboardShell`) | ✓ Same widget tree | Companion home shell with section slots |
| Nav structure (5-tab bottom-nav, FAB, quick-access grid) | ✓ Same template | Same nav shape regardless of vertical |
| Tile content (what each tab opens) | Per-vertical | "Today's appointments" → salon: appointments list; trades: jobs list; fuel: route stops |
| Page content (the actual screens) | Per-vertical | `TradesFieldDispatchPage` ≠ `SalonStylistAppointmentsPage` ≠ `FuelDriverRoutePage` |

Per-vertical route registry decides which slots populate; the slot CONTENT widget
is per-vertical. This gives verticals radical page UX freedom while preserving
shell + nav predictability.

### E clarification — three rules to avoid past pixel-resizing pain

1. **Use `LayoutBuilder.constraints.maxWidth` (logical pt), not `MediaQuery.size.width` (raw pixel).** Logical pt accounts for system text scale and density.
2. **Three breakpoints, not five.** More breakpoints = more places to break.
3. **Companion mode pins to Compact** regardless of width. The mode trumps the size.

### Open questions deferred from this session

The research agent surfaced 9 open questions in this doc (§ "Open questions
for Mark") + 10 in `COMPANION_B2_SPEC_2026-05-15.md`. Status:
- **A, B, C, D, E, F above** — closed in inline Q/A.
- **Remaining 13 + open agent Qs** — triage in next session before Phase 1 / B2 implementation begins.

---

## 1. Three views model

Eden Biz ships **one Flutter codebase** (`eden-biz/flutter/`) that produces
three operating surfaces via Path α (single binary + mode flag). The same
absorbed trades content drives all three; the difference is which route set
is registered, which JWT issuer authenticates, and which chrome the layout
shell renders.

| Aspect                    | **Admin (back-office)**                                   | **Employee companion (field)**                          | **Customer companion (portal)**                                |
|---------------------------|-----------------------------------------------------------|---------------------------------------------------------|----------------------------------------------------------------|
| Target form factors       | Desktop & web primary; tablet secondary; phone last-resort | Phone primary; tablet secondary; web fallback           | Phone primary; tablet & web acceptable                         |
| Primary screen sizes      | ≥1024pt wide                                              | 390–820pt wide                                          | 390–820pt wide                                                 |
| Gesture model             | Pointer/keyboard primary, touch supported                 | Touch-first; one-thumb reach; large tap targets (≥44pt) | Touch-first; minimal gestures (tap + scroll + pull-to-refresh) |
| Nav model                 | Left sidebar (`EdenDesktopLayout` collapsible drawer + sticky header) | Bottom-anchored nav (`EdenMobileLayout`) — paginated 6-tab strip with submenu sheets | Bottom tab bar (4–5 destinations: Home / Work / Messages / Billing / Account) |
| Auth posture              | Tenant-staff JWT (`business_vertical` claim + RBAC role + `canViewAsDirects`) | Tenant-staff JWT — same issuer as admin; companion-mode is a CHROME variant, not an identity variant | Separate JWT issuer (`/portal/`) — customer identity, NOT tenant-staff identity |
| Online/offline posture    | Online-only acceptable; degraded read-only fallback for last-known data | Offline-CRITICAL — write queue + reconcile; long deadzones expected | Mostly online; degraded fallback (read-only cached balance, no payment) |
| Density                   | High (data-grid first; description-list dense; multi-pane) | Low — single primary action per screen; cards over tables | Low — large hit targets; one decision per screen                |
| Theming                   | Vertical-skinned (`VerticalNavSkin` decorations + color)  | Vertical-skinned + role-skinned (Tech vs Lead vs Dispatcher) | Vertical-skinned + tenant-branded (logo, primary color)         |
| Routes IN scope           | All ~36 trades-flutter folders absorbed                   | The `fieldViewAllowed: true` subset (15 in trades; ~10–20 per vertical) | A 6–8-page portal subset (dashboard, project, billing, messaging, approvals, profile) |
| Routes OUT of scope       | —                                                         | All customizations / settings / audit / accounting / agent-builder / process-builder | Anything internal — employees, fleet, payroll, dispatch         |
| Telemetry boundary        | All events tagged `mode=admin`                            | `mode=field-companion` + role + crew_id                 | `mode=customer-portal` + customer_id (NEVER staff identifiers)  |

The Path α discriminator (admin vs field-companion) is **chrome-only** —
the binary, JWT, and tenant context are identical; only the route registry
and layout shell differ. The customer companion is a **harder boundary**
(separate auth + separate identity model); document it as a SEPARATE
build target later (B2 spec).

---

## 2. Pattern catalog

Each pattern: problem → where it appears → primitives → responsive
behavior → a11y. Cross-vertical unless explicitly noted "trades-only."

### P-01 — Paginated bottom-tab strip with submenu sheets

**Problem.** A field-mode user needs reach to 10–20 routes from a single
hand. A standard 5-destination `BottomNavigationBar` truncates too far;
a hamburger drawer breaks thumb-reach.

**Source.** `trades/client/src/components/layout/MobileBottomNav.tsx`
(1271 LOC). 6 visible tabs per page, paginated with swipe gestures,
left/right chevrons, and dot indicators. Items with submenus open a
bottom sheet above the strip. Active item is highlighted; pagination
auto-jumps to the page containing the active route on navigation
(no reordering — preserves muscle memory).

**Wave A primitives composed.**
- `EdenMobileLayout` (existing `eden_layout/`) — the chrome shell.
- `EdenQuickActionBar` (Wave A) — pattern of horizontally scrollable
  action row inside the submenu sheet for "Customer Sections" / "Inventory
  Sections" etc.
- `EdenNetworkStatusBar` (Wave A) — pinned above the strip when offline.
- `EdenAuthenticatedImage` (Wave A) — used inside submenu rows for
  customer-avatar prefix.

**Responsive.** Phone-width: paginated strip is the primary nav.
Tablet (≥768pt): collapses into `EdenDesktopLayout` rail OR persists
as bottom nav per UX-mode preference. Desktop: hidden entirely.

**A11y.** Each tab announces `Semantics(label, selected, button)`;
pagination dots are buttons with `aria-label="Go to page N"`. Swipe
gesture has keyboard equivalents (Tab + Enter to chevron).

**Trades-react specific (do NOT generalize).** The Customers tab's
inline customer-search + work-location tree (mobile-customer-submenu.png)
is trades-flavored selection state ("I'm working at customer X / location
Y"). Generalize to `EdenContextSelector` only if salon (stylist's chair
of the day), fuel (truck of the day), medical (caseload of the day)
need an equivalent semantic. Hold off until two verticals demand it.

### P-02 — Quick Action FAB ladder

**Problem.** Field user needs ≤3 high-frequency actions (start job,
log time, capture photo) without navigating away from current screen.

**Source.** `trades-flutter/lib/features/mobile_home/.../mobile_ai_fab.dart`
+ `mobile_ai_chat_sheet.dart`. A single primary FAB (gold accent in trades)
opens a bottom sheet of 3–6 quick actions; secondary persistent FAB
(avatar circle) is the user/role switcher.

**Wave A primitives composed.**
- `EdenQuickActionBar` — render the action set inside the sheet.
- Existing `EdenChatBubble` / `EdenMessageInput` — if the sheet is an AI
  chat surface.

**Responsive.** Phone: FAB + bottom-sheet sequence. Tablet: secondary
FAB persists; primary action set may inline into the page header.
Desktop: FAB is replaced by a `EdenCommandPalette` keyboard shortcut.

**A11y.** FAB needs `tooltip` + `Semantics(button, label)`. Sheet
`showModalBottomSheet` already announces correctly.

### P-03 — Quick Access tile grid

**Problem.** Below the today-snapshot ("greeting + appointments"), the
field user needs a launcher grid of vertical-flavored shortcuts: trades
gets Find Parts / Quick Bid / PO Status / Escalate; salon would get
Today's Chair / Walk-In / Tip-Out / Cash-Out; fuel would get Manifest /
Tank Levels / Spill Log / Delivery Confirm.

**Source.** `trades-flutter/lib/features/mobile_home/.../quick_access_grid.dart`
— 3×2 grid; tap → push named route; per-tile accent colors for emphasis
(gold for revenue, red for escalation).

**Wave A primitives composed.**
- `EdenRoleDashboardShell` (Wave A) is the parent surface that hosts
  this grid; the grid itself is a candidate pattern to codify as a
  preset of `EdenQuickActionBar` (taller-tile variant) or its own
  primitive `EdenQuickAccessGrid` if the rendering diverges enough.

**Vertical-flavor mechanism.** The tile set is **VerticalNavSkin-driven**
(see §5). Tile definitions live in
`eden-platform-flutter/lib/src/navigation/skins/<vertical>_skin.dart`;
the grid widget consumes the skin's `quickAccessItems` list.

**Responsive.** Phone: 3×2. Tablet portrait: 4×2. Tablet landscape /
desktop: hidden (the role-dashboard's content surfaces these via
direct navigation).

**A11y.** Each tile is a button with `Semantics(label, hint)`; iconography
must have text label visible (no icon-only).

### P-04 — Card-as-row (mobile data list)

**Problem.** A data-table on phone is unreadable. Field user needs
scannable rows with title + 1–2 metadata lines + status badges +
2–3 inline actions.

**Source.** `trades/client/src/components/ui/mobile-data-list.tsx`.
`MobileDataList` + `MobileDataListItem` + optional `MobileDataGroup`
collapsible header. Same data shape as `MobileDataListItem` props:
title, subtitle, badges, metadata k/v pairs, icon, actions, onClick,
chevron.

**Wave A primitives composed.**
- This is the mobile mode of `eden_data_grid/` (partially exists).
  Surface enhancement: `EdenDataGrid(mode: card)` renders this layout;
  `EdenListPageScaffold` (Wave A) accepts a `mobileMode: card` flag.

**Responsive.** Phone: card-stack. Tablet portrait: 2-up card grid.
Tablet landscape: optional split — card-list left + detail right
(see P-09). Desktop: full data-grid; this pattern is hidden.

**A11y.** Each card is a button if `onClick` is set; chevron is decorative
(no separate tab stop). Metadata k/v pairs use `Semantics` to group.

### P-05 — Swipe-to-action row

**Problem.** Quick approve/dismiss/snooze on inbox-style lists
(maintenance reminders, callbacks, blocked tasks, customer messages,
approval queue items).

**Source.** Not present in trades-react today; trades-flutter has the
ergonomic in Field Notes (delete-on-swipe). Pattern is standard mobile.

**Wave A primitives composed.**
- Built atop `Dismissible` (Flutter material). Library codification:
  `EdenSwipeActionRow` wrapping a card with left/right action sets
  (icon + color + label).
- Composes with `EdenDataGrid(mode: card)` from P-04 — the swipe is
  a row-level wrapper, not a list-level concern.

**Responsive.** Phone: swipe gesture. Tablet/desktop: swipe is hidden;
actions surface as inline icon buttons on hover/focus.

**A11y.** Swipe MUST have an accessible alternative — long-press to
open an actions sheet, or visible "more" icon button. Announce action
in `SemanticsAction.scrollDown` hint.

### P-06 — Pull-to-refresh

**Problem.** Field user has stale data; needs explicit, unambiguous
refresh affordance without navigating away.

**Source.** `trades-flutter/lib/features/portal/.../portal_dashboard_page.dart`
uses Flutter's `RefreshIndicator`. trades-react relies on TanStack Query
invalidation on focus — different model; companion must support pull-to-
refresh explicitly.

**Wave A primitives composed.**
- No new primitive needed. Document the pattern as: every companion
  page using `EdenListPageScaffold` or `EdenDetailPageScaffold` MUST
  wrap its scrollable body in `RefreshIndicator` and expose an
  `onRefresh: Future<void> Function()` prop.

**Responsive.** Phone/tablet: pull-to-refresh. Desktop: a header refresh
button (`EdenIconButton`) is the equivalent.

**A11y.** `RefreshIndicator` has built-in semantics; surface a manual
refresh button for keyboard users.

### P-07 — Offline-queue indicator on actions

**Problem.** A field action (submit inspection, log time, attach photo)
must not block on connectivity. The user needs (a) immediate optimistic
feedback, (b) a clear "queued, will send when online" state, (c) visible
queue depth + sync progress.

**Source.** `trades-flutter/lib/features/field_crew/data/offline_queue_item_model.dart`
+ `offline_queue_page.dart`. Pattern: optimistic write → indicator badge
on the action button → list view of queued items → retry/discard per item.

**Wave A primitives composed.**
- `EdenOfflineQueueViewer` (Wave A) — the list view.
- `EdenNetworkStatusBar` (Wave A) — pinned bar at top.
- New: `EdenOfflineQueueBadge` (small counter pill) — render on any
  action button; consumes a queue-depth provider from the consumer app
  (transport-agnostic — accepts an `int? queuedCount` prop).
- Existing `EdenBadge` — base for the counter pill.

**Responsive.** Same on all form factors. Desktop renders the queue
viewer in a side rail instead of full-screen.

**A11y.** Badge value MUST be announced ("3 actions queued"). Queue
viewer rows have accessible retry/discard buttons.

### P-08 — Full-screen photo + signature capture flow

**Problem.** Field photo or customer signature requires the entire
viewport — landscape preferred, modal — and a clear "save" / "retake" /
"cancel" set.

**Source.** `trades-flutter/lib/features/field_crew/.../photo_capture_page.dart`,
`signature_capture_page.dart`. Existing primitive `eden_signature_pad.dart`
is the brush surface — the FLOW around it (clauses, witness signature
slot, audit metadata) is what's missing.

**Wave A primitives composed.**
- `EdenConsentFlow` (Wave A) — for signature with explicit clauses ladder.
- New page-level patterns codified post-Wave A:
  - `EdenSignatureCapturePage` (B-T-A2 in deep audit)
  - `EdenPhotoCapturePage` (B-T-A5)

**Responsive.** Phone: forced landscape modal. Tablet: same. Desktop:
inline panel within the parent page (no forced rotation).

**A11y.** Signature pad has a "draw signature" Semantics hint; clauses
ladder is keyboard-traversable; witness signature slot is a separate
focusable region.

### P-09 — Master/detail split (tablet) ⇄ push-nav (phone)

**Problem.** On tablet, splitting list left + detail right doubles
information density without forcing a back-tap. On phone, the same
content forces full-screen push-nav.

**Source.** Standard responsive pattern; trades-react implements it via
breakpoint-aware page composition. trades-flutter currently does NOT
implement consistently — gap.

**Wave A primitives composed.**
- `EdenListPageScaffold` accepts a `detailBuilder: Widget? Function(item)`
  optional prop. On phone, tapping a list item pushes a new route
  rendering the detail; on tablet, the detail renders in a 1/3 right
  panel.
- `EdenDetailPageScaffold` is the page used in both cases — the
  difference is whether it's a route or a panel.

**Responsive.** Phone <768pt: push-nav. Tablet portrait 768–1024pt:
optional split (consumer opt-in via scaffold prop). Tablet landscape +
desktop ≥1024pt: split is default.

**A11y.** When in split mode, list and detail are two separate
landmarks; focus moves into the detail region after selection.

### P-10 — Sticky bottom action bar

**Problem.** Long forms (intake, inspection, change-order) put the
primary action (Submit, Save) below the fold; the user has to scroll
to find it.

**Source.** `trades/client/src/components/QuickActionBar.tsx` and the
"pin / chat / call / print" row visible in mobile-customer-detail.png.

**Wave A primitives composed.**
- `EdenQuickActionBar` (Wave A) — the strip.
- The pattern: `EdenDetailPageScaffold` accepts a `footer: Widget?` prop
  rendered as a `BottomAppBar` with safe-area insets.

**Responsive.** Phone: full-width sticky bar. Tablet: floating action
panel docked bottom-right. Desktop: header-right action group instead
(no bottom bar).

**A11y.** The bar is in the page's primary tab order, BEFORE the
bottom-tab-strip (`P-01`). Each action button has a visible label.

### P-11 — Mode-toggle escape hatch

**Problem.** A manager-tier user is previewing the field view to debug
a tech's issue; they need an unmissable "exit" button. A tablet user
who landed in mobile chrome by viewport-detect needs the equivalent.

**Source.** `trades/client/src/components/FieldViewGate.tsx` (when a
forbidden route is hit) + `UXModeToggle.tsx` (bottom-pinned 3-state
toggle: mobile / desktop / auto).

**Wave A primitives composed.**
- Existing `eden_button.dart`, `eden_card.dart`, `eden_alert.dart`.
- New: `EdenUxModeToggle` (donor: trades-react `UXModeToggle.tsx`) — a
  3-state toggle pinned to the bottom of the viewport on touch devices.
  Trades has a `FieldViewBadge.tsx` companion showing "Field View" in
  the header. Codify both as one primitive: `EdenModeToggle({modes,
  activeMode, onChange, badgeText?})`.
- New: `EdenModeGate` — the gate page shown when a route isn't allowed
  in the current mode (donor: `FieldViewGate.tsx`). Library doesn't
  ship the allowlist itself — that's consumer concern — but ships
  the page.

**Responsive.** All form factors.

**A11y.** Toggle has `Semantics(label, selected)` per option; gate page
is keyboard-focusable with a primary action button.

### P-12 — Today-snapshot card

**Problem.** Open the app → answer "what is the user doing right now?"
in under 2 seconds. Greeting, alert banner (if any), project-of-the-day
card, today's appointments, quick-access grid.

**Source.** `trades-flutter/lib/features/mobile_home/.../mobile_home_page.dart`.

**Wave A primitives composed.**
- `EdenRoleDashboardShell` (Wave A) — the parent shell.
- `EdenIntakeForm` is NOT relevant here (this is read-only summary).
- Existing `eden_stat_card.dart` for the snapshot stats.
- Existing `eden_card.dart` + AI `eden_insight_card` (donation pending
  from trades-flutter) for the appointment cards.

**Vertical flavor.** Trades: appointments + project truck assignment.
Salon: chair schedule for the day + first/last service + open slots.
Fuel: route + manifest + tank levels + ETA to first stop. Medical:
caseload + first/last visit + open documentation. Mechanism: the
shell consumes a per-vertical `TodaySnapshotConfig` from the
`VerticalNavSkin`.

**Responsive.** Phone: vertical stack. Tablet portrait: 2-column.
Desktop: this is the role-dashboard wide variant — see Wave A
`EdenRoleDashboardShell`.

**A11y.** Greeting is the page's `h1`; each section has a `h2`.

### P-13 — Onboarding tour overlay (showcase)

**Problem.** First-launch field user needs to understand the
companion's restricted route set, the offline indicator, the
mode-toggle, and the primary action surface.

**Source.** trades-flutter pubspec includes `showcaseview`; eden-ui-flutter
already ships `EdenAppTourOverlay` (Wave A).

**Wave A primitives composed.**
- `EdenAppTourOverlay` — the engine.
- `EdenAppTourOverlay` is fed a vertical-flavored tour script
  (`VerticalNavSkin.companionTour`) — same skin mechanism as P-03 / P-12.

**Responsive.** Same on all form factors.

**A11y.** Each tour step has `Semantics(liveRegion)` to announce on
appearance; users can dismiss with Escape.

### P-14 — Approval / consent flow

**Problem.** Field signature for inspection acceptance; portal
quote-approval by customer; consent-to-treatment for medical; consent-
to-search for gov caseworker; W9/insurance attestation for subcontractor.

**Source.** Existing `eden_signature_pad.dart`. The flow shape is
identical across verticals; only the clause text varies.

**Wave A primitives composed.**
- `EdenConsentFlow` (Wave A) — the flow.
- Existing `eden_form_wizard.dart` for the step machinery.
- `EdenAuthenticatedImage` (Wave A) — for tenant-logo on the consent
  header.
- The witness-signature slot reuses `eden_signature_pad` instance #2.

**Responsive.** Phone: full-screen modal. Tablet: 80%-width modal.
Desktop: inline page.

**A11y.** Clauses are individually focusable; the witness slot is
labeled "Witness signature (optional)" or "(required)" by clause config.

### P-15 — Pinned network-status bar

**Problem.** Offline / server-unreachable / pending-changes / conflicts
all need to be visible WITHOUT requiring the user to navigate to a
status page.

**Source.** `trades/client/src/components/layout/MobileBottomNav.tsx`
inline status block (lines 1071–1099) + the standalone
`NetworkStatusIndicator.tsx`.

**Wave A primitives composed.**
- `EdenNetworkStatusBar` (Wave A) — the bar.
- `EdenBadge` — the pending/conflict count pills.

**Responsive.** Phone: top-of-viewport bar (between the chrome header
and the body). Tablet/desktop: same position; less critical (admin is
online-only acceptable per §1).

**A11y.** `Semantics(liveRegion)` so screen readers announce
disconnect/reconnect.

### P-16 — Context-pinned customer/job header

**Problem.** Field user is "currently working at customer X, location Y"
and that context should propagate across schedule, photos, time entry,
notes, signature flows without re-selecting.

**Source.** `MobileBottomNav.tsx` Customers submenu localStorage-backed
selection (`SELECTED_CUSTOMER_KEY` + `SELECTED_LOCATION_KEY` + same-tab
`CustomEvent` dispatch). When customer/location is selected, sub-page
URLs are augmented with `customerId=X`.

**Wave A primitives composed.**
- Not a library primitive — this is application-level state. The
  library contribution is the visual representation: a
  `EdenContextPinHeader` (small bar showing "Working at Emerson, Mark
  → North Garage" with a Clear button) composed of `eden_badge.dart`,
  `eden_button.dart`.

**Responsive.** Phone: sub-header above the page body. Tablet/desktop:
sidebar pin or breadcrumb.

**A11y.** The pin is announced as "Context: customer X, location Y";
the clear button is "Clear context."

### P-17 — Live GPS / geofence status indicator

**Problem.** Check-in requires GPS quality verification: high accuracy
within geofence → green; moderate → yellow; poor → red; off → blocked.

**Source.** `trades-flutter/lib/features/field_crew/.../check_in_page.dart`
uses `EdenBadge` + ad-hoc colored dot + `EdenDescriptionList` for
coordinate display.

**Wave A primitives composed.**
- Existing `EdenBadge` (success/warning/danger variants).
- `EdenMapPreview` (Wave A) — for the geofence visualization.
- New (codify): `EdenGpsStatusIndicator` — three-state pill
  + accuracy meters + lat/lng monospace. Trades-flavored but useful
  for fuel-truck (route adherence), medical home-visit (verify visit
  occurred at patient address), gov field inspection (chain-of-
  custody verification of inspection location). PROMOTE TO WAVE B
  cross-vertical primitive (multiple verticals need it).

**Responsive.** Phone: full pill. Tablet/desktop: small inline badge.

**A11y.** `Semantics(label: "GPS signal: high, accuracy 5 meters,
within geofence")` so a low-vision user can verify before
checking in.

### P-18 — Insight-card ladder (AI suggestions inline)

**Problem.** Below an appointment / job card, the field user wants
contextual AI hints: "material arriving 2pm" / "check equipment history
first" / "weather may delay outdoor work."

**Source.** `trades-flutter/lib/features/mobile_home/.../mobile_insight_card.dart`.

**Wave A primitives composed.**
- New (donation from trades-flutter): `EdenInsightCard` — small tinted
  card with icon + text + dismiss. Already flagged in
  ABSORPTION_RESEARCH §2.4 as a Wave-4 port.
- Existing `eden_suggestion_block.dart` is the wider variant.

**Responsive.** Phone: stacked below parent card. Tablet/desktop:
right-side rail.

**A11y.** Each insight card has a dismiss button; insight text is the
card's accessible name.

### P-19 — Vertical-flavored portal home

**Problem.** Customer companion home page differs per vertical
(trades = projects + invoices; salon = upcoming appointment + book
again + tip; fuel = delivery schedule + tank level + pay; medical =
upcoming visit + bill + telehealth join; retail = order status +
loyalty + reorder).

**Source.** `trades-flutter/lib/features/portal/.../portal_dashboard_page.dart`
(reasonable trades baseline: `EdenStatCard` row + upcoming appts +
projects list + overdue-invoice alert; bottom nav with Home / Projects
/ Messages / Billing).

**Wave A primitives composed.**
- `EdenListPageScaffold` (Wave A) — the parent.
- `EdenRoleDashboardShell` (Wave A) — the configurable shell consumed
  via a customer-flavored skin (small reuse: customer-portal IS a role
  shell, just for `role=customer`).
- Existing `eden_stat_card`, `eden_card`, `eden_badge`.
- `EdenMembershipTierBadge` (Wave A) for loyalty / clearance variants.
- `EdenAuthenticatedImage` (Wave A) — tenant logo / project photos.

**Responsive.** Phone: stack. Tablet portrait: 2-column. Desktop:
3-column with sidebar.

**A11y.** Customer portal is the surface most-likely to be audited for
WCAG / Section 508. Every component MUST meet AA contrast and full
keyboard reachability — this is a HARD constraint per Wave C overlay
for any tenant in a regulated vertical.

### P-20 — Vertical-flavored intake flow

**Problem.** First-time customer / employee / case-subject completes
a vertical-specific intake: trades = new-customer + property
attributes; salon = client preferences + allergies; medical =
HIPAA + medications + insurance; legal = matter intake + conflict
check; gov = case intake + identity verification.

**Source.** Not present in trades today (trades is mature on the
opposite — admin-creates-customer). Pattern is locked Wave A
`EdenIntakeForm`.

**Wave A primitives composed.**
- `EdenIntakeForm` (Wave A) — branching, save-and-resume.
- `EdenConsentFlow` (Wave A) — terminal step of any intake involving
  signature.
- `EdenPhoneInput` (Wave A) — universal contact field.
- `EdenAddressInput` (Wave A) — universal address field.

**Responsive.** Phone: linear vertical. Tablet: same with wider form
fields. Desktop: 2-column form within an `EdenDetailPageScaffold`.

**A11y.** Validation summary at the top is a `liveRegion`; each field
has explicit label + hint + error.

---

## 3. Responsive strategy

### Three flavors

| Flavor              | Definition                                                                  | When to use                                                                                |
|---------------------|-----------------------------------------------------------------------------|--------------------------------------------------------------------------------------------|
| **Responsive**      | Single widget tree; CSS/Flutter-equivalent rules flex layout                | Forms (P-20), cards (P-04), badges, indicators (P-15)                                      |
| **Adaptive**        | Different widget trees per breakpoint                                       | Nav chrome (P-01 mobile vs desktop sidebar), photo capture (P-08 modal vs panel)            |
| **Hybrid**          | Shared body widget tree + breakpoint-aware chrome wrapper                   | Page scaffolds (Wave A `EdenListPageScaffold`, `EdenDetailPageScaffold`), master/detail (P-09) |

### Breakpoints (locked)

Track Tailwind/Material conventions so the consuming `eden-biz-flutter`
matches the same numbers in its `lib/shared/responsive.dart`:

| Token       | Min width (logical pt) | Form factor expectation         |
|-------------|------------------------|---------------------------------|
| `phoneSm`   | 320                    | Old iPhone / Android in portrait |
| `phone`     | 390                    | iPhone 14/15 portrait — the iPhone-narrow constraint per eden-ui-flutter PROJECT.md |
| `tablet`    | 768                    | iPad portrait                    |
| `tabletLg`  | 1024                   | iPad landscape / small laptop    |
| `desktop`   | 1280                   | Standard laptop                  |
| `desktopXl` | 1536                   | External monitor                 |

trades-react today uses `TABLET_BREAKPOINT = 768` (UXModeContext) and
`TABLET_BREAKPOINT_PX = 1024` (FieldViewContext). The two breakpoints
serve different decisions:
- **768pt**: switch nav chrome from bottom-tab to sidebar.
- **1024pt**: stop auto-engaging field-view; treat as full-desktop.

Library convention: nav-chrome decision is at the `tablet` (768pt)
breakpoint; auto-field-view decision is at `tabletLg` (1024pt).

### How nav chrome differs across breakpoints

| Breakpoint  | Nav surface                                                                              | Mode-toggle visibility (P-11) |
|-------------|------------------------------------------------------------------------------------------|-------------------------------|
| <390pt      | `EdenMobileLayout` bottom-paginated strip (P-01)                                          | Hidden (no escape needed — only mobile chrome exists at this size) |
| 390–767pt   | `EdenMobileLayout` bottom-paginated strip (P-01) + maybe persistent FAB (P-02)            | Visible (touch device — user may want desktop chrome) |
| 768–1023pt  | `EdenMobileLayout` OR `EdenDesktopLayout` based on `UXMode` preference + touch detection  | Visible (Touch tablet → can flip either way) |
| 1024–1279pt | `EdenDesktopLayout` collapsible sidebar; bottom-tab hidden                                | Hidden unless `fieldViewActive` (manager preview) |
| ≥1280pt     | `EdenDesktopLayout` expanded sidebar + sticky header                                       | Hidden unless `fieldViewActive` (manager preview) |

---

## 4. Companion-mode-vs-admin discrimination (Path α)

Trades-react today uses **two layered mechanisms** that produce the
companion-view illusion on a single binary:

1. **UXMode** (`UXModeContext.tsx`) — `mobile | desktop | auto`. Persisted
   to `localStorage`. Drives nav chrome (sidebar vs bottom-tab).
2. **FieldView** (`FieldViewContext.tsx`) — boolean overlay
   (`fieldViewActive`). Persisted to `sessionStorage`. Drives route
   filtering (only `fieldViewAllowed: true` routes are reachable) AND
   forces `effectiveMode = mobile` regardless of UXMode preference.

The combination behaves like:
- Phone-sized viewport → auto-engages FieldView → mobile chrome + field
  route subset.
- Tablet docked to monitor → desktop chrome + full route set; manual
  toggle if user wants field preview.
- Manager-tier user on mobile → field route subset by default; toggle
  off if they need full admin route access.

For Eden Biz Path α, we need to **collapse these into ONE concept**:
`AppMode = admin | fieldCompanion`. Customer companion is a separate
build target with its own auth issuer (NOT a mode flag on the staff
build).

### Options for the discrimination signal

| Option                                        | Mechanism                                                                                                          | Pros                                                                                       | Cons                                                                                                    |
|-----------------------------------------------|--------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------|
| **(a) Screen-size auto-detect at startup**    | Read `MediaQuery.of(context).size.width` on first frame; if <1024pt, default `AppMode = fieldCompanion`            | Zero user friction; matches trades-react current behavior (FieldViewContext line 99)        | Tablet-docked-to-monitor edge case; user must know about the mode-toggle to undo                        |
| **(b) JWT `app_mode` claim**                  | Backend issues different JWTs for "field-companion-built apps" vs "admin-built apps"; client trusts claim          | Hard boundary; auditable; lets backend cap RBAC tighter for field tokens                    | Requires backend support; loses the "same login, dual-mode" convenience trades-react has today          |
| **(c) First-launch picker**                   | On first cold launch, show "I'm a tech in the field" vs "I'm in the office" radio; persist in `SharedPreferences` | Explicit; respects user intent                                                              | Friction on first launch; users pick once and the answer goes stale                                     |
| **(d) URL subdomain / Dart-define**           | `app.eden-biz.com` vs `field.eden-biz.com`; build flag `--dart-define=APP_MODE=field-companion`                    | Hard boundary at build time; perfect for App Store separation                              | Requires multiple build targets; doesn't help web (same binary loads either)                            |
| **(e) HYBRID (a) + (c) + manual toggle (P-11)** | Auto-detect at startup; offer first-launch picker only if ambiguous (tablet 768–1023pt); always show mode-toggle | Matches trades-react; preserves "same login dual-mode"; tablet edge case has explicit fallback | Requires both detection + picker code paths; more state to test                                         |

### Recommendation: HYBRID (a) + (c) + manual toggle (P-11)

Rationale:
1. **Preserve the dual-mode behavior trades-react already validated.**
   Managers debugging a tech's issue need the toggle. Auto-detection
   at startup matches FieldViewContext's `isTabletOrNarrower()` default.
2. **JWT claim (b) is too rigid** for the multi-vertical use case where
   a small-shop salon owner is both admin AND the only field worker;
   they need to flip between modes per-task.
3. **Subdomain / dart-define (d) IS valuable BUT for the customer
   companion**, NOT employee companion. Lock that there.
4. **First-launch picker (c)** kicks in ONLY in the tablet 768–1023pt
   ambiguous zone — phone is unambiguous mobile, ≥1024pt is unambiguous
   desktop.
5. Mode-toggle (P-11) is the always-available escape — exactly as
   trades-react ships today.

Concrete signal:
```
AppMode resolveAppMode({
  required Size viewport,
  required SharedPreferences prefs,
  required JwtClaims claims,
}) {
  // Hard override from JWT (Wave C / FedRAMP scenarios where backend wants control)
  if (claims.appMode != null) return claims.appMode!;
  // Persisted user choice from picker or toggle
  if (prefs.getString('app_mode') case final v?) return AppMode.values.byName(v);
  // Default by viewport
  if (viewport.width < 768) return AppMode.fieldCompanion;
  if (viewport.width >= 1024) return AppMode.admin;
  // Ambiguous tablet zone — show first-launch picker
  return AppMode.askUser;
}
```

The library contribution: a `EdenAppModePicker` widget (donation from
trades-react `UXModeToggle.tsx` patterns) + the existing `EdenModeGate`
(donation from `FieldViewGate.tsx`).

---

## 5. Vertical-flavor mechanism (skinning the same companion mode)

Per ABSORPTION_RESEARCH locked Q3: `eden-platform-flutter` grows a
`VerticalNavSkin` interface; trades is the first implementation. The
skin produces nav decoration + tour script + quick-access tiles +
copy strings for ONE vertical.

For companion-mode patterns above, the skin extends to cover companion-
specific items:

```dart
// eden-platform-flutter/lib/src/navigation/vertical_nav_skin.dart
abstract class VerticalNavSkin {
  String get verticalId; // 'trades-hvac' | 'salon-spa' | 'fuel-delivery' | ...

  // Admin nav decoration (existing scope)
  List<NavGroup> get adminNavGroups;
  Map<String, IconData> get routeIcons;
  Map<String, String> get routeLabels;

  // Companion-mode additions (NEW scope per this doc)
  List<NavGroup> get companionNavGroups; // The field-view allowlist equivalent
  List<QuickAccessItem> get companionQuickAccessTiles; // P-03
  TodaySnapshotConfig get companionTodaySnapshot; // P-12
  List<TourStep> get companionTour; // P-13
  PortalConfig get customerPortalConfig; // P-19 — drives portal tabs/cards

  // Theming
  ColorScheme get colorScheme;
  String get appNameDisplay;
}
```

Per-vertical packages register skins at app boot:

```dart
// eden-biz/flutter/lib/main.dart
final tenantVertical = jwtClaims.businessVertical; // from JWT
final skin = VerticalNavSkinRegistry.resolve(tenantVertical);
// skin then drives nav, dashboard shells, portal config
```

**The skin is a runtime selection, not a build flag.** Same binary
serves trades-hvac, salon-spa, fuel-delivery, medical, retail, legal,
gov tenants. The build flag (Path α) selects only mode (admin vs
field-companion), not vertical. This keeps the App-Store footprint
small while letting any tenant onboard via vertical-preset seeding.

**Where to draw the skin boundary:** the library (`eden-ui-flutter`)
ships PRIMITIVES. The platform (`eden-platform-flutter`) ships the
`VerticalNavSkin` interface + registry. The verticals (`eden-biz/
flutter/lib/features/<vertical>/`) ship their skin implementations.
None of this work touches library code other than the patterns this
doc requires.

---

## 6. Offline + connectivity model

Per-view posture (from §1 reiterated as engineering contracts):

| View                  | Connectivity contract                                                                                     | Primitives engaged                                   |
|-----------------------|-----------------------------------------------------------------------------------------------------------|------------------------------------------------------|
| Admin                 | Online required. Degraded fallback = read-only cached last-known data with prominent stale banner.        | `EdenNetworkStatusBar` (Wave A); `EdenAlert.warning` for stale-data banner |
| Employee companion    | Offline-first. Write queue + reconcile. Conflict resolution UX present. Long deadzones (1+ day) expected. | `EdenNetworkStatusBar`, `EdenOfflineQueueViewer` (Wave A); `EdenOfflineQueueBadge` (new); P-07 pattern; conflict resolution = `EdenAlert.warning` + per-item retry/discard |
| Customer companion    | Online preferred; degraded read-only fallback. Payments + signature DEFER if offline; cannot be queued (legal/financial integrity). | `EdenNetworkStatusBar`; `EdenAlert.danger` for "payment requires connection" |

**Library contribution:** the three primitives above. The CONSUMERS
own the actual queue persistence, retry policy, and conflict
resolution — those involve transport (forbidden in eden-ui-flutter).

**Where the trades-flutter `field_crew/data/offline_queue_item_model.dart`
pattern lands:** in `eden-biz/flutter/lib/features/companion/offline/`
as the consumer impl that feeds queue-depth + queued-items to
`EdenOfflineQueueViewer` and `EdenOfflineQueueBadge`.

---

## 7. Open questions for Mark

These need decisions before B2 spec (`COMPANION_B2_SPEC_2026-05-15.md`)
or Wave B/D planning can lock.

### Q1 — Customer companion: separate binary or part of the same?

Per VERTICAL_SKIN_ARCHITECTURE.md §1, customer portal is third-listed
alongside admin + employee companion. The doc shows it as the existing
Templ-served web portal. trades-flutter has a Flutter `portal/` feature
folder with login + dashboard + billing + messaging + project detail.

**Question.** Does the customer portal ship as:
- (i) Same Flutter binary, customer-mode flag + customer JWT → unifies
  codebase but mixes employee + customer auth contexts in one app shell.
- (ii) Separate Flutter binary (`eden-biz/customer-portal/`) → cleaner
  auth boundary; doubles maintenance.
- (iii) Templ + web only (status quo) → no Flutter customer portal;
  trades-flutter `portal/` is archived.

Recommendation tentatively (ii) — separate binary; preserves trades-
flutter portal investment; clean App Store separation; clear auth
boundary. Awaiting confirmation.

### Q2 — Path α mode-toggle: who can flip?

trades-react gates the FieldView toggle on `canViewAsDirects`
(manager-tier permission). A bare tech cannot toggle OUT of field view
because trades-react auto-engages it for them and they have no
permission to escape.

**Question.** In Eden Biz, does any staff role flip between admin and
field-companion freely, or is the mode pegged to role (manager toggles,
field crew is stuck in companion)?

Recommendation tentatively: free toggle for all staff on touch devices
(per UXModeToggle's `canToggleUX` gating logic); managers also get the
`FieldView` preview lens. Pegging to role creates the "field tech
stranded in field view with no way to reach payroll setup" UX dead-end.

### Q3 — VerticalNavSkin packaging: where do skins LIVE?

Three options:
- (a) Skins live in `eden-platform-flutter/lib/src/navigation/skins/`
  (one place; cross-app reusable).
- (b) Skins live in `eden-biz/flutter/lib/features/<vertical>/skin.dart`
  (per-vertical feature folder; co-located with vertical features).
- (c) Skins live in `eden-libs/eden-vertical-skins/` (new sibling
  package; importable by any app).

Recommendation: (a) for now, matching ABSORPTION_RESEARCH Q3 locked
decision. Re-evaluate if a non-biz app (investor portal, customer
portal binary) needs different skins for the SAME vertical.

### Q4 — Companion route allowlist: declarative or imperative?

trades-react has a declarative `routePermissions.ts` with
`fieldViewAllowed: true` flags per-route. Flutter `go_router` doesn't
have an equivalent built-in.

**Question.** Should the library ship a `EdenCompanionRouteRegistry`
helper, or is this purely consumer concern?

Recommendation: consumer concern. The library ships `EdenModeGate`
(P-11) — the page shown when a route is forbidden in the current mode.
The REGISTRY is in `eden-biz/flutter/lib/router.dart` as a filter step
in the `go_router` setup. Trade-off: less library convenience, but
keeps eden-ui-flutter transport-agnostic per PROJECT.md.

### Q5 — Customer companion auth: where does it terminate?

Customer portal users authenticate via a SEPARATE JWT issuer (per §1).
- (i) Reuse `eden-platform-go` issuer with a `customer_role` claim.
- (ii) Separate microservice (`/portal-auth/`) issuing customer-scoped
  JWTs.
- (iii) OAuth/OIDC bridge for customer SSO from third-party providers
  (Google/Apple Sign-in).

Recommendation deferred to backend planning. Library impact only: the
customer portal binary's `EdenLoginPage` must support per-tenant branding
(logo, primary color) — already covered by `EdenAuthenticatedImage`
(Wave A) + theme.

### Q6 — Trades-react patterns marked "specific" — keep specific?

Three patterns above are flagged trades-specific:
- P-01 inline customer-search + work-location tree (mobile-customer-submenu.png).
- P-17 GPS / geofence status indicator.
- The Customers-tab localStorage-backed context selector (P-16).

**Question.** Generalize each now (so Wave B includes them), or wait
until a second vertical actually needs each?

Recommendation: generalize **P-17** now (multiple verticals confirm need
— see fuel / medical / gov use cases in §2 P-17 entry). Defer P-01
customer-search-tree and P-16 context selector until salon-spa
implementation surfaces a parallel need.

### Q7 — Sticky bottom action bar (P-10) vs FAB (P-02): which wins on phone?

Both compete for the same screen real-estate. trades-flutter's mobile_home
ships both: FAB top-right of bottom area, sticky avatar FAB below. The
trades-react QuickActionBar is the bar; FAB doesn't exist there.

**Question.** Codify the rule: "FAB for cross-page actions (AI chat, new
item); sticky bar for in-page primary action (Submit, Save)"?

Recommendation: yes — that's the rule. Document on each Wave A
primitive's contract: `EdenDetailPageScaffold` accepts `footer:` (sticky
bar); `EdenRoleDashboardShell` accepts `floatingAction:` (FAB).

### Q8 — Onboarding tour: who writes the script?

`EdenAppTourOverlay` (Wave A) is the engine; the script comes from
`VerticalNavSkin.companionTour`. Who maintains the script per vertical
— is it part of vertical-preset seeding (backend) or per-vertical
package (frontend)?

Recommendation: frontend, in the skin. Tour script is UI; the backend
ships only the data model + feature flags, not UI copy.

### Q9 — Patterns we may have MISSED

Three areas not covered above that may warrant their own pattern entries
once we learn more from salon / fuel / medical vertical implementations:
- **Tipping / cash drawer** (salon, retail, fuel, medical co-pay) — POS
  patterns. Wave B B-R1 EdenPosKeypad + B-S4 EdenTippingSelector. Pattern
  shape will emerge from those builds.
- **Live messaging / chat in the field** (dispatcher ↔ tech, tech ↔
  customer-via-portal). Existing `eden_chat_*` widgets cover the
  surfaces; the integration with field route is a P-01 / P-16 follow-on.
- **Vehicle / equipment state tile** (fleet truck status, salon chair
  status, fuel tank status, retail register status, medical exam-room
  status). Wave B B-T2 EdenCrewDispatchTile is the trades shape;
  generalize for cross-vertical at Wave D consolidation.

---

## 8. Cross-references

- **B2 spec** (build pipeline + mode discrimination lock):
  `./COMPANION_B2_SPEC_2026-05-15.md`
- **Use case matrix** (40+ rows × form-factor / audience / online posture /
  primitives / vertical):
  `./COMPANION_USE_CASE_MATRIX_2026-05-15.md`
- **Parent assessment** (Wave A/B/C scope):
  `./VERTICAL_COVERAGE_ASSESSMENT_2026-05-15.md`
- **Trades remap deep audit** (per-folder remap; sub-systems; donor map):
  `./TRADES_REMAP_DEEP_AUDIT_2026-05-15.md`
- **Skin architecture** (Path α + VerticalNavSkin):
  `/Users/markemerson/Source/eden-biz/go/.planning/VERTICAL_SKIN_ARCHITECTURE.md`
- **Absorption research** (Q1–Q4 locked decisions):
  `./ABSORPTION_RESEARCH_2026-05-15.md`

---

*End of patterns doc. 20 patterns; 9 open questions; library remains
transport-agnostic.*
