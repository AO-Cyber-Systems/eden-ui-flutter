---
quick: 1
slug: edenpageheader-iphone-narrow-layoutbuild
type: tdd
confidence: high
wave: 1
depends_on: []
files_modified:
  - lib/src/widgets/eden_page_header.dart
  - test/widgets/eden_page_header_test.dart
autonomous: true
requirements: [RESP-01, RESP-02, RESP-03]

must_haves:
  truths:
    - "EdenPageHeader at iPhone-narrow (390pt) with 3 actions renders without RenderFlex overflow"
    - "EdenPageHeader at iPhone-narrow with actions stacks the actions block below the title block"
    - "EdenPageHeader at desktop width (>=1024pt) preserves the original side-by-side title+actions layout"
    - "EdenPageHeader with 0 actions skips the breakpoint logic and renders the original Row at all widths"
    - "All existing widget tests in test/widgets/ continue to pass after the fix"
  artifacts:
    - path: "test/widgets/eden_page_header_test.dart"
      provides: "Widget test coverage for EdenPageHeader at narrow + wide viewports"
      contains: "testWidgets"
    - path: "lib/src/widgets/eden_page_header.dart"
      provides: "EdenPageHeader with LayoutBuilder + 480pt breakpoint stacking actions vertically on narrow"
      contains: "LayoutBuilder"
  key_links:
    - from: "lib/src/widgets/eden_page_header.dart"
      to: "constraints.maxWidth < 480"
      via: "LayoutBuilder builder branch"
      pattern: "constraints\\.maxWidth\\s*<\\s*480"
    - from: "test/widgets/eden_page_header_test.dart"
      to: "tester.view.physicalSize"
      via: "iPhone-narrow viewport setup"
      pattern: "tester\\.view\\.physicalSize"
---

<objective>
Fix the iPhone-narrow `RenderFlex overflowed` regression in `EdenPageHeader` (RESP-01..03) by introducing a `LayoutBuilder` with a 480pt breakpoint that stacks actions below the title block on narrow viewports, while preserving the original side-by-side layout on wide viewports.

Purpose: Widget regressions in this lib propagate to every downstream Eden app — `EdenPageHeader` is used on every page; iPhone-narrow overflow is a visible production bug. RESP-01..03 collectively gate the v1 milestone.

Output:
- 1 new widget test file with 8 test cases covering narrow + wide + edge variants
- 1 modified widget file with the `LayoutBuilder` + 480pt breakpoint pattern (proven downstream in eden-biz-flutter `dea58e9`)
- 2 atomic commits: `test:` (RED) → `feat:` (GREEN)
</objective>

<file_tree>
lib/src/widgets/
└── eden_page_header.dart                ← MODIFY (Row -> LayoutBuilder + breakpoint)

test/widgets/
└── eden_page_header_test.dart           ← CREATE (8 testWidgets cases)
</file_tree>

<execution_context>
@/Users/markemerson/.claude/devflow/workflows/execute-trd.md
@/Users/markemerson/.claude/devflow/templates/summary.md
</execution_context>

<embedded_context>

<codebase_examples>

**Existing widget test pattern — `test/widgets/eden_alert_test.dart`** (mirror this structure exactly):
```dart
import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenAlert', () {
    testWidgets('renders message text', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenAlert(message: 'Something happened'),
      ));
      expect(find.text('Something happened'), findsOneWidget);
    });
    // ...
  });
}
```

**Current `EdenPageHeader` source — `lib/src/widgets/eden_page_header.dart`** (the bare-Row implementation that overflows):
```dart
return Padding(
  padding: const EdgeInsets.only(bottom: EdenSpacing.space6),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (leading != null) ...[
        leading!,
        const SizedBox(width: EdenSpacing.space3),
      ],
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.headlineMedium),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(description!, style: ...),
            ],
          ],
        ),
      ),
      if (actions != null && actions!.isNotEmpty) ...[
        const SizedBox(width: EdenSpacing.space3),
        Row(mainAxisSize: MainAxisSize.min, children: [...actions...]),
      ],
    ],
  ),
);
```

**Package barrel exports** — `lib/eden_ui.dart` re-exports `EdenPageHeader` and `EdenSpacing`. Test imports use the barrel: `import 'package:eden_ui_flutter/eden_ui.dart';` (NOT relative paths into `lib/src/`).

**Public widget API to preserve** (constructor signature must not change):
```dart
EdenPageHeader({
  super.key,
  required this.title,        // String
  this.description,           // String?
  this.actions,               // List<Widget>?
  this.leading,               // Widget?
});
```

</codebase_examples>

<anti_patterns>

- **Do NOT change the constructor signature.** `EdenPageHeader` is exported from `lib/eden_ui.dart` and consumed by every downstream Eden Flutter app. Adding required params or renaming fields breaks every consumer.
- **Do NOT import via relative paths in tests.** All other `test/widgets/*_test.dart` files import via the package barrel `package:eden_ui_flutter/eden_ui.dart`. Stay consistent.
- **Do NOT introduce platform / transport / business logic into the widget.** Per `eden-libs/CLAUDE.md`: `eden-ui-flutter` must remain transport-agnostic. This fix is pure layout — no platform checks (`Platform.isIOS`), no MediaQuery-platform sniffing. Use `LayoutBuilder` constraints only.
- **Do NOT add MediaQuery-based breakpoints** — use `LayoutBuilder` so the widget responds to its parent's constraints (correct behavior inside Drawers, side panels, dialogs at any window size). This matches the eden-biz-flutter `_GlobalTopBar` pattern that already shipped.
- **Do NOT batch behavior tests with the production fix in one commit.** Iron Law: RED commit (failing test) lands first, GREEN commit (production fix) lands second. Verify RED actually fails before writing the fix — `flutter test test/widgets/eden_page_header_test.dart` must exit non-zero on Task 1.
- **Do NOT forget viewport teardown.** `addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });` in every viewport-modifying test. Without it, viewport state leaks across test cases and contaminates other tests in the same run.

</anti_patterns>

<error_recovery>

**If RED step doesn't fail (Task 1):** The bare-Row layout SHOULD throw `RenderFlex overflowed` at 390pt with 3 ElevatedButton actions. If `tester.takeException()` returns null on the narrow case:
1. Check that `tester.view.physicalSize = const Size(390, 844)` is set BEFORE `pumpWidget` — viewport must be applied to the test view before the first frame.
2. Confirm `tester.view.devicePixelRatio = 1.0` is set — without this, the default dpr can yield a logical width >480pt even at physicalSize 390.
3. Use buttons with non-trivial labels (e.g. `Text('Action $i')` not `Text('A')`) — single-letter buttons may fit even in the bare-Row layout.
4. Increase action count to 3-4 — 1-2 small buttons may also fit.

**If GREEN step regresses other tests (Task 2):** Run `flutter test test/widgets/` and inspect failures. The most likely culprits:
- Viewport state leakage from Task 1 tests — add the `addTearDown` block to every narrow-viewport test.
- A downstream consumer test that asserted on the exact widget tree shape (Row > Column > ...). The widget tree NOW has a `LayoutBuilder` wrapper. None of the existing 30 widget tests touch `EdenPageHeader` directly (verify via `grep -r "EdenPageHeader" test/`), but if one does, update its tree-shape assertion.

**If `flutter analyze` warns about unused imports / variables in the new test file:** Remove the unused symbols. Common offender: importing `EdenSpacing` in the test file but never using it directly. Test cases assert on rendered output, not on spacing constants.

**Rollback path:** Each task is one commit. Task 1 RED commit on its own is harmless (a failing test in a new file). If Task 2 GREEN goes sideways, `git revert HEAD` reverts the production fix, leaving the failing test in place for the next attempt.

</error_recovery>

</embedded_context>

<context>
@/Users/markemerson/Source/eden-libs/eden-ui-flutter/.planning/PROJECT.md
@/Users/markemerson/Source/eden-libs/eden-ui-flutter/.planning/REQUIREMENTS.md
@/Users/markemerson/Source/eden-libs/eden-ui-flutter/.planning/STATE.md
@/Users/markemerson/Source/eden-libs/eden-ui-flutter/lib/src/widgets/eden_page_header.dart
@/Users/markemerson/Source/eden-libs/eden-ui-flutter/test/widgets/eden_alert_test.dart
@/Users/markemerson/Source/eden-libs/eden-ui-flutter/lib/src/tokens/spacing.dart
@/Users/markemerson/Source/eden-libs/eden-ui-flutter/lib/eden_ui.dart
</context>

<gotchas>

- **Viewport semantics in flutter_test:** `tester.view.physicalSize` is in PHYSICAL pixels; logical width = `physicalSize.width / devicePixelRatio`. Set `devicePixelRatio = 1.0` so `Size(390, 844)` yields logical 390x844 (iPhone 14 logical). Without forcing dpr=1.0, the default test view dpr can be 3.0 and you'd actually be testing a logical 130pt viewport (which would also overflow but for the wrong reason).
- **`addTearDown` ordering:** Register teardown IMMEDIATELY after setting `physicalSize` / `devicePixelRatio`, before `pumpWidget`. If the test throws mid-pump, you still want the reset to fire so subsequent tests aren't poisoned.
- **`tester.takeException()` is one-shot:** It returns the FIRST framework error since the last call and clears the buffer. Call it ONCE per test after the relevant pump. For overflow assertions: `expect(tester.takeException(), isNull);` after `pumpWidget` confirms no `FlutterError` was thrown during layout.
- **`Wrap` vs `Row` for the actions block:** Use `Wrap` for the actions on the narrow stacked path — actions can themselves be too wide for a single 390pt row (e.g. 3 buttons with long labels). `Wrap` line-breaks them; a `Row` would re-overflow horizontally even after the vertical stacking fix.
- **`Expanded` only on the wide path:** On the stacked-vertical path, the title block must NOT be wrapped in `Expanded` (no Flex parent). On the wide path, `Expanded(child: titleBlock)` is required so title takes remaining width after actions.
- **480pt threshold rationale:** iPhone Pro Max logical width is ~430pt; iPad Mini portrait is ~768pt. 480pt sits cleanly between phones-portrait and tablets-portrait, matching the eden-biz-flutter `_GlobalTopBar` precedent. Don't bikeshed the number — match the existing downstream convention.

</gotchas>

<tasks>

<task type="auto">
  <name>Task 1 (RED): create test/widgets/eden_page_header_test.dart with 8 failing testWidgets cases</name>
  <files>test/widgets/eden_page_header_test.dart</files>
  <action>
Create `test/widgets/eden_page_header_test.dart` mirroring the structure of `test/widgets/eden_alert_test.dart`. Import via the package barrel `package:eden_ui_flutter/eden_ui.dart`.

Define a top-level `Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));` helper.

Write `group('EdenPageHeader', () { ... })` with these 8 testWidgets cases. Each viewport-modifying test must register `addTearDown` to reset physicalSize and devicePixelRatio before any `pumpWidget` call.

Test list (write ALL of these in this single RED commit — no batching deferred to a later commit):

1. `'renders without overflow at iPhone-narrow (390x844, dpr 1.0) with 3 ElevatedButton actions'`
   - Set `tester.view.physicalSize = const Size(390, 844); tester.view.devicePixelRatio = 1.0;`
   - Pump `EdenPageHeader(title: 'Settings', actions: [for (int i = 0; i < 3; i++) ElevatedButton(onPressed: () {}, child: Text('Action $i'))])`
   - Assert `expect(tester.takeException(), isNull);`
   - Assert `expect(find.text('Settings'), findsOneWidget);`
   - Assert each `'Action 0'`, `'Action 1'`, `'Action 2'` is `findsOneWidget`.

2. `'renders original Row layout at iPhone-narrow when actions is null (no breakpoint logic triggered)'`
   - Same narrow viewport.
   - Pump `EdenPageHeader(title: 'Profile')` (no actions, no description, no leading).
   - Assert no exception, title found.

3. `'renders original Row layout at iPhone-narrow when actions is empty list'`
   - Same narrow viewport.
   - Pump `EdenPageHeader(title: 'Profile', actions: [])`.
   - Assert no exception, title found. (Confirms `actions!.isNotEmpty` short-circuits the breakpoint.)

4. `'stacks actions below title block at iPhone-narrow with leading widget + 2 actions'`
   - Same narrow viewport.
   - Pump `EdenPageHeader(title: 'Account', leading: Icon(Icons.person), description: 'Manage your details', actions: [TextButton(onPressed: () {}, child: Text('Cancel')), ElevatedButton(onPressed: () {}, child: Text('Save'))])`.
   - Assert no exception.
   - Assert `find.byIcon(Icons.person)`, `find.text('Account')`, `find.text('Manage your details')`, `find.text('Cancel')`, `find.text('Save')` all `findsOneWidget`.

5. `'preserves side-by-side layout at desktop width (1024x768, dpr 1.0) with 3 actions'`
   - Set `tester.view.physicalSize = const Size(1024, 768); tester.view.devicePixelRatio = 1.0;`
   - Pump same 3-action header as test 1.
   - Assert no exception, title and all 3 action labels found.
   - Assert title's render box `centerLeft.dx` is LESS than the first action button's render box `centerLeft.dx` (proves they're side-by-side, not stacked). Use `tester.getTopLeft(find.text('Settings')).dy` and `tester.getTopLeft(find.text('Action 0')).dy` and assert their `dy` values are approximately equal (within 50pt — proves same row, not stacked vertically).

6. `'asserts actions are vertically stacked below title at iPhone-narrow (positional check)'`
   - Same narrow viewport as test 1.
   - Pump same 3-action header as test 1.
   - Assert `tester.getTopLeft(find.text('Settings')).dy < tester.getTopLeft(find.text('Action 0')).dy` (action is BELOW title vertically — proves stacking happened).

7. `'description-omitted variant renders title-only at narrow and wide'`
   - Two pumps in one test (or split — preference: split into two for clarity if you prefer; one-test version is acceptable). At narrow then wide:
     - Pump `EdenPageHeader(title: 'No Desc', actions: [ElevatedButton(onPressed: () {}, child: Text('OK'))])`.
     - Assert no exception, title found, `find.text('OK')` found.
     - Reset viewport, set wide, pump again, same assertions.

8. `'long-title variant (80+ chars) wraps within title block at narrow without overflow'`
   - Narrow viewport.
   - Pump `EdenPageHeader(title: 'A' * 90, actions: [ElevatedButton(onPressed: () {}, child: Text('Go'))])`.
   - Assert `expect(tester.takeException(), isNull);` (the long title must wrap inside the title-Column, not push actions into overflow).

Approach for each test:
```dart
testWidgets('renders without overflow at iPhone-narrow ...', (tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(wrap(EdenPageHeader(
    title: 'Settings',
    actions: [
      for (int i = 0; i < 3; i++)
        ElevatedButton(onPressed: () {}, child: Text('Action $i')),
    ],
  )));

  expect(tester.takeException(), isNull);
  expect(find.text('Settings'), findsOneWidget);
  expect(find.text('Action 0'), findsOneWidget);
  expect(find.text('Action 1'), findsOneWidget);
  expect(find.text('Action 2'), findsOneWidget);
});
```

# CRITICAL: Tests 1, 4, 6, 8 MUST FAIL when run against the current bare-Row production widget. Test 6 fails because the current widget renders title and actions on the same row (dy values equal). Tests 1, 4, 8 fail with `RenderFlex overflowed` exceptions caught by `tester.takeException()`.
# GOTCHA: Test 5 (wide) and tests 2, 3, 7 (narrow with no/empty actions) PASS against the current widget — they are regression guards proving the fix doesn't break the wide path or the no-actions path. Don't expect them to fail. The Iron Law requires SOME test to fail in RED; tests 1, 4, 6, 8 satisfy that.
# PATTERN: Mirror `test/widgets/eden_alert_test.dart` exactly for structure (top-level `wrap` helper, single `group`, `testWidgets` per case).
  </action>
  <verify>
Run: `flutter test test/widgets/eden_page_header_test.dart`

Expected: Test runner reports failures on at least tests 1, 4, 6, and 8 (the iPhone-narrow overflow assertions and the stacking positional check). Tests 2, 3, 5, 7 should pass even against the current production widget — they assert behavior the current widget already exhibits correctly.

Confirm command exits NON-ZERO. The framework error `A RenderFlex overflowed by N pixels on the right` should appear in the failure output for the overflow tests.

Also run: `flutter analyze test/widgets/eden_page_header_test.dart` — must exit clean (no warnings, no errors).
  </verify>
  <done>
- `test/widgets/eden_page_header_test.dart` exists with all 8 testWidgets cases inside a single `group('EdenPageHeader', () { ... })`.
- File imports `package:eden_ui_flutter/eden_ui.dart` (NOT relative `../../lib/src/...`).
- Each viewport-modifying test calls `addTearDown` to reset `physicalSize` and `devicePixelRatio`.
- `flutter test test/widgets/eden_page_header_test.dart` exits non-zero with at least 4 failing test cases (RED state confirmed).
- `flutter analyze test/widgets/eden_page_header_test.dart` exits clean.
- Atomic commit on this task: `test(quick-1): add EdenPageHeader widget tests for iPhone-narrow overflow (RED)`.
  </done>
  <recovery>
- If all tests pass against the bare-Row widget: see `<error_recovery>` block above. Most likely causes: dpr not forced to 1.0, viewport set after pumpWidget, or button labels too short to trigger overflow. Fix the test, re-run, confirm RED.
- If `flutter analyze` flags issues: typically unused imports. Remove offending symbol or add a use-site.
- If the file fails to compile (missing `EdenPageHeader` symbol): re-confirm `lib/eden_ui.dart` exports `src/widgets/eden_page_header.dart` (it does — verified at planning time).
- Rollback: this task creates a single new file. If the task derails, `rm test/widgets/eden_page_header_test.dart` and restart.
  </recovery>
</task>

<task type="auto">
  <name>Task 2 (GREEN): replace EdenPageHeader Row with LayoutBuilder + 480pt breakpoint</name>
  <files>lib/src/widgets/eden_page_header.dart</files>
  <action>
Replace the body of `EdenPageHeader.build` so the outer layout becomes a `LayoutBuilder` that switches between vertical-stack (narrow) and side-by-side (wide) at a 480pt threshold.

Keep the constructor signature, all four fields (`title`, `description`, `actions`, `leading`), and the `Padding(EdgeInsets.only(bottom: EdenSpacing.space6))` outer wrapper unchanged.

New body shape (replaces the existing `child: Row(...)` inside the Padding):

```dart
return Padding(
  padding: const EdgeInsets.only(bottom: EdenSpacing.space6),
  child: LayoutBuilder(
    builder: (context, constraints) {
      final hasActions = actions != null && actions!.isNotEmpty;
      final stackVertically = hasActions && constraints.maxWidth < 480;

      final titleBlock = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: EdenSpacing.space3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.headlineMedium),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );

      final actionsBlock = hasActions
          ? Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: actions!,
            )
          : null;

      if (stackVertically) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleBlock,
            const SizedBox(height: EdenSpacing.space3),
            actionsBlock!,
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: titleBlock),
          if (actionsBlock != null) ...[
            const SizedBox(width: EdenSpacing.space3),
            actionsBlock,
          ],
        ],
      );
    },
  ),
);
```

# CRITICAL: Do NOT change the constructor signature, parameter names, or types. The widget is exported via `lib/eden_ui.dart` and consumed by every downstream Eden Flutter app.
# CRITICAL: Use `Wrap` (not `Row`) for the actions block. Long action labels at 390pt can themselves overflow a `Row`; `Wrap` line-breaks them safely.
# GOTCHA: The wide path wraps `titleBlock` in `Expanded(...)` (Row child). The narrow path does NOT (Column child — no Flex sizing needed). The `titleBlock` itself is the same widget tree in both cases; only its wrapping differs.
# GOTCHA: `actionsBlock!` non-null assertion in the narrow branch is safe because `stackVertically` requires `hasActions == true`, which requires `actions != null && actions!.isNotEmpty`, which guarantees `actionsBlock` was constructed.
# PATTERN: This is the same `LayoutBuilder` + `< 480` + `Wrap` pattern that shipped in eden-biz-flutter `_GlobalTopBar` (commit `dea58e9`) — proven downstream.
  </action>
  <verify>
1. `flutter test test/widgets/eden_page_header_test.dart` — all 8 tests pass (GREEN). Exit code 0.
2. `flutter test test/widgets/` — full widget-test regression. All ~30 existing widget tests still pass. Exit code 0.
3. `flutter analyze lib/src/widgets/eden_page_header.dart test/widgets/eden_page_header_test.dart` — clean, no warnings, no errors.
4. Optional spot-check: `flutter test` (full project test suite) exits 0 — confirms nothing else regressed.
  </verify>
  <done>
- `lib/src/widgets/eden_page_header.dart` build method uses `LayoutBuilder` with a `< 480` breakpoint.
- Constructor signature unchanged.
- All 8 tests in `test/widgets/eden_page_header_test.dart` pass.
- All other widget tests in `test/widgets/` continue to pass (no regression).
- `flutter analyze` clean on both modified files.
- Atomic commit on this task: `feat(quick-1): EdenPageHeader stacks actions on narrow viewports (GREEN)`.
- RESP-01, RESP-02, RESP-03 are all satisfied (overflow fixed, narrow test infrastructure exists, wide path explicitly tested).
  </done>
  <recovery>
- If GREEN tests still fail: inspect the failure. Most likely: missed `Expanded` on the wide path (titleBlock takes 0 width, actions render alongside an invisible title) or used `Row` instead of `Wrap` for actions (re-overflows on narrow with long labels). Re-read the action block code, fix, re-run.
- If other widget tests in `test/widgets/` fail after the GREEN commit: see `<error_recovery>` block. Most likely viewport state leakage from Task 1 — verify `addTearDown` is registered in every viewport-modifying test.
- If `flutter analyze` flags an unused import in the production file: the prior implementation imported only `flutter/material.dart` and the local `spacing.dart` — both still needed. No new imports required for this fix.
- Rollback: `git revert HEAD` reverts the GREEN commit cleanly. The RED commit (Task 1) remains in history with failing tests, ready for the next attempt.
  </recovery>
</task>

</tasks>

<validation_gates>
<lint>flutter analyze lib/src/widgets/eden_page_header.dart test/widgets/eden_page_header_test.dart</lint>
<test>flutter test test/widgets/eden_page_header_test.dart</test>
<regression>flutter test test/widgets/</regression>
</validation_gates>

<verification>
RESP-01 — `flutter test test/widgets/eden_page_header_test.dart` passes; the iPhone-narrow 3-action test asserts `tester.takeException() == null`. Confirmed by Task 2's verify step.

RESP-02 — `test/widgets/eden_page_header_test.dart` contains the iPhone-narrow viewport setup pattern (`tester.view.physicalSize = const Size(390, 844); tester.view.devicePixelRatio = 1.0;` + `addTearDown` reset). This file IS the shared pattern — future widgets follow this template.

RESP-03 — Test 5 in the new test file explicitly pumps `EdenPageHeader` at desktop width (1024x768) with 3 actions and asserts the side-by-side layout via positional checks (title and first action share approximately the same `dy`). Wide path covered by a dedicated test, separate from the narrow tests.

Regression — `flutter test test/widgets/` exits 0; all ~30 existing widget tests in the catalog still pass. No cross-contamination from new viewport-modifying tests (verified by Task 2's regression verify step).
</verification>

<success_criteria>
- [ ] `test/widgets/eden_page_header_test.dart` exists with 8 testWidgets cases inside `group('EdenPageHeader', ...)`.
- [ ] Test file imports via `package:eden_ui_flutter/eden_ui.dart` and follows the `wrap()` helper + `MaterialApp/Scaffold` pattern from `eden_alert_test.dart`.
- [ ] Every viewport-modifying test registers `addTearDown` to reset physicalSize and devicePixelRatio.
- [ ] `lib/src/widgets/eden_page_header.dart` uses `LayoutBuilder` with the `constraints.maxWidth < 480` breakpoint and `Wrap` for the actions block.
- [ ] `EdenPageHeader` constructor signature is unchanged (`title`, `description`, `actions`, `leading` all preserved with same types and required-ness).
- [ ] `flutter test test/widgets/eden_page_header_test.dart` passes (8/8 tests green).
- [ ] `flutter test test/widgets/` passes (full widget-test regression, no other widget tests broken).
- [ ] `flutter analyze lib/src/widgets/eden_page_header.dart test/widgets/eden_page_header_test.dart` exits clean.
- [ ] Two atomic commits land in order: `test(quick-1): ... (RED)` followed by `feat(quick-1): ... (GREEN)`.
- [ ] RESP-01, RESP-02, RESP-03 all marked complete in the post-task STATE.md / REQUIREMENTS.md update.
</success_criteria>

<output>
After completion, create `.planning/quick/1-edenpageheader-iphone-narrow-layoutbuild/1-SUMMARY.md` with:
- Files modified / created (with line counts)
- Commits landed (`test:` SHA, `feat:` SHA)
- Test results (8/8 passing, regression count)
- RESP-01..03 status flip to complete
- Note for STATE.md: append entry to "Quick Tasks Completed" table.
</output>
