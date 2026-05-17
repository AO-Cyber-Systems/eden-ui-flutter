import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_workflow_node_fixtures.dart' show wrap;

void main() {
  group('EdenWorkflowValidationPanel', () {
    testWidgets('renders header "Workflow Validation"', (tester) async {
      const result = EdenWorkflowValidationResult(issues: []);
      await tester.pumpWidget(
        wrap(const EdenWorkflowValidationPanel(result: result)),
      );
      expect(find.text('Workflow Validation'), findsOneWidget);
    });

    testWidgets('shows "Workflow is ready to activate" when valid + no warnings',
        (tester) async {
      const result = EdenWorkflowValidationResult(issues: []);
      await tester.pumpWidget(
        wrap(const EdenWorkflowValidationPanel(result: result)),
      );
      expect(find.text('Workflow is ready to activate'), findsOneWidget);
    });

    testWidgets('shows warnings subtitle when valid + warnings present',
        (tester) async {
      const result = EdenWorkflowValidationResult(issues: [
        EdenWorkflowValidationIssue(
          severity: EdenProcessValidationSeverity.warning,
          message: 'Branch with one outgoing',
          suggestion: 'add more',
          nodeId: 'branch-0',
        ),
      ]);
      await tester.pumpWidget(
        wrap(const EdenWorkflowValidationPanel(result: result)),
      );
      expect(
        find.textContaining('warning(s) — workflow is activatable'),
        findsOneWidget,
      );
    });

    testWidgets('shows error subtitle when invalid', (tester) async {
      const result = EdenWorkflowValidationResult(issues: [
        EdenWorkflowValidationIssue(
          severity: EdenProcessValidationSeverity.error,
          message: 'Workflow must have a trigger node',
          suggestion: 'add trigger',
        ),
      ]);
      await tester.pumpWidget(
        wrap(const EdenWorkflowValidationPanel(result: result)),
      );
      expect(
        find.textContaining('error(s) — fix before activating'),
        findsOneWidget,
      );
    });

    testWidgets('renders error issue with red error icon', (tester) async {
      const result = EdenWorkflowValidationResult(issues: [
        EdenWorkflowValidationIssue(
          severity: EdenProcessValidationSeverity.error,
          message: 'Workflow must have a trigger node',
          suggestion: 'Drag a trigger from the toolbox',
        ),
      ]);
      await tester.pumpWidget(
        wrap(const EdenWorkflowValidationPanel(result: result)),
      );
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Workflow must have a trigger node'), findsOneWidget);
      expect(find.text('Drag a trigger from the toolbox'), findsOneWidget);
    });

    testWidgets('renders warning icon for warnings', (tester) async {
      const result = EdenWorkflowValidationResult(issues: [
        EdenWorkflowValidationIssue(
          severity: EdenProcessValidationSeverity.warning,
          message: 'No end node',
        ),
      ]);
      await tester.pumpWidget(
        wrap(const EdenWorkflowValidationPanel(result: result)),
      );
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('tapping issue with nodeId fires onIssueTap',
        (tester) async {
      const result = EdenWorkflowValidationResult(issues: [
        EdenWorkflowValidationIssue(
          severity: EdenProcessValidationSeverity.error,
          nodeId: 'action-0',
          message: 'action-0 not connected',
        ),
      ]);
      final taps = <String>[];
      await tester.pumpWidget(
        wrap(EdenWorkflowValidationPanel(
          result: result,
          onIssueTap: taps.add,
        )),
      );
      await tester.tap(find.text('action-0 not connected'));
      await tester.pumpAndSettle();
      expect(taps, ['action-0']);
    });

    testWidgets('close button fires onClose', (tester) async {
      var closed = 0;
      const result = EdenWorkflowValidationResult(issues: []);
      await tester.pumpWidget(
        wrap(EdenWorkflowValidationPanel(
          result: result,
          onClose: () => closed++,
        )),
      );
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(closed, 1);
    });
  });
}
