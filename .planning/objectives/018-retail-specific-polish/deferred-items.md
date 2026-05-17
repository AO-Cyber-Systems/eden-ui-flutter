# Deferred Items — Objective 018 Retail-Specific Polish

Out-of-scope test failures discovered during obj 018 execution. Not caused
by this objective; left for owners of the affected widgets.

## Pre-existing failing tests — `flutter test` baseline at obj 018 start

Observed on `ee594f8` (obj 016 complete) before any 018 commits landed, and
again on `a6661bc` (obj 018 complete). Total: 8 failures, distributed across
4 pre-existing test files. None touch obj 018 widgets.

### `test/widgets/eden_intake_form_builder_test.dart` (2 failures)
- `EdenIntakeFormBuilder 3-pane layout (≥900pt) renders 9 Draggable palette entries`
- `EdenIntakeFormBuilder 3-pane layout (≥900pt) Config pane shows empty hint when no field selected`

(Tracked in stashed pre-obj-018 test-fix patches; not yet committed.)

### `test/widgets/eden_client_sms_thread_test.dart` (2 failures)
- `EdenClientSmsThread date separators 3 messages across 3 days → 3 separators`
- `EdenClientSmsThread send callback input "Hello" + send fires onSend with draft`

(Same stash — date-separator finder ambiguity, Icons.send vs Icons.send_rounded.)

### `test/widgets/eden_memorable_date_test.dart` (1 failure)
- `EdenMemorableDate — Section 508 a11y each field has its own Semantics label`

### `test/widgets/eden_permission_matrix_test.dart` (3 failures)
- `EdenPermissionMatrix — break-glass mode enabled tapping break-glass icon opens justification dialog`
- `EdenPermissionMatrix — break-glass mode enabled confirm disabled until justification >= 20 chars`
- `EdenPermissionMatrix — break-glass mode enabled confirm with valid justification fires onBreakGlass(roleId, permId, justification)`

## Rationale for deferral

Per executor `<scope_boundary>` rule: only auto-fix issues DIRECTLY caused
by the current task's changes. None of these widgets are touched by obj 018.
Fixing belongs in the owning objective's follow-up.

## Stashed pre-obj-018 work

A pre-existing local stash (`stash@{0}: pre-obj018-stash`) contains in-flight
fixes for the eden_client_sms_thread_test + eden_intake_form_builder_test
date-separator / icon-name / surface-size issues, plus the
USE_CASES_*_2026-05-17.md research files. Those land independent of
obj 018 — re-apply via `git stash pop stash@{0}` at the operator's
discretion.
