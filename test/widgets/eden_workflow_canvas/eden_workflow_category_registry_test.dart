import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EdenWorkflowCategoryRegistry', () {
    setUp(() {
      EdenWorkflowCategoryRegistry.instance.resetToDefaults();
    });

    test('singleton — instance returns same instance across calls', () {
      final a = EdenWorkflowCategoryRegistry.instance;
      final b = EdenWorkflowCategoryRegistry.instance;
      expect(identical(a, b), isTrue);
    });

    test('resetToDefaults registers exactly 5 defaults', () {
      EdenWorkflowCategoryRegistry.instance.resetToDefaults();
      expect(EdenWorkflowCategoryRegistry.instance.all().length, 5);
    });

    test('all 5 default ids present after resetToDefaults', () {
      final ids = EdenWorkflowCategoryRegistry.instance
          .all()
          .map((c) => c.id)
          .toSet();
      expect(ids, {'appointment', 'task', 'project', 'customer', 'callback'});
    });

    test('lookup("appointment") returns non-null with displayName + icon', () {
      final cat = EdenWorkflowCategoryRegistry.instance.lookup('appointment');
      expect(cat, isNotNull);
      expect(cat!.displayName, 'Appointment');
      expect(cat.icon, isA<IconData>());
    });

    test('lookup("task") returns task category', () {
      final cat = EdenWorkflowCategoryRegistry.instance.lookup('task');
      expect(cat?.displayName, 'Task');
    });

    test('register adds new category and lookup returns it', () {
      const visit = EdenWorkflowCategory(
        id: 'visit',
        displayName: 'Patient Visit',
        icon: Icons.local_hospital,
      );
      EdenWorkflowCategoryRegistry.instance.register(visit);
      expect(EdenWorkflowCategoryRegistry.instance.lookup('visit'), visit);
      expect(EdenWorkflowCategoryRegistry.instance.all().length, 6);
    });

    test('register called twice with same id throws StateError', () {
      const visit = EdenWorkflowCategory(
        id: 'visit',
        displayName: 'Patient Visit',
        icon: Icons.local_hospital,
      );
      EdenWorkflowCategoryRegistry.instance.register(visit);
      expect(
        () => EdenWorkflowCategoryRegistry.instance.register(visit),
        throwsA(isA<StateError>()),
      );
    });

    test('register throws on duplicate default id (must reset first)', () {
      const dup = EdenWorkflowCategory(
        id: 'appointment',
        displayName: 'Custom Appointment',
        icon: Icons.event_available,
      );
      expect(
        () => EdenWorkflowCategoryRegistry.instance.register(dup),
        throwsA(isA<StateError>()),
      );
    });

    test('lookup returns null for nonexistent id', () {
      expect(
        EdenWorkflowCategoryRegistry.instance.lookup('nonexistent'),
        isNull,
      );
    });

    test('reset clears everything (no defaults)', () {
      EdenWorkflowCategoryRegistry.instance.reset();
      expect(EdenWorkflowCategoryRegistry.instance.all(), isEmpty);
    });

    test('resetToDefaults re-registers the 5 defaults exactly', () {
      EdenWorkflowCategoryRegistry.instance.reset();
      expect(EdenWorkflowCategoryRegistry.instance.all(), isEmpty);
      EdenWorkflowCategoryRegistry.instance.resetToDefaults();
      expect(EdenWorkflowCategoryRegistry.instance.all().length, 5);
      final ids = EdenWorkflowCategoryRegistry.instance
          .all()
          .map((c) => c.id)
          .toSet();
      expect(ids, {'appointment', 'task', 'project', 'customer', 'callback'});
    });

    test('all() returns unmodifiable snapshot', () {
      final list = EdenWorkflowCategoryRegistry.instance.all();
      expect(
        () => list.add(const EdenWorkflowCategory(
          id: 'x',
          displayName: 'X',
          icon: Icons.abc,
        )),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('EdenWorkflowCategory equality by id', () {
      const a = EdenWorkflowCategory(
        id: 'visit',
        displayName: 'Patient Visit',
        icon: Icons.local_hospital,
      );
      const b = EdenWorkflowCategory(
        id: 'visit',
        displayName: 'Different label',
        icon: Icons.medical_services,
      );
      expect(a, equals(b)); // id-only equality
      expect(a.hashCode, b.hashCode);
    });
  });
}
