import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_fixtures/eden_process_dialog_fixtures.dart';

void main() {
  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('EdenProcessPhaseEditorDialog', () {
    testWidgets('renders Dialog with title "Edit Phase"', (tester) async {
      final phase = phaseForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessPhaseEditorDialog(
          phase: phase,
          onUpdate: (_) {},
        ),
      ));
      await openDialog(tester);
      expect(find.text('Edit Phase'), findsOneWidget);
    });

    testWidgets('Name + Description fields populated', (tester) async {
      final phase = phaseForEditFixture(
        displayName: 'Planning',
        description: 'Setup tasks',
      );
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessPhaseEditorDialog(
          phase: phase,
          onUpdate: (_) {},
        ),
      ));
      await openDialog(tester);
      expect(find.widgetWithText(TextField, 'Planning'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Setup tasks'), findsOneWidget);
    });

    testWidgets('renders 8 color swatches', (tester) async {
      final phase = phaseForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessPhaseEditorDialog(
          phase: phase,
          onUpdate: (_) {},
        ),
      ));
      await openDialog(tester);
      for (final c in ['blue', 'green', 'amber', 'red', 'purple', 'pink', 'cyan', 'gray']) {
        expect(find.byKey(ValueKey('color-swatch-$c')), findsOneWidget);
      }
    });

    testWidgets('tapping non-current swatch fires onUpdate({color: <new>})',
        (tester) async {
      Map<String, dynamic>? updates;
      final phase = phaseForEditFixture(color: 'blue');
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessPhaseEditorDialog(
          phase: phase,
          onUpdate: (u) => updates = u,
        ),
      ));
      await openDialog(tester);
      await tester.tap(find.byKey(const ValueKey('color-swatch-amber')));
      await tester.pump();
      expect(updates?['color'], 'amber');
    });

    testWidgets('tapping current swatch is a no-op', (tester) async {
      int callCount = 0;
      final phase = phaseForEditFixture(color: 'blue');
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessPhaseEditorDialog(
          phase: phase,
          onUpdate: (_) => callCount += 1,
        ),
      ));
      await openDialog(tester);
      await tester.tap(find.byKey(const ValueKey('color-swatch-blue')));
      await tester.pump();
      expect(callCount, 0);
    });

    testWidgets('toggling a checkbox fires onUpdate({field: !current})',
        (tester) async {
      Map<String, dynamic>? updates;
      final phase = phaseForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessPhaseEditorDialog(
          phase: phase,
          onUpdate: (u) => updates = u,
        ),
      ));
      await openDialog(tester);
      // Phase has isMilestone=false; tap milestone checkbox should fire
      // onUpdate({isMilestone: true}).
      await tester.tap(find.byKey(const ValueKey('checkbox-row-Milestone')));
      await tester.pump();
      expect(updates?['isMilestone'], true);
    });

    testWidgets('Enter in Name field saves trimmed value', (tester) async {
      Map<String, dynamic>? updates;
      final phase = phaseForEditFixture(displayName: 'Planning');
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessPhaseEditorDialog(
          phase: phase,
          onUpdate: (u) => updates = u,
        ),
      ));
      await openDialog(tester);
      await tester.enterText(find.widgetWithText(TextField, 'Planning'), '  Discovery  ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(updates?['displayName'], 'Discovery');
    });

    testWidgets('whitespace-only name does NOT fire onUpdate', (tester) async {
      int callCount = 0;
      final phase = phaseForEditFixture(displayName: 'Planning');
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessPhaseEditorDialog(
          phase: phase,
          onUpdate: (_) => callCount += 1,
        ),
      ));
      await openDialog(tester);
      await tester.enterText(find.widgetWithText(TextField, 'Planning'), '    ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(callCount, 0);
    });

    testWidgets('Close button pops the dialog', (tester) async {
      final phase = phaseForEditFixture();
      await tester.pumpWidget(dialogTestHarness(
        (ctx) => EdenProcessPhaseEditorDialog(
          phase: phase,
          onUpdate: (_) {},
        ),
      ));
      await openDialog(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
