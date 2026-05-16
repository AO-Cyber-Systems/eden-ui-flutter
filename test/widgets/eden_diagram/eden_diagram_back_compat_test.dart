import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Back-compat regression test for objective 006 invariant:
///   Existing `EdenDiagram(data: ...)` consumer code MUST continue to work
///   unchanged across all 15 TRDs of objective 006.
///
/// If this test breaks, an additive change accidentally became breaking.
void main() {
  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: child));

  group('EdenDiagram — back-compat (objective 006 invariant)', () {
    testWidgets(
        'renders unchanged EdenDiagram(data: ...) constructor with no ports',
        (tester) async {
      final data = EdenDiagramData(
        nodes: [
          EdenDiagramNode(id: 'a', x: 0, y: 0, label: 'A'),
          EdenDiagramNode(id: 'b', x: 200, y: 100, label: 'B'),
        ],
        edges: [EdenDiagramEdge(id: 'e1', sourceId: 'a', targetId: 'b')],
      );

      await tester.pumpWidget(wrap(SizedBox(
        width: 800,
        height: 600,
        child: EdenDiagram(data: data),
      )));
      await tester.pumpAndSettle();

      expect(find.byType(EdenDiagram), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test(
        'EdenDiagramNode.portOffset(side) returns same legacy offsets when ports is null',
        () {
      final node =
          EdenDiagramNode(id: 'n', x: 100, y: 50, width: 200, height: 60);
      expect(node.portOffset(EdenPortSide.top), const Offset(200, 50));
      expect(node.portOffset(EdenPortSide.right), const Offset(300, 80));
      expect(node.portOffset(EdenPortSide.bottom), const Offset(200, 110));
      expect(node.portOffset(EdenPortSide.left), const Offset(100, 80));
    });

    test(
        'EdenDiagramNode.portOffset(side) still returns legacy offsets when ports is set',
        () {
      final node = EdenDiagramNode(
        id: 'n',
        x: 100,
        y: 50,
        width: 200,
        height: 60,
        ports: const [
          EdenDiagramPort(
            id: 'yes',
            side: EdenPortSide.right,
            kind: EdenDiagramPortKind.source,
          ),
        ],
      );
      // Legacy method returns the 4-direction value; canvas (TRD 02) is the
      // only place that prefers `ports` when present.
      expect(node.portOffset(EdenPortSide.right), const Offset(300, 80));
    });
  });
}
