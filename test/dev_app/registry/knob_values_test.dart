// test/dev_app/registry/knob_values_test.dart
//
// TDD RED phase: unit tests for KnobValues immutable typed value bag.
// These tests are written FIRST, before any implementation exists.

import 'package:eden_ui_flutter/dev_app/registry/knob_values.dart';
import 'package:flutter_test/flutter_test.dart';

// Private test enum — only used in tests
enum _TestVariant { b, c }

void main() {
  group('KnobValues', () {
    test('get<T> reified — returns typed enum value', () {
      final knobs = KnobValues({'v': _TestVariant.b});
      expect(knobs.get<_TestVariant>('v'), equals(_TestVariant.b));
    });

    test('get<bool> returns stored bool', () {
      final knobs = KnobValues({'flag': true});
      expect(knobs.get<bool>('flag'), isTrue);
    });

    test('copyWith returns NEW bag with updated value', () {
      final original = KnobValues({'v': _TestVariant.b});
      final updated = original.copyWith('v', _TestVariant.c);
      expect(updated.get<_TestVariant>('v'), equals(_TestVariant.c));
    });

    test('copyWith leaves original unchanged', () {
      final original = KnobValues({'v': _TestVariant.b});
      original.copyWith('v', _TestVariant.c);
      expect(original.get<_TestVariant>('v'), equals(_TestVariant.b));
    });

    test('copyWith preserves other keys', () {
      final original = KnobValues({'v': _TestVariant.b, 'flag': false});
      final updated = original.copyWith('v', _TestVariant.c);
      expect(updated.get<bool>('flag'), isFalse);
    });
  });
}
