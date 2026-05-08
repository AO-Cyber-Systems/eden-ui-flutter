---
kind: ui-lib
default_work: feature
org: AO-Cyber-Systems
github_repo: AO-Cyber-Systems/eden-libs
---

# eden-ui-flutter

## What This Is

Reusable Flutter UI widget library for Eden apps. Owns the design tokens (spacing, colors, radii, typography), the visual widget catalog (EdenAlert, EdenButton, EdenCard, EdenDataTable, EdenPageHeader, etc.), and the visual dev catalog. **Transport-agnostic** — no business logic, no auth, no network. Consumed via `path:` dep from `eden-biz-flutter` and other downstream Eden Flutter apps.

Lives inside the `eden-libs` monorepo at `eden-libs/eden-ui-flutter/`. Sibling packages: `eden-platform-go` (proto + Go server), `eden-platform-api-dart` (generated Dart codegen), `eden-platform-flutter` (auth shell + nav, transport-agnostic UI consumer of THIS lib).

## Core Value

**Predictable, accessible widget primitives that downstream apps can compose without inheriting platform/transport concerns.** Visual consistency across the Eden product line (biz, investor portal, customer portal, dataroom, etc.) traces back here. If a widget regression ships from this lib, every downstream app inherits it.

## Requirements

### Validated

- ✓ ~30 widget components shipped — EdenAlert, EdenAvatar, EdenBadge, EdenBanner, EdenButton, EdenCard, EdenCheckbox, EdenDataTable, EdenDatePicker, EdenPageHeader, etc.
- ✓ Design token system — `EdenSpacing`, `EdenRadii`, theme tokens
- ✓ Test coverage pattern — `test/widgets/eden_*_test.dart` files using a shared `wrap()` helper that mounts widgets in `MaterialApp(home: Scaffold(body: child))`
- ✓ Visual dev catalog — runnable via `just dev-ui` from the eden-libs workspace root

### Active

<!-- See ROADMAP.md for the live objective list. -->

- [ ] **EPH-01** — `EdenPageHeader` Row layout no longer overflows on iPhone-narrow viewports (≥390pt logical width). See Objective 1 in ROADMAP.md.

### Out of Scope

- **Business logic** — orchestration, auth, persistence belong in `eden-platform-flutter` or downstream apps
- **Transport** — this lib is transport-agnostic; no Dio, no Connect, no HTTP at all
- **Codegen** — proto/Connect codegen lives in `eden-platform-api-dart`
- **Visual regression baselines** — defer until Eden visual identity is stable enough that pixel-diffs aren't constant noise (likely a separate `eden-libs/visual-regression` package later)
- **iOS-real-device testing** — sim coverage is the gate; downstream apps own real-device testing of THEIR composites
- **Storybook-style published catalog** — internal `just dev-ui` is sufficient; no public catalog hosting

## Context

**Architecture position:** lowest layer of the Eden Flutter stack. Imports `flutter/material.dart` and `flutter/widgets.dart`; nothing higher. Cannot import `eden-platform-flutter` (which imports this) or any downstream app code.

**Test pattern (locked):** `testWidgets('renders ...', (tester) async {...})` with `wrap()` helper at the top of each test file. Mirror the existing `test/widgets/eden_alert_test.dart` shape for new test files.

**Build/test commands** (run from `eden-libs/` workspace root):
- `just setup` — workspace bootstrap
- `just generate` — regenerate Dart codegen (no-op for this package; lives in eden-platform-api-dart)
- `just test` — runs `flutter test` for all eden-libs Flutter packages
- `just lint` — `flutter analyze` for Flutter packages + `go vet` for Go
- `just dev-ui` — launches the visual catalog
- `just check` — full pre-commit gate

**Versioning:** monorepo workspace. No semver bumps; changes propagate to downstream apps via `path:` dep on next `flutter pub get`.

**Known regressions surfaced by downstream apps:**
- `EdenPageHeader` Row overflow on iPhone-narrow (caught by `eden-biz-flutter` Obj 12 iOS sentinel; tracked as Objective 1 here)
- `EdenButton` Text-in-constrained-Flex overflow (already fixed at `e081038 fix(eden-button): wrap Text label in Flexible to prevent overflow in constrained layouts`)

## Constraints

- **Stack:** Flutter (current stable). Material 3 design tokens. No third-party widget libs.
- **Transport-agnostic:** no `dio`, no `http`, no `connectrpc`. Forbidden by package responsibility.
- **Platform parity:** widgets MUST render acceptably on iOS, Android, macOS, Windows, Linux, and web. No platform-specific imports without `kIsWeb` / `Platform.isIOS` etc. guards.
- **Responsive baseline:** widgets MUST render without `RenderFlex overflowed` warnings at iPhone-narrow logical widths (≥390pt). This is the strictest viewport in current downstream usage.
- **Performance:** widget build cost should not regress; no expensive layout computations in `build()`.
- **Backward compatibility:** widgets are consumed by 3+ downstream apps. Breaking changes require a downstream-coordination commit.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| `kind: ui-lib`, `default_work: feature` | Most work is widget additions / responsive fixes / token tweaks | — Pending |
| Skip research (project bootstrap) | Stack is locked Flutter+Material; existing 30-widget catalog is the spec | ✓ Good |
| First objective targets iPhone-narrow `EdenPageHeader` overflow | Surfaced by downstream eden-biz-flutter Obj 12 iOS sentinel; concrete fix path in spike notes | — Pending (Objective 1) |
| Widget tests, NOT integration tests, are the primary gate | This lib is transport-agnostic; integration tests belong in downstream apps | ✓ Good |

---
*Last updated: 2026-05-07 after bootstrap (skipped research/roadmapper phases — context lifted from `eden-biz-flutter/.planning/objectives/12-ui-e2e-coverage/12-04-SUMMARY.md` § Deferred Items).*
