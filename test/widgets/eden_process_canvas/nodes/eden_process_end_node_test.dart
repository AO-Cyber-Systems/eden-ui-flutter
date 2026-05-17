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

  group('EdenProcessEndNode', () {
    testWidgets('renders Stop icon inside a red circle', (tester) async {
      await tester.pumpWidget(wrap(EdenProcessEndNode(
        context: nodeCtx(endDiagramNodeFixture()),
      )));

      expect(find.byIcon(Icons.stop), findsOneWidget);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(EdenProcessEndNode),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, isNotNull);
    });

    testWidgets('renders selection ring when ctx.selected==true',
        (tester) async {
      await tester.pumpWidget(wrap(EdenProcessEndNode(
        context: nodeCtx(endDiagramNodeFixture(), selected: true),
      )));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(EdenProcessEndNode),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('omits selection ring when ctx.selected==false',
        (tester) async {
      await tester.pumpWidget(wrap(EdenProcessEndNode(
        context: nodeCtx(endDiagramNodeFixture()),
      )));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(EdenProcessEndNode),
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

      await tester.pumpWidget(wrap(EdenProcessEndNode(
        context: nodeCtx(endDiagramNodeFixture()),
      )));

      expect(tester.takeException(), isNull);
    });
  });
}
