import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_diagram_extension_fixtures.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 800, height: 600, child: child),
        ),
      );

  group('EdenDiagram — hitTestNode (objective 006, parity D-1)', () {
    testWidgets('returns the node at the given screen position', (tester) async {
      final key = GlobalKey<EdenDiagramState>();
      final data = simpleTwoNodeDiagramFixture();
      await tester.pumpWidget(wrap(EdenDiagram(key: key, data: data)));
      await tester.pumpAndSettle();

      // Node 'a' bounds: (0,0,200,60). Test screen position (100, 30) is on
      // node 'a' since pan = (0,0) and scale = 1.
      final hit = key.currentState!.hitTestNode(const Offset(100, 30));
      expect(hit?.id, 'a');
    });

    testWidgets('returns null when screen position is outside any node',
        (tester) async {
      final key = GlobalKey<EdenDiagramState>();
      await tester.pumpWidget(
          wrap(EdenDiagram(key: key, data: simpleTwoNodeDiagramFixture())));
      await tester.pumpAndSettle();

      final hit = key.currentState!.hitTestNode(const Offset(600, 500));
      expect(hit, isNull);
    });

    testWidgets('respects z-order — returns last node when overlapping',
        (tester) async {
      final key = GlobalKey<EdenDiagramState>();
      await tester.pumpWidget(
          wrap(EdenDiagram(key: key, data: overlappingNodesFixture())));
      await tester.pumpAndSettle();

      final hit = key.currentState!.hitTestNode(const Offset(150, 150));
      expect(hit?.id, 'top');
    });
  });

  group('EdenDiagram — onDragUpdate / onDragLeave + onDropTargetChanged', () {
    testWidgets('fires onDropTargetChanged(nodeId) when hit changes',
        (tester) async {
      final key = GlobalKey<EdenDiagramState>();
      final emitted = <String?>[];
      await tester.pumpWidget(wrap(EdenDiagram(
        key: key,
        data: simpleTwoNodeDiagramFixture(),
        onDropTargetChanged: emitted.add,
      )));
      await tester.pumpAndSettle();

      key.currentState!.onDragUpdate(const Offset(100, 30)); // over 'a'
      expect(emitted, ['a']);
    });

    testWidgets('de-dups consecutive updates over the same node', (tester) async {
      final key = GlobalKey<EdenDiagramState>();
      final emitted = <String?>[];
      await tester.pumpWidget(wrap(EdenDiagram(
        key: key,
        data: simpleTwoNodeDiagramFixture(),
        onDropTargetChanged: emitted.add,
      )));
      await tester.pumpAndSettle();

      key.currentState!.onDragUpdate(const Offset(100, 30));
      key.currentState!.onDragUpdate(const Offset(110, 35));
      expect(emitted, ['a']);
    });

    testWidgets('fires onDropTargetChanged(newId) when hit changes nodes',
        (tester) async {
      final key = GlobalKey<EdenDiagramState>();
      final emitted = <String?>[];
      await tester.pumpWidget(wrap(EdenDiagram(
        key: key,
        data: simpleTwoNodeDiagramFixture(),
        onDropTargetChanged: emitted.add,
      )));
      await tester.pumpAndSettle();

      key.currentState!.onDragUpdate(const Offset(100, 30)); // 'a'
      key.currentState!.onDragUpdate(const Offset(400, 230)); // 'b'
      expect(emitted, ['a', 'b']);
    });

    testWidgets('fires onDropTargetChanged(null) when leaving a node',
        (tester) async {
      final key = GlobalKey<EdenDiagramState>();
      final emitted = <String?>[];
      await tester.pumpWidget(wrap(EdenDiagram(
        key: key,
        data: simpleTwoNodeDiagramFixture(),
        onDropTargetChanged: emitted.add,
      )));
      await tester.pumpAndSettle();

      key.currentState!.onDragUpdate(const Offset(100, 30)); // 'a'
      key.currentState!.onDragUpdate(const Offset(600, 500)); // empty
      expect(emitted, ['a', null]);
    });

    testWidgets('onDragLeave fires null only when previously set',
        (tester) async {
      final key = GlobalKey<EdenDiagramState>();
      final emitted = <String?>[];
      await tester.pumpWidget(wrap(EdenDiagram(
        key: key,
        data: simpleTwoNodeDiagramFixture(),
        onDropTargetChanged: emitted.add,
      )));
      await tester.pumpAndSettle();

      key.currentState!.onDragLeave();
      expect(emitted, isEmpty);
      key.currentState!.onDragUpdate(const Offset(100, 30));
      key.currentState!.onDragLeave();
      expect(emitted, ['a', null]);
      key.currentState!.onDragLeave();
      expect(emitted, ['a', null]); // idempotent
    });
  });

  group('EdenDiagram — dropTargetNodeId visual ring', () {
    testWidgets('renders without exceptions when dropTargetNodeId is set',
        (tester) async {
      await tester.pumpWidget(wrap(EdenDiagram(
        data: simpleTwoNodeDiagramFixture(),
        dropTargetNodeId: 'a',
      )));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(EdenDiagram), findsOneWidget);
    });

    testWidgets('renders without exceptions when dropTargetNodeId is null',
        (tester) async {
      await tester.pumpWidget(wrap(EdenDiagram(
        data: simpleTwoNodeDiagramFixture(),
        dropTargetNodeId: null,
      )));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
