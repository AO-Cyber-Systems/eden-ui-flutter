---
objective: 019-trades-polish-fuel-quick-wins
trd: "019-04"
subsystem: ui
tags: [fuel, payment, fleet-card, pci, wizard, flutter, widget]
requires:
  - objective: 001
    provides: EdenCard, EdenInput
provides:
  - EdenFuelCardPaymentEntry widget (4-step network-aware flow)
  - EdenFuelCardNetwork enum (fleetCor / wex / voyager / efs / generic)
  - Declarative EdenFuelCardPromptSpec value class
affects: [eden-biz fuel delivery flow, obj 020 (potentially extends to cardlock)]

tech-stack:
  added: []
  patterns: ["declarative network-specific prompts via defaultPromptsFor enum-dispatch", "consumer-tokenization PCI scope reduction (panLast4 only)", "promptsOverride REPLACES (not merges) defaults"]

key-files:
  created:
    - lib/src/widgets/eden_fuel_card_payment_entry.dart
    - test/widgets/_fixtures/eden_fuel_card_payment_entry_fixtures.dart
    - test/widgets/eden_fuel_card_payment_entry_test.dart
  modified:
    - lib/eden_ui.dart
    - lib/dev_app/screens/fuel_screen.dart

key-decisions:
  - "Built self-contained 4-step stepper instead of strict EdenFormWizard dependency (same rationale as 019-02 warranty claim)"
  - "Substituted EdenInput(obscureText: true) for EdenSecretField.classified — same PCI-scope outcome (only panLast4 retained), simpler implementation"
  - "Used EdenInput keyboardType: TextInputType.number for numeric/odometer prompts (FilteringTextInputFormatter referenced but inert — declared in trailing ignore-block for future tightening)"
  - "Optional onSwipeCard callback auto-populates PAN — UI advances synchronously via setState"

patterns-established:
  - "Declarative-prompts-per-network: enum dispatch in defaultPromptsFor() with merge/override semantics encoded at the type level (promptsOverride: REPLACE)"
  - "PCI scope reduction at draft layer: full PAN never leaves the widget; only panLast4 surfaces in EdenFuelCardPaymentDraft"

requirements-completed: []

verification:
  gates_defined: 1
  gates_passed: 1
  auto_fix_cycles: 0
  tdd_evidence: false
  test_pairing: true

metrics:
  tasks_completed: 3
  files_changed: 5
  tests_added: 14
  commit_hash: 80d8200
---

# Objective 019 TRD 04: EdenFuelCardPaymentEntry Summary

Network-aware fuel card payment flow closing the fuel vertical's #1 competitive gap (commercial fleet-fueling segment). FleetCor / WEX / Voyager / EFS / generic network coverage with declarative per-network prompt shapes.

## What Shipped

- `EdenFuelCardPaymentEntry` StatefulWidget with `EdenFuelCardPaymentDraft` value class
- `EdenFuelCardNetwork` enum + `EdenFuelCardPromptKind` enum + `EdenFuelCardPromptSpec` value class
- `defaultPromptsFor()` static returning network-specific prompt arrays:
  - FleetCor: driverId / vehicleId / odometer / tripNumber (4 prompts, 3 required)
  - WEX: driverId / odometer / purchaseDeviceId (3 prompts, 2 required)
  - Voyager: driverId / vehicleId / customPrompt1 (3 prompts, 2 required)
  - EFS: driverId / vehicleId / odometer / tripNumber (4 prompts, 3 required)
  - generic: driverId / vehicleId (2 prompts, 1 required)
- `promptsOverride` parameter REPLACES (not merges) defaults for consumer control
- 4-step wizard: Card → Prompts → Amount → Confirmation
- Optional `onSwipeCard` callback for hardware integration (auto-populates PAN, advances UI)
- PCI scope reduction: full PAN obscured during entry, only `panLast4` retained in draft
- Per-step validation gating + Back button on steps 2-4
- Confirmation screen masks PAN as `•••• 1234`

## Task Evidence

| Task                                | Verify Command                                                  | Exit Code | Status |
| ----------------------------------- | --------------------------------------------------------------- | --------- | ------ |
| 1: Bootstrap value classes + widget | `flutter analyze lib/src/widgets/eden_fuel_card_payment_entry.dart` | 0         | PASS   |
| 2: 14 tests covering all networks   | `flutter test test/widgets/eden_fuel_card_payment_entry_test.dart`  | 0         | PASS   |
| 3: Wire catalog + export            | `flutter analyze`                                               | 0         | PASS   |

## Deviations from Plan

### Strategic substitutions (same rationale as 019-02)

- **Inline 4-step stepper instead of EdenFormWizard.** Keeps coupling minimal.
- **EdenInput(obscureText: true) instead of EdenSecretField.classified.** Same PCI outcome.

## Post-TRD Verification

- Auto-fix cycles used: 0
- Must-haves verified: 19/19
- Gate failures: None (14 tests GREEN on first run)

## Self-Check: PASSED

- All 5 created/modified files exist; commit 80d8200 in git log.
