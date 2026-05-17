import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: Center(child: child),
        ),
      );

  group('EdenProcessValidationPanel — chip', () {
    testWidgets('zero issues → "Valid" chip with check_circle icon',
        (tester) async {
      const result = EdenProcessValidationResult(
        isValid: true,
        issues: [],
        orphanCount: 0,
      );
      await tester.pumpWidget(wrap(
        const EdenProcessValidationPanel(result: result),
      ));
      expect(find.text('Valid'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('only warnings → amber "N warnings" chip', (tester) async {
      const result = EdenProcessValidationResult(
        isValid: true,
        issues: [
          EdenProcessValidationIssue(
            type: EdenProcessValidationSeverity.warning,
            nodeId: 'phase-1',
            message: 'Phase X has no task groups',
          ),
          EdenProcessValidationIssue(
            type: EdenProcessValidationSeverity.warning,
            nodeId: 'group-10',
            message: 'Group Y is empty',
          ),
        ],
        orphanCount: 0,
      );
      await tester.pumpWidget(wrap(
        const EdenProcessValidationPanel(result: result),
      ));
      expect(find.text('2 warnings'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('errors → red "N errors" chip (warnings hidden)',
        (tester) async {
      const result = EdenProcessValidationResult(
        isValid: false,
        issues: [
          EdenProcessValidationIssue(
            type: EdenProcessValidationSeverity.error,
            nodeId: 'start',
            message: 'Process has no phases',
          ),
          EdenProcessValidationIssue(
            type: EdenProcessValidationSeverity.warning,
            nodeId: 'phase-1',
            message: 'Phase X has no task groups',
          ),
        ],
        orphanCount: 0,
      );
      await tester.pumpWidget(wrap(
        const EdenProcessValidationPanel(result: result),
      ));
      expect(find.text('1 error'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });
  });

  group('EdenProcessValidationPanel — popup list', () {
    testWidgets('tapping chip opens menu listing each issue', (tester) async {
      const result = EdenProcessValidationResult(
        isValid: false,
        issues: [
          EdenProcessValidationIssue(
            type: EdenProcessValidationSeverity.error,
            nodeId: 'decision-1',
            message: 'Decision missing branches',
            suggestion: 'Connect both Yes and No paths',
          ),
          EdenProcessValidationIssue(
            type: EdenProcessValidationSeverity.warning,
            nodeId: 'phase-1',
            message: 'Phase X has no task groups',
          ),
        ],
        orphanCount: 0,
      );
      await tester.pumpWidget(wrap(
        const EdenProcessValidationPanel(result: result),
      ));
      await tester.tap(find.byKey(const ValueKey('validation-panel-popup')));
      await tester.pumpAndSettle();
      expect(find.text('Decision missing branches'), findsOneWidget);
      expect(find.text('Phase X has no task groups'), findsOneWidget);
      expect(find.text('Connect both Yes and No paths'), findsOneWidget);
    });

    testWidgets('selecting an issue fires onIssueClicked', (tester) async {
      EdenProcessValidationIssue? clicked;
      const issue = EdenProcessValidationIssue(
        type: EdenProcessValidationSeverity.error,
        nodeId: 'phase-1',
        message: 'Issue A',
      );
      const result = EdenProcessValidationResult(
        isValid: false,
        issues: [issue],
        orphanCount: 0,
      );
      await tester.pumpWidget(wrap(EdenProcessValidationPanel(
        result: result,
        onIssueClicked: (i) => clicked = i,
      )));
      await tester.tap(find.byKey(const ValueKey('validation-panel-popup')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Issue A'));
      await tester.pumpAndSettle();
      expect(clicked?.message, 'Issue A');
    });

    testWidgets('empty issues shows "No issues found" placeholder',
        (tester) async {
      const result = EdenProcessValidationResult(
        isValid: true,
        issues: [],
        orphanCount: 0,
      );
      await tester.pumpWidget(wrap(
        const EdenProcessValidationPanel(result: result),
      ));
      await tester.tap(find.byKey(const ValueKey('validation-panel-popup')));
      await tester.pumpAndSettle();
      expect(find.text('No issues found'), findsOneWidget);
    });
  });
}
