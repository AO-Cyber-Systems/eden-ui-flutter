---
objective: 013-b-medical-clinical-primitives
kind: ui-lib
work: feature
status: planned
estimated_effort: 2-3 weeks Claude execution
trd_count: 9
waves: 3
depends_on:
  - 012-cross-vertical-commerce-primitives  # EdenLineItemEditor used by claim/visit; EdenAggregateKpiStrip + EdenSparkline used by chart/labs
  - 009-vertical-theme-system               # EdenStatusPalette + medicalInstitutional profile for severity coloring
  - 011-compliance-overlay-primitives       # EdenAuditLogViewer composed into PatientChartScaffold side-rail
parents:
  - .planning/VERTICAL_WIREFRAMES_VALIDATION_2026-05-17.md  # primary spec
  - .planning/VERTICAL_UX_RESEARCH_2026-05-16.md             # medical density + HIPAA conventions
  - .planning/VERTICAL_COVERAGE_ASSESSMENT_2026-05-15.md     # B-medical gap list
  - .planning/COMPANION_UX_PATTERNS_2026-05-15.md            # locked decisions (esp. F: AI surface stays callback-driven)
---

# Objective 013 — B-Medical clinical primitives

## Goal

Ship the 9 medical-vertical-specific primitives that unblock Eden's primary-care SKU. Per `VERTICAL_WIREFRAMES_VALIDATION_2026-05-17.md` §3.1 + §5: medical is currently **0 FULL / 1 PARTIAL / 4 BLOCKED of 5 screens** — every product-defining medical screen (Patient Chart, Visit/Encounter, Patient Roster, Billing) is blocked by missing clinical primitives. After this objective ships, downstream `eden-biz-flutter` medical apps compose a Patient Chart + Visit Encounter surface from library widgets without re-implementing any clinical density, HIPAA overlay wiring, FHIR-shape value mapping, or three-pane chart layout.

The 9 widgets fall in three tiers:
- **Wave 1 — Atomic clinical primitives (5 widgets):** `EdenVitalsRow`, `EdenMedicationList`, `EdenLabResultTable`, `EdenProblemList`, `EdenAllergyList`. All parallel — different files, different value classes, zero shared state.
- **Wave 2 — Clinical composers (2 widgets):** `EdenSOAPNote` (Subjective/Objective/Assessment/Plan composer per locked decision F: template-slot API, callback-driven), `EdenChartTimeline` (compressed multi-year clinical timeline composing `EdenActivityFeedItem` with medical-flavored render).
- **Wave 3 — Page-shell capstones (2 widgets):** `EdenPatientChartScaffold` (three-pane shell composing Wave 1 + Wave 2 + obj 011 `EdenAuditLogViewer`), `EdenVisitEncounterScaffold` (during-appointment workflow composing `EdenSOAPNote` + obj 012 `EdenLineItemEditor` + obj 001 `EdenConsentFlow`).

These widgets are library-owned, FHIR-shape (NOT FHIR-bound), HIPAA-aware, theme-profile aware. **Per locked decision C (`COMPANION_UX_PATTERNS_2026-05-15.md` §0):** PHI handling reuses obj 011's compliance overlay (`EdenAuditLogViewer` composes into chart side-rail; PHI-bearing widgets carry classification labels via theme tokens). **Library remains transport-agnostic** — no Epic / Cerner / athenahealth API knowledge. Consumer apps wrap their FHIR/HL7 backend models into library value classes.

## Why now

- **Medical is critically under-served.** Per validation doc §1: 4 of 5 medical screens BLOCKED, 1 PARTIAL. Eden cannot field a primary-care app at all today. This is the single highest-impact gap in the library for a previously-unaddressed vertical.
- **Obj 012 commerce primitives unblock the billing-shaped portion.** `EdenLineItemEditor` (obj 012-01) handles claim posting + copay + charge entry (per validation doc §3.1.M5). Obj 012's `EdenAggregateKpiStrip` + chart family extensions land the KPI strips medical billing screens need. Obj 012 must ship first.
- **Obj 009 vertical theme system already shipped `EdenThemeProfile.medicalInstitutional`.** Use `Theme.of(context).extension<EdenStatusPalette>()` for vitals reference-range coloring (red urgent / yellow caution / green normal) — no new color tokens needed. Per UX research §1.4: medical wants institutional teal/white, sharper corners (4–6pt), no shadow, IBM Plex Sans body — all locked by the medical profile.
- **Obj 011 EdenAuditLogViewer already shipped.** HIPAA audit trail visibility composes into `EdenPatientChartScaffold` side-rail without new development.
- **Obj 001 EdenIntakeForm + EdenConsentFlow + EdenSignaturePad already shipped.** SOAP-note signed-off-by-patient flow composes from existing primitives.
- **Obj 003 EdenActivityFeedItem already shipped.** `EdenChartTimeline` composes it with medical-flavored render (severity tinting + category icon).
- **Cross-vertical re-use beyond medical.** Several Wave 1 widgets carry value across other verticals:
  - `EdenVitalsRow` → gov caseworker home visits (vitals capture), fuel hazmat (driver vitals if regulated).
  - `EdenChartTimeline` → any compressed multi-year activity timeline (gov case history, legal matter timeline).
  - `EdenProblemList` / `EdenAllergyList` shape generalizes to `EdenIssueList` / `EdenWarningList` (cross-vertical incident tracking).

## Components in scope

| ID | Component | Composes | Donor / Source | Wave |
|---|---|---|---|---|
| 013-01 | `EdenVitalsRow` | `EdenStatusPalette` (obj 009) | New — clinical density strip; no donor (validation doc §3.1.M1) | 1 |
| 013-02 | `EdenMedicationList` | `EdenBadge`, `EdenStatusPalette` (obj 009) | New — FHIR-shape MedicationStatement display | 1 |
| 013-03 | `EdenLabResultTable` | `EdenDataTable.dense` (obj 010), `EdenSparkline` (obj 012-07) | New — extends dense table with flag column + inline sparkline cell | 1 |
| 013-04 | `EdenProblemList` | `EdenBadge`, `EdenStatusPalette` (obj 009) | New — FHIR-shape Condition (ICD-10) display | 1 |
| 013-05 | `EdenAllergyList` | `EdenAlert.danger`, `EdenBadge` | New — FHIR-shape AllergyIntolerance; non-dismissible severity banner | 1 |
| 013-06 | `EdenSOAPNote` | callback-driven (per locked decision F); no compose | New — 4-section composer with template-slot API; voice/AI handled via consumer callbacks | 2 |
| 013-07 | `EdenChartTimeline` | `EdenActivityFeedItem` (obj 003-06) | New — compressed clinical timeline with severity tinting + category filter chips | 2 |
| 013-08 | `EdenPatientChartScaffold` | `EdenDetailPageScaffold` (obj 001), `EdenTabs`, `EdenDescriptionList`, Wave 1 widgets, `EdenAuditLogViewer` (obj 011), `aiInsightSlot` callback | New — three-pane composite shell | 3 |
| 013-09 | `EdenVisitEncounterScaffold` | `EdenWorkflowStepper`, `EdenSOAPNote` (013-06), `EdenLineItemEditor` (obj 012-01), `EdenConsentFlow` (obj 001), `EdenBlockingAlerts` | New — encounter workflow page shell | 3 |

## Wave structure

| Wave | TRDs | Theme |
|------|------|-------|
| **1 — Atomic clinical primitives** | 013-01, 013-02, 013-03, 013-04, 013-05 | All 5 parallel — different files, different value classes, no shared state. Independent of each other. |
| **2 — Clinical composers** | 013-06, 013-07 | Parallel — different files. 013-06 (SOAP) is self-contained; 013-07 (timeline) only composes obj 003 widgets. |
| **3 — Page-shell capstones** | 013-08, 013-09 | Sequential. 013-08 (PatientChartScaffold) first — composes Wave 1 + Wave 2. 013-09 (VisitEncounterScaffold) second — composes 013-06 + obj 012 + obj 001. |

## Critical design constraints

- **HIPAA/PHI-aware.** Per locked decision C: PHI display reuses obj 011 compliance overlay. `EdenPatientChartScaffold` composes `EdenAuditLogViewer` (obj 011) into its side-rail; PHI-bearing widgets carry classification labels via `EdenStatusPalette.phi` tokens (obj 009).
- **FHIR-shape value classes — NOT FHIR-bound.** Library defines `EdenVitalSign`, `EdenMedicationStatement`, `EdenLabResult`, `EdenCondition`, `EdenAllergyIntolerance` value classes that are *aligned* with FHIR resource shapes (familiar to medical devs) but **library-owned** (no `fhir_dart` dependency, no proto generation). Consumer maps backend models (Epic / Cerner / athenahealth) → library value classes at the integration boundary.
- **Theme-profile aware.** Use `EdenThemeProfile.medicalInstitutional` (obj 009). Severity coloring via `Theme.of(context).extension<EdenStatusPalette>()`: `.danger` = red urgent, `.warning` = yellow caution, `.success` = green normal. iPhone-narrow ≥390pt baseline.
- **AI surface stays callback-driven.** Per locked decision F: `EdenChartTimeline` + `EdenPatientChartScaffold` expose `Widget? aiInsightSlot` for downstream consumers to plug in summarization (composes `EdenAiPanel` from obj 003 at downstream layer, NOT here).
- **No backend bind.** Library has no knowledge of Epic / Cerner / athenahealth APIs.
- **No new pubspec deps.**
- **Multitenancy-equivalent = HIPAA isolation.** Per global TDD Playbook habit 6: every Wave 1+2 widget test MUST include a "wrong-patient isolation" assertion proving fixture data for patient A can never render under patient B's context. Wave 3 page-shell scaffolds include integration-level isolation assertions (full chart, wrong patient ID, asserts zero PHI bleeds).

## TDD + project constraints

- **Strict TDD per global Playbook + DevFlow Iron Law.** Every Wave 1 widget = standalone TDD TRD. Every Wave 2 composer = TDD TRD. Wave 3 scaffolds composed of TDD'd parts; scaffold integration tests pair with composition tests (composes correctly under wrap()).
- **Test list first.** Every TRD includes a `## Test list` section with happy / edge / failure / multitenancy(HIPAA) cases before any test code is written.
- **One test at a time.** RED → GREEN → REFACTOR per behavior. No batching.
- **Hand-built fixtures with `// Do NOT regenerate via LLM` header.** Realistic-but-non-PII clinical data: ICD-10 codes (E11.9 = T2DM, I10 = essential hypertension, J44.9 = COPD), common drugs (metformin 500mg, lisinopril 10mg, atorvastatin 40mg), common lab panels (CBC, CMP, lipid panel) with reference ranges (Hgb 12-16 g/dL, Glucose 70-99 mg/dL, LDL <100 mg/dL).
- **`wrap()` helper test pattern** (matches obj 005 pattern).
- **iPhone-narrow ≥390pt baseline.**
- **Visual catalog.** New `lib/dev_app/screens/medical_screen.dart` (created in 013-01; appended by 013-02..013-07; 013-08 + 013-09 may add their own composite-demo sections or get separate screens at planner discretion).
- **Export section.** `// Objective 013 — B-Medical clinical primitives Wave N` in `lib/eden_ui.dart`.
- **Outside-in for Wave 3 scaffolds.** Page-shell integration test first (renders all panes with realistic data), then descend to composition-level (each pane renders its expected widgets), then unit-level (helper functions: e.g. tab-state controller, severity-tint computer).

## Out of scope

- **`EdenEPrescribeForm` + `EdenOrderEntryForm`** (validation doc §3.1.M2 steps Vitals/Orders) — deferred to a separate B-medical-orders objective. These touch CPT/NDC code lookup (downstream platform concern), not pure UI.
- **`EdenDataTable.compactClinical`** (validation doc cross-vertical gap §4.1 #10) — deferred. The current `EdenDataTable.dense` (obj 010-06) is sufficient for v1 Patient Roster + Claims; clinical-row-grouping enhancement is a v2 polish (validation doc §5 obj 013 proposal explicitly bundles it as TRD-09 alternative; we defer to keep this objective shippable in ~2-3 weeks).
- **`EdenVitalsCaptureForm`** (validation doc §3.1.M2 vitals capture) — deferred. v1 falls back to `EdenForm` + `EdenInput` composition. Split-BP numpad-style entry is a v2 polish.
- **`EdenDicomViewer`** (validation doc §3.1.M1 imaging tab) — explicitly out of library scope per validation doc; consumer apps provide their own DICOM viewer.
- **Voice input + AI completion.** Per locked decision F: SOAP composer exposes callback slots; library does NOT ship `speech_to_text` integration or AI streaming.
