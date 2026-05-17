---
objective: 011-compliance-overlay-primitives
kind: ui-lib
work: feature
status: planned
github_repo: AO-Cyber-Systems/eden-libs
---

# Objective 011 — Compliance Overlay Primitives (Wave C + USWDS + Civilian Re-use)

## Goal

Ship the Wave C compliance overlay set — 14 primitives (6 net-new Wave C + 4 enhancements to existing widgets + 4 USWDS conformance) — that gate DHHS/DOD vertical opt-in **and** carry civilian re-use across HIPAA / SOC 2 / PCI / attorney-privilege use cases. Per locked decision C in `COMPANION_UX_PATTERNS_2026-05-15.md` §0: build gov-first NOW, expose to commercial as opt-in. Cross-vertical leverage baked into every primitive's API (no DHHS/DOD/HIPAA imports; consumers map their entities to library value classes).

After this objective ships, downstream `eden-biz-flutter` (any vertical) + `eden-platform-flutter` (any companion shell) compose a federal-compliance-shaped surface from library primitives without re-implementing classification banners, audit-log viewers, FOIA workflow cards, USWDS-conformant headers, Section 508 audit overlays, CAC/PIV affordances, MFA hardware token entry, virus-scan upload states, federal role models, CUI clipboard handling, memorable-date inputs, or language toggles. Civilian verticals get the same primitives with re-labeled defaults (e.g. classification banner as data-sensitivity banner; audit log as activity log; permission matrix with non-federal roles).

## Scope

14 TRDs across 5 waves (~3-4 wk Claude execution):

**Wave 1 — Foundation banners** (3 TRDs, parallel)
- 011-01 — `EdenClassificationBanner` (UNCLASSIFIED / CUI / SECRET / TOP SECRET + civilian re-label)
- 011-11 — `EdenUSWDSBanner` ("official website of the U.S. government" pattern)
- 011-12 — `EdenAgencyIdentifier` (agency logo + name footer block)

**Wave 2 — Auth + crypto affordances** (2 TRDs, parallel)
- 011-02 — `EdenCacPivButton` (smartcard auth affordance; callback-based, no platform-channel impl)
- 011-10 — `EdenMfaHardwareToken` (YubiKey / RSA token entry; composes `EdenOtpInput`)

**Wave 3 — Form + input enhancements** (4 TRDs, parallel)
- 011-08 — Enhance `EdenSecretField` (CUI clipboard-confined + paste-from-outside warning, additive)
- 011-09 — Enhance `EdenFileUpload` (virus-scan / CUI-marking / spillage-quarantine states, additive)
- 011-13 — `EdenMemorableDate` (USWDS M/D/Y 3-field input, sibling to `EdenDatePicker`)
- 011-14 — `EdenLanguageSelector` (USWDS language toggle pattern; EO 13166 / Section 508)

**Wave 4 — Audit + viewing surfaces** (3 TRDs, parallel)
- 011-03 — `EdenSection508Audit` (dev-tools overlay highlighting ARIA / contrast / focus-order issues; library-internal QA primitive)
- 011-04 — `EdenAuditLogViewer` (immutable activity stream; actor / action / target / hash-chain link; composes `EdenActivityFeed`)
- 011-07 — Enhance `EdenPermissionMatrix` (federal role models — Privileged User / ISSO / ISSM — + break-glass affordance with justification capture; additive)

**Wave 5 — Composite surfaces** (2 TRDs, parallel)
- 011-05 — `EdenFoiaRequestCard` (request meta + due-date pill + redaction-pass status + exemption codes; composes `EdenListPageScaffold`)
- 011-06 — `EdenCaseFileShell` (multi-tab regulated dossier — header → activity → docs → contacts → notes → audit; composes `EdenDetailPageScaffold` + `EdenAuditLogViewer`)

## Constraints

- **No new pubspec deps.** Platform-channel work (CAC/PIV smartcard, hardware token) is interface-only in library; downstream consumer apps provide platform impl. Library exposes callbacks.
- **Transport-agnostic.** No HTTP / Connect / Dio / network calls. Compliance widgets receive pre-loaded data via value classes; consumers wire transport.
- **No vertical-specific imports.** Library does NOT bind to DHHS / DOD / HIPAA / PCI APIs. Every widget exposes generic-enough constructor params for civilian re-use per locked decision C.
- **Backwards-compatible.** Enhancements to existing widgets (`EdenSecretField`, `EdenFileUpload`, `EdenPermissionMatrix`) are ADDITIVE constructor parameters with defaults that preserve current behavior. All existing call sites compile and behave identically without changes.
- **Section 508 / WCAG 2.1 AA mandatory** for all 14 widgets. Explicit a11y test cases in every TRD (semantic labels, focus order, contrast, keyboard nav).
- **iPhone-narrow (≥390pt) responsive baseline** per `PROJECT.md` constraints — no `RenderFlex overflowed` warnings.
- **Test-pairing rule enforced.** Every source file with logic has a paired `test/widgets/eden_*_test.dart` file.
- **Hand-built fixtures only.** No LLM-generated test data. Fixture files start with `// Do NOT regenerate via LLM — hand-built fixtures for {WidgetName}.`
- **Obj 009 dependency (advisory).** This objective consumes `EdenThemeProfile.govFederal` for default styling. Obj 009 has not shipped — TRDs MUST plan against an interface stub (a const-Map `_govFederalColors` constant local to each widget) that obj 009 can replace with real theme-extension reads in a follow-up patch.

## Cross-vertical re-use (locked decision C)

Every Wave C primitive that has civilian utility must expose a generic-enough API so commercial verticals can opt in:

| Widget | Federal use | Civilian re-use |
|---|---|---|
| `EdenClassificationBanner` | ICD 710 UNCLASSIFIED/CUI/SECRET/TS | `EdenSensitivityBanner` alias — data-sensitivity banner for commercial CRM with custom labels (Internal / Confidential / Restricted). Legal vertical uses for attorney-client privilege (`EdenPrivilegeBanner`) |
| `EdenAuditLogViewer` | DOD audit-trail UX, FedRAMP, HIPAA | Generic activity log for any vertical — actor/action/target/timestamp |
| `EdenFoiaRequestCard` | FOIA workflow | Generic records-request workflow for any business intaking customer data requests (GDPR data subject access) |
| `EdenPermissionMatrix` (enh) | Federal roles + break-glass | All commercial verticals — break-glass + justification capture useful for SOC 2 compliance |
| `EdenSecretField` (enh) | DoD CUI clipboard | All commercial verticals — PCI-clipboard confinement, password-manager handoff warnings |
| `EdenFileUpload` (enh) | Virus-scan / spillage | All commercial verticals — virus-scan status useful for any user-uploaded file workflow |
| `EdenMfaHardwareToken` | YubiKey / RSA / CAC backup | All commercial verticals — hardware MFA for high-security users |
| `EdenCaseFileShell` | DHHS social services, DOJ case files | Generic multi-tab dossier for legal matters, medical patients, insurance claims, complex CRM contacts |
| `EdenSection508Audit` | Section 508 conformance gate | All consumer apps — generic a11y audit overlay |
| `EdenUSWDSBanner` / `EdenAgencyIdentifier` | Federal-mandatory | Federal-only (no civilian re-use intended) |
| `EdenMemorableDate` | USWDS pattern; Section 508-optimized DOB | Date-of-birth on any intake form (medical / legal / retail age-verify) |
| `EdenLanguageSelector` | EO 13166 federal mandate | Any consumer app needing i18n toggle |

## Verification

- All 14 widgets render correctly on iPhone-narrow (≥390pt) without `RenderFlex overflowed`.
- All 14 widgets have widget tests using the `wrap()` helper pattern.
- All 14 widgets have explicit Section 508 / WCAG 2.1 AA test cases (semantic labels, focus order, contrast, keyboard nav).
- Section 508 audit primitive (011-03) flags ZERO issues when run against the new compliance demo screens (self-test gate).
- Civilian re-use variants documented in dartdoc on every Wave C primitive (e.g., `/// Civilian re-use: pass [labelText: 'Internal'] to render as a generic sensitivity banner.`).
- New dev catalog screen `lib/dev_app/screens/compliance_screen.dart` showcases 8 Wave C primitives + the 3 enhancements with realistic federal AND civilian examples.
- New dev catalog screen `lib/dev_app/screens/uswds_screen.dart` showcases the 4 USWDS conformance widgets.
- 5 wave-specific export sections in `lib/eden_ui.dart` ("Objective 011 — Wave 1/2/3/4/5") cleanly group exports.
- All existing tests pass unchanged (backwards-compat gate for enhancements).

## Output (per wave landing)

- 14 new/enhanced widget files under `lib/src/widgets/`
- 11 new test files (3 enhancements append to existing widget tests if any; new tests for 11 new widgets); 14 new fixture files under `test/widgets/_fixtures/`
- 2 new dev catalog screens (`compliance_screen.dart`, `uswds_screen.dart`)
- 2 new home_screen tiles ("Compliance Overlay" + "USWDS Conformance")
- 5 export sections in `lib/eden_ui.dart`
- ROADMAP.md entry marked complete when objective ships

## Sequencing

Wave order is by **dependency direction**, not effort:

- Wave 1 (banners) ships first because Wave 5 composites consume them.
- Wave 2 (auth) is independent — runs parallel with Wave 1.
- Wave 3 (input enhancements) is independent — runs parallel with earlier waves once executor capacity allows.
- Wave 4 (audit/viewing) is independent — `EdenAuditLogViewer` (011-04) needed by Wave 5 `EdenCaseFileShell` (011-06).
- Wave 5 (composites) ships LAST — composes earlier-wave primitives.

Wave 4 must precede Wave 5 due to the 011-04 → 011-06 dependency. All other waves can interleave subject to executor capacity.

## Dependency notes

- **Obj 009 (theme system) NOT REQUIRED to ship before 011.** TRDs plan against a local `_govFederalColors` constant stub. When obj 009 lands, follow-up patches swap the stubs for `Theme.of(context).extension<EdenStatusPalette>()` reads.
- **Obj 001 dependencies (Wave A):** `EdenListPageScaffold` (TRD 001-01), `EdenDetailPageScaffold` (TRD 001-02), `EdenOtpInput` (TRD 001-05), `EdenDatePicker` (existing) — all SHIPPED per ROADMAP, available for composition.
- **Obj 003 dependencies:** `EdenActivityFeed` (existing, composed by 011-04). Available.
- **Existing widgets enhanced:** `eden_permission_matrix.dart`, `eden_secret_field.dart`, `eden_file_upload.dart`, `eden_compliance_badge.dart`. All edits ADDITIVE.

## Related research / locked decisions

- `.planning/VERTICAL_UX_RESEARCH_2026-05-16.md` §3.3 (Obj 011 recommendation) + §4 (USWDS conformance set per research) — primary spec.
- `.planning/VERTICAL_COVERAGE_ASSESSMENT_2026-05-15.md` §3 Wave C — original 10 Wave C primitives.
- `.planning/COMPANION_UX_PATTERNS_2026-05-15.md` §0 locked decision C — gov-first build with civilian re-use opt-in.
- `~/.claude/CLAUDE.md` TDD Playbook — strict TDD, test-list-first, hand-built fixtures, outside-in (system-shaped widget tests → unit helper tests).
