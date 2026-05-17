# Deferred Items — Objective 021

Pre-existing test failures inherited from earlier objectives. Out of scope per executor scope-boundary rule. Reproduced via `flutter test` at start of TRD 021-01 BEFORE any obj 021 code was added.

## Failures (8 total, all pre-existing)

| Test file | Count | Notes |
|---|---|---|
| `test/widgets/eden_intake_form_builder_test.dart` | 2 | inherited from obj 016 |
| `test/widgets/eden_client_sms_thread_test.dart` | 2 | inherited from obj 016 |
| `test/widgets/eden_memorable_date_test.dart` | 1 | a11y Semantics labelling — pre-existing |
| `test/widgets/eden_permission_matrix_test.dart` | 3 | inherited from obj 011-07 break-glass mode |

## Scope rule

Per devflow executor scope-boundary rule: only auto-fix issues DIRECTLY caused by current task's changes. These failures predate obj 021 and are in files NOT modified by any obj 021 TRD.
