# Objective 022 — Context

Captured 2026-08-26. Wave 0a of the AO white-label programme
(`~/dev/whitelabel-state.md`). These are OPERATOR DECISIONS — do not re-open them.

## Verified findings — measured 2026-08-26, do not re-derive

1. **`EdenTheme.light({EdenThemeProfile profile, MaterialColor? brand})`** uses `profile`
   for exactly ONE thing: `_withStatusPalette(base, profile)`. Its `ColorScheme.light(...)`
   is built from hardcoded `EdenColors.neutral[...]` / `Colors.white`, with only `primary`
   derived from `brand`.
2. **`EdenBrandPresetRegistry` is a CLOSED set of 15** presets, each holding a
   `MaterialColor` — so a partner hex that is not one of the 15 has no path in today.
3. **`EdenThemeProfileData` has a `const` constructor but only 5 static instances**
   (`commercialWarmData` etc.). Hex literals are used for `surfaceTonalSeed` precisely
   because `MaterialColor[shade]` is not a const expression.
4. **`EdenAdaptiveTheme.light(profile, brand:)` already composes** `EdenTheme.light` +
   `EdenProfileFonts` and resolves primary as `brand?.color ?? profile.data.primaryColor`.
   This is the right seam to extend — do NOT build a parallel one.
5. **`EdenProfileFonts` already calls `GoogleFonts.getFont(family)`** per profile. Runtime
   font family is an extension of this path, not a new mechanism.
6. **Four declared tokens are INERT** — `surfaceTonalSeed`, `radiusMultiplier`,
   `minimumTouchTargetPx`, `preferBorderOverShadow` are read by NO production code, only
   by tests asserting their declared values. See "Out of scope".

## Decisions — LOCKED

1. **Back-compat is the acceptance spine.** `EdenTheme.light()`/`.dark()` with no brand
   argument, and all five profiles, must produce byte-identical `ThemeData` to today.
   Objective 009's back-compat tests stay green and UNMODIFIED. Prove it, don't assert it.
2. **Extend `EdenAdaptiveTheme`, do not fork it.** One theming entry point. A second
   "runtime" path that diverges from the static one is the failure mode to avoid.
3. **The 15 presets stay.** The swatch generator is an ESCAPE HATCH for a partner colour
   outside the set, not a replacement for the registry. `EdenBrandPreset` keeps its
   `MaterialColor` field.
4. **No new font delivery.** Reuse `GoogleFonts.getFont`. Do not add asset bundling, do
   not add a webfont loader. If a requested family is unavailable, fall back to the
   profile default rather than throwing — a bad font name must not crash an app's boot.
5. **Downstream shape.** The consumer is a Flutter web app reading `window.APP_CONFIG`
   injected by its container entrypoint at start. Values arrive as plain strings
   (`"#0F62FE"`, `"Inter"`) already parsed from JSON. Design the API for that, not for a
   Dart-literal caller.

## In scope — three capabilities

1. `MaterialColor` from one arbitrary hex string. Must produce a full, sane shade ramp
   (50..900) and handle malformed input without throwing.
2. `EdenThemeProfileData` constructible at runtime from plain values.
3. Font family from a runtime string, through the existing `EdenProfileFonts` path.

## Out of scope — this is Objective 0b, do NOT start it

Making `surfaceTonalSeed` / `radiusMultiplier` / `minimumTouchTargetPx` /
`preferBorderOverShadow` actually reach widgets. **165 of 314** files in
`lib/src/widgets/` reference `EdenRadii.*` as static constants; **184** files in
`lib/src` reference `EdenColors` directly. A `radiusMultiplier` of 0.333 changes nothing
today and cannot until those call sites read from context. That needs a ThemeExtension,
a call-site migration, and a design spike — a separate objective. Adding a token here
that still reaches nothing would be worse than leaving it declared, because it would look
finished.

## Discretion

- Swatch-generation algorithm (HSL lightness ramp vs Material's own tonal palette vs
  something else). Pick one and justify it against a real partner hex; the only hard
  requirement is that shade 500 equals the supplied colour and the ramp stays legible for
  both light and dark surfaces.
- Whether runtime profile construction is a factory on `EdenThemeProfileData`, a builder,
  or a `copyWith` from an existing profile. Favour whatever keeps the byte-identity proof
  simple.
- Where malformed-input fallbacks log (or whether they log at all) in a UI library.

## Constraints

- Repo `/Users/justin/dev/eden-ui-flutter` (a SYMLINK into `/Users/justin/dev/eden-libs/`),
  branch `df/022-runtime-brand-tokens`, cut from clean `main`.
- **Consumers pin this library by git SHA** (eden-biz, eden-platform-flutter), so a merge
  does not move them — but `eden-biz-mobile` uses `path: ../eden-libs/eden-ui-flutter`,
  the SAME working copy, and picks up local changes immediately. Do not leave the tree
  broken between commits.
- **HARD RULE: never port 8080** for any local verification. Use 8091.
