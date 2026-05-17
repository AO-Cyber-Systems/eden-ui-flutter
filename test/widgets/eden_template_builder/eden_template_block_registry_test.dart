// Do NOT regenerate via LLM — hand-built tests for EdenTemplateBlockRegistry.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    EdenTemplateBlockRegistry.instance.resetToDefaults();
    EdenTemplateVariablesRegistry.instance.reset();
  });

  group('EdenTemplateBlockRegistry singleton', () {
    test('instance returns the same object across calls', () {
      final a = EdenTemplateBlockRegistry.instance;
      final b = EdenTemplateBlockRegistry.instance;
      expect(identical(a, b), isTrue);
    });
  });

  group('default 12 block descriptors after resetToDefaults', () {
    test('all().length == 12', () {
      expect(EdenTemplateBlockRegistry.instance.all().length, 12);
    });

    test('default ids include text, field, table, list, photoGrid, signature, '
        'divider, spacer, image, qrCode, conditional, repeater', () {
      final ids =
          EdenTemplateBlockRegistry.instance.all().map((d) => d.id).toSet();
      expect(ids, {
        'text',
        'field',
        'table',
        'list',
        'photoGrid',
        'signature',
        'divider',
        'spacer',
        'image',
        'qrCode',
        'conditional',
        'repeater',
      });
    });

    test('text descriptor has displayName / icon / category', () {
      final t = EdenTemplateBlockRegistry.instance.lookup('text');
      expect(t, isNotNull);
      expect(t!.displayName, 'Text');
      expect(t.icon, Icons.text_fields);
      expect(t.category, 'Content');
      expect(t.isAdvanced, isFalse);
    });

    test('conditional descriptor is Advanced category + isAdvanced=true', () {
      final c = EdenTemplateBlockRegistry.instance.lookup('conditional');
      expect(c, isNotNull);
      expect(c!.category, 'Advanced');
      expect(c.isAdvanced, isTrue);
    });

    test('repeater descriptor is Advanced category + isAdvanced=true', () {
      final r = EdenTemplateBlockRegistry.instance.lookup('repeater');
      expect(r, isNotNull);
      expect(r!.category, 'Advanced');
      expect(r.isAdvanced, isTrue);
    });

    test('byCategory(Content) has 10 entries', () {
      expect(
        EdenTemplateBlockRegistry.instance.byCategory('Content').length,
        10,
      );
    });

    test('byCategory(Advanced) has 2 entries', () {
      expect(
        EdenTemplateBlockRegistry.instance.byCategory('Advanced').length,
        2,
      );
    });

    test('byCategory(Unknown) returns empty list', () {
      expect(
        EdenTemplateBlockRegistry.instance.byCategory('Unknown'),
        isEmpty,
      );
    });
  });

  group('lookup', () {
    test('lookup(nonexistent) returns null', () {
      expect(
        EdenTemplateBlockRegistry.instance.lookup('nonexistent'),
        isNull,
      );
    });
  });

  group('register', () {
    test('adds a new descriptor', () {
      const desc = EdenTemplateBlockDescriptor(
        id: 'payment_line',
        displayName: 'Payment Line',
        description: 'Receipt payment row',
        icon: Icons.attach_money,
        category: 'Commerce',
      );
      EdenTemplateBlockRegistry.instance.register(desc);
      expect(
        EdenTemplateBlockRegistry.instance.lookup('payment_line'),
        equals(desc),
      );
      expect(
        EdenTemplateBlockRegistry.instance.byCategory('Commerce').length,
        1,
      );
    });

    test('overwrites by id', () {
      const a = EdenTemplateBlockDescriptor(
        id: 'custom',
        displayName: 'First',
        description: 'first',
        icon: Icons.star,
        category: 'Custom',
      );
      const b = EdenTemplateBlockDescriptor(
        id: 'custom',
        displayName: 'Second',
        description: 'second',
        icon: Icons.star,
        category: 'Custom',
      );
      EdenTemplateBlockRegistry.instance.register(a);
      EdenTemplateBlockRegistry.instance.register(b);
      expect(
        EdenTemplateBlockRegistry.instance.lookup('custom')!.displayName,
        'Second',
      );
    });
  });

  group('reset / resetToDefaults', () {
    test('reset clears all entries', () {
      EdenTemplateBlockRegistry.instance.reset();
      expect(EdenTemplateBlockRegistry.instance.all(), isEmpty);
    });

    test('resetToDefaults re-registers the 12 defaults', () {
      EdenTemplateBlockRegistry.instance.reset();
      EdenTemplateBlockRegistry.instance.resetToDefaults();
      expect(EdenTemplateBlockRegistry.instance.all().length, 12);
    });
  });
}
