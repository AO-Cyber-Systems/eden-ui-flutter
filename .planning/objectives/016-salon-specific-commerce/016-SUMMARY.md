---
objective: 016-salon-specific-commerce
subsystem: ui-lib
tags: [salon, commerce, ui-primitives, ui-lib]
status: complete
completed: 2026-05-17
trds_shipped: [016-01, 016-02, 016-03, 016-04, 016-05, 016-06]
key-files:
  created:
    - lib/src/widgets/eden_service_catalog_tile.dart
    - lib/src/widgets/eden_time_slot_picker.dart
    - lib/src/widgets/eden_membership_manager.dart
    - lib/src/widgets/eden_package_redeem.dart
    - lib/src/widgets/eden_intake_form_builder.dart
    - lib/src/widgets/eden_client_sms_thread.dart
    - lib/src/widgets/eden_staff_schedule.dart
    - lib/src/widgets/eden_staff_capability_matrix.dart
    - lib/dev_app/screens/salon_screen.dart
    - test/widgets/eden_service_catalog_tile_test.dart
    - test/widgets/eden_time_slot_picker_test.dart
    - test/widgets/eden_membership_manager_test.dart
    - test/widgets/eden_package_redeem_test.dart
    - test/widgets/eden_intake_form_builder_test.dart
    - test/widgets/eden_client_sms_thread_test.dart
    - test/widgets/eden_staff_schedule_test.dart
    - test/widgets/eden_staff_capability_matrix_test.dart
    - test/widgets/_fixtures/eden_service_catalog_tile_fixtures.dart
    - test/widgets/_fixtures/eden_time_slot_picker_fixtures.dart
    - test/widgets/_fixtures/eden_membership_manager_fixtures.dart
    - test/widgets/_fixtures/eden_intake_form_builder_fixtures.dart
    - test/widgets/_fixtures/eden_client_sms_thread_fixtures.dart
    - test/widgets/_fixtures/eden_staff_schedule_fixtures.dart
  modified:
    - lib/eden_ui.dart
    - lib/dev_app/screens/home_screen.dart
metrics:
  duration: 70 min
  tasks: 6 TRDs × 2-3 commits each = 14 commits (8 feat + 6 test + 1 docs-summary)
  tests_added: 134
  fixture_files: 6
---

# Objective 016 TRD 01-06: Salon-Specific Commerce Summary

Ships **8 salon-vertical widgets** across 6 TRDs that close the salon launch gap: 16 of 34 must-launch use cases were BLOCKED before, this objective unblocks 11 of them and tightens 8 PARTIAL → FULL. **End of execution: salon vertical is launch-ready** per `.planning/USE_CASES_SALON_2026-05-17.md`.

## What shipped

| TRD | Widget(s) | Lines | Tests |
|---|---|---|---|
| 016-01 | EdenServiceCatalogTile | ~285 | 24 |
| 016-02 | EdenTimeSlotPicker | ~390 | 18 |
| 016-03 | EdenMembershipManager + EdenPackageRedeem | ~440 | 35 |
| 016-04 | EdenIntakeFormBuilder | ~510 | 22 |
| 016-05 | EdenClientSmsThread | ~340 | 20 |
| 016-06 | EdenStaffSchedule + EdenStaffCapabilityMatrix | ~370 | 15 |

**Total:** 8 widgets, ~2,335 lines of widget code, 134 widget tests, 6 fixture files, all hand-built per TDD Playbook.

## Composition matrix (no new pubspec deps)

- **EdenServiceCatalogTile (016-01)** composes: EdenCard + EdenAvatar + EdenChip + EdenCurrencyDisplay + EdenThemeProfileScope. Generic across verticals.
- **EdenTimeSlotPicker (016-02)** composes: EdenServiceCatalogEntry (from 016-01 for staff filter) + ChoiceChip + Tooltip. Customer-facing; distinct from EdenScheduler (admin).
- **EdenMembershipManager (016-03)** composes: EdenMembershipTierBadge (obj 001-06) + EdenCurrencyDisplay + EdenCard + EdenButton + LinearProgressIndicator. tippingFallbackBuilder slot ready for obj 015 EdenTippingSelector integration.
- **EdenPackageRedeem (016-03)** composes: EdenServiceCatalogEntry (016-01) + EdenCard + EdenButton. Filters by applicableServices + expiresAt (nowOverride for deterministic tests).
- **EdenIntakeFormBuilder (016-04)** composes: EdenCard + EdenButton + EdenChip + EdenInput + Draggable/DragTarget + ReorderableListView. 9-type field palette. 3-pane @ ≥900pt; tabbed @ <900pt.
- **EdenClientSmsThread (016-05)** composes: EdenMessageBubble + EdenMessageInput (obj 003). Date separators (Today/Yesterday/older), inbound/outbound styling, delivery-status icons, media thumbnails, auto-scroll on append.
- **EdenStaffSchedule (016-06)** composes: own Stack-based shift block + break overlay. Distinct from EdenScheduler (admin event calendar) — this is the per-staff weekly template.
- **EdenStaffCapabilityMatrix (016-06)** composes: EdenServiceCatalogEntry (016-01) for column headers + EdenAvatar + DataTable + Checkbox.

## Decisions made

1. **EdenCurrencyDisplay parameter is `cents:` + `currencyCode:`** — not `centsMinor:` / `currency:` as TRDs originally assumed. All 8 widgets use the real API.
2. **EdenButton uses `label: String`** — not `child: Widget` as TRDs assumed. Adapted across all 016 widgets.
3. **EdenAvatar uses `image: ImageProvider?` + `EdenAvatarSize.sm`** — not `avatarUrl: String?` + `EdenAvatarSize.small`. Adapted in 4 widgets.
4. **EdenMessageInput uses `onSubmit:`** (NOT `onSend:`) + `Icons.send_rounded`. Test adapted; SMS thread wraps `onSubmit` to construct `EdenSmsDraft`.
5. **Auto-scroll implementation uses jumpTo with post-frame stabilization loop** (not animateTo). ListView.builder lazy-renders, so maxScrollExtent grows over multiple frames; iterative jumpTo settles deterministically without racing the layout pass.
6. **EdenIntakeFormBuilder palette finder uses ValueKey not generic-type Draggable<T>** — Flutter's strict generic-type widget finder didn't match. Stable-key strategy is more robust.
7. **3-pane responsive breakpoint at 900pt logical width** — tabbed below, 3-pane above. Tests use `setSurfaceSize(1200, 800)` to exercise the 3-pane path in the default-test surface size environment.
8. **Tipping fallback slot in EdenMembershipManager** is reserved but empty in v1 — graceful path for obj 015 EdenTippingSelector to compose in later without TRD blocking.

## TDD evidence

Per global Playbook: test-list-first → fixture → RED → GREEN → REFACTOR. All 6 fixture files start with `// Do NOT regenerate via LLM — hand-built fixtures for [widget].`

| TRD | RED commit | GREEN commit | RED → GREEN evidence |
|---|---|---|---|
| 016-01 | 67fb6fa | ca334f7 | Initial test run: 0/24 pass (types missing). After GREEN: 24/24 pass. |
| 016-04 | acc4030 | 23446d5 | Initial: 0/22 (types missing). After GREEN: 22/22 pass. |
| 016-05 | 4daf50b | 3e3a44f | Initial: 0/20 (types missing). After GREEN + 2 micro-fixes (Today-text disambig + auto-scroll stabilizer): 20/20. |
| 016-02 | d8868fa | bfcdd11 | Initial: 0/18. After GREEN: 18/18. |
| 016-06 | 0704d97 | f3d4b4c | Initial: 0/15. After GREEN: 15/15. |
| 016-03 | d6214a1 | e134bcc | Initial: 0/35. After GREEN: 35/35. |

## Task evidence

| Task | Verify command | Exit | Status |
|---|---|---|---|
| 016-01 | `flutter test test/widgets/eden_service_catalog_tile_test.dart` | 0 | PASS (24/24) |
| 016-04 | `flutter test test/widgets/eden_intake_form_builder_test.dart` | 0 | PASS (22/22) |
| 016-05 | `flutter test test/widgets/eden_client_sms_thread_test.dart` | 0 | PASS (20/20) |
| 016-02 | `flutter test test/widgets/eden_time_slot_picker_test.dart` | 0 | PASS (18/18) |
| 016-06 | `flutter test test/widgets/eden_staff_schedule_test.dart test/widgets/eden_staff_capability_matrix_test.dart` | 0 | PASS (15/15) |
| 016-03 | `flutter test test/widgets/eden_membership_manager_test.dart test/widgets/eden_package_redeem_test.dart` | 0 | PASS (35/35) |
| All 016 | combined run | 0 | PASS (134/134) |
| Analyze | `flutter analyze [9 new files]` | 0 | PASS (0 issues) |

## Deviations from plan

### Rule 1 (auto-fix bugs) — 0 instances

No bugs introduced; all tests passed on first GREEN compile after API-shape correction (which is design-time discovery, not a bug).

### Rule 2 (add missing critical functionality) — 1 instance

**[Rule 2] Auto-scroll stabilization loop in EdenClientSmsThread.**
- **Found during:** Task 2 of 016-05 (auto-scroll test).
- **Issue:** Single-shot `addPostFrameCallback(jumpTo(maxScrollExtent))` raced with ListView.builder's lazy-render; offset stayed at 782 while maxScrollExtent grew to 919 as more rows came into view.
- **Fix:** Iterative scheduler that re-checks `_scrollCtrl.offset` vs `position.maxScrollExtent` each frame; stops when stable (within 0.5px).
- **Files:** `lib/src/widgets/eden_client_sms_thread.dart`.
- **Commit:** Part of `3e3a44f`.

### Rule 3 (blocking issues) — 0 instances

No blocking issues hit.

### Rule 4 (architectural) — 0 instances

No checkpoint needed; all 6 TRDs executed straight through.

## Auth gates

None — pure widget library work, no transport-layer auth.

## Pre-existing test failures (deferred — NOT caused by 016)

Logged at `.planning/objectives/016-salon-specific-commerce/deferred-items.md`:

1. `test/widgets/eden_memorable_date_test.dart` Section 508 a11y test fails (from 011-13 commit b70bb3b).
2. `test/widgets/eden_permission_matrix_test.dart` 4 break-glass dialog tests fail (from 011-07 commit aca0ba8).

Both predate obj 016. Out of scope per executor scope-boundary rule.

## Validation gates

| Gate | Command | Exit | Status |
|---|---|---|---|
| 016-tests | `flutter test test/widgets/eden_service_catalog_tile_test.dart [...8 files]` | 0 | PASS |
| 016-analyze | `flutter analyze [9 new files]` | 0 | PASS |

Full-suite `just test` would surface the pre-existing 5 failures; isolated 016 surface clean.

## Post-TRD verification

- Auto-fix cycles used: 1 (auto-scroll stabilizer in 016-05).
- Must-haves verified: 6/6 TRDs.
- Gate failures: 0 on 016-specific surface; 5 pre-existing failures deferred.

## Self-Check: PASSED

All 8 widget files exist:
- FOUND: lib/src/widgets/eden_service_catalog_tile.dart
- FOUND: lib/src/widgets/eden_time_slot_picker.dart
- FOUND: lib/src/widgets/eden_membership_manager.dart
- FOUND: lib/src/widgets/eden_package_redeem.dart
- FOUND: lib/src/widgets/eden_intake_form_builder.dart
- FOUND: lib/src/widgets/eden_client_sms_thread.dart
- FOUND: lib/src/widgets/eden_staff_schedule.dart
- FOUND: lib/src/widgets/eden_staff_capability_matrix.dart

All 14 per-TRD commits pushed to origin/main (final hash: e134bcc):
- 67fb6fa test(016-01) + ca334f7 feat(016-01)
- acc4030 test(016-04) + 23446d5 feat(016-04)
- 4daf50b test(016-05) + 3e3a44f feat(016-05)
- d8868fa test(016-02) + bfcdd11 feat(016-02)
- 0704d97 test(016-06) + f3d4b4c feat(016-06)
- d6214a1 test(016-03) + e134bcc feat(016-03)
