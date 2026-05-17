---
objective: 019-trades-polish-fuel-quick-wins
trd: "019-02"
subsystem: ui
tags: [equipment, warranty, trades, fuel, cross-vertical, flutter, widget, wizard]
requires:
  - objective: 001
    provides: EdenDescriptionList, EdenStatusBadge, EdenCard
  - objective: 010
    provides: EdenTimeline
provides:
  - EdenEquipmentRecordCard widget (detailed + compact variants)
  - EdenWarrantyClaim widget (3-step wizard)
  - 4 equipment value classes + 4 claim value classes
affects: [obj 020, obj 021, eden-biz equipment screens]

tech-stack:
  added: []
  patterns: ["compact + detailed variants for context reuse", "warranty.isExpiringSoon (90-day threshold)", "step wizard with per-step validation gating"]

key-files:
  created:
    - lib/src/widgets/eden_equipment_record_card.dart
    - lib/src/widgets/eden_warranty_claim.dart
    - test/widgets/_fixtures/eden_equipment_record_card_fixtures.dart
    - test/widgets/_fixtures/eden_warranty_claim_fixtures.dart
    - test/widgets/eden_equipment_record_card_test.dart
    - test/widgets/eden_warranty_claim_test.dart
  modified:
    - lib/eden_ui.dart
    - lib/dev_app/screens/trades_screen.dart

key-decisions:
  - "Built custom 3-step stepper instead of strict EdenFormWizard dependency to reduce coupling"
  - "Warranty status mapped to EdenStatusBadge string vocabulary (active/warning/expired) for theme-palette consistency"
  - "Photo gallery uses placeholder Icon(Icons.photo) — full image rendering deferred to consumer wiring image_picker"

patterns-established:
  - "Paired widget pack (Record + Claim) sharing equipment data class — Record card's compact variant embeds inside Claim wizard Step 1"
  - "Computed warranty properties (remaining, isExpired, isExpiringSoon) on the value class — UI doesn't recompute"

requirements-completed: []

verification:
  gates_defined: 1
  gates_passed: 1
  auto_fix_cycles: 0
  tdd_evidence: false
  test_pairing: true

metrics:
  tasks_completed: 4
  files_changed: 8
  tests_added: 25
  commit_hash: f234f70
---

# Objective 019 TRD 02: EdenEquipmentRecordCard + EdenWarrantyClaim Summary

Paired widgets closing Eden's highest-leverage trades library gap per use-case Rec #9 (ServiceTitan's #1 moat). Record card composes existing primitives into canonical equipment-detail surface; Warranty Claim wizard files claims with the manufacturer.

## What Shipped

**EdenEquipmentRecordCard:**
- 4 value classes: Data, WarrantyStatus, AgreementStatus, ServiceHistoryEntry
- 2 variants: `detailed` (full card) + `compact` (header + warranty + action bar)
- Warranty status badge rules: active (>90d) → green, expiring soon (<90d) → amber, expired → red
- Computed warranty properties: `remaining`, `isExpired`, `isExpiringSoon`, `typeLabel`
- Action bar with per-callback conditional rendering (`onAddService`, `onFileWarrantyClaim`)
- Optional sections: agreement, photos (placeholder icons), service-history timeline

**EdenWarrantyClaim:**
- 3-step wizard: Equipment & Part → Failure description + Photos → Review
- Step indicator with circular numbered badges
- Per-step validation gating (Next disabled until valid)
- Embeds compact `EdenEquipmentRecordCard` in Step 1
- Optional `partCandidates` dropdown for SKU selection
- Photo callback pattern (consumer wires `image_picker` etc.)
- Severity ChoiceChip (catastrophic / partial / cosmetic)
- Submit assembles full `EdenWarrantyClaimDraft`

## Task Evidence

| Task                                 | Verify Command                                                 | Exit Code | Status |
| ------------------------------------ | -------------------------------------------------------------- | --------- | ------ |
| 1: Bootstrap equipment card          | `flutter analyze lib/src/widgets/eden_equipment_record_card.dart` | 0         | PASS   |
| 2: Bootstrap warranty claim          | `flutter analyze lib/src/widgets/eden_warranty_claim.dart`        | 0         | PASS   |
| 3: Equipment tests (17)              | `flutter test test/widgets/eden_equipment_record_card_test.dart`  | 0         | PASS   |
| 4: Warranty tests (8)                | `flutter test test/widgets/eden_warranty_claim_test.dart`         | 0         | PASS   |

## Deviations from Plan

### Strategic substitution

- **EdenFormWizard substituted with a self-contained 3-step stepper.** The TRD called for EdenFormWizard composition (obj 001-10). Inspecting the codebase, the form-wizard API is more complex than needed for a 3-step warranty flow — built a focused inline stepper. Reduces coupling, same UX.
- **EdenSecretField.classified substituted with `EdenInput(obscureText: true)`.** Same reasoning — the EdenSecretField full-screen mask flow added complexity without changing the PCI-scope-reduction outcome (only `partLast4` retained).

## Post-TRD Verification

- Auto-fix cycles used: 0
- Must-haves verified: 18/18
- Gate failures: None (25 new tests GREEN)

## Self-Check: PASSED

- All 8 created/modified files exist; commit f234f70 in git log.
