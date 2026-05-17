import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_fixtures/eden_workflow_flow_node_fixtures.dart';
import '../_fixtures/eden_workflow_node_fixtures.dart' show wrap;

void main() {
  group('EdenBranchNode — visual', () {
    testWidgets('renders gray card with call_split icon', (tester) async {
      await tester.pumpWidget(
        wrap(EdenBranchNode(context: branchNodeContextFixture())),
      );
      expect(find.byIcon(Icons.call_split), findsOneWidget);
    });

    testWidgets('renders "BRANCH" uppercase label and "Split" subtitle',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenBranchNode(context: branchNodeContextFixture())),
      );
      expect(find.text('BRANCH'), findsOneWidget);
      expect(find.text('Split'), findsOneWidget);
    });

    testWidgets('selection ring when selected', (tester) async {
      await tester.pumpWidget(
        wrap(EdenBranchNode(
          context: branchNodeContextFixture(selected: true),
        )),
      );
      final container = tester.widget<Container>(find
          .byWidgetPredicate((w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).border != null)
          .first);
      final decoration = container.decoration as BoxDecoration;
      expect((decoration.border as Border).top.width, 2.5);
    });

    testWidgets('renders at 390pt narrow width without overflow',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenBranchNode(context: branchNodeContextFixture()), width: 390),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenBranchNode — delete button', () {
    testWidgets('delete NOT visible by default on desktop', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      await tester.pumpWidget(
        wrap(EdenBranchNode(
          context: branchNodeContextFixture(),
          config: EdenBranchNodeConfig(onDelete: () {}),
        )),
      );
      expect(find.byIcon(Icons.delete_outline), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('delete visible on hover (desktop)', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      await tester.pumpWidget(
        wrap(EdenBranchNode(
          context: branchNodeContextFixture(),
          config: EdenBranchNodeConfig(onDelete: () {}),
        )),
      );
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(EdenBranchNode)));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('delete always visible on touch', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await tester.pumpWidget(
        wrap(EdenBranchNode(
          context: branchNodeContextFixture(),
          config: EdenBranchNodeConfig(onDelete: () {}),
        )),
      );
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('tap delete fires onDelete', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      var deleted = 0;
      await tester.pumpWidget(
        wrap(EdenBranchNode(
          context: branchNodeContextFixture(),
          config: EdenBranchNodeConfig(onDelete: () => deleted++),
        )),
      );
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(deleted, 1);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
