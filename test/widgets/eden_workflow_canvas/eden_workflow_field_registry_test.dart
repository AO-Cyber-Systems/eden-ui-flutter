import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_workflow_node_fixtures.dart';

void main() {
  group('EdenWorkflowFieldRegistry', () {
    setUp(() {
      EdenWorkflowFieldRegistry.instance.reset();
    });

    test('singleton instance', () {
      final a = EdenWorkflowFieldRegistry.instance;
      final b = EdenWorkflowFieldRegistry.instance;
      expect(identical(a, b), isTrue);
    });

    test('ships EMPTY by default (no defaults)', () {
      expect(EdenWorkflowFieldRegistry.instance.all(), isEmpty);
    });

    test('register adds field and lookup returns it', () {
      final f = customerNameFieldFixture();
      EdenWorkflowFieldRegistry.instance.register(f);
      expect(EdenWorkflowFieldRegistry.instance.lookup('customer.name'), f);
    });

    test('byCategory filters by category id', () {
      EdenWorkflowFieldRegistry.instance
          .register(customerNameFieldFixture()); // appointment
      EdenWorkflowFieldRegistry.instance
          .register(appointmentStartFieldFixture()); // appointment
      EdenWorkflowFieldRegistry.instance
          .register(taskPriorityFieldFixture()); // task

      final appointmentFields =
          EdenWorkflowFieldRegistry.instance.byCategory('appointment');
      expect(appointmentFields.length, 2);
      final ids = appointmentFields.map((f) => f.name).toSet();
      expect(ids, {'customer.name', 'start_time'});
    });

    test('search matches name or label case-insensitively', () {
      EdenWorkflowFieldRegistry.instance.register(customerNameFieldFixture());
      EdenWorkflowFieldRegistry.instance.register(customerEmailFieldFixture());
      EdenWorkflowFieldRegistry.instance.register(taskPriorityFieldFixture());

      final results = EdenWorkflowFieldRegistry.instance.search('CUST');
      expect(results.length, 2);
      expect(results.map((f) => f.name).toSet(),
          {'customer.name', 'customer.email'});
    });

    test('search filters by categoryId when provided', () {
      EdenWorkflowFieldRegistry.instance.register(customerNameFieldFixture());
      EdenWorkflowFieldRegistry.instance.register(taskPriorityFieldFixture());

      final results = EdenWorkflowFieldRegistry.instance
          .search('', categoryId: 'task');
      expect(results.length, 1);
      expect(results[0].name, 'priority');
    });

    test('register duplicate name throws StateError', () {
      EdenWorkflowFieldRegistry.instance.register(customerNameFieldFixture());
      expect(
        () => EdenWorkflowFieldRegistry.instance
            .register(customerNameFieldFixture()),
        throwsA(isA<StateError>()),
      );
    });

    test('reset clears the registry', () {
      EdenWorkflowFieldRegistry.instance.register(customerNameFieldFixture());
      EdenWorkflowFieldRegistry.instance.reset();
      expect(EdenWorkflowFieldRegistry.instance.all(), isEmpty);
    });

    test('lookup returns null for unregistered name', () {
      expect(
        EdenWorkflowFieldRegistry.instance.lookup('nonexistent'),
        isNull,
      );
    });

    test('EdenWorkflowField equality by name', () {
      const a = EdenWorkflowField(
        name: 'x',
        label: 'X',
        type: 'string',
        category: 'task',
      );
      const b = EdenWorkflowField(
        name: 'x',
        label: 'Different',
        type: 'number',
        category: 'appointment',
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
