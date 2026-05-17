import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_fixtures/eden_workflow_delay_merge_fixtures.dart';
import '../_fixtures/eden_workflow_node_fixtures.dart' show wrap;

void main() {
  group('EdenMergeNode — visual', () {
    testWidgets('renders gray card with merge icon', (tester) async {
      await tester.pumpWidget(
        wrap(EdenMergeNode(context: mergeNodeContextFixture())),
      );
      expect(find.byIcon(Icons.merge), findsOneWidget);
    });

    testWidgets('renders "MERGE" uppercase + "Join" subtitle', (tester) async {
      await tester.pumpWidget(
        wrap(EdenMergeNode(context: mergeNodeContextFixture())),
      );
      expect(find.text('MERGE'), findsOneWidget);
      expect(find.text('Join'), findsOneWidget);
    });

    testWidgets('selection ring when selected', (tester) async {
      await tester.pumpWidget(
        wrap(EdenMergeNode(
          context: mergeNodeContextFixture(selected: true),
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

    testWidgets('renders at 390pt narrow without overflow', (tester) async {
      await tester.pumpWidget(
        wrap(EdenMergeNode(context: mergeNodeContextFixture()), width: 390),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenMergeNode — delete button', () {
    testWidgets('delete always visible on touch + fires onDelete',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      var deleted = 0;
      await tester.pumpWidget(
        wrap(EdenMergeNode(
          context: mergeNodeContextFixture(),
          config: EdenMergeNodeConfig(onDelete: () => deleted++),
        )),
      );
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(deleted, 1);
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('EdenWorkflowGraphBuilder — public port helpers', () {
    test('triggerPorts returns 2 source ports', () {
      final ports = EdenWorkflowGraphBuilder.triggerPorts();
      expect(ports.length, 2);
      expect(ports.every((p) => p.kind == EdenDiagramPortKind.source), isTrue);
    });

    test('conditionPorts returns 4 ports (2 target + 2 source)', () {
      final ports = EdenWorkflowGraphBuilder.conditionPorts();
      expect(ports.length, 4);
      expect(ports.map((p) => p.id).toSet(), {'top', 'left', 'yes', 'no'});
    });

    test('actionPorts returns 4 ports', () {
      final ports = EdenWorkflowGraphBuilder.actionPorts();
      expect(ports.length, 4);
    });

    test('endPorts returns 2 target ports (no source)', () {
      final ports = EdenWorkflowGraphBuilder.endPorts();
      expect(ports.length, 2);
      expect(ports.every((p) => p.kind == EdenDiagramPortKind.target), isTrue);
    });

    test('branchPorts returns 5 ports (2 target + 3 source)', () {
      final ports = EdenWorkflowGraphBuilder.branchPorts();
      expect(ports.length, 5);
      final ids = ports.map((p) => p.id).toSet();
      expect(ids, containsAll(['top', 'left', 'right', 'right-2', 'bottom']));
      final sources =
          ports.where((p) => p.kind == EdenDiagramPortKind.source).length;
      expect(sources, 3);
    });

    test('mergePorts returns 5 ports (3 target + 2 source)', () {
      final ports = EdenWorkflowGraphBuilder.mergePorts();
      expect(ports.length, 5);
      final ids = ports.map((p) => p.id).toSet();
      expect(ids, containsAll(['top', 'left', 'left-2', 'right', 'bottom']));
      final targets =
          ports.where((p) => p.kind == EdenDiagramPortKind.target).length;
      expect(targets, 3);
    });

    test('delayPorts returns 4 ports (2 target + 2 source)', () {
      final ports = EdenWorkflowGraphBuilder.delayPorts();
      expect(ports.length, 4);
    });
  });
}
