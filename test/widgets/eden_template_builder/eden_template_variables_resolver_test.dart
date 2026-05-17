// Do NOT regenerate via LLM — hand-built tests for EdenTemplateVariablesResolver.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EdenTemplateVariablesResolver.resolve — happy paths', () {
    test('simple token substitution', () {
      final out = EdenTemplateVariablesResolver.resolve(
        'Hello {{customer.name}}',
        const {
          'customer': {'name': 'Mark'},
        },
      );
      expect(out, 'Hello Mark');
    });

    test('multiple tokens', () {
      final out = EdenTemplateVariablesResolver.resolve(
        'Hi {{user.first}} {{user.last}}',
        const {
          'user': {'first': 'A', 'last': 'B'},
        },
      );
      expect(out, 'Hi A B');
    });

    test('nested dotted path', () {
      final out = EdenTemplateVariablesResolver.resolve(
        '{{a.b.c}}',
        const {
          'a': {
            'b': {'c': 'deep'},
          },
        },
      );
      expect(out, 'deep');
    });

    test('tolerates whitespace inside {{ }}', () {
      final out = EdenTemplateVariablesResolver.resolve(
        '{{ customer.name }}',
        const {
          'customer': {'name': 'Mark'},
        },
      );
      expect(out, 'Mark');
    });

    test('numeric value substitution (toString)', () {
      final out = EdenTemplateVariablesResolver.resolve(
        'Total: {{invoice.total}}',
        const {
          'invoice': {'total': 100.50},
        },
      );
      // Dart strips trailing zero in double.toString → '100.5'.
      expect(out, contains('100.5'));
    });

    test('integer value substitution', () {
      final out = EdenTemplateVariablesResolver.resolve(
        '{{order.count}}',
        const {
          'order': {'count': 42},
        },
      );
      expect(out, '42');
    });
  });

  group('EdenTemplateVariablesResolver.resolve — edge cases', () {
    test('no tokens — input unchanged', () {
      final out = EdenTemplateVariablesResolver.resolve(
        'Static text only.',
        const {'anything': 'ignored'},
      );
      expect(out, 'Static text only.');
    });

    test('empty input', () {
      expect(
        EdenTemplateVariablesResolver.resolve('', const {}),
        '',
      );
    });

    test('non-identifier token characters — regex does not match', () {
      final out = EdenTemplateVariablesResolver.resolve(
        'Bad {{not-an-identifier!@#}}',
        const {},
      );
      expect(out, 'Bad {{not-an-identifier!@#}}');
    });
  });

  group('EdenTemplateVariablesResolver.resolve — missing tokens', () {
    test('default behaviour — empty placeholder', () {
      final out = EdenTemplateVariablesResolver.resolve(
        'Hello {{customer.name}}',
        const {},
      );
      expect(out, 'Hello ');
    });

    test('custom placeholder', () {
      final out = EdenTemplateVariablesResolver.resolve(
        'Hello {{customer.name}}',
        const {},
        missingPlaceholder: '???',
      );
      expect(out, 'Hello ???');
    });

    test('throwOnMissing throws EdenTemplateMissingVariableException', () {
      expect(
        () => EdenTemplateVariablesResolver.resolve(
          'Hello {{customer.name}}',
          const {},
          throwOnMissing: true,
        ),
        throwsA(
          isA<EdenTemplateMissingVariableException>()
              .having((e) => e.path, 'path', 'customer.name'),
        ),
      );
    });

    test('null intermediate is treated as missing', () {
      final out = EdenTemplateVariablesResolver.resolve(
        'Hello {{customer.name}}',
        const {'customer': null},
      );
      expect(out, 'Hello ');
    });

    test('null intermediate with throwOnMissing throws', () {
      expect(
        () => EdenTemplateVariablesResolver.resolve(
          'Hello {{customer.name}}',
          const {'customer': null},
          throwOnMissing: true,
        ),
        throwsA(isA<EdenTemplateMissingVariableException>()),
      );
    });

    test('non-map intermediate is treated as missing', () {
      final out = EdenTemplateVariablesResolver.resolve(
        '{{user.name.first}}',
        const {
          'user': {'name': 'Mark'},
        },
      );
      // 'name' is a String — walking past it returns null.
      expect(out, '');
    });
  });
}
