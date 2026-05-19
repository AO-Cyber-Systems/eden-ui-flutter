---
objective: 6-unify-breakpoint-vocabulary-in-eden-ui-f
job: 6
type: standard
mode: quick-full
work: refactor
kind: ui-lib
wave: 1
depends_on: []
files_modified:
  - lib/src/widgets/eden_app_mode.dart
  - lib/src/utils/responsive.dart
  - lib/src/utils/BREAKPOINTS.md
  - lib/src/widgets/eden_page_header.dart
  - lib/src/widgets/eden_gift_card_manager.dart
  - lib/src/widgets/eden_route_optimization_result.dart
  - lib/src/widgets/eden_sales_analytics_scaffold.dart
  - lib/src/widgets/eden_price_book_builder.dart
  - lib/src/widgets/eden_cash_drawer_close.dart
  - lib/src/widgets/eden_soap_note.dart
  - lib/src/widgets/eden_uswds_banner.dart
  - lib/src/widgets/eden_time_card.dart
  - lib/src/widgets/eden_time_slot_picker.dart
  - lib/src/widgets/eden_tank_fleet_map.dart
  - lib/src/widgets/eden_commissions_editor.dart
  - lib/src/widgets/eden_empty_state.dart
  - lib/src/widgets/eden_intake_form_builder.dart
  - lib/src/widgets/eden_template_builder/eden_template_builder_canvas.dart
  - lib/src/widgets/scheduler/scheduler_toolbar.dart
  - lib/src/widgets/eden_scheduler.dart
  - lib/src/widgets/eden_dispatch_page.dart
  - lib/src/widgets/eden_quick_add_product_grid.dart
  - lib/src/widgets/eden_pos_register_scaffold.dart
  - lib/src/widgets/eden_detail_header.dart
  - lib/src/widgets/eden_detail_page_scaffold.dart
  - lib/src/widgets/eden_list_page_scaffold.dart
  - lib/src/widgets/eden_role_dashboard_shell.dart
  - lib/src/widgets/eden_phone_input.dart
  - lib/src/pages/eden_settings_page.dart
  - lib/src/pages/eden_profile_page.dart
  - lib/src/widgets/eden_secure_messaging_thread.dart
  - lib/src/widgets/scheduler/scheduler_dialogs.dart
autonomous: true
must_haves:
  truths:
    - "Three breakpoint vocabularies coexist (EdenResponsive class, EdenAppMode constants, scattered inline literals) plus a hidden 4th vocabulary in widget-level narrowBreakpoint/tabletBreakpoint parameters."
    - "21+ inline literal call sites in lib/src/ compare maxWidth/width against magic numbers (480, 600, 840, 900, 1024, 1100, 1200, etc.) without named-constant references."
    - "EdenResponsive class has ZERO external call sites (audit's '2 call sites' is stale — only self-references inside responsive.dart remain). Safe to soft-deprecate."
    - "Widget-level narrowBreakpoint params (default 480) exist on EdenDetailHeader, EdenDetailPageScaffold, EdenListPageScaffold, EdenRoleDashboardShell, EdenPhoneInput; tabletBreakpoint (default 768) exists on EdenRoleDashboardShell — these are a 4th vocabulary the audit note flagged."
    - "EdenAppMode (kEdenAppModeCompactMax=600, kEdenAppModeExpandedMin=840) is the canonical Material 3 standard already adopted by eden_adaptive_layout.dart."
    - "Existing test suite (3865 tests across 437 test files) is the regression gate — pure rename refactor MUST keep them GREEN."
  artifacts:
    - "lib/src/widgets/eden_app_mode.dart extended with 3 new tokens: kEdenAppModeNarrowMax=480, kEdenAppModeDenseDesktopMin=1100, kEdenAppModeFullDesktopMin=1200 (existing Compact/Expanded constants unchanged)."
    - "lib/src/utils/responsive.dart marked with @Deprecated annotations on mobileMax/tabletMax/desktopMax + isMobile/isTablet/isDesktop pointing to kEdenAppMode* tokens."
    - "21+ inline literal sites migrated: boundary literals (480, 600, 840, 1100, 1200) replaced with named constants; one-off literals (390, 768, 800, 900, 1024, 1280) retained with explanatory '// breakpoint: X — reason' comments."
    - "Widget-level narrowBreakpoint/tabletBreakpoint param defaults updated to reference kEdenAppModeNarrowMax / kEdenAppModeCompactMax (param API unchanged, just the default expression)."
    - "lib/src/utils/BREAKPOINTS.md created — canonical 5-tier vocabulary doc (narrow/compact/medium/expanded-dense/expanded-full) with threshold values, rationale, and usage guide."
    - "Full test suite (3865 tests) passes GREEN after all migrations — zero behavior change."
  key_links:
    - "lib/src/widgets/eden_app_mode.dart — token home; new constants land here."
    - "lib/src/utils/responsive.dart — legacy vocabulary; gets @Deprecated annotations."
    - "lib/src/widgets/eden_adaptive_layout.dart — existing consumer of kEdenAppMode* tokens; reference pattern for new sites."
    - ".planning/quick/dev-catalog-visual-audit-2026-05-18.md — Section 'Breakpoint vocabulary note' is the source audit triggering this job."
    - "lib/src/utils/BREAKPOINTS.md — new doc; the artifact future contributors will read to know which token to use."
---

<objective>
Unify the eden-ui-flutter breakpoint vocabulary under the existing Material 3 standard already canonized by `EdenAppMode`. Eliminate vocabulary fragmentation across 3 (effectively 4, counting widget-level narrowBreakpoint parameters) coexisting systems by:

1. Extending `kEdenAppMode*` token set with 3 new named constants for the breakpoints currently scattered as inline literals (480, 1100, 1200).
2. Migrating 21+ inline-literal call sites in `lib/src/` to use the named constants. One-off intentional literals get explanatory comments instead.
3. Soft-deprecating `EdenResponsive` (zero external call sites — safe to mark `@Deprecated`).
4. Documenting the canonical 5-tier vocabulary in a new `BREAKPOINTS.md`.

Why: Section 4 of `.planning/quick/dev-catalog-visual-audit-2026-05-18.md` flagged this as a latent inconsistency-drift source. The architectural decision was already locked at `COMPANION_UX_PATTERNS_2026-05-15.md §0 lock E` (Material 3 tiers via `EdenAppMode`) — this job is consolidation under that locked standard, not a new design choice.

Purpose: One vocabulary, named tokens, discoverable via the breakpoint doc, with `EdenResponsive` clearly flagged as legacy. Future widget authors reach for the right token instead of inventing a new magic number.

Output: ~25 files modified across `lib/src/`, 3865 existing tests still GREEN, new BREAKPOINTS.md doc, soft-deprecated EdenResponsive.
</objective>

<resolved_configuration>
**Kind:** ui-lib (from PROJECT.md)
**Work:** refactor (inferred from objective description + planning_context constraints: "TDD: SKIPPED — pure refactor")
**TDD:** skip — rename refactor with zero behavior change. Existing 3865-test suite IS the verification gate. Per constraints block: "Existing 3865 tests must remain GREEN — that IS the verification."
**Verification routing (Flutter stack):** `dart format`, `dart analyze`, `flutter test` (full suite, 3865 tests across 437 files).
**Constraints honored:** no_llm_test_data, no_property_based_default, no_gherkin_layer (all inherited from CLAUDE.md TDD playbook; not exercised by a rename-only refactor but no opt-outs needed).
**Off-limits dirs exception:** Per planning_context: migration of inline literals inside `eden_template_builder/` IS allowed (rename, not functional change). One site exists at `eden_template_builder_canvas.dart:99`.
**Anti-enterprise:** Single JOB.md, 3 atomic-commit tasks, ~40% context target.
</resolved_configuration>

<embedded_context>
  <codebase_examples>
    <example name="existing-canonical-tokens" file="lib/src/widgets/eden_app_mode.dart">
```dart
/// Material 3 Compact tier upper bound (exclusive).
const double kEdenAppModeCompactMax = 600.0;

/// Material 3 Expanded tier lower bound (inclusive).
const double kEdenAppModeExpandedMin = 840.0;
```
This is the existing canonical home for breakpoint tokens. New tokens MUST land here, MUST follow the same naming pattern (`kEdenAppMode<Tier><Bound>`), and MUST be `const double` with a doc-comment citing the source / locked decision.
    </example>

    <example name="canonical-consumer-pattern" file="lib/src/widgets/eden_adaptive_layout.dart">
```dart
import 'eden_app_mode.dart' show kEdenAppModeCompactMax, kEdenAppModeExpandedMin;

// ...
if (width < kEdenAppModeCompactMax) return EdenAdaptiveTier.compact;
if (width < kEdenAppModeExpandedMin) return EdenAdaptiveTier.medium;
```
This is the reference pattern for consuming the tokens — explicit `show` import, direct comparison against the named constant. New consumer sites should follow this shape.
    </example>

    <example name="typical-inline-literal-site-to-migrate" file="lib/src/widgets/eden_page_header.dart">
```dart
final stackVertically = hasActions && constraints.maxWidth < 480;
```
Becomes:
```dart
import '../widgets/eden_app_mode.dart' show kEdenAppModeNarrowMax;
// ...
final stackVertically = hasActions && constraints.maxWidth < kEdenAppModeNarrowMax;
```
Note: the actual file is already inside `lib/src/widgets/`, so the import is just `'eden_app_mode.dart'`. Adjust import path per call-site location.
    </example>

    <example name="widget-param-default-migration" file="lib/src/widgets/eden_detail_header.dart">
```dart
this.narrowBreakpoint = 480,
```
Becomes:
```dart
this.narrowBreakpoint = kEdenAppModeNarrowMax,
```
Public param API unchanged — only the default expression. Consumers passing explicit `narrowBreakpoint: 480` keep working.
    </example>

    <example name="one-off-literal-annotation-pattern">
For literals that are NOT canonical tier boundaries (390, 768, 800, 900, 1024, 1280 in scattered sites), keep as literal with explanatory comment:
```dart
// Was: final isWide = constraints.maxWidth >= 1024;
final isWide = constraints.maxWidth >= 1024; // breakpoint: 1024 — POS register requires landscape tablet (eden_pos_register_scaffold.dart pattern)
```
Rule: if the literal sits on a canonical tier boundary (480/600/840/1100/1200), use the named token. If it's an intentional one-off (e.g., POS-tablet 1024, dispatch-three-pane 1280), comment it instead — don't invent a token for one site.
    </example>
  </codebase_examples>

  <anti_patterns>
    <anti_pattern name="inventing-new-tokens-for-one-off-sites">
DO NOT add tokens for the 768, 800, 900, 1024, 1280 one-offs. They are intentional component-specific thresholds. The audit explicitly recommended a 5-tier vocabulary (narrow/compact/medium/expanded-dense/expanded-full). Adding more tokens recreates the fragmentation problem.
    </anti_pattern>

    <anti_pattern name="changing-existing-token-values">
DO NOT change `kEdenAppModeCompactMax = 600.0` or `kEdenAppModeExpandedMin = 840.0`. These are LOCKED at `COMPANION_UX_PATTERNS_2026-05-15.md §0 lock E`. Adjusting them is out of scope and would break Material 3 alignment.
    </anti_pattern>

    <anti_pattern name="deleting-EdenResponsive-class">
DO NOT delete `EdenResponsive` even though it has zero external call sites. Soft-deprecate via `@Deprecated(...)` annotation on the class members. Downstream consumers (`eden-biz-flutter`, `eden-platform-flutter`) consume this lib via `path:` dep and may have call sites we haven't audited. Deprecation lets them migrate before removal.
    </anti_pattern>

    <anti_pattern name="dev_app-screen-migration">
DO NOT migrate inline literals inside `lib/dev_app/screens/`. These are dev-catalog demo widgets that intentionally use fixed pixel widths (390, 600, 800, 1200) for viewport-simulation columns. They are documentation, not production code. Scope is `lib/src/` only.
    </anti_pattern>

    <anti_pattern name="batching-into-one-mega-commit">
DO NOT commit all three tasks as one commit. The atomic-commit boundary is critical for revert safety on a 25+-file refactor. Three commits: (1) add tokens + deprecate, (2) migrate inline sites, (3) add docs + final test confirmation.
    </anti_pattern>
  </anti_patterns>

  <gotchas>
    <gotcha name="import-path-varies-by-location">
The token home is `lib/src/widgets/eden_app_mode.dart`. Import path depends on consumer location:
- From `lib/src/widgets/foo.dart`: `import 'eden_app_mode.dart' show kEdenAppMode...;`
- From `lib/src/widgets/scheduler/scheduler_toolbar.dart`: `import '../eden_app_mode.dart' show kEdenAppMode...;`
- From `lib/src/widgets/eden_template_builder/eden_template_builder_canvas.dart`: `import '../eden_app_mode.dart' show kEdenAppMode...;`
- From `lib/src/pages/eden_settings_page.dart`: `import '../widgets/eden_app_mode.dart' show kEdenAppMode...;`
Use `show` clauses to keep imports tight.
    </gotcha>

    <gotcha name="MediaQuery-width-vs-maxWidth">
Two literal-comparison patterns exist:
- `constraints.maxWidth < 480` (inside `LayoutBuilder`) — most common (17+ sites)
- `MediaQuery.maybeOf(context)?.size.width ?? 1280` then `width < 600` (inside `EdenScheduler`)
Both migrate the same way — replace the literal with the named constant. The default-fallback literal `?? 1280` is an intentional one-off (full-desktop default), comment it.
    </gotcha>

    <gotcha name="BoxConstraints-maxWidth-literals-also-count">
4 sites use `BoxConstraints(maxWidth: 600)` or `BoxConstraints(maxWidth: 480)` as a content-width clamp (not a tier comparison):
- `eden_settings_page.dart:54` (600)
- `eden_profile_page.dart:148` (600)
- `eden_secure_messaging_thread.dart:283` (480)
- `scheduler/scheduler_dialogs.dart:79` (480)
These are content-width clamps, not tier comparisons. **Treat as one-offs with annotation comments** — they're not part of the tier-decision vocabulary the audit flagged. Optional to migrate; if migrated, use named token; if not, add `// width: 600 — content clamp` comment.
    </gotcha>

    <gotcha name="EdenResponsive-internal-self-references">
`EdenResponsive` has 0 external call sites but its own methods (`isMobile`, `isTablet`, `isDesktop`, `EdenResponsiveBuilder.build`) reference each other. When adding `@Deprecated` annotations, expect dart analyze warnings about the internal self-references. Either:
- Suppress with `// ignore: deprecated_member_use_from_same_package` on internal refs, OR
- Annotate the whole class `@Deprecated(...)` and let warnings flow (cleaner — confirms the whole surface is deprecated).
Recommend the second approach — single class-level annotation.
    </gotcha>

    <gotcha name="off-limits-dir-exception">
The objective constraints explicitly permit migration inside `eden_template_builder/` for this rename-only refactor. The single site is `eden_template_builder/eden_template_builder_canvas.dart:99`. Document the exception in commit message.
    </gotcha>
  </gotchas>

  <error_recovery>
    <recovery name="tests-fail-after-migration">
If `flutter test` fails after task 2:
1. Run `flutter test --reporter expanded 2>&1 | head -80` to identify the failing test.
2. Most likely cause: wrong constant chosen (e.g., used `kEdenAppModeCompactMax` where original was `< 480`, not `< 600`). Re-verify the original literal value vs the new constant value.
3. If the constant value is correct, the test may have been asserting against the inline literal (rare — would be a fragile test). Update the test to import and reference the same constant.
4. NEVER revert a deprecation to make a test pass — fix the root cause.
    </recovery>

    <recovery name="dart-analyze-fails-after-deprecation">
If `dart analyze` fails after task 1 with `deprecated_member_use` errors inside `responsive.dart` itself:
- Expected. Add `// ignore_for_file: deprecated_member_use_from_same_package` at the top of `responsive.dart`, OR
- Move the `@Deprecated(...)` annotation to the class level (preferred) so internal refs are uniformly deprecated.
If `dart analyze` fails outside `responsive.dart`: a consumer in `lib/src/` is using `EdenResponsive`. Confirm via `grep -rn 'EdenResponsive' lib/src/` — at planning time this returned zero, but recheck.
    </recovery>

    <recovery name="off-limits-dir-test-failure">
If a test inside `test/widgets/eden_template_builder_*_test.dart` fails after migrating the literal at `eden_template_builder_canvas.dart:99`:
1. Diff the test to see if it was asserting against `< 1200` directly.
2. Update the test to import and reference `kEdenAppModeFullDesktopMin` for the same comparison.
3. The constraint allowed migration; tests adjust to match.
    </recovery>
  </error_recovery>
</embedded_context>

<file_tree>
lib/src/
├── widgets/
│   ├── eden_app_mode.dart                   ← MODIFY (add 3 new tokens)
│   ├── eden_adaptive_layout.dart            (unchanged — reference pattern)
│   ├── eden_page_header.dart                ← MODIFY (480 site)
│   ├── eden_gift_card_manager.dart          ← MODIFY (600 site)
│   ├── eden_route_optimization_result.dart  ← MODIFY (900 one-off → comment)
│   ├── eden_sales_analytics_scaffold.dart   ← MODIFY (1024 one-off → comment)
│   ├── eden_price_book_builder.dart         ← MODIFY (900+600 sites)
│   ├── eden_cash_drawer_close.dart          ← MODIFY (600 site)
│   ├── eden_soap_note.dart                  ← MODIFY (840 site)
│   ├── eden_uswds_banner.dart               ← MODIFY (600 site)
│   ├── eden_time_card.dart                  ← MODIFY (600 site)
│   ├── eden_time_slot_picker.dart           ← MODIFY (600 site)
│   ├── eden_tank_fleet_map.dart             ← MODIFY (1024 one-off → comment)
│   ├── eden_commissions_editor.dart         ← MODIFY (600 site)
│   ├── eden_empty_state.dart                ← MODIFY (480 site)
│   ├── eden_intake_form_builder.dart        ← MODIFY (900 one-off → comment)
│   ├── eden_scheduler.dart                  ← MODIFY (600 site + 1280 default)
│   ├── eden_dispatch_page.dart              ← MODIFY (1280+1024 one-offs → comments)
│   ├── eden_quick_add_product_grid.dart     ← MODIFY (600+1024 sites)
│   ├── eden_pos_register_scaffold.dart      ← MODIFY (1024 one-off → comment)
│   ├── eden_detail_header.dart              ← MODIFY (narrowBreakpoint default 480 → token)
│   ├── eden_detail_page_scaffold.dart       ← MODIFY (narrowBreakpoint default 480 → token)
│   ├── eden_list_page_scaffold.dart         ← MODIFY (narrowBreakpoint default 480 → token)
│   ├── eden_role_dashboard_shell.dart       ← MODIFY (narrow 480 + tablet 768 → tokens/comments)
│   ├── eden_phone_input.dart                ← MODIFY (narrowBreakpoint default 480 → token)
│   ├── eden_secure_messaging_thread.dart    ← MODIFY (BoxConstraints 480 → comment)
│   ├── scheduler/
│   │   ├── scheduler_toolbar.dart           ← MODIFY (1100+480 sites)
│   │   └── scheduler_dialogs.dart           ← MODIFY (BoxConstraints 480 → comment)
│   └── eden_template_builder/
│       └── eden_template_builder_canvas.dart  ← MODIFY (1200 site — off-limits exception)
├── pages/
│   ├── eden_settings_page.dart              ← MODIFY (BoxConstraints 600 → comment)
│   └── eden_profile_page.dart               ← MODIFY (BoxConstraints 600 → comment)
└── utils/
    ├── responsive.dart                      ← MODIFY (soft-deprecate)
    └── BREAKPOINTS.md                       ← CREATE (canonical vocabulary doc)
</file_tree>

<validation_gates>
**Before commit, each task MUST pass:**

```bash
# Task 1 (tokens added + deprecation):
dart format lib/src/widgets/eden_app_mode.dart lib/src/utils/responsive.dart
dart analyze lib/src/widgets/eden_app_mode.dart lib/src/utils/responsive.dart
# Acceptable: deprecated_member_use_from_same_package inside responsive.dart (intentional).

# Task 2 (migration):
dart format lib/src/
dart analyze lib/src/
flutter test
# Expected: 0 analyzer errors (warnings on EdenResponsive self-refs OK), 3865 tests GREEN.

# Task 3 (doc + final gate):
flutter test --reporter compact
# Expected: '3865 passed, 0 failed' or equivalent (whatever the current GREEN baseline is — must match).
```

**Final acceptance gate (run after all 3 tasks):**
```bash
flutter test 2>&1 | tail -5
dart analyze 2>&1 | tail -10
git log --oneline -3   # confirm 3 atomic commits
grep -rn 'EdenResponsive\b' lib/src/ --include='*.dart' | grep -v responsive.dart
# Expected: empty result (no external consumers — confirms deprecation safe).
```
</validation_gates>

<tasks>

<task type="auto">
<name>Add named breakpoint tokens + soft-deprecate EdenResponsive</name>

<files>
lib/src/widgets/eden_app_mode.dart
lib/src/utils/responsive.dart
</files>

<action>
**Goal:** Land the new vocabulary in the canonical token home AND mark the legacy vocabulary as deprecated. Single atomic commit — both changes are coupled (the deprecation message references the new tokens).

**Step 1.1 — Extend `lib/src/widgets/eden_app_mode.dart`:**

After the existing `kEdenAppModeExpandedMin = 840.0;` declaration (around line 35), add 3 new tokens with doc-comments matching the existing style. Use this exact text:

```dart
/// Strict narrow-phone tier upper bound (exclusive). Below this logical-pt
/// width, ultra-narrow phone layouts (iPhone SE-class) MUST stack actions
/// vertically and collapse multi-pane scaffolds to single-column. Used by
/// EdenPageHeader, EdenEmptyState, EdenDetailHeader/Scaffold defaults, and
/// scheduler narrow mode.
///
/// This is the strict subset of [kEdenAppModeCompactMax] (600pt) — sites
/// that need only the strict narrow guard use this; sites that need the
/// full Compact tier use [kEdenAppModeCompactMax].
const double kEdenAppModeNarrowMax = 480.0;

/// Dense-desktop tier lower bound (inclusive). At or above this logical-pt
/// width, desktop chrome can show expanded toolbars without icon-only
/// collapse. Below this, toolbars collapse to icon-only mode to preserve
/// canvas width. Used by EdenScheduler toolbar + EdenWorkflowDesigner
/// toolbar.
///
/// This sits between [kEdenAppModeExpandedMin] (840pt — tablet-landscape
/// floor) and [kEdenAppModeFullDesktopMin] (1200pt — full-desktop floor).
const double kEdenAppModeDenseDesktopMin = 1100.0;

/// Full-desktop tier lower bound (inclusive). At or above this logical-pt
/// width, complex multi-pane layouts (template builders, visit encounter
/// scaffolds, three-pane intake forms) can fully expand. Below this, they
/// fall back to compact / stacked modes.
const double kEdenAppModeFullDesktopMin = 1200.0;
```

**Step 1.2 — Soft-deprecate `lib/src/utils/responsive.dart`:**

Add a class-level `@Deprecated` annotation immediately before `class EdenResponsive {`. Also add `// ignore_for_file: deprecated_member_use_from_same_package` at the top of the file (after the existing `import 'package:flutter/material.dart';`). Use this exact pattern:

```dart
import 'package:flutter/material.dart';
// ignore_for_file: deprecated_member_use_from_same_package

/// Layout modes for responsive design.
@Deprecated('Use kEdenAppMode* tokens from lib/src/widgets/eden_app_mode.dart. '
    'See lib/src/utils/BREAKPOINTS.md for the canonical 5-tier vocabulary.')
enum EdenLayoutMode { mobile, tablet, desktop, wide }

/// Breakpoint layout utilities.
@Deprecated('Use kEdenAppMode* tokens from lib/src/widgets/eden_app_mode.dart. '
    'See lib/src/utils/BREAKPOINTS.md for the canonical 5-tier vocabulary.')
class EdenResponsive {
  // ... existing body unchanged
}
```

Also annotate `EdenResponsiveBuilder`:
```dart
@Deprecated('Use LayoutBuilder + kEdenAppMode* tokens directly. '
    'See lib/src/utils/BREAKPOINTS.md.')
class EdenResponsiveBuilder extends StatelessWidget {
  // ... existing body unchanged
}
```

Do NOT change the constant values (`mobileMax = 768`, `tabletMax = 1024`, `desktopMax = 1280`, etc.) — they stay for downstream consumers that haven't migrated yet.

**Step 1.3 — Validate and commit:**

```bash
dart format lib/src/widgets/eden_app_mode.dart lib/src/utils/responsive.dart
dart analyze lib/src/widgets/eden_app_mode.dart lib/src/utils/responsive.dart
flutter test test/  # confirm baseline still GREEN before moving on
```

Commit via df-tools:
```bash
node ~/.claude/devflow/bin/df-tools.cjs commit "refactor(breakpoints): add named tokens + soft-deprecate EdenResponsive" --files lib/src/widgets/eden_app_mode.dart lib/src/utils/responsive.dart
```

# CRITICAL: existing kEdenAppModeCompactMax (600) and kEdenAppModeExpandedMin (840) values MUST NOT change — locked at COMPANION_UX_PATTERNS_2026-05-15.md §0 lock E.
# GOTCHA: `ignore_for_file: deprecated_member_use_from_same_package` is required because EdenResponsive's own methods call each other; without it, dart analyze flags every self-reference.
# PATTERN: Token doc-comments mirror the existing kEdenAppModeCompactMax doc-comment style — cite the source decision, explain when to use this vs adjacent tokens.
</action>

<verify>
```bash
# 1. New tokens exist with correct values.
grep -E "kEdenAppMode(NarrowMax|DenseDesktopMin|FullDesktopMin)\s*=" lib/src/widgets/eden_app_mode.dart
# Expected output (3 lines):
#   const double kEdenAppModeNarrowMax = 480.0;
#   const double kEdenAppModeDenseDesktopMin = 1100.0;
#   const double kEdenAppModeFullDesktopMin = 1200.0;

# 2. Existing tokens unchanged.
grep -E "kEdenAppMode(CompactMax|ExpandedMin)\s*=" lib/src/widgets/eden_app_mode.dart
# Expected:
#   const double kEdenAppModeCompactMax = 600.0;
#   const double kEdenAppModeExpandedMin = 840.0;

# 3. EdenResponsive deprecated.
grep -E "^@Deprecated" lib/src/utils/responsive.dart | wc -l
# Expected: >= 2 (class EdenResponsive + class EdenResponsiveBuilder + optional enum).

# 4. Analyzer clean.
dart analyze lib/src/widgets/eden_app_mode.dart lib/src/utils/responsive.dart
# Expected: 'No issues found.' (or only deprecation warnings inside responsive.dart which are suppressed by ignore_for_file).

# 5. Baseline tests still GREEN.
flutter test 2>&1 | tail -3
# Expected: '+3865: All tests passed!' or whatever the current GREEN count is.

# 6. Commit landed.
git log --oneline -1
# Expected: 'refactor(breakpoints): add named tokens + soft-deprecate EdenResponsive'
```
</verify>

<done>
- 3 new constants (`kEdenAppModeNarrowMax`, `kEdenAppModeDenseDesktopMin`, `kEdenAppModeFullDesktopMin`) exist in `eden_app_mode.dart` with values 480.0, 1100.0, 1200.0 and doc-comments.
- Existing `kEdenAppModeCompactMax` and `kEdenAppModeExpandedMin` unchanged.
- `EdenLayoutMode`, `EdenResponsive`, `EdenResponsiveBuilder` carry `@Deprecated(...)` annotations pointing to the new tokens.
- `dart analyze` reports no errors for these two files.
- Full test suite still GREEN (no behavior change — just additions and annotations).
- One atomic commit landed via df-tools with message `refactor(breakpoints): add named tokens + soft-deprecate EdenResponsive`.
</done>

<recovery>
If `dart analyze` errors on `responsive.dart` after adding the annotations: confirm `// ignore_for_file: deprecated_member_use_from_same_package` is present at the top of the file (line 2). If still failing, move each `@Deprecated` annotation to the individual method level instead of the class level (more verbose but bypasses the same-package-deprecation issue completely).

If a test suddenly fails after this step: extremely unlikely (no behavior change), but check whether any test imported `EdenResponsive` and was relying on `isDeprecated == false`. Search: `grep -rn 'EdenResponsive' test/`. If any test file references it, just suppress with `// ignore: deprecated_member_use` on that line — the deprecation is intentional.
</recovery>
</task>

<task type="auto">
<name>Migrate inline literal sites to named tokens</name>

<files>
lib/src/widgets/eden_page_header.dart
lib/src/widgets/eden_gift_card_manager.dart
lib/src/widgets/eden_route_optimization_result.dart
lib/src/widgets/eden_sales_analytics_scaffold.dart
lib/src/widgets/eden_price_book_builder.dart
lib/src/widgets/eden_cash_drawer_close.dart
lib/src/widgets/eden_soap_note.dart
lib/src/widgets/eden_uswds_banner.dart
lib/src/widgets/eden_time_card.dart
lib/src/widgets/eden_time_slot_picker.dart
lib/src/widgets/eden_tank_fleet_map.dart
lib/src/widgets/eden_commissions_editor.dart
lib/src/widgets/eden_empty_state.dart
lib/src/widgets/eden_intake_form_builder.dart
lib/src/widgets/eden_template_builder/eden_template_builder_canvas.dart
lib/src/widgets/scheduler/scheduler_toolbar.dart
lib/src/widgets/eden_scheduler.dart
lib/src/widgets/eden_dispatch_page.dart
lib/src/widgets/eden_quick_add_product_grid.dart
lib/src/widgets/eden_pos_register_scaffold.dart
lib/src/widgets/eden_detail_header.dart
lib/src/widgets/eden_detail_page_scaffold.dart
lib/src/widgets/eden_list_page_scaffold.dart
lib/src/widgets/eden_role_dashboard_shell.dart
lib/src/widgets/eden_phone_input.dart
lib/src/widgets/eden_secure_messaging_thread.dart
lib/src/widgets/scheduler/scheduler_dialogs.dart
lib/src/pages/eden_settings_page.dart
lib/src/pages/eden_profile_page.dart
</files>

<action>
**Goal:** Migrate all inline literal breakpoint comparisons in `lib/src/` to use the named tokens added in Task 1. One-off literals get annotation comments instead. Single atomic commit (large but coherent — every change is "rename the literal at this site").

**Step 2.0 — Re-run discovery to confirm the migration set:**

```bash
grep -rnE "(constraints|c)\.maxWidth\s*[<>]=?\s*(480|600|840|1100|1200)" lib/src/ --include="*.dart"
grep -rnE "(constraints|c)\.maxWidth\s*[<>]=?\s*(390|768|800|900|1024|1280)" lib/src/ --include="*.dart"
grep -rnE "MediaQuery.*\.width\s*[<>]=?\s*(480|600|840|1100|1200|1280|1024)" lib/src/ --include="*.dart"
grep -rnE "this\.(narrow|tablet)Breakpoint\s*=\s*\d+" lib/src/ --include="*.dart"
grep -rnE "BoxConstraints\(maxWidth:\s*(480|600|840|1100|1200)" lib/src/ --include="*.dart"
```

Paste the full output as a checklist; tick each site as you migrate it. Expected ~21-25 distinct sites.

**Step 2.1 — Migration table (boundary literals → named tokens):**

Migrate these sites by replacing the literal with the named token. Add `import 'eden_app_mode.dart' show <token>;` (or relative path) at the top of each file if not already present.

| File:Line | Original | Replacement | Token |
|-----------|----------|-------------|-------|
| eden_page_header.dart:36 | `< 480` | `< kEdenAppModeNarrowMax` | NarrowMax |
| eden_gift_card_manager.dart:632 | `< 600` | `< kEdenAppModeCompactMax` | CompactMax |
| eden_price_book_builder.dart:873 | `>= 600` | `>= kEdenAppModeCompactMax` | CompactMax |
| eden_cash_drawer_close.dart:420 | `< 600` | `< kEdenAppModeCompactMax` | CompactMax |
| eden_soap_note.dart:150 | `>= 840` | `>= kEdenAppModeExpandedMin` | ExpandedMin |
| eden_uswds_banner.dart:178 | `>= 600` | `>= kEdenAppModeCompactMax` | CompactMax |
| eden_time_card.dart:168 | `< 600` | `< kEdenAppModeCompactMax` | CompactMax |
| eden_time_slot_picker.dart:182 | `< 600` | `< kEdenAppModeCompactMax` | CompactMax |
| eden_commissions_editor.dart:444 | `< 600` | `< kEdenAppModeCompactMax` | CompactMax |
| eden_empty_state.dart:82 | `< 480` | `< kEdenAppModeNarrowMax` | NarrowMax |
| eden_template_builder_canvas.dart:99 | `< 1200` | `< kEdenAppModeFullDesktopMin` | FullDesktopMin |
| scheduler_toolbar.dart:157 | `< 1100` | `< kEdenAppModeDenseDesktopMin` | DenseDesktopMin |
| scheduler_toolbar.dart:160 | `< 480` | `< kEdenAppModeNarrowMax` | NarrowMax |
| eden_scheduler.dart:299 | `< 600` | `< kEdenAppModeCompactMax` | CompactMax |
| eden_quick_add_product_grid.dart:124 | `< 600` | `< kEdenAppModeCompactMax` | CompactMax |
| dev_app/screens/scheduler_screen.dart:295 | `< 1100` | `< kEdenAppModeDenseDesktopMin` | DenseDesktopMin (SKIP — dev_app out of scope) |

**Note on dev_app/scheduler_screen.dart:295**: dev_app is out of scope per anti-pattern guidance. Skip it.

**Step 2.2 — Widget-param defaults (4th vocabulary):**

Replace the magic-number default in each widget's constructor with a named token. Public API (the param name) stays the same.

| File:Line | Original | Replacement |
|-----------|----------|-------------|
| eden_detail_header.dart:49 | `this.narrowBreakpoint = 480,` | `this.narrowBreakpoint = kEdenAppModeNarrowMax,` |
| eden_detail_page_scaffold.dart:54 | `this.narrowBreakpoint = 480,` | `this.narrowBreakpoint = kEdenAppModeNarrowMax,` |
| eden_list_page_scaffold.dart:48 | `this.narrowBreakpoint = 480,` | `this.narrowBreakpoint = kEdenAppModeNarrowMax,` |
| eden_role_dashboard_shell.dart:88 | `this.narrowBreakpoint = 480,` | `this.narrowBreakpoint = kEdenAppModeNarrowMax,` |
| eden_role_dashboard_shell.dart:89 | `this.tabletBreakpoint = 768,` | KEEP literal + `// breakpoint: 768 — legacy tablet floor; intentional one-off, not a canonical tier` |
| eden_phone_input.dart:52 | `this.narrowBreakpoint = 480.0,` | `this.narrowBreakpoint = kEdenAppModeNarrowMax,` |

Param defaults MUST be `const`-evaluable. The new constants are `const double`, so this works in default-param position.

**Step 2.3 — One-off literals (NOT canonical tiers) — annotate with comments:**

These sites keep the literal but get an explanatory inline comment. Format: `// breakpoint: <value> — <reason>`. Reason should be brief and self-evident from the call site.

| File:Line | Original | Annotated |
|-----------|----------|-----------|
| eden_route_optimization_result.dart:138 | `< 900` | `< 900; // breakpoint: 900 — route-optimization two-pane fold` |
| eden_sales_analytics_scaffold.dart:144 | `>= 1024` | `>= 1024; // breakpoint: 1024 — analytics tablet-landscape floor` |
| eden_price_book_builder.dart:459 | `< 900` | `< 900; // breakpoint: 900 — price-book two-pane fold` |
| eden_tank_fleet_map.dart:205 | `< 1024` | `< 1024; // breakpoint: 1024 — tank-fleet tabbed-fallback floor` |
| eden_intake_form_builder.dart:262 | `>= 900` | `>= 900; // breakpoint: 900 — intake three-pane floor` |
| eden_dispatch_page.dart:182 | `>= 1280` | `>= 1280; // breakpoint: 1280 — dispatch full-desktop tier` |
| eden_dispatch_page.dart:184 | `>= 1024` | `>= 1024; // breakpoint: 1024 — dispatch tablet-landscape tier` |
| eden_pos_register_scaffold.dart:226 | `>= 1024` | `>= 1024; // breakpoint: 1024 — POS register requires landscape tablet` |
| eden_quick_add_product_grid.dart:125 | `< 1024` | `< 1024; // breakpoint: 1024 — product-grid medium-tier column count` |
| eden_scheduler.dart:298 | `?? 1280;` | `?? 1280; // breakpoint: 1280 — default fallback for null MediaQuery (test contexts)` |

**Step 2.4 — `BoxConstraints(maxWidth: ...)` content-width clamps — annotate (NOT migrate):**

These are content-width clamps, not tier comparisons. Per the gotcha, treat as one-offs.

| File:Line | Pattern | Annotation |
|-----------|---------|------------|
| eden_settings_page.dart:54 | `BoxConstraints(maxWidth: 600)` | Add `// width: 600 — settings content clamp` |
| eden_profile_page.dart:148 | `BoxConstraints(maxWidth: 600)` | Add `// width: 600 — profile content clamp` |
| eden_secure_messaging_thread.dart:283 | `BoxConstraints(maxWidth: 480)` | Add `// width: 480 — message-bubble narrow clamp` |
| scheduler_dialogs.dart:79 | `BoxConstraints(maxWidth: 480)` | Add `// width: 480 — dialog narrow clamp` |

**Step 2.5 — Validate and commit:**

```bash
dart format lib/src/
dart analyze lib/src/
flutter test
```

Expect: 0 analyzer errors, 3865 tests GREEN. If a test fails, follow `<recovery name="tests-fail-after-migration">` in embedded_context.

Commit:
```bash
node ~/.claude/devflow/bin/df-tools.cjs commit "refactor(breakpoints): migrate inline literals to kEdenAppMode* tokens" --files lib/src/widgets/ lib/src/pages/
```

# CRITICAL: every named-token substitution MUST preserve the original value (480 → kEdenAppModeNarrowMax which is 480.0, not 500 or 460). Double-check the table.
# GOTCHA: dev_app/screens/ sites are OUT OF SCOPE — they're viewport-simulation demos, not production logic.
# GOTCHA: import paths vary by file location — see embedded_context > gotchas > import-path-varies-by-location.
# PATTERN: One-off comment format `// breakpoint: <value> — <reason>` should be terse but self-evident at the call site.
</action>

<verify>
```bash
# 1. No remaining inline boundary literals in lib/src/.
grep -rnE "(constraints|c)\.maxWidth\s*[<>]=?\s*(480|600|840|1100|1200)\b" lib/src/ --include="*.dart"
# Expected: zero hits (all migrated to named tokens).

# 2. One-off literals still present BUT now have annotation comments.
grep -rnE "(constraints|c)\.maxWidth\s*[<>]=?\s*(900|1024|1280)" lib/src/ --include="*.dart"
# Each hit should have a '// breakpoint: ...' or '; // breakpoint: ...' annotation on the same line. Spot-check 3-4.

# 3. Widget param defaults reference the token.
grep -n "this.narrowBreakpoint" lib/src/widgets/eden_detail_header.dart lib/src/widgets/eden_detail_page_scaffold.dart lib/src/widgets/eden_list_page_scaffold.dart lib/src/widgets/eden_role_dashboard_shell.dart lib/src/widgets/eden_phone_input.dart
# Each should show `= kEdenAppModeNarrowMax,` not `= 480` or `= 480.0`.

# 4. Imports of kEdenAppMode* tokens spread to migrated files.
grep -rn "kEdenAppMode" lib/src/widgets/ lib/src/pages/ --include="*.dart" | wc -l
# Expected: >= 25 (one or more refs per migrated file).

# 5. dart analyze clean.
dart analyze lib/src/ 2>&1 | tail -5
# Expected: 'No issues found.' or only deprecation warnings on EdenResponsive self-refs.

# 6. ALL TESTS STILL GREEN — this is the critical regression gate.
flutter test 2>&1 | tail -3
# Expected: same total test count as the pre-refactor baseline (e.g. '+3865: All tests passed!').
# If a test fails, do NOT commit — diagnose per error_recovery > tests-fail-after-migration.

# 7. Commit landed.
git log --oneline -1
# Expected: 'refactor(breakpoints): migrate inline literals to kEdenAppMode* tokens'

# 8. Off-limits-dir exception documented.
git log --oneline -1 | grep -i breakpoint
ls lib/src/widgets/eden_template_builder/eden_template_builder_canvas.dart
grep -n "kEdenAppModeFullDesktopMin" lib/src/widgets/eden_template_builder/eden_template_builder_canvas.dart
# Expected: at least 1 match showing the migration happened.
```
</verify>

<done>
- Zero inline canonical-boundary literals (480/600/840/1100/1200) remain in `lib/src/` `LayoutBuilder`/`MediaQuery` width comparisons — all use `kEdenAppMode*` tokens.
- One-off literals (390/768/800/900/1024/1280) preserved with `// breakpoint: X — reason` annotations.
- Widget-level `narrowBreakpoint` defaults (5 widgets) reference `kEdenAppModeNarrowMax`.
- `tabletBreakpoint = 768` on `eden_role_dashboard_shell` annotated as a one-off (not a canonical tier).
- `BoxConstraints(maxWidth: ...)` content-width clamps (4 sites) annotated but not migrated.
- `dart analyze` reports zero errors for `lib/src/`.
- Full test suite (3865 tests) GREEN — zero regressions.
- Off-limits-dir exception (`eden_template_builder_canvas.dart`) migrated per constraint exception.
- One atomic commit landed via df-tools.
</done>

<recovery>
**If `flutter test` fails:** Per `<error_recovery>` block in embedded_context. Most likely a wrong constant chosen — verify the original value matches the new token's value (480 → NarrowMax, 600 → CompactMax, 840 → ExpandedMin, 1100 → DenseDesktopMin, 1200 → FullDesktopMin). If a test was asserting against the literal value directly, update the test to import and reference the same constant.

**If a file's import path is wrong:** `dart analyze` will flag it with a `uri_does_not_exist` error. Fix per the import-path gotcha in embedded_context.

**If you discover an additional inline literal during the grep at Step 2.0 that's NOT in the migration table:** Decide using the rule from `<codebase_examples>`:
- On a canonical boundary (480/600/840/1100/1200)? → migrate to the matching token.
- Off boundary? → annotate with `// breakpoint: <value> — <reason>` comment.
- Document any additions in the commit message body.

**If the off-limits-dir migration (`eden_template_builder_canvas.dart`) breaks a template-builder test:** Per `<recovery name="off-limits-dir-test-failure">`. Update the test to import and reference `kEdenAppModeFullDesktopMin` for the same comparison — the constraint explicitly permits this rename.
</recovery>
</task>

<task type="auto">
<name>Add BREAKPOINTS.md vocabulary doc + final regression gate</name>

<files>
lib/src/utils/BREAKPOINTS.md
</files>

<action>
**Goal:** Land the canonical-vocabulary doc that future contributors will consult to pick the right token. Then run the final regression gate confirming the full refactor lands GREEN.

**Step 3.1 — Create `lib/src/utils/BREAKPOINTS.md`:**

Write the doc with these required sections (the actual prose below is the deliverable — write it verbatim adapted as needed):

```markdown
# Eden UI Flutter — Breakpoint Vocabulary

Canonical 5-tier Material 3 breakpoint set for `eden-ui-flutter`. All tokens
live in `lib/src/widgets/eden_app_mode.dart`. Use these tokens for all
viewport-width comparisons inside `lib/src/`.

## Tiers

| Token | Value (pt) | Tier | Use For |
|-------|-----------|------|---------|
| `kEdenAppModeNarrowMax` | 480 | Narrow (strict phone) | iPhone SE-class narrow guards: stack actions vertically, collapse multi-pane scaffolds. |
| `kEdenAppModeCompactMax` | 600 | Compact (M3) | Material 3 Compact tier upper bound. Below this: field-companion / phone-class chrome. |
| `kEdenAppModeExpandedMin` | 840 | Expanded (M3) | Material 3 Expanded tier lower bound. At/above: tablet-landscape or larger; admin chrome default. |
| `kEdenAppModeDenseDesktopMin` | 1100 | Dense desktop | Toolbar-collapse floor: at/above, toolbars can show expanded labels; below, collapse to icon-only. |
| `kEdenAppModeFullDesktopMin` | 1200 | Full desktop | Multi-pane fully-expanded floor: at/above, three-pane / canvas layouts can fully expand. |

Decision-source for Compact (600) and Expanded (840): COMPANION_UX_PATTERNS_2026-05-15.md §0 lock E.

## How to pick

1. Stacking actions vertically on narrow phones only? → `kEdenAppModeNarrowMax`
2. Switching between field-companion and tablet-or-larger chrome? → `kEdenAppModeCompactMax` (M3 Compact) or `kEdenAppModeExpandedMin` (M3 Expanded)
3. Collapsing a toolbar to icon-only on dense desktop? → `kEdenAppModeDenseDesktopMin`
4. Three-pane layout vs stacked? → `kEdenAppModeFullDesktopMin`

## One-offs (NOT canonical tiers)

These breakpoints appear in a handful of sites and are NOT canonical tiers.
Keep them as inline literals with `// breakpoint: <value> — <reason>` comments.
Do NOT add tokens for them.

- **390pt** — iPhone Pro / SE viewport width simulation (dev_app demo widths only).
- **768pt** — Legacy M2-era tablet floor; `EdenRoleDashboardShell.tabletBreakpoint` default.
- **800pt** — Sales-analytics tablet floor.
- **900pt** — Two/three-pane fold thresholds for individual components (route-optimization, price-book, intake-form).
- **1024pt** — Tablet-landscape floor for POS/analytics/dispatch/quick-add components.
- **1280pt** — Dispatch full-desktop / EdenScheduler default-fallback width.

## Legacy: `EdenResponsive`

`lib/src/utils/responsive.dart` provides a legacy `EdenResponsive` class
with M2-era breakpoints (mobileMax 768 / tabletMax 1024 / desktopMax 1280).
It is `@Deprecated` as of 2026-05-18. New code MUST use the `kEdenAppMode*`
tokens above. Downstream consumers (eden-biz-flutter, eden-platform-flutter)
should migrate at their next refactor pass.

## File layout

- **Token home:** `lib/src/widgets/eden_app_mode.dart`
- **Reference consumer:** `lib/src/widgets/eden_adaptive_layout.dart` (shows the import + comparison pattern).
- **This doc:** `lib/src/utils/BREAKPOINTS.md`

## Source

This vocabulary was consolidated in `.planning/quick/6-unify-breakpoint-vocabulary-in-eden-ui-f/`
based on the breakpoint-fragmentation note in
`.planning/quick/dev-catalog-visual-audit-2026-05-18.md` Section "Breakpoint
vocabulary note".
```

**Step 3.2 — Final regression gate (full validation):**

```bash
# All steps must pass before commit.
dart format lib/
dart analyze lib/ 2>&1 | tail -10
flutter test 2>&1 | tail -5
git status
```

Acceptance:
- `dart format`: no changes (idempotent — Tasks 1+2 already formatted).
- `dart analyze`: zero errors. Warnings restricted to `deprecated_member_use_from_same_package` inside `responsive.dart` (suppressed by ignore_for_file).
- `flutter test`: same total count as baseline (e.g. `+3865: All tests passed!`), zero failures.
- `git status`: only `lib/src/utils/BREAKPOINTS.md` untracked / new.

**Step 3.3 — Commit:**

```bash
node ~/.claude/devflow/bin/df-tools.cjs commit "docs(breakpoints): add BREAKPOINTS.md canonical-vocabulary doc" --files lib/src/utils/BREAKPOINTS.md
```

**Step 3.4 — Write SUMMARY.md (quick-full mode requirement):**

Per the quick-full mode (and CLAUDE.md feedback_workflow), write a brief SUMMARY.md to `.planning/quick/6-unify-breakpoint-vocabulary-in-eden-ui-f/SUMMARY.md` capturing:
- Total files modified count
- Tests GREEN count (baseline preserved)
- Off-limits-dir exception used (which dir, which file, justified by which constraint)
- Atomic-commit list (3 commits, with subject lines)
- Any surprises during discovery (e.g., EdenResponsive truly had 0 external call sites, not 2 as the audit said)

Keep it ≤ 30 lines. This is for the next session to pick up cleanly.

# CRITICAL: do NOT commit if `flutter test` shows ANY regression. The whole refactor is a no-behavior-change rename — a failure means a token-value mismatch slipped in. Diagnose and fix before committing.
# GOTCHA: `dart format` may show no-op output — that's expected if Tasks 1+2 already formatted. Idempotent.
# PATTERN: BREAKPOINTS.md sits next to `responsive.dart` (the deprecated file) so anyone reading the deprecation message lands on the migration doc immediately.
</action>

<verify>
```bash
# 1. Doc exists with required sections.
ls -la lib/src/utils/BREAKPOINTS.md
grep -c "^## " lib/src/utils/BREAKPOINTS.md
# Expected: file present, >= 5 second-level headings (Tiers, How to pick, One-offs, Legacy, File layout / Source).

# 2. Doc references all 5 named tokens.
grep -E "kEdenAppMode(NarrowMax|CompactMax|ExpandedMin|DenseDesktopMin|FullDesktopMin)" lib/src/utils/BREAKPOINTS.md | wc -l
# Expected: >= 5 (each token referenced at least once).

# 3. Final regression gate — ALL tests still GREEN.
flutter test 2>&1 | tail -3
# Expected: 'All tests passed!' or '+3865: All tests passed!'. ZERO failures.

# 4. dart analyze clean across full lib/.
dart analyze lib/ 2>&1 | grep -E "error|Error" | grep -v "deprecated_member_use_from_same_package" | wc -l
# Expected: 0 (no errors outside the expected deprecation warnings, which are suppressed anyway).

# 5. Three atomic commits landed in order.
git log --oneline -3
# Expected output (most recent first):
#   <hash> docs(breakpoints): add BREAKPOINTS.md canonical-vocabulary doc
#   <hash> refactor(breakpoints): migrate inline literals to kEdenAppMode* tokens
#   <hash> refactor(breakpoints): add named tokens + soft-deprecate EdenResponsive

# 6. SUMMARY.md exists for the quick job.
ls -la .planning/quick/6-unify-breakpoint-vocabulary-in-eden-ui-f/SUMMARY.md

# 7. No EdenResponsive external consumers remain (final confirmation deprecation is safe).
grep -rn 'EdenResponsive\b' lib/src/ test/ --include='*.dart' | grep -v 'lib/src/utils/responsive.dart'
# Expected: empty result (no consumers outside the deprecated file itself).

# 8. Architectural invariant: transport-agnostic unchanged.
grep -rE "import\s+'package:(http|dio|grpc|shared_preferences|flutter_riverpod)" lib/src/widgets/eden_app_mode.dart lib/src/utils/
# Expected: empty (no new transport / state-mgmt deps introduced).

# 9. No new pubspec deps.
git diff pubspec.yaml pubspec.lock 2>&1 | head -5
# Expected: empty diff (no dependency churn).
```
</verify>

<done>
- `lib/src/utils/BREAKPOINTS.md` exists with all 5 sections (Tiers / How to pick / One-offs / Legacy / File layout+Source) and references all 5 `kEdenAppMode*` tokens.
- Full `flutter test` GREEN at the same baseline count as before the refactor — zero behavior regressions.
- `dart analyze lib/` reports zero errors.
- Three atomic commits landed in order via df-tools (named tokens + deprecation → migration → doc).
- `.planning/quick/6-unify-breakpoint-vocabulary-in-eden-ui-f/SUMMARY.md` exists capturing files-modified count, test baseline, off-limits-dir exception, commit list, and discovery surprises.
- Transport-agnostic invariant preserved (no new imports of http/dio/grpc/shared_preferences/flutter_riverpod).
- `pubspec.yaml` / `pubspec.lock` unchanged (no new deps).
- No `EdenResponsive` external consumers exist anywhere in `lib/src/` or `test/` — deprecation confirmed safe.
</done>

<recovery>
**If `flutter test` shows any failure at this final gate:**
1. Do NOT commit the doc. Roll back to clean working tree first: `git status` to see new file, leave it untracked.
2. Identify the failing test: `flutter test --reporter expanded 2>&1 | grep -A 20 "FAILED\|EXCEPTION"`.
3. Diagnose per `<recovery name="tests-fail-after-migration">` in embedded_context — most likely a wrong-token substitution from Task 2.
4. Fix in a follow-up commit on Task 2's branch — DO NOT amend the Task 2 commit (atomic-commit policy).
5. Re-run the gate. Only commit BREAKPOINTS.md once the suite is GREEN.

**If `dart analyze` shows unexpected errors:** Likely a stray import or a missed substitution. Re-run the discovery grep from Task 2 Step 2.0 to spot leftover sites.

**If grep at verify-step 7 finds an external EdenResponsive consumer that wasn't there during planning:** Possible since the codebase moves fast. Migrate that one site to the matching token in this task, document in SUMMARY.md, then re-run the gate.
</recovery>
</task>

</tasks>

<verification>
**End-to-end verification this whole job succeeded:**

```bash
# Tokens exist with correct values.
grep -E "^const double kEdenAppMode(NarrowMax|CompactMax|ExpandedMin|DenseDesktopMin|FullDesktopMin)" lib/src/widgets/eden_app_mode.dart
# Expected: 5 const double declarations matching 480.0, 600.0, 840.0, 1100.0, 1200.0.

# Deprecation in place.
grep "@Deprecated" lib/src/utils/responsive.dart | wc -l
# Expected: >= 2 (class-level + enum-level + ResponsiveBuilder-level — 2-3 acceptable).

# Migration completed.
grep -rnE "(constraints|c)\.maxWidth\s*[<>]=?\s*(480|600|840|1100|1200)\b" lib/src/ --include="*.dart"
# Expected: zero hits.

# Doc landed.
test -f lib/src/utils/BREAKPOINTS.md && echo "doc exists"

# Three atomic commits in correct order.
git log --oneline -3 | grep -E "^[a-f0-9]+ (refactor|docs)\(breakpoints\)"
# Expected: 3 lines, two refactor + one docs.

# Regression-free.
flutter test 2>&1 | tail -3
# Expected: 'All tests passed!' at baseline count.

# Architectural invariant.
git diff HEAD~3 pubspec.yaml pubspec.lock | wc -l
# Expected: 0 (no dep churn across the whole job).
```
</verification>

<success_criteria>
- Single JOB.md written to `.planning/quick/6-unify-breakpoint-vocabulary-in-eden-ui-f/6-JOB.md`.
- 3 atomic-commit tasks defined (tokens+deprecation → migration → docs+gate).
- `must_haves` in frontmatter (truths, artifacts, key_links) — required by quick-full mode.
- Each task has `files`, `action`, `verify`, `done` fields.
- TDD skipped, justified in resolved_configuration.
- Off-limits-dir exception documented (`eden_template_builder_canvas.dart` migration permitted by constraints).
- 5-tier canonical vocabulary (Narrow/Compact/Medium/DenseDesktop/FullDesktop) honored.
- Verification gates use `dart format`, `dart analyze`, `flutter test` (Flutter stack routing).
- All 3865 existing tests must remain GREEN — encoded as the primary verification gate.
- No new pubspec deps.
- Transport-agnostic invariant preserved.
- df-tools commit used (raw git commit blocked per constraints).
</success_criteria>

<output>
After all 3 tasks complete:
- `lib/src/widgets/eden_app_mode.dart` — extended with 3 new tokens
- `lib/src/utils/responsive.dart` — soft-deprecated
- ~25 files in `lib/src/widgets/` and `lib/src/pages/` — inline literals migrated to named tokens or annotated as one-offs
- `lib/src/utils/BREAKPOINTS.md` — new canonical-vocabulary doc
- `.planning/quick/6-unify-breakpoint-vocabulary-in-eden-ui-f/SUMMARY.md` — brief job recap
- Three atomic commits on the working branch, GREEN test baseline preserved.
</output>
