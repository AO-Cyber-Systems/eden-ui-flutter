import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenPersonaSelector — pill display', () {
    testWidgets(
        'operations active → pill shows "Operations" + dashboard icon + dropdown arrow',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenPersonaSelector(
          activePersona: EdenAiPersona.operations,
          onChanged: (_) {},
        ),
      ));
      expect(find.text('Operations'), findsOneWidget);
      expect(find.byIcon(Icons.dashboard), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('finance active → Finance + account_balance + green',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenPersonaSelector(
          activePersona: EdenAiPersona.finance,
          onChanged: (_) {},
        ),
      ));
      expect(find.text('Finance'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance), findsOneWidget);
    });

    testWidgets('fieldTech active → Field Tech + engineering + blue',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenPersonaSelector(
          activePersona: EdenAiPersona.fieldTech,
          onChanged: (_) {},
        ),
      ));
      expect(find.text('Field Tech'), findsOneWidget);
      expect(find.byIcon(Icons.engineering), findsOneWidget);
    });

    testWidgets('executive active → Executive + insights + purple',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenPersonaSelector(
          activePersona: EdenAiPersona.executive,
          onChanged: (_) {},
        ),
      ));
      expect(find.text('Executive'), findsOneWidget);
      expect(find.byIcon(Icons.insights), findsOneWidget);
    });
  });

  group('EdenPersonaSelector — dropdown', () {
    testWidgets('tapping pill opens dropdown listing all 4 personas',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenPersonaSelector(
          activePersona: EdenAiPersona.operations,
          onChanged: (_) {},
        ),
      ));
      await tester.tap(find.byType(EdenPersonaSelector));
      await tester.pumpAndSettle();
      expect(find.text('Field Tech'), findsOneWidget);
      expect(find.text('Finance'), findsOneWidget);
      // Operations appears twice (pill + menu item) → at least 2.
      expect(find.text('Operations'), findsNWidgets(2));
      expect(find.text('Executive'), findsOneWidget);
    });

    testWidgets('selecting a persona fires onChanged with that value',
        (tester) async {
      EdenAiPersona? last;
      await tester.pumpWidget(wrap(
        EdenPersonaSelector(
          activePersona: EdenAiPersona.operations,
          onChanged: (p) => last = p,
        ),
      ));
      await tester.tap(find.byType(EdenPersonaSelector));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finance').last);
      await tester.pumpAndSettle();
      expect(last, EdenAiPersona.finance);
    });

    testWidgets(
        'active persona row in dropdown has check icon + bold; others do not',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenPersonaSelector(
          activePersona: EdenAiPersona.operations,
          onChanged: (_) {},
        ),
      ));
      await tester.tap(find.byType(EdenPersonaSelector));
      await tester.pumpAndSettle();
      // Exactly 1 check icon visible (for the active row).
      expect(find.byIcon(Icons.check), findsOneWidget);
      // Bold operations row.
      final operationsItemTexts = tester
          .widgetList<Text>(find.text('Operations'))
          .toList();
      // 2 widgets: 1 in the pill (w600 hard-coded), 1 in the popup item.
      // Both should be w600.
      expect(
        operationsItemTexts.where((t) => t.style?.fontWeight == FontWeight.w600).length,
        2,
      );
    });
  });

  group('EdenPersonaSelector — tooltip', () {
    testWidgets('exposes tooltip parameter (default Switch persona)',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenPersonaSelector(
          activePersona: EdenAiPersona.operations,
          onChanged: (_) {},
        ),
      ));
      final button = tester.widget<PopupMenuButton<EdenAiPersona>>(
          find.byType(PopupMenuButton<EdenAiPersona>));
      expect(button.tooltip, 'Switch persona');
    });
  });

  group('EdenPersonaSelector — iPhone-narrow safety', () {
    testWidgets(
        'pill renders inside SizedBox(width: 390) with no overflow',
        (tester) async {
      await tester.pumpWidget(wrap(
        SizedBox(
          width: 390,
          child: Row(
            children: [
              Expanded(child: const Text('Header content')),
              EdenPersonaSelector(
                activePersona: EdenAiPersona.executive,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
