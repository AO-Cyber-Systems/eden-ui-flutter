---
objective: 6-unify-breakpoint-vocabulary-in-eden-ui-f
job: 6
type: standard
mode: quick-full
work: refactor
status: complete
duration: ~25min
tests: 3865 GREEN (baseline preserved)
files_modified: 30
commits: 3
completed_date: 2026-05-18
---

# Job 6: Unify Breakpoint Vocabulary — SUMMARY

**One-liner:** Consolidated 4 coexisting breakpoint vocabularies into a single canonical Material 3 5-tier set (`kEdenAppMode*` tokens), soft-deprecated `EdenResponsive`, migrated 21+ inline literals, documented in `BREAKPOINTS.md`. Zero behavior regressions across 3865 tests.

## Files Modified

- **2 token/legacy files:** `lib/src/widgets/eden_app_mode.dart` (extended with 3 new tokens), `lib/src/utils/responsive.dart` (soft-deprecated via `@Deprecated`).
- **27 widget/page files in `lib/src/`:** inline literals migrated to named tokens (15 sites) OR annotated as intentional one-offs (12 sites including BoxConstraints clamps).
- **1 new doc:** `lib/src/utils/BREAKPOINTS.md` — canonical 5-tier vocabulary with usage guide.

## Atomic Commits (3, in order)

1. `b528174` — `refactor(breakpoints): add named tokens + soft-deprecate EdenResponsive`
2. `a018b9d` — `refactor(breakpoints): migrate inline literals to kEdenAppMode* tokens`
3. `d60d648` — `docs(breakpoints): add BREAKPOINTS.md canonical-vocabulary doc`

All pushed to `origin/main`.

## New Tokens

| Token | Value | Purpose |
|-------|-------|---------|
| `kEdenAppModeNarrowMax` | 480.0 | Strict narrow-phone guard (iPhone SE-class) |
| `kEdenAppModeDenseDesktopMin` | 1100.0 | Toolbar-collapse floor |
| `kEdenAppModeFullDesktopMin` | 1200.0 | Multi-pane fully-expanded floor |

Existing `kEdenAppModeCompactMax=600` and `kEdenAppModeExpandedMin=840` unchanged (locked at COMPANION_UX_PATTERNS_2026-05-15.md §0 lock E).

## Verification

- **Test gate:** `flutter test` → 3865 GREEN (matches baseline, zero regressions).
- **Analyzer:** `dart analyze lib/src/` → 0 errors. Pre-existing info-level lints unchanged (out of scope).
- **Boundary literal grep:** `grep -rnE "(constraints|c)\.maxWidth\s*[<>]=?\s*(480|600|840|1100|1200)\b" lib/src/` → zero hits.
- **Pubspec churn:** `git diff HEAD~3 pubspec.yaml pubspec.lock` → 0 lines.
- **Transport invariant:** No new imports of http/dio/grpc/shared_preferences/flutter_riverpod.

## Off-Limits-Dir Exception (Documented)

Per job constraints, one rename-only migration permitted inside an otherwise off-limits dir:

- `lib/src/widgets/eden_template_builder/eden_template_builder_canvas.dart:99` — `< 1200` → `< kEdenAppModeFullDesktopMin`.
- Other off-limits dirs (`eden_diagram`, `eden_process_canvas`, `eden_workflow_canvas`) — zero modifications.

## Discovery Surprises

- **EdenResponsive truly has 0 external call sites** (audit said "2 stale references"). Only its own internal methods reference each other (handled via `ignore_for_file: deprecated_member_use_from_same_package`). Soft-deprecation confirmed safe.
- **One additional `narrowBreakpoint` site found** in `lib/src/widgets/eden_store_credit_ledger.dart:179` (default `700`) that wasn't in the planning migration table. Left as-is — 700 is not a canonical tier and the file wasn't on the planning file-list.
- **`dart format lib/src/` reformatted 316 unrelated files** (pre-existing formatter drift, different Dart SDK version). Restored unrelated files via `git checkout HEAD --` before commit. Only the 30 intentionally-touched files reformatted (idempotent — `0 changed` on re-run).
- **`lib/src/widgets/eden_app_mode.dart` doc-comment** at line 24 references `EdenResponsive.mobileMax` — kept (it's documentation of the historical divergence, not a runtime consumer).

## Deferred / Out of Scope

- 316 unrelated files needed `dart format` whitespace reflow (different formatter version than codebase). Out of scope for this refactor — flagged for a follow-up formatting-only commit if desired.
- 32 pre-existing info-level analyzer lints (deprecated `groupValue` on `Radio` post-Flutter 3.32, prefer_const_constructors, unnecessary_import in scheduler module). Out of scope.

## Self-Check: PASSED

- 3 atomic commits exist (`b528174`, `a018b9d`, `d60d648`) — verified via `git log --oneline -3`.
- `lib/src/utils/BREAKPOINTS.md` exists with 6 `## ` sections + 9 token references.
- All 3865 tests GREEN.
- No `EdenResponsive` external consumers.
- Pubspec unchanged.
