import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:eden_ui_flutter/src/widgets/eden_diagram/diagram_painter.dart'
    as painter;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_diagram_extension_fixtures.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 800, height: 600, child: child),
        ),
      );

  group('EdenDiagram — multi-handle ports (objective 006, parity E-5)', () {
    test('customPortPixelPosition computes position for each side', () {
      final node =
          EdenDiagramNode(id: 'd', x: 100, y: 100, width: 100, height: 100);
      const yesPort = EdenDiagramPort(
        id: 'yes',
        side: EdenPortSide.right,
        kind: EdenDiagramPortKind.source,
      );
      expect(
        painter.EdenDiagramPainter.customPortPixelPosition(node, yesPort),
        const Offset(200, 150),
      );

      const noPort = EdenDiagramPort(
        id: 'no',
        side: EdenPortSide.bottom,
        kind: EdenDiagramPortKind.source,
      );
      expect(
        painter.EdenDiagramPainter.customPortPixelPosition(node, noPort),
        const Offset(150, 200),
      );
    });

    test('resolveEdgeStart honors sourcePortId when present', () {
      final node = EdenDiagramNode(
        id: 'd',
        x: 100,
        y: 100,
        width: 100,
        height: 100,
        ports: const [
          EdenDiagramPort(
            id: 'yes',
            side: EdenPortSide.right,
            kind: EdenDiagramPortKind.source,
          ),
        ],
      );
      final edge = EdenDiagramEdge(
        id: 'e',
        sourceId: 'd',
        targetId: 't',
        sourcePortId: 'yes',
      );
      expect(
        painter.EdenDiagramPainter.resolveEdgeStart(edge, node),
        const Offset(200, 150),
      );
    });

    test('resolveEdgeStart falls back to enum when sourcePortId is null', () {
      final node = EdenDiagramNode(
        id: 'd',
        x: 100,
        y: 100,
        width: 100,
        height: 100,
        ports: const [
          EdenDiagramPort(
            id: 'yes',
            side: EdenPortSide.right,
            kind: EdenDiagramPortKind.source,
          ),
        ],
      );
      final edge = EdenDiagramEdge(
        id: 'e',
        sourceId: 'd',
        targetId: 't',
        sourcePort: EdenPortSide.bottom,
      );
      // Falls back to legacy 4-direction model
      expect(
        painter.EdenDiagramPainter.resolveEdgeStart(edge, node),
        const Offset(150, 200),
      );
    });

    test('resolveEdgeStart falls back to enum when portId is unknown', () {
      final node = EdenDiagramNode(
        id: 'd',
        x: 100,
        y: 100,
        width: 100,
        height: 100,
        ports: const [
          EdenDiagramPort(
            id: 'yes',
            side: EdenPortSide.right,
            kind: EdenDiagramPortKind.source,
          ),
        ],
      );
      final edge = EdenDiagramEdge(
        id: 'e',
        sourceId: 'd',
        targetId: 't',
        sourcePort: EdenPortSide.top,
        sourcePortId: 'no_such_port',
      );
      expect(
        painter.EdenDiagramPainter.resolveEdgeStart(edge, node),
        const Offset(150, 100),
      ); // top center fallback
    });

    testWidgets('renders decision-with-ports fixture without exceptions',
        (tester) async {
      await tester.pumpWidget(wrap(EdenDiagram(
        data: decisionWithPortsFixture(),
      )));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
