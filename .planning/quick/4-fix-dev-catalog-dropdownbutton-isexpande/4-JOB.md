---
quick_task: 4-fix-dev-catalog-dropdownbutton-isexpande
type: standard
wave: 1
depends_on: []
files_modified:
  - lib/dev_app/screens/layouts_screen.dart
  - lib/dev_app/screens/chat_screen.dart
  - lib/dev_app/screens/companion_screen.dart
  - lib/dev_app/screens/process_builder_screen.dart
  - lib/dev_app/screens/template_builder_screen.dart
autonomous: true
tdd_default: skip
tdd_exception: dev catalog scaffolding (parity with quick tasks 2-3); cosmetic-only layout fix; no logic changes; no library widget changes
must_haves:
  - All 8 DropdownButton sites in lib/dev_app/screens/ render with the chevron separated from neighboring text (no flush collision on narrow viewports).
  - Row-hosted dropdowns (7 sites) use `Expanded(child: DropdownButton<T>(... isExpanded: true ...))` so the dropdown stretches to fill remaining row width.
  - AppBar.actions-hosted dropdowns (2 sites: process_builder + template_builder) use `SizedBox(width: 180, child: DropdownButton<T>(... isExpanded: true ...))` because the actions slot cannot host an Expanded.
  - Off-limits directories untouched: lib/src/widgets/, lib/dev_app/screens/widgets/eden_diagram*, eden_process_canvas*, eden_workflow_canvas*, eden_template_builder*.
  - Existing scheduler tests (275) remain GREEN.
  - `flutter analyze` clean on the 5 modified files.
  - Single atomic commit via df-tools.
---

<objective>
Eliminate cosmetic chevron-collision defects on 8 `DropdownButton` instances across 5 dev catalog screens by adding `isExpanded: true` plus the appropriate width-constraining ancestor (`Expanded` for Row children, `SizedBox(width: 180)` for AppBar.actions). Dev catalog scaffolding only — no library widget changes, no logic changes, no transport changes. Purely cosmetic parity with the rest of the catalog. Same TDD-skip rationale as quick tasks 2-3.
</objective>

<context>
**Source audit:** `.planning/quick/dev-catalog-visual-audit-2026-05-18.md` Section 2 quick task 4.

**Why two fix patterns:**
- `DropdownButton.isExpanded: true` tells the dropdown to expand to its parent's max width. Without a width-constraining ancestor, Flutter throws an "unbounded width" error at build time.
- Row children get unbounded horizontal constraints by default → must wrap in `Expanded` (which gives them remaining row width).
- `AppBar.actions` is a `List<Widget>` with constrained width per child; `Expanded` is not allowed there because actions does not use a Flex layout. Fixed `SizedBox(width: 180)` is the canonical Flutter pattern for AppBar dropdowns.

**Sites confirmed by direct read:**
| File | Line | Variant | Container | Fix |
|------|------|---------|-----------|-----|
| layouts_screen.dart | 508 | `DropdownButton<String>` | Row child after `Text('Role preset: ')` + `SizedBox(width: 12)` | wrap in `Expanded`, add `isExpanded: true` |
| chat_screen.dart | 239 | `DropdownButton<EdenAiPersona>` | Row child (toolbar with EdenButton siblings) | wrap in `Expanded`, add `isExpanded: true` |
| chat_screen.dart | 500 | `DropdownButton<EdenAiPersona>` | Row child after `Text('Persona: ')` | wrap in `Expanded`, add `isExpanded: true` |
| chat_screen.dart | 681 | `DropdownButton<String>` | Row child after `Text('Vertical: ')` + `SizedBox(width: 8)` | wrap in `Expanded`, add `isExpanded: true` |
| companion_screen.dart | 108 | `DropdownButton<String>` | Row child after `Text('Vertical: ')` + `SizedBox(width: 8)` | wrap in `Expanded`, add `isExpanded: true` |
| companion_screen.dart | 479 | `DropdownButton<String>` | Row child after `Text('Vertical: ')` + `SizedBox(width: 8)` | wrap in `Expanded`, add `isExpanded: true` |
| companion_screen.dart | 502 | `DropdownButton<EdenGpsStatus>` | Row child after `Text('Status: ')` | wrap in `Expanded`, add `isExpanded: true` |
| process_builder_screen.dart | 102 | `DropdownButton<String>` | `AppBar.actions` `Padding` child | wrap in `SizedBox(width: 180)`, add `isExpanded: true` |
| template_builder_screen.dart | 138 | `DropdownButton<String>` inside `DropdownButtonHideUnderline` | `AppBar.actions` `Padding` child | wrap in `SizedBox(width: 180)` around the `DropdownButtonHideUnderline`, add `isExpanded: true` on inner DropdownButton |

Wait — that's 9 entries because chat_screen has 3 dropdowns (239, 500, 681) and companion has 3 (108, 479, 502), giving 7 Row-hosted + 2 AppBar-hosted = **9 total** (NOT 8). The source audit said 8; let me re-tally from the planning context:

- layouts: 1 (508)
- chat: 3 (239, 500, 681)
- companion: 3 (108, 479, 502)
- process_builder: 1 (102)
- template_builder: 1 (138)
- **Total: 9**

The planning context preamble said "8" but the per-file breakdown enumerates 9 sites. The executor must fix **all 9 enumerated sites**. The "8" in the preamble is a miscount in the upstream context; trust the per-file enumeration which lists 9 distinct line numbers. (Communicate this discrepancy in commit body for traceability.)
</context>

<embedded_context>
  <codebase_examples>
    <example name="Row-hosted DropdownButton wrap pattern (target shape)">
      <file>lib/dev_app/screens/layouts_screen.dart</file>
      <before>
        Row(
          children: <Widget>[
            const Text('Role preset: '),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _selected,
              items: _options.map(...).toList(),
              onChanged: (v) { if (v != null) setState(() => _selected = v); },
            ),
          ],
        ),
      </before>
      <after>
        Row(
          children: <Widget>[
            const Text('Role preset: '),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selected,
                items: _options.map(...).toList(),
                onChanged: (v) { if (v != null) setState(() => _selected = v); },
              ),
            ),
          ],
        ),
      </after>
    </example>
    <example name="AppBar.actions DropdownButton wrap pattern (target shape)">
      <file>lib/dev_app/screens/process_builder_screen.dart</file>
      <before>
        AppBar(
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButton<String>(
                value: _layout.id,
                dropdownColor: Theme.of(context).colorScheme.surface,
                underline: const SizedBox.shrink(),
                items: const [...],
                onChanged: (v) { ... },
              ),
            ),
          ],
        ),
      </before>
      <after>
        AppBar(
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 180,
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _layout.id,
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  underline: const SizedBox.shrink(),
                  items: const [...],
                  onChanged: (v) { ... },
                ),
              ),
            ),
          ],
        ),
      </after>
    </example>
    <example name="DropdownButtonHideUnderline wrap (template_builder special case)">
      <file>lib/dev_app/screens/template_builder_screen.dart</file>
      <before>
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: ...,
              items: const [...],
              onChanged: (v) { ... },
            ),
          ),
        ),
      </before>
      <after>
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            width: 180,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: ...,
                items: const [...],
                onChanged: (v) { ... },
              ),
            ),
          ),
        ),
      </after>
    </example>
  </codebase_examples>

  <anti_patterns>
    <anti_pattern name="Adding isExpanded:true without width-constraining ancestor">
      Setting `isExpanded: true` on a Row-hosted DropdownButton WITHOUT wrapping in `Expanded` (or a sized parent) throws "BoxConstraints forces an infinite width" at build time. Always pair `isExpanded: true` with a parent that supplies a finite width.
    </anti_pattern>
    <anti_pattern name="Using Expanded inside AppBar.actions">
      `AppBar.actions` is a `List<Widget>` rendered by an internal layout that does NOT permit `Expanded` (no enclosing Flex). Using `Expanded` here throws "Incorrect use of ParentDataWidget". Use `SizedBox(width: N)` for fixed-width AppBar dropdowns.
    </anti_pattern>
    <anti_pattern name="Modifying library widgets to fix scaffolding bug">
      The defect is in the dev catalog scaffolding (lib/dev_app/screens/), NOT in the library widgets. Do NOT touch lib/src/widgets/ or any EdenDropdown wrapper. The library is transport-agnostic and consumed by other apps; scaffolding cosmetics are local to the catalog.
    </anti_pattern>
    <anti_pattern name="Changing Dropdown widths in off-limits canvases">
      eden_diagram, eden_process_canvas, eden_workflow_canvas, eden_template_builder directories are off-limits. The 2 AppBar dropdowns in process_builder_screen.dart and template_builder_screen.dart are in dev_app/screens/ (the scaffold layer), NOT in those off-limits canvas directories. Verify path before editing.
    </anti_pattern>
  </anti_patterns>

  <gotchas>
    - template_builder_screen.dart wraps its DropdownButton in `DropdownButtonHideUnderline`. The `SizedBox(width: 180)` must wrap the OUTER `DropdownButtonHideUnderline`, not slot between it and the inner DropdownButton — otherwise the underline-hide widget loses its width context.
    - chat_screen.dart line 239 lives in a Row of toolbar buttons (EdenButtons + Dropdown). After `Expanded` wrap, the dropdown takes ALL remaining horizontal space in the row, which is the desired catalog behavior (dropdown becomes the rightmost stretchy element). If visual review later objects, swap to `Flexible` instead of `Expanded`, but default to `Expanded` per the established quick-task-2/3 pattern.
    - chat_screen.dart line 681 has a sibling `Row(...)` structure with `const SizedBox(width: 8)` between label and dropdown — preserve that spacing exactly. The `Expanded` wraps ONLY the DropdownButton, not the SizedBox.
    - companion_screen.dart has two Row siblings (vertical row + status row at 475-498 and 499-514). Each row needs its own independent `Expanded` wrap on its dropdown. Do not merge them.
    - `flutter analyze` may surface unrelated lints in these files; ignore lints not introduced by this change. The verify gate checks ONLY the dropdown shape, not pre-existing lints.
  </gotchas>

  <error_recovery>
    <case name="Build error: BoxConstraints forces an infinite width">
      Means `isExpanded: true` was added without an `Expanded` or `SizedBox` ancestor. Wrap the DropdownButton in `Expanded(child: ...)` (Row case) or `SizedBox(width: 180, child: ...)` (AppBar case).
    </case>
    <case name="Incorrect use of ParentDataWidget. Expanded widgets must be placed inside Flex widgets">
      Means `Expanded` was used inside `AppBar.actions` (which is not a Flex). Replace `Expanded` with `SizedBox(width: 180)`.
    </case>
    <case name="Underline appears under template_builder dropdown after edit">
      Means `SizedBox` was placed BETWEEN `DropdownButtonHideUnderline` and `DropdownButton` instead of wrapping the `DropdownButtonHideUnderline`. Move the `SizedBox` to wrap the outer `DropdownButtonHideUnderline`.
    </case>
    <case name="Off-limits dir touched by mistake">
      `git diff --stat` should show ONLY the 5 files in `files_modified` frontmatter. If any file under lib/src/widgets/, eden_diagram, eden_process_canvas, eden_workflow_canvas, or eden_template_builder appears, `git restore` it before commit.
    </case>
  </error_recovery>
</embedded_context>

<file_tree>
lib/dev_app/screens/
├── layouts_screen.dart            ← MODIFY (1 dropdown @ L508)
├── chat_screen.dart               ← MODIFY (3 dropdowns @ L239, L500, L681)
├── companion_screen.dart          ← MODIFY (3 dropdowns @ L108, L479, L502)
├── process_builder_screen.dart    ← MODIFY (1 dropdown @ L102, AppBar)
└── template_builder_screen.dart   ← MODIFY (1 dropdown @ L138, AppBar + HideUnderline)
</file_tree>

<task type="auto">
  <name>Apply isExpanded + width-constraining ancestor to all 9 DropdownButton sites in dev catalog screens</name>
  <files>
    lib/dev_app/screens/layouts_screen.dart,
    lib/dev_app/screens/chat_screen.dart,
    lib/dev_app/screens/companion_screen.dart,
    lib/dev_app/screens/process_builder_screen.dart,
    lib/dev_app/screens/template_builder_screen.dart
  </files>
  <action>
For each of the 9 enumerated sites, apply the fix pattern matching its container.

Approach:

**Row-hosted sites (7 sites) — apply pattern A:**
1. `lib/dev_app/screens/layouts_screen.dart:508` — DropdownButton<String> in Row after "Role preset: " label.
2. `lib/dev_app/screens/chat_screen.dart:239` — DropdownButton<EdenAiPersona> in toolbar Row (last child after EdenButton siblings).
3. `lib/dev_app/screens/chat_screen.dart:500` — DropdownButton<EdenAiPersona> in Row after "Persona: " label.
4. `lib/dev_app/screens/chat_screen.dart:681` — DropdownButton<String> in Row after "Vertical: " label + SizedBox(8).
5. `lib/dev_app/screens/companion_screen.dart:108` — DropdownButton<String> in Row after "Vertical: " label + SizedBox(8).
6. `lib/dev_app/screens/companion_screen.dart:479` — DropdownButton<String> in Row after "Vertical: " label + SizedBox(8).
7. `lib/dev_app/screens/companion_screen.dart:502` — DropdownButton<EdenGpsStatus> in Row after "Status: " label.

Pattern A (Row child):
```dart
// BEFORE
DropdownButton<T>(
  value: ...,
  items: ...,
  onChanged: ...,
),
// AFTER
Expanded(
  child: DropdownButton<T>(
    isExpanded: true,
    value: ...,
    items: ...,
    onChanged: ...,
  ),
),
```

**AppBar.actions-hosted sites (2 sites) — apply pattern B / B':**

8. `lib/dev_app/screens/process_builder_screen.dart:102` — DropdownButton<String> inside `Padding` inside `AppBar.actions`.

Pattern B (AppBar.actions direct DropdownButton):
```dart
// BEFORE
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8),
  child: DropdownButton<String>(
    value: _layout.id,
    dropdownColor: Theme.of(context).colorScheme.surface,
    underline: const SizedBox.shrink(),
    items: const [...],
    onChanged: ...,
  ),
),
// AFTER
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8),
  child: SizedBox(
    width: 180,
    child: DropdownButton<String>(
      isExpanded: true,
      value: _layout.id,
      dropdownColor: Theme.of(context).colorScheme.surface,
      underline: const SizedBox.shrink(),
      items: const [...],
      onChanged: ...,
    ),
  ),
),
```

9. `lib/dev_app/screens/template_builder_screen.dart:138` — DropdownButton<String> inside `DropdownButtonHideUnderline` inside `Padding` inside `AppBar.actions`.

Pattern B' (AppBar.actions DropdownButton wrapped in DropdownButtonHideUnderline):
```dart
// BEFORE
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8),
  child: DropdownButtonHideUnderline(
    child: DropdownButton<String>(
      value: ...,
      items: const [...],
      onChanged: ...,
    ),
  ),
),
// AFTER — SizedBox wraps OUTER DropdownButtonHideUnderline, isExpanded on INNER DropdownButton
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8),
  child: SizedBox(
    width: 180,
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        value: ...,
        items: const [...],
        onChanged: ...,
      ),
    ),
  ),
),
```

# CRITICAL: For sites 1-7 (Row), use `Expanded`. For sites 8-9 (AppBar.actions), use `SizedBox(width: 180)`.
# GOTCHA: `Expanded` inside AppBar.actions throws ParentDataWidget error. Don't cross the streams.
# GOTCHA: For site 9 (template_builder), `SizedBox` wraps the `DropdownButtonHideUnderline`, NOT slotted between it and the DropdownButton — preserves underline-hide context.
# GOTCHA: Preserve all sibling SizedBox(width: 8) and SizedBox(width: 12) spacing widgets exactly. They are NOT wrapped — only the DropdownButton is.
# PATTERN: Same TDD-skip rationale as quick tasks 2-3 — dev catalog scaffolding cosmetic fix, no library widget changes.

After editing, run:
```bash
flutter analyze lib/dev_app/screens/layouts_screen.dart lib/dev_app/screens/chat_screen.dart lib/dev_app/screens/companion_screen.dart lib/dev_app/screens/process_builder_screen.dart lib/dev_app/screens/template_builder_screen.dart
```
Expect: zero NEW errors introduced. Pre-existing lints (if any) are out-of-scope.

Run scheduler test suite to confirm no regression:
```bash
flutter test test/  # adjust path if scheduler tests live elsewhere; surface for human if path unclear
```
Expect: 275 tests GREEN (unchanged from baseline).

Commit via df-tools (raw git blocked):
```bash
node ~/.claude/devflow/bin/df-tools.cjs commit "fix(dev-catalog): add isExpanded + width-constraining ancestor to 9 DropdownButton sites

Source audit Section 2 quick task 4 enumerated 9 sites across 5 dev catalog
screens (preamble said 8 — miscount, trust per-file enumeration):

- layouts_screen.dart L508 (Row)
- chat_screen.dart L239, L500, L681 (Rows)
- companion_screen.dart L108, L479, L502 (Rows)
- process_builder_screen.dart L102 (AppBar.actions)
- template_builder_screen.dart L138 (AppBar.actions + DropdownButtonHideUnderline)

Row-hosted (7): wrapped in Expanded + isExpanded:true.
AppBar-hosted (2): wrapped in SizedBox(width:180) + isExpanded:true.

Cosmetic only. No library widget changes. No logic changes.
Transport-agnostic invariant preserved. TDD-skip parity with quick tasks 2-3.
Off-limits dirs (lib/src/widgets/, eden_diagram, eden_process_canvas,
eden_workflow_canvas, eden_template_builder) untouched." --files lib/dev_app/screens/layouts_screen.dart lib/dev_app/screens/chat_screen.dart lib/dev_app/screens/companion_screen.dart lib/dev_app/screens/process_builder_screen.dart lib/dev_app/screens/template_builder_screen.dart
```
  </action>
  <verify>
1. **File-scoped grep for shape compliance:**
   ```bash
   for f in lib/dev_app/screens/layouts_screen.dart \
            lib/dev_app/screens/chat_screen.dart \
            lib/dev_app/screens/companion_screen.dart \
            lib/dev_app/screens/process_builder_screen.dart \
            lib/dev_app/screens/template_builder_screen.dart; do
     echo "=== $f ==="
     grep -n "DropdownButton" "$f"
   done
   ```
   For each `DropdownButton<...>(` line, the next 1-3 lines should contain `isExpanded: true,` AND the line immediately above the DropdownButton should be either `Expanded(` (Row case) or `child: SizedBox(` / `SizedBox(width: 180,` (AppBar case) OR a `DropdownButtonHideUnderline(` line where the SizedBox sits above the HideUnderline (template_builder case).

2. **Count assertion (should be 9 isExpanded:true occurrences in these 5 files):**
   ```bash
   grep -rn "isExpanded: true" lib/dev_app/screens/{layouts,chat,companion,process_builder,template_builder}_screen.dart | wc -l
   ```
   Expect: `9`. If different, recount sites and reconcile.

3. **Off-limits dir untouched:**
   ```bash
   git diff --stat HEAD | grep -E '(lib/src/widgets/|eden_diagram|eden_process_canvas|eden_workflow_canvas|eden_template_builder)'
   ```
   Expect: empty output.

4. **flutter analyze clean (no new errors on modified files):**
   ```bash
   flutter analyze lib/dev_app/screens/layouts_screen.dart lib/dev_app/screens/chat_screen.dart lib/dev_app/screens/companion_screen.dart lib/dev_app/screens/process_builder_screen.dart lib/dev_app/screens/template_builder_screen.dart
   ```
   Expect: no errors introduced by this change. Pre-existing lints OK.

5. **Scheduler tests GREEN:**
   ```bash
   flutter test
   ```
   Expect: 275 tests pass (baseline preserved).

6. **Single atomic commit:**
   ```bash
   git log -1 --oneline
   ```
   Expect: one new commit titled `fix(dev-catalog): add isExpanded + width-constraining ancestor to 9 DropdownButton sites`.
  </verify>
  <done>
- All 9 enumerated DropdownButton sites in `lib/dev_app/screens/{layouts,chat,companion,process_builder,template_builder}_screen.dart` carry `isExpanded: true`.
- All 7 Row-hosted sites are wrapped in `Expanded(child: ...)`.
- Both AppBar.actions-hosted sites are wrapped in `SizedBox(width: 180, child: ...)` (with template_builder's SizedBox wrapping the outer `DropdownButtonHideUnderline`).
- `grep -rn "isExpanded: true" lib/dev_app/screens/{layouts,chat,companion,process_builder,template_builder}_screen.dart | wc -l` returns `9`.
- `git diff --stat` shows exactly the 5 files in `files_modified`; no off-limits files touched.
- `flutter analyze` on the 5 files reports no NEW errors.
- `flutter test` reports 275 GREEN (baseline unchanged).
- Single atomic df-tools commit landed.
  </done>
  <recovery>
- If a build error surfaces ("BoxConstraints forces an infinite width"): an `isExpanded: true` was added without a width-constraining ancestor. Locate the offending file and add the missing `Expanded` / `SizedBox` wrap.
- If ParentDataWidget error surfaces: an `Expanded` was placed inside `AppBar.actions`. Swap to `SizedBox(width: 180)`.
- If template_builder dropdown shows an underline: the `SizedBox` wraps the inner `DropdownButton` instead of the outer `DropdownButtonHideUnderline`. Move the `SizedBox` outward by one level.
- If scheduler tests fail: this fix is cosmetic-only with no logic changes; a test failure means a non-cosmetic edit slipped in. Run `git diff` against each file; any line changed outside the dropdown-wrap shape is in error. Restore those lines.
- If an off-limits file appears in `git diff`: `git restore <path>` immediately. Do not commit.
- If grep shape check shows fewer than 9 `isExpanded: true` occurrences: one or more sites were missed. Re-walk the 9-site enumeration in `<context>` table.
  </recovery>
</task>

<validation_gates>
  <gate name="shape-grep">
    grep -rn "isExpanded: true" lib/dev_app/screens/{layouts,chat,companion,process_builder,template_builder}_screen.dart | wc -l  # expect 9
  </gate>
  <gate name="off-limits-untouched">
    git diff --stat HEAD | grep -E '(lib/src/widgets/|eden_diagram|eden_process_canvas|eden_workflow_canvas|eden_template_builder)' | wc -l  # expect 0
  </gate>
  <gate name="static-analysis">
    flutter analyze lib/dev_app/screens/layouts_screen.dart lib/dev_app/screens/chat_screen.dart lib/dev_app/screens/companion_screen.dart lib/dev_app/screens/process_builder_screen.dart lib/dev_app/screens/template_builder_screen.dart
  </gate>
  <gate name="test-suite">
    flutter test  # 275 baseline expected
  </gate>
  <gate name="atomic-commit">
    git log -1 --oneline | grep -q "fix(dev-catalog): add isExpanded"  # single commit landed
  </gate>
</validation_gates>

<success>
The dev catalog renders chevrons cleanly separated from neighboring text on all 9 DropdownButton sites across narrow + wide viewports. No library widgets touched. No logic changed. No tests broken. Single atomic commit. Cosmetic parity with quick tasks 2-3 achieved.
</success>
</content>
</invoke>