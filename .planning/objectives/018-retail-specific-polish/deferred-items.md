# Deferred Items — Objective 018 Retail-Specific Polish

Out-of-scope test failures discovered during obj 018 execution. Not caused
by this objective; left for owners of the affected widgets.

## Pre-existing failing tests (8 total) — `flutter test` baseline at obj 018 start

Observed on `ee594f8` (obj 016 complete) before any 018 commits landed:

### `test/widgets/support_panel_test.dart` (5 failures)
- `EdenSupportPanel renders demo page with FAB`
- `EdenSupportPanel FAB opens panel with tabs`
- `EdenSupportPanel Help tab shows articles after loading`
- `EdenSupportPanel Support tab shows tickets`
- `EdenSupportPanel Tours tab shows available tours`
- `EdenSupportPanel panel closes when close button tapped`
- `EdenSupportPanel Help tab article detail and feedback`

### `test/widgets/eden_permission_matrix_test.dart` (3 failures)
- `EdenPermissionMatrix — break-glass mode enabled confirm disabled until justification >= 20 chars`
- `EdenPermissionMatrix — break-glass mode enabled confirm with valid justification fires onBreakGlass(roleId, permId, justification)`
- `EdenPermissionMatrix — break-glass mode enabled cancel closes dialog without firing callback`
- `EdenPermissionMatrix — Section 508 a11y break-glass icon has Semantics announcing override role + permission`

## Rationale for deferral

Per executor `<scope_boundary>` rule: only auto-fix issues DIRECTLY caused
by the current task's changes. `EdenSupportPanel` and `EdenPermissionMatrix`
are obj 011/013-era widgets; 018 does not touch them. Fixing belongs in
their owning objective's follow-up.
