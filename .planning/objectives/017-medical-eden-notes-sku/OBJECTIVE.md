---
objective: 017-medical-eden-notes-sku
kind: ui-lib
work: feature
status: planned
estimated_effort: 2-4 weeks Claude execution
trd_count: 5
waves: 2
depends_on:
  - 001-wave-a-cross-vertical-fundamentals  # EdenAuthenticatedImage (017-02), EdenConsentFlow / EdenDetailHeader (composes), EdenCurrencyDisplay (017-04 copay)
  - 009-vertical-theme-system               # EdenThemeProfile.medicalInstitutional + EdenStatusPalette for severity/PHI tokens
  - 011-compliance-overlay-primitives       # EdenClassificationBanner + EdenAuditLogViewer (017-05)
  - 013-b-medical-clinical-primitives       # EdenSOAPNote + EdenMedicationList + EdenProblemList (017-01)
parents:
  - .planning/USE_CASES_MEDICAL_2026-05-17.md           # §7 SKU A — "Eden Notes" (Behavioral health / cash-pay specialty)
  - .planning/objectives/013-b-medical-clinical-primitives/OBJECTIVE.md  # shipped clinical primitives this objective composes
---

# Objective 017 — Medical Eden Notes SKU + Cross-Vertical Clinical

## Goal

Ship the 5 medical-vertical primitives that close the "Eden Notes" SKU gap (per `USE_CASES_MEDICAL_2026-05-17.md` §7 SKU A): a behavioral-health / cash-pay / concierge-medicine SKU comparable to SimplePractice, ship-ready ~2-4 wk after obj 013. After this objective ships, downstream `eden-biz-flutter` medical apps compose a complete patient-facing visit-encounter surface — after-visit summary, insurance card capture, appointment lifecycle, eligibility result display, HIPAA-aware secure messaging — without re-implementing any of it.

This is the **fastest customer-facing SKU win** in the medical roadmap. obj 013 closed the clinical-display surface (chart, vitals, meds, labs, SOAP, timeline). obj 017 closes the *patient-facing* surface that turns the clinical display into a marketable SKU:

- **017-01 EdenAVSGenerator** — UC-COM-03 (After Visit Summary): patient-friendly print/email composing SOAP + meds + problems. *The single most-requested patient-portal surface across competitors (athenahealth, DrChrono, SimplePractice all ship this).*
- **017-02 EdenInsuranceCard** — UC-INT-03 (Insurance capture): front/back card capture + extraction display. *Required even for cash-pay practices that occasionally bill.*
- **017-03 EdenAppointmentStatusFlow** — UC-SCH-05 (No-show + late-cancel tracking): 6-state appointment lifecycle widget. *Day-to-day front-desk surface; every competitor has it.*
- **017-04 EdenEligibilityResultCard** — UC-PRE-01 (270/271 eligibility): visual eligibility/copay/deductible/coverage card. *athenahealth's marquee "patient responsibility known at check-in" KPI — single highest-impact RCM differentiator per `USE_CASES_MEDICAL_2026-05-17.md` §5 #1.*
- **017-05 EdenSecureMessagingThread** — UC-COM-01 (Secure messaging): HIPAA-aware variant of generic conversation thread. *PHI banner + encryption-at-rest UX cues + audit-log-aware. Reuses obj 011 ClassificationBanner + AuditLogViewer.*

Cross-vertical leverage:
- **017-02 EdenInsuranceCard** generalizes to ID-document capture (driver licenses for trades / gov / fuel; warranty cards for retail).
- **017-03 EdenAppointmentStatusFlow** generalizes to any state-machine status widget (job lifecycle for trades, order lifecycle for retail, case lifecycle for gov).
- **017-04 EdenEligibilityResultCard** shape generalizes to any "pre-flight check result" card (gov benefit eligibility, trades warranty eligibility).
- **017-05 EdenSecureMessagingThread** is the HIPAA bezel on top of a generic thread — same pattern reusable for attorney-privileged threads (legal), classified comms (gov).

## Why now

- **SKU A is the fastest path to medical revenue.** Per `USE_CASES_MEDICAL_2026-05-17.md` §7: obj 013 shipped the visual readiness for a clinic SKU; obj 017 polishes it into a marketable behavioral-health / cash-pay SKU competitive with SimplePractice. 2-4 wk of focused widget work versus 6-9 mo for SKU B (PCP).
- **obj 013 unblocked composition.** EdenSOAPNote + EdenMedicationList + EdenProblemList shipped; 017-01 AVSGenerator composes them directly.
- **obj 001 + 009 + 011 unblocked the rest.** EdenAuthenticatedImage + EdenAttachmentPreview (017-02), EdenStepper (017-03), EdenCurrencyDisplay (017-04), EdenClassificationBanner + EdenAuditLogViewer (017-05) all already shipped.
- **Patient-facing surface, not provider-facing.** Different design pressure from obj 013: patient-readable typography, simplified language, print/email-friendly. Different value class shape (no FHIR overload).
- **`EdenThemeProfile.medicalInstitutional` already shipped (obj 009).** Use `Theme.of(context).extension<EdenStatusPalette>()` for severity coloring (copay/deductible thresholds, appointment status states) — no new color tokens needed.

## Components in scope

| ID | Component | Composes | Wave |
|---|---|---|---|
| 017-01 | `EdenAVSGenerator` | `EdenSOAPNote` (013-06) view-mode, `EdenMedicationList` (013-02), `EdenProblemList` (013-04), `EdenDetailHeader` (001-02) | 1 |
| 017-02 | `EdenInsuranceCard` | `EdenAuthenticatedImage` (001-07), `EdenAttachmentPreview` (existing), `EdenBadge` | 1 |
| 017-03 | `EdenAppointmentStatusFlow` | `EdenStepper` (existing), `EdenBadge`, `EdenStatusPalette` (009) | 1 |
| 017-04 | `EdenEligibilityResultCard` | `EdenCurrencyDisplay` (001-04), `EdenBadge`, `EdenAlert`, `EdenStatusPalette` (009) | 2 |
| 017-05 | `EdenSecureMessagingThread` | `EdenClassificationBanner` (011-01), `EdenAuditLogViewer` (011-04), `EdenMessageBubble` + `EdenMessageInput` (existing), `EdenAttachmentPreview` | 2 |

## Wave structure

| Wave | TRDs | Theme |
|------|------|-------|
| **1 — Atomic clinical surfaces** | 017-01, 017-02, 017-03 | All 3 parallel — different files, different value classes, different compose targets. 017-01 (AVS) bootstraps any new `medical_screen.dart` sections; 017-02 + 017-03 append serially after 017-01 lands to avoid screen-file conflicts. |
| **2 — RCM entry + secure comms** | 017-04, 017-05 | Parallel — different files. 017-04 (Eligibility) composes obj 001 + 009; 017-05 (SecureMessaging) composes obj 011. Neither depends on the other. |

## Critical design constraints

- **HIPAA isolation (per global TDD Playbook habit 6).** Every widget that displays patient-specific data takes a `patientId` constructor param + asserts at construction that all child entities (medications, problems, appointments, eligibility results, messages) share the same `patientId`. Mismatch throws `AssertionError` in debug. Same discipline as obj 013 — pattern is locked.
- **No backend bind.** 270/271 eligibility fetch is the consumer's job; 017-04 renders the result. Card OCR extraction is the consumer's job; 017-02 displays the extracted fields. Encryption-at-rest is the consumer's job; 017-05 displays the UX cues. The library remains transport-agnostic; no `dio`, no `http`, no `connectrpc`.
- **Patient-readable typography.** Per `USE_CASES_MEDICAL_2026-05-17.md` SKU A behavioral-health skew: AVS + messaging must read at 8th-grade reading level visually — use `EdenThemeProfile.medicalInstitutional` Plex Sans body but lean toward larger body sizes than provider-facing chart UI (≥14pt body, not the 12pt clinical density).
- **Theme-profile aware.** Use `EdenThemeProfile.medicalInstitutional` (obj 009). Severity coloring via `Theme.of(context).extension<EdenStatusPalette>()`: `.danger` = red (high copay, denied eligibility, late-cancel), `.warning` = yellow (caution, partial eligibility), `.success` = green (covered, confirmed). iPhone-narrow ≥390pt baseline.
- **PHI banner discipline (017-05 specifically).** Per locked decision C (`COMPANION_UX_PATTERNS_2026-05-15.md` §0): PHI display reuses obj 011's compliance overlay. 017-05 composes `EdenClassificationBanner` with `level: custom, labelText: 'PHI — HIPAA Protected'` at the top of every thread render. Non-dismissible (same pattern as 013-05 allergy criticality banner).
- **AVS output channels (017-01).** Print + email + portal-render. Library renders the composite widget; consumer wires the print/email side via callback (`onPrintRequested`, `onEmailRequested`) — same callback-driven discipline as obj 013-06 SOAPNote.
- **No new pubspec deps.** Composes existing primitives only.
- **iPhone-narrow ≥390pt baseline.** Patient-portal SKU is mobile-first; baseline is stricter than provider-facing chart UI.

## TDD + project constraints (per global CLAUDE.md Playbook)

- **Strict TDD per global Playbook + DevFlow Iron Law.** Every widget = standalone TDD TRD (`type: standard` with task-level `tdd="true"`). Wave 1 + Wave 2 widgets all testable; no exceptions.
- **Test list first.** Every TRD includes a `## Test list` section with happy / edge / failure / HIPAA-isolation cases before any test code is written.
- **One test at a time.** RED → GREEN → REFACTOR per behavior. No batching.
- **Hand-built fixtures with `// Do NOT regenerate via LLM` header.** Realistic-but-non-PII patient data: synthetic patient names (`patient-alpha`, `patient-bravo`), realistic plan names (Aetna PPO 5000, BCBS HDHP, Cigna Open Access), realistic copays ($25 PCP / $50 specialist / $250 ER) and deductibles ($2500 individual, $5000 family). Insurance card front/back is a placeholder rect with member-id text; no real plan logos. Appointment IDs and message bodies are realistic-but-fabricated.
- **`wrap()` helper test pattern** (matches obj 005 + obj 013 pattern).
- **Outside-in for UI flows.** Per global Playbook habit 5: integration-level test first (widget renders with realistic fixture → asserts top-level user-observable behavior), then descend to composition (each sub-element renders correctly), then unit-level helpers (e.g. eligibility result-color computer, appointment-state transitions).
- **Multitenancy guard = HIPAA isolation.** Per global Playbook habit 6: every widget test includes a "wrong-patient isolation" assertion proving that fixture data for patient A cannot render under patient B's context.
- **Visual catalog.** APPEND sections to existing `lib/dev_app/screens/medical_screen.dart`. Add cross-vertical scenarios where applicable (017-02 ID-doc capture for trades / gov; 017-03 status-flow for retail order lifecycle).
- **Export section.** `// Objective 017 — Medical Eden Notes SKU Wave N` in `lib/eden_ui.dart`.

## Out of scope

- **270/271 transport.** 017-04 renders the result; consumer fetches it. Clearinghouse integration is a separate platform objective.
- **OCR card-data extraction.** 017-02 displays the result; consumer wires the OCR. ML/vision is a separate platform objective.
- **End-to-end encryption.** 017-05 renders the UX cues (PHI banner, encryption indicator); consumer wires actual encryption-at-rest + in-transit. Cryptography is a platform concern.
- **Print formatting.** 017-01 builds the widget; consumer wires `Printing` package or PDF generation. Library is print-output-agnostic.
- **Email delivery.** 017-01 builds the widget + emits a structured `EdenAvsExport` value on `onEmailRequested`; consumer wires SMTP / SendGrid.
- **`EdenAppointmentScheduler`** — appointment booking surface is deferred to a separate Cluster 2 (UC-SCH-01) objective; obj 017-03 is the *status flow* (post-booking lifecycle), not the booker.
- **Telehealth video.** UC-COM-05 deferred. 017-05 messaging is text + attachment only; video calling is a downstream-app concern (Daily.co / Twilio / Agora integration).
- **`EdenPatientPortalShell`** — page-shell composition of 017-01..05 deferred to a follow-up objective once the 5 primitives ship and downstream `eden-biz-flutter` validates per-vertical layout needs.
- **eRx for psych (SKU A scope).** Per `USE_CASES_MEDICAL_2026-05-17.md` §7: psych eRx is a narrow subset of SKU B (Eden Clinic) and is deferred entirely from SKU A.
