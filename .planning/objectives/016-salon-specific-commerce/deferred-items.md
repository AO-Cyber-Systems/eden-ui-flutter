# Deferred Items — Obj 016 Execution

## Pre-existing test failures (NOT caused by 016)

Observed during 016 wave-1 regression check. These exist in main BEFORE obj 016:

1. `test/widgets/eden_memorable_date_test.dart` — Section 508 a11y per-field Semantics label test fails (from 011-13).
2. `test/widgets/eden_permission_matrix_test.dart` — break-glass dialog opening/confirm/justification tests fail (4 tests, from 011-07).

Both predate obj 016 (commits b70bb3b, aca0ba8). Out of scope per executor scope-boundary rule. Recommended follow-up: separate test-stabilization objective.
