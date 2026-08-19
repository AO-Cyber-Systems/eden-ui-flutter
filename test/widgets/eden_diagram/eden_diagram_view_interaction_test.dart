// View-mode interaction for EdenDiagram (quick 68): drag-to-pan when readOnly,
// two-finger pinch zoom gated on interactiveZoom, and the zoom-only toolbar.
//
// Edit-mode behaviour must be byte-identical to before, so every readOnly:true
// case here has a readOnly:false counterpart acting as a regression guard.

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

  EdenDiagramState stateOf(WidgetTester tester) =>
      tester.state<EdenDiagramState>(find.byType(EdenDiagram));

  group('EdenDiagram - view-mode pan (quick 68)', () {
    testWidgets('readOnly: true - a single-pointer drag moves panOffset',
        (tester) async {
      await tester.pumpWidget(wrap(EdenDiagram(
        data: simpleTwoNodeDiagramFixture(),
        readOnly: true,
        showToolbar: false,
      )));
      await tester.pumpAndSettle();

      expect(stateOf(tester).panOffset, Offset.zero);

      // Start on empty canvas: the center of an 800x600 box is (400, 300) and
      // the fixture nodes sit at (0,0,200,60) and (300,200,200,60).
      final center = tester.getCenter(find.byType(EdenDiagram));
      final gesture = await tester.startGesture(center);
      // The first move consumes the ScaleGestureRecognizer pan slop and is what
      // starts the gesture, so the pan delta is measured from here.
      await gesture.moveBy(const Offset(40, 40));
      await tester.pump();
      final afterSlop = stateOf(tester).panOffset;

      await gesture.moveBy(const Offset(50, 30));
      await tester.pump();
      expect(stateOf(tester).panOffset - afterSlop, const Offset(50, 30));

      await gesture.up();
      await tester.pump();
    });

    testWidgets('readOnly: true - tester.drag pans by roughly the drag delta',
        (tester) async {
      await tester.pumpWidget(wrap(EdenDiagram(
        data: simpleTwoNodeDiagramFixture(),
        readOnly: true,
        showToolbar: false,
      )));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(EdenDiagram), const Offset(120, 90));
      await tester.pump();

      final panned = stateOf(tester).panOffset;
      expect(panned.dx, greaterThan(0));
      expect(panned.dy, greaterThan(0));
      // Slop consumed before the recognizer starts is bounded, so the realised
      // pan must land close to the requested delta.
      expect((panned - const Offset(120, 90)).distance, lessThan(60));
    });

    testWidgets(
        'readOnly: false, showToolbar: false - the same drag does NOT pan',
        (tester) async {
      await tester.pumpWidget(wrap(EdenDiagram(
        data: simpleTwoNodeDiagramFixture(),
        readOnly: false,
        showToolbar: false,
      )));
      await tester.pumpAndSettle();

      expect(stateOf(tester).panOffset, Offset.zero);

      await tester.drag(find.byType(EdenDiagram), const Offset(120, 90));
      await tester.pump();

      // Edit mode keeps the select tool; panning stays behind the Pan tool.
      expect(stateOf(tester).panOffset, Offset.zero);
    });

    testWidgets('readOnly: false - dragging a node still moves the node',
        (tester) async {
      final data = simpleTwoNodeDiagramFixture();
      await tester.pumpWidget(wrap(EdenDiagram(
        data: data,
        readOnly: false,
        showToolbar: false,
      )));
      await tester.pumpAndSettle();

      // Node 'a' occupies (0,0,200,60), so (100,30) is its middle.
      final topLeft = tester.getTopLeft(find.byType(EdenDiagram));
      await tester.dragFrom(
          topLeft + const Offset(100, 30), const Offset(60, 60));
      await tester.pump();

      expect(data.nodeById('a')!.x, greaterThan(0));
      expect(data.nodeById('a')!.y, greaterThan(0));
      expect(stateOf(tester).panOffset, Offset.zero);
    });
  });

  group('EdenDiagram - pinch zoom (quick 68)', () {
    testWidgets('interactiveZoom: true - pinch raises scale above 1.0',
        (tester) async {
      await tester.pumpWidget(wrap(EdenDiagram(
        data: simpleTwoNodeDiagramFixture(),
        readOnly: true,
        showToolbar: false,
      )));
      await tester.pumpAndSettle();

      expect(stateOf(tester).scale, 1.0);

      final center = tester.getCenter(find.byType(EdenDiagram));
      final g1 = await tester.startGesture(center - const Offset(20, 0));
      final g2 = await tester.startGesture(center + const Offset(20, 0));
      await tester.pump();
      await g1.moveBy(const Offset(-60, 0));
      await g2.moveBy(const Offset(60, 0));
      await tester.pump();

      // Assert BEFORE releasing: releasing ends the gesture.
      expect(stateOf(tester).scale, greaterThan(1.0));

      await g1.up();
      await g2.up();
      await tester.pump();
    });

    testWidgets('interactiveZoom: false - the same pinch leaves scale at 1.0',
        (tester) async {
      await tester.pumpWidget(wrap(EdenDiagram(
        data: simpleTwoNodeDiagramFixture(),
        readOnly: true,
        showToolbar: false,
        interactiveZoom: false,
      )));
      await tester.pumpAndSettle();

      final center = tester.getCenter(find.byType(EdenDiagram));
      final g1 = await tester.startGesture(center - const Offset(20, 0));
      final g2 = await tester.startGesture(center + const Offset(20, 0));
      await tester.pump();
      await g1.moveBy(const Offset(-60, 0));
      await g2.moveBy(const Offset(60, 0));
      await tester.pump();

      expect(stateOf(tester).scale, 1.0);

      await g1.up();
      await g2.up();
      await tester.pump();
    });
  });

  group('EdenDiagram - toolbar contents by mode (quick 68)', () {
    testWidgets('readOnly: true, showToolbar: true - zoom buttons only',
        (tester) async {
      await tester.pumpWidget(wrap(EdenDiagram(
        data: simpleTwoNodeDiagramFixture(),
        readOnly: true,
        showToolbar: true,
      )));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Zoom In'), findsOneWidget);
      expect(find.byTooltip('Zoom Out'), findsOneWidget);
      expect(find.byTooltip('Reset Zoom'), findsOneWidget);

      expect(find.byTooltip('Select (V)'), findsNothing);
      expect(find.byTooltip('Pan (H)'), findsNothing);
      expect(find.byTooltip('Connect (C)'), findsNothing);
      expect(find.byTooltip('Add Rectangle'), findsNothing);
      expect(find.byTooltip('Add Diamond'), findsNothing);
      expect(find.byTooltip('Add Circle'), findsNothing);
    });

    testWidgets('readOnly: false, showToolbar: true - the full edit toolbar',
        (tester) async {
      await tester.pumpWidget(wrap(EdenDiagram(
        data: simpleTwoNodeDiagramFixture(),
        readOnly: false,
        showToolbar: true,
      )));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Zoom In'), findsOneWidget);
      expect(find.byTooltip('Zoom Out'), findsOneWidget);
      expect(find.byTooltip('Reset Zoom'), findsOneWidget);
      expect(find.byTooltip('Select (V)'), findsOneWidget);
      expect(find.byTooltip('Pan (H)'), findsOneWidget);
      expect(find.byTooltip('Connect (C)'), findsOneWidget);
      expect(find.byTooltip('Add Rectangle'), findsOneWidget);
      expect(find.byTooltip('Add Diamond'), findsOneWidget);
      expect(find.byTooltip('Add Circle'), findsOneWidget);
    });

    testWidgets('readOnly: true, showToolbar: false - no toolbar at all',
        (tester) async {
      await tester.pumpWidget(wrap(EdenDiagram(
        data: simpleTwoNodeDiagramFixture(),
        readOnly: true,
        showToolbar: false,
      )));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Zoom In'), findsNothing);
      expect(find.byTooltip('Zoom Out'), findsNothing);
      expect(find.byTooltip('Reset Zoom'), findsNothing);
      expect(find.byTooltip('Pan (H)'), findsNothing);
    });

    testWidgets('the view-only Zoom In button actually raises scale',
        (tester) async {
      await tester.pumpWidget(wrap(EdenDiagram(
        data: simpleTwoNodeDiagramFixture(),
        readOnly: true,
        showToolbar: true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('100%'), findsOneWidget);

      await tester.tap(find.byTooltip('Zoom In'));
      await tester.pumpAndSettle();

      expect(stateOf(tester).scale, greaterThan(1.0));
      expect(find.text('120%'), findsOneWidget);
    });
  });
}
