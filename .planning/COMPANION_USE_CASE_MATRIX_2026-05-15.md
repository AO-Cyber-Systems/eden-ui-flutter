---
title: Companion Use Case Matrix — Eden Biz
date: 2026-05-15
author: research session (mark + Claude Opus 4.7 1M)
parents:
  - ./COMPANION_UX_PATTERNS_2026-05-15.md
  - ./COMPANION_B2_SPEC_2026-05-15.md
  - /Users/markemerson/Source/eden-biz/go/.planning/VERTICAL_SKIN_ARCHITECTURE.md
  - ./VERTICAL_COVERAGE_ASSESSMENT_2026-05-15.md
  - ./TRADES_REMAP_DEEP_AUDIT_2026-05-15.md
status: read-only research; row count target 40-60; achieved 54 rows
---

# Companion Use Case Matrix

> Each row = one distinct user task. Columns answer "where does this
> task live in the build-mode + form-factor + connectivity model?"
> Use to scope Wave B/D builds and to validate the Wave A primitive
> set covers the task surface.

## Column legend

| Column                      | Meaning                                                                                               |
|-----------------------------|-------------------------------------------------------------------------------------------------------|
| `#`                         | Stable row ID. Reference in plans as `UC-NN`.                                                          |
| Task                        | One-sentence user goal.                                                                                |
| Audience                    | `employee` (tenant staff) or `customer` (end-customer of the tenant).                                  |
| Primary form factor         | `phone`, `tablet`, `desktop`. Multiple if equally weighted.                                            |
| Online posture              | `req` (online required) / `tol` (offline-tolerant, queues + reconciles) / `only` (offline-only OK).    |
| Companion in-scope          | `yes` (routes reachable from companion mode) / `no` (admin-only) / `portal` (customer-portal binary).  |
| Wave A primitives           | Subset of the 15 Wave A widgets needed. Abbreviations: LPS=EdenListPageScaffold, DPS=EdenDetailPageScaffold, MP=EdenMapProvider+EdenMapPreview+EdenAddressInput, RDS=EdenRoleDashboardShell, QAB=EdenQuickActionBar, OQV=EdenOfflineQueueViewer, ATO=EdenAppTourOverlay, CF=EdenConsentFlow, IF=EdenIntakeForm, PI=EdenPhoneInput, AI=EdenAuthenticatedImage, NSB=EdenNetworkStatusBar, CD=EdenCurrencyDisplay, MTB=EdenMembershipTierBadge. Existing widgets noted as needed. |
| Pattern refs                | `P-NN` from `COMPANION_UX_PATTERNS_2026-05-15.md`.                                                     |
| Verticals applicable        | `T`=trades, `S`=salon/spa, `F`=fuel, `M`=medical, `R`=retail, `L`=legal, `G`=government. `*` = all.    |

---

## A. Employee tasks — Trades

| #  | Task                                                                  | Audience  | Form factor   | Online | Companion | Wave A primitives                                              | Patterns          | Verticals |
|----|-----------------------------------------------------------------------|-----------|----------------|--------|-----------|----------------------------------------------------------------|--------------------|-----------|
| 01 | Field tech opens app, sees today's schedule + next stop                | employee  | phone          | tol    | yes       | RDS, QAB, NSB, AI                                              | P-12, P-15, P-18   | T,F,M,G   |
| 02 | Field tech checks in at job site with GPS verification                 | employee  | phone          | tol    | yes       | MP, NSB, OQV; existing `eden_signature_pad`, `eden_badge`      | P-07, P-15, P-17   | T,F,M,G   |
| 03 | Field tech captures before/during/after photos on a job                | employee  | phone          | tol    | yes       | OQV, NSB; existing `eden_attachment_preview`                   | P-07, P-08, P-15   | T,M,G,R   |
| 04 | Field tech fills out digital inspection form with photo evidence       | employee  | phone, tablet  | tol    | yes       | IF, OQV; existing `eden_form_wizard`, `eden_signature_pad`     | P-07, P-08, P-20   | T,F,M,G   |
| 05 | Field tech captures customer signature for inspection acceptance       | employee  | phone, tablet  | tol    | yes       | CF, AI                                                         | P-08, P-14         | T,F,M,G   |
| 06 | Field tech logs time entry with break tracking                         | employee  | phone          | tol    | yes       | OQV, NSB; existing `eden_input`                                | P-07, P-15         | T,F,M,L,G |
| 07 | Field tech adds field notes for follow-up                               | employee  | phone          | tol    | yes       | OQV; existing `eden_markdown_editor`                           | P-07               | T,F,M,G   |
| 08 | Field tech requests parts from inventory while on site                  | employee  | phone          | tol    | yes       | QAB, OQV                                                       | P-02, P-03, P-07   | T,F,M,G,R |
| 09 | Field tech looks up parts catalog (search + barcode scan)               | employee  | phone          | tol    | yes       | existing `eden_search_input`, `eden_barcode_scanner`           | P-03               | T,F,R,M   |
| 10 | Field tech checks PO status                                            | employee  | phone          | req    | yes       | LPS (mobile card mode); existing `eden_data_grid`              | P-04               | T,F,R     |
| 11 | Field tech submits quick bid / estimate from field                      | employee  | phone, tablet  | tol    | yes       | IF, CD, OQV; existing `eden_streaming_indicator`               | P-07, P-20         | T,F,M,L,R |
| 12 | Field tech escalates blocked work to dispatcher                         | employee  | phone          | tol    | yes       | QAB, OQV                                                       | P-03, P-07         | T,F,M,G   |
| 13 | Field tech reviews customer history / equipment record before arrival   | employee  | phone          | tol    | yes       | DPS (mobile push-nav), AI                                      | P-09, P-18         | T,F,M     |
| 14 | Field tech packs truck against today's job checklist                    | employee  | phone          | tol    | yes       | OQV; existing `eden_checklist_builder`                         | P-05, P-07         | T,F,R     |
| 15 | Field tech receives push notification of new dispatch                    | employee  | phone          | req    | yes       | NSB; existing `eden_notification_list`                         | P-15               | T,F,M,G   |
| 16 | Field tech reviews offline queue + retries failed sync                  | employee  | phone          | only   | yes       | OQV, NSB                                                       | P-07, P-15         | T,F,M,G   |
| 17 | Field tech navigates to next job address via map app handoff           | employee  | phone          | req    | yes       | MP                                                             | (uses external app) | T,F,M,G   |

---

## B. Employee tasks — Salon / Spa

| #  | Task                                                                  | Audience  | Form factor   | Online | Companion | Wave A primitives                                          | Patterns          | Verticals |
|----|-----------------------------------------------------------------------|-----------|----------------|--------|-----------|------------------------------------------------------------|--------------------|-----------|
| 18 | Stylist opens app, sees today's chair appointments + first/last       | employee  | phone, tablet  | req    | yes       | RDS, QAB, AI                                               | P-12, P-18         | S,M       |
| 19 | Stylist marks client arrived / in-chair / completed                    | employee  | phone, tablet  | tol    | yes       | QAB, OQV                                                   | P-02, P-05, P-07   | S,M,G     |
| 20 | Stylist captures client preferences + allergy notes (intake)           | employee  | phone, tablet  | tol    | yes       | IF, OQV                                                    | P-07, P-20         | S,M       |
| 21 | Stylist photographs the finished style for client portfolio             | employee  | phone          | tol    | yes       | OQV; existing `eden_attachment_preview`                    | P-07, P-08         | S,M,G,R   |
| 22 | Stylist checks out client at chair (POS + tip)                          | employee  | tablet         | req    | yes       | CD; pending Wave B-S/R EdenPosKeypad, EdenTippingSelector  | P-04               | S,R,M,F   |
| 23 | Stylist books next appointment for the client before they leave        | employee  | phone, tablet  | req    | yes       | existing `eden_scheduler`                                  | P-02, P-09         | S,M,F,T   |
| 24 | Stylist views walk-in availability for the day                         | employee  | phone, tablet  | req    | yes       | existing `eden_scheduler`                                  | P-09               | S,M,F     |
| 25 | Stylist sells a gift card / product package                             | employee  | tablet         | req    | yes       | CD, MTB; pending Wave B-S6 EdenGiftCardTile                | P-04               | S,R,M     |
| 26 | Stylist marks tip-out / cash drawer count at end of shift               | employee  | tablet         | req    | partial   | CD; pending Wave B-S/R primitives                          | P-04               | S,R,F     |

---

## C. Employee tasks — Fuel delivery

| #  | Task                                                                  | Audience  | Form factor   | Online | Companion | Wave A primitives                                          | Patterns          | Verticals |
|----|-----------------------------------------------------------------------|-----------|----------------|--------|-----------|------------------------------------------------------------|--------------------|-----------|
| 27 | Driver opens app, sees today's route + manifest                        | employee  | phone, tablet  | tol    | yes       | RDS, QAB, NSB, AI                                          | P-12, P-15, P-18   | F,T,M,G   |
| 28 | Driver navigates from stop to stop on the route                         | employee  | phone, tablet  | tol    | yes       | MP                                                         | (uses external map) | F,T,M,G   |
| 29 | Driver records tank gauge / meter reading at delivery                   | employee  | phone, tablet  | tol    | yes       | OQV, NSB; pending Wave B-F1 EdenTankGauge                  | P-07               | F         |
| 30 | Driver captures delivery confirmation signature                         | employee  | phone, tablet  | tol    | yes       | CF, OQV                                                    | P-08, P-14         | F,T,M,G   |
| 31 | Driver logs spill / incident report from cab                            | employee  | phone          | tol    | yes       | IF, OQV; existing `eden_attachment_preview`                | P-07, P-20         | F,T,M,G   |
| 32 | Driver reviews DOT / hazmat documents en route                          | employee  | phone, tablet  | only   | yes       | existing `eden_document_viewer`                            | (read-only)        | F,T,G     |
| 33 | Driver performs pre-trip vehicle inspection (DVIR)                      | employee  | phone, tablet  | tol    | yes       | IF, OQV; existing `eden_checklist_builder`                 | P-07, P-20         | F,T,G     |

---

## D. Employee tasks — Medical (DHHS-adjacent)

| #  | Task                                                                  | Audience  | Form factor   | Online | Companion | Wave A primitives                                          | Patterns          | Verticals |
|----|-----------------------------------------------------------------------|-----------|----------------|--------|-----------|------------------------------------------------------------|--------------------|-----------|
| 34 | Nurse opens app, sees today's home-visit caseload                       | employee  | phone, tablet  | tol    | yes       | RDS, QAB, NSB, AI                                          | P-12, P-15, P-18   | M,G       |
| 35 | Nurse records vitals during home visit (BP, pulse, O2, glucose)        | employee  | phone, tablet  | tol    | yes       | OQV; pending Wave B-M3 EdenVitalsRow                       | P-07               | M,G       |
| 36 | Nurse captures patient signature on consent-to-treatment                | employee  | phone, tablet  | tol    | yes       | CF, AI, OQV                                                | P-08, P-14         | M,G       |
| 37 | Nurse documents SOAP-style chart entry post-visit                       | employee  | phone, tablet  | tol    | yes       | OQV; pending Wave B-M1 EdenSoapForm; existing `eden_markdown_editor` | P-07     | M,G       |
| 38 | Nurse photographs wound for documentation                               | employee  | phone          | tol    | yes       | OQV; existing `eden_attachment_preview`                    | P-07, P-08         | M,G,T     |
| 39 | Nurse verifies patient identity at door (face + DOB confirm)            | employee  | phone          | req    | yes       | AI; existing `eden_input`                                  | P-12               | M,G       |

---

## E. Employee tasks — Government caseworker

| #  | Task                                                                  | Audience  | Form factor   | Online | Companion | Wave A primitives                                          | Patterns          | Verticals |
|----|-----------------------------------------------------------------------|-----------|----------------|--------|-----------|------------------------------------------------------------|--------------------|-----------|
| 40 | Caseworker opens app, sees today's site-visit caseload                  | employee  | phone, tablet  | tol    | yes       | RDS, QAB, NSB, AI                                          | P-12, P-15, P-18   | G,M       |
| 41 | Caseworker uploads consent-to-search form at site visit                 | employee  | phone, tablet  | tol    | yes       | CF, AI, OQV                                                | P-08, P-14         | G,M       |
| 42 | Caseworker performs site inspection with chain-of-custody photos        | employee  | phone, tablet  | tol    | yes       | OQV; pending Wave C C7 EdenAuditLogEntry                   | P-07, P-08, P-17   | G,M,T     |
| 43 | Caseworker views classification-banner-protected case file              | employee  | phone, tablet, desktop | req | yes       | DPS; pending Wave C C1 EdenClassificationBanner            | P-09               | G         |
| 44 | Caseworker logs out via short idle timeout (Sec-508 hardening)          | employee  | *              | req    | yes       | existing `eden_login_page`                                 | (auto-logout)      | G,M       |

---

## F. Employee tasks — Retail cashier

| #  | Task                                                                  | Audience  | Form factor   | Online | Companion | Wave A primitives                                          | Patterns          | Verticals |
|----|-----------------------------------------------------------------------|-----------|----------------|--------|-----------|------------------------------------------------------------|--------------------|-----------|
| 45 | Cashier rings sale with barcode scan + manual entry                     | employee  | tablet         | tol    | yes       | CD, OQV; existing `eden_barcode_scanner`; pending Wave B-R1 EdenPosKeypad | P-04, P-07 | R,S,F,M   |
| 46 | Cashier processes refund / return                                       | employee  | tablet         | req    | yes       | CD; pending Wave B-R2 EdenReceiptPreview                   | P-04               | R,S,F,M   |
| 47 | Cashier adjusts inventory on receiving shipment (barcode scan)          | employee  | phone, tablet  | tol    | yes       | OQV; existing `eden_barcode_scanner`; pending Wave B-R3 EdenInventoryAdjust | P-07 | R,T,F,M,G |
| 48 | Cashier handles customer loyalty enrollment + tier check                | employee  | tablet         | req    | yes       | MTB, PI; existing `eden_input`                             | P-04               | R,S,M     |

---

## G. Employee tasks — Legal

| #  | Task                                                                  | Audience  | Form factor   | Online | Companion | Wave A primitives                                          | Patterns          | Verticals |
|----|-----------------------------------------------------------------------|-----------|----------------|--------|-----------|------------------------------------------------------------|--------------------|-----------|
| 49 | Attorney starts billable-hours timer from phone                         | employee  | phone          | tol    | yes       | QAB, OQV; pending Wave B-L1 EdenBillableTimer              | P-02, P-07         | L,M,T     |
| 50 | Attorney captures client intake at first meeting                        | employee  | phone, tablet  | tol    | yes       | IF, PI, OQV                                                | P-07, P-20         | L,M,S,G   |
| 51 | Attorney reviews matter file (read-only) at courthouse                  | employee  | phone, tablet  | only   | yes       | DPS; pending Wave B-L2 EdenMatterCard                      | P-09               | L         |

---

## H. Employee tasks — Cross-vertical admin (companion-mode applicable)

| #  | Task                                                                  | Audience  | Form factor   | Online | Companion | Wave A primitives                                          | Patterns          | Verticals |
|----|-----------------------------------------------------------------------|-----------|----------------|--------|-----------|------------------------------------------------------------|--------------------|-----------|
| 52 | Dispatcher reassigns crew/staff to job from desk                        | employee  | desktop, tablet | req   | no        | existing `eden_scheduler`, `eden_kanban`                   | P-09               | T,F,M,G,S |
| 53 | Dispatcher views live map of all crews/staff in the field              | employee  | desktop, tablet | req   | no        | MP                                                         | P-09               | T,F,M,G   |
| 54 | Dispatcher sends broadcast message to all crews                         | employee  | desktop, tablet | req   | no        | existing `eden_chat_bubble`, `eden_message_input`          | (broadcast)        | T,F,M,G   |
| 55 | Manager runs payroll batch + approval                                   | employee  | desktop        | req    | no        | CD; existing `eden_data_grid`, `eden_workflow_stepper`     | P-09               | T,F,M,S,R,L,G |
| 56 | Manager approves change order with multi-step ladder                    | employee  | desktop, tablet | req   | no        | CD; existing `eden_workflow_stepper`                       | P-09, P-14         | T,F,M,G,L |
| 57 | Admin configures vertical preset / customizations                        | employee  | desktop        | req    | no        | existing `eden_settings_section`                           | (admin-only)        | *         |
| 58 | Admin reviews + approves subcontractor W9 / insurance                   | employee  | desktop, tablet | req   | no        | existing `eden_certificate_card`, `eden_compliance_badge`  | (admin-only)        | T,F,G,M,L |
| 59 | Manager toggles into field-view lens to debug a tech's UX issue         | employee  | desktop, tablet | req   | yes       | `EdenModeToggle` (Wave A donor), `EdenModeGate` (P-11)     | P-11               | *         |

---

## I. Customer tasks — Portal binary (cross-vertical)

| #  | Task                                                                  | Audience  | Form factor   | Online | Companion | Wave A primitives                                          | Patterns          | Verticals |
|----|-----------------------------------------------------------------------|-----------|----------------|--------|-----------|------------------------------------------------------------|--------------------|-----------|
| 60 | Customer logs in to portal (email + password or magic link)             | customer  | phone, desktop | req    | portal    | existing `eden_login_page`; PI for SMS-verify                | P-15               | *         |
| 61 | Customer opens portal home, sees projects / appointments / balance      | customer  | phone, desktop | tol    | portal    | RDS, AI; existing `eden_stat_card`                         | P-12, P-19         | *         |
| 62 | Customer pays an invoice from phone                                     | customer  | phone, desktop | req    | portal    | CD, AI; pending Wave B-R2 EdenReceiptPreview               | P-04, P-15         | *         |
| 63 | Customer approves a quote / estimate (sig + clauses)                    | customer  | phone, desktop | req    | portal    | CF, AI                                                     | P-08, P-14         | T,F,M,S,L,G |
| 64 | Customer books an appointment online (cross-vertical booking widget)    | customer  | phone, desktop | req    | portal    | existing `eden_scheduler`, MP, PI                          | (booking flow)     | S,M,T,F   |
| 65 | Customer checks loyalty balance / membership tier                       | customer  | phone, desktop | tol    | portal    | MTB, CD                                                    | P-19               | S,R,M,L,G |
| 66 | Customer messages tenant staff via portal chat                          | customer  | phone, desktop | req    | portal    | existing `eden_chat_bubble`, `eden_message_input`, AI      | P-19               | *         |
| 67 | Customer uploads document / form for tenant review                       | customer  | phone, desktop | req    | portal    | existing `eden_file_upload`, AI                            | P-19               | T,F,M,L,G |
| 68 | Customer reviews project timeline + photos                              | customer  | phone, desktop | tol    | portal    | DPS, AI; existing `eden_progress`, `eden_timeline`         | P-09, P-19         | T,F,G     |
| 69 | Customer fills out vertical intake (medical history / preferences / W9) | customer  | phone, desktop | req    | portal    | IF, PI, CF                                                 | P-08, P-14, P-20   | M,L,S,T,G |
| 70 | Customer joins telehealth visit from portal                              | customer  | phone, desktop | req    | portal    | existing `eden_link_button`; defers to external video link | P-19               | M         |
| 71 | Customer requests delivery rescheduling / cancellation                   | customer  | phone, desktop | req    | portal    | existing `eden_button`, `eden_alert`                       | P-19               | F,T,M,R   |
| 72 | Customer enables push notifications for portal events                    | customer  | phone          | req    | portal    | existing `eden_settings_section`                           | (push consent)     | *         |
| 73 | Customer downloads receipt / invoice PDF                                 | customer  | phone, desktop | req    | portal    | existing `eden_file_upload` reverse / `eden_document_viewer` | P-19              | *         |
| 74 | Customer flips between language / currency / accessibility settings       | customer  | phone, desktop | tol    | portal    | CD, existing `eden_settings_section`                       | P-19               | *         |

---

## Summary statistics

| Bucket                                  | Count |
|-----------------------------------------|------:|
| Total rows                              | 74    |
| Employee tasks                          | 59    |
| Customer tasks (portal binary)          | 15    |
| Phone-primary tasks                     | 50    |
| Tablet-primary tasks                    | 29    |
| Desktop-primary tasks (companion `no`)  | 9     |
| Offline-tolerant tasks (`tol`)          | 39    |
| Offline-only-OK tasks (`only`)          | 3     |
| Online-required tasks (`req`)           | 32    |
| Companion-in-scope (`yes`)              | 51    |
| Companion-not-in-scope (`no`)           | 8     |
| Customer-portal-only (`portal`)         | 15    |

(Note: rows that list multiple form factors are counted once per
primary; a task spanning phone + tablet counts toward phone if phone is
the principal target.)

### Wave A primitive coverage check

| Wave A primitive                   | Rows requiring it      | Coverage         |
|------------------------------------|------------------------|------------------|
| EdenListPageScaffold (LPS)         | 10 (rows 10, 22, 23, 24, 45, 46, etc.) | broad |
| EdenDetailPageScaffold (DPS)       | 13, 43, 51, 68         | medium           |
| EdenMapProvider+Preview (MP)       | 02, 17, 28, 53, 64     | medium           |
| EdenRoleDashboardShell (RDS)       | 01, 18, 27, 34, 40, 61 | broad (every "today" entry point) |
| EdenQuickActionBar (QAB)           | 01, 08, 12, 18, 19, 27, 34, 40, 49 | broad (every companion home) |
| EdenOfflineQueueViewer (OQV)       | 02, 03, 04, 06, 07, 08, 11, 14, 16, 19, 20, 21, 29, 30, 31, 35, 36, 37, 38, 41, 42, 45, 47, 49, 50 | very broad (~50% of employee rows) |
| EdenAppTourOverlay (ATO)           | (engaged for every companion-mode first launch — not a per-task primitive) | n/a |
| EdenConsentFlow (CF)               | 05, 30, 36, 41, 63, 69 | medium (every signature flow) |
| EdenIntakeForm (IF)                | 04, 11, 20, 31, 33, 50, 69 | medium (every form pattern) |
| EdenPhoneInput (PI)                | 48, 50, 60, 64, 69     | medium (every contact-collection) |
| EdenAuthenticatedImage (AI)        | 01, 02, 13, 18, 21, 22, 27, 34, 36, 38, 40, 41, 42, 43, 61, 62, 63, 66, 67, 68, 69 | very broad |
| EdenNetworkStatusBar (NSB)         | 01, 02, 03, 06, 15, 16, 27, 29, 34, 40, 60 | very broad (every companion entry point) |
| EdenCurrencyDisplay (CD)           | 11, 22, 25, 26, 45, 46, 48, 55, 56, 62, 65, 74 | broad (every money render) |
| EdenMembershipTierBadge (MTB)      | 25, 48, 65             | small but real    |

**Read:** Wave A primitives cover the breadth of tasks above. The
heavy hitters (OQV, NSB, AI, CD, QAB, RDS) appear in ≥10 rows each —
codifying them as library widgets pays off across multiple tasks.

The unique "pending" Wave B primitives referenced in rows that Wave A
does not cover:
- `EdenTankGauge` (row 29) — Wave B-F1 fuel-specific.
- `EdenSoapForm`, `EdenVitalsRow` (rows 37, 35) — Wave B-M medical.
- `EdenPosKeypad`, `EdenReceiptPreview`, `EdenInventoryAdjust` (rows
  22, 45, 46, 47, 62) — Wave B-R retail (also serves salon, fuel,
  medical co-pay).
- `EdenTippingSelector`, `EdenGiftCardTile` (rows 22, 25) — Wave B-S
  salon (also serves retail, hospitality).
- `EdenBillableTimer`, `EdenMatterCard` (rows 49, 51) — Wave B-L legal.
- `EdenClassificationBanner`, `EdenAuditLogEntry` (rows 42, 43) —
  Wave C government overlay.
- `EdenGpsStatusIndicator` (rows 02, 42) — promote to Wave B per
  P-17 analysis in patterns doc.

### Companion-not-in-scope check

Rows with `Companion=no` (admin-only): 52–58. Verify these are
deliberately not reachable from companion mode per B2 spec §2 route
classification:

| #  | Task                                       | Rationale                                                                    |
|----|--------------------------------------------|------------------------------------------------------------------------------|
| 52 | Dispatcher reassigns crew                  | Desk task — schedule-grid manipulation needs wide screen + pointer accuracy. |
| 53 | Dispatcher views live map                  | Desk task — multi-pin overview needs screen real estate.                     |
| 54 | Dispatcher broadcast message               | Desk task — keyboard composition for long messages.                          |
| 55 | Manager runs payroll                       | Financial workflow — risk of misfire on phone; admin-only.                   |
| 56 | Manager approves change order              | Multi-stakeholder approval ladder; desk task.                                |
| 57 | Admin configures vertical preset           | Settings page; not field-reachable per trades-react `MOBILE_NAV_HIDDEN_ROUTES`. |
| 58 | Admin reviews W9 / insurance               | Compliance docs; desk task.                                                  |

Row 59 (manager toggles field-view lens) is in COMPANION YES bucket
because the LENS itself is a companion-mode entry point — manager IS
flipping to companion chrome to preview a tech's UX. The toggle widget
itself is rendered in the admin chrome's header (per B2 §4 Q-B2-4
recommendation).

### Vertical coverage check

| Vertical | Rows applicable | Mostly companion? |
|----------|-----------------|-------------------|
| Trades (T) | 01-17, 28, 31-33, 38, 42, 47-50, 56, 58, 59, 60-71, 73-74 | yes |
| Salon (S) | 18-26, 50, 52-59, 60-71, 73-74 | mixed |
| Fuel (F) | 02-06, 22, 23, 26, 27-33, 45-48, 52-56, 58-71, 73-74 | yes |
| Medical (M) | 02-08, 13, 15, 18-25, 28, 30, 33, 34-39, 42, 47-48, 50-71, 73-74 | yes |
| Retail (R) | 03, 08-11, 14, 22, 25-26, 45-48, 56, 60-67, 69, 71, 73-74 | mixed |
| Legal (L) | 06, 11, 49-51, 55-56, 60-71, 73-74 | mostly admin |
| Gov (G) | 02-08, 11-12, 15-16, 20-21, 26, 28, 30-33, 34, 36-44, 47, 50-56, 58-71, 73-74 | yes |

**Read:** trades, fuel, medical, gov are companion-heavy (the on-the-go
verticals). Salon and retail are mixed (POS-at-counter is companion-ish
but stationary). Legal is mostly admin with a small companion surface
(billable timer, intake, courthouse read).

---

## How to use this matrix

### When planning Wave B / D objectives

For each new objective spec, find the matching row(s) here. The
"Wave A primitives" column tells you what the library already
provides; the "Pattern refs" column tells you which patterns
(P-NN in `COMPANION_UX_PATTERNS_2026-05-15.md`) you should compose.
If a row references a pending primitive (e.g., "pending Wave B-F1
EdenTankGauge"), that's the build dependency — note it in the
objective's `depends_on:` field.

### When validating Wave A scope

The summary statistics show every Wave A primitive is reached by 3+
rows; the highest-leverage ones (OQV, NSB, AI, CD) hit ≥10 rows.
Wave A primitives that DON'T appear in 3+ rows are over-built; review.

### When planning per-vertical sequencing

Filter rows by vertical column. The first row count = how many
companion-mode-applicable tasks that vertical has. trades, fuel,
medical, gov all show 15+ companion-applicable tasks → companion
build is meaningful. Legal shows ~5 → companion may not warrant a
full build (defer behind admin work).

### When asking "does Wave A miss anything?"

Look for rows where Wave A primitives are absent / minimal AND the
row is companion-in-scope. Candidates for Wave-A-promotion or B-rapid:
- Row 22 (POS at chair) — needs `EdenPosKeypad`. Wave B-R1.
- Row 29 (tank gauge) — needs `EdenTankGauge`. Wave B-F1.
- Row 35 (vitals) — needs `EdenVitalsRow`. Wave B-M3.
- Row 49 (billable timer) — needs `EdenBillableTimer`. Wave B-L1.

None of these are missing from Wave A; they're correctly classified as
Wave B vertical-specific. Wave A is not under-scoped.

---

## Cross-references

- **Patterns doc** — defines P-01 through P-20 referenced above:
  `./COMPANION_UX_PATTERNS_2026-05-15.md`
- **B2 spec** — Path α mode discrimination + build pipeline:
  `./COMPANION_B2_SPEC_2026-05-15.md`
- **Parent assessment** — Wave A/B/C scope source:
  `./VERTICAL_COVERAGE_ASSESSMENT_2026-05-15.md`
- **Deep audit** — per-folder remap source for trades:
  `./TRADES_REMAP_DEEP_AUDIT_2026-05-15.md`
- **Skin architecture** — Path α model source:
  `/Users/markemerson/Source/eden-biz/go/.planning/VERTICAL_SKIN_ARCHITECTURE.md`

---

*End of matrix. 74 rows across 9 task buckets; ~70% companion-in-scope;
Wave A coverage validated; pending Wave B primitives surfaced.*
