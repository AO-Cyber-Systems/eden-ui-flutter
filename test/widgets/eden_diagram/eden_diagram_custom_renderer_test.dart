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

  group('EdenDiagram — customNodeRenderer (objective 006)', () {
    testWidgets('renders one consumer widget per node when provided',
        (tester) async {
      await tester.pumpWidget(wrap(EdenDiagram(
        data: simpleTwoNodeDiagramFixture(),
        customNodeRenderer: probeNodeRenderer,
      )));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('probe-a')), findsOneWidget);
      expect(find.byKey(const ValueKey('probe-b')), findsOneWidget);
    });

    testWidgets('does not render probe widgets when customNodeRenderer is null',
        (tester) async {
      await tester.pumpWidget(wrap(EdenDiagram(
        data: simpleTwoNodeDiagramFixture(),
      )));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('probe-a')), findsNothing);
      expect(find.byKey(const ValueKey('probe-b')), findsNothing);
    });

    testWidgets(
        'ctx.dropTarget flag flips probe color when dropTargetNodeId matches',
        (tester) async {
      await tester.pumpWidget(wrap(EdenDiagram(
        data: simpleTwoNodeDiagramFixture(),
        customNodeRenderer: probeNodeRenderer,
        dropTargetNodeId: 'a',
      )));
      await tester.pumpAndSettle();

      // probeNodeRenderer renders green when dropTarget == true, red otherwise.
      final probeA = tester.widget<Container>(
        find.byKey(const ValueKey('probe-a')),
      );
      expect(probeA.color, Colors.green);

      final probeB = tester.widget<Container>(
        find.byKey(const ValueKey('probe-b')),
      );
      expect(probeB.color, Colors.red);
    });

    testWidgets('renders at iPhone-narrow (390pt) without overflow',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 800,
            child: EdenDiagram(
              data: simpleTwoNodeDiagramFixture(),
              customNodeRenderer: probeNodeRenderer,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
