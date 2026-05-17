import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_fixtures/eden_workflow_node_fixtures.dart' show wrap;

EdenDiagramNodeContext _endNodeContext({
  bool selected = false,
  bool dropTarget = false,
}) =>
    EdenDiagramNodeContext(
      node: EdenDiagramNode(
        id: 'end-0',
        x: 0,
        y: 0,
        width: 48,
        height: 48,
        label: 'End',
        data: const {'nodeType': 'end'},
      ),
      selected: selected,
      dropTarget: dropTarget,
    );

void main() {
  group('EdenWorkflowEndNode', () {
    testWidgets('renders 48x48 red circle with stop icon', (tester) async {
      await tester.pumpWidget(
        wrap(EdenWorkflowEndNode(context: _endNodeContext())),
      );
      expect(find.byType(EdenWorkflowEndNode), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);
    });

    testWidgets('NO delete button (uniquely required like trigger)',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenWorkflowEndNode(context: _endNodeContext())),
      );
      expect(find.byIcon(Icons.delete_outline), findsNothing);
      expect(find.byIcon(Icons.delete), findsNothing);
    });

    testWidgets('selection ring when selected', (tester) async {
      await tester.pumpWidget(
        wrap(EdenWorkflowEndNode(context: _endNodeContext(selected: true))),
      );
      final container = tester.widget<Container>(find.descendant(
        of: find.byType(EdenWorkflowEndNode),
        matching: find.byType(Container),
      ).first);
      final decoration = container.decoration as BoxDecoration;
      expect((decoration.border as Border).top.width, 2.5);
    });

    testWidgets('drop-target ring when dropTarget true', (tester) async {
      await tester.pumpWidget(
        wrap(EdenWorkflowEndNode(
          context: _endNodeContext(dropTarget: true),
        )),
      );
      final container = tester.widget<Container>(find.descendant(
        of: find.byType(EdenWorkflowEndNode),
        matching: find.byType(Container),
      ).first);
      final decoration = container.decoration as BoxDecoration;
      expect((decoration.border as Border).top.width, 2.5);
    });

    testWidgets('renders at 390pt narrow without overflow', (tester) async {
      await tester.pumpWidget(
        wrap(EdenWorkflowEndNode(context: _endNodeContext()), width: 390),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('NO popover (tapping does nothing)', (tester) async {
      await tester.pumpWidget(
        wrap(EdenWorkflowEndNode(context: _endNodeContext())),
      );
      // GestureDetector / InkWell absence means no tap-target editor opens.
      await tester.tap(find.byType(EdenWorkflowEndNode));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
