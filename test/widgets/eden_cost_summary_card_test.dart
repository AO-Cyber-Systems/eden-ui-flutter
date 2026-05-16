import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenCostSummaryCard', () {
    testWidgets(
        'renders 3 line items + total for default labor/material/equipment values',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCostSummaryCard(
          laborCents: 120000,
          materialCents: 45000,
          equipmentCents: 25000,
        ),
      ));
      expect(find.text('Labor'), findsOneWidget);
      expect(find.text('Materials'), findsOneWidget);
      expect(find.text('Equipment'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      // Total in dollars formatted by EdenCurrencyDisplay.
      expect(find.text(r'$1,900.00'), findsOneWidget);
    });

    testWidgets('renders default title "Cost Summary" when none provided',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCostSummaryCard(
          laborCents: 0,
          materialCents: 0,
          equipmentCents: 0,
        ),
      ));
      expect(find.text('Cost Summary'), findsOneWidget);
    });

    testWidgets('renders custom title override',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCostSummaryCard(
          laborCents: 0,
          materialCents: 0,
          equipmentCents: 0,
          title: 'Project Budget',
        ),
      ));
      expect(find.text('Project Budget'), findsOneWidget);
      expect(find.text('Cost Summary'), findsNothing);
    });

    testWidgets(
        'composes EdenCurrencyDisplay for every monetary value (4 in default case)',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCostSummaryCard(
          laborCents: 120000,
          materialCents: 45000,
          equipmentCents: 25000,
        ),
      ));
      expect(find.byType(EdenCurrencyDisplay), findsNWidgets(4));
    });

    testWidgets('negative cents in a line item renders with leading sign',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCostSummaryCard(
          laborCents: 10000,
          materialCents: -5000,
          equipmentCents: 0,
        ),
      ));
      // Materials line shows '-$50.00'.
      expect(find.text(r'-$50.00'), findsOneWidget);
    });

    testWidgets(
        'extraRows render in order between equipment and total',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCostSummaryCard(
          laborCents: 100,
          materialCents: 100,
          equipmentCents: 100,
          extraRows: [
            EdenCostRow(label: 'Subcontractor', cents: 50000),
            EdenCostRow(label: 'Permits', cents: 7500),
          ],
        ),
      ));
      expect(find.text('Subcontractor'), findsOneWidget);
      expect(find.text('Permits'), findsOneWidget);
      // 5 line items + 1 total = 6 EdenCurrencyDisplay instances.
      expect(find.byType(EdenCurrencyDisplay), findsNWidgets(6));
    });

    testWidgets(
        'donor quirk: extraRows do NOT contribute to displayed total',
        (tester) async {
      // labor + material + equipment = 300 cents → '\$3.00' regardless of extraRows.
      await tester.pumpWidget(wrap(
        const EdenCostSummaryCard(
          laborCents: 100,
          materialCents: 100,
          equipmentCents: 100,
          extraRows: [
            EdenCostRow(label: 'Subcontractor', cents: 50000),
            EdenCostRow(label: 'Permits', cents: 7500),
          ],
        ),
      ));
      expect(find.text(r'$3.00'), findsOneWidget);
      // Subcontractor's value should still be present in its line item.
      expect(find.text(r'$500.00'), findsOneWidget);
    });

    testWidgets(
        'iPhone-narrow: no overflow inside SizedBox(width: 390)',
        (tester) async {
      await tester.pumpWidget(wrap(
        const SizedBox(
          width: 390,
          child: EdenCostSummaryCard(
            laborCents: 120000,
            materialCents: 45000,
            equipmentCents: 25000,
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'iPhone-narrow with long label ellipsizes without overflowing the row',
        (tester) async {
      await tester.pumpWidget(wrap(
        const SizedBox(
          width: 390,
          child: EdenCostSummaryCard(
            laborCents: 100,
            materialCents: 100,
            equipmentCents: 100,
            extraRows: [
              EdenCostRow(
                label: 'Equipment rental + operator labor (50ch label)',
                cents: 100000,
              ),
            ],
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
