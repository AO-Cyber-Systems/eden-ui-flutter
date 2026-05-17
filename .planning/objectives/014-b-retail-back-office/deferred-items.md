# Deferred items — Objective 014 B-Retail Back-Office

Issues discovered during obj 014 execution that are **out of scope** for this objective
per executor scope-boundary rule (only auto-fix issues DIRECTLY caused by current task's
changes). Each item is pre-existing and untouched by any obj 014 TRD.

## Pre-existing test failures (full-suite)

### 1. `test/widgets/eden_memorable_date_test.dart` — `each field has its own Semantics label`

- **Status:** PRE-EXISTING (failing on main before obj 014 TRD 014-02 landed).
- **Discovered during:** TRD 014-02 full-suite regression check.
- **Root cause:** `find.bySemanticsLabel('Month' | 'Day' | 'Year')` no longer matches
  the SemanticsNode hierarchy in current Flutter test infrastructure. The widget
  HAS the labeled Semantics ancestors — the test's finder is stale.
- **Fix is staged in this branch's pre-obj-014 stash:** stash uses
  `find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Month'/...)`
  to walk the widget tree directly instead of the SemanticsNode tree. Stash applied
  after obj 014 closes.
- **Out of scope reason:** Test file is for obj-011-08 USWDS conformance; orthogonal
  to retail primitives.

### 2. `test/widgets/eden_permission_matrix_test.dart` — 3 break-glass-dialog tests

- **Status:** PRE-EXISTING (failing on main before obj 014 TRD 014-02 landed).
- **Discovered during:** TRD 014-02 full-suite regression check.
- **Root cause:** `find.byType(TextField)` matches TWO TextFields after a recent change
  (one in the dialog, one elsewhere) — needs to scope to `find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField))`.
- **Fix is staged in this branch's pre-obj-014 stash.** Stash applied after obj 014 closes.
- **Out of scope reason:** Permission matrix is obj-011 compliance overlay; orthogonal.

## Resolution plan

After obj 014 closes:

1. `git stash pop` to restore the fix patches for both test files.
2. Confirm fixes resolve the 4 failures.
3. Commit as a separate `fix(tests): stabilize Section 508 + break-glass finders` commit.
4. Push.

Decision: NOT pulling these fixes into obj 014's commit chain — keeps the objective's
diff bounded to retail-back-office concerns only.
