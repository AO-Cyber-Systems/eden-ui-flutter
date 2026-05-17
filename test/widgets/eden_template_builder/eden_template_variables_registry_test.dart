// Do NOT regenerate via LLM — hand-built tests for EdenTemplateVariablesRegistry.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    EdenTemplateBlockRegistry.instance.resetToDefaults();
    EdenTemplateVariablesRegistry.instance.reset();
  });

  group('EdenTemplateVariablesRegistry singleton', () {
    test('instance returns the same object across calls', () {
      final a = EdenTemplateVariablesRegistry.instance;
      final b = EdenTemplateVariablesRegistry.instance;
      expect(identical(a, b), isTrue);
    });

    test('ships EMPTY after reset', () {
      expect(EdenTemplateVariablesRegistry.instance.all(), isEmpty);
    });
  });

  group('register / lookup', () {
    test('register a single group with fields', () {
      EdenTemplateVariablesRegistry.instance
          .register('customer', const ['name', 'email', 'phone']);
      expect(
        EdenTemplateVariablesRegistry.instance.lookup('customer'),
        const ['name', 'email', 'phone'],
      );
    });

    test('register on existing group APPENDS (does not replace)', () {
      EdenTemplateVariablesRegistry.instance
          .register('customer', const ['name', 'email', 'phone']);
      EdenTemplateVariablesRegistry.instance
          .register('customer', const ['address']);
      expect(
        EdenTemplateVariablesRegistry.instance.lookup('customer'),
        const ['name', 'email', 'phone', 'address'],
      );
    });

    test('lookup(unknown) returns null', () {
      expect(
        EdenTemplateVariablesRegistry.instance.lookup('unknown'),
        isNull,
      );
    });
  });

  group('all / groups', () {
    test('all returns Map<String, List<String>> with all groups', () {
      EdenTemplateVariablesRegistry.instance
          .register('customer', const ['name']);
      EdenTemplateVariablesRegistry.instance
          .register('invoice', const ['total']);
      final all = EdenTemplateVariablesRegistry.instance.all();
      expect(all.keys.toSet(), {'customer', 'invoice'});
      expect(all['customer'], const ['name']);
      expect(all['invoice'], const ['total']);
    });

    test('groups returns sorted group names', () {
      EdenTemplateVariablesRegistry.instance.register('zeta', const ['z']);
      EdenTemplateVariablesRegistry.instance.register('alpha', const ['a']);
      EdenTemplateVariablesRegistry.instance.register('mu', const ['m']);
      expect(
        EdenTemplateVariablesRegistry.instance.groups(),
        const ['alpha', 'mu', 'zeta'],
      );
    });
  });

  group('reset', () {
    test('reset clears all entries', () {
      EdenTemplateVariablesRegistry.instance
          .register('customer', const ['name']);
      EdenTemplateVariablesRegistry.instance.reset();
      expect(EdenTemplateVariablesRegistry.instance.all(), isEmpty);
    });
  });
}
