// test/tool/emit_component_manifest_test.dart
//
// Holds `kDataDisplayComponents` to the directory it claims to describe, and
// the emitted manifest to its locked schema.
//
// WHY A CLOSED PARTITION AND NOT A SCAN ALONE. The declaration could have
// been derived by parsing source, or by having each component register
// itself. Both fail OPEN in the same way the oracle has been bitten by all
// session: a regex that stops matching, or a component that forgets to
// register, is indistinguishable from "nothing to declare". So the
// declaration is written by hand and this test proves it accounts for the
// directory EXACTLY — every `componentId` in source appears in the list, and
// every entry in the list still exists in source. Adding a component and
// skipping the decision is what fails.
//
// Same shape as `test/design/design_md_fresh_test.dart`'s 'token-file
// coverage' group, including its vacuity guard, for the same reason.
library;

import 'dart:convert';
import 'dart:io';

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/emit_component_manifest.dart';

/// Where the data-display components live. Used for the "add it here"
/// guidance and for the vacuity guard, NOT for membership — see [_kScanDir].
const String _kComponentDir = 'lib/src/widgets/eden_data_display';

/// THE SCAN IS LIB-WIDE, and the reason is a gate that would otherwise report
/// the same thing for "clean" and "not looked at".
///
/// This scanned `_kComponentDir` only. Nothing in the repo requires a
/// `componentId` widget to live there, and the escape is not hypothetical:
/// `summary/pipeline` is one of eden-biz's ten ids and
/// `lib/src/widgets/eden_pipeline_graph.dart` already exists at the TOP
/// level. Adding the declaration to that existing file — the natural place
/// for it — meant the scan never read it, cases 1/3/4 all stayed green, and
/// the manifest silently omitted a renderable surface. That is the direction
/// this whole gate calls unsafe.
///
/// The repo's own lint config documents the identical escape one level down,
/// on its `enforced_paths` globs: "A new component built outside the enforced
/// globs would have run `dart run custom_lint` green while using raw colours
/// and raw spacing — a gate that reports the same thing for 'clean' and 'not
/// looked at'." Same shape, reproduced one level up.
///
/// Measured cost of closing it: 542 `.dart` files under `lib/`, 22ms to read
/// them all, and the same two ids come back today — so widening is zero-risk
/// and strictly stronger.
const String _kScanDir = 'lib';

/// Matches a `componentId` string declaration, in the spellings that analyze
/// and lint clean in THIS repo.
///
/// `static const String componentId = '…';` is the house style, but neither
/// `prefer_single_quotes` nor any type-annotation lint is enabled here
/// (`analysis_options.yaml` includes only `flutter_lints` → `lints`
/// recommended), so `"double quoted"` and an un-annotated `static const`
/// both pass every gate in the repo. A strict pattern therefore fails OPEN on
/// the two most plausible ways the next component gets written. Hence the
/// optional type, either quote character, and an optional `r` prefix.
///
/// TEXTUAL, not a Dart parse. The trade is stated in both directions rather
/// than only the flattering one:
///
///  - FAIL LOUD (safe): a commented-out or doc-comment declaration is a false
///    positive — an id "in source" with no entry, so case 1 reds with a
///    message naming the file. Same trade `tool/gen_design_md.dart` makes.
///  - FAIL OPEN (unsafe): an id built by concatenation or interpolation, a
///    `static final`, or a `static String get componentId =>` is invisible to
///    this pattern. [_kLooseIdPattern] is the tripwire for exactly that —
///    anything that mentions `componentId =` but does not parse as a literal
///    makes case "regex-coverage" red, so a style this cannot read fails
///    loudly instead of silently.
final RegExp _componentIdPattern = RegExp(
    r"""static\s+const\s+(?:String\s+)?componentId\s*=\s*r?['"]([^'"]*)['"]\s*;""");

/// Deliberately loose: anything that assigns to a `componentId`. Counted
/// against [_componentIdPattern]'s matches so a declaration style the strict
/// pattern cannot read is reported rather than skipped.
final RegExp _kLooseIdPattern = RegExp(r'\bcomponentId\s*=');

String _repoRoot() {
  final String root = Directory.current.path;
  if (!File('$root/pubspec.yaml').existsSync()) {
    fail('emit_component_manifest_test: expected to run from the '
        'eden_ui_flutter package root (no pubspec.yaml under '
        'Directory.current="$root"). Run `flutter test` from the package '
        'root.');
  }
  return root;
}

/// Every `component_id` declared anywhere under [_kScanDir], mapped to EVERY
/// file that declares it.
///
/// A `List` of paths per id, not one path. Keyed single-valued this silently
/// dropped a second declaration of the same id — map size stayed 1, cases 1
/// and 3 compared equal sets, and two widgets claiming one id was
/// undetectable. The list is what lets case "source-duplicates" name both
/// files.
///
/// Paths are ROOT-RELATIVE, not basenames: across 542 files a bare file name
/// is ambiguous.
Map<String, List<String>> _idsInSource(String root) {
  final Directory dir = Directory('$root/$_kScanDir');
  if (!dir.existsSync()) {
    fail('$_kScanDir does not exist. If the package layout moved, this whole '
        'gate is vacuous and every case below would pass trivially.');
  }
  final Map<String, List<String>> found = <String, List<String>>{};
  for (final File file in dir
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))) {
    final String source = file.readAsStringSync();
    final String rel = file.path.replaceAll(r'\', '/').replaceFirst(
          '${root.replaceAll(r'\', '/')}/',
          '',
        );
    for (final RegExpMatch m in _componentIdPattern.allMatches(source)) {
      found.putIfAbsent(m.group(1)!, () => <String>[]).add(rel);
    }
  }
  return found;
}

/// Files whose `componentId =` the strict pattern could not read, with the
/// count of each. Feeds the regex-coverage tripwire.
Map<String, (int loose, int strict)> _idPatternCoverage(String root) {
  final Map<String, (int, int)> out = <String, (int, int)>{};
  for (final File file in Directory('$root/$_kScanDir')
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))) {
    final String source = file.readAsStringSync();
    final int loose = _kLooseIdPattern.allMatches(source).length;
    if (loose == 0) continue;
    final int strict = _componentIdPattern.allMatches(source).length;
    if (loose != strict) {
      out[file.path.replaceAll(r'\', '/').replaceFirst(
            '${root.replaceAll(r'\', '/')}/',
            '',
          )] = (loose, strict);
    }
  }
  return out;
}

List<String> _declaredIdList() =>
    kDataDisplayComponents.map(((String, Type) e) => e.$1).toList();

Set<String> _declaredIds() => _declaredIdList().toSet();

void main() {
  group('closed partition', () {
    test('case 4 (vacuity): the scan finds .dart files AND finds ids', () {
      final String root = _repoRoot();
      final Directory dir = Directory('$root/$_kComponentDir');

      final int dartFiles = dir
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((File f) => f.path.endsWith('.dart'))
          .length;
      expect(dartFiles, greaterThan(0),
          reason: '$_kComponentDir resolved to no .dart files at all. Cases '
              '1-3 would then compare two empty sets and pass, so this guard '
              'runs FIRST — a moved directory must fail loudly, not quietly '
              'satisfy a partition.');

      expect(_idsInSource(root), isNotEmpty,
          reason: 'the scan matched no `static const String componentId` '
              'anywhere. Either every component lost its id, or '
              '_componentIdPattern has stopped matching the declaration '
              'style — and a regex that matches nothing looks exactly like a '
              'directory with nothing to declare.');
    });

    test('case 1 (happy): every component_id in source is declared', () {
      final Map<String, List<String>> inSource = _idsInSource(_repoRoot());
      final Set<String> declared = _declaredIds();

      final Set<String> undeclared =
          inSource.keys.toSet().difference(declared);
      expect(undeclared, isEmpty,
          reason: 'component_id(s) declared in source but missing from '
              'kDataDisplayComponents: '
              '${undeclared.map((String id) => '$id (${inSource[id]!.join(', ')})').join('; ')}\n'
              'A component the manifest does not name is a surface the agent '
              'will be told this package cannot render, while the widget sits '
              'right there. Add it to kDataDisplayComponents in '
              'lib/src/widgets/eden_data_display/eden_data_display_exports.dart '
              'as `(TheWidget.componentId, TheWidget)` — reference the '
              'STATIC, never a re-typed string literal.');
    });

    test('case 3 (ghost): every declared entry still exists in source', () {
      final Map<String, List<String>> inSource = _idsInSource(_repoRoot());

      final Set<String> ghosts =
          _declaredIds().difference(inSource.keys.toSet());
      expect(ghosts, isEmpty,
          reason: 'kDataDisplayComponents names component_id(s) that no '
              'source file declares: ${ghosts.join(', ')}. A component was '
              'renamed or deleted without updating the declaration, so the '
              'manifest promises the agent a surface that no longer exists.');
    });

    test('source-duplicates: no component_id is declared by two widgets', () {
      final Map<String, List<String>> inSource = _idsInSource(_repoRoot());

      final Map<String, List<String>> dupes = <String, List<String>>{
        for (final MapEntry<String, List<String>> e in inSource.entries)
          if (e.value.length > 1) e.key: e.value,
      };
      expect(dupes, isEmpty,
          reason: 'component_id(s) declared by more than one widget: '
              '${dupes.entries.map((MapEntry<String, List<String>> e) => '${e.key} -> ${e.value.join(' AND ')}').join('; ')}\n'
              'WHICH WIDGET RENDERS AN ID is the entire product of this '
              'seam, so two claimants is the undetectable condition the '
              'manifest exists to remove. The emitted JSON would carry two '
              'objects with one component_id, and a Go consumer '
              'unmarshalling into a map keeps whichever lands last.');
    });

    test('declaration-duplicates: kDataDisplayComponents names each id once',
        () {
      final List<String> all = _declaredIdList();

      // LENGTH AGAINST SET SIZE, because every other assertion in this file
      // compares Sets and a duplicate collapses invisibly in all of them:
      // case 1 and case 3 would see equal sets, case 5 equal sets, case 6
      // would sort [a, a, b] and find it sorted, and case 7 iterates each
      // entry on its own. Green everywhere, two entries emitted.
      expect(all.length, _declaredIds().length,
          reason: 'kDataDisplayComponents lists ${all.length} entries but '
              'only ${_declaredIds().length} distinct component_id(s). A '
              'duplicate collapses in every Set comparison in this file, so '
              'this length check is the only place it can surface.');
    });

    test(
        'regex-coverage: no `componentId =` in lib/ is invisible to the '
        'strict pattern', () {
      final Map<String, (int, int)> unreadable =
          _idPatternCoverage(_repoRoot());

      // THE TRIPWIRE. `_componentIdPattern` reads the spellings that lint
      // clean here, but it cannot read an id built by concatenation or
      // interpolation, a `static final`, or a getter. Those fail OPEN — the
      // component simply never appears in the scan — which is the one
      // direction this gate must not fail in. Counting a deliberately loose
      // match against the strict one turns that silence into a failure.
      expect(unreadable, isEmpty,
          reason: 'file(s) mention `componentId =` in a form the strict '
              'pattern cannot read (loose vs strict match counts): '
              '${unreadable.entries.map((MapEntry<String, (int, int)> e) => '${e.key} ${e.value.$1} vs ${e.value.$2}').join('; ')}\n'
              'Either write the declaration as a plain literal '
              '(`static const String componentId = \'x/y\';`) or widen '
              '_componentIdPattern — but do NOT delete this case: a style '
              'the scan cannot read is a component that escapes the '
              'partition silently.');
    });

    // Case 2 — the undeclared-component failure mode — is NOT asserted here.
    // It cannot be: proving it requires a component file that is absent from
    // the declaration, and committing one would make case 1 permanently RED.
    // It is proven instead by a DIFFERENTIAL CONTROL run by hand and recorded
    // in the task summary: write a probe component declaring an undeclared
    // id, watch case 1 fail NAMING it, delete the probe, watch it pass. A
    // test that has only ever been seen green proves nothing about what it
    // detects, so the evidence lives in the record rather than nowhere.
  });

  group('manifest', () {
    test('case 5: manifest ids == declared ids, derived not hardcoded', () {
      final Set<String> fromManifest = buildComponentManifestEntries()
          .map((Map<String, Object> e) => e['component_id']! as String)
          .toSet();

      // AGAINST THE SOURCE SCAN, not against kDataDisplayComponents.
      //
      // This compared `fromManifest` to `_declaredIds()`. Both derived from
      // kDataDisplayComponents, so it was the same expression on each side —
      // a tautology with a `map()` in the middle, and the identical defect a
      // review found in PR #58's `expect(resolvedInk,
      // EdenGlyphInk.of(ctx).success)`. All it could detect was a filter or
      // a constant added inside buildComponentManifestEntries's eight lines,
      // and a key rename already fails case 7.
      //
      // Pointed at the scan it closes EMITTER -> SOURCE directly: the
      // artifact a consumer reads is tied to the widgets on disk, and the
      // hand-written declaration becomes a cross-checked third party rather
      // than the single root all five assertions grew from.
      expect(fromManifest, equals(_idsInSource(_repoRoot()).keys.toSet()),
          reason: 'the emitted manifest and kDataDisplayComponents disagree. '
              'buildComponentManifestEntries() must emit exactly the declared '
              'set — no filtering, no additions.');
    });

    test('case 6: entries are sorted by component_id ascending', () {
      final List<String> ids = buildComponentManifestEntries()
          .map((Map<String, Object> e) => e['component_id']! as String)
          .toList();
      final List<String> sorted = List<String>.of(ids)..sort();

      expect(ids, equals(sorted),
          reason: 'emitted order $ids is not sorted. The manifest is '
              'committed/consumed output: unsorted entries make a diff show '
              'declaration-order churn instead of real change.');
    });

    test('case 7: schema is LOCKED — exactly the declared keys, all non-empty',
        () {
      for (final Map<String, Object> entry in buildComponentManifestEntries()) {
        expect(entry.keys.toList(), equals(kComponentManifestKeys),
            reason: 'entry $entry does not carry exactly '
                '$kComponentManifestKeys in that order. The schema is the '
                'contract with the agent side; an extra or renamed key is a '
                'breaking change that must be deliberate.');
        for (final String key in kComponentManifestKeys) {
          final Object? value = entry[key];
          expect(value, isA<String>(),
              reason: '$key in $entry is not a String');
          expect((value! as String).trim(), isNotEmpty,
              reason: '$key in $entry is empty — an entry that names nothing '
                  'is worse than no entry, because it reads as coverage');
        }
      }
    });

    test('case 8: encoded output round-trips and ends with a newline', () {
      final List<Map<String, Object>> entries =
          buildComponentManifestEntries();
      final String encoded = encodeComponentManifest(entries);

      expect(encoded.endsWith('\n'), isTrue,
          reason: 'the manifest must end with a trailing newline, matching '
              'emit_flutter_manifest.dart and the Go side it is read beside');

      final Object? decoded = jsonDecode(encoded);
      expect(decoded, isA<List<Object?>>());
      expect((decoded! as List<Object?>).length, entries.length,
          reason: 'round-trip changed the entry count, so the encoder is '
              'dropping or duplicating entries');
    });
  });
}
