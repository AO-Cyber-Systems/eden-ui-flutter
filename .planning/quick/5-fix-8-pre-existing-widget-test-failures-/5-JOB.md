---
objective: 5-fix-8-pre-existing-widget-test-failures
mode: quick
type: standard
wave: 1
depends_on: []
files_modified:
  - lib/src/widgets/eden_memorable_date/eden_memorable_date.dart
  - test/widgets/eden_intake_form_builder_test.dart
  - test/widgets/_fixtures/eden_client_sms_thread_fixtures.dart
  - test/widgets/eden_client_sms_thread_test.dart
  - test/widgets/eden_permission_matrix_test.dart
autonomous: true
must_haves:
  - All 8 previously-failing widget tests turn GREEN (no skips, no xfails).
  - `flutter test` full-suite baseline stays GREEN — no new regressions in any test file.
  - EdenMemorableDate Section 508 a11y contract is delivered in shipping code (Month/Day/Year Semantics nodes are discoverable, not absorbed by inner TextField).
  - 4 atomic commits land, one per modified file, with a clean blame trail.
  - Zero changes to off-limits dirs (eden_diagram, eden_process_canvas, eden_workflow_canvas, eden_template_builder, lib/src/widgets/scheduler/).
verification_commands:
  - flutter test test/widgets/eden_memorable_date_test.dart
  - flutter test test/widgets/eden_intake_form_builder_test.dart
  - flutter test test/widgets/eden_client_sms_thread_test.dart
  - flutter test test/widgets/eden_permission_matrix_test.dart
  - flutter test
---

<objective>
Fix 8 pre-existing widget test failures (4 distinct root causes) identified by the 2026-05-18 triage. One fix is a real shipping a11y bug on `EdenMemorableDate` (Section 508 contract silently broken); the other three are test-side corrections (surface-size, fixture content, icon API drift, scoped finder). All fixes are surgical — total ~18 LOC across 5 files. Commit strategy: one atomic commit per file fixed for clean blame.

**Source of truth:** `.planning/quick/test-failures-triage-2026-05-18.md` Section 3.
</objective>

<context>
- **Mode:** quick (bugfix posture, ~25% context budget). No new TDD ceremony for the test-side fixes; the Memorable Date widget fix uses the existing failing a11y test as its RED step (TDD Iron Law satisfied: test exists, fails today, must pass after the widget edit). Per user TDD playbook habit 4: hand-built fixtures only, preserve `// Do NOT regenerate via LLM` headers if present.
- **Transport-agnostic invariant:** unchanged. No network, no platform-flutter coupling, no pubspec changes.
- **Quick mode plan format:** single JOB.md (not per-task TRD files). Tasks below are atomic and ordered for natural per-file commit boundaries.
- **Off-limits dirs:** `lib/src/widgets/{eden_diagram,eden_process_canvas,eden_workflow_canvas,eden_template_builder,scheduler}/` — zero edits. None of the target files live in those trees, so this is a guardrail, not a constraint on the fix.
- **Commit tool:** `df-tools commit` (raw `git commit` is blocked by repo guardrails).
- **Per triage Section 4 Risk Notes:** no cross-test pollution; all failures reproducible in isolation; #4 (Icons.send → Icons.send_rounded) accepts the impl as spec-of-record over the earlier test.
</context>

<test_list>
This is the existing failing-test inventory. Each must transition from RED → GREEN. No new tests are written for this job (the triage classifies these as bugfix-class, not new-behavior).

| # | Test | Current State | Target State | Fix Owner |
|---|------|---------------|--------------|-----------|
| 1 | `EdenIntakeFormBuilder 3-pane layout (≥900pt) → renders 9 Draggable palette entries` | RED (Found 0 Draggable) | GREEN | Task 2 |
| 2 | `EdenIntakeFormBuilder 3-pane layout (≥900pt) → Config pane shows empty hint when no field selected` | RED (Found 0 text) | GREEN | Task 2 |
| 3 | `EdenClientSmsThread date separators → 3 messages across 3 days → 3 separators` | RED (Found 2 'Today') | GREEN | Task 3 |
| 4 | `EdenClientSmsThread send callback → input "Hello" + send fires onSend with draft` | RED (Found 0 Icons.send) | GREEN | Task 4 |
| 5 | `EdenMemorableDate — Section 508 a11y → each field has its own Semantics label` | RED (Found 0 semantics label 'Month') | GREEN | Task 1 |
| 6 | `EdenPermissionMatrix → tapping break-glass icon opens justification dialog` | RED (Found 2 TextField) | GREEN | Task 5 |
| 7 | `EdenPermissionMatrix → confirm disabled until justification ≥ 20 chars` | RED (Bad state: Too many elements) | GREEN | Task 5 |
| 8 | `EdenPermissionMatrix → confirm with valid justification fires onBreakGlass(...)` | RED (Bad state: Too many elements) | GREEN | Task 5 |
</test_list>

<embedded_context>
<gotchas>
- **Semantics + TextField absorption.** Without `container: true`, a `Semantics(label: 'X', child: someTextField)` annotation is absorbed by the descendant TextField's own semantics node. The parent label is discarded silently. Screen readers announce only the TextField's intrinsic semantics. Fix: add `container: true` to force the parent Semantics to emit its own discoverable node alongside the child.
- **`setSurfaceSize` lifecycle.** Always pair with `addTearDown(() => tester.binding.setSurfaceSize(null))` so the next test isn't polluted with the previous test's window size. The `iPhone-narrow` group in the same test file already follows this pattern — mimic it.
- **Fixture file headers.** If `test/widgets/_fixtures/eden_client_sms_thread_fixtures.dart` starts with `// Do NOT regenerate via LLM` (or similar), preserve that header literally. Hand-edit the one line; do not reformat the file.
- **Icons.send vs Icons.send_rounded.** Different codepoints (U+0E163 vs U+0E571). `find.byIcon` matches on IconData equality, so the codepoint mismatch is the failure mode. Per triage Section 4: impl is spec-of-record, test is wrong.
- **`find.descendant` scoping.** `find.byType(TextField)` matches all TextFields in the tree. When a widget grows a sibling field (e.g. a search box added before the dialog feature), pre-existing tests with `findsOneWidget` start failing. Scope to `find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField))` to restore intent.
</gotchas>

<anti_patterns>
- DO NOT change `lib/src/widgets/eden_message_input.dart` (or wherever `Icons.send_rounded` lives) to revert to `Icons.send`. The widget is the spec; the test is wrong. (Triage Section 4 confirmed.)
- DO NOT add new test cases — the triage already inventoried 8 failing tests; this objective makes those 8 pass and nothing more.
- DO NOT consolidate the 4 fixes into one commit. Atomic per-file commits are an explicit constraint for clean blame.
- DO NOT use raw `git commit` — repo guardrails reject it. Use `df-tools commit`.
- DO NOT touch off-limits dirs even incidentally (eden_diagram, eden_process_canvas, eden_workflow_canvas, eden_template_builder, lib/src/widgets/scheduler/).
- DO NOT regenerate fixture data via LLM. Hand-edit the single offending line.
</anti_patterns>

<codebase_examples>
**Existing `setSurfaceSize` pattern in same test file** (triage Section 3 references it as a working sibling group — mimic exactly):
```dart
Future<void> _setLargeSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1200, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}
```

**Existing `Semantics(container: true, ...)` pattern elsewhere in eden-ui-flutter** — Semantics-with-container is the correct Flutter idiom for "I want my own a11y node, don't merge me into my child." Look at any existing form-field widget in `lib/src/widgets/` that wraps Semantics around an input for a reference shape.

**`find.descendant` scoping pattern** — standard Flutter widget test idiom:
```dart
final dialogField = find.descendant(
  of: find.byType(AlertDialog),
  matching: find.byType(TextField),
);
expect(dialogField, findsOneWidget);
await tester.enterText(dialogField, 'some text...');
```
</codebase_examples>
</embedded_context>

<validation_gates>
- `flutter test test/widgets/eden_memorable_date_test.dart` — verifies Task 1 (RED → GREEN).
- `flutter test test/widgets/eden_intake_form_builder_test.dart` — verifies Task 2 (tests #1, #2 green).
- `flutter test test/widgets/eden_client_sms_thread_test.dart` — verifies Tasks 3 + 4 (tests #3, #4 green).
- `flutter test test/widgets/eden_permission_matrix_test.dart` — verifies Task 5 (tests #6, #7, #8 green).
- `flutter test` — final full-suite gate; baseline must remain GREEN.
- `flutter analyze` — must remain GREEN (no new lints).
</validation_gates>

<tasks>

<task type="auto" tdd="true">
  <name>Fix EdenMemorableDate Section 508 a11y: add container: true to Month/Day/Year Semantics wrappers</name>
  <files>lib/src/widgets/eden_memorable_date/eden_memorable_date.dart</files>
  <action>
This is the only task that modifies shipping code. The existing test `EdenMemorableDate — Section 508 a11y → each field has its own Semantics label` is the RED step (currently fails with `Found 0 semantics label 'Month'`). This commit is the GREEN step.

Open `lib/src/widgets/eden_memorable_date/eden_memorable_date.dart`. Locate the three `Semantics(label: 'Month' | 'Day' | 'Year', ...)` wrappers (triage references lines ~251, 317, 359 in the historical layout — actual current line numbers may have shifted since the triage snapshot, so find them by label string).

For each of the 3 wrappers, add `container: true` as a sibling field to the existing `label:`:

```dart
// before
return Semantics(
  label: 'Month',
  child: Column(...),
);

// after
return Semantics(
  label: 'Month',
  container: true,
  child: Column(...),
);
```

Repeat for `_DayField` (label: 'Day') and `_YearField` (label: 'Year').

# CRITICAL: Without `container: true`, the descendant TextField's semantics node absorbs/discards the parent label. Screen readers then announce only the TextField's intrinsic semantics, NOT "Month"/"Day"/"Year". This is the Section 508 contract violation.
# GOTCHA: Do NOT also add `explicitChildNodes: true` — the triage prescribes only `container: true`, and adding more flags risks changing the semantics tree shape in ways the existing test doesn't expect.
# PATTERN: Keep edits minimal — 3 lines added, no other reshaping of the widget.

After the edit, run `flutter test test/widgets/eden_memorable_date_test.dart` to confirm the a11y test now passes.

Commit with `df-tools commit`:
- Message: `fix(eden_memorable_date): add container:true to M/D/Y Semantics for Section 508`
- Files: `lib/src/widgets/eden_memorable_date/eden_memorable_date.dart`
  </action>
  <verify>
`flutter test test/widgets/eden_memorable_date_test.dart` — all tests in the file pass, including the previously-failing `each field has its own Semantics label` test.
  </verify>
  <done>
- 3 lines added (`container: true,`) in the widget file, one per Month/Day/Year Semantics wrapper.
- The previously-failing a11y test now passes.
- Atomic commit landed via `df-tools commit` with the message above.
- No other files modified in this commit.
  </done>
  <recovery>
If the test still fails after adding `container: true`:
- Confirm all 3 wrappers got the flag (search the file for `label: 'Month'`, `label: 'Day'`, `label: 'Year'` — each must have a `container: true` sibling).
- Confirm the test expectation matches what `container: true` produces. If the test asserts the label appears as a top-level semantics node (typical), `container: true` is sufficient. If it asserts something stricter (e.g. label without merging), may need `explicitChildNodes: true` as well — but only add this if the test still fails after the minimal fix.
- If still red: do NOT remove the `container: true` flag. The flag is correct per Flutter docs; the test may need closer reading. Surface a diagnostic dump via `debugDumpSemanticsTree()` from inside the failing test to inspect the actual tree.
  </recovery>
</task>

<task type="auto">
  <name>Fix EdenIntakeFormBuilder 3-pane tests: set 1200x800 surface size for tests #1 and #2</name>
  <files>test/widgets/eden_intake_form_builder_test.dart</files>
  <action>
Test-only fix. Default Flutter test surface is 800x600; the widget's `SizedBox(1200, 800)` gets clamped, LayoutBuilder reports maxWidth=800, and the widget falls into tabbed mode (not 3-pane). The palette ListView and config pane never mount, so `find.byType(Draggable<EdenIntakeFieldType>)` returns Found 0.

Open `test/widgets/eden_intake_form_builder_test.dart`. Add a helper at the top of `main()`:

```dart
Future<void> _setLargeSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1200, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}
```

Then prepend `await _setLargeSurface(tester);` as the first line inside each of the 5 testWidgets in the `3-pane layout (≥900pt)` group (triage references lines ~66, 80, 94, 105, 116 — verify by group membership, not line numbers).

The 2 failing tests are inside that group (renders 9 Draggable palette entries; Config pane empty-hint). Adding the helper to all 5 tests in the group keeps the group internally consistent and prevents the other 3 from regressing if they currently pass by accident.

# CRITICAL: `addTearDown(() => tester.binding.setSurfaceSize(null))` is mandatory — without it, the 1200x800 size leaks into subsequent tests and may break the tab-mode tests in the same file (which intentionally use 600pt width).
# PATTERN: Mirror the `iPhone-narrow` group in the same file if it already uses `setSurfaceSize` — same idiom, different dimensions.
# GOTCHA: Do NOT wrap the widget itself with a SizedBox in the test. `setSurfaceSize` is the correct lever; SizedBox composition won't override `MediaQuery.size` which is what LayoutBuilder reads.

Run `flutter test test/widgets/eden_intake_form_builder_test.dart` to confirm both previously-failing tests now pass and no other test in the file regresses.

Commit with `df-tools commit`:
- Message: `test(eden_intake_form_builder): set 1200x800 surface size for 3-pane tests`
- Files: `test/widgets/eden_intake_form_builder_test.dart`
  </action>
  <verify>
`flutter test test/widgets/eden_intake_form_builder_test.dart` — all tests pass, including the previously-failing `renders 9 Draggable palette entries` and `Config pane shows empty hint when no field selected`.
  </verify>
  <done>
- Helper `_setLargeSurface` added at top of `main()`.
- `await _setLargeSurface(tester);` prepended to all 5 testWidgets in `3-pane layout (≥900pt)` group.
- Previously-failing tests #1 and #2 now pass.
- All other tests in the file still pass.
- Atomic commit landed via `df-tools commit`.
  </done>
  <recovery>
If a sibling test in the same file regresses (e.g. a tab-mode test that intentionally used 600pt):
- That test likely also needs an explicit `setSurfaceSize(Size(600, 800))` with matching teardown. Pre-add the size it expects rather than relying on the default.
- Confirm the teardown via `addTearDown` is reached (no early `return` before it).
  </recovery>
</task>

<task type="auto">
  <name>Fix EdenClientSmsThread fixture: rename m3.body so it doesn't collide with date-separator 'Today'</name>
  <files>test/widgets/_fixtures/eden_client_sms_thread_fixtures.dart</files>
  <action>
Test-fixture-only fix. The `threeSpanningDays()` fixture builder sets the third message body to literal string `'Today'`, which collides with the date-separator label the same fixture is designed to validate. The date-separator test finds 2 occurrences of `'Today'` (separator label + message body) and fails the `findsOneWidget`-style assertion.

Open `test/widgets/_fixtures/eden_client_sms_thread_fixtures.dart` (triage references line 145).

**Preserve any `// Do NOT regenerate via LLM` header** if present — hand-edit only the offending line.

Find the line:
```dart
body: 'Today',
```
inside `threeSpanningDays()` (specifically the `m3` message).

Change to:
```dart
body: 'Latest',
```

(Triage suggested `'Latest'`; alternative non-colliding strings like `'Today is going to be busy'` or `'Reminder for today'` would also work, but `'Latest'` is the shortest and matches the triage prescription.)

# CRITICAL: Hand-edit only the one line. Do NOT reformat the file, regenerate via tooling, or touch other fixture entries.
# GOTCHA: If the file header says `// Do NOT regenerate via LLM` — that header MUST stay. It exists precisely to prevent the LLM-generated test data anti-pattern (per user TDD playbook habit 4).
# PATTERN: One-line surgical edit. No new fixture, no schema change.

Run `flutter test test/widgets/eden_client_sms_thread_test.dart` to confirm the date-separator test now passes. (The other previously-failing test in this file — `send callback` — is addressed in Task 4 and may still fail after this commit; that is expected.)

Commit with `df-tools commit`:
- Message: `test(eden_client_sms_thread): rename m3.body to avoid 'Today' collision`
- Files: `test/widgets/_fixtures/eden_client_sms_thread_fixtures.dart`
  </action>
  <verify>
`flutter test test/widgets/eden_client_sms_thread_test.dart --plain-name "3 messages across 3 days"` — date-separator test passes. (Full file may still have the `send callback` test failing until Task 4 lands; that is acceptable mid-task.)
  </verify>
  <done>
- One line changed: `m3.body` value updated from `'Today'` to `'Latest'` (or equivalent non-colliding string).
- `// Do NOT regenerate via LLM` header preserved if present.
- Date-separator test passes.
- Atomic commit landed via `df-tools commit`.
- No other fixture entries modified.
  </done>
  <recovery>
If the date-separator test still finds 2 `'Today'` matches after the rename:
- Search the fixture file for any other `body: 'Today'` lines (m1, m2) — those would also collide.
- Confirm the date-separator widget renders `'Today'` literally (not a localized variant) for the asserted day; if it renders e.g. `'today'` lowercase or with a tilde, the test+fixture pair may have a different intent than triage assumed. In that case, surface a question rather than guessing.
  </recovery>
</task>

<task type="auto">
  <name>Fix EdenClientSmsThread send-callback test: update Icons.send → Icons.send_rounded</name>
  <files>test/widgets/eden_client_sms_thread_test.dart</files>
  <action>
Test-only fix. The `EdenMessageInput` widget uses `Icons.send_rounded` (codepoint U+0E571), but the test asserts `find.byIcon(Icons.send)` (codepoint U+0E163). Per triage Section 4: the widget is the intended design (rounded is the more polished visual); the test is wrong and we update the test rather than reverting the widget.

Open `test/widgets/eden_client_sms_thread_test.dart` (triage references line 194).

Find:
```dart
final sendIcon = find.byIcon(Icons.send);
```

Change to:
```dart
final sendIcon = find.byIcon(Icons.send_rounded);
```

# CRITICAL: Do NOT modify `lib/src/widgets/eden_message_input.dart` (or wherever `Icons.send_rounded` is rendered). The widget is the spec-of-record per triage Section 4 Risk Notes.
# GOTCHA: Confirm there's only ONE occurrence of `Icons.send` in the test file. If there are multiple, update only the one used by the `send callback` test; others may be intentional (e.g. testing a different button).

Run `flutter test test/widgets/eden_client_sms_thread_test.dart` to confirm BOTH previously-failing tests in this file (date separators from Task 3 + send callback from this task) now pass.

Commit with `df-tools commit`:
- Message: `test(eden_client_sms_thread): align send-icon finder with Icons.send_rounded`
- Files: `test/widgets/eden_client_sms_thread_test.dart`
  </action>
  <verify>
`flutter test test/widgets/eden_client_sms_thread_test.dart` — entire file passes, including `send callback → input "Hello" + send fires onSend with draft`.
  </verify>
  <done>
- One line changed: `Icons.send` → `Icons.send_rounded` in the `send callback` test.
- Send-callback test passes.
- Date-separator test (from Task 3) still passes.
- Atomic commit landed via `df-tools commit`.
- Widget source code untouched.
  </done>
  <recovery>
If the test still fails after the rename:
- Confirm `EdenMessageInput` actually renders `Icons.send_rounded` (grep the lib/ tree). If the widget renders some other icon entirely (e.g. `Icons.arrow_forward`), the test is asserting against an outdated spec and needs to match the actual rendered icon.
- Confirm there's only one IconButton in the input toolbar; if multiple, the `find.byIcon` may need additional scoping.
  </recovery>
</task>

<task type="auto">
  <name>Fix EdenPermissionMatrix tests: scope TextField finder to AlertDialog descendant</name>
  <files>test/widgets/eden_permission_matrix_test.dart</files>
  <action>
Test-only fix. The widget has a pre-existing "Search permissions..." TextField above the matrix; tests use bare `find.byType(TextField)` and now find 2 matches (search box + dialog field). `findsOneWidget` fails; `enterText` throws `Bad state: Too many elements`. Fix: scope the finder to `find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField))`.

Open `test/widgets/eden_permission_matrix_test.dart` (triage references lines 96, 115, 124, 153).

For each of the 3 testWidgets affected (tests #6, #7, #8), introduce a scoped finder at the top of the test body and use it in place of `find.byType(TextField)`:

```dart
final dialogField = find.descendant(
  of: find.byType(AlertDialog),
  matching: find.byType(TextField),
);
```

Then replace usages:
- `expect(find.byType(TextField), findsOneWidget)` → `expect(dialogField, findsOneWidget)`
- `tester.enterText(find.byType(TextField), '...')` → `tester.enterText(dialogField, '...')`

Apply to all 3 affected testWidgets (the triage notes line 115 and 124 are inside the same testWidgets — that test has 2 `enterText` calls, both need the scoped finder).

# CRITICAL: Do NOT remove the "Search permissions..." TextField from the widget. It's a pre-existing, intentional feature; the tests overlooked it.
# GOTCHA: If a test has BOTH a `findsOneWidget` assertion and an `enterText` call on TextField, BOTH need updating. Don't update one and leave the other.
# PATTERN: Declare `final dialogField = find.descendant(...)` once at the top of each testWidgets body for readability; reuse it in all assertions/interactions.

Run `flutter test test/widgets/eden_permission_matrix_test.dart` to confirm all 3 previously-failing tests now pass.

Commit with `df-tools commit`:
- Message: `test(eden_permission_matrix): scope TextField finder to AlertDialog descendant`
- Files: `test/widgets/eden_permission_matrix_test.dart`
  </action>
  <verify>
`flutter test test/widgets/eden_permission_matrix_test.dart` — all tests pass, including the 3 previously-failing tests (`tapping break-glass icon opens justification dialog`, `confirm disabled until justification ≥ 20 chars`, `confirm with valid justification fires onBreakGlass(...)`).
  </verify>
  <done>
- 3 testWidgets updated to use scoped `find.descendant(of: AlertDialog, matching: TextField)` finder.
- All 3 previously-failing tests pass.
- Other tests in the file still pass.
- Atomic commit landed via `df-tools commit`.
- Widget source untouched.
  </done>
  <recovery>
If a test still fails after scoping:
- Confirm the dialog actually contains a TextField (not e.g. a TextFormField or some custom input). If TextFormField, `find.descendant(of: AlertDialog, matching: find.byType(TextFormField))` is the correct scope.
- Confirm the dialog has opened by the time the finder runs (`tester.pumpAndSettle()` after the tap that opens the dialog).
- If `find.byType(AlertDialog)` itself returns nothing, the dialog may use `Dialog` or a custom widget — switch the `of:` argument accordingly.
  </recovery>
</task>

</tasks>

<verification>
After all 5 tasks complete and commit:

1. **Per-file gates** (already covered in each task's `<verify>`):
   - `flutter test test/widgets/eden_memorable_date_test.dart` — GREEN
   - `flutter test test/widgets/eden_intake_form_builder_test.dart` — GREEN
   - `flutter test test/widgets/eden_client_sms_thread_test.dart` — GREEN
   - `flutter test test/widgets/eden_permission_matrix_test.dart` — GREEN

2. **Full-suite gate** (must run last):
   - `flutter test` — ENTIRE suite GREEN. No regressions in any test file.

3. **Lint gate**:
   - `flutter analyze` — GREEN. No new lints introduced.

4. **Commit log gate**:
   - `git log --oneline -5` shows 4 atomic commits with the messages prescribed in each task (one per file modified).
   - Each commit touches exactly one file.

5. **Off-limits guard gate**:
   - `git diff <objective-start>..HEAD --stat` shows NO files modified under `lib/src/widgets/{eden_diagram,eden_process_canvas,eden_workflow_canvas,eden_template_builder,scheduler}/`.

6. **Section 508 spot check** (manual, optional):
   - Memorable Date widget in dev catalog: VoiceOver / TalkBack announces "Month", "Day", "Year" when focusing each field. (Not strictly gated since the widget test covers the contract, but worth a real-screen-reader smoke per triage Section 4 risk note about gov vertical / FedRAMP downstream consumers.)
</verification>

<success_criteria>
- 8/8 previously-failing widget tests now pass.
- `flutter test` baseline GREEN (no new regressions).
- `flutter analyze` GREEN (no new lints).
- 4 atomic commits in git log, one per file fixed, with prescribed messages.
- Zero edits to off-limits dirs.
- `// Do NOT regenerate via LLM` header preserved in fixture file (if present).
- EdenMemorableDate Section 508 a11y contract delivered in shipping code (`container: true` on all 3 Semantics wrappers).
- Transport-agnostic invariant unchanged (no new pubspec deps, no platform-flutter coupling).
</success_criteria>

<output>
- 1 widget file modified: `lib/src/widgets/eden_memorable_date/eden_memorable_date.dart` (3 lines added — Section 508 a11y fix, shipping behavior change).
- 4 test files modified: `test/widgets/eden_intake_form_builder_test.dart`, `test/widgets/_fixtures/eden_client_sms_thread_fixtures.dart`, `test/widgets/eden_client_sms_thread_test.dart`, `test/widgets/eden_permission_matrix_test.dart` (~15 LOC total across all 4 — test-side corrections).
- 4 atomic commits in git history with per-file blame trail.
- 8 widget tests transitioned RED → GREEN; full-suite `flutter test` baseline preserved.
</output>
