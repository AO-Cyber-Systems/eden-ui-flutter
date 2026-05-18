---
objective: 5-fix-8-pre-existing-widget-test-failures
mode: quick
type: standard
status: complete
wave: 1
depends_on: []
files_modified:
  - lib/src/widgets/eden_memorable_date.dart
  - test/widgets/eden_intake_form_builder_test.dart
  - test/widgets/_fixtures/eden_client_sms_thread_fixtures.dart
  - test/widgets/eden_client_sms_thread_test.dart
  - test/widgets/eden_permission_matrix_test.dart
files_created: []
commits:
  - e6e84d6 fix(eden_memorable_date): add container:true to M/D/Y Semantics for Section 508
  - bc554a7 test(eden_intake_form_builder): set 1200x800 surface size for 3-pane tests
  - e581798 test(eden_client_sms_thread): rename m1/m2/m3 bodies to avoid date-separator collisions
  - 9ad847c test(eden_client_sms_thread): align send-icon finder with Icons.send_rounded
  - 85c3ee2 test(eden_permission_matrix): scope TextField finder to AlertDialog descendant
tests_added: 0
tests_unblocked: 8
test_baseline_before: "3857 passed / 1 skipped / 8 failed"
test_baseline_after: "3865 passed / 1 skipped / 0 failed"
duration_sec: 577
started_at: 2026-05-18T14:18:57Z
completed_at: 2026-05-18T14:28:34Z
---

# Quick Task 5: Fix 8 Pre-existing Widget Test Failures — Summary

## One-liner

Restored 8 widget tests to GREEN — 1 real Section 508 a11y bug in `EdenMemorableDate` and 4 test-side bugs (surface size, fixture string collisions, icon-codepoint drift, finder scoping) — landed as 5 atomic commits with zero net regressions and zero edits to off-limits directories.

## What Shipped

**1 shipping behavior change (a11y fix):**

- `EdenMemorableDate` Month/Day/Year inner Semantics wrappers now declare `container: true` AND `explicitChildNodes: true` so their `label: 'Month' | 'Day' | 'Year'` is emitted as discoverable a11y nodes rather than being absorbed by the descendant TextField. This restores the Section 508 contract that screen readers (VoiceOver / TalkBack / JAWS) and CAC/PIV-authenticated federal users rely on for self-identifying field announcements.

**4 test-side corrections (no library impact):**

- `eden_intake_form_builder_test.dart` — 3-pane (≥900pt) tests now explicitly call `_setLargeSurface(tester)` (1200x800) so LayoutBuilder reports the wide-mode branch instead of clamping to the 800x600 default and falling into tabbed mode. Paired with `addTearDown(setSurfaceSize(null))` to avoid leaking into the existing `iPhone-narrow (390pt)` group.
- `eden_client_sms_thread_fixtures.dart` — `threeSpanningDays()` message bodies renamed (`Three days ago`/`Yesterday`/`Today` → `Oldest`/`Middle`/`Latest`) so they no longer collide with the date-separator labels the fixture is designed to validate. The `// Do NOT regenerate via LLM` header was preserved literally.
- `eden_client_sms_thread_test.dart` — `find.byIcon(Icons.send)` updated to `find.byIcon(Icons.send_rounded)` to match the widget's intentional rounded variant (per triage Section 4: widget is spec-of-record). An additional `await tester.pump()` was inserted between `enterText` and `tap` so the IconButton has a frame to re-enable (`onPressed` toggles off `null` once the controller is non-empty).
- `eden_permission_matrix_test.dart` — 3 break-glass dialog tests now scope `find.byType(TextField)` to `find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField))` so the pre-existing "Search permissions..." TextField in the matrix toolbar no longer fools `findsOneWidget` / makes `enterText` throw `Bad state: Too many elements`.

## Commits

| # | Hash | Type | Subject | Files | Purpose |
|---|------|------|---------|-------|---------|
| 1 | `e6e84d6` | `fix` | add container:true to M/D/Y Semantics for Section 508 | `lib/src/widgets/eden_memorable_date.dart` (+6) | Real a11y bug fix in shipping widget |
| 2 | `bc554a7` | `test` | set 1200x800 surface size for 3-pane tests | `test/widgets/eden_intake_form_builder_test.dart` (+10) | Test-only — surface dimensions |
| 3 | `e581798` | `test` | rename m1/m2/m3 bodies to avoid date-separator collisions | `test/widgets/_fixtures/eden_client_sms_thread_fixtures.dart` (+3/-3) | Test fixture rename |
| 4 | `9ad847c` | `test` | align send-icon finder with Icons.send_rounded | `test/widgets/eden_client_sms_thread_test.dart` (+2/-1) | Test-only icon + pump |
| 5 | `85c3ee2` | `test` | scope TextField finder to AlertDialog descendant | `test/widgets/eden_permission_matrix_test.dart` (+16/-4) | Test-only — finder scoping |

Net diff: 5 files, +37 / -8 lines. One per file → clean blame trail.

## Tests Unblocked (8 → GREEN)

| # | Test | Was | Now | Fix Commit |
|---|------|-----|-----|------------|
| 1 | `EdenMemorableDate — Section 508 a11y → each field has its own Semantics label` | RED (`Found 0 semantics label 'Month'`) | GREEN | `e6e84d6` |
| 2 | `EdenIntakeFormBuilder 3-pane layout (≥900pt) → renders 9 Draggable palette entries` | RED (`Found 0 Draggable`) | GREEN | `bc554a7` |
| 3 | `EdenIntakeFormBuilder 3-pane layout (≥900pt) → Config pane shows empty hint when no field selected` | RED (`Found 0 text`) | GREEN | `bc554a7` |
| 4 | `EdenClientSmsThread date separators → 3 messages across 3 days → 3 separators` | RED (`Found 2 'Today'`) | GREEN | `e581798` |
| 5 | `EdenClientSmsThread send callback → input "Hello" + send fires onSend with draft` | RED (`Found 0 Icons.send`) | GREEN | `9ad847c` |
| 6 | `EdenPermissionMatrix → tapping break-glass icon opens justification dialog` | RED (`Found 2 TextField`) | GREEN | `85c3ee2` |
| 7 | `EdenPermissionMatrix → confirm disabled until justification ≥ 20 chars` | RED (`Bad state: Too many elements`) | GREEN | `85c3ee2` |
| 8 | `EdenPermissionMatrix → confirm with valid justification fires onBreakGlass(...)` | RED (`Bad state: Too many elements`) | GREEN | `85c3ee2` |

## Task Evidence

| Task | Verify Command | Exit Code | Status |
|------|----------------|-----------|--------|
| 1 (memorable_date) | `flutter test test/widgets/eden_memorable_date_test.dart` | 0 | PASS (13/13) |
| 2 (intake_form_builder) | `flutter test test/widgets/eden_intake_form_builder_test.dart` | 0 | PASS (22/22) |
| 3 (sms_thread_fixtures) | `flutter test test/widgets/eden_client_sms_thread_test.dart --plain-name "3 messages across 3 days"` | 0 | PASS (1/1; full file still had 1 expected fail until Task 4) |
| 4 (sms_thread_test) | `flutter test test/widgets/eden_client_sms_thread_test.dart` | 0 | PASS (20/20) |
| 5 (permission_matrix) | `flutter test test/widgets/eden_permission_matrix_test.dart` | 0 | PASS (12/12) |

## Validation Gate Results

| Gate | Command | Exit Code | Status |
|------|---------|-----------|--------|
| memorable_date file | `flutter test test/widgets/eden_memorable_date_test.dart` | 0 | PASS |
| intake_form_builder file | `flutter test test/widgets/eden_intake_form_builder_test.dart` | 0 | PASS |
| client_sms_thread file | `flutter test test/widgets/eden_client_sms_thread_test.dart` | 0 | PASS |
| permission_matrix file | `flutter test test/widgets/eden_permission_matrix_test.dart` | 0 | PASS |
| full suite | `flutter test` | 0 | PASS (3865 passed / 1 skipped / 0 failed) |
| analyze | `flutter analyze` | n/a | UNCHANGED (270 issues — baseline, no new lints in modified files) |
| off-limits guard | `git diff HEAD~5 --stat -- 'lib/src/widgets/{eden_diagram,eden_process_canvas,eden_workflow_canvas,eden_template_builder,scheduler}/*'` | n/a | PASS (empty output → zero edits) |

## TDD Evidence (Task 1 only)

Task 1 followed the TDD Iron Law using the **existing failing test** as the RED step.

| Phase | Command | Exit Code | Expected | Actual |
|-------|---------|-----------|----------|--------|
| RED | `flutter test test/widgets/eden_memorable_date_test.dart --plain-name "each field has its own Semantics label"` | 1 | FAIL (correct) | `Found 0 widgets matching predicate` — RED confirmed |
| GREEN (initial — `container: true` only) | `flutter test test/widgets/eden_memorable_date_test.dart` | 1 | PASS expected | FAIL — Section 508 test still RED |
| GREEN (final — `container: true` + `explicitChildNodes: true`) | `flutter test test/widgets/eden_memorable_date_test.dart` | 0 | PASS (correct) | All 13 tests pass |
| REFACTOR | (none — minimal edit) | n/a | n/a | n/a |

Tasks 2–5 are test-only commits (no shipping behavior change), so they do not require RED→GREEN ceremony per quick-mode posture.

## Post-TRD Verification

- Auto-fix cycles used: 2 (both in Task 1; both inside the task's `<recovery>` clause)
- Must-haves verified: 5/5
- Gate failures: None

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] EdenMemorableDate required `explicitChildNodes: true` in addition to `container: true`**

- **Found during:** Task 1 GREEN step.
- **Issue:** The triage prescribed `container: true` only, but after applying that change the Section 508 test still failed (`Found 0 widgets matching predicate`). The test uses `find.bySemanticsLabel('Month')`, which traverses the semantics tree. Without `explicitChildNodes: true`, the parent Semantics node still merges with descendants and the label gets absorbed.
- **Fix:** Added `explicitChildNodes: true` alongside `container: true` on all 3 Semantics wrappers (Month/Day/Year). This is the path explicitly authorized by the task's `<recovery>` clause: *"may need `explicitChildNodes: true` as well — but only add this if the test still fails after the minimal fix."* Required by the test, not by my judgment.
- **Files modified:** `lib/src/widgets/eden_memorable_date.dart` (+6 lines vs. the +3 the triage estimated).
- **Commit:** `e6e84d6` (still atomic — single-file, single-feature commit).
- **Impact:** None on shipping behavior beyond the intended a11y fix. `explicitChildNodes: true` further guarantees the parent node is announced separately by screen readers, which strengthens (does not weaken) the Section 508 contract.

**2. [Rule 1 — Bug] EdenClientSmsThread fixture: m1 and m2 bodies also needed renaming (not just m3)**

- **Found during:** Task 3 verification — after renaming `m3.body` from `'Today'` to `'Latest'`, the test still failed with `Found 2 widgets with text "Yesterday"` (separator label colliding with `m2.body: 'Yesterday'`).
- **Issue:** The triage focused on the visible `'Today'` collision but missed that `m1.body: 'Three days ago'` (date separator says `'Wed, May 13'` so this one was actually safe) and `m2.body: 'Yesterday'` (date separator says `'Yesterday'` → collision) had the same class of bug.
- **Fix:** Renamed `m1.body` `'Three days ago'` → `'Oldest'` (defensive — even though `'Wed, May 13'` separator wouldn't collide, future format changes could) and `m2.body` `'Yesterday'` → `'Middle'` to break the collision. Path explicitly authorized by the task's `<recovery>` clause: *"Search the fixture file for any other body: 'Today' lines (m1, m2) — those would also collide."*
- **Files modified:** `test/widgets/_fixtures/eden_client_sms_thread_fixtures.dart` (3 lines changed instead of the 1 the triage estimated).
- **Commit:** `e581798` (commit message updated to reflect m1/m2/m3 scope; still atomic — single fixture file). The `// Do NOT regenerate via LLM` header was preserved literally.
- **Impact:** Zero — the fixture's purpose is to provide 3 messages spanning 3 distinct days for the date-separator test; the body strings carry no semantic meaning to the widget under test. Bodies are just opaque payload.

**3. [Rule 1 — Bug] EdenClientSmsThread send-callback test needed an extra `pump()` between `enterText` and `tap`**

- **Found during:** Task 4 verification — after updating `Icons.send` → `Icons.send_rounded`, `findsOneWidget` passed but `captured` was still `null` after the tap.
- **Issue:** `EdenMessageInput`'s send IconButton has `onPressed: isEmpty || !widget.enabled ? null : _handleSubmit`. With `onPressed: null`, the button is disabled and `tester.tap()` silently no-ops. The `isEmpty` flag is recomputed from the controller in `build()`, and `setState()` is only called via the TextField's `onChanged` → `_handleChanged`. Without a pump after `enterText`, the IconButton hasn't rebuilt yet, so the gesture handler is still bound to `null`.
- **Fix:** Inserted a single `await tester.pump();` between `enterText` and the icon lookup. This commits the pending setState and rebuilds the IconButton with `onPressed: _handleSubmit`.
- **Files modified:** `test/widgets/eden_client_sms_thread_test.dart` (+1 line beyond the icon-name change).
- **Commit:** `9ad847c` (still atomic — single test file). Commit message unchanged from triage prescription since the icon update is the primary fix.
- **Impact:** None on shipping code; the test was relying on implicit timing the controller-driven enabled-state logic doesn't actually provide.

### Architectural Changes Required

None.

## Authentication Gates

None.

## Off-Limits Guardrail

Verified zero modifications to `lib/src/widgets/{eden_diagram,eden_process_canvas,eden_workflow_canvas,eden_template_builder,scheduler}/`:

```
$ git diff HEAD~5 --stat -- \
    'lib/src/widgets/eden_diagram*' \
    'lib/src/widgets/eden_process_canvas*' \
    'lib/src/widgets/eden_workflow_canvas*' \
    'lib/src/widgets/eden_template_builder*' \
    'lib/src/widgets/scheduler/*'
(empty output — guardrail respected)
```

## Transport-Agnostic Invariant

Preserved. No pubspec changes, no platform-flutter coupling, no network calls introduced. The one library edit is pure presentation-layer a11y metadata.

## Hand-Built Fixture Header

`test/widgets/_fixtures/eden_client_sms_thread_fixtures.dart` line 1 still reads `// Do NOT regenerate via LLM — hand-built fixtures for EdenClientSmsThread.` verbatim. Only the 3 `body:` strings inside `threeSpanningDays()` were hand-edited.

## Self-Check

- [x] `lib/src/widgets/eden_memorable_date.dart` exists and contains all 3 `container: true` + `explicitChildNodes: true` flags
- [x] `test/widgets/eden_intake_form_builder_test.dart` has `_setLargeSurface` helper and 5 prepended calls
- [x] `test/widgets/_fixtures/eden_client_sms_thread_fixtures.dart` line 1 = `// Do NOT regenerate via LLM` header preserved
- [x] `test/widgets/eden_client_sms_thread_test.dart` uses `Icons.send_rounded`
- [x] `test/widgets/eden_permission_matrix_test.dart` uses `find.descendant(of: AlertDialog, ...)` in 3 testWidgets
- [x] Commit `e6e84d6` exists in `git log`
- [x] Commit `bc554a7` exists in `git log`
- [x] Commit `e581798` exists in `git log`
- [x] Commit `9ad847c` exists in `git log`
- [x] Commit `85c3ee2` exists in `git log`
- [x] `flutter test` final: 3865 passed / 1 skipped / 0 failed
- [x] Zero off-limits-dir edits

## Self-Check: PASSED
