# Deferred Items — Quick Task 4

Out-of-scope pre-existing test failures observed during execution. NOT caused by this task's dropdown edits (verified by stashing changes and re-running affected suites on clean HEAD — same 8 failures reproduced).

Job's `275 baseline` expectation in `<verify>` is stale; the actual current suite baseline is `3857 passed, 1 skipped, 8 failed` on HEAD (commit 804758e).

## Pre-existing failing tests (8)

1. `test/widgets/eden_intake_form_builder_test.dart` — "3-pane layout (≥900pt) renders 9 Draggable palette entries"
2. `test/widgets/eden_intake_form_builder_test.dart` — "3-pane layout (≥900pt) Config pane shows empty hint when no field selected"
3. `test/widgets/eden_client_sms_thread_test.dart` — "date separators 3 messages across 3 days → 3 separators"
4. `test/widgets/eden_client_sms_thread_test.dart` — "send callback input \"Hello\" + send fires onSend with draft"
5. `test/widgets/eden_memorable_date_test.dart` — "Section 508 a11y each field has its own Semantics label"
6. `test/widgets/eden_permission_matrix_test.dart` — "break-glass mode enabled tapping break-glass icon opens justification dialog"
7. `test/widgets/eden_permission_matrix_test.dart` — "break-glass mode enabled confirm disabled until justification >= 20 chars"
8. `test/widgets/eden_permission_matrix_test.dart` — "break-glass mode enabled confirm with valid justification fires onBreakGlass(roleId, permId, justification)"

## Scope rationale

Quick task 4 touches only `lib/dev_app/screens/` (dev catalog scaffolding). None of the failing tests exercise dev_app scaffolds; they exercise widgets under `lib/src/widgets/` (which is in the off-limits list for this task). Per `deviation_rules.SCOPE_BOUNDARY`, these are logged here rather than fixed.

## Recommendation

File a separate quick task to triage these 8 widget-test failures.
