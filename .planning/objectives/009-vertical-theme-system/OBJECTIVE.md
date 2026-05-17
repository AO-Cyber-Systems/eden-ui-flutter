---
objective: 009-vertical-theme-system
kind: ui-lib
work: feature
status: planned
estimated_effort: 2-3 weeks Claude execution
trd_count: 5
waves: 3
github_issue: TBD
---

# Objective 009 — Vertical Theme System + Brand Preset Registry

## Goal

Ship the foundational theme infrastructure that lets `eden-ui-flutter` present **5 distinct aesthetic profiles** (commercial / medical / gov / retail / legal) and **per-tenant brand color overrides** without changing a single line of consumer widget code. After this objective ships, downstream `eden-biz-flutter` and other Eden Flutter apps wrap their `MaterialApp` in `EdenAdaptiveTheme(profile: ..., brand: ..., child: ...)` and the entire 230+ widget catalog renders in the chosen aesthetic. The current `EdenTheme.light()/dark()` API continues to work unchanged — new profiles are strictly opt-in.

Per the locked recommendation in `VERTICAL_UX_RESEARCH_2026-05-16.md` §2.4 and §3.1, this is the single highest-leverage step in the eden-ui-flutter roadmap: **unlocks all 7 verticals on the existing shell + 230+ component catalog** without inventing new components. Required precursor to medical (Obj 013) and gov-compliance (Obj 011) downstream work, both of which depend on `EdenThemeProfile.medicalInstitutional` and `EdenThemeProfile.govFederal` being available.

## Why now

- **Cross-vertical readiness.** Salon, trades, fuel verticals already ship today on `commercialWarm` (de facto default). Medical (consultative whiteish/teal) and gov (federal navy/red, USWDS-conformant) verticals are blocked on aesthetic profile support — they cannot ship on today's single-aesthetic theme.
- **Per-tenant branding gap.** `EdenTheme.brandColor` is a global mutable static. Multi-tenant downstream apps (`eden-biz-flutter` future tenant switching) cannot brand-override per tenant without a per-tenant theme-resolve wrapper.
- **Status-color inconsistency.** Today's widgets hard-code `EdenColors.error`, `Colors.red`, `EdenColors.success` etc. There's no profile-driven semantic palette — every vertical inherits commercial-warm status hues, which reads as "celebratory" in oncology contexts and "informal" in gov contexts.
- **Font opt-in blocker for institutional verticals.** Medical wants IBM Plex Sans; gov wants Public Sans. Today's theme bakes Outfit/Plus Jakarta into the `TextTheme` with no profile-aware override path.
- **Backwards-compat tax compounds.** Every additional widget shipped on the single-aesthetic theme makes a later retrofit more expensive. Ship the foundation now while the API surface is still tractable.

## Scope (5 TRDs across 3 waves)

| TRD | Focus | Wave |
|---|---|---|
| 009-01 | `EdenThemeProfile` enum + `EdenThemeProfileData` value type (5 profiles: commercialWarm / medicalInstitutional / govFederal / retailVibrant / legalProfessional) with token deltas (primary color, surface tonal map, radii multiplier, density, optional font family slots, ≥48pt touch floor for gov) + `EdenThemeProfileScope` `InheritedWidget` for context-based lookup. Pure data + scope — no theme building yet. | 1 |
| 009-02 | `EdenStatusPalette extends ThemeExtension<EdenStatusPalette>` semantic color palette (success / warning / danger / info / neutral × {bg, fg, border, text} subset) with profile-aware default constructors + back-compat fallback so `EdenColors.success` static reads keep working. Extended `EdenTheme.light/dark` to attach `EdenStatusPalette` to `ThemeData.extensions` based on profile. | 1 |
| 009-03 | `EdenBrandPreset` value class + `EdenBrandPresetRegistry` with 10+ ship-with presets (gold/blue/emerald/purple/red/slate/cyan from existing `EdenColors.presets` + new vertically-flavored: salonCoral / tradesIndustrialBlue / medicalTeal / fuelEnergyOrange / govFederalNavy / legalNavy / retailVibrantMagenta / wellnessSage). Registry exposes lookup by id + filter by recommended vertical. | 2 |
| 009-04 | `EdenProfileFonts` per-profile font opt-in helper using existing `google_fonts ^6.1.0` package (no new pubspec deps). Maps profiles to font family closures: medical → IBM Plex Sans/Mono + Outfit display retained; gov → Public Sans body + display; legal → Crimson Pro display opt-in; default + retail → existing Outfit/Plus Jakarta/JetBrains Mono. Hand-rolled `EdenProfileFontResolver` so consumers don't need to know per-profile font family strings. | 2 |
| 009-05 | `EdenAdaptiveTheme` top-level widget that wraps `MaterialApp` (typically used as `MaterialApp(theme: EdenAdaptiveTheme.light(profile, brand), darkTheme: EdenAdaptiveTheme.dark(profile, brand))` OR as an ancestor widget that provides the `EdenThemeProfileScope` and re-themes via inherited resolution). Composes 009-01..009-04. Includes the visual catalog screen `lib/dev_app/screens/theme_profiles_screen.dart` showing all 5 profiles side-by-side with sample-component triptychs (button + card + badge under each profile + each font + each brand preset). | 3 |

## Wave structure (parallelism map)

- **Wave 1 — Foundation (sequential, 2 TRDs):** 009-01 first (enum + data + scope — pure data, no Material wiring). 009-02 depends on 009-01 because `EdenStatusPalette` needs the profile enum to default its values. Sequential within the wave.
- **Wave 2 — Brand + Font (parallel, 2 TRDs):** 009-03 (brand-preset registry — pure data, no theme dependency) and 009-04 (per-profile font helper — depends on 009-01 for profile enum only) can run **in parallel**. Distinct files, distinct concerns, no overlap.
- **Wave 3 — Adaptive wrapper (1 TRD):** 009-05 — composes everything. Single TRD because it's the integration point + the catalog screen + the back-compat verification harness.

## Constraints (locked, do not revisit)

1. **Backwards-compatible. No exceptions.** `EdenTheme.light()` and `EdenTheme.dark()` continue to work with zero changes for consumers. All existing 1041+ widget tests pass without modification. The default profile (`EdenThemeProfile.commercialWarm`) reproduces today's pixel output exactly.
2. **No new pubspec dependencies.** Library remains at 0-new-deps for fonts (use existing `google_fonts ^6.1.0` for IBM Plex / Public Sans / Crimson Pro). NO `intl`, NO theme-management packages (`flex_color_scheme`, `theme_tailor` etc. are NOT permitted).
3. **No vertical-specific imports in widgets.** Widgets read from `Theme.of(context).extension<EdenStatusPalette>()` or `EdenThemeProfileScope.maybeOf(context)`. NO `if (profile == EdenThemeProfile.medical) { ... }` runtime branching in widgets. Theme data drives behavior; widgets stay vertical-agnostic.
4. **Hand-built fixtures + sample data.** Per global TDD Playbook habit 4 + resolver `no_llm_test_data` constraint: every test fixture file carries the `// Do NOT regenerate via LLM` header. Brand presets, profile data, and font resolver tables are hand-built — no AI-shaped repetition.
5. **`type: tdd` is the default per global TDD Playbook habit 1.** Each TRD includes a `## Test list` section enumerating behavior cases BEFORE any test code. Each TRD ships as ONE feature with RED→GREEN→REFACTOR commit cadence. Habit 3 (one test at a time) applies during execution.
6. **Outside-in test ordering per habit 5.** For TRDs ending in catalog/widget changes (009-05), test order is: catalog screen mount test → widget composition test → token/data unit test. For pure-data TRDs (009-01..04), test order is: public API contract test → derived getter test → edge-case test.
7. **Per locked decision C (vertical-flavor at PAGE level, NOT shell).** Theme profile is a global per-tenant config. Widgets adapt automatically by reading theme tokens. No page-level theme override APIs. No "render this page in `govFederal` but the rest in `commercialWarm`" support — out of scope.
8. **`wrap()` test helper pattern.** Every test file declares its own `Widget wrap(Widget child)` helper (mirror `test/widgets/eden_authenticated_image_test.dart` shape). For tests that need a specific profile, wrap variant: `Widget wrapWithProfile(EdenThemeProfile profile, Widget child)` defined inline.
9. **iPhone-narrow ≥390pt baseline preserved.** The catalog screen `theme_profiles_screen.dart` MUST render without `RenderFlex overflowed` warnings at 390pt logical width. Use `Wrap` or `SingleChildScrollView` triptychs, not unbounded `Row`s.
10. **Export section in `lib/eden_ui.dart`.** Open `// Objective 009 — Vertical Theme System` section header. Add exports incrementally per TRD (each TRD appends only its own files to the section).
11. **Profile names are LOCKED.** `commercialWarm`, `medicalInstitutional`, `govFederal`, `retailVibrant`, `legalProfessional`. Do NOT rename or add profiles in this objective. Future profiles (e.g., `commercialDense` for trades-dispatcher density) are deferred to a v2 objective.
12. **No `EdenSpacing.spaceHalf` / `EdenDensity` enum in this objective.** Density work is deferred. The 009-01 `EdenThemeProfileData` carries a `density` field for future use, but the `EdenSpacing` tokens themselves are NOT extended in this objective. Profiles' visual differences in v1 = primary color + surface tonal palette + radii multiplier + status palette + optional font family. NOT spacing/density.

## Success criteria (must-haves, observable truths)

1. **All 5 TRDs landed.** Each TRD commits a passing test suite RED→GREEN per global Playbook habit 1.
2. **Backwards-compat gate.** `flutter test` passes with **zero modifications** to existing tests in `test/widgets/` (1041 baseline + new tests). `EdenTheme.light()` and `EdenTheme.dark()` continue to return `ThemeData` identical to today's output (verified by golden-property tests comparing `ColorScheme` fields).
3. **All 5 profiles selectable.** A widget test in `test/widgets/eden_adaptive_theme_test.dart` mounts the same `EdenButton + EdenCard + EdenBadge` triple under each profile and asserts that `Theme.of(context).colorScheme.primary` changes per profile.
4. **Status palette wired.** A widget can read `Theme.of(context).extension<EdenStatusPalette>()!.successFg` and the value differs between `commercialWarm` and `govFederal` profiles (gov uses USWDS green; commercial uses Eden emerald).
5. **Brand preset registry exposes ≥10 presets.** `EdenBrandPresetRegistry.all().length >= 10` and lookup by id returns the correct preset.
6. **Per-profile font resolver returns correct family.** `EdenProfileFonts.bodyFontFor(EdenThemeProfile.medicalInstitutional)` returns a `TextStyle` whose `fontFamily` corresponds to IBM Plex Sans (verified by GoogleFonts API). `EdenThemeProfile.commercialWarm` returns Plus Jakarta Sans.
7. **`EdenAdaptiveTheme` widget exists** and accepts `(profile, brand?, child)` props. Composes 009-01..009-04. Provides `EdenThemeProfileScope` to descendants. Documented inline with usage example for downstream apps.
8. **Catalog screen renders all 5 profiles.** `lib/dev_app/screens/theme_profiles_screen.dart` shows all 5 profiles side-by-side (or stacked on Compact) with sample component triptych (EdenButton + EdenCard + EdenBadge) under each. Runnable via `just dev-ui` → "Theme Profiles" tile in home_screen.
9. **`just check` passes cleanly.** `flutter analyze` 0 issues; `flutter test` full suite passes; lint clean.
10. **Zero new pubspec dependencies added.** Verified via `git diff pubspec.yaml` — only `flutter.assets` may change (none needed for this objective).
11. **Export section in `lib/eden_ui.dart`** contains `// Objective 009 — Vertical Theme System` with 5+ exports across the 5 TRDs.

## Out of scope

- **Density tokens / `EdenSpacing.spaceHalf` / `EdenDensity` enum** — deferred to v2 objective. v1 profile differences are color/radii/font, NOT spacing.
- **New widgets / component variants.** Pure theme work; no `EdenButton.dense` etc.
- **Page-level theme overrides.** Per locked decision C.
- **Visual regression baselines for each profile.** Deferred to `VRT-01` v2 future objective (per ROADMAP.md). The catalog screen serves as visual reference; pixel-diff tooling lives in a future sibling package.
- **USWDS exact-token conformance audit.** 009-01 uses _approximated_ USWDS values for `govFederal` (Public Sans + navy primary + federal red error). Exact conformance with USWDS v3 tokens deferred to Obj 011 (compliance overlay primitives) which depends on this objective.
- **Per-tenant theme persistence / runtime hot-swap UI.** The library exposes the wrapper; consumer apps own the storage + UI for tenant theme selection. `EdenAdaptiveTheme` does support runtime profile changes (rebuild with new `profile:` prop), but persistence is downstream.
- **Dark-mode per-profile tuning.** `EdenAdaptiveTheme.dark(profile, brand)` is provided, but the dark-mode color schemes use the same per-profile primary + EdenColors-derived surfaces. No per-profile dark-mode aesthetic tuning (e.g., medical-dark-mode using specific institutional grays) — deferred.
- **Cross-profile font subset bundling.** GoogleFonts loads fonts on-demand at runtime. Offline-first font bundling is downstream concern.
- **Backend / transport / auth work** (forbidden by PROJECT.md).

## References

- `.planning/PROJECT.md` — library constraints, test pattern, validation commands
- `.planning/VERTICAL_UX_RESEARCH_2026-05-16.md` §2.4 (theme system enhancements detail), §3.1 (Objective 009 recommendation) — primary spec
- `lib/src/tokens/colors.dart` — existing `EdenColors.presets` map (gold/blue/emerald/purple/red/slate/cyan)
- `lib/src/tokens/typography.dart` — existing `EdenTypography` font conventions
- `lib/src/tokens/radii.dart` — existing `EdenRadii.{sm,md,lg,xl,xxl,full}` ramp
- `lib/src/theme/eden_theme.dart` — current `EdenTheme.light/dark` implementation (this TRD extends it; does NOT replace it)
- `~/.claude/CLAUDE.md` — global TDD Playbook (habits 1-6 apply throughout)
- Per locked decision C from `COMPANION_UX_PATTERNS_2026-05-15.md` — vertical-flavor at PAGE level, NOT shell
