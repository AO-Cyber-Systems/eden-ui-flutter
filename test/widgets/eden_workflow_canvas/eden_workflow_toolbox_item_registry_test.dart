import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EdenWorkflowToolboxItemRegistry', () {
    setUp(() {
      EdenWorkflowToolboxItemRegistry.instance.resetToDefaults();
    });

    test('singleton instance', () {
      final a = EdenWorkflowToolboxItemRegistry.instance;
      final b = EdenWorkflowToolboxItemRegistry.instance;
      expect(identical(a, b), isTrue);
    });

    test('resetToDefaults registers 18 default items (5 trig + 3 cond + 6 act + 4 flow)', () {
      // TRD 020-07 originally said 19; actual category sum is 18
      // (5 triggers + 3 conditions + 6 actions + 4 flow). Per-category
      // counts are authoritative per must-haves.
      expect(EdenWorkflowToolboxItemRegistry.instance.all().length, 18);
    });

    test('5 triggers', () {
      expect(
        EdenWorkflowToolboxItemRegistry.instance.byCategory('trigger').length,
        5,
      );
    });

    test('3 conditions', () {
      expect(
        EdenWorkflowToolboxItemRegistry.instance
            .byCategory('condition')
            .length,
        3,
      );
    });

    test('6 actions', () {
      expect(
        EdenWorkflowToolboxItemRegistry.instance.byCategory('action').length,
        6,
      );
    });

    test('4 flow control items', () {
      expect(
        EdenWorkflowToolboxItemRegistry.instance.byCategory('flow').length,
        4,
      );
    });

    test('lookup returns the item by id', () {
      final t =
          EdenWorkflowToolboxItemRegistry.instance.lookup('action-email');
      expect(t?.label, 'Send Email');
      expect(t?.nodeType, 'action');
    });

    test('register custom item + reset clears', () {
      EdenWorkflowToolboxItemRegistry.instance.reset();
      expect(EdenWorkflowToolboxItemRegistry.instance.all(), isEmpty);
      EdenWorkflowToolboxItemRegistry.instance.register(
        const EdenWorkflowToolboxItem(
          id: 'custom',
          nodeType: 'action',
          label: 'Custom',
          icon: Icons.bolt,
          description: 'desc',
          category: 'action',
        ),
      );
      expect(EdenWorkflowToolboxItemRegistry.instance.all().length, 1);
    });

    test('register duplicate throws', () {
      expect(
        () => EdenWorkflowToolboxItemRegistry.instance.register(
          const EdenWorkflowToolboxItem(
            id: 'action-email',
            nodeType: 'action',
            label: 'Dup',
            icon: Icons.email,
            description: '',
            category: 'action',
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
