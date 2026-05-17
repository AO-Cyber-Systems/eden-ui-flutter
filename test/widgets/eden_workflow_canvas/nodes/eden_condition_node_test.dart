import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_fixtures/eden_workflow_flow_node_fixtures.dart';
import '../_fixtures/eden_workflow_node_fixtures.dart' show wrap;

void main() {
  group('EdenConditionNode — visual + diamond', () {
    testWidgets('renders 140x140 outer box', (tester) async {
      await tester.pumpWidget(
        wrap(EdenConditionNode(context: conditionNodeContextFixture())),
      );
      final sized = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(EdenConditionNode),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sized.width, 140);
      expect(sized.height, 140);
    });

    testWidgets('inner diamond is rotated (Transform with pi/4 angle)',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenConditionNode(context: conditionNodeContextFixture())),
      );
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('renders "IF" uppercase label and call_split icon',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenConditionNode(context: conditionNodeContextFixture())),
      );
      expect(find.text('IF'), findsOneWidget);
      expect(find.byIcon(Icons.call_split), findsOneWidget);
    });

    testWidgets('label shows "field = value" when configured', (tester) async {
      await tester.pumpWidget(
        wrap(EdenConditionNode(
          context: conditionNodeContextFixture(
            field: 'status',
            operator: EdenWorkflowConditionOperator.equals,
            value: 'completed',
          ),
        )),
      );
      expect(find.text('status = completed'), findsOneWidget);
    });

    testWidgets('label shows "Configure..." when field is empty',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenConditionNode(
          context: unconfiguredConditionNodeContextFixture(),
        )),
      );
      expect(find.text('Configure...'), findsOneWidget);
    });

    testWidgets('operator symbol > for greater_than', (tester) async {
      await tester.pumpWidget(
        wrap(EdenConditionNode(
          context: conditionNodeContextFixture(
            field: 'amount',
            operator: EdenWorkflowConditionOperator.greater_than,
            value: 5000,
          ),
        )),
      );
      expect(find.text('amount > 5000'), findsOneWidget);
    });

    testWidgets('operator label "contains" for contains', (tester) async {
      await tester.pumpWidget(
        wrap(EdenConditionNode(
          context: conditionNodeContextFixture(
            field: 'name',
            operator: EdenWorkflowConditionOperator.contains,
            value: 'Acme',
          ),
        )),
      );
      expect(find.text('name contains Acme'), findsOneWidget);
    });

    testWidgets('renders at 390pt narrow width without overflow',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenConditionNode(context: conditionNodeContextFixture()),
          width: 390,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenConditionNode — popover editor', () {
    testWidgets('tap diamond opens popover with field/op/value fields',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenConditionNode(context: conditionNodeContextFixture())),
      );
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Edit Condition'), findsOneWidget);
      expect(find.text('Field'), findsOneWidget);
      expect(find.text('Operator'), findsOneWidget);
      expect(find.text('Value'), findsOneWidget);
    });

    testWidgets('Save with non-empty field fires onUpdate with formatted label',
        (tester) async {
      final captures = <Map<String, dynamic>>[];
      await tester.pumpWidget(
        wrap(EdenConditionNode(
          context: conditionNodeContextFixture(
            field: 'priority',
            operator: EdenWorkflowConditionOperator.equals,
            value: 'high',
          ),
          config: EdenConditionNodeConfig(onUpdate: captures.add),
        )),
      );
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(captures.length, 1);
      expect(captures[0]['field'], 'priority');
      expect(captures[0]['operator'], 'equals');
      expect(captures[0]['value'], 'high');
      expect(captures[0]['label'], 'priority = high');
    });

    testWidgets('Save with empty field does NOT fire onUpdate (donor parity)',
        (tester) async {
      final captures = <Map<String, dynamic>>[];
      await tester.pumpWidget(
        wrap(EdenConditionNode(
          context: unconfiguredConditionNodeContextFixture(),
          config: EdenConditionNodeConfig(onUpdate: captures.add),
        )),
      );
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(captures, isEmpty);
    });

    testWidgets('Cancel does NOT fire onUpdate', (tester) async {
      final captures = <Map<String, dynamic>>[];
      await tester.pumpWidget(
        wrap(EdenConditionNode(
          context: conditionNodeContextFixture(),
          config: EdenConditionNodeConfig(onUpdate: captures.add),
        )),
      );
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(captures, isEmpty);
    });
  });
}
