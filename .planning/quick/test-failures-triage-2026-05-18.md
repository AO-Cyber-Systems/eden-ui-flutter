# Pre-Existing Widget Test Failures — Triage (2026-05-18)

Read-only investigation of 8 deferred test failures. Evidence-based classification with proposed fix scope.

Tests live at `test/widgets/<file>.dart` (flat layout), not in subdirectories as originally reported.

## Section 1 — Per-Test Failure Summary

| # | Test (group → name) | Error | Root Cause Class | Introducing Commit | Proposed Fix LOC |
|---|---|---|---|---|---|
| 1 | `EdenIntakeFormBuilder 3-pane layout (≥900pt) → renders 9 Draggable palette entries` | `Found 0` Draggable<EdenIntakeFieldType\> | **Test logic bug** — missing `setSurfaceSize(Size(1200, 800))`; default 800x600 surface clamps the SizedBox(1200,800) → LayoutBuilder sees maxWidth=800 → builder renders tabbed layout (palette tab not selected, ListView not in tree) | `acc4030 test(016-04): add failing tests for EdenIntakeFormBuilder…` | ~2 LOC (1 setSurfaceSize + addTearDown) per test; cleanest fix is to wrap the 5 affected tests in a shared setUp or add a `_setLargeSurface(tester)` helper |
| 2 | `EdenIntakeFormBuilder 3-pane layout (≥900pt) → Config pane shows empty hint when no field selected` | `Found 0` text "Tap a field to configure" | **Same root cause as #1** — _ConfigPane never mounts because layout falls into tabbed mode | `acc4030` | covered by #1 fix |
| 3 | `EdenClientSmsThread date separators → 3 messages across 3 days → 3 separators` | `Found 2` text "Today" (separator + message body) | **Stale fixture** — `threeSpanningDays()` fixture sets `m3.body = 'Today'` which collides with the date-separator label that same fixture is designed to test | `4daf50b test(016-05): add failing tests for EdenClientSmsThread + fixtures` | ~1 LOC (rename body to e.g. `'Latest'`) in `_fixtures/eden_client_sms_thread_fixtures.dart` |
| 4 | `EdenClientSmsThread send callback → input "Hello" + send fires onSend with draft` | `Found 0` icon U+0E571 (`Icons.send`) | **API drift** — `EdenMessageInput` source uses `Icons.send_rounded`; test asserts `Icons.send` | impl commit `3e3a44f feat(016-05): EdenClientSmsThread + dev catalog…` (test was test-first against the spec'd icon; impl chose a different variant) | ~1 LOC in test (change `Icons.send` → `Icons.send_rounded`) **OR** ~1 LOC in widget to revert to `Icons.send`. See Risk Notes — picking the test side preserves the spec-first intent. |
| 5 | `EdenMemorableDate — Section 508 a11y → each field has its own Semantics label` | `Found 0` semantics label "Month" | **Widget bug (real)** — `_MonthField`/`_DayField`/`_YearField` each wrap children in `Semantics(label: …)` WITHOUT `container: true`/`explicitChildNodes: true`. The TextField below absorbs/overrides the annotation, so the label never becomes a queryable node | impl commit `3cdcd20 feat(011-13): EdenMemorableDate USWDS-conformant M/D/Y…` (test from `b70bb3b` correctly asserts the a11y contract) | ~3 LOC in widget — add `container: true` to each of the 3 `Semantics` widgets at lines 251, 317, 359 of `lib/src/widgets/eden_memorable_date.dart` |
| 6 | `EdenPermissionMatrix → tapping break-glass icon opens justification dialog` | `Found 2` TextField (search box + dialog field) | **Test logic bug** — assertion `find.byType(TextField), findsOneWidget` ignores the pre-existing "Search permissions..." TextField above the matrix; that TextField was already part of the widget before the 011-07 enhancement | test commit `aca0ba8 test(011-07): add baseline + failing tests for EdenPermissionMatrix…` | ~1 LOC — change to `find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField))` |
| 7 | `EdenPermissionMatrix → confirm disabled until justification ≥ 20 chars` | `Bad state: Too many elements` (enterText hits 2 TextField states) | **Same root cause as #6** — `tester.enterText(find.byType(TextField), …)` cannot resolve to one when search + dialog both exist | `aca0ba8` | covered by #6 fix; ~2 LOC (both `enterText` calls need the scoped finder) |
| 8 | `EdenPermissionMatrix → confirm with valid justification fires onBreakGlass(…)` | `Bad state: Too many elements` | **Same root cause as #6** | `aca0ba8` | covered by #6 fix; ~1 LOC |

## Section 2 — Aggregate Scope Recommendation

**Recommended:** `/devflow:build` with 4 small TDD TRDs (one per widget area) — NOT a single `/devflow:quick`, NOT 4× `/devflow:micro`.

**Reasoning:**
- 4 distinct root causes touching 4 unrelated widgets — no single sweep fixes more than one.
- One of the four (#5 Memorable Date) is a **real widget bug** (a11y contract not delivered). That cannot be a test-only edit; it changes shipping code, so it needs a TDD trip (RED test exists; GREEN by adding `container: true`; verify the existing test now passes). Per the TDD playbook this is exactly the kind of `type=tdd` TRD that should not be relaxed.
- The other three (#1+2, #3, #4, #6+7+8) are test-only fixes but each on a different widget — bundling under one quick risks one regression masking another. Atomic per-widget commits give cleaner blame and the executor can run the affected test file as its exit-code proof per fix.
- Total LOC is small (~15 LOC across 4 widgets) but spread enough that 4 narrow TRDs are cheaper than 4 separate micro tasks (which each pay full DevFlow ceremony) and safer than one omnibus quick task.

**Each TRD scope:**
1. TRD-A — `eden_intake_form_builder_test.dart`: add `setSurfaceSize` to 5 `3-pane` testWidgets (test-only).
2. TRD-B — `eden_client_sms_thread_fixtures.dart` + `eden_client_sms_thread_test.dart`: rename fixture body + change `Icons.send` → `Icons.send_rounded` (test-only).
3. TRD-C — `eden_memorable_date.dart`: add `container: true` to 3 Semantics wrappers (**widget code change** — TDD: existing failing a11y test goes RED → GREEN).
4. TRD-D — `eden_permission_matrix_test.dart`: scope TextField finder to dialog descendant in 3 testWidgets (test-only).

## Section 3 — Exact Fix Instructions (Per Test)

### Fix A — Intake Form Builder (test-only)

File: `test/widgets/eden_intake_form_builder_test.dart`

Before each of the 5 `3-pane layout (≥900pt) → …` testWidgets and the tab-mode tests that intentionally use width=600, add an explicit surface size. Cleanest: a helper at top of `main()`:

```dart
Future<void> _setLargeSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1200, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}
```

Then prepend `await _setLargeSurface(tester);` to the 5 `3-pane` tests at lines 66, 80, 94, 105, 116 (and any unaffected sibling tests using default size that also depend on a 3-pane layout).

Why this works: `setSurfaceSize` overrides the test window so `MediaQuery.size` and resulting layout constraints actually reach 1200x800; SizedBox(1200,800) is no longer clamped to 800x600.

### Fix B — SMS Thread (test/fixture-only, 2 spots)

File: `test/widgets/_fixtures/eden_client_sms_thread_fixtures.dart` (line 145):

```dart
// before
body: 'Today',
// after
body: 'Latest',
```

File: `test/widgets/eden_client_sms_thread_test.dart` (line 194):

```dart
// before
final sendIcon = find.byIcon(Icons.send);
// after
final sendIcon = find.byIcon(Icons.send_rounded);
```

### Fix C — Memorable Date (widget code change)

File: `lib/src/widgets/eden_memorable_date.dart` — 3 `Semantics(...)` wrappers at lines 251, 317, 359:

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

Repeat for `_DayField` (line 317, label 'Day') and `_YearField` (line 359, label 'Year').

This makes the Semantics widget emit its own discoverable node rather than annotating the descendant TextField (which already has its own semantics node and absorbs/discards the parent's label without `container: true`).

### Fix D — Permission Matrix (test-only, 3 spots)

File: `test/widgets/eden_permission_matrix_test.dart`

Replace the 3 occurrences (lines 96, 115, 124, 153 — note that 115 and 124 are inside the same testWidgets) of bare `find.byType(TextField)` with:

```dart
final dialogField = find.descendant(
  of: find.byType(AlertDialog),
  matching: find.byType(TextField),
);
```

Then use `dialogField` in `enterText` and the `findsOneWidget` assertion.

## Section 4 — Risk Notes

- **#5 Memorable Date is the only test that surfaces a real shipping bug.** USWDS Section 508 conformance is part of the widget's named contract (`USWDS-conformant M/D/Y input + …`). Screen readers will currently NOT announce "Month/Day/Year" as field names — they'll fall back to whatever the underlying TextField semantics expose. If anything is downstream of this in the gov vertical (eden-ui-flutter Wave A or AOC FedRAMP screens), they may already be silently non-conformant. Worth a smoke test on a real screen reader after fix lands.
- **#4 Icon choice (Icons.send vs Icons.send_rounded).** The test predates the impl in the same objective (016-05); the test was the spec-of-record. Changing the test rather than the widget concedes that the impl chose differently and we're rubber-stamping. Acceptable trade-off (rounded is the more polished visual), but worth a one-line catalog screenshot diff to confirm no other downstream consumer expects `Icons.send` flat.
- **#1+2 Surface size.** No widget defect — the LayoutBuilder breakpoint at 900pt is working as designed. Risk is zero; tests just lacked the `setSurfaceSize` call that the `iPhone-narrow` group correctly uses.
- **#3 Fixture body "Today".** Zero risk; trivial fixture content change.
- **#6/7/8 Permission Matrix.** Zero risk to widget; tests need scoping. Search TextField pre-existed the 011-07 enhancement so the test author overlooked it.

No cross-test pollution detected. No Flutter SDK / deprecation issues observed. All failures reproducible in isolation.
