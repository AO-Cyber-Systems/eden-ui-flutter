---
objective: 10-agent-component-manifest
trd: 10
type: standard
wave: 1
depends_on: []
files_modified:
  - lib/src/widgets/eden_data_display/eden_data_display_exports.dart
  - tool/emit_component_manifest.dart
  - test/tool/emit_component_manifest_test.dart
autonomous: true
mode: quick
kind: ui-lib
work: feature
fixture_strategy: generators
must_haves:
  truths:
    - "A component_id declared on a widget under lib/src/widgets/eden_data_display/ but absent from kDataDisplayComponents fails a test BY NAME, with the exact line to add."
    - "A component_id listed in kDataDisplayComponents with no matching declaration on disk fails a test BY NAME."
    - "`flutter test tool/emit_component_manifest.dart` writes a sorted JSON array under build/ naming exactly the ids this package can render."
    - "The manifest's id set is DERIVED from the widgets, never hardcoded — landing a third component changes the manifest without editing any expected-value list."
    - "The partition gate has been WATCHED GO RED against a probe component and then GREEN after its removal, with both outputs captured verbatim."
  artifacts:
    - lib/src/widgets/eden_data_display/eden_data_display_exports.dart
    - tool/emit_component_manifest.dart
    - test/tool/emit_component_manifest_test.dart
  key_links:
    - "kDataDisplayComponents entries reference EdenAppointmentList.componentId / EdenRefusal.componentId — the STATIC on the widget, never a re-typed string literal."
    - "The partition test's source scan reads the .dart files on disk, so it sees a new component that no Dart code imports."
---

# JOB 10 — Agent-component manifest: declare and verify the renderable set

## Resolved configuration

```
Planning objective 10 (quick mode)
  Kind: ui-lib (from PROJECT.md)
  Work: feature  <- INHERITED from PROJECT.md default_work
                If this is actually a different work type, pass --work <type>.
  Defaults (from defaults-table):
    tdd=strict, depth=comprehensive, model=quality
    security_isolation=n/a, test_list_first=required
    fixture_strategy=generators, back_compat=none
  Applied user playbook (~/.claude/CLAUDE.md TDD Playbook):
    tdd=strict, fixture_strategy=generators (hand-built probe, no LLM test data)
  Constraints active: no_llm_test_data, no_property_based_default, no_gherkin_layer
  flutter-ui-scope detector: detected=false (quick mode has no objective dir;
    and correct on the merits — this job adds NO rendered surface, no widget,
    no state matrix, no golden).
```

## Why this exists

eden-biz `go/internal/agentintent/` carries 15 fixtures using **10 distinct
`component_id` values** across 28 occurrences. eden-ui-flutter renders **two** of
them (`list/appointments`, `error/refusal`).

Neither side declares the valid set. eden-biz's `fixtures_integrity_test.go:150`
asserts only that `ComponentID` is non-empty. An agent can emit
`summary/pipeline`, the Go fixture test passes, and nothing anywhere knows the
renderer cannot draw it. **An unknown `component_id` is today an UNDETECTABLE
condition.** This job makes it detectable. It is the seam only — it builds none
of the 8 missing components.

## Scope boundaries (do not cross)

- **Do NOT hardcode eden-biz's 10 ids anywhere in eden-ui.** The manifest declares
  what THIS package can render; eden-biz checks its fixtures against it. Coupling
  the renderer to the agent's fixture set inverts the dependency. A header comment
  RECORDING that 8 of the 10 ids seen in eden-biz fixtures have no renderer yet,
  and that `error/refusal` is the declared path for them, is wanted — a
  machine-readable list of those 8 is not.
- **Do NOT build any of the 8 missing components.**
- **Do NOT add a widget.** This job must move NO golden baseline.
- No new dependencies: `dart:convert` + `dart:io` + the already-present
  `flutter_test` only.
- No push, no PR, no merge, no `gh`.

## Test list (write these cases before the code that satisfies them)

Closed partition:
1. **Happy** — every `componentId` declared in source appears in `kDataDisplayComponents`.
2. **Undeclared (failure mode)** — a source `componentId` absent from the
   declaration fails, naming the id AND the exact entry to add.
3. **Ghost (failure mode)** — a declared entry with no matching declaration on
   disk fails, naming it (rename/delete without updating the list).
4. **Vacuity guard (edge)** — the scanned directory resolves to a non-empty set of
   `.dart` files AND a non-empty set of discovered ids. Without this, a moved
   directory makes cases 1–3 pass trivially.

Manifest:
5. Manifest ids == declared ids, set-for-set — **derived, not a hardcoded list of two.**
6. Entries sorted by `component_id` ascending.
7. Schema LOCKED: exactly the declared keys, no extras, all values non-empty strings.
8. Encoded output round-trips through `jsonDecode` to a list of the same length,
   with a trailing newline.

Fixture note (`no_llm_test_data`): the only fixture is the hand-written probe
component in Task 3. No generated sample data anywhere.

## Tasks

<task type="auto" tdd="true">
  <name>Declare the renderable set and gate it with a closed-partition test</name>

  <files>
lib/src/widgets/eden_data_display/eden_data_display_exports.dart
test/tool/emit_component_manifest_test.dart
  </files>

  <action>
Add `kDataDisplayComponents` to `eden_data_display_exports.dart`. That file's
existing header already states the intent — "a dispatcher can build its map by
reading the components rather than maintaining a second list beside them" — so the
declaration belongs there, beside the prose that promises it. The file is already
re-exported from `lib/eden_ui.dart:79`, so the constant becomes public API with no
new export wiring.

Shape: a sorted `const` list of `(String, Type)` records, mirroring the repo's
existing record idiom in `kScannedTokenFiles` (accessed as `e.$1` in
`test/design/design_md_fresh_test.dart:145`):

    const List<(String, Type)> kDataDisplayComponents = <(String, Type)>[
      (EdenAppointmentList.componentId, EdenAppointmentList),
      (EdenRefusal.componentId, EdenRefusal),
    ];

# CRITICAL: reference the STATIC (`EdenAppointmentList.componentId`), never a
#   re-typed 'list/appointments' literal. A re-typed literal is a second list
#   that drifts — exactly the failure this job exists to close.
# GOTCHA: this needs `import` directives alongside the existing `export`s; a
#   barrel that only re-exports cannot see the symbols it names. If the `const`
#   record list does not analyze, drop to `final` and note why in a comment —
#   do not silently weaken the pairing to `(String, String)`.

Doc-comment the constant with: what it is (the authoritative set of component_ids
THIS package can render), who consumes it (the manifest emitter; eden-biz checks
its fixtures against the emitted manifest), and the note that 8 of the 10
component_ids appearing in eden-biz `go/internal/agentintent/` fixtures have no
renderer here yet, with `error/refusal` the declared path for them. Record that as
prose only — **no list of the 8 ids.**

Then write `test/tool/emit_component_manifest_test.dart` with the closed-partition
group (test-list cases 1–4). MIRROR `test/design/design_md_fresh_test.dart` group
`'token-file coverage'` (lines 128–178) — same shape, same failure-message
discipline:

- `_repoRoot()` resolved from `Directory.current` with an up-front `fail()` if
  `pubspec.yaml` is absent. **Never a hardcoded absolute path**
  (cf. `edenbiz-website-tests-gated-on-absolute-paths`).
- Scan `lib/src/widgets/eden_data_display/` for `*.dart` files, read each as text,
  and extract ids with
  `RegExp(r"static\s+const\s+String\s+componentId\s*=\s*'([^']*)'\s*;")`.
  Reading SOURCE TEXT (not the import graph) is the load-bearing choice: it sees a
  component file that nothing imports yet, which is exactly how an undeclared
  component lands.
- Vacuity guard FIRST, in the `design_md_fresh_test` idiom:
  `expect(onDisk, isNotEmpty, reason: '... resolved to nothing — if this directory
  moved, this whole gate is vacuous and the partition below would pass trivially')`,
  and the same for the discovered-id set.
- `undeclared = discovered.difference(declared)` -> `expect(..., isEmpty, reason:
  'component(s) declared in source with no manifest entry: $undeclared\nAdd
  (<Widget>.componentId, <Widget>) to kDataDisplayComponents in
  lib/src/widgets/eden_data_display/eden_data_display_exports.dart.')`
- `ghosts = declared.difference(discovered)` -> `expect(..., isEmpty, reason:
  'component(s) listed but not declared on disk: $ghosts — renamed or deleted
  without updating kDataDisplayComponents')`

# NOTE: the scan is textual, so a commented-out `static const String componentId`
#   would be a false positive. That is the same trade `gen_design_md.dart` makes
#   and is acceptable; say so in a comment rather than building a Dart parser.

RED FIRST, and make the RED a real one: commit the declaration with **only** the
`EdenAppointmentList` entry, run the partition test, and confirm it fails naming
`error/refusal`. A compile error is not a RED. Then add the `EdenRefusal` entry for
GREEN. Two atomic commits (`test:` then `feat:`) per the repo's existing pattern.
  </action>

  <verify>
flutter analyze lib/src/widgets/eden_data_display/eden_data_display_exports.dart test/tool/emit_component_manifest_test.dart

flutter test -j 2 test/tool/emit_component_manifest_test.dart > /tmp/o.txt 2>&1; echo "EXIT=$?"

# NEVER pipe `flutter test` into tail/head/grep — a pipeline returns the LAST
# stage's status, so a failing run reports success. That happened once already
# this session: a run reporting exit 0 had 38 failures. Redirect, then read $?,
# then read /tmp/o.txt with a separate command.
  </verify>

  <done>
`kDataDisplayComponents` exists with two entries, both referencing the widget
static. The partition test was WATCHED fail with only one entry (message named
`error/refusal`) and passes with both. `flutter analyze` clean on both files.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Emit the component manifest, with the id set derived from the declaration</name>

  <files>
tool/emit_component_manifest.dart
test/tool/emit_component_manifest_test.dart
  </files>

  <action>
READ `tool/emit_flutter_manifest.dart` FIRST and mirror it in structure and idiom.
Its header explains every constraint that also applies here; do not rediscover
them.

`tool/emit_component_manifest.dart`:

- Header block covering: what it emits and why (the first authoritative
  declaration of which `component_id`s this package can render); the LOCKED schema;
  the run instruction — `flutter test tool/emit_component_manifest.dart`, **NOT
  `dart run`**, because the widget imports pull in `dart:ui` which a bare
  `dart run` cannot resolve; the 0-new-deps note; and the prose record that 8 of
  the 10 component_ids in eden-biz's `agentintent` fixtures have no renderer here,
  with `error/refusal` the declared path for them. **No list of the 8 ids.**
- `const String defaultEmitOut = 'build/eden-ui-components.json';` overridable via
  `const String.fromEnvironment('EMIT_OUT', defaultValue: defaultEmitOut)`, set
  with `--dart-define=EMIT_OUT=...`.
- `List<Map<String, Object>> buildComponentManifestEntries()` — PURE, no I/O, so it
  is unit-testable in isolation exactly as `buildFlutterManifestEntries()` is. It
  reads `kDataDisplayComponents`, maps each record to the locked schema, and sorts
  by `component_id` ascending.
- LOCK the schema in the header and keep it minimal:
  `{"component_id": <id>, "widget": <Type as String>}`. Two keys, no more. Any
  extra key is drift a downstream consumer will bind to.
- `String encodeComponentManifest(List<Map<String, Object>> entries)` —
  `JsonEncoder.withIndent('  ')` plus a trailing newline, matching the flutter
  emitter's convention.
- `main()` wrapped in a single `test('emit eden-ui-components.json', () {...})`.
  # GOTCHA (from emit_flutter_manifest.dart's header): a plain `main()` under
  #   `flutter test` reports "No tests ran" and exits NON-ZERO, which breaks any
  #   chained invocation. The `test()` wrapper is what makes the exit code 0.
  Body creates the parent dir recursively, writes the file, logs
  `wrote N entries -> <path>`, and `expect(entries, isNotEmpty)`.

Then add test-list cases 5–8 to `test/tool/emit_component_manifest_test.dart`,
importing the tool directly as `import '../../tool/emit_component_manifest.dart';`
(the flutter-manifest test does the same — tool files are plain library code
outside `lib/`).

# CRITICAL for case 5: assert the manifest ids equal the ids DERIVED from
#   kDataDisplayComponents / the source scan — NOT a hardcoded expected list of
#   two. A hardcoded list would need editing every time a component lands, and
#   would pass while asserting nothing.

Case 7 asserts the key set is exactly `{'component_id', 'widget'}` per entry
(assert BOTH directions: no missing key and no extra key) and that both values are
non-empty strings.

RED first: write cases 5–8 against the not-yet-written `buildComponentManifestEntries`,
confirm the failure, then implement. `test:` then `feat:` commits.
  </action>

  <verify>
flutter analyze tool/emit_component_manifest.dart test/tool/emit_component_manifest_test.dart

flutter test -j 2 test/tool/emit_component_manifest_test.dart > /tmp/o.txt 2>&1; echo "EXIT=$?"

flutter test tool/emit_component_manifest.dart > /tmp/emit.txt 2>&1; echo "EXIT=$?"
# then, as a SEPARATE command, confirm the written file:
cat build/eden-ui-components.json

# Confirm the override path works (separate command, read $? directly):
flutter test tool/emit_component_manifest.dart --dart-define=EMIT_OUT=/tmp/cm.json > /tmp/emit2.txt 2>&1; echo "EXIT=$?"
  </verify>

  <done>
`flutter test tool/emit_component_manifest.dart` exits 0 and writes a
2-entry, id-sorted JSON array to `build/eden-ui-components.json`; the
`--dart-define=EMIT_OUT` override writes to the given path instead. Cases 5–8
pass, and case 5 derives its expectation rather than hardcoding two ids.
  </done>
</task>

<task type="auto" tdd="false">
  <name>Probe the gate: prove it goes RED by name, then GREEN, and that no golden moved</name>

  <files>
lib/src/widgets/eden_data_display/_vacuity_probe.dart   (CREATE then DELETE — must not survive the task)
  </files>

  <action>
The differential control. Without it, the partition test reports the same thing for
a repo with full coverage and for one whose scan silently resolves to nothing —
i.e. it would prove nothing (cf. `tool/probe_guard_assert.sh`, which exists for
exactly this reason, and the `edenbiz-migration-gate-is-dead` failure mode).

1. Hand-write `lib/src/widgets/eden_data_display/_vacuity_probe.dart` containing a
   `componentId` NOT in the declaration. Keep it dependency-free — the partition
   test reads source text, so the probe needs no imports and nothing needs to
   import it:

       // TEMPORARY vacuity probe — delete immediately. See JOB 10 Task 3.
       class EdenVacuityProbe {
         static const String componentId = 'probe/vacuity';
       }

   Hand-written, not generated (`no_llm_test_data`).

2. Run the partition test. CONFIRM it FAILS and that the message NAMES
   `probe/vacuity`. A failure that does not name the offender is not the gate this
   job promised. **Capture the failure output VERBATIM for the summary.**

3. Delete the probe file.

4. Re-run. CONFIRM GREEN. **Capture that output VERBATIM too.**

5. Confirm the probe is gone: `git status --porcelain lib/src/widgets/eden_data_display/`
   must show no `_vacuity_probe.dart`, untracked or otherwise.

6. GOLDEN CHECK. This job adds no widget and must move NO baseline. Run the wider
   sweep, then confirm `git status --porcelain` over the golden directories is
   EMPTY. **If any golden changed, STOP and report — that is a finding, not churn.
   Do not re-bless it, do not commit it.**
  </action>

  <verify>
# RED probe (with the probe file present) — plain redirect, read $? directly:
flutter test -j 2 test/tool/emit_component_manifest_test.dart > /tmp/red.txt 2>&1; echo "EXIT=$?"
# EXPECT non-zero. Then read /tmp/red.txt as a SEPARATE command and confirm it
# names probe/vacuity.

# GREEN (after deleting the probe):
flutter test -j 2 test/tool/emit_component_manifest_test.dart > /tmp/green.txt 2>&1; echo "EXIT=$?"
# EXPECT 0.

# Full sweep:
flutter analyze lib/src/widgets/eden_data_display/eden_data_display_exports.dart tool/emit_component_manifest.dart test/tool/emit_component_manifest_test.dart

flutter test -j 2 test/tool/ test/design/ > /tmp/o.txt 2>&1; echo "EXIT=$?"
# -j 2 IS REQUIRED. This machine is memory-constrained; a full-concurrency run
# was killed twice today.
# NEVER pipe `flutter test` into tail/head/grep — a pipeline returns the LAST
# stage's status, so a failing run reports success. Redirect, echo $?, then read
# the file in a separate command.

# No golden may move:
git status --porcelain test/stories/_generated/goldens test/widgets/goldens
# EXPECT empty output.

# Probe must be gone:
git status --porcelain lib/src/widgets/eden_data_display/
  </verify>

  <done>
The partition gate was watched go RED naming `probe/vacuity` and GREEN after the
probe's removal, both outputs captured verbatim in the summary. The probe file is
deleted and absent from `git status`. `flutter test -j 2 test/tool/ test/design/`
exits 0. `flutter analyze` clean. `git status --porcelain` over both golden
directories is empty — no baseline moved.
  </done>
</task>

## Verification (whole job)

- `flutter analyze` clean on all three changed files.
- `flutter test -j 2 test/tool/ test/design/` -> `EXIT=0`. **`-j 2` is required**
  (memory-constrained machine; full-concurrency runs were killed twice today).
- Every `flutter test` invocation uses a plain redirect and reads `$?` directly.
  **Never pipe `flutter test` into `tail`/`head`/`grep`** — a pipeline returns the
  LAST stage's status, so a failing run reports success. A run reporting exit 0
  with 38 failures already happened once this session.
- `git status --porcelain test/stories/_generated/goldens test/widgets/goldens`
  is EMPTY. Any golden change is a finding to report, not churn to bless.
- The RED and GREEN probe outputs are quoted verbatim in the summary.

## Success criteria

- [ ] `kDataDisplayComponents` declares both renderable ids, each referencing the
      widget's `componentId` static (no re-typed literals).
- [ ] An undeclared component fails BY NAME with the exact entry to add.
- [ ] A ghost entry fails BY NAME.
- [ ] Vacuity guards present, in the `design_md_fresh_test` idiom.
- [ ] `flutter test tool/emit_component_manifest.dart` emits a sorted,
      schema-locked JSON array under `build/`; `--dart-define=EMIT_OUT` overrides.
- [ ] The manifest assertion is DERIVED from the widgets — no hardcoded list of two.
- [ ] Probe RED + GREEN captured verbatim; probe file deleted.
- [ ] No golden moved. No new dependency. None of eden-biz's 10 ids hardcoded.
- [ ] No push, no PR, no merge, no `gh`.
