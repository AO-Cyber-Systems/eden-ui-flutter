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

/// Where the data-display components live, relative to the package root.
const String _kComponentDir = 'lib/src/widgets/eden_data_display';

/// Matches `static const String componentId = '<id>';`.
///
/// TEXTUAL, not a Dart parse — so a COMMENTED-OUT declaration is a false
/// positive. That is the same trade `tool/gen_design_md.dart` already makes
/// and it is stated rather than hidden: the alternative is a Dart parser,
/// which is a great deal of machinery to guard a directory of this size, and
/// a parser has its own silent-failure modes. A false positive here fails
/// LOUDLY (an id in source with no declaration), which is the safe direction.
final RegExp _componentIdPattern =
    RegExp(r"static\s+const\s+String\s+componentId\s*=\s*'([^']*)'\s*;");

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

/// Every `component_id` declared in source under [_kComponentDir], mapped to
/// the file that declares it (for failure messages that name a path).
Map<String, String> _idsInSource(String root) {
  final Directory dir = Directory('$root/$_kComponentDir');
  if (!dir.existsSync()) {
    fail('$_kComponentDir does not exist. If the components moved, this '
        'whole gate is vacuous and every case below would pass trivially.');
  }
  final Map<String, String> found = <String, String>{};
  for (final File file in dir
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))) {
    final String source = file.readAsStringSync();
    for (final RegExpMatch m in _componentIdPattern.allMatches(source)) {
      found[m.group(1)!] = file.uri.pathSegments.last;
    }
  }
  return found;
}

Set<String> _declaredIds() =>
    kDataDisplayComponents.map(((String, Type) e) => e.$1).toSet();

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
      final Map<String, String> inSource = _idsInSource(_repoRoot());
      final Set<String> declared = _declaredIds();

      final Set<String> undeclared =
          inSource.keys.toSet().difference(declared);
      expect(undeclared, isEmpty,
          reason: 'component_id(s) declared in source but missing from '
              'kDataDisplayComponents: '
              '${undeclared.map((String id) => '$id (${inSource[id]})').join(', ')}\n'
              'A component the manifest does not name is a surface the agent '
              'will be told this package cannot render, while the widget sits '
              'right there. Add it to kDataDisplayComponents in '
              'lib/src/widgets/eden_data_display/eden_data_display_exports.dart '
              'as `(TheWidget.componentId, TheWidget)` — reference the '
              'STATIC, never a re-typed string literal.');
    });

    test('case 3 (ghost): every declared entry still exists in source', () {
      final Map<String, String> inSource = _idsInSource(_repoRoot());

      final Set<String> ghosts = _declaredIds().difference(inSource.keys.toSet());
      expect(ghosts, isEmpty,
          reason: 'kDataDisplayComponents names component_id(s) that no '
              'source file declares: ${ghosts.join(', ')}. A component was '
              'renamed or deleted without updating the declaration, so the '
              'manifest promises the agent a surface that no longer exists.');
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

      // DERIVED on both sides. A hardcoded `{'list/appointments',
      // 'error/refusal'}` would need editing every time a component lands,
      // and would pass while asserting nothing about the emitter.
      expect(fromManifest, equals(_declaredIds()),
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
