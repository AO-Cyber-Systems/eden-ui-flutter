import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_fixtures/eden_workflow_node_fixtures.dart';

void main() {
  setUp(() {
    EdenWorkflowCategoryRegistry.instance.resetToDefaults();
  });

  group('EdenTriggerNode — visual', () {
    testWidgets('renders without exception', (tester) async {
      await tester.pumpWidget(
        wrap(EdenTriggerNode(context: triggerNodeContextFixture())),
      );
      expect(find.byType(EdenTriggerNode), findsOneWidget);
    });

    testWidgets('renders "TRIGGER" uppercase label', (tester) async {
      await tester.pumpWidget(
        wrap(EdenTriggerNode(context: triggerNodeContextFixture())),
      );
      expect(find.text('TRIGGER'), findsOneWidget);
    });

    testWidgets('renders trigger-type-specific label and icon for entity_created',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenTriggerNode(
          context: triggerNodeContextFixture(
            triggerType: EdenWorkflowTriggerType.entity_created,
          ),
        )),
      );
      expect(find.text('Entity Created'), findsOneWidget);
      expect(find.byIcon(Icons.bolt), findsOneWidget);
    });

    testWidgets('renders trigger-type-specific icon for scheduled',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenTriggerNode(
          context: triggerNodeContextFixture(
            triggerType: EdenWorkflowTriggerType.scheduled,
          ),
        )),
      );
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.text('On Schedule'), findsOneWidget);
    });

    testWidgets('renders category subtitle from registry lookup',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenTriggerNode(
          context: triggerNodeContextFixture(category: 'task'),
        )),
      );
      expect(find.text('Task'), findsOneWidget);
    });

    testWidgets('renders selection ring when ctx.selected == true',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenTriggerNode(
          context: triggerNodeContextFixture(selected: true),
        )),
      );
      // Find the outer Container with BoxDecoration border
      final container = tester.widget<Container>(find
          .descendant(
            of: find.byType(InkWell),
            matching: find.byType(Container),
          )
          .first);
      final decoration = container.decoration as BoxDecoration;
      // Selection ring has width 2.5 vs default 2
      expect((decoration.border as Border).top.width, 2.5);
    });

    testWidgets('renders drop-target ring when ctx.dropTarget == true',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenTriggerNode(
          context: triggerNodeContextFixture(dropTarget: true),
        )),
      );
      final container = tester.widget<Container>(find
          .descendant(
            of: find.byType(InkWell),
            matching: find.byType(Container),
          )
          .first);
      final decoration = container.decoration as BoxDecoration;
      expect((decoration.border as Border).top.width, 2.5);
    });

    testWidgets('does NOT render a delete button (Trigger is unique)',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenTriggerNode(context: triggerNodeContextFixture())),
      );
      expect(find.byIcon(Icons.delete_outline), findsNothing);
      expect(find.byIcon(Icons.delete), findsNothing);
    });

    testWidgets('renders at iPhone-narrow (390pt) without RenderFlex overflow',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenTriggerNode(context: triggerNodeContextFixture()),
          width: 390,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenTriggerNode — popover editor', () {
    testWidgets('tapping card opens popover dialog', (tester) async {
      await tester.pumpWidget(
        wrap(EdenTriggerNode(context: triggerNodeContextFixture())),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Edit Trigger'), findsOneWidget);
    });

    testWidgets('popover shows trigger-type dropdown with all 6 values',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenTriggerNode(context: triggerNodeContextFixture())),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      // Open the trigger-type dropdown
      await tester.tap(find.byType(DropdownButtonFormField<EdenWorkflowTriggerType>));
      await tester.pumpAndSettle();
      // All 6 values appear (each name once in the popup); use minimum check
      expect(find.text('Entity Created'), findsWidgets);
      expect(find.text('On Schedule'), findsWidgets);
      expect(find.text('On Completion'), findsWidgets);
      expect(find.text('Manual'), findsWidgets);
      expect(find.text('Status Change'), findsWidgets);
      expect(find.text('Time-Based'), findsWidgets);
    });

    testWidgets('popover shows category dropdown with 5 defaults', (tester) async {
      await tester.pumpWidget(
        wrap(EdenTriggerNode(context: triggerNodeContextFixture())),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      expect(find.text('Appointment'), findsWidgets);
      expect(find.text('Task'), findsWidgets);
      expect(find.text('Project'), findsWidgets);
      expect(find.text('Customer'), findsWidgets);
      expect(find.text('Callback'), findsWidgets);
    });

    testWidgets('Save fires onUpdate with new triggerType + category',
        (tester) async {
      final captures = <Map<String, dynamic>>[];
      await tester.pumpWidget(
        wrap(EdenTriggerNode(
          context: triggerNodeContextFixture(),
          config: EdenTriggerNodeConfig(
            onUpdate: captures.add,
          ),
        )),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(captures.length, 1);
      expect(captures[0]['triggerType'], 'entity_created');
      expect(captures[0]['category'], 'appointment');
    });

    testWidgets('Cancel does NOT fire onUpdate', (tester) async {
      final captures = <Map<String, dynamic>>[];
      await tester.pumpWidget(
        wrap(EdenTriggerNode(
          context: triggerNodeContextFixture(),
          config: EdenTriggerNodeConfig(
            onUpdate: captures.add,
          ),
        )),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(captures, isEmpty);
    });

    testWidgets('after Save, the popover dismisses', (tester) async {
      await tester.pumpWidget(
        wrap(EdenTriggerNode(
          context: triggerNodeContextFixture(),
          config: const EdenTriggerNodeConfig(),
        )),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
