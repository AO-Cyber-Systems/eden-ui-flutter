---
objective: 23-ui-oracle-loop-w1a-catalog-as-contract
job: 10
subsystem: design-tokens
tags: [dart, flutter, codegen, markdown, tdd]

# Dependency graph
requires: []
provides:
  - "tool/gen_design_md.dart — pure extractTokens/renderTokenBlock/spliceIntoMarkers + main() IO shell"
  - "DESIGN.md — hand-written token-reference prose with a marker-bounded generated token block"
  - "test/design/design_md_fresh_test.dart — the staleness gate (runs inside the existing flutter test CI job)"
  - "test/tool/gen_design_md_test.dart — unit coverage of the extract/render/splice primitives"
affects: [23-11, 23-12]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Generated-block-in-hand-written-file: BEGIN/END HTML-comment markers bound the only region a tool may touch; spliceIntoMarkers throws rather than appending or rewriting when a marker is missing."
    - "Class-scoped strict extraction: extraction is bounded to one named class per file (EdenColors/EdenSpacing/EdenRadii/EdenTypography) rather than the whole file, so app-specific bonus classes bundled in the same source file (AOHealthGradients, AOHealthColors) are out of scope by design, not silently skipped."
    - "Fail loudly on an unrecognized static declaration inside the scanned class body; named skips (MaterialColor swatch, the presets index map, derived BorderRadius helpers, font-family-only getters) are explicit and commented, never silent."

key-files:
  created:
    - tool/gen_design_md.dart
    - DESIGN.md
    - test/design/design_md_fresh_test.dart
    - test/tool/gen_design_md_test.dart
  modified: []

key-decisions:
  - "Extraction is scoped per-file to exactly one named class body (found by a column-0-brace heuristic matching this repo's dartfmt output), not the whole file — colors.dart also holds AOHealthGradients/AOHealthColors (app-specific gradient/color bundles unrelated to the shared Eden design tokens), which are never scanned."
  - "A MaterialColor swatch (gold, blue, emerald, ...) is documented as ONE token row (name + base hex) rather than expanding all 11-12 shades — the recovery note anticipated exactly this shape."
  - "The `presets` derived index (Map<String, MaterialColor>) and radii.dart's derived `BorderRadius.circular(x)` helpers are explicitly, individually named skip patterns — not a blanket 'ignore anything odd' rule."
  - "typography.dart's three font-family-only getters (displayFont/bodyFont/monoFont) are out of scope for 'type scale' (a scale of sizes) and are an explicit named skip; the 15 fontSize/fontWeight/height TextStyle methods (displayLarge...codeSmall) ARE the type scale and are generated."
  - "shadows.dart, springs.dart and durations.dart are never read at all (not just omitted from rendering) — row 1a-10 scopes generation to colour, type scale, spacing and radii; the block ends with a literal '_Not generated: shadows, springs (structured values)._' footer."

patterns-established:
  - "Pure extract/render/splice core + main() IO shell, mirroring tool/emit_flutter_manifest.dart's split and its 'flutter test tool/<x>.dart' run convention."

requirements-completed: [W1A-1a-10]

# Verification evidence
verification:
  gates_defined: 3
  gates_passed: 3
  auto_fix_cycles: 0
  tdd_evidence: true
  test_pairing: true

# Metrics
duration: 20min
completed: 2026-09-22
---

# Objective 23 TRD 10: Generated DESIGN.md token block Summary

**`tool/gen_design_md.dart` extracts colour/type-scale/spacing/radii tokens from `lib/src/tokens/*.dart` by a strict per-class, per-shape scan and splices them into a marker-bounded block in a hand-written `DESIGN.md`; `test/design/design_md_fresh_test.dart` fails, by name, with the regeneration command, whether the markdown or the Dart drifts.**

## Performance

- **Duration:** ~20 min
- **Tasks:** 2
- **Files created:** 4 (`tool/gen_design_md.dart`, `DESIGN.md`, `test/design/design_md_fresh_test.dart`, `test/tool/gen_design_md_test.dart`)

## Accomplishments
- Strict, class-scoped Dart token extraction for four shapes (flat `Color`, `MaterialColor` swatch, `double`, and typography's two-line `TextStyle(fontSize/fontWeight/height)` method) with named, documented skips for everything intentionally out of scope, and a loud named error for anything unrecognized.
- `DESIGN.md` created: thin hand-written prose pointing to `design-stack-flutter.md` and `design/patterns/` for RULES, a marker-bounded generated token block (Colors, Type scale, Spacing, Radii — 19 + 15 + 12 + 6 = 52 rows), and a footer noting shadows/springs are not generated.
- Freshness gate proven to fail from BOTH directions: an edited value in the committed markdown, and a token added to the Dart with no regeneration — same named test, same "Regenerate with: flutter test tool/gen_design_md.dart" remedy either way.
- Idempotent generation confirmed: running the generator twice in a row leaves `git status --short DESIGN.md`/`git status --short` clean.

## Task Evidence

| Task | Verify Command | Exit Code | Status |
|---|---|---|---|
| 1: tool/gen_design_md.dart — extract/render | `flutter test test/tool/gen_design_md_test.dart` | 0 | PASS |
| 2: DESIGN.md + freshness gate | `flutter test test/design/design_md_fresh_test.dart` | 0 | PASS |

## Task Commits

1. **Task 1: extract/render/splice primitives** —
   - `605a49c` test(23-10): add failing tests for gen_design_md extract/render/splice primitives
   - `5914dba` feat(23-10): tool/gen_design_md.dart - strict token extraction, stable render, marker-bounded splice
2. **Task 2: DESIGN.md + freshness gate** —
   - `2ed9a12` feat(23-10): DESIGN.md - hand-written token reference prose + generated token block
   - `56c8c91` test(23-10): freshness gate for DESIGN.md's generated token block (cases 5-8)
   - `aa348b2` fix(23-10): drop the duplicated w prefix in type-scale font-weight rendering (w800 not ww800)

_Note: no separate REFACTOR commit — the `aa348b2` fix above is a genuine bug (rendered "ww800"), caught by inspecting the generated DESIGN.md before committing it, not a style refactor._

## Validation Gate Results

| Gate | Command | Exit Code | Status |
|---|---|---|---|
| lint | `flutter analyze --no-fatal-infos` | 0 | PASS (369 issues, 0 errors, same 2 pre-existing warnings as baseline) |
| test (focused) | `flutter test test/design/design_md_fresh_test.dart test/tool/gen_design_md_test.dart` | 0 | PASS (9/9) |
| build (full suite) | `flutter test` | 0 | PASS (4632 passed, 5 skipped, 0 failed — baseline 4623 + 9 new) |

## TDD Evidence

| Phase | Command | Exit Code | Expected |
|---|---|---|---|
| RED (Task 1, cases 1-4 + splice) | `flutter test test/tool/gen_design_md_test.dart` with `tool/gen_design_md.dart` temporarily renamed away | 1 | FAIL (correct) — "Method not found: 'extractTokens'/'TokenEntry'/'renderTokenBlock'/'spliceIntoMarkers'", "Undefined name 'TokenGroup'/'kBeginMarker'/'kEndMarker'" |
| GREEN (Task 1) | `flutter test test/tool/gen_design_md_test.dart` (restored) | 0 | PASS (correct) — 6/6 |
| RED (Task 2, case 5 — perturb DESIGN.md) | edited `\`gold\` \| \`0xFFD4A853\`` → `...54` in DESIGN.md, then `flutter test test/design/design_md_fresh_test.dart --plain-name "cases 5"` | 1 | FAIL (correct) — "DESIGN.md's token block is stale. first difference: line 25 / expected: \| \`gold\` \| \`0xFFD4A853\` \| / found: \| \`gold\` \| \`0xFFD4A854\` \| / Regenerate with: flutter test tool/gen_design_md.dart"; reverted with `git checkout -- DESIGN.md` |
| RED (Task 2, case 6 — perturb the Dart) | added `static const Color caseSixProbeToken = Color(0xFF123456);` to `lib/src/tokens/colors.dart`, then re-ran the same test | 1 | FAIL (correct) — "first difference: line 40 / expected: \| \`caseSixProbeToken\` \| \`0xFF123456\` \| / found: \| \`auroraPurple\` \| \`0xFFA855F7\` \|"; reverted with `git checkout -- lib/src/tokens/colors.dart` |
| GREEN (Task 2, after both reverts) | `flutter test test/design/design_md_fresh_test.dart` | 0 | PASS (correct) — 3/3 |

## Post-TRD Verification

- **Auto-fix cycles used:** 1 (the `ww800` font-weight rendering bug, caught by reading the generated DESIGN.md, fixed in `aa348b2` before any commit claimed GREEN)
- **Must-haves verified:** 3/3 (generated-from-Dart truths; the "token added, no regen" failure; prose survives regeneration)
- **Gate failures:** None

## Files Created/Modified
- `tool/gen_design_md.dart` — extractTokens (per-group strict shape, class-scoped), renderTokenBlock (stable, marker-bounded), spliceIntoMarkers (throws on missing marker), classBody (column-0-brace class scoping), generateTokenBlock (whole-repo orchestration shared by main() and the freshness test), main() IO shell writing DESIGN.md.
- `DESIGN.md` — thin hand-written intro + "Adding a token" footer; generated block for Colors (19 rows: 7 MaterialColor swatch families + neutral + 8 status + 4 aurora + cyan), Type scale (15 rows: displayLarge...codeSmall), Spacing (12 rows), Radii (6 rows); `_Not generated: shadows, springs (structured values)._` footer.
- `test/design/design_md_fresh_test.dart` — the staleness gate (compares in-memory regeneration to the committed file, never writes) + prose-preservation invariant + no-write invariant.
- `test/tool/gen_design_md_test.dart` — hand-built-fixture unit tests for the four extraction/rendering primitives.

## Decisions Made
See `key-decisions` in frontmatter — the load-bearing one is scoping extraction to a single named class per file (not the whole file), which is what keeps colors.dart's `AOHealthGradients`/`AOHealthColors` classes and the `presets`/`BorderRadius` derived members from tripping the strict "fail loudly on unmatched" rule while still refusing to silently skip anything inside the actual token classes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed doubled "w" prefix in type-scale font-weight rendering**
- **Found during:** Task 2 (running the generator and reading the produced DESIGN.md before committing)
- **Issue:** `FontWeight.(\w+)` already captures the leading "w" (e.g. "w800"), but the renderer also prepended a literal "w", producing "ww800" instead of "w800" for every type-scale row.
- **Fix:** Drop the prepended "w"; render the captured group directly.
- **Files modified:** `tool/gen_design_md.dart`
- **Verification:** Re-ran `flutter test tool/gen_design_md.dart` and inspected the regenerated `DESIGN.md` — all 15 type-scale rows now read `w800`/`w700`/.../`w400` correctly; `flutter test test/tool/gen_design_md_test.dart` and `test/design/design_md_fresh_test.dart` both still green.
- **Committed in:** `aa348b2`

**2. [Rule 3 - Blocking] Real token files have shapes the TRD's sketch only partly anticipated**
- **Found during:** Task 1 design, reading `lib/src/tokens/colors.dart` and `typography.dart`
- **Issue:** The TRD's recovery note anticipated `MaterialColor` swatches but not: `colors.dart` also holding two unrelated app-specific classes (`AOHealthGradients`, `AOHealthColors`) and a derived `presets` map; `radii.dart` holding derived `BorderRadius.circular()` helpers alongside the raw doubles; `typography.dart` having NO `static const` declarations at all for its "type scale" (it's `static TextStyle` methods/getters returning `GoogleFonts.x(fontSize:...)` calls).
- **Fix:** Scoped extraction per-file to one named class body; added explicit, individually-commented skip patterns for the derived/out-of-scope members (presets index, BorderRadius helpers, font-family-only getters) alongside the strict per-group accepted shapes; gave typography its own two-line "type scale" shape distinct from the const-scalar shape used elsewhere.
- **Files modified:** `tool/gen_design_md.dart`
- **Verification:** `flutter test test/design/design_md_fresh_test.dart` passes against the real files (idempotent, no error), and both RED perturbation proofs (cases 5 and 6, above) demonstrate the strict-shape/staleness guarantees still hold.
- **Committed in:** `5914dba` (part of Task 1's feat commit — this was resolved before the first GREEN, not a later patch)

---

**Total deviations:** 2 (1 auto-fixed bug, 1 auto-resolved blocking/scope question)
**Impact on plan:** No scope creep — both were necessary to make the generator actually work against the real repository rather than an idealized token file; the class-scoping decision is called out explicitly above and in the TRD's own `key-decisions` so a reviewer can second-guess it directly.

## Issues Encountered
None beyond the two deviations above.

## User Setup Required
None — no external service configuration required.

## Next Objective Readiness
- `DESIGN.md`'s token block is generated and covered by the existing `flutter test` CI job — no `ci.yml` change needed or made.
- `git diff pubspec.yaml` is empty; no dependency was added (`dart:io` + the already-present `flutter_test` only).
- 23-11 (custom_lint) and 23-12 (release v2.2.0) do not depend on anything this TRD would need to change further.

---
*Objective: 23-ui-oracle-loop-w1a-catalog-as-contract*
*Completed: 2026-09-22*
