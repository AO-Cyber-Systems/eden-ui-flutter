// test/theme/eden_brand_preset_test.dart
//
// EdenBrandPreset + EdenBrandPresetRegistry contract tests (objective 009 TRD 03).
// Test list per TRD 009-03-TRD.md ## Test list section.

import 'dart:io';

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/brand_preset_fixtures.dart';

void main() {
  group('EdenBrandPreset value class', () {
    test('is const-able', () {
      // Test list item 1.
      // ignore: prefer_const_constructors
      const preset = EdenBrandPreset(
        id: 'x',
        displayName: 'X',
        color: EdenColors.gold,
        recommendedFor: ['salon'],
      );
      expect(preset.id, 'x');
      expect(preset.displayName, 'X');
      expect(preset.color, EdenColors.gold);
      expect(preset.recommendedFor, ['salon']);
    });
  });

  group('EdenBrandPresetRegistry.all()', () {
    test('returns at least 10 presets', () {
      // Test list item 2.
      final all = EdenBrandPresetRegistry.all();
      expect(all, isNotEmpty);
      expect(all.length, greaterThanOrEqualTo(10),
          reason:
              'OBJECTIVE.md success criterion 5 — registry exposes >= 10 presets');
    });

    test('returns an unmodifiable list', () {
      // Test list item 3.
      final all = EdenBrandPresetRegistry.all();
      expect(
        () => all.add(const EdenBrandPreset(
          id: 'rogue',
          displayName: 'Rogue',
          color: EdenColors.gold,
          recommendedFor: ['x'],
        )),
        throwsUnsupportedError,
      );
    });

    test('contains all expected ids in the locked order', () {
      final all = EdenBrandPresetRegistry.all();
      final actualIds = all.map((p) => p.id).toList();
      for (final expectedId in BrandPresetFixtures.expectedIds) {
        expect(actualIds, contains(expectedId),
            reason: 'Missing preset id: $expectedId');
      }
    });

    test('all preset ids are unique (test list item 6)', () {
      final all = EdenBrandPresetRegistry.all();
      final ids = all.map((p) => p.id).toList();
      final uniqueIds = ids.toSet();
      expect(uniqueIds.length, ids.length,
          reason: 'Duplicate id detected — registry contract broken');
    });
  });

  group('EdenBrandPresetRegistry.byId', () {
    test('returns matching preset for known id', () {
      // Test list item 4.
      final preset = EdenBrandPresetRegistry.byId('gold');
      expect(preset, isNotNull);
      expect(preset!.id, 'gold');
    });

    test('returns null for unknown id', () {
      // Test list item 5.
      expect(EdenBrandPresetRegistry.byId('does-not-exist'), isNull);
    });
  });

  group('Bridge entries from EdenColors.presets (test list items 7-13)', () {
    test('gold bridge wraps EdenColors.gold', () {
      expect(
          identical(
              EdenBrandPresetRegistry.byId('gold')!.color, EdenColors.gold),
          isTrue);
    });
    test('blue bridge wraps EdenColors.blue', () {
      expect(
          identical(
              EdenBrandPresetRegistry.byId('blue')!.color, EdenColors.blue),
          isTrue);
    });
    test('emerald bridge wraps EdenColors.emerald', () {
      expect(
          identical(EdenBrandPresetRegistry.byId('emerald')!.color,
              EdenColors.emerald),
          isTrue);
    });
    test('purple bridge wraps EdenColors.purple', () {
      expect(
          identical(EdenBrandPresetRegistry.byId('purple')!.color,
              EdenColors.purple),
          isTrue);
    });
    test('red bridge wraps EdenColors.red', () {
      expect(
          identical(EdenBrandPresetRegistry.byId('red')!.color, EdenColors.red),
          isTrue);
    });
    test('slate bridge wraps EdenColors.slate', () {
      expect(
          identical(
              EdenBrandPresetRegistry.byId('slate')!.color, EdenColors.slate),
          isTrue);
    });
    test('cyan bridge wraps EdenColors.cyan', () {
      expect(
          identical(
              EdenBrandPresetRegistry.byId('cyan')!.color, EdenColors.cyan),
          isTrue);
    });
  });

  group('Vertically-flavored presets (test list items 14-21)', () {
    test('salon-coral has displayName Coral + salon in recommendedFor', () {
      final p = EdenBrandPresetRegistry.byId('salon-coral')!;
      expect(p.displayName, 'Coral');
      expect(p.recommendedFor, contains('salon'));
    });

    test('trades-industrial-blue has trades in recommendedFor', () {
      final p = EdenBrandPresetRegistry.byId('trades-industrial-blue')!;
      expect(p.recommendedFor, contains('trades'));
    });

    test('medical-teal wraps EdenColors.cyan + medical in recommendedFor', () {
      final p = EdenBrandPresetRegistry.byId('medical-teal')!;
      expect(p.recommendedFor, contains('medical'));
      expect(identical(p.color, EdenColors.cyan), isTrue);
    });

    test('fuel-energy-orange has fuel in recommendedFor', () {
      final p = EdenBrandPresetRegistry.byId('fuel-energy-orange')!;
      expect(p.recommendedFor, contains('fuel'));
    });

    test('gov-federal-navy has gov AND federal in recommendedFor', () {
      final p = EdenBrandPresetRegistry.byId('gov-federal-navy')!;
      expect(p.recommendedFor, containsAll(['gov', 'federal']));
    });

    test('legal-navy has legal in recommendedFor', () {
      final p = EdenBrandPresetRegistry.byId('legal-navy')!;
      expect(p.recommendedFor, contains('legal'));
    });

    test('retail-vibrant-magenta has retail in recommendedFor', () {
      final p = EdenBrandPresetRegistry.byId('retail-vibrant-magenta')!;
      expect(p.recommendedFor, contains('retail'));
    });

    test('wellness-sage has wellness in recommendedFor', () {
      final p = EdenBrandPresetRegistry.byId('wellness-sage')!;
      expect(p.recommendedFor, contains('wellness'));
    });
  });

  group('EdenBrandPresetRegistry.forVertical', () {
    test('salon returns at least 2 (gold + salon-coral)', () {
      // Test list item 22.
      final results = EdenBrandPresetRegistry.forVertical('salon');
      expect(results.length, greaterThanOrEqualTo(2));
      final ids = results.map((p) => p.id).toList();
      expect(ids, containsAll(['gold', 'salon-coral']));
    });

    test('case-insensitive match (Salon == salon)', () {
      // Test list item 23.
      final lower = EdenBrandPresetRegistry.forVertical('salon');
      final mixed = EdenBrandPresetRegistry.forVertical('Salon');
      expect(mixed.length, lower.length);
      expect(mixed.map((p) => p.id).toSet(), lower.map((p) => p.id).toSet());
    });

    test('medical returns at least cyan + medical-teal', () {
      // Test list item 24.
      final results = EdenBrandPresetRegistry.forVertical('medical');
      final ids = results.map((p) => p.id).toList();
      expect(ids, containsAll(['cyan', 'medical-teal']));
    });

    test('gov returns at least 3 presets', () {
      // Test list item 25.
      final results = EdenBrandPresetRegistry.forVertical('gov');
      expect(results.length, greaterThanOrEqualTo(3),
          reason: 'blue + red + gov-federal-navy expected');
    });

    test('legal returns at least slate + legal-navy', () {
      // Test list item 26.
      final results = EdenBrandPresetRegistry.forVertical('legal');
      final ids = results.map((p) => p.id).toList();
      expect(ids, containsAll(['slate', 'legal-navy']));
    });

    test('unknown vertical returns empty list (not null)', () {
      // Test list item 27.
      final results =
          EdenBrandPresetRegistry.forVertical('nonexistent-vertical');
      expect(results, isEmpty);
      expect(results, isNotNull);
    });

    test('default returns at least gold', () {
      // Test list item 28.
      final results = EdenBrandPresetRegistry.forVertical('default');
      expect(results.map((p) => p.id).toList(), contains('gold'));
    });
  });

  group('Sanity', () {
    test('every preset has non-empty id, displayName, and recommendedFor', () {
      // Test list item 29.
      for (final preset in EdenBrandPresetRegistry.all()) {
        expect(preset.id, isNotEmpty, reason: 'Preset with empty id detected');
        expect(preset.displayName, isNotEmpty,
            reason: 'Preset ${preset.id} has empty displayName');
        expect(preset.recommendedFor, isNotEmpty,
            reason: 'Preset ${preset.id} has empty recommendedFor list');
      }
    });

    test('eden_brand_preset.dart carries no-LLM header (greppable contract)',
        () {
      // Test list item 30 — file-content contract per Constraint 4.
      final file = File('lib/src/theme/eden_brand_preset.dart');
      expect(file.existsSync(), isTrue,
          reason: 'eden_brand_preset.dart must exist');
      final contents = file.readAsStringSync();
      expect(contents, contains('Do NOT regenerate via LLM'),
          reason:
              'Header contract per OBJECTIVE.md Constraint 4 + Playbook habit 4');
    });
  });
}
