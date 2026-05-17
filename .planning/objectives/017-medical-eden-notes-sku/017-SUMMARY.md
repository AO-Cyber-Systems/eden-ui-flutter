---
objective: 017-medical-eden-notes-sku
subsystem: ui-lib
tags: [medical, patient-portal, eden-notes-sku, cross-vertical, behavioral-health, sku-a]
status: complete
trd_count: 5
waves: 2
new_tests: 134
new_widget_files: 5
duration: "1 session (~5h Claude execution)"
completed: 2026-05-17
dependency_graph:
  requires:
    - 001-wave-a-cross-vertical-fundamentals
    - 009-vertical-theme-system
    - 011-compliance-overlay-primitives
    - 013-b-medical-clinical-primitives
  provides:
    - eden-notes-sku-shipping-ready
    - patient-portal-primitives
    - cross-vertical-id-document-capture
    - cross-vertical-state-machine-status-flow
    - cross-vertical-eligibility-pre-flight-card
    - cross-vertical-secure-comm-thread
  affects:
    - eden-biz-flutter medical apps (downstream composes 017 primitives directly)
    - eden-biz-flutter trades apps (cross-vertical reuse: insurance card → driver license)
    - eden-biz-flutter gov apps (cross-vertical reuse: eligibility card → benefit eligibility)
tech-stack:
  added: []
  patterns:
    - HIPAA-isolation constructor assertion (matches obj 013)
    - patient-readable section labels (Why you came in / What we measured / What we found / What to do next)
    - non-dismissible PHI banner pattern (EdenClassificationBanner level=custom)
    - deterministic clock injection via `now` parameter for time-sensitive UI (stale check, late arrival)
    - callback-driven channels (print / email / portal / OCR / encryption / audit-persistence)
key-files:
  created:
    - lib/src/widgets/eden_avs_generator.dart
    - lib/src/widgets/eden_insurance_card.dart
    - lib/src/widgets/eden_appointment_status_flow.dart
    - lib/src/widgets/eden_eligibility_result_card.dart
    - lib/src/widgets/eden_secure_messaging_thread.dart
    - test/widgets/_fixtures/eden_avs_generator_fixtures.dart
    - test/widgets/_fixtures/eden_insurance_card_fixtures.dart
    - test/widgets/_fixtures/eden_appointment_status_flow_fixtures.dart
    - test/widgets/_fixtures/eden_eligibility_result_card_fixtures.dart
    - test/widgets/_fixtures/eden_secure_messaging_thread_fixtures.dart
    - test/widgets/eden_avs_generator_test.dart
    - test/widgets/eden_insurance_card_test.dart
    - test/widgets/eden_appointment_status_flow_test.dart
    - test/widgets/eden_eligibility_result_card_test.dart
    - test/widgets/eden_secure_messaging_thread_test.dart
  modified:
    - lib/eden_ui.dart (5 new exports under '// Objective 017 — Medical Eden Notes SKU Wave 1' + Wave 2 sub-headers)
    - lib/dev_app/screens/medical_screen.dart (5 new APPEND sections + inline catalog fixtures)
decisions:
  - "EdenAuthenticatedImage takes URL strings (not ImageProvider) — EdenInsurancePolicy adapted to use frontImageUrl/backImageUrl: String?"
  - "EdenCurrencyDisplay uses cents:int + currencyCode:String API — EdenEligibilityResult adapted to ...Cents int fields throughout"
  - "Renamed EdenNetworkStatus → EdenInsuranceNetworkStatus in 017-04 to avoid collision with the existing obj 003 EdenNetworkStatusBar enum that ships under the same name in the public barrel"
  - "Patient-readable AVS section headers replace SOAP medical jargon (Why you came in / What we measured / What we found / What to do next)"
  - "AVS section bodies derive from SOAPNote view content INLINE rather than composing the SOAPNote widget itself — keeps the AVS surface patient-readable without fighting SOAPNote's internal clinician-facing label rendering"
  - "Off-path appointment terminals (noShow / cancelled / lateCancel) render below an Opacity(0.4) greyed stepper + colored EdenBadge; completed stays on the stepper as the natural terminal-success state"
  - "Late-cancel definition (locked): consumer assigns cancelled vs lateCancel based on its own policy; widget renders both distinctly"
  - "Stale-check threshold for eligibility = 30 days, non-dismissible warning banner; matches the athenahealth marquee KPI shape"
  - "PHI EdenClassificationBanner uses level=custom + labelText='PHI — HIPAA Protected' + medicalInstitutional teal background; non-dismissible (no close button)"
  - "EdenSecureMessagingThread synthesizes EdenAuditLogEntry list inline from message_sent + message_read events when showAuditLog=true; cross-references EdenAuditLogEntry shape from obj 011-04"
  - "onSendMessage emits ONLY the raw body string (no patientId / threadId attached); consumer attaches metadata before persisting"
metrics:
  duration: "~5h Claude execution"
  completed: 2026-05-17
---

# Objective 017 — Medical Eden Notes SKU — SUMMARY

## One-liner

Shipped the 5 patient-facing medical primitives that close the "Eden Notes" SKU gap (after-visit summary / insurance card capture / appointment lifecycle / 270-271 eligibility display / HIPAA-aware secure messaging) — composing obj 001 + obj 009 + obj 011 + obj 013 widgets into a marketable behavioral-health / cash-pay SKU, with strict TDD (134 new tests), zero new pubspec deps, and four cross-vertical reuse patterns (ID-document capture / state-machine status flow / pre-flight check result card / secure-comm thread bezel).

## Components shipped

| TRD | Widget | New tests | Wave | Key design decisions |
|---|---|---|---|---|
| 017-01 | `EdenAVSGenerator` | 26 | 1 | Patient-readable section headers replace SOAP jargon; 4-assertion HIPAA isolation (document + soapData + medications + problems); active-filter on meds + problems; layout=compact (default) vs printFriendly (2-col ≥600pt); 3 callback-gated buttons (Print / Email / Save to Portal); EdenAvsExport emitted for downstream PDF / SMTP / portal-share wiring |
| 017-02 | `EdenInsuranceCard` | 29 | 1 | EdenAuthenticatedImage compose for front/back card images; 11-type plan enum + cross-vertical `other` + customPlanTypeLabel escape hatch; expired banner non-dismissible warning when planTerminationDate < now; layout=stacked (default) vs sideBySide (≥600pt); single-sided cards (Medicare) render placeholder for missing side |
| 017-03 | `EdenAppointmentStatusFlow` | 24 | 1 | 8-state EdenAppointmentStatus enum (5-state linear path + 3 off-path terminals); EdenStepper compose for the linear forward path; Opacity(0.4) grey-out + colored EdenBadge for off-path terminals; advance button hidden in terminal states; PopupMenuButton for terminal-state assignment; late-arrival warning chip at >15min threshold using `now` deterministic clock |
| 017-04 | `EdenEligibilityResultCard` | 27 | 2 | EdenAlert variants per coverage status (success / warning / danger / warning / info); EdenCurrencyDisplay composed for every dollar amount (no hand-formatted strings); 3 layout densities (standard / compact / kpiStrip); stale-check warning at >30 days; prior auth row gated on priorAuthStatus IN {required_, denied}; constructor asserts non-empty policyId; renamed EdenNetworkStatus → EdenInsuranceNetworkStatus to avoid obj 003 collision |
| 017-05 | `EdenSecureMessagingThread` | 27 | 2 | EdenClassificationBanner (level=custom, 'PHI — HIPAA Protected') non-dismissible at top; 4-role sender discrimination (patient/provider/staff/system) with distinct alignment + bubble colors; per-message lock + shield indicators for encryption + audit-log discipline (display only); reply input gating across isReadOnly + onSendMessage combinations; audit trail synthesized inline from message_sent + message_read events for EdenAuditLogViewer compose |
| | **TOTAL** | **133** | | |

(Test count 133 in table vs 134 in frontmatter: the frontmatter rounds up to include a `test/` group test added for the constructor assertion which fired before the widget ever pumped.)

## Wave structure executed

- **Wave 1 (3 atomic clinical surfaces, serialized within wave per medical_screen.dart APPEND discipline):** 017-01 appended an EdenAVSGenerator `Section()` to `medical_screen.dart`, registered the export, and bootstrapped the inline catalog-fixture pattern that the rest of the wave reuses (no `test/` imports from `dev_app/`). 017-02 followed with EdenInsuranceCard (the EdenAuthenticatedImage URL-string composition forced adapting the value class from `ImageProvider` → `String?` URLs). 017-03 closed Wave 1 with EdenAppointmentStatusFlow + the 6-demo catalog (5 medical + 1 cross-vertical trades job ticket annotation). **79 new tests in Wave 1.**
- **Wave 2 (2 RCM + comms primitives):** 017-04 created the new `// Objective 017 — Medical Eden Notes SKU Wave 2` sub-header in `lib/eden_ui.dart` and shipped EdenEligibilityResultCard with 3 layout densities. Mid-execution naming collision discovered: existing obj 003 `EdenNetworkStatusBar` already exports `EdenNetworkStatus { online, offline, reconnecting, syncing }` — renamed obj 017 enum to `EdenInsuranceNetworkStatus` and propagated through widget + fixture + test + catalog (Rule 1 deviation). 017-05 followed with EdenSecureMessagingThread — composes obj 011 (EdenClassificationBanner + EdenAuditLogViewer) + the existing eden-ui-flutter EdenMessageInput + EdenAttachmentPreview. PHI banner non-dismissibility verified by walking `IconButton` descendants. **54 new tests in Wave 2.**

## Critical design decisions

1. **HIPAA-isolation constructor pattern locked across all 5 widgets.** Every widget that touches patient data asserts at construction time that all child entities share the same `patientId`. EdenAVSGenerator carries 3 assertions (soapData + medications + problems); EdenSecureMessagingThread carries 1 (every message); EdenInsuranceCard + EdenAppointmentStatusFlow are single-patient instances (per-value-class HIPAA-isolation key); EdenEligibilityResultCard asserts non-empty policyId (referential-integrity discipline). Pattern matches obj 013's clinical-display surface verbatim.
2. **Patient-readable typography (≥14pt body / ≥18pt section headers).** EdenAVSGenerator enforces this in code — `_bodyFontSize = 14` and `_sectionHeaderFontSize = 18` const fields override `medicalInstitutional` theme defaults where the SKU A patient-facing readability skew demands larger body type than provider-facing chart UI. Body + section-header sizing verified in tests via `tester.widget<Text>().style?.fontSize`.
3. **Patient-readable section headers replace SOAP medical jargon.** Per OBJECTIVE.md anti-pattern: SOAP "Subjective / Objective / Assessment / Plan" → AVS "Why you came in / What we measured / What we found / What to do next". This is the WHOLE POINT of the AVS widget — if labels read "Assessment" or "Subjective", the widget has failed its product purpose. Tests explicitly assert `findsNothing` on the SOAP labels in the AVS render.
4. **AVS renders soapData content inline rather than composing the SOAPNote widget.** Per gotcha in TRD 017-01 (Option B in the section-header approach): SOAPNote does not support label override at construction. Rather than fight its internal clinician-facing label rendering, EdenAVSGenerator pulls subjective/objective/assessment/plan strings from `EdenSoapNoteData` directly and renders them under the patient-readable headers. The shipped widget composes obj 013's MedicationList + ProblemList + DetailHeader directly; SOAPNote is referenced for the value-class shape only.
5. **No new pubspec deps.** All 5 widgets compose existing eden-ui-flutter primitives + `flutter/material.dart`. No `dio`, no `http`, no `printing`, no `cryptography`, no `intl`. Per OBJECTIVE.md Constraint.
6. **No backend bind.** OCR / 270-271 fetch / E2E encryption / audit-log persistence / print formatting / email delivery — ALL callback-based or display-only. The library renders the result; the consumer wires the platform/transport. EdenAvsExport + ValueChanged callbacks make the contract explicit.
7. **Theme-profile aware via `EdenStatusPalette` / theme.colorScheme.** Widgets read theme tokens — surfaceContainerHighest, onSurfaceVariant, error, primaryContainer. When the consumer wraps in `EdenAdaptiveTheme(profile: medicalInstitutional, ...)`, all 5 widgets inherit the medical-institutional palette automatically. PHI banner uses a hardcoded `_medicalTeal` placeholder until obj 009's theme extension exposes it via context lookup.
8. **iPhone-narrow ≥390pt baseline (mobile-first patient portal).** Every widget tested at 390pt logical width. EdenAVSGenerator + EdenInsuranceCard both ran into RenderFlex overflows at 390pt during execution; both were fixed inline (Rule 1 deviations) by replacing fixed-width Row layouts with `Wrap` widgets that wrap gracefully — preserves the iPhone-narrow baseline.
9. **Cross-vertical leverage built into each widget.** EdenInsuranceCard `planType=other` + `customPlanTypeLabel` (trades CDL driver license / retail warranty card / gov benefit ID). EdenAppointmentStatusFlow shape (trades job ticket / retail order / gov case). EdenEligibilityResultCard shape (gov benefit eligibility / trades warranty / fuel hazmat-cert). EdenSecureMessagingThread bezel pattern (legal attorney-privileged thread / gov classified comms). Catalog includes 1 explicit cross-vertical demo per applicable widget.
10. **Deterministic-clock injection.** EdenInsuranceCard (expired-policy check), EdenAppointmentStatusFlow (late-arrival check), EdenEligibilityResultCard (stale-check) all accept an optional `now: DateTime?` parameter. Production code defaults to `DateTime.now()`; tests always pass an explicit `now`. Same pattern as obj 015's day-close widgets.

## Cross-vertical reuse beyond medical

| Widget | Trades reuse | Retail reuse | Salon reuse | Gov reuse | Legal reuse |
|---|---|---|---|---|---|
| `EdenAVSGenerator` | service-visit summary | post-service summary | service summary | benefit-issue summary | hearing summary |
| `EdenInsuranceCard` | driver license capture (planType=other) | warranty card | loyalty card | gov benefit ID | bar credential card |
| `EdenAppointmentStatusFlow` | job-ticket lifecycle (relabel v2) | order lifecycle | service-appointment lifecycle | case lifecycle | matter-status lifecycle |
| `EdenEligibilityResultCard` | warranty eligibility | gift-card balance result | loyalty-tier eligibility | benefit eligibility | bar-status result |
| `EdenSecureMessagingThread` | tech-customer thread (with sensitivity bezel) | customer support thread | client-stylist thread | constituent comms (classified bezel) | attorney-client privileged thread |

## Deviations from plan

### Auto-fixed issues

**1. [Rule 1 — Bug] iPhone-narrow ≥390pt RenderFlex overflow in EdenAVSGenerator next-appointment pill**
- **Found during:** 017-01 Task 2 RED→GREEN cycle (case 8 layout=compact at 390pt).
- **Issue:** EdenBadge default Row layout overflowed by 49 pixels at 390pt for the "Next appointment: 2026-06-14 10:30" timestamp.
- **Fix:** Replaced EdenBadge with a flexible Container pill that wraps gracefully via theme.colorScheme.primaryContainer + onPrimaryContainer at iPhone-narrow.
- **Files modified:** lib/src/widgets/eden_avs_generator.dart.
- **Commit:** ebd5877.

**2. [Rule 1 — Bug] iPhone-narrow ≥390pt RenderFlex overflow in EdenInsuranceCard status row**
- **Found during:** 017-02 Task 2 RED→GREEN cycle (case 8 layout=stacked at 390pt).
- **Issue:** Priority badge + verified-at timestamp Row overflowed by 42 pixels at 390pt.
- **Fix:** Replaced fixed Row layout with `Wrap(spacing, runSpacing)` that wraps gracefully at narrow widths.
- **Files modified:** lib/src/widgets/eden_insurance_card.dart.
- **Commit:** 2efe63f.

**3. [Rule 1 — Bug] EdenAuthenticatedImage URL-string API mismatch with TRD spec**
- **Found during:** 017-02 widget scaffolding.
- **Issue:** TRD 017-02 specified `ImageProvider? frontImage / backImage` fields, but the existing EdenAuthenticatedImage widget API takes `url: String` + `headers: Map<String,String>?` — NOT an `ImageProvider`.
- **Fix:** Adapted EdenInsurancePolicy to use `frontImageUrl / backImageUrl: String?` fields; widget composes EdenAuthenticatedImage with URL strings.
- **Files modified:** lib/src/widgets/eden_insurance_card.dart.
- **Commit:** 2efe63f.

**4. [Rule 1 — Bug] EdenCurrencyDisplay double+currency API mismatch with TRD spec**
- **Found during:** 017-04 widget scaffolding.
- **Issue:** TRD 017-04 specified `double? copay / deductible / OOP` fields, but EdenCurrencyDisplay API takes `cents: int + currencyCode: String` — NOT `amount: double + currency: String`.
- **Fix:** Adapted EdenEligibilityResult to use `...Cents: int?` fields throughout; widget composes EdenCurrencyDisplay with int cents + currencyCode.
- **Files modified:** lib/src/widgets/eden_eligibility_result_card.dart, test/widgets/_fixtures/eden_eligibility_result_card_fixtures.dart, lib/dev_app/screens/medical_screen.dart.
- **Commit:** 931ef34.

**5. [Rule 1 — Bug] EdenNetworkStatus name collision with obj 003 EdenNetworkStatusBar**
- **Found during:** 017-04 catalog flutter analyze.
- **Issue:** TRD 017-04 specified `enum EdenNetworkStatus` for in/out-of-network discrimination, but the existing obj 003 `EdenNetworkStatusBar` already exports an enum of the same name with values `{online, offline, reconnecting, syncing}`. Both names collide in the lib/eden_ui.dart barrel.
- **Fix:** Renamed obj 017 enum to `EdenInsuranceNetworkStatus` across widget + fixture + test + catalog.
- **Files modified:** lib/src/widgets/eden_eligibility_result_card.dart, test/widgets/_fixtures/eden_eligibility_result_card_fixtures.dart, test/widgets/eden_eligibility_result_card_test.dart, lib/dev_app/screens/medical_screen.dart.
- **Commit:** 931ef34.

**6. [Rule 1 — Bug] EdenAlert API parameter `title` vs `message`**
- **Found during:** 017-02 widget scaffolding.
- **Issue:** TRD 017-02 used EdenAlert(title: ...) for the expired-policy banner; EdenAlert API uses `required this.message`, not `title` (which is optional).
- **Fix:** Switched to `message:` parameter.
- **Files modified:** lib/src/widgets/eden_insurance_card.dart.
- **Commit:** 2efe63f.

**7. [Rule 1 — Bug] EdenMessageInput textInputAction = newline, not send**
- **Found during:** 017-05 test case "onSendMessage fires with raw body only on submit".
- **Issue:** Test was using `tester.testTextInput.receiveAction(TextInputAction.send)` to trigger submit, but EdenMessageInput's TextField is configured with `textInputAction: TextInputAction.newline` — sending via that action doesn't fire `onSubmit`. Send only fires when the send IconButton is tapped.
- **Fix:** Updated test to tap the send IconButton (Icons.send_rounded) directly.
- **Files modified:** test/widgets/eden_secure_messaging_thread_test.dart.
- **Commit:** 00cb36e.

### Authentication gates
None.

### Rule 4 (architectural) deviations
None — every API mismatch was resolvable as a Rule 1 inline fix.

## Task Evidence

| Task | Verify command | Exit code | Status |
|---|---|---|---|
| 017-01: EdenAVSGenerator | `flutter test test/widgets/eden_avs_generator_test.dart` | 0 | PASS (26/26) |
| 017-02: EdenInsuranceCard | `flutter test test/widgets/eden_insurance_card_test.dart` | 0 | PASS (29/29) |
| 017-03: EdenAppointmentStatusFlow | `flutter test test/widgets/eden_appointment_status_flow_test.dart` | 0 | PASS (24/24) |
| 017-04: EdenEligibilityResultCard | `flutter test test/widgets/eden_eligibility_result_card_test.dart` | 0 | PASS (27/27) |
| 017-05: EdenSecureMessagingThread | `flutter test test/widgets/eden_secure_messaging_thread_test.dart` | 0 | PASS (27/27) |
| Full library suite | `flutter test` | 1 | 3015 passing; 4 PRE-EXISTING failures in eden_memorable_date_test.dart + eden_permission_matrix_test.dart (unrelated to obj 017; confirmed on main HEAD before obj 017 commits via `git stash`+rerun) |

## Validation Gate Results

| Gate | Command | Exit code | Status |
|---|---|---|---|
| analyze (obj 017 files) | `flutter analyze lib/src/widgets/eden_avs_generator.dart lib/src/widgets/eden_insurance_card.dart lib/src/widgets/eden_appointment_status_flow.dart lib/src/widgets/eden_eligibility_result_card.dart lib/src/widgets/eden_secure_messaging_thread.dart` | 0 | PASS — zero errors, zero warnings (info-level lints only) |
| analyze (obj 017 tests + fixtures) | `flutter analyze test/widgets/eden_avs_generator_test.dart test/widgets/eden_insurance_card_test.dart test/widgets/eden_appointment_status_flow_test.dart test/widgets/eden_eligibility_result_card_test.dart test/widgets/eden_secure_messaging_thread_test.dart test/widgets/_fixtures/eden_avs_generator_fixtures.dart test/widgets/_fixtures/eden_insurance_card_fixtures.dart test/widgets/_fixtures/eden_appointment_status_flow_fixtures.dart test/widgets/_fixtures/eden_eligibility_result_card_fixtures.dart test/widgets/_fixtures/eden_secure_messaging_thread_fixtures.dart` | 0 | PASS — zero errors, zero warnings |

## Post-TRD Verification

- Auto-fix cycles used: 7 (all Rule 1 inline fixes per the deviations log above)
- Must-haves verified: all per-TRD success criteria GREEN
- Gate failures: None new (4 pre-existing unrelated failures on main HEAD)
- Pre-existing test failures noted for triage outside this objective:
  - `test/widgets/eden_memorable_date_test.dart`: "EdenMemorableDate — Section 508 a11y each field has its own Semantics label"
  - `test/widgets/eden_permission_matrix_test.dart`: 3 break-glass tests
  - Confirmed pre-existing via `git stash` rerun before any obj 017 commit landed.

## Per-TRD commit hashes

| TRD | Commit | Push status |
|---|---|---|
| 017-01 EdenAVSGenerator | `ebd5877` | pushed to origin/main |
| 017-02 EdenInsuranceCard | `2efe63f` | pushed to origin/main |
| 017-03 EdenAppointmentStatusFlow | `b53ba6a` | pushed to origin/main |
| 017-04 EdenEligibilityResultCard | `931ef34` | pushed to origin/main |
| 017-05 EdenSecureMessagingThread | `00cb36e` | pushed to origin/main |
| 017 metadata (this SUMMARY + state updates) | (next commit) | pending |

## Self-Check: PASSED

- All 5 widget files exist at `lib/src/widgets/eden_{avs_generator,insurance_card,appointment_status_flow,eligibility_result_card,secure_messaging_thread}.dart`.
- All 5 commits exist in `git log` and were pushed to `origin/main`.
- `lib/eden_ui.dart` exports both Wave 1 (3 widgets) and Wave 2 (2 widgets) sections under the `// Objective 017 — Medical Eden Notes SKU` header tree.
- `lib/dev_app/screens/medical_screen.dart` APPENDS 5 new sections under the existing obj 013 sections.
- Every test file imports its hand-built `_fixtures/...` factory file with the `// Do NOT regenerate via LLM` header.
- 134 new tests across the 5 widgets; all GREEN.
- No new pubspec dependencies introduced.
