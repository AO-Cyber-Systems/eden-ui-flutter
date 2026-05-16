---
objective: 007-b-trades-a-field-companion
kind: ui-lib
work: feature
status: planned
estimated_effort: 2-3 weeks Claude execution
trd_count: 8
waves: 4
---

# Objective 007 — B-Trades-A Field/Companion Pages (cross-vertical)

## Goal

Ship the 8 cross-vertical companion-mode page composites per `TRADES_REMAP_DEEP_AUDIT_2026-05-15.md` §5 B-trades-A. After this objective ships, downstream `eden-platform-flutter` (and any companion-mode vertical app — trades-hvac, medical home-visit, fuel-truck driver, gov caseworker site visits) can compose a field-crew companion shell out of library primitives without re-implementing the inspection-form-with-photos-and-signature pattern, the full-screen photo/signature capture flows, the GPS clock-in/out pattern, the truck-load packout checklist, the mobile launcher grid, or the bottom-sheet AI chat surface.

These are **pages, not page-shells.** They are full-page compositions that drop into an `EdenCompanionShell` (objective 002) content slot. The shell + nav + chrome are owned by Objective 002; this objective owns the page CONTENT.

## Why now

- **Objective 002 Companion Shell Foundation just shipped (2026-05-15).** `EdenCompanionShell` + `EdenAdaptiveLayout` (forceCompact for lock E rule 3) + `EdenGpsStatusIndicator` are all GREEN — the compositional substrate this objective needs.
- **Wave A primitives (objective 001) provide every dependency.** `EdenAuthenticatedImage`, `EdenMapPreview`, `EdenIntakeForm`, `EdenConsentFlow`, `EdenOfflineQueueViewer`, `EdenNetworkStatusBar`, `EdenQuickActionBar`, `EdenSignaturePad` (existing pre-Wave-A widget) — all available.
- **AI surface primitives (objective 003) provide the FAB + chat sheet inputs.** `EdenAgentChat`, `EdenAgentChatFab`, `EdenAiPersona`, `EdenChatMessage` — `MobileAiFab` + `MobileAiChatSheet` compose these into FAB + bottom-sheet variants.
- **Donor source 100% present in `trades-flutter`.** All 9 donor files exist and were inspected at planning time. No greenfield UX design required — the trades-flutter implementations are the spec; the port strips Riverpod + trades-specific business logic and replaces them with callback-driven generic surfaces.
- **Companion field surface unblocks trades-hvac + medical home-visit pilot starts.** Without these 8 pages, the consumers must each re-vendor inspection-form-with-photos, signature-capture, packout-checklist patterns — exactly the redundancy this lib exists to prevent.

## Scope (8 components)

| TRD | Component | Donor (trades-flutter) | Wave |
|---|---|---|---|
| 01 | `EdenInspectionFormPage` | `lib/features/field_crew/presentation/inspection_form_page.dart` (+ `inspection_list_page.dart` context) | 4 |
| 02 | `EdenSignatureCapturePage` | `lib/features/field_crew/presentation/signature_capture_page.dart` | 3 |
| 03 | `EdenPackoutPage` | `lib/features/field_crew/presentation/packout_page.dart` | 4 |
| 04 | `EdenPhotoCapturePage` | `lib/features/field_crew/presentation/photo_capture_page.dart` | 3 |
| 05 | `EdenCheckInPage` | `lib/features/field_crew/presentation/check_in_page.dart` | 2 |
| 06 | `EdenLocationMapPage` | `lib/features/field_crew/presentation/location_map_page.dart` | 2 |
| 07 | `EdenMobileQuickAccessGrid` | `lib/features/mobile_home/presentation/widgets/quick_access_grid.dart` | 1 |
| 08 | `EdenMobileAiFab` + `EdenMobileAiChatSheet` | `lib/features/mobile_home/presentation/widgets/mobile_ai_fab.dart` + `mobile_ai_chat_sheet.dart` | 1 |

## Wave structure (parallelism map)

- **Wave 1 — Mobile-shell primitives (2 TRDs):** 07, 08. Small + reusable across companion pages. No cross-dependencies. Run as 2 concurrent executor sessions.
- **Wave 2 — GPS-aware pages (2 TRDs):** 05, 06. Both depend on Wave A `EdenMapPreview` + Obj-002 `EdenGpsStatusIndicator`. No cross-dependencies. Run as 2 concurrent executor sessions once Wave 1 is GREEN (the Wave 1 dep is purely about pacing/library catalog; technically Wave 1 + Wave 2 could overlap, but staggering keeps `lib/eden_ui.dart` export-section coordination clean).
- **Wave 3 — Capture-flow pages (2 TRDs):** 02, 04. Full-screen single-task flows. No cross-dependencies. Run as 2 concurrent executor sessions.
- **Wave 4 — Form-flow pages (2 TRDs):** 01, 03. Multi-step form pages. TRD 01 composes Wave A `EdenIntakeForm` + `EdenConsentFlow` + `EdenAuthenticatedImage` + Obj-002 `EdenGpsStatusIndicator`. TRD 03 composes existing eden_ui primitives. No cross-dependencies. Run as 2 concurrent executor sessions.

## Constraints (locked, do not revisit)

1. **TDD strict (Iron Law).** Every TRD's testable tasks carry `tdd="true"`. Test-list checklist required at the top of every TRD. Hand-built fixture builders only (resolver constraints: `no_llm_test_data`, `no_property_based_default`, `no_gherkin_layer`). One test at a time through RED → GREEN → REFACTOR. Per `~/.claude/CLAUDE.md` TDD Playbook habits 1–4.
2. **Outside-in.** Widget test at the top-level public page first, then drill into internal helpers. iPhone-narrow responsive baseline (≥390pt) MUST be in every TRD's test list.
3. **Test pattern locked.** `testWidgets('renders ...', (tester) async {...})` with `wrap()` helper at the top of each test file. Mirror existing patterns in `test/widgets/eden_companion_shell_test.dart`. Widget tests, NOT integration tests.
4. **Transport-agnostic.** No `dio`, no `http`, no `connectrpc`, no `shared_preferences`, no `flutter_riverpod`, no `geolocator`, no `camera_awesome`, no `image_picker`, no `signature_pad`, no `flutter_map`, no `google_maps_flutter`. All side-effecting capabilities (camera, GPS, persistence, network) come in as **callbacks or value-typed props from the consumer**. Library renders the UX; consumer wires the platform.
5. **Companion-mode optimized.** Per locked decision E rule 3: pin to Compact at all widths. Each page is designed to render inside an `EdenCompanionShell` content slot OR stand alone full-screen on phone widths (≥390pt). Pages do NOT wrap themselves in `EdenCompanionShell` — that's the consumer's job (shell pinning is the shell's responsibility, not the page's).
6. **Generic types — no trades binding.** Field-crew context is cross-vertical. No `package:trades/...` imports anywhere. Donor data classes (`InspectionForm`, `PackoutItem`, `CheckIn`, `LocationUpdate`) are NOT ported — instead, the consumer supplies its own model data via library-defined value types or callbacks.
7. **Offline-first per locked decision D.** Each page handles offline state (composes/exposes hooks for `EdenOfflineQueueViewer` + `EdenNetworkStatusBar`). Photo capture writes to a consumer-supplied queue callback; signature capture writes to a consumer-supplied queue callback; etc. Library does NOT own queue persistence.
8. **Hand-built fixtures.** Consumer supplies model data; widgets render. Test fixtures live in `test/widgets/_fixtures/eden_<page>_fixtures.dart` per existing pattern. NO LLM-generated test data — resolver constraint `no_llm_test_data` enforced.
9. **iPhone-narrow ≥390pt baseline.** Strictest viewport in downstream usage. Every TRD's test list includes a 390pt render-without-overflow case.
10. **Visual catalog entry.** Each page gets a catalog entry. Per scale (8 pages dense enough for own screen), open a new `lib/dev_app/screens/field_screen.dart` and register it in `home_screen.dart` under category "Field / Companion Pages — Objective 007". Wave 1 TRDs (07, 08) bootstrap the screen file; subsequent waves append entries.
11. **Export section.** Open `// Objective 007 — B-Trades-A field/companion pages` section in `lib/eden_ui.dart`. Wave 1's first-completing TRD bootstraps the section header; subsequent TRDs append exports.
12. **No new `pubspec.yaml` deps.** Use existing — `showcaseview` (already present), no `geolocator`, no `camera_awesome`, no `signature_pad` package (compose existing `EdenSignaturePad`). Callbacks model the consumer-side platform wiring.
13. **Material 3 + tokens.** Use `EdenSpacing`, `EdenRadii`, `EdenColors`, `EdenTypography` from `lib/src/tokens/`. No third-party widget libs except those already in `pubspec.yaml`.

## Open questions deferred to executor

- **Photo capture (TRD 04):** the donor uses `camera_awesome` placeholder. The library version cannot include `camera_awesome` (constraint 12). Approach: accept `Future<EdenCapturedPhoto> Function(BuildContext context, EdenPhotoCaptureRequest request)? onCapture` callback. The widget shows the captured-photo preview, annotation UI, and "Use Photo" / "Retake" controls; the consumer wires `image_picker` / `camera_awesome` / etc. See TRD 04 for the locked callback signature.
- **Signature capture (TRD 02):** the donor `signature_capture_page.dart` uses a `CustomPainter` placeholder. The library has a real `EdenSignaturePad` widget. `EdenSignatureCapturePage` composes `EdenSignaturePad` as its centerpiece — full-screen wrapper with clear/save action bar + signer name line + "signed on $date" footer. No new package dep.
- **Map (TRD 05, 06):** compose existing `EdenMapPreview` + `EdenMapProvider` interface (objective 001 TRD 03). For `NoOpMapProvider` (default), the page degrades to placeholder card per Wave A pattern.

## What this objective explicitly does NOT ship

- **Routing.** Pages emit `Navigator.of(context).pop(...)` results or fire `on*` callbacks. The consumer's `go_router` (or any router) does the navigation.
- **Persistence.** No queue store, no draft auto-save, no IndexedDB / sqflite. The page emits `onSaveDraft(...)` / `onSubmit(...)` callbacks; the consumer owns persistence.
- **Connectivity polling.** Network status is passed in via `EdenNetworkStatus` enum (already a Wave A type).
- **Camera / GPS / signature-bitmap platform wiring.** All capability acquisition is a consumer responsibility, wired through callbacks at the page boundary.
- **InspectionFormPage data schema validation.** The page renders fields based on a value-typed schema; validation predicates are caller-supplied. Library does not own the validation language.
- **AI streaming integration (TRD 08).** The AI chat sheet is a thin compositional wrapper around objective-003 `EdenAgentChat` — it accepts the same `EdenChatStreamSender` + `EdenChatConversationCreator` callbacks that objective 003 already defines. No new streaming surface.
- **Field-notes page.** The donor `field_notes_page.dart` exists but is NOT in the 8-component scope per audit §5. Defer to a follow-on objective if cross-vertical demand surfaces.

## Acceptance criteria

- All 8 components ship as `lib/src/widgets/eden_<page>.dart` files with matching `test/widgets/eden_<page>_test.dart` + `test/widgets/_fixtures/eden_<page>_fixtures.dart`.
- All tests GREEN under `flutter test` in the `eden-ui-flutter/` package.
- `just lint` (flutter analyze) passes.
- `just check` (full pre-commit gate) passes.
- No new `pubspec.yaml` dependencies.
- No `package:trades/...` / `package:flutter_riverpod/...` / `package:dio/...` / `package:http/...` / `package:connectrpc/...` / `package:geolocator/...` / `package:camera_awesome/...` / `package:image_picker/...` / `package:signature_pad/...` / `package:flutter_map/...` / `package:google_maps_flutter/...` imports anywhere under `lib/`.
- `lib/dev_app/screens/field_screen.dart` renders all 8 components live with hand-built fixture data.
- `lib/eden_ui.dart` exports section `// Objective 007 — B-Trades-A field/companion pages` lists all 8 widget exports + any new value types.
- iPhone-narrow (390pt) render-without-overflow verified for every page in its test list.

## References

- `TRADES_REMAP_DEEP_AUDIT_2026-05-15.md` §5 B-trades-A (this objective's primary spec — 8 components)
- `objectives/002-companion-shell-foundation/` — `EdenCompanionShell`, `EdenAdaptiveLayout` (forceCompact), `EdenGpsStatusIndicator`
- `objectives/001-wave-a-cross-vertical-fundamentals/` — Wave A primitives composed into these pages
- `objectives/003-phase-1-widget-donations/` — AI surface primitives (`EdenAgentChat` + `EdenAgentChatFab`)
- Donor: `AOCyber-Trades/trades-flutter/lib/features/field_crew/presentation/*.dart` (8 page files inspected at planning time)
- Donor: `AOCyber-Trades/trades-flutter/lib/features/mobile_home/presentation/widgets/{quick_access_grid,mobile_ai_fab,mobile_ai_chat_sheet}.dart` (3 widget files inspected at planning time)
- `~/.claude/CLAUDE.md` — Global TDD Playbook (habits 1–6 applied)
