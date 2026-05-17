import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_fixtures/eden_workflow_node_fixtures.dart';

void main() {
  setUp(() {
    EdenWorkflowFieldRegistry.instance.reset();
  });

  group('EdenWorkflowEventBrowser', () {
    testWidgets('renders empty state when registry is empty', (tester) async {
      await tester.pumpWidget(
        wrap(EdenWorkflowEventBrowser(onFieldSelected: (_) {})),
      );
      expect(find.text('No fields available'), findsOneWidget);
    });

    testWidgets('renders categorized sections when fields registered',
        (tester) async {
      EdenWorkflowFieldRegistry.instance.register(customerNameFieldFixture());
      EdenWorkflowFieldRegistry.instance
          .register(appointmentStartFieldFixture());
      EdenWorkflowFieldRegistry.instance.register(taskPriorityFieldFixture());

      await tester.pumpWidget(
        wrap(EdenWorkflowEventBrowser(onFieldSelected: (_) {})),
      );
      await tester.pumpAndSettle();

      // Two categories: APPOINTMENT (2 fields) + TASK (1 field)
      expect(find.text('APPOINTMENT'), findsOneWidget);
      expect(find.text('TASK'), findsOneWidget);
    });

    testWidgets('tapping a category expands the field list', (tester) async {
      EdenWorkflowFieldRegistry.instance.register(customerNameFieldFixture());

      await tester.pumpWidget(
        wrap(EdenWorkflowEventBrowser(onFieldSelected: (_) {})),
      );
      // Initially not expanded — field name not visible
      expect(find.text('customer.name'), findsNothing);
      await tester.tap(find.text('APPOINTMENT'));
      await tester.pumpAndSettle();
      expect(find.text('customer.name'), findsOneWidget);
    });

    testWidgets('tapping a field fires onFieldSelected with the field',
        (tester) async {
      EdenWorkflowFieldRegistry.instance.register(customerNameFieldFixture());
      final captures = <EdenWorkflowField>[];

      await tester.pumpWidget(
        wrap(EdenWorkflowEventBrowser(
          onFieldSelected: captures.add,
          initialCategoryId: 'appointment',
        )),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('customer.name'));
      await tester.pumpAndSettle();

      expect(captures.length, 1);
      expect(captures[0].name, 'customer.name');
    });

    testWidgets('typing in search filters the visible field list',
        (tester) async {
      EdenWorkflowFieldRegistry.instance.register(customerNameFieldFixture());
      EdenWorkflowFieldRegistry.instance
          .register(appointmentStartFieldFixture());
      EdenWorkflowFieldRegistry.instance.register(taskPriorityFieldFixture());

      await tester.pumpWidget(
        wrap(EdenWorkflowEventBrowser(
          onFieldSelected: (_) {},
          initialCategoryId: 'appointment',
        )),
      );
      await tester.enterText(find.byType(TextField), 'cust');
      await tester.pumpAndSettle();
      // Only APPOINTMENT category contains 'cust' matches.
      expect(find.text('APPOINTMENT'), findsOneWidget);
      expect(find.text('TASK'), findsNothing);
    });

    testWidgets('renders at popover width (320pt) without overflow',
        (tester) async {
      EdenWorkflowFieldRegistry.instance.register(customerNameFieldFixture());
      await tester.pumpWidget(
        wrap(
          EdenWorkflowEventBrowser(
            onFieldSelected: (_) {},
            initialCategoryId: 'appointment',
          ),
          width: 320,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('displays type badge for each field', (tester) async {
      EdenWorkflowFieldRegistry.instance
          .register(appointmentStartFieldFixture()); // date
      EdenWorkflowFieldRegistry.instance
          .register(projectBudgetFieldFixture()); // number

      await tester.pumpWidget(
        wrap(EdenWorkflowEventBrowser(onFieldSelected: (_) {})),
      );
      await tester.tap(find.text('APPOINTMENT'));
      await tester.pumpAndSettle();
      expect(find.text('date'), findsOneWidget);
    });
  });
}
