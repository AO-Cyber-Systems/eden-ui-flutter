---
title: Companion B2 Spec — Path α Build Target Shape
date: 2026-05-15
author: research session (mark + Claude Opus 4.7 1M)
parents:
  - /Users/markemerson/Source/eden-biz/go/.planning/VERTICAL_SKIN_ARCHITECTURE.md
  - ./COMPANION_UX_PATTERNS_2026-05-15.md
  - ./TRADES_REMAP_DEEP_AUDIT_2026-05-15.md
locked_at: 2026-05-15 by mark; supersedes Q5-deferred decision in deep audit
status: locks the build-target shape; doesn't ship code
---

# Companion B2 Spec — Path α Build Target Shape

> Per `TRADES_REMAP_DEEP_AUDIT_2026-05-15.md` Q5 (locked):
> "Companion mode UX target = simple, on-the-go. Mode-selection mechanism
> deferred to B2 spec time."
>
> **B2 = this doc.** Mechanism locked below. Wave B planning + companion
> route registry implementation in `eden-biz/flutter/` MUST adopt this
> shape.

---

## 1. Locked discrimination mechanism

**Choice: Hybrid auto-detect + first-launch-picker + manual mode-toggle**
(option (e) from `COMPANION_UX_PATTERNS_2026-05-15.md` §4).

### Resolution algorithm (locked)

```dart
enum AppMode { admin, fieldCompanion, askUser }

AppMode resolveAppMode({
  required Size viewport,             // MediaQuery
  required SharedPreferences prefs,   // persisted user choice
  required JwtClaims claims,          // from auth
  required bool isBootstrapBuild,     // dart-define APP_BUILD=field-companion → forces fieldCompanion
}) {
  // 1. Dart-define hard pin (App-Store / Play-Store builds)
  if (isBootstrapBuild) return AppMode.fieldCompanion;

  // 2. JWT claim hard pin (FedRAMP / Wave C — backend may cap a token to field-only)
  if (claims.appMode case final m?) return m;

  // 3. Persisted user choice (manual toggle from P-11 or first-launch picker)
  if (prefs.getString('app_mode') case final v?) {
    return AppMode.values.byName(v);
  }

  // 4. Viewport-driven default
  if (viewport.width < 768) return AppMode.fieldCompanion;
  if (viewport.width >= 1024) return AppMode.admin;

  // 5. Ambiguous tablet zone (768–1023pt) → show picker on cold launch
  return AppMode.askUser;
}
```

### Properties

- **Default-on for phones.** Phone-width users land in field-companion
  chrome on first launch with NO interaction required. Matches
  trades-react `FieldViewContext.tsx:99` (`isTabletOrNarrower()` default).
- **Default-on for desktop.** Wide-screen users land in admin chrome
  with no interaction required.
- **Tablet ambiguity resolved by user.** A one-time first-launch picker
  ("I'm in the field" / "I'm in the office") with a "remember my choice"
  default checked. Result persisted in `SharedPreferences`.
- **Escape hatch always present.** The `EdenModeToggle` widget
  (donation from `trades-react/UXModeToggle.tsx`) is rendered by the
  layout shell on any device where the user can flip — that's any
  touch device or any user whose role permits the alternate chrome.
- **JWT can override.** A FedRAMP-restricted backend can stamp
  `app_mode=fieldCompanion` in the JWT and the client will refuse to
  switch. Out-of-scope for v1; mechanism present in code for Wave C.
- **Build flag can override.** A dedicated companion build target
  (`flutter build --dart-define=APP_BUILD=field-companion`) hard-pins
  the binary to companion mode. Lets us ship a separate App Store
  listing if marketing demands it, without changing the discrimination
  algorithm in code paths.

### Why this mix

Reasoning recap from patterns doc §4:
1. **Phones don't need a picker.** They're unambiguous.
2. **Desktops don't need a picker.** They're unambiguous.
3. **Tablets DO need a picker.** trades-react's auto-engage at <1024pt
   ships some tablet users into mobile chrome when they're docked to
   monitors and would prefer admin.
4. **Managers debugging tech UX need a toggle.** trades-react's
   FieldView lens already proves the value — preserve it.
5. **Build flag is for App Store strategy** (separate listing for
   "Eden Field Crew" app — see §3 below), NOT for default behavior.
6. **JWT claim is for regulated-vertical lockdown** — Wave C.

---

## 2. Build pipeline

### Single binary, runtime mode-flag (Path α — confirmed)

One Flutter codebase under `eden-biz/flutter/` produces ONE binary
(or one per platform: APK, IPA, web bundle, macOS, Linux desktop). The
mode is selected at app boot via the algorithm in §1. Same auth,
same JWT, same tenant context, same Connect transport, same Riverpod
providers.

What differs at runtime by mode:
- **Route registry.** `go_router` is configured with the FULL admin
  route set; a filter step strips routes when the user's resolved
  `AppMode == fieldCompanion` and the route's
  `companionAllowed != true`.
- **Layout shell.** `AppMode.admin` → wrap in `EdenDesktopLayout`
  (sidebar + sticky header). `AppMode.fieldCompanion` → wrap in
  `EdenMobileLayout` (paginated bottom-tab + drawer + FAB).
- **Initial route.** Admin defaults to `/forefront` (per trades-react
  navigation default). Companion defaults to `/mobile-home` (per
  trades-flutter `mobile_home_page.dart`).
- **Theme.** Optionally compact density on admin desktop; spacious
  44pt+ tap targets on companion (per UXModeContext
  `data-field-view="true"` body attribute pattern).
- **Onboarding tour.** P-13 — different tour script per mode (and per
  vertical via VerticalNavSkin).

What's IDENTICAL across modes:
- Auth flow + JWT issuance.
- Tenant context + business_vertical claim.
- Connect client + API calls.
- Riverpod providers + state shape.
- All data shapes / domain models.
- Crash reporting / telemetry (with `mode` tag on every event).

### Build commands

```sh
# Default — discrimination at runtime, no hard pin
flutter build apk
flutter build ipa
flutter build web

# Companion-pinned build (separate App Store listing strategy)
flutter build apk --dart-define=APP_BUILD=field-companion
flutter build ipa --dart-define=APP_BUILD=field-companion

# Admin-pinned build (rare — only if a tenant wants to lock down a kiosk
# to admin-only)
flutter build web --dart-define=APP_BUILD=admin
```

### What gets stripped from companion builds

Tree-shaking is automatic for Flutter; what matters is what gets
**deferred** vs **never registered**. Two-tier strategy:

- **Tier 1: defer.** Route is in the registry but won't be navigated
  to from companion-mode UI. If the user has a deep-link, the
  `EdenModeGate` page (P-11) shows with an "Exit field view" button.
  Binary size includes the page but it's lazy-loaded.
- **Tier 2: dart-define-strip.** When `APP_BUILD=field-companion` is
  set, the route table itself excludes admin-only routes at compile
  time via `if (kFieldCompanionBuild)` guards. Reduces binary size
  ~30–40% for the dedicated-build case.

For v1: stick with Tier 1 (defer; runtime filtering). Tier 2 is a
size-optimization for Wave D after we see a real binary-size problem.

### Route classification

Add a `companionAllowed: bool` field to each `go_router` route's
metadata (mirrors trades-react `routePermissions.ts:fieldViewAllowed`).
Default: `false` (fail-closed — admin routes are not reachable from
companion unless explicitly opted in). Trades-react has 15
`fieldViewAllowed: true` routes today; expect 10–20 per vertical:

| Vertical    | Estimated companion-allowed route count |
|-------------|----------------------------------------|
| Trades      | 15 (matches trades-react today)        |
| Salon       | 8–10 (chair / appointments / clients / sales / tips) |
| Fuel        | 10–12 (route / manifest / tank / delivery / spill log / DOT) |
| Medical     | 12–14 (visits / charts / vitals / consent / messages) |
| Retail      | 6–8 (POS / inventory adjust / orders / customers / barcode) |
| Legal       | 4–6 (matters / billable timer / notes / calendar) |
| Gov         | 8–12 (cases / consent / inspection / chain-of-custody) |

### Hot-reload semantics

When the user flips the mode-toggle:
1. Persist new choice → `SharedPreferences`.
2. Hot-rebuild the layout shell (route registry filter re-runs).
3. If current route is no longer allowed in new mode → navigate to
   the new mode's home route (`/forefront` admin → `/mobile-home`
   companion or vice versa).
4. Tour overlay (P-13) may re-arm if user crosses a threshold for the
   first time.

No full app restart; no re-auth; no Connect-client reset.

---

## 3. App-store posture

### Listing strategy (locked v1)

**Single listing per vertical, dual-mode app.** A trades-HVAC tenant
downloads one app from the App Store; admin staff and field crew BOTH
use it; the mode auto-resolves on their device.

Rationale:
- Avoids duplicating App Store assets / reviews / IAP setup.
- Matches trades-react Tauri-mobile current shape (one Tauri build).
- Single SKU per vertical keeps marketing simple.
- Field crew updates ship at the same cadence as admin updates.

App Store listings (planned, v1):

| Listing                          | Vertical          | Bundle ID                            | Audience                              | Mode at launch       |
|----------------------------------|-------------------|---------------------------------------|---------------------------------------|----------------------|
| Eden Salon                       | salon-spa         | `ai.aocyber.eden.salon`               | Tenant staff (owner + stylists)       | Auto-detect          |
| Eden Field (Trades)              | trades-hvac       | `ai.aocyber.eden.trades`              | Tenant staff (admin + field crew)     | Auto-detect          |
| Eden Fuel                        | fuel-delivery     | `ai.aocyber.eden.fuel`                | Tenant staff (dispatch + drivers)     | Auto-detect          |
| Eden Care                        | medical           | `ai.aocyber.eden.medical`             | Tenant staff (admin + clinical staff) | Auto-detect          |
| Eden Retail                      | retail            | `ai.aocyber.eden.retail`              | Tenant staff (manager + cashier)      | Auto-detect          |
| Eden Legal                       | legal             | `ai.aocyber.eden.legal`               | Tenant staff (attorney + paralegal)   | Auto-detect          |
| Eden Gov                         | government        | `ai.aocyber.eden.gov`                 | Tenant staff (caseworker + admin)     | Auto-detect          |
| **Eden Customer Portal**         | cross-vertical    | `ai.aocyber.eden.customer`            | END-CUSTOMERS of tenants              | Always customer-portal |

### Why per-vertical listings (not one mega-listing)

- App Store search relevance per industry. A salon owner searches "salon
  scheduling app" — Eden Salon is more discoverable than "Eden Biz."
- Different App Store screenshots / promo videos per vertical.
- Different review pipelines (HIPAA-aware reviewer for Eden Care vs
  no PHI considerations for Eden Salon).
- Different IAP / subscription tiers per vertical possible.

### Why a SEPARATE customer-portal listing

- Different audience (end-customers, NOT tenant staff).
- Different auth issuer.
- Different branding (per-tenant; uses `EdenAuthenticatedImage` for
  logo override).
- Different App Store reviewer concerns (customer portal handles
  consumer financial flows; staff app handles business financial flows).
- Per-tenant whitelabeling is plausible; per-tenant whitelabeling of
  the staff app is NOT (Eden is the brand for tenants).

### Icon variants

- Per-vertical icon: distinct color + glyph per vertical (gold gear for
  trades, gold scissors for salon, gold pump for fuel, etc.).
- Mode does NOT change icon. Same icon for admin staff and field crew
  on the same vertical.

### Web posture

- `app.eden-biz.com` — staff app (auto-detect mode).
- `portal.eden-biz.com` — customer portal (separate binary).
- `<tenant>.eden-biz.com` (custom domain) — customer portal with
  tenant branding override.

---

## 4. Auth boundary

### Staff app (admin + field-companion)

- JWT issuer: `eden-platform-go` (existing).
- Claims include: `tenant_id`, `user_id`, `role`, `permissions`,
  `business_vertical`, optionally `app_mode` (FedRAMP override).
- Same login for admin + companion (no separate field-crew login).
- Companion mode does NOT change the JWT; it changes the chrome.
- RBAC enforcement is BACKEND. Field-companion chrome merely HIDES the
  routes the user couldn't reach anyway (route allowlist + permission
  filter both apply).

### Customer portal

- JWT issuer: SEPARATE — `eden-portal-go` (TBD, see Q5 of patterns doc).
- Claims include: `tenant_id`, `customer_id` (NOT `user_id`), portal-
  specific scopes (`portal:read_billing`, `portal:approve_quote`, etc.).
- Customer JWTs CANNOT access staff endpoints. Backend enforces.
- Customer auth flow: email + password OR magic-link OR OAuth/OIDC.
- Per-tenant SSO config possible later (a tenant federates customer
  identity from their own IdP).
- Library impact: `EdenLoginPage` already exists; customer portal binary
  uses its `branding:` prop to render tenant logo via
  `EdenAuthenticatedImage` (Wave A) + tenant-colored theme.

### Token storage

- Staff app: secure storage (iOS Keychain / Android KeyStore).
- Customer portal: same.
- Refresh-token cadence: short-lived access token (15min) + long-lived
  refresh token (30 days); identical pattern for both.

---

## 5. Vertical-companion combinations (prioritized)

Per locked vertical sequencing (mark, 2026-05-15): salon → trades →
fuel → medical → retail → legal → gov.

| Combination                       | Vertical-preset status        | Companion-allowed route count (est.) | Priority for B2 |
|-----------------------------------|-------------------------------|-------------------------------------|-----------------|
| `salon-staff-companion`           | Salon: ~70% there (MP1-MP4)   | 8–10 (chair / appts / clients / sales / tips) | **P0** — drives Wave A validation |
| `trades-field-companion`          | Trades: re-homing in progress | 15 (trades-react `fieldViewAllowed` set) | **P0** — donor source for patterns |
| `fuel-driver-companion`           | Fuel: greenfield              | 10–12 (route / manifest / tank / delivery / spill log / DOT) | P1 |
| `medical-nurse-companion`         | Medical: greenfield (HIPAA)   | 12–14 (visits / charts / vitals / consent) | P2 |
| `medical-clinical-companion`      | Medical: greenfield           | (subset of nurse; provider-flavored) | P2.5 |
| `retail-cashier-companion`        | Retail: greenfield            | 6–8 (POS / inventory / orders) | P3 |
| `retail-manager-companion`        | Retail: greenfield            | (admin-only, no companion-mode) | n/a |
| `legal-attorney-companion`        | Legal: greenfield             | 4–6 (matters / billable timer / notes) | P4 |
| `gov-caseworker-companion`        | Gov: gated by Wave C overlay  | 8–12 (cases / consent / inspection) | P5 — Wave C blocks |

P0 builds (salon + trades) ship first to validate the Path α
mechanism. P1+ builds reuse the patterns and primitives unchanged.

### What "P0" means concretely for B2 spec

For salon AND trades (the two P0 combinations), the B2 spec locks:
1. The companion-allowed route allowlist (declared in `go_router` per
   route).
2. The `VerticalNavSkin.companionNavGroups` for the vertical.
3. The `VerticalNavSkin.companionQuickAccessTiles` for the vertical (P-03).
4. The `VerticalNavSkin.companionTodaySnapshot` for the vertical (P-12).
5. The `VerticalNavSkin.companionTour` for the vertical (P-13).
6. Vertical-flavored copy strings (route labels, button text).

The PATTERNS themselves (P-01 through P-20) are shared cross-vertical;
only the SKIN inputs vary.

---

## 6. Open questions surfaced from drafting B2

### Q-B2-1 — Where does the first-launch picker live?

The first-launch picker page (only shown in ambiguous tablet zone) is
an app-level concern, but the WIDGET is shared. Two options:
- (a) Ship `EdenAppModePicker` in eden-ui-flutter as a library widget;
  consumer-app calls `showDialog` with it.
- (b) Each app composes its own picker from `EdenCard` + `EdenButton`.

Recommendation: (a). The picker is identical in shape across all 8 app
listings; codifying as a primitive prevents drift.

### Q-B2-2 — Mode-toggle visibility rule

trades-react gates `canToggleUX` on `fieldViewActive || isTouchDevice`.
For Eden Biz we generalize:
- Show the toggle when: viewport is in 390–1023pt AND user has touch
  capability, OR `fieldViewActive` lens is engaged (manager preview),
  OR user has manually set a mode via toggle (so they can flip back).
- Hide the toggle when: viewport ≥1024pt AND user has no touch (clear
  desktop) AND no manager-preview lens active.

Lock this rule in `EdenModeToggle.shouldRender(ctx)` static helper.

### Q-B2-3 — Web build mode resolution

`MediaQuery` on web works but a user can resize a browser window. The
resize-event behavior needs locking:
- Trades-react: resize triggers `effectiveMode` recompute (every
  resize, debounced). FieldViewContext only auto-engages on resize if
  user has NO persisted choice.
- Eden Biz lock: same — resize triggers recompute, but ONLY if no
  persisted choice. Once user makes a choice (via picker OR toggle),
  resize doesn't change mode.

### Q-B2-4 — Mode-toggle position on desktop

Desktop with `fieldViewActive` lens engaged (manager preview) needs
the toggle SOMEWHERE — trades-react pins it bottom-of-viewport
(`UXModeToggle.tsx`). For desktop, that conflicts with a sticky
footer (P-10).

Recommendation: when desktop is in lens preview mode, dock the toggle
to the top-right of the chrome header (small icon button + dropdown),
NOT bottom. Library widget `EdenModeToggle` accepts a `position` prop
(`bottom` | `headerRight`).

### Q-B2-5 — Multi-mode IAP / subscription state

If a tenant subscribes to "Eden Salon Pro" tier, does that subscription
state apply to BOTH admin and field-companion modes (same JWT) or are
some features companion-mode-only?

Recommendation: subscription state is on the JWT; companion-mode is
chrome-only; same features per JWT regardless of mode. Edge case:
if backend wants to gate a feature to companion-mode specifically
(e.g., "GPS tracking only enabled when field-companion app is in use"),
that's a backend RBAC + telemetry concern, not a library / mode concern.

### Q-B2-6 — Per-vertical companion icon design

Each per-vertical app has a distinct icon. Mode does NOT change icon
(§3). But: should the companion app present a different launcher icon
on the device when `APP_BUILD=field-companion` (Tier 2 dart-define
build)?

Recommendation: yes, if/when we ever ship a Tier 2 build, the icon
delta becomes the user's signal. For v1 with Tier 1 deferred routing,
icon is identical.

### Q-B2-7 — Tablet "I'm in the office" picker permanence

If a user picks "I'm in the office" on first launch (tablet 768–1023pt),
and later drives to a job site and wants to switch — do they:
- (a) Tap the mode-toggle (P-11) to switch → persists new choice
  forever.
- (b) Long-press the mode-toggle to switch JUST FOR THIS SESSION (not
  persist) — and snap back to "office" next launch.

Recommendation: (a) for v1 (simpler model). Surface (b) later if users
report friction.

### Q-B2-8 — Wave C / FedRAMP companion-mode hardening

When backend issues `app_mode=fieldCompanion` claim (FedRAMP scenario,
hardware-restricted device), the client MUST refuse to flip to admin.
For v1, the `EdenModeToggle.shouldRender(ctx)` helper returns `false`
if the JWT claim is present. Verify with `aocyber-compliance` team
that this is the right enforcement model.

### Q-B2-9 — Splash / loading state during mode resolution

The mode resolution (§1) runs BEFORE the first frame. While SharedPreferences
loads + JWT validates + MediaQuery resolves, the user sees... what?

Recommendation: `EdenSplashPage` (existing widget) is rendered during
async resolution. Time budget: <500ms steady-state; show splash <2s
or escalate to a "loading taking longer than expected" surface (also
`EdenSplashPage` with a `slow` flag).

### Q-B2-10 — Test strategy for Path α

How do we e2e-test that:
- Phone launch → companion mode.
- Desktop launch → admin mode.
- Tablet → picker → choice persists.
- Toggle → re-route to mode home.
- Forbidden deep-link → `EdenModeGate` page.
- Build flag → hard-pinned mode.

Recommendation: `eden-biz/flutter/integration_test/companion_mode/` test
suite using `flutter_test` + viewport overrides. Library-level
`EdenModeToggle` and `EdenModeGate` get widget tests in
`eden-ui-flutter/test/widgets/`.

---

## 7. What this B2 spec DOES NOT lock

Out of scope; deferred to Wave B planning or later objectives:
- The exact 15+ companion-allowed routes per vertical (driven by
  vertical-preset seeding planning).
- The skin's specific tour scripts / quick-access tile sets (writer:
  vertical-implementation engineers, not library).
- Customer portal binary's full feature set (drives a separate
  customer-portal B2 spec later).
- Tier 2 dart-define stripping (size optimization for later).
- Backend `app_mode` JWT claim contract (eden-platform-go team).
- Sublease/multi-vertical tenants (a tenant owning a salon+spa AND
  a fuel-delivery business with one JWT) — defer until a customer
  asks.

---

## 8. Cross-references

- **Patterns** (P-01 through P-20):
  `./COMPANION_UX_PATTERNS_2026-05-15.md`
- **Use case matrix** (per-task companion-mode-in-scope flags):
  `./COMPANION_USE_CASE_MATRIX_2026-05-15.md`
- **Skin architecture** (Path α):
  `/Users/markemerson/Source/eden-biz/go/.planning/VERTICAL_SKIN_ARCHITECTURE.md`
- **Parent assessment** (Wave A scope):
  `./VERTICAL_COVERAGE_ASSESSMENT_2026-05-15.md`
- **Deep audit** (Q5 deferral that this doc resolves):
  `./TRADES_REMAP_DEEP_AUDIT_2026-05-15.md`

---

*End of B2 spec. Path α discrimination mechanism locked: hybrid
auto-detect + first-launch-picker + manual mode-toggle. Single
binary per vertical, dual-mode at runtime. Separate customer-portal
binary with separate auth issuer.*
