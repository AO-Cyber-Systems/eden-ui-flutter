import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_fixtures/eden_process_node_fixtures.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: Center(
              child: SizedBox(width: 48, height: 48, child: child),
            ),
          ),
        ),
      );

  group('EdenProcessStartNode', () {
    testWidgets('renders Play icon inside a green circle', (tester) async {
      await tester.pumpWidget(wrap(EdenProcessStartNode(
        context: nodeCtx(startDiagramNodeFixture()),
      )));

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(EdenProcessStartNode),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, isNotNull);
    });

    testWidgets('renders selection ring when ctx.selected==true', (tester) async {
      await tester.pumpWidget(wrap(EdenProcessStartNode(
        context: nodeCtx(startDiagramNodeFixture(), selected: true),
      )));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(EdenProcessStartNode),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('omits selection ring when ctx.selected==false', (tester) async {
      await tester.pumpWidget(wrap(EdenProcessStartNode(
        context: nodeCtx(startDiagramNodeFixture()),
      )));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(EdenProcessStartNode),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNull);
    });

    testWidgets('renders without overflow at 390pt narrow viewport',
        (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrap(EdenProcessStartNode(
        context: nodeCtx(startDiagramNodeFixture()),
      )));

      expect(tester.takeException(), isNull);
    });
  });

  group('EdenProcessNodeRenderer.dispatch', () {
    testWidgets('returns EdenProcessStartNode for nodeType=start',
        (tester) async {
      final ctx = nodeCtx(startDiagramNodeFixture());
      await tester.pumpWidget(wrap(EdenProcessNodeRenderer.dispatch(ctx)));

      expect(find.byType(EdenProcessStartNode), findsOneWidget);
    });

    testWidgets('returns EdenProcessEndNode for nodeType=end', (tester) async {
      final ctx = nodeCtx(endDiagramNodeFixture());
      await tester.pumpWidget(wrap(EdenProcessNodeRenderer.dispatch(ctx)));

      expect(find.byType(EdenProcessEndNode), findsOneWidget);
    });

    testWidgets('returns EdenProcessOrphanNode for nodeType=orphan',
        (tester) async {
      final ctx = nodeCtx(phaseOrphanFixture());
      await tester.pumpWidget(wrap(EdenProcessNodeRenderer.dispatch(ctx)));

      expect(find.byType(EdenProcessOrphanNode), findsOneWidget);
    });

    testWidgets('returns fallback for unknown nodeType', (tester) async {
      final node = EdenDiagramNode(
        id: 'mystery',
        x: 0,
        y: 0,
        width: 100,
        height: 40,
        label: 'mystery-node',
        data: const {'nodeType': 'something_unknown'},
      );
      await tester.pumpWidget(wrap(EdenProcessNodeRenderer.dispatch(nodeCtx(node))));

      // _UnknownNodeFallback is a private class; we detect it via its red text label
      expect(find.text('mystery-node'), findsOneWidget);
    });

    testWidgets('returns fallback when nodeType is missing', (tester) async {
      final node = EdenDiagramNode(
        id: 'no-type',
        x: 0,
        y: 0,
        width: 100,
        height: 40,
        label: 'no-type-node',
      );
      await tester.pumpWidget(wrap(EdenProcessNodeRenderer.dispatch(nodeCtx(node))));

      expect(find.text('no-type-node'), findsOneWidget);
    });

    testWidgets('passes onDeleteOrphan from config to orphan node',
        (tester) async {
      String? deletedId;
      final config = EdenProcessNodeRendererConfig(
        onDeleteOrphan: (id) => deletedId = id,
      );
      final ctx = nodeCtx(phaseOrphanFixture(id: 'orphan-X'));
      await tester.pumpWidget(wrap(
        EdenProcessNodeRenderer.dispatch(ctx, config: config),
      ));

      // Find the orphan widget and fire its onDelete by triggering hover + tap on delete icon.
      // For this dispatch test, just verify the widget tree connects the callback:
      final orphan = tester.widget<EdenProcessOrphanNode>(
        find.byType(EdenProcessOrphanNode),
      );
      orphan.onDelete?.call('orphan-X');
      expect(deletedId, 'orphan-X');
    });
  });
}
