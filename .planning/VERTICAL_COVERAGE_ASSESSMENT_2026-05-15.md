# eden-ui-flutter — Vertical Coverage Assessment

**Date:** 2026-05-15
**Author:** assessment session w/ Mark
**Library state:** `AO-Cyber-Systems/eden-libs/eden-ui-flutter` @ `c50bc16` (pulled 2026-05-15) — version `1.0.0-rc.1`, 172 `eden_*.dart` top-level widgets + 11 specialised sub-suites (`approval_queue/`, `barcode_scanner/`, `checklist_builder/`, `conversation_thread/`, `data_grid/`, `eden_diagram/`, `eden_layout/`, `permission_matrix/`, `pull_request_detail/`, `scheduler/`, `support_panel/`, `sync_indicator/`).
**Companion lib audit:** Rails `eden-ui` (149 partials, v0.3.0) confirmed **not in product use** — Eden Biz frontends are all Flutter. Rails lib stays parked. No other Flutter UI libs found.
**Predecessor:** `eden-biz/go/.planning/EDEN_UI_FLUTTER_COMPONENT_OPPORTUNITIES.md` (2026-05-02). This doc extends that analysis to seven verticals (was: trades + eden-biz only).

---

## TL;DR

eden-ui-flutter is **breadth-rich and dev/ops/sec-deep**. It already covers ~75% of the generic CRUD/admin/dashboard surface for any vertical. Where it is **thin** is exactly where verticals diverge: industry-specific transactional primitives (POS keypad, tank gauge, SOAP note, matter timer, classification banner) and a small set of cross-cutting business primitives still missing despite the dev/ops investment (currency display, address+map, e-sign flow, intake-form patterns, list/detail page scaffolds).

**Three buckets of work** to support trades / fuel-delivery / salon-spa / medical / retail / legal / government:

1. **Wave A — cross-vertical fundamentals (8 components, ~3-4 wk).** Unblocks every vertical at once. Includes the long-pending scaffolds + currency + address + e-sign + intake-form patterns the 2026-05-02 doc already flagged.
2. **Wave B — vertical-specific primitives (≈22 components, ~6-8 wk).** Each vertical needs 2-4 industry primitives the library does not have. Tank gauge for fuel; SOAP note for medical; matter timer for legal; etc.
3. **Wave C — government overlay (≈10 components, ~3-4 wk).** Federal compliance UX is a cross-cutting layer atop A+B: classification banners, Section-508 audit primitives, CAC/PIV affordances, audit-log viewer, FOIA workflow card, PHI redaction overlay. This wave is **gating for DHHS/DOD** vertical opt-in.

Total addressable scope: **~40 new or enhanced components**, ~12-16 weeks of focused library work. Highest-leverage start = Wave A (every vertical benefits day 1, and the work is mostly already-identified ports from trades-flutter / eden-biz vendor copies).

---

## 1. What the library is good at today

### 1.1 Token + theme foundation — ✓ solid

`lib/src/tokens/` (colors, spacing, radii, shadows, durations, typography) + a single `eden_theme.dart` gives downstream apps consistent Material 3 tokens. **No gap.**

### 1.2 Layout shell — ✓ adequate, needs scaffolds

`eden_layout/` provides `eden_desktop_layout.dart`, `eden_mobile_layout.dart`, `layout_data.dart`. Good chrome primitives. **Gap:** no page-level scaffolds (list-page-scaffold, detail-page-scaffold) — every consumer app reinvents this. Already flagged as Wave 2 in the 2026-05-02 doc. **Highest-leverage missing primitive in the library.**

### 1.3 Auth + onboarding pages — ✓ shipped

`eden_login_page`, `eden_signup_page`, `eden_forgot_password_page`, `eden_reset_password_page`, `eden_splash_page`, `eden_onboarding_page`, `eden_profile_page`, `eden_settings_page`, `eden_maintenance_page` cover the standard SaaS entry surface. **No gap for commercial verticals.** Government auth (CAC/PIV, MFA-with-hardware-token) needs additive components — see Wave C.

### 1.4 Form + input primitives — ✓ broad

`eden_input`, `eden_select`, `eden_combobox`, `eden_multi_select`, `eden_date_picker`, `eden_quick_date_range`, `eden_toggle`, `eden_rating`, `eden_secret_field`, `eden_search_input`, `eden_form`, `eden_form_wizard`, `eden_rich_text_editor`, `eden_markdown_editor`, `eden_file_upload`, `eden_async_form_scaffold`, `eden_masked_text`, `eden_signature_pad`. **Adequate.** Gaps surface only inside verticals (intake-form pattern, POS keypad, address+map). See §2.

### 1.5 Data display — ✓ broad

`eden_data_table`, `eden_data_grid`, `eden_key_value_table`, `eden_description_list`, `eden_stat_card`, `eden_chart`, `eden_burndown_chart`, `eden_code_frequency_chart`, `eden_contribution_graph`, `eden_pipeline_graph`, `eden_progress_ring`, `eden_progress`, `eden_kanban`, `eden_timeline`, `eden_workflow_stepper`. **Adequate.**

### 1.6 Comms + collaboration — ✓ broad

`eden_chat_bubble`, `eden_message_bubble`, `eden_message_input`, `eden_conversation_thread`, `eden_discussion_thread`, `eden_email_viewer`, `eden_email_row`, `eden_notification_list`, `eden_typing_indicator`, `eden_reaction_bar`, `eden_mention_overlay`, `eden_review_comment`, `eden_review_summary`, `eden_reviewer_list`, `eden_command_palette`. Tilted toward dev-tool comms but the primitives transfer to helpdesk / customer-portal / care-team contexts.

### 1.7 Scheduling — ⚠ partial

`eden_scheduler.dart` supports month/week/day, conflict detection, assignee filtering. **Does NOT yet support** drag-to-reschedule, resource swimlanes (staff-as-column), mobile-optimised gesture variant. Trades-flutter has the full thing (~7,960 LOC). 2026-05-02 doc names this as **Wave 1 — Calendar Port.** Still the right move; salon, medical, trades dispatch, fuel-delivery dispatch all need this.

### 1.8 Dev/Sec/Ops primitives — ✓ overinvested for the question at hand

`eden_terraform_state_card`, `eden_vulnerability_row`, `eden_security_alert`, `eden_certificate_card`, `eden_compliance_badge`, `eden_environment_card`, `eden_feature_flag_row`, `eden_health_check`, `eden_incident_card`, `eden_deployment_timeline`, `eden_branch_selector`, `eden_blame_view`, `eden_diff_viewer`, `eden_pull_request_detail`, `eden_pull_request_row`, `eden_release_card`, `eden_milestone_card`, `eden_epic_card`, `eden_objective_progress`, `eden_plan_viewer`, `eden_value_stream_map`, `eden_workflow_stepper`, `eden_secret_field`, `eden_port_row`, `eden_registry_row`, `eden_service_row`, `eden_request_log`, `eden_job_log`, `eden_terminal_output`, `eden_log_viewer`, `eden_change­log_section`, `eden_env_editor`, `eden_polling_container`, `eden_streaming_indicator`. Excellent for aosentry / aodex / aocyber-compliance / devflow. **Largely unused by business verticals** — but several have second-use leases inside Wave C government overlay (compliance_badge, certificate_card, security_alert, audit-log viewing).

### 1.9 AI surface — ✓ well-stocked, donation pending from trades

Library has: `ai/` subdir, `eden_agent_decision_log`, `eden_agent_run_card`, `eden_streaming_indicator`, `eden_sources_footer`, `eden_suggestion_block`. Trades-flutter has additional pieces (`eden_ai_panel`, `eden_agent_chat`, `eden_insight_card`, `persona_selector`, `persona_switch_proposal`, `ai_insight_slot`, `ai_collapsible_section`) flagged in 2026-05-02 doc as Wave 4 ports. Still the right call.

---

## 2. Vertical-by-vertical gap matrix

Legend: ✓ buildable as-is · ◐ buildable with composition (worth codifying as a pattern) · ✗ missing primitive · ⚠ existing primitive needs enhancement.

| Capability                                             | Trades (HVAC, plumbing) | Fuel Delivery | Salon/Spa | Medical (DHHS-adjacent) | Retail | Legal Services | Gov (DHHS/DOD) |
|--------------------------------------------------------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **Cross-vertical fundamentals**                        |     |     |     |     |     |     |     |
| List-page scaffold (header → filters → grid → drawer)  |  ◐  |  ◐  |  ◐  |  ◐  |  ◐  |  ◐  |  ◐  |
| Detail-page scaffold (header → tabs → side rail)       |  ◐  |  ◐  |  ◐  |  ◐  |  ◐  |  ◐  |  ◐  |
| Currency / money display                               |  ✗  |  ✗  |  ✗  |  ✗  |  ✗  |  ✗  |  ✗  |
| Address input + map preview                            |  ✗  |  ✗  |  ✓  |  ✗  |  ✗  |  ✗  |  ✗  |
| E-sign / consent flow (above signature_pad)            |  ✗  |  ✗  |  ✓  |  ✗  |  ✗  |  ✗  |  ✗  |
| Intake-form / questionnaire pattern                    |  ◐  |  ◐  |  ✗  |  ✗  |  ◐  |  ✗  |  ✗  |
| Phone input (intl. + verify)                           |  ✗  |  ✗  |  ✗  |  ✗  |  ✗  |  ✗  |  ✗  |
| Loyalty / membership tier badge                        |  ✓  |  ◐  |  ✗  |  ✓  |  ✗  |  ✓  |  ✓  |
| **Trades-specific**                                    |     |     |     |     |     |     |     |
| Drag-reschedule resource scheduler (staff swimlanes)   |  ⚠  |  ⚠  |  ⚠  |  ⚠  |  ✓  |  ✓  |  ✓  |
| Job-site photo gallery (before / during / after)       |  ✗  |  ✗  |  ◐  |  ◐  |  ✓  |  ✓  |  ✓  |
| Crew / truck dispatch tile                             |  ✗  |  ✗  |  ✓  |  ✓  |  ✓  |  ✓  |  ✓  |
| Time entry w/ billable indicator                       |  ✗  |  ✗  |  ✓  |  ✓  |  ✓  |  ✗  |  ✓  |
| Work-order card                                        |  ✗  |  ✗  |  ✓  |  ✓  |  ✓  |  ✓  |  ✓  |
| Change-order / approval ladder                         |  ◐  |  ◐  |  ✓  |  ✓  |  ✓  |  ◐  |  ◐  |
| **Fuel-delivery-specific**                             |     |     |     |     |     |     |     |
| Tank gauge / volume meter                              |  ✓  |  ✗  |  ✓  |  ✓  |  ✓  |  ✓  |  ✓  |
| Route + stop list with ETA                             |  ◐  |  ✗  |  ✓  |  ◐  |  ◐  |  ✓  |  ✓  |
| Meter reading entry                                    |  ✓  |  ✗  |  ✓  |  ✓  |  ✓  |  ✓  |  ✓  |
| Hazmat / DOT document viewer                           |  ✓  |  ✗  |  ✓  |  ◐  |  ✓  |  ✓  |  ◐  |
| **Salon/Spa-specific**                                 |     |     |     |     |     |     |     |
| Service catalog tile / staff capability matrix         |  ◐  |  ✓  |  ✗  |  ◐  |  ◐  |  ◐  |  ✓  |
| Time-slot picker (booking widget)                      |  ✓  |  ✓  |  ✗  |  ✗  |  ✓  |  ✗  |  ✓  |
| Gift card / package tile                               |  ✓  |  ✓  |  ✗  |  ✓  |  ✗  |  ✓  |  ✓  |
| Tipping selector                                       |  ◐  |  ◐  |  ✗  |  ✓  |  ✗  |  ✓  |  ✓  |
| **Retail-specific**                                    |     |     |     |     |     |     |     |
| POS keypad / quick-add bar                             |  ✓  |  ✓  |  ✗  |  ✓  |  ✗  |  ✓  |  ✓  |
| Receipt preview (line items + tax/discount)            |  ✗  |  ✗  |  ✗  |  ✓  |  ✗  |  ◐  |  ✓  |
| Inventory adjustment widget                            |  ◐  |  ◐  |  ◐  |  ◐  |  ✗  |  ✓  |  ◐  |
| Stock-level indicator                                  |  ◐  |  ◐  |  ◐  |  ◐  |  ✗  |  ✓  |  ◐  |
| Barcode scanner (have)                                 |  ✓  |  ✓  |  ✓  |  ✓  |  ✓  |  ✓  |  ✓  |
| **Medical-specific**                                   |     |     |     |     |     |     |     |
| SOAP / chart-entry form                                |  ✓  |  ✓  |  ✓  |  ✗  |  ✓  |  ◐  |  ◐  |
| Visit summary card                                     |  ◐  |  ◐  |  ◐  |  ✗  |  ✓  |  ◐  |  ◐  |
| Vitals row / observation strip                         |  ✓  |  ✓  |  ✓  |  ✗  |  ✓  |  ✓  |  ◐  |
| PHI redaction overlay                                  |  ✓  |  ✓  |  ✓  |  ✗  |  ✓  |  ◐  |  ✗  |
| Consent w/ witness signature                           |  ◐  |  ◐  |  ◐  |  ✗  |  ✓  |  ◐  |  ✗  |
| **Legal-services-specific**                            |     |     |     |     |     |     |     |
| Matter / case card                                     |  ◐  |  ◐  |  ◐  |  ◐  |  ✓  |  ✗  |  ◐  |
| Billable-time timer widget                             |  ◐  |  ◐  |  ◐  |  ◐  |  ✓  |  ✗  |  ◐  |
| Document discovery list (Bates-numbered)               |  ✓  |  ✓  |  ✓  |  ✓  |  ✓  |  ✗  |  ◐  |
| Conflict-of-interest check tile                        |  ✓  |  ✓  |  ✓  |  ✓  |  ✓  |  ✗  |  ◐  |
| **Government (DHHS/DOD) overlay**                      |     |     |     |     |     |     |     |
| Classification banner (U / CUI / S / TS)               |  ✓  |  ✓  |  ✓  |  ◐  |  ✓  |  ◐  |  ✗  |
| CAC / PIV auth affordance                              |  ✓  |  ✓  |  ✓  |  ◐  |  ✓  |  ◐  |  ✗  |
| Section-508 / WCAG audit primitives                    |  ⚠  |  ⚠  |  ⚠  |  ⚠  |  ⚠  |  ⚠  |  ✗  |
| Audit-log viewer (user-facing, immutable)              |  ◐  |  ◐  |  ◐  |  ◐  |  ◐  |  ◐  |  ✗  |
| FOIA / records-request workflow card                   |  ✓  |  ✓  |  ✓  |  ◐  |  ✓  |  ◐  |  ✗  |
| Case-file shell (multi-tab regulated dossier)          |  ◐  |  ◐  |  ◐  |  ✗  |  ✓  |  ✗  |  ✗  |

**Reading the matrix:** every column has 2-6 ✗ entries. The diagonal is where the leverage is — most ✗ cells in column N have a ◐ or ✓ in other columns, meaning the missing primitive often unlocks 3+ verticals at once (e.g., POS keypad serves salon/spa + retail + medical co-pay collection + government cashier surfaces).

---

## 3. Recommended waves

### Wave A — Cross-vertical fundamentals (3-4 wk)

Highest leverage; every vertical benefits day 1. Components are either already-flagged ports from trades-flutter / eden-biz vendor or net-new but small.

| # | Component                           | Source                                                                                 | Notes                                                                                                                                              |
|---|--------------------------------------|----------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------|
| A1 | `EdenListPageScaffold`              | Port `trades-flutter/lib/shared/widgets/list_page_scaffold.dart`                       | Header → filters → grid → side drawer. Codifies the pattern every CRUD admin screen reinvents.                                                     |
| A2 | `EdenDetailPageScaffold` + `EdenDetailHeader` | Port `trades-flutter/lib/shared/widgets/detail_view_scaffold.dart` + `detail_header.dart` | Header → tabs → side rail. Same leverage argument as A1.                                                                                            |
| A3 | `EdenCurrencyDisplay`                | Port `trades-flutter/lib/shared/widgets/currency_display.dart`                         | Locale-aware money rendering. Used by invoicing, POS, payroll, expenses, portal payments, fuel pricing, legal billing.                              |
| A4 | `EdenAddressInput` + `EdenMapPreview` | New                                                                                    | Trades dispatch / fuel routing / medical home-visit / salon mobile services all need it. Wraps a pluggable map backend (Mapbox/Google/OSM). |
| A5 | `EdenConsentFlow` (sig + clause acceptance ladder) | New, composes existing `eden_signature_pad` + `eden_form_wizard` | Above the signature pad: explicit-clauses ladder, dated witness signature slot, audit metadata. Medical / legal / government / fuel delivery all need it. |
| A6 | `EdenIntakeForm` (questionnaire pattern) | New, composes `eden_form_wizard`                                                    | Branching, conditional questions, save-and-resume, validation summary. Medical intake, legal client intake, government case intake, salon onboarding.       |
| A7 | `EdenPhoneInput` + verify affordance  | Port from Rails eden-ui `phone_input.html.erb` pattern, new in Flutter                | International format, country picker, SMS-verify button hook. SMS-OTP also needed in Wave C government MFA.                                          |
| A8 | `EdenMembershipTierBadge`             | New                                                                                    | Salon membership, retail loyalty, legal retainer status, gov clearance level (reuse for Wave C with different palette).                              |

### Wave B — Vertical-specific primitives (6-8 wk)

Grouped by vertical for clarity; can ship as 7 parallel mini-objectives (one per vertical).

#### B-trades (≈2-3 wk)
- B-T1 `EdenWorkOrderCard` — title, scheduled window, crew, status pipeline, photo strip. Reused across trades, gov property maintenance, medical facility ops.
- B-T2 `EdenCrewDispatchTile` — crew/truck + ETA + assigned stops, drag target. Reused for fuel and gov fleet.
- B-T3 `EdenJobSitePhotoGallery` — categorised before/during/after with timestamp + GPS. Reused for trades QA, salon style portfolios, medical wound documentation, retail damage claims, gov inspection.
- B-T4 `EdenTimeEntry` — clock-in/out with billable flag + GPS stamp. Reused by legal billable-hours, payroll, gov contractor labour.
- B-T5 ⚠ enhance `EdenScheduler` — drag-to-reschedule, resource swimlanes, mobile gesture variant. **2026-05-02 Wave 1 port; still owed.**

#### B-fuel (≈1-1.5 wk)
- B-F1 `EdenTankGauge` — vertical liquid-level meter, capacity %, low-threshold visual cue. Used by propane/heating-oil/diesel customer dashboards.
- B-F2 `EdenRouteStopList` — ordered stop sequence with ETA, drag-reorder. Reuses A4 map preview.
- B-F3 `EdenMeterReadingEntry` — gallons + photo + reading source picker (manual / telemetry / customer-reported).
- B-F4 `EdenHazmatDocViewer` — DOT manifest, MSDS, driver-cert overlay. Reuses `eden_attachment_preview`.

#### B-salon (≈1.5-2 wk)
- B-S1 `EdenServiceCatalogTile` — service name, duration, price, staff-capability avatars. Backbone of MangoMint parity.
- B-S2 `EdenTimeSlotPicker` — booking widget: staff × hour grid with availability. Reuses A1 scheduler enhancement.
- B-S3 `EdenGiftCardTile` / `EdenPackageTile` — recipient, balance, expiry. Already a known MP4 gap.
- B-S4 `EdenTippingSelector` — preset % + custom amount. POS-adjacent; also retail + medical co-pay.

#### B-retail (≈1.5-2 wk)
- B-R1 `EdenPOSKeypad` — numpad + quick-add product grid + cart strip. Cross-vertical: retail, salon POS, medical co-pay collection, gov cashier surfaces.
- B-R2 `EdenReceiptPreview` — line items, tax/discount/promo lines, total. Reuses A3 currency.
- B-R3 `EdenInventoryAdjustment` — count entry, variance reason, photo evidence. Used by retail, salon back-bar, medical supply, fuel truck inventory.
- B-R4 `EdenStockLevelIndicator` — port from trades-flutter `stock_level_indicator.dart` (already flagged 2026-05-02 Wave 3).

#### B-medical (≈2 wk)
- B-M1 `EdenSOAPNote` — Subjective/Objective/Assessment/Plan composed form pattern w/ template snippets. Foundation for chart-entry.
- B-M2 `EdenVisitSummaryCard` — chief complaint, vitals strip, diagnosis list, plan summary. Patient-portal + provider review.
- B-M3 `EdenVitalsRow` — BP / HR / temp / SpO2 / RR / weight strip with trend arrows.
- B-M4 `EdenPHIRedactionOverlay` — toggleable masking on `eden_attachment_preview` + `eden_document_viewer` for screensharing / portal preview.
- B-M5 ⚠ enhance `EdenConsentFlow` (A5) with witness-signature slot for medical procedures + minor-patient guardian flow.

#### B-legal (≈1-1.5 wk)
- B-L1 `EdenMatterCard` — matter name, client, lifecycle stage, lead attorney, hours-this-period, last activity.
- B-L2 `EdenBillableTimer` — running clock + matter selector + descrip text + pause/resume + auto-rounding rule. Reused by gov contractor labour tracking.
- B-L3 `EdenBatesNumberedList` — document discovery list with Bates ID, exhibit-tag affordance.
- B-L4 `EdenConflictOfInterestCheck` — client/opposing-party search tile + manual override w/ rationale field.

### Wave C — Government overlay (3-4 wk)

Cross-cutting layer atop Waves A+B. **Gates DHHS/DOD vertical opt-in.**

- C1 `EdenClassificationBanner` — UNCLASSIFIED / CUI / S / TS top-of-screen + watermark variant. Background + foreground per ICD 710.
- C2 `EdenCacPivButton` + helper — smartcard auth affordance with insertion-prompt empty state. (Web build delegates to platform agent; native build uses platform channels.)
- C3 `EdenSection508Audit` — dev-tools-style overlay highlighting ARIA / contrast / focus-order issues across the live widget tree. Library-internal QA primitive.
- C4 `EdenAuditLogViewer` — user-facing immutable activity stream with actor / action / target / hash-chain link. Re-uses `eden_activity_feed`. Required for HIPAA + FedRAMP + DOD audit-trail UX.
- C5 `EdenFoiaRequestCard` — request meta, due-date pill, redaction-pass status, exemption codes. Reuses A1 list-page scaffold.
- C6 `EdenCaseFileShell` — multi-tab regulated dossier (case header → activity → documents → contacts → notes → audit). DHHS social services, DOJ case files, IG investigations.
- C7 ⚠ enhance `EdenPermissionMatrix` — federal role models (Privileged User, ISSO, ISSM), break-glass affordance with justification capture.
- C8 ⚠ enhance `EdenSecretField` — DoD CUI handling: copy-confined-to-classified-clipboard variants, paste-from-outside warning.
- C9 ⚠ enhance `EdenFileUpload` — virus-scan / CUI-marking / spillage-quarantine states. Reuses `eden_compliance_badge`.
- C10 `EdenMfaHardwareToken` — YubiKey / RSA token entry affordance. Composes with A7 phone-input verify.

### Wave D — Library hygiene (continuous; 1-2 wk equivalent over the program)

Already partially captured in `EDEN_UI_FLUTTER_COMPONENT_OPPORTUNITIES.md` (2026-05-02). Listed here for completeness.

- D1 Duplication migration — swap `eden-biz-flutter/lib/core/widgets/{confirm_dialog,toast,company_switcher}` to library equivalents; remove vendor.
- D2 Trades-flutter shared/widgets ports — the ~15 Category-A widgets from 2026-05-02 §B.A.
- D3 AI panel suite port (Wave 4 of 2026-05-02 doc).
- D4 Visual catalog regression baseline — defer until A+B settles.
- D5 Documentation + storybook hosting — defer.

---

## 4. Component-level scorecard (compact)

| Bucket                              | Coverage today                                                                       |
|-------------------------------------|--------------------------------------------------------------------------------------|
| **Layout + theme + tokens**         | ✓ Solid foundation; one gap = page-level scaffolds (A1, A2).                          |
| **Forms + inputs**                  | ✓ Broad. Gaps: phone (A7), address+map (A4), consent flow (A5), intake pattern (A6). |
| **Data display**                    | ✓ Broad. No cross-vertical gap. Vertical-specific gauges/tiles in Wave B.            |
| **Comms + chat**                    | ✓ Broad. Tilted dev-comms but transferable.                                          |
| **Scheduling**                      | ⚠ Partial. Needs drag/swimlanes/mobile (B-T5; 2026-05-02 Wave 1).                    |
| **Money / billing / POS**           | ✗ Sparse. Missing currency (A3), POS keypad (B-R1), receipt (B-R2), tipping (B-S4), billable timer (B-L2). |
| **Industry-specific (medical / legal / fuel)** | ✗ Sparse by design. Wave B fills 14 primitives.                            |
| **Government / federal compliance** | ✗ Sparse by design. Wave C fills 10 primitives (with two enhancements to existing).  |
| **Dev / sec / ops**                 | ✓ Over-served for the question; some primitives re-leverage into Wave C.             |
| **AI surface**                      | ✓ Library has core; trades donation pending (2026-05-02 Wave 4).                     |

---

## 5. Recommendations

1. **Land Wave A in one sprint.** 8 components, 3-4 wk, every vertical benefits. Includes already-flagged Wave 2 scaffolds (2026-05-02). This is the single highest-leverage step.

2. **Pick Wave B verticals by go-to-market priority.** Per current planning (`eden-biz/go/.planning/`), priority order is roughly: salon/spa (MP-track winding down), trades (obj 018/023/029/030/031 in flight), fuel-delivery (obj 100 just kicked off), medical/legal/retail (deferred). Recommend running Wave B subsets in that order: B-salon + B-trades first, then B-fuel, then medical/legal/retail when the verticals enter the roadmap.

3. **Treat Wave C as a separate ticket-gated track.** Federal compliance UX is not a tax to apply to everyone — it's an opt-in layer for the DHHS/DOD vertical only. **However**, several Wave C components have civilian utility (audit-log viewer, classification banner repurposed as data-sensitivity banner, MFA hardware token, virus-scan upload states). Build them gov-first but expose to commercial verticals as opt-in.

4. **Resist the urge to refactor what works.** The library's dev/sec/ops tilt is a feature, not a bug — it's a paid-down asset from aosentry/aodex/aocyber-compliance. Wave C reuses three of those primitives (`eden_compliance_badge`, `eden_certificate_card`, `eden_security_alert`) without modification. Don't generalise just-to-generalise.

5. **Run library work in parallel with vertical execution.** eden-ui-flutter is `kind: ui-lib` per `.planning/PROJECT.md` — it does NOT need to wait on vertical objectives. Wave A can be a single eden-libs objective; Wave B subsets can ship as small objectives interleaved with each vertical's flutter sprint.

6. **Set the bar for new components.** Every Wave A/B/C component must ship with: (a) widget test using the existing `wrap()` helper pattern, (b) iPhone-narrow (≥390pt) responsive baseline, (c) visual catalog entry under `lib/dev_app/`, (d) test coverage of the multitenancy-aware empty-state if the component renders tenant-scoped data. Per `eden-ui-flutter/.planning/PROJECT.md` constraints.

---

## 6. Decisions locked (2026-05-15)

Resolved with Mark in the assessment session. These supersede the corresponding §3 Wave entries where they differ; downstream planning should treat them as inputs, not open questions.

1. **Wave B sequencing — `Salon → Trades → Fuel → Medical → Retail → Legal`.**
   Tracks current roadmap state (MP-track winding down → obj 018/023/029/030/031 in flight → obj 100 just kicked off → deferred verticals). Each set unblocks the next vertical entering execution.
   *How to apply:* plan B-salon as the first Wave B sub-objective; do not interleave verticals without explicit reason.

2. **Wave C — build gov-first NOW, expose to commercial as opt-in.**
   Federal-shaped UX is not a tax; it's an opt-in layer with civilian re-use (audit-log viewer, classification → data-sensitivity banner, MFA hardware token, virus-scan upload states). Build with FedRAMP / DHHS / DOD requirements in mind from day 1; surface in the visual catalog so any vertical can pull pieces.
   *How to apply:* Wave C runs in parallel with Wave A, not after it. Do **not** wait on FedRAMP HIGH ATO.

3. **Map backend for A4 — pluggable adapter.**
   Library exposes an `EdenMapProvider` interface. Downstream companion apps (one per vertical per `VERTICAL_SKIN_ARCHITECTURE.md`) wire their own provider. Commercial verticals likely default to Mapbox or Google Maps; government / CUI workloads will need a MapLibre + self-hosted-tiles + Nominatim/Pelias geocoding adapter when DHHS/DOD ships.
   *How to apply:* A4 implementation must NOT hard-code a vendor SDK. Reference impls (Mapbox, MapLibre) ship as separate `eden_ui_flutter_map_*` siblings or in a `map_providers/` subdir; library core depends on the interface only.

4. **POS keypad (B-R1) — web + iPad/POS terminal native from v1.**
   Mark's call: avoid the rebuild later. ~2× scope but the touch-first gesture model and a11y posture have to be designed in, not retrofitted.
   *How to apply:* B-R1 ships against `eden-biz/pos/` Flutter target's platform constraints AND web. Test coverage must include touch gesture sequences + screen-reader transcripts + iPhone-narrow responsiveness. Coordinate with `eden-biz/pos/` for hardware-keyboard-shortcut requirements.

5. **SOAP note (B-M1) — generic shell + template plug-in slot.**
   `EdenSOAPNote` scaffold ships the 4 sections (Subjective / Objective / Assessment / Plan) with a template-slot API. Downstream apps (medical vertical, DHHS workflows) supply their own templates. Library stays transport- and domain-agnostic per `PROJECT.md` constraints.
   *How to apply:* template-slot API design is part of B-M1; downstream template libraries are separate work and do NOT live in `eden-ui-flutter`.

---

*Generated 2026-05-15. Sequel to `eden-biz/go/.planning/EDEN_UI_FLUTTER_COMPONENT_OPPORTUNITIES.md` (2026-05-02). Living in `eden-libs/eden-ui-flutter/.planning/` so it tracks library evolution alongside `PROJECT.md` + `ROADMAP.md`.*
