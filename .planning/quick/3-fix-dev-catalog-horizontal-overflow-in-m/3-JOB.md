---
mode: quick
job: 3-fix-dev-catalog-horizontal-overflow-in-m
type: standard
wave: 1
depends_on: []
files_modified:
  - lib/dev_app/screens/medical_screen.dart
  - lib/dev_app/screens/retail_polish_screen.dart
  - lib/dev_app/screens/scheduler_screen.dart
autonomous: true
must_haves:
  - medical_screen.dart lines 1060, 1247, 1276 each wrap their SizedBox(width: 1200, ...) in SingleChildScrollView(scrollDirection: Axis.horizontal, ...)
  - retail_polish_screen.dart lines 105, 166, 225 each replace SizedBox(width: NNN, child: X) with ConstrainedBox(constraints: BoxConstraints(maxWidth: NNN), child: X)
  - scheduler_screen.dart line 295 changes c.maxWidth < 900 to c.maxWidth < 1100 (matches scheduler_toolbar.dart:157 canon)
  - flutter analyze lib/dev_app/screens/medical_screen.dart lib/dev_app/screens/retail_polish_screen.dart lib/dev_app/screens/scheduler_screen.dart returns clean
  - iPhone-narrow (>=390pt) renders the 6 priority rows without horizontal RenderFlex overflow
  - Off-limits directories (eden_diagram, eden_process_canvas, eden_workflow_canvas, eden_template_builder, lib/src/widgets/scheduler/) untouched
---

<objective>
Fix six dev-catalog horizontal overflow instances (3 medical, 3 retail_polish) all stemming from the same root cause family as the just-fixed scheduler bug (quick task 2): fixed-width children rendered bare inside a vertical ListView, producing horizontal RenderFlex overflow on iPhone-narrow (>=390pt) viewports. Also align scheduler_screen.dart's reference-page LayoutBuilder breakpoint with the documented `EdenScheduler` toolbar canon (1100pt, not 900pt).

Source audit: @.planning/quick/dev-catalog-visual-audit-2026-05-18.md (Section 1 priority-1 rows + Section 2 quick task 3 spec).

Two pattern variants apply here:
- **Medical scaffolds (1200pt wide):** the natural width is the demonstration point (showing full multi-pane layout at desktop scale), so wrap in a horizontally-scrollable container so phone users can pan to see the desktop tier rather than collapse it. Matches the proven `data_display_screen.dart:949-952` pattern (`SingleChildScrollView(scrollDirection: Axis.horizontal, child: SizedBox(width: 1100, child: ...))`).
- **Retail widgets (600/800pt wide):** the width is an upper cap for desktop, not a fixed dimension worth scrolling to see. Replace `SizedBox(width: NNN, child: X)` with `ConstrainedBox(constraints: BoxConstraints(maxWidth: NNN), child: X)` so phone-narrow viewports render at the natural narrower width and only the cap applies on wider viewports.
- **Scheduler breakpoint:** cosmetic-only constant change; align the dev_app reference page LayoutBuilder with the actual `EdenScheduler` toolbar canon at `scheduler_toolbar.dart:157` (`c.maxWidth < 1100`).

All three files live under `lib/dev_app/screens/` (dev catalog scaffolding, not library code). TDD is skipped per quick-task-2 task-3 precedent — these are pure scaffolding wrappers; the library widgets they wrap (`EdenPatientChartScaffold`, `EdenVisitEncounterScaffold`, `EdenLoyaltyMemberDetail`, `EdenStoreCreditLedger`, `EdenGiftCardBalanceLookup`) remain unchanged and already have their own tests.

Single atomic commit covering all 7 edits (3 medical wraps + 3 retail conversions + 1 scheduler breakpoint).
</objective>

<embedded_context>

<codebase_examples>

**Proven scrollable-wrap pattern at `lib/dev_app/screens/data_display_screen.dart:945-960` (use for medical scaffolds):**

```dart
Widget build(BuildContext context) {
  final jobs = TradesScenarios.weekEvents;
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SizedBox(
      width: 1100,
      child: EdenDataTable(
        striped: true,
        columns: const <EdenTableColumn>[
          EdenTableColumn(label: 'Job ID'),
          ...
        ],
      ),
    ),
  );
}
```

**Current overflow patterns to fix:**

`medical_screen.dart:1058-1067` (and lines 1245, 1274 follow same shape):
```dart
_Subsection(
  label: 'Expanded tier (1200×800) — three-pane layout',
  child: SizedBox(
    width: 1200,
    height: 800,
    child: EdenPatientChartScaffold(
      data: data,
      patientId: data.patientId,
    ),
  ),
),
```

`retail_polish_screen.dart:103-108` (and lines 166, 225 follow same shape):
```dart
return SizedBox(
  width: 600,
  child: EdenLoyaltyMemberDetail(member: member),
);
```

**Canonical 1100pt breakpoint at `lib/src/widgets/scheduler/scheduler_toolbar.dart:154-157`:**

```dart
// to icon-only when the toolbar's available width drops below 1100pt
// (above which there's room for label + icon together).
final iconOnly = c.maxWidth.isFinite && c.maxWidth < 1100;
```

`scheduler_screen.dart:295` currently reads `final isCompact = c.maxWidth < 900;` — this is the reference-page LayoutBuilder, not the live scheduler widget. Change the constant to 1100 to match the toolbar canon.

</codebase_examples>

<anti_patterns>

- **Do NOT touch the wrapped library widgets** (`EdenPatientChartScaffold`, `EdenVisitEncounterScaffold`, `EdenLoyaltyMemberDetail`, `EdenStoreCreditLedger`, `EdenGiftCardBalanceLookup`). They live under `lib/src/widgets/` and already have their own tests. This task wraps the scaffolding ONLY.
- **Do NOT modify the scheduler library** at `lib/src/widgets/scheduler/` (off-limits per quick-task-2 precedent). The breakpoint canon at `scheduler_toolbar.dart:157` is the source of truth; we align `scheduler_screen.dart` (dev_app) TO it, not the other way around.
- **Do NOT add new pubspec dependencies.** All needed widgets (`SingleChildScrollView`, `ConstrainedBox`, `BoxConstraints`) are stock Flutter framework.
- **Do NOT mass-replace every `SizedBox(width: ...)` in these files** — only the 6 audit-flagged instances. Other `SizedBox` uses in these screens (spacing, intentional fixed-width controls) must remain untouched.
- **Do NOT drop the `height` from the medical `SizedBox`** when wrapping. The scaffolds need the height constraint to render correctly; the wrap adds horizontal scroll while preserving the `width: 1200, height: NNN` inner box. Final shape:
  ```dart
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SizedBox(
      width: 1200,
      height: NNN,
      child: EdenPatientChartScaffold(...),
    ),
  ),
  ```
- **Do NOT use raw `git commit`** — repo-config blocks it. Use df-tools commit (see <verify>).

</anti_patterns>

<error_recovery>

- **If `flutter analyze` fails after edits:** likely an unbalanced paren/brace from the wrap. Re-read each edited block; the medical wraps add exactly one `SingleChildScrollView(scrollDirection: Axis.horizontal, child: ...)` outer layer (2 lines + closing `)`); the retail conversions are pure token replacements (`SizedBox(width: NNN, child:` → `ConstrainedBox(constraints: BoxConstraints(maxWidth: NNN), child:`, with matching close `)`).
- **If scheduler tests break:** the change at line 295 is a constant-only edit inside `scheduler_screen.dart` (dev_app reference page, not the library). Library scheduler tests must not depend on this file. If any test fails, revert the scheduler edit and surface — do not touch the library.
- **If visual verification reveals an overflow remains:** confirm you wrapped the SizedBox (not the `_Subsection` and not the child). The overflow happens because the SizedBox itself is wider than the parent ListView; the scroll wrap must be the immediate parent of the SizedBox.

</error_recovery>

</embedded_context>

<gotchas>

- **`SizedBox` height preserved in medical wraps.** Each medical SizedBox has both `width: 1200` and `height: NNN`. Keep both inside the wrapped SizedBox — the scaffolds need the height constraint. Only the horizontal scroll wrap is new.
- **Retail `const` removal.** `retail_polish_screen.dart:223` reads `return const SizedBox(width: 600, child: EdenGiftCardBalanceLookup(onLookup: _demoLookup));`. After conversion to `ConstrainedBox`, the `const` keyword likely needs to stay if both the constraints object AND the child are const-constructible. Check by running `flutter analyze` after — if it complains, drop `const`. (`BoxConstraints(maxWidth: 600)` is const-constructible, and `EdenGiftCardBalanceLookup` accepts a const constructor in this call, so `const ConstrainedBox(constraints: BoxConstraints(maxWidth: 600), child: EdenGiftCardBalanceLookup(onLookup: _demoLookup))` should hold const.)
- **Line numbers drift across files.** Quick-task-2's scheduler fix may have shifted line numbers in `scheduler_screen.dart` slightly. The audit said "line ~295" with tilde for that reason. `grep -n 'c.maxWidth < 900' lib/dev_app/screens/scheduler_screen.dart` confirms the current location before editing — at time of planning it's at line 295 exactly.
- **Three retail widths differ (600 / 800 / 600).** Preserve each line's specific width when converting:
  - line 105: `width: 600` → `maxWidth: 600`
  - line 166: `width: 800` → `maxWidth: 800`
  - line 225: `width: 600` → `maxWidth: 600`

</gotchas>

<validation_gates>

```bash
# Static analysis (must pass clean on edited files):
flutter analyze lib/dev_app/screens/medical_screen.dart lib/dev_app/screens/retail_polish_screen.dart lib/dev_app/screens/scheduler_screen.dart

# Existing scheduler tests must remain green:
flutter test test/widgets/scheduler/
```

</validation_gates>

<file_tree>

```
lib/
├── dev_app/
│   └── screens/
│       ├── medical_screen.dart           ← MODIFY (wrap 3 SizedBoxes in SingleChildScrollView)
│       ├── retail_polish_screen.dart     ← MODIFY (convert 3 SizedBoxes to ConstrainedBoxes)
│       └── scheduler_screen.dart         ← MODIFY (900 → 1100 breakpoint constant)
└── src/
    └── widgets/
        └── scheduler/
            └── scheduler_toolbar.dart    ← REFERENCE ONLY — DO NOT MODIFY (canonical 1100pt source)
```

</file_tree>

<task type="auto">
  <name>Wrap 6 dev-catalog SizedBoxes + align scheduler reference-page breakpoint</name>

  <files>
    lib/dev_app/screens/medical_screen.dart
    lib/dev_app/screens/retail_polish_screen.dart
    lib/dev_app/screens/scheduler_screen.dart
  </files>

  <action>
Make 7 surgical edits across 3 files. All edits are pure scaffolding — no library code, no tests, no new dependencies.

**Edit 1 — `lib/dev_app/screens/medical_screen.dart` line 1060** (Expanded tier patient chart, 1200×800):

Wrap the existing `SizedBox(width: 1200, height: 800, child: EdenPatientChartScaffold(...))` in a horizontal SingleChildScrollView. Find the block:

```dart
_Subsection(
  label: 'Expanded tier (1200×800) — three-pane layout',
  child: SizedBox(
    width: 1200,
    height: 800,
    child: EdenPatientChartScaffold(
      data: data,
      patientId: data.patientId,
    ),
  ),
),
```

Replace its `child:` body with:

```dart
_Subsection(
  label: 'Expanded tier (1200×800) — three-pane layout',
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SizedBox(
      width: 1200,
      height: 800,
      child: EdenPatientChartScaffold(
        data: data,
        patientId: data.patientId,
      ),
    ),
  ),
),
```

**Edit 2 — `lib/dev_app/screens/medical_screen.dart` line 1247** (Annual physical empty, 1200×600):

Same wrap pattern. Find the `SizedBox(width: 1200, height: 600, child: EdenVisitEncounterScaffold(...))` inside the `_Subsection(label: 'Annual physical — empty (just started)', ...)`. Wrap that SizedBox in `SingleChildScrollView(scrollDirection: Axis.horizontal, child: ...)`. Preserve the SizedBox's `width: 1200, height: 600` and the entire `EdenVisitEncounterScaffold(...)` child verbatim.

**Edit 3 — `lib/dev_app/screens/medical_screen.dart` line 1276** (URI visit, 1200×700):

Same wrap pattern. Find the `SizedBox(width: 1200, height: 700, child: EdenVisitEncounterScaffold(...))` inside the `_Subsection(label: 'URI visit — mid-visit with PCN-allergy alert', ...)`. Wrap that SizedBox in `SingleChildScrollView(scrollDirection: Axis.horizontal, child: ...)`. Preserve the SizedBox's `width: 1200, height: 700` and the entire `EdenVisitEncounterScaffold(...)` child verbatim.

**Edit 4 — `lib/dev_app/screens/retail_polish_screen.dart` line 105** (loyalty member detail):

Find:
```dart
return SizedBox(
  width: 600,
  child: EdenLoyaltyMemberDetail(member: member),
);
```

Replace with:
```dart
return ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 600),
  child: EdenLoyaltyMemberDetail(member: member),
);
```

**Edit 5 — `lib/dev_app/screens/retail_polish_screen.dart` line 166** (store credit ledger):

Find:
```dart
return SizedBox(width: 800, child: EdenStoreCreditLedger(data: data));
```

Replace with:
```dart
return ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 800),
  child: EdenStoreCreditLedger(data: data),
);
```

**Edit 6 — `lib/dev_app/screens/retail_polish_screen.dart` line 225** (gift card balance lookup):

Find:
```dart
return const SizedBox(
  width: 600,
  child: EdenGiftCardBalanceLookup(onLookup: _demoLookup),
);
```

Replace with:
```dart
return const ConstrainedBox(
  constraints: BoxConstraints(maxWidth: 600),
  child: EdenGiftCardBalanceLookup(onLookup: _demoLookup),
);
```

(Note: `const` is preserved here because both `BoxConstraints(maxWidth: 600)` and `EdenGiftCardBalanceLookup(onLookup: _demoLookup)` are const-constructible in this call site. If `flutter analyze` rejects the `const`, drop it from the outer `ConstrainedBox` only.)

**Edit 7 — `lib/dev_app/screens/scheduler_screen.dart` line 295** (reference-page breakpoint):

Find:
```dart
final isCompact = c.maxWidth < 900;
```

Replace with:
```dart
final isCompact = c.maxWidth < 1100;
```

This aligns the dev_app reference page with `scheduler_toolbar.dart:157`'s canonical 1100pt threshold ("responsive collapse to icon-only below 1100pt"). Cosmetic — not an overflow fix; the reference page now matches the live widget's behavior at the same viewport widths.

# CRITICAL: Off-limits dirs untouched — zero modifications to lib/src/widgets/scheduler/, eden_diagram/, eden_process_canvas/, eden_workflow_canvas/, eden_template_builder/.
# GOTCHA: Verify `grep -n 'c.maxWidth < 900' lib/dev_app/screens/scheduler_screen.dart` returns line 295 BEFORE editing. If line drifted (post-quick-task-2 commits), use the actual line.
# GOTCHA: Preserve the inner `SizedBox` height in medical wraps — the scaffolds need both width and height constraints to render their multi-pane layouts.
# PATTERN: Follow the proven `data_display_screen.dart:945-960` shape exactly for medical wraps.
  </action>

  <verify>
Run all of the following from the repo root:

1. **Confirm exact files modified (no off-limits drift):**
   ```bash
   git status --short
   ```
   Expected output (exactly these three lines, no others):
   ```
    M lib/dev_app/screens/medical_screen.dart
    M lib/dev_app/screens/retail_polish_screen.dart
    M lib/dev_app/screens/scheduler_screen.dart
   ```

2. **Confirm off-limits dirs untouched:**
   ```bash
   git diff --name-only | grep -E '(lib/src/widgets/scheduler/|eden_diagram|eden_process_canvas|eden_workflow_canvas|eden_template_builder)'
   ```
   Expected: empty output (no matches).

3. **Static analysis clean:**
   ```bash
   flutter analyze lib/dev_app/screens/medical_screen.dart lib/dev_app/screens/retail_polish_screen.dart lib/dev_app/screens/scheduler_screen.dart
   ```
   Expected: `No issues found!` (or zero errors / zero warnings).

4. **Existing scheduler tests still green:**
   ```bash
   flutter test test/widgets/scheduler/
   ```
   Expected: all tests pass.

5. **Confirm scheduler canon alignment:**
   ```bash
   grep -n 'c.maxWidth < 1100' lib/dev_app/screens/scheduler_screen.dart
   grep -n 'c.maxWidth < 1100' lib/src/widgets/scheduler/scheduler_toolbar.dart
   ```
   Expected: both grep calls return a match (line 295 in scheduler_screen.dart; line 157 in scheduler_toolbar.dart).

6. **Confirm medical wraps applied (sanity check):**
   ```bash
   grep -c 'SingleChildScrollView' lib/dev_app/screens/medical_screen.dart
   ```
   Expected: count >= 3 (one per medical wrap; may be higher if file already used the pattern elsewhere — baseline check the pre-edit count first if needed).

7. **Confirm retail conversions applied:**
   ```bash
   grep -c 'ConstrainedBox' lib/dev_app/screens/retail_polish_screen.dart
   grep -c 'SizedBox(width: 600' lib/dev_app/screens/retail_polish_screen.dart
   grep -c 'SizedBox(width: 800' lib/dev_app/screens/retail_polish_screen.dart
   ```
   Expected: ConstrainedBox count >= 3; the two `SizedBox(width: 600|800` greps should return 0 (or match only unrelated SizedBoxes if any remain — the 3 audit-flagged ones are gone).
  </verify>

  <done>
- `git status --short` lists exactly 3 modified files (medical_screen, retail_polish_screen, scheduler_screen).
- `flutter analyze` on those 3 files returns clean (no issues).
- `flutter test test/widgets/scheduler/` passes (existing scheduler tests remain green).
- Both scheduler-screen line 295 and scheduler-toolbar line 157 now read `c.maxWidth < 1100`.
- Three medical `SizedBox(width: 1200, ...)` blocks each have a `SingleChildScrollView(scrollDirection: Axis.horizontal, ...)` parent.
- Three retail SizedBoxes (600/800/600) are now ConstrainedBoxes with matching `BoxConstraints(maxWidth: ...)`.
- No files under `lib/src/widgets/scheduler/`, `eden_diagram/`, `eden_process_canvas/`, `eden_workflow_canvas/`, or `eden_template_builder/` modified.
- Single atomic commit created via df-tools:
  ```bash
  node ~/.claude/devflow/bin/df-tools.cjs commit "fix(dev-catalog): wrap medical scaffolds + cap retail widgets to restore iPhone-narrow rendering, align scheduler reference-page breakpoint to 1100pt canon" --files lib/dev_app/screens/medical_screen.dart lib/dev_app/screens/retail_polish_screen.dart lib/dev_app/screens/scheduler_screen.dart
  ```
  </done>

  <recovery>
- **If `flutter analyze` errors on a medical wrap:** inspect the closing parens. Each medical wrap adds exactly one `SingleChildScrollView(scrollDirection: Axis.horizontal, child: ...)` outer layer with one closing `)` to match. The inner `SizedBox(width: NNN, height: NNN, child: EdenXxxScaffold(...))` is unchanged.
- **If `flutter analyze` errors on the retail `const ConstrainedBox` (Edit 6):** drop the outer `const` (keep the inner `BoxConstraints` as const-or-not based on what compiles). The earlier two retail conversions (Edits 4–5) don't use `const` and should compile straight.
- **If `flutter test test/widgets/scheduler/` fails:** the scheduler library tests must not depend on `lib/dev_app/screens/scheduler_screen.dart`. If they do fail, revert ONLY Edit 7 (`git checkout -- lib/dev_app/screens/scheduler_screen.dart`), re-run, confirm green, then surface the dependency for human review. Keep Edits 1–6 (medical + retail) — those are unrelated to scheduler tests.
- **If git status shows files outside the 3 expected:** stop. Run `git diff <unexpected-file>` to inspect, then `git checkout -- <unexpected-file>` to revert. The constraint is hard: only the 3 dev_app screens may be modified.
  </recovery>
</task>

<verification>

**Visual sanity check (after task completes):**

Optional but recommended — launch the dev catalog and manually pan through the 6 fixed rows at an iPhone-narrow viewport (>=390pt):
- **Medical Patient Chart — Expanded tier (1200×800):** should render horizontally scrollable at narrow widths (drag/swipe to see right side).
- **Medical Visit Encounter — Annual physical (1200×600):** same, horizontal scroll available.
- **Medical Visit Encounter — URI visit (1200×700):** same, horizontal scroll available.
- **Retail Loyalty Member Detail:** should render at the natural narrow width (filling viewport), capped at 600pt on wider viewports.
- **Retail Store Credit Ledger:** same shape, 800pt cap.
- **Retail Gift Card Balance Lookup:** same shape, 600pt cap.

No horizontal RenderFlex overflow indicators (red-and-yellow striped warnings) should appear on any of the 6 rows at iPhone-narrow widths.

**Behavior parity:** The wrapped library widgets (`EdenPatientChartScaffold`, `EdenVisitEncounterScaffold`, `EdenLoyaltyMemberDetail`, `EdenStoreCreditLedger`, `EdenGiftCardBalanceLookup`) are unchanged — their existing tests remain authoritative for behavior. The dev catalog wraps add zero behavioral change; they only alter how the scaffolds are rendered inside the dev catalog's vertical ListView.

**Scheduler canon alignment:** the dev_app reference page at `scheduler_screen.dart:295` and the canonical toolbar collapse threshold at `scheduler_toolbar.dart:157` now share the literal `1100`. Future changes to one should consider the other (consider a shared constant in a follow-up; not in scope for this quick task).

</verification>

<success_criteria>

1. **No horizontal RenderFlex overflow** on the 6 priority-1 audit rows at iPhone-narrow (>=390pt).
2. **Atomic commit** via df-tools covering all 3 file modifications, no extras.
3. **`flutter analyze` clean** on the 3 edited files.
4. **Existing scheduler tests stay green** (`flutter test test/widgets/scheduler/`).
5. **Off-limits dirs untouched** (lib/src/widgets/scheduler/, eden_diagram/, eden_process_canvas/, eden_workflow_canvas/, eden_template_builder/).
6. **Library widgets untouched** — only `lib/dev_app/screens/*.dart` modified.
7. **No new pubspec dependencies** added.
8. **Scheduler breakpoint canon aligned** — `scheduler_screen.dart:295` and `scheduler_toolbar.dart:157` both reference `1100`.

</success_criteria>

<output_artifacts>

- `lib/dev_app/screens/medical_screen.dart` — 3 SizedBox blocks wrapped in horizontal SingleChildScrollView.
- `lib/dev_app/screens/retail_polish_screen.dart` — 3 SizedBoxes converted to ConstrainedBoxes.
- `lib/dev_app/screens/scheduler_screen.dart` — 1 breakpoint constant updated (900 → 1100).
- 1 atomic git commit on the active branch via `df-tools commit` with message: `fix(dev-catalog): wrap medical scaffolds + cap retail widgets to restore iPhone-narrow rendering, align scheduler reference-page breakpoint to 1100pt canon`.

</output_artifacts>
