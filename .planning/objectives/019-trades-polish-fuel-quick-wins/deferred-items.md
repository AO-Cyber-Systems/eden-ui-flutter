# Obj 019 — Deferred Items

Out-of-scope issues discovered during execution. Not addressed because they
are pre-existing failures unrelated to obj 019 widget work.

## Pre-existing test failures (8 total)

Failing tests in `eden_permission_matrix_test.dart` and `support_panel_test.dart` —
all from prior objectives. Per memory note `feedback_005_preserve_all_functionality.md`
the previous executor stashed test fixes for these (`stash@{0}: pre-obj018-stash:
leftover test fixes`). They appear unrelated to any obj 019 work.

- `EdenPermissionMatrix — break-glass mode enabled confirm disabled until justification >= 20 chars`
- `EdenPermissionMatrix — break-glass mode enabled confirm with valid justification fires onBreakGlass(...)`
- `EdenPermissionMatrix — break-glass mode enabled cancel closes dialog without firing callback`
- `EdenPermissionMatrix — Section 508 a11y break-glass icon has Semantics announcing override role + permission`
- `EdenSupportPanel Tours tab shows available tours`
- `EdenSupportPanel panel closes when close button tapped`
- `EdenSupportPanel Help tab article detail and feedback`
- (and one duplicate trace)

## Action

Recommend addressing in a follow-up dedicated stabilization pass, OR popping
`stash@{0}` to apply the previously-prepared test fixes.
