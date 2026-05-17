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
              child: SizedBox(width: 200, height: 200, child: child),
            ),
          ),
        ),
      );

  EdenProcessDecisionConfig makeDecision({
    int id = 1,
    String name = 'Approval Required?',
    String condition = 'cost > 5000',
  }) =>
      EdenProcessDecisionConfig(id: id, name: name, condition: condition);

  group('EdenProcessDecisionNode — rendering', () {
    testWidgets('renders rotated-diamond Transform.rotate at pi/4',
        (tester) async {
      final dec = makeDecision();
      await tester.pumpWidget(wrap(EdenProcessDecisionNode(
        context: nodeCtx(decisionDiagramNodeFixture()),
        config: decisionRendererConfigFixture(decisionsById: {1: dec}),
      )));
      expect(find.byType(Transform), findsAtLeastNWidgets(1));
    });

    testWidgets('renders call_split icon', (tester) async {
      final dec = makeDecision();
      await tester.pumpWidget(wrap(EdenProcessDecisionNode(
        context: nodeCtx(decisionDiagramNodeFixture()),
        config: decisionRendererConfigFixture(decisionsById: {1: dec}),
      )));
      expect(find.byIcon(Icons.call_split), findsOneWidget);
    });

    testWidgets('renders decision name', (tester) async {
      final dec = makeDecision(name: 'Continue?');
      await tester.pumpWidget(wrap(EdenProcessDecisionNode(
        context: nodeCtx(decisionDiagramNodeFixture()),
        config: decisionRendererConfigFixture(decisionsById: {1: dec}),
      )));
      expect(find.text('Continue?'), findsOneWidget);
    });

    testWidgets('renders condition text below name when non-empty',
        (tester) async {
      final dec = makeDecision(condition: 'cost > 5000');
      await tester.pumpWidget(wrap(EdenProcessDecisionNode(
        context: nodeCtx(decisionDiagramNodeFixture()),
        config: decisionRendererConfigFixture(decisionsById: {1: dec}),
      )));
      expect(find.text('cost > 5000'), findsOneWidget);
    });

    testWidgets('omits condition text when empty', (tester) async {
      final dec = makeDecision(condition: '');
      await tester.pumpWidget(wrap(EdenProcessDecisionNode(
        context: nodeCtx(decisionDiagramNodeFixture()),
        config: decisionRendererConfigFixture(decisionsById: {1: dec}),
      )));
      // No additional text below the name should match anything condition-like.
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('renders missing-decision fallback when lookup fails',
        (tester) async {
      await tester.pumpWidget(wrap(EdenProcessDecisionNode(
        context: nodeCtx(decisionDiagramNodeFixture(decisionId: 999)),
        config: decisionRendererConfigFixture(decisionsById: const {}),
      )));
      expect(find.text('Missing decision 999'), findsOneWidget);
    });

    testWidgets('tapping trash fires onDeleteDecision', (tester) async {
      int? deleted;
      final dec = makeDecision(id: 7);
      await tester.pumpWidget(wrap(EdenProcessDecisionNode(
        context: nodeCtx(decisionDiagramNodeFixture(decisionId: 7)),
        config: decisionRendererConfigFixture(
          decisionsById: {7: dec},
          onDeleteDecision: (id) => deleted = id,
        ),
      )));
      await tester.tap(find.byIcon(Icons.delete_outline), warnIfMissed: false);
      await tester.pump();
      expect(deleted, 7);
    });

    testWidgets('selected=true increases border width', (tester) async {
      final dec = makeDecision();
      await tester.pumpWidget(wrap(EdenProcessDecisionNode(
        context: nodeCtx(decisionDiagramNodeFixture(), selected: true),
        config: decisionRendererConfigFixture(decisionsById: {1: dec}),
      )));
      // Find the rotated container (Transform > Container).
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(Transform),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect((decoration.border as Border).top.width, 2);
    });
  });

  group('EdenProcessDecisionNode — inline edit dialog', () {
    testWidgets('tap on name opens dialog with name + condition fields',
        (tester) async {
      final dec = makeDecision(name: 'Approve?', condition: 'cost > 5000');
      await tester.pumpWidget(wrap(EdenProcessDecisionNode(
        context: nodeCtx(decisionDiagramNodeFixture()),
        config: decisionRendererConfigFixture(decisionsById: {1: dec}),
      )));

      await tester.tap(find.text('Approve?'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Edit Decision'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('Save with non-empty name fires onUpdateDecision',
        (tester) async {
      int? updatedId;
      Map<String, dynamic>? updates;
      final dec = makeDecision(id: 5, name: 'Approve?', condition: '');
      await tester.pumpWidget(wrap(EdenProcessDecisionNode(
        context: nodeCtx(decisionDiagramNodeFixture(decisionId: 5)),
        config: decisionRendererConfigFixture(
          decisionsById: {5: dec},
          onUpdateDecision: (id, u) {
            updatedId = id;
            updates = u;
          },
        ),
      )));

      await tester.tap(find.text('Approve?'));
      await tester.pumpAndSettle();
      // Modify the name field.
      final nameFinder = find.byType(TextField).first;
      await tester.enterText(nameFinder, 'Continue?');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(updatedId, 5);
      expect(updates?['name'], 'Continue?');
    });

    testWidgets('Cancel does NOT fire onUpdateDecision', (tester) async {
      int callCount = 0;
      final dec = makeDecision();
      await tester.pumpWidget(wrap(EdenProcessDecisionNode(
        context: nodeCtx(decisionDiagramNodeFixture()),
        config: decisionRendererConfigFixture(
          decisionsById: {1: dec},
          onUpdateDecision: (_, __) => callCount += 1,
        ),
      )));

      await tester.tap(find.text('Approval Required?'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'something');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(callCount, 0);
    });

    testWidgets('Empty name on save silently cancels (no callback)',
        (tester) async {
      int callCount = 0;
      final dec = makeDecision();
      await tester.pumpWidget(wrap(EdenProcessDecisionNode(
        context: nodeCtx(decisionDiagramNodeFixture()),
        config: decisionRendererConfigFixture(
          decisionsById: {1: dec},
          onUpdateDecision: (_, __) => callCount += 1,
        ),
      )));

      await tester.tap(find.text('Approval Required?'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(callCount, 0);
    });
  });

  group('EdenProcessNodeRenderer dispatch extension — decision', () {
    testWidgets('returns EdenProcessDecisionNode for nodeType=decision',
        (tester) async {
      final dec = makeDecision();
      await tester.pumpWidget(wrap(EdenProcessNodeRenderer.dispatch(
        nodeCtx(decisionDiagramNodeFixture()),
        config: decisionRendererConfigFixture(decisionsById: {1: dec}),
      )));
      expect(find.byType(EdenProcessDecisionNode), findsOneWidget);
    });
  });

  group('EdenProcessDecisionNode — iPhone-narrow safe', () {
    testWidgets('renders at 390pt without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final dec = makeDecision();
      await tester.pumpWidget(wrap(EdenProcessDecisionNode(
        context: nodeCtx(decisionDiagramNodeFixture()),
        config: decisionRendererConfigFixture(decisionsById: {1: dec}),
      )));
      expect(tester.takeException(), isNull);
    });
  });
}
