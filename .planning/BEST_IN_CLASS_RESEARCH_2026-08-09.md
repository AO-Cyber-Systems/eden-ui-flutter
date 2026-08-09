# Best-in-Class Research — Making Eden UI the Best Flutter UI Framework

Date: 2026-08-09
Status: Research + proposed objectives (nothing here is committed scope until promoted into `ROADMAP.md`)

## 1. Purpose and method

Directive: "make our Flutter frameworks the best in the business," with gskinnerTeam
(https://github.com/gskinnerTeam) as a named reference point.

Method:

1. Full inventory of `eden-ui-flutter` (786 `Eden*` widgets, 508 lib files, 453 test
   files) and `eden-platform-flutter` (auth/nav/networking/observability shell).
2. Study of gskinner's public Flutter portfolio (org repos, pub.dev publisher page,
   engineering blog, Wonderous app).
3. Competitive scan of the current Flutter UI-framework landscape (Forui, shadcn_ui
   port, GetWidget, TDesign, Widgetbook, Material 3 Expressive token direction).
4. Gap analysis mapping 1 against 2–3, then proposed objectives sized to our existing
   objective/TRD process.

## 2. Where we already lead

Worth stating before the gaps, because the strategy below protects these:

- **Breadth no competitor has.** Forui ships ~40 general-purpose widgets; we ship
  ~786 including vertical packs (medical/FHIR, gov/USWDS + classification banners,
  retail/POS, salon, fuel, trades) and three visual graph editors (process canvas,
  workflow canvas, template builder). Nobody else has an `EdenSchedulerSwimlaneView`
  or a Mermaid parser in their design system.
- **Vertical theme profiles.** 5 locked profiles × 15 brand presets with a
  byte-for-byte back-compat anchor is a real multi-tenant theming architecture, not
  a demo.
- **Discipline artifacts.** The comment culture (decisions recorded with rejected
  alternatives and measured numbers), TDD commit pairs, back-compat anchor tests,
  and eden-platform's security-gate-shaped test suite are ahead of any public
  Flutter framework, including gskinner's.
- **Layering.** eden-ui is verifiably transport-agnostic and state-management-free;
  the riverpod bridge lives on the platform side. This is the correct dependency
  direction, and it is enforced, not aspirational.

## 3. What gskinner does that we should absorb

gskinner is not a component-library shop — their moat is **motion, polish,
accessibility retrofitted as craft, and developer ergonomics**. The relevant assets:

| Asset | What it is | What we take |
|---|---|---|
| `flutter_animate` (4.5k likes, Flutter Favorite) | Unified declarative effect API: `.animate().fade().slide()` chains, no `AnimationController` boilerplate | The **API ergonomics pattern**: our motion tokens (`EdenDurations`, `EdenSprings`) are good primitives with no ergonomic entry point. Proposal: `EdenMotion` extension API (obj-023) so product teams stop hand-rolling 68 `AnimationController`s |
| Wonderous app (4.5k stars) | Showcase app that doubles as marketing + education | The **flagship showcase** pattern: our dev catalog is internal-only; a hosted, beautiful catalog is how frameworks win mindshare (obj-026) |
| Screen-reader blog series ("Top 10 accessibility lessons") | Retrofit a11y on a motion-heavy app | Their checklist maps directly onto our gaps: `disableAnimations` respect, semantic ordering, live regions. Feeds obj-024 |
| Rendering-optimization blog series | Avoid opacity layers, repaint boundaries, etc. | Perf budget discipline → obj-028 benchmark harness |
| `focusable_control_builder` | One builder that wires focus + hover + pressed + keyboard for custom controls | Pattern for closing our focus gap: most of our 700+ widgets do no explicit focus management. A single `EdenControlBuilder` primitive, applied progressively, beats 700 bespoke fixes (obj-024) |
| `flextras`, `gap`-style layout sugar | Padded/separated Columns and Rows | Cheap ergonomic wins: `EdenColumn(separator:)`, `EdenGap` on our spacing tokens (obj-023) |
| `defer_pointer` | Hit-test children outside parent bounds | Adopt technique in canvases (our node editors clip hit-tests today) |
| `context_menus`, `statsfl` | Right-click menus; FPS overlay | We have context menus in canvases only; promote to a general `EdenContextMenu`. `statsfl`-style overlay belongs in the dev catalog toolbar |
| `universal_platform` | Web-safe platform checks | We already handle this via conditional imports; no action |

Key strategic read: gskinner wins on **quality-per-widget and public credibility**;
we win on **breadth and enterprise theming**. The plan is to keep our breadth and
close the quality-per-widget gap, because the reverse (them growing to our breadth)
is a decade of vertical domain work.

## 4. Competitive landscape (2026)

- **Forui** (forui.dev) — shadcn-inspired, ~40 minimalist widgets, its own token
  system decoupled from Material, first-class docs site with live examples, and a
  CLI that scaffolds themes/snippets. Its docs + CLI are the bar for DX, not its
  widget count.
- **shadcn_ui Flutter port** — same story: small, beautiful, docs-driven adoption.
- **GetWidget / TDesign** — breadth plays (~1000 widgets combined) with weak
  cohesion; proof that breadth without token discipline and docs reads as a junk
  drawer. A cautionary tale for our vertical packs if we don't split/curate.
- **Widgetbook** — the de-facto commercial catalog tool (knobs, addons, device
  frames, **Widgetbook Cloud visual regression review**). Our home-grown explorer
  already matches its core (stories, knobs, viewport/profile/brand/brightness
  toolbar, deep links, manifest emission for eden-docs). Verdict: keep ours, add
  the two things theirs has that matters — golden capture per story and a hosted
  build (obj-022, obj-026).
- **Material 3 Expressive** (I/O 2026) — Google is adding shape/motion/spacing
  system tokens, watch/XR form factors, and Figma→code token export. Our
  `EdenLoadingIndicator` already tracks M3E. Direction to track: token-file
  interchange (design-token JSON) so brand presets can be designer-authored
  (obj-027).

## 5. Gap analysis — what separates us from "best in the business"

Ordered by (user-visible impact × effort-to-close). Items 1–4 are the credibility
gaps: any external reviewer auditing "best Flutter framework" claims checks these
first.

1. **Visual regression (VRT-01, already tracked).** 1 golden image for 786 widgets
   × 5 profiles × 15 brands × 2 brightnesses × 5 breakpoints. The deferral reason
   ("identity not stable") has expired — the visual audit of 2026-05-18 fixed the
   catalog defect table; the identity is now stable enough that goldens are signal,
   not noise. The story registry is the missing piece's enabler: 45 stories ×
   profile/brightness matrix ≈ deterministic golden set with zero per-widget work.
2. **Accessibility as an enforced gate, not a retrofit.** 234 `Semantics` sites but
   zero `meetsGuideline` assertions; `govFederal` promises a 48pt touch floor with
   no enforcement path; no `textScaler`/`boldText`/`highContrast`/reduce-motion
   handling anywhere. We literally ship `EdenSection508Audit` as a product widget
   without passing our own audit. For gov/medical verticals this is a sales risk,
   not just polish.
3. **Reduce-motion + motion ergonomics.** 68 raw `AnimationController`s, zero
   `MediaQuery.disableAnimations` reads. One shared motion entry point fixes both.
4. **Internationalization.** ~369 hardcoded English strings, no ARB pipeline, RTL
   untested (14 `Directionality` refs). We ship `EdenLanguageSelector` — the
   selector works; nothing it selects is localized. Medical + gov verticals will
   force this eventually; doing it late is 10× the cost.
5. **Published documentation + hosted catalog.** README is 22 lines; the excellent
   docs live in dartdoc comments and `.planning/` where no adopter sees them.
   The `flutter-stories.json` emitter proves the portal intent — finish the loop.
6. **Density system.** `EdenThemeProfileDensity` declared, not wired. Compact/dense
   is table-stakes for POS and back-office (our own verticals).
7. **Theming completeness.** One `ThemeExtension` (status palette); spacing, radii,
   shadows, motion are static classes → not overridable per subtree, which is why
   `radiusMultiplier` / `minimumTouchTargetPx` sit in profile data half-enforced.
8. **Package architecture.** 786 widgets in one package makes versioning, review,
   and visual coherence expensive, and forces every consumer to compile FHIR
   widgets to get a button. (GetWidget shows where this road ends.)
9. **Cross-platform CI (XPL-01, tracked)** + empty `integration_test/`/`.maestro/`.
10. **Performance budgets.** "Build cost should not regress" with no harness.
11. **API consistency tooling.** No public-API diff gate, no lint enforcing
    dartdoc-on-public or tokens-over-raw-values.
12. **CHANGELOG/migration guides** with 18–24 downstream consumers.

## 6. Proposed objectives (022–030)

Numbered to continue `ROADMAP.md`; each is sized for the existing objective/TRD
process. Waves are dependency-ordered.

### Wave 1 — Credibility gates (the "audit-proof" wave)

- **obj-022 — Story-driven golden matrix (executes VRT-01).**
  Drive goldens from `StoryRegistry` rather than per-widget test files: for each of
  the 45 stories, capture `{commercialWarm, govFederal, medicalInstitutional} ×
  {light, dark} × {390, 768, 1280}` goldens via a single parameterized harness.
  Add `golden_toolkit`-style CI diffing with an explicit update ritual. Grow story
  count as the coverage lever (each new story buys 18 goldens for free). Acceptance:
  golden CI job red on unreviewed pixel drift; story count ≥ 120.
- **obj-023 — Eden Motion API + reduce-motion.**
  (a) `EdenMotion` — a `flutter_animate`-inspired extension API over `EdenDurations`
  + `EdenSprings` (`widget.edenFadeIn()`, `edenSpring(EdenSprings.snap)`), so new
  code stops hand-rolling controllers. (b) A `MotionScope` that resolves
  `MediaQuery.disableAnimations` once and gates every Eden animation widget
  (`EdenBouncingDots`, `EdenPulsingWrapper`, `EdenSkeletonScope`, `EdenFabMenu`,
  carousel autoplay). (c) Layout sugar: `EdenGap`/`EdenColumn(separator:)` on
  spacing tokens. Acceptance: zero direct `AnimationController` in *new* widget
  code (lint), all shipped animation widgets no-op under `disableAnimations`.
- **obj-024 — Accessibility enforcement.**
  (a) Shared `EdenControlBuilder` (focus + hover + pressed + keyboard, modeled on
  gskinner's `focusable_control_builder`) and migrate the 20 highest-traffic
  interactive widgets to it. (b) Add `meetsGuideline(textContrastGuideline)`,
  `androidTapTargetGuideline`, `labeledTapTargetGuideline` assertions to the story
  harness from obj-022 — a11y coverage scales with the same story lever.
  (c) Enforce `minimumTouchTargetPx` from the active profile inside `EdenButton`/
  chips/icon buttons. (d) `textScaler` 1.3× sweep as a story-harness axis; fix
  overflows. Acceptance: story harness runs 4 guideline assertions across all
  stories; govFederal 48pt floor enforced in code, with tests.

### Wave 2 — Adoption surface (the "win mindshare" wave)

- **obj-025 — Theming v2: tokens as ThemeExtensions + density wiring.**
  Promote spacing/radii/shadows/motion to `ThemeExtension`s (static classes stay as
  const sources feeding them — no breaking change; `EdenStatusPalette` is the
  template). Wire `EdenThemeProfileDensity` to the spacing extension
  (comfortable/compact/dense). Retire the `EdenTheme.brandColor` mutable static
  (deprecate → `EdenAdaptiveTheme` everywhere). Kill the remaining hardcoded
  status-color branches (`eden_status_dot_overlay.dart:60` TODO). Acceptance:
  subtree theme override demo story; POS register story renders in `dense`.
- **obj-026 — Public catalog + docs site.**
  Deploy the existing dev catalog as a hosted web build behind eden-docs (the
  hash-routing decision already anticipates this), add a docs layer per component:
  usage snippet, do/don't, a11y notes, API link — sourced from dartdoc so it can't
  drift. Wonderous-style landing page with the 5 vertical profiles as the hook
  (nobody else can show one codebase re-skinning from federal to salon live).
  Acceptance: public URL, every barrel-exported widget reachable via search
  (manifest emitter already provides the index).
- **obj-027 — Design-token interchange.**
  Emit/ingest W3C design-token JSON for the token layer so brand presets can be
  designer-authored (Figma → tokens file → `EdenBrandPreset`), aligning with the
  Material 3 Expressive token-export direction. Keep the 15-preset registry closed;
  interchange feeds it via PR, preserving the "Do NOT regenerate via LLM" review
  gate. Acceptance: round-trip test tokens.css ↔ JSON ↔ Dart consts.

### Wave 3 — Scale and trust (the "enterprise-grade" wave)

- **obj-028 — Performance harness + budgets.**
  Benchmark suite (frame-build cost for the heavy six: data grid, scheduler, three
  canvases, charts) with CI-tracked numbers and gskinner's rendering-optimization
  checklist applied (repaint boundaries around canvas nodes, no opacity layers in
  lists). `statsfl`-style FPS overlay toggle in the catalog toolbar. Acceptance:
  budget file in repo, CI warns on >10% regression.
- **obj-029 — Package split: eden_ui core + vertical packs.**
  Melos-style workspace: `eden_ui` (tokens, theme, ~80 core widgets, layout,
  motion), `eden_ui_charts`, `eden_ui_canvas` (diagram/process/workflow/template),
  `eden_ui_scheduler`, and one package per vertical (`eden_ui_medical`,
  `eden_ui_gov`, `eden_ui_retail`, `eden_ui_salon`, `eden_ui_fuel`,
  `eden_ui_trades`, `eden_ui_commerce`). The current barrel becomes a
  meta-package re-exporting everything, so all 18–24 consumers keep compiling
  unchanged. Do this *after* obj-022 goldens exist (the split is a pure refactor
  proven by unchanged goldens). Also unlocks: per-pack versioning, MAP-GOOGLE-01 /
  MAP-MAPLIBRE-01 siblings fit the same pattern, and an eventual public pub.dev
  release of core without exposing vertical IP.
- **obj-030 — API governance + i18n foundation.**
  (a) Public-API diff gate (`dart_apitool`) in CI + CHANGELOG discipline + custom
  lints: dartdoc-on-public, tokens-over-raw-values, no-new-AnimationController.
  (b) i18n: extract the ~369 widget strings into an `EdenLocalizations` ARB
  pipeline (en + es + fr seed), `textDirection` audit + RTL story-harness axis.
  Vertical packs own their domain strings post-split. Acceptance: API diff job
  blocking; core widgets string-literal-free (lint-enforced); RTL goldens for the
  20 layout-critical widgets.

Platform-side (tracked in eden-platform-flutter, not here): finish riverpod Stage D
consumer migrations; replace the sidebar's hardcoded 45-entry icon map with a
registry + server-supplied fallback glyph; SHA-pin discipline already noted in its
pubspec comments.

## 7. Sequencing rationale

- obj-022 first because it converts the story registry (already built, 45 stories)
  into the enforcement substrate that obj-023/024's acceptance criteria and
  obj-029's refactor-safety all reuse. Highest leverage per LOC in the plan.
- obj-029 (split) deliberately *after* goldens and theming v2: refactors of this
  size without pixel-level proof are how visual coherence dies.
- The waves alternate internal rigor (1) → external adoption (2) → scale (3), so
  each wave produces something visible: Wave 1 ends with audit-proof claims, Wave 2
  ends with a public catalog, Wave 3 ends with a publishable core.

## 8. Sources

- gskinnerTeam org: https://github.com/orgs/gskinnerTeam/repositories
- gskinner pub.dev publisher: https://pub.dev/publishers/gskinner.com/packages
- flutter_animate: https://github.com/gskinner/flutter_animate
- gskinner blog — screen readers: https://blog.gskinner.com/archives/2022/09/flutter-crafting-a-great-experience-for-screen-readers.html
- gskinner blog — rendering optimization: https://blog.gskinner.com/archives/2022/09/flutter-rendering-optimization-tips.html
- gskinner blog — favorite pub.dev libraries: https://blog.gskinner.com/archives/2022/01/flutter-our-favorite-pub-dev-libraries.html
- Wonderous app: https://github.com/gskinnerTeam/flutter-wonderous-app
- Forui: https://forui.dev/
- awesome-flutter: https://github.com/Solido/awesome-flutter
- Flutter Gems — widget libraries: https://fluttergems.dev/widget-library-ui-framework/
- Material 3 in Flutter: https://docs.flutter.dev/ui/design/material
- M3 token update (Flutter breaking change): https://docs.flutter.dev/release/breaking-changes/material-design-3-token-update
