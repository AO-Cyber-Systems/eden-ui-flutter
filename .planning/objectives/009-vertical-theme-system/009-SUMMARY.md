---
objective: 009-vertical-theme-system
type: full-objective
trd_count: 5
subsystem: theme
tags: [vertical-theme, theme-extension, brand-preset, profile-fonts, adaptive-theme, dev-catalog]
dependency-graph:
  requires:
    - eden_theme.dart (existing)
    - eden_colors.dart (existing)
    - google_fonts ^6.1.0 (existing)
  provides:
    - EdenThemeProfile enum (5 LOCKED values)
    - EdenThemeProfileData @immutable value class
    - EdenThemeProfileScope InheritedWidget
    - EdenStatusPalette ThemeExtension
    - EdenBrandPreset value class + EdenBrandPresetRegistry (15 presets)
    - EdenProfileFonts static resolver
    - EdenAdaptiveTheme StatelessWidget + .light/.dark static factories
    - ThemeProfilesScreen dev catalog
  affects:
    - EdenTheme.light/dark (additive: optional profile param)
    - lib/eden_ui.dart (Obj 009 export section)
    - lib/dev_app/screens/home_screen.dart (nav tile)
tech-stack:
  added: []
  patterns: [ThemeExtension, InheritedWidget, immutable-value-class, static-factory, composition-wrapper]
key-files:
  created:
    - lib/src/theme/eden_theme_profile.dart
    - lib/src/theme/eden_theme_profile_scope.dart
    - lib/src/theme/eden_status_palette.dart
    - lib/src/theme/eden_brand_preset.dart
    - lib/src/theme/eden_profile_fonts.dart
    - lib/src/theme/eden_adaptive_theme.dart
    - lib/dev_app/screens/theme_profiles_screen.dart
    - test/theme/_fixtures/profile_fixtures.dart
    - test/theme/_fixtures/brand_preset_fixtures.dart
    - test/theme/eden_theme_profile_test.dart
    - test/theme/eden_theme_profile_scope_test.dart
    - test/theme/eden_status_palette_test.dart
    - test/theme/eden_theme_status_palette_attach_test.dart
    - test/theme/eden_brand_preset_test.dart
    - test/theme/eden_profile_fonts_test.dart
    - test/theme/eden_adaptive_theme_test.dart
    - test/dev_app/theme_profiles_screen_test.dart
  modified:
    - lib/src/theme/eden_theme.dart  # additive: optional profile param + EdenStatusPalette attach
    - lib/eden_ui.dart  # Obj 009 section with 6 exports
    - lib/dev_app/screens/home_screen.dart  # nav tile + import
decisions:
  - "Profile enum LOCKED at 5 values: commercialWarm (default), medicalInstitutional, govFederal, retailVibrant, legalProfessional"
  - "EdenColors MaterialColors reused across presets per aesthetic-preservation principle 1 — no new hex tokens in v1"
  - "Hex literals (not MaterialColor[X] lookups) for surfaceTonalSeed because MaterialColor[X] is not const-eligible"
  - "TextTheme overlay short-circuits when both body+display family null — zero allocation for commercialWarm/retailVibrant back-compat"
  - "EdenAdaptiveTheme primary-color resolution: explicit brand → profile.data.primaryColor → EdenTheme default. Makes adaptive distinct (govFederal yields navy without explicit brand) while preserving commercialWarm parity (gold == gold)."
  - "GoogleFonts test env populates fontFamily as PascalCase+_regular suffix ('PlusJakartaSans_regular') — adopted hasFontFamilyPrefix matcher"
  - "Map-based merge helper for ThemeExtension iterable avoids Dart inference quirk with typed-set spreads of generic-of-generic"
metrics:
  duration_minutes: ~60
  completed_date: 2026-05-17
  tests_added: 122  # across 5 TRDs
  total_tests_after: 2066
  commits: 16  # 5 RED + 5 GREEN + 5 contract-lock/refactor + 1 catalog
---

# Objective 009 — Vertical Theme System Summary

Profile-aware theme architecture for Eden UI Flutter: 5 LOCKED vertical aesthetic profiles (commercial / medical / gov / retail / legal) composed via `EdenAdaptiveTheme.{light,dark}(profile, brand?)` with profile-aware `ThemeExtension` for semantic status colors, profile-aware `TextTheme` overlay using `EdenProfileFonts`, and a 15-preset `EdenBrandPresetRegistry` for tenant brand selection. Every existing widget continues to render under default `EdenTheme.light()` exactly as before (back-compat anchor verified per-field).

## Waves shipped

| Wave | TRDs | Outcome |
|---|---|---|
| 1 — Foundation | 009-01, 009-02 | EdenThemeProfile enum + InheritedWidget scope + EdenStatusPalette ThemeExtension wired into EdenTheme.{light,dark} |
| 2 — Brand + Font | 009-03, 009-04 | 15-preset EdenBrandPresetRegistry + EdenProfileFonts resolver delegating to profile.data |
| 3 — Composition + catalog | 009-05 | EdenAdaptiveTheme widget + static factories + ThemeProfilesScreen visual catalog mounted under home_screen |

## Deviations from plan

### Auto-fixed inline

**1. [Rule 3 - Build] Dart inference quirk on ThemeExtension iterable spread (TRD 009-02 Task 3)**
- **Found during:** EdenTheme.{light,dark} extension attach
- **Issue:** `<ThemeExtension<dynamic>>[ ...base.extensions.values, EdenStatusPalette.forProfile(profile) ]` rejected by Dart with "Can't assign spread elements of type 'ThemeExtension<dynamic>' to collection elements of type 'ThemeExtension<ThemeExtension<dynamic>>'". Set literal variant produced the same error. The Dart inference engine fights spread context types when the element type is itself generic-of-dynamic.
- **Fix:** Extracted `_withStatusPalette(base, profile)` helper that builds via `Map<Object, ThemeExtension<dynamic>>.from(base.extensions)` and returns `.values` — a properly-typed `Iterable<ThemeExtension<dynamic>>` that binds cleanly to `ThemeData.copyWith(extensions:)`. Helper documented inline.
- **Files modified:** `lib/src/theme/eden_theme.dart`
- **Commit:** `e14ae28`

**2. [Rule 3 - Build] GoogleFonts TextStyle requires TestWidgetsFlutterBinding (TRDs 009-02 Task 3, 009-04 Task 1, 009-05 Task 1)**
- **Found during:** First ThemeData construction in a plain `test()` block
- **Issue:** `EdenTheme.{light,dark}` call GoogleFonts inside `_buildTheme` to build a TextTheme. GoogleFonts requires the TestWidgetsFlutterBinding to be initialized (asset loader / font cache) AND `allowRuntimeFetching = false` (no network in test env). Plain `test()` block doesn't initialize the binding.
- **Fix:** Converted all ThemeData-constructing tests to `testWidgets((tester) async { ... })` per existing `support_panel_test.dart` pattern. testWidgets initializes the binding + provides mocked font assets automatically.
- **Files modified:** `test/theme/eden_theme_status_palette_attach_test.dart`, `test/theme/eden_profile_fonts_test.dart`, `test/theme/eden_adaptive_theme_test.dart`
- **Commits:** included in `e14ae28`, `fe38c31`, `bb2d77b`

**3. [Rule 1 - Bug] GoogleFonts test-env fontFamily shape mismatch (TRDs 009-04, 009-05)**
- **Found during:** First GoogleFonts-backed TextStyle assertion
- **Issue:** TRDs assumed `TextStyle.fontFamily` equals the canonical Google Fonts family name (`'Plus Jakarta Sans'`). Actual test-env shape: `'PlusJakartaSans_regular'` (PascalCase, no spaces, weight suffix). Tests were asserting on the canonical form and failing.
- **Fix:** Introduced reusable `hasFontFamilyPrefix(canonicalFamily)` matcher that strips spaces and asserts `startsWith(pascalCase)`. Preserves contract intent (correct family per profile) while matching test-env shape. Documented inline in the test files.
- **Files modified:** `test/theme/eden_profile_fonts_test.dart`, `test/theme/eden_adaptive_theme_test.dart`
- **Commits:** `2e277b8`, `bb2d77b`

**4. [Rule 2 - Missing functionality] EdenAdaptiveTheme primary-color resolution (TRD 009-05 Task 2)**
- **Found during:** `EdenAdaptiveTheme.light(govFederal).colorScheme.primary` assertion (expected blue, got gold)
- **Issue:** Initial impl passed `brand?.color` to `EdenTheme.light`. `EdenTheme.light` falls back to `brandColor` (static = gold) when brand is null. Result: ALL profiles produced gold primary unless caller explicitly passed a brand — defeating the whole "profile shapes the theme" promise (govFederal MUST yield navy; medical MUST yield cyan).
- **Fix:** New resolution order: `brand?.color ?? profile.data.primaryColor`. Profile's canonical `primaryColor` (from `EdenThemeProfileData`) is the default when no brand override. Back-compat preserved because `commercialWarmData.primaryColor == EdenColors.gold == EdenTheme.brandColor` — no drift for default profile.
- **Files modified:** `lib/src/theme/eden_adaptive_theme.dart`
- **Commit:** `e7503e1`

### Pre-existing failures (not caused by 009)

A transient `EdenCard.interactive` not-found compile failure was observed during one full-suite run mid-execution. Investigated and logged in `deferred-items.md` — verified pre-existing via `git stash`. On the next full-suite run after Task 3 lands, the file compiles and all 12 tests pass GREEN. Diagnosed as a Dart analyzer / build cache state anomaly, not a real defect.

## Task Evidence

| TRD | Task | Verify Command | Exit | Status |
|---|---|---|---|---|
| 009-01 | 1 (RED) | `flutter test test/theme/` | 1 | FAIL (correct) |
| 009-01 | 2 (GREEN) | `flutter test test/theme/eden_theme_profile_test.dart test/theme/eden_theme_profile_scope_test.dart` | 0 | PASS |
| 009-01 | 3 (CONTRACT) | `flutter test test/theme/eden_theme_profile_test.dart` | 0 | PASS (24/24) |
| 009-02 | 1 (RED) | `flutter test test/theme/eden_status_palette_test.dart` | 1 | FAIL (correct) |
| 009-02 | 2 (GREEN) | `flutter test test/theme/eden_status_palette_test.dart` | 0 | PASS (19/19) |
| 009-02 | 3 (WIRING) | `flutter test test/theme/eden_theme_status_palette_attach_test.dart` | 0 | PASS (8/8) |
| 009-03 | 1 (RED) | `flutter test test/theme/eden_brand_preset_test.dart` | 1 | FAIL (correct) |
| 009-03 | 2 (GREEN) | `flutter test test/theme/eden_brand_preset_test.dart` | 0 | PASS (31/31) |
| 009-04 | 1 (RED) | `flutter test test/theme/eden_profile_fonts_test.dart` | 1 | FAIL (correct) |
| 009-04 | 2 (GREEN) | `flutter test test/theme/eden_profile_fonts_test.dart` | 0 | PASS (22/22) |
| 009-05 | 1 (RED) | `flutter test test/theme/eden_adaptive_theme_test.dart` | 1 | FAIL (correct) |
| 009-05 | 2 (GREEN) | `flutter test test/theme/eden_adaptive_theme_test.dart` | 0 | PASS (18/18) |
| 009-05 | 3 (CATALOG) | `flutter test test/dev_app/theme_profiles_screen_test.dart` | 0 | PASS (4/4) |

## TDD Evidence (RED → GREEN → REFACTOR cadence per TRD)

| TRD | RED commit | GREEN commit | Optional refactor / contract-lock | Cadence |
|---|---|---|---|---|
| 009-01 | `2bffcff` | `f380766` | `2557973` (back-compat anchor + per-profile data assertions) | test → feat → test |
| 009-02 | `69fd862` | `7faee68` | `e14ae28` (EdenTheme wiring — second feat as separate task) | test → feat → feat |
| 009-03 | `29a1cbe` | `bd43bc4` | — | test → feat |
| 009-04 | `fe38c31` | `2e277b8` | — | test → feat |
| 009-05 | `bb2d77b` | `e7503e1` | `13ab938` (catalog screen + home nav tile — final feat) | test → feat → feat |

Every RED commit was a strict failure (production type undefined / compile error) before the GREEN commit. Iron Law honored across all 5 TRDs.

## Validation Gate Results

| Gate | Command | Exit | Status |
|---|---|---|---|
| Theme dir tests | `flutter test test/theme/` | 0 | PASS (122/122) |
| Catalog screen | `flutter test test/dev_app/theme_profiles_screen_test.dart` | 0 | PASS (4/4) |
| Full library suite | `flutter test` | 0 | PASS (2066/2066) |
| Production analyze | `flutter analyze lib/src/theme/ lib/dev_app/screens/theme_profiles_screen.dart` | 0 | PASS (0 issues) |
| Obj 009 exports | `grep "Objective 009" lib/eden_ui.dart` | 0 | 1 section header + 6 exports |

## Post-TRD Verification

- Auto-fix cycles used: 4 (3× Rule 3 build/wiring, 1× Rule 2 missing functionality)
- Must-haves verified: All TRDs' must-have lists are GREEN per the test evidence above
- Gate failures: None
- Pre-existing failures touched: None (all 14 originally-suspected failures in `eden_card_interactive_test.dart` were transient cache state; verified GREEN on final full-suite run)

## Public API surface (consumer-facing additions)

```dart
// Enum + data
enum EdenThemeProfile { commercialWarm, medicalInstitutional, govFederal, retailVibrant, legalProfessional }
class EdenThemeProfileData { /* @immutable, const-able, profile.data getter */ }
enum EdenThemeProfileDensity { comfortable, dense }

// Inherited scope
class EdenThemeProfileScope extends InheritedWidget { /* .of(context) + .maybeOf(context) */ }

// Status palette ThemeExtension
class EdenStatusPalette extends ThemeExtension<EdenStatusPalette> {
  factory EdenStatusPalette.commercial();
  factory EdenStatusPalette.forProfile(EdenThemeProfile);
  // 15 Color fields: {success,warning,danger,info,neutral} × {Bg,Fg,Border}
}

// Brand presets
class EdenBrandPreset { /* id + displayName + MaterialColor + recommendedFor */ }
class EdenBrandPresetRegistry {
  static List<EdenBrandPreset> all();           // 15 presets (unmodifiable)
  static EdenBrandPreset? byId(String id);
  static List<EdenBrandPreset> forVertical(String vertical);  // case-insensitive
}

// Font resolver
class EdenProfileFonts {
  static String? bodyFontFamily(EdenThemeProfile);
  static String? displayFontFamily(EdenThemeProfile);
  static String? monoFontFamily(EdenThemeProfile);
  static TextStyle bodyTextStyle(EdenThemeProfile, {fontSize, fontWeight, height, color});
  static TextStyle displayTextStyle(EdenThemeProfile, {...});
  static TextStyle monoTextStyle(EdenThemeProfile, {...});
}

// Composition (Pattern A — MaterialApp.theme)
ThemeData EdenAdaptiveTheme.light(EdenThemeProfile, {EdenBrandPreset? brand});
ThemeData EdenAdaptiveTheme.dark(EdenThemeProfile, {EdenBrandPreset? brand});

// Composition (Pattern B — in-tree subtree theming)
class EdenAdaptiveTheme extends StatelessWidget {
  EdenAdaptiveTheme({required profile, brand, required child});
}

// EdenTheme.{light,dark} extended additively (back-compat)
ThemeData EdenTheme.light({EdenThemeProfile profile = commercialWarm, MaterialColor? brand});
ThemeData EdenTheme.dark({EdenThemeProfile profile = commercialWarm, MaterialColor? brand});
```

## Back-compat invariants (all verified by test)

- `EdenTheme.light()` no-args → identical output to before objective 009 (TRD 009-02 attach test passes)
- `EdenAdaptiveTheme.light(commercialWarm)` no-brand → primary, body+display fontFamily, status palette successFg all equal `EdenTheme.light()` (TRD 009-05 anchor test passes)
- `EdenColors.{success,warning,error,info,successBg,warningBg,errorBg,infoBg}` static constants UNCHANGED in identity (TRD 009-02 item 25)
- `commercialWarmData` profile data values frozen (TRD 009-01 items 10-16)
- All 1748 widget tests pre-existing this objective continue to pass GREEN

## Self-Check: PASSED

Files verified present:
- lib/src/theme/eden_theme_profile.dart (FOUND)
- lib/src/theme/eden_theme_profile_scope.dart (FOUND)
- lib/src/theme/eden_status_palette.dart (FOUND)
- lib/src/theme/eden_brand_preset.dart (FOUND)
- lib/src/theme/eden_profile_fonts.dart (FOUND)
- lib/src/theme/eden_adaptive_theme.dart (FOUND)
- lib/dev_app/screens/theme_profiles_screen.dart (FOUND)
- 8 test files under test/theme/ + test/dev_app/ (FOUND)

All 16 commits present in git log (verified via `git log fe92eb1..HEAD --oneline | grep 009-`).
