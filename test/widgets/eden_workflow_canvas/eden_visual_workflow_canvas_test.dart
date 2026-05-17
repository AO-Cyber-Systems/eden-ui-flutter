import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_workflow_canvas_fixtures.dart';

Widget _wrapWide(Widget child, {double width = 1400, double height = 900}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, height)),
      child: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    ),
  );
}

void main() {
  setUp(() {
    EdenWorkflowCategoryRegistry.instance.resetToDefaults();
    EdenWorkflowActionRegistry.instance.resetToDefaults();
    EdenWorkflowToolboxItemRegistry.instance.resetToDefaults();
  });

  group('EdenVisualWorkflowCanvas', () {
    testWidgets('iPhone-narrow fallback at <1200pt', (tester) async {
      await tester.pumpWidget(
        _wrapWide(
          EdenVisualWorkflowCanvas(
            definition: simpleWorkflowDefinitionFixture(),
          ),
          width: 800,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Workflow designer requires tablet/desktop width'),
        findsOneWidget,
      );
      expect(find.byType(EdenDiagram), findsNothing);
    });

    testWidgets('wide screen renders EdenDiagram + toolbox', (tester) async {
      await tester.pumpWidget(
        _wrapWide(
          EdenVisualWorkflowCanvas(
            definition: simpleWorkflowDefinitionFixture(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EdenDiagram), findsOneWidget);
      expect(find.byType(EdenWorkflowToolbox), findsOneWidget);
    });

    testWidgets('hideToolbox: true hides the toolbox', (tester) async {
      await tester.pumpWidget(
        _wrapWide(
          EdenVisualWorkflowCanvas(
            definition: simpleWorkflowDefinitionFixture(),
            hideToolbox: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EdenWorkflowToolbox), findsNothing);
    });

    testWidgets('Save button visible when onSave provided', (tester) async {
      await tester.pumpWidget(
        _wrapWide(
          EdenVisualWorkflowCanvas(
            definition: simpleWorkflowDefinitionFixture(),
            onSave: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('Save fires onSave with EdenWorkflowSaveData', (tester) async {
      final captures = <EdenWorkflowSaveData>[];
      await tester.pumpWidget(
        _wrapWide(
          EdenVisualWorkflowCanvas(
            definition: simpleWorkflowDefinitionFixture(),
            onSave: captures.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(captures.length, 1);
      expect(captures[0].triggerType,
          EdenWorkflowTriggerType.entity_created);
    });

    testWidgets('Validation badge button toggles panel', (tester) async {
      await tester.pumpWidget(
        _wrapWide(
          EdenVisualWorkflowCanvas(
            definition: simpleWorkflowDefinitionFixture(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EdenWorkflowValidationPanel), findsNothing);
      // Locate the validation button by its check_circle_outline OR
      // error_outline icon (whichever matches the workflow state).
      final validationIconFinder = find
          .descendant(
            of: find.byType(FilledButton),
            matching: find.byIcon(Icons.check_circle_outline),
          )
          .first;
      await tester.tap(validationIconFinder);
      await tester.pumpAndSettle();
      expect(find.byType(EdenWorkflowValidationPanel), findsOneWidget);
    });

    testWidgets('populated definition emits nodes via graph builder',
        (tester) async {
      await tester.pumpWidget(
        _wrapWide(
          EdenVisualWorkflowCanvas(
            definition: populatedWorkflowDefinitionFixture(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // 5 nodes: trigger + condition + 2 actions + end (graph builder
      // emits them from the definition fixture).
      // We confirm at least one of each node-type renders.
      expect(find.byType(EdenTriggerNode), findsOneWidget);
      expect(find.byType(EdenConditionNode), findsOneWidget);
      expect(find.byType(EdenActionNode), findsAtLeastNWidgets(2));
      expect(find.byType(EdenWorkflowEndNode), findsOneWidget);
    });
  });
}
