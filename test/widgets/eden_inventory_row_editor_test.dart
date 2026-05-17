import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_inventory_row_editor_fixtures.dart';

Widget wrap(Widget child, {double width = 1200, double height = 200}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );

void main() {
  group('EdenInventoryRowEditor — read-only mode static rendering', () {
    testWidgets('renders SKU text', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(const EdenInventoryRowEditor(
          data: EdenInventoryRowFixtures.coffeeBeans,
        )),
      );
      expect(find.text('CB-001'), findsOneWidget);
    });

    testWidgets('renders name text', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(const EdenInventoryRowEditor(
          data: EdenInventoryRowFixtures.coffeeBeans,
        )),
      );
      expect(find.text('Espresso Blend 1kg'), findsOneWidget);
    });

    testWidgets('renders cost via EdenCurrencyDisplay when non-null',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(const EdenInventoryRowEditor(
          data: EdenInventoryRowFixtures.coffeeBeans,
        )),
      );
      // Two EdenCurrencyDisplays (cost + price).
      expect(find.byType(EdenCurrencyDisplay), findsNWidgets(2));
    });

    testWidgets('renders onHand text', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(const EdenInventoryRowEditor(
          data: EdenInventoryRowFixtures.coffeeBeans,
        )),
      );
      expect(find.text('18'), findsOneWidget);
    });

    testWidgets('renders reorderPoint text', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(const EdenInventoryRowEditor(
          data: EdenInventoryRowFixtures.coffeeBeans,
        )),
      );
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('renders location text', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(const EdenInventoryRowEditor(
          data: EdenInventoryRowFixtures.coffeeBeans,
        )),
      );
      expect(find.text('A-12'), findsOneWidget);
    });

    testWidgets('renders EdenStockLevelIndicator when onHand+reorderPoint non-null',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(const EdenInventoryRowEditor(
          data: EdenInventoryRowFixtures.coffeeBeans,
        )),
      );
      expect(find.byType(EdenStockLevelIndicator), findsOneWidget);
    });

    testWidgets('read-only mode renders edit pencil icon', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(const EdenInventoryRowEditor(
          data: EdenInventoryRowFixtures.coffeeBeans,
        )),
      );
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });
  });

  group('EdenInventoryRowEditor — null field handling', () {
    testWidgets('costCents null shows em-dash', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(const EdenInventoryRowEditor(
          data: EdenInventoryRowFixtures.minimal,
        )),
      );
      // 5 em-dashes for cost / price / onHand / reorderPoint / location.
      expect(find.text('—'), findsNWidgets(5));
    });

    testWidgets('priceCents null shows em-dash', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(const EdenInventoryRowEditor(
          data: EdenInventoryRowFixtures.minimal,
        )),
      );
      // No EdenCurrencyDisplay rendered when cost+price both null.
      expect(find.byType(EdenCurrencyDisplay), findsNothing);
    });

    testWidgets('onHand+reorderPoint both null → no stock indicator',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(const EdenInventoryRowEditor(
          data: EdenInventoryRowFixtures.minimal,
        )),
      );
      expect(find.byType(EdenStockLevelIndicator), findsNothing);
    });

    testWidgets('onHand non-null with reorderPoint null → stock indicator renders binary',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(const EdenInventoryRowEditor(
          data: EdenInventoryRowFixtures.stockNoReorder,
        )),
      );
      expect(find.byType(EdenStockLevelIndicator), findsOneWidget);
    });
  });

  group('EdenInventoryRowEditor — editable mode', () {
    testWidgets('editable: true renders EdenInputs for editable cells',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(const EdenInventoryRowEditor(
          data: EdenInventoryRowFixtures.coffeeBeans,
          editable: true,
        )),
      );
      // 5 inputs: cost / price / onHand / reorder / location.
      expect(find.byType(EdenInput), findsNWidgets(5));
    });

    testWidgets('editable: true renders Save + Cancel icon buttons',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(const EdenInventoryRowEditor(
          data: EdenInventoryRowFixtures.coffeeBeans,
          editable: true,
        )),
      );
      expect(find.byTooltip('Save'), findsOneWidget);
      expect(find.byTooltip('Cancel'), findsOneWidget);
      // And no edit-pencil.
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });

    testWidgets('editable cost input pre-populated with formatted cents',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(const EdenInventoryRowEditor(
          data: EdenInventoryRowFixtures.coffeeBeans,
          editable: true,
        )),
      );
      expect(find.text('12.00'), findsOneWidget);
      expect(find.text('24.00'), findsOneWidget);
    });
  });

  group('EdenInventoryRowEditor — bulk-select checkbox', () {
    testWidgets('selected: false renders unchecked', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenInventoryRowEditor(
          data: EdenInventoryRowFixtures.coffeeBeans,
          onSelectionChanged: (_, __) {},
        )),
      );
      final cb = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(cb.value, false);
    });

    testWidgets('selected: true renders checked', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenInventoryRowEditor(
          data: EdenInventoryRowFixtures.coffeeBeans,
          selected: true,
          onSelectionChanged: (_, __) {},
        )),
      );
      final cb = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(cb.value, true);
    });

    testWidgets('tap on checkbox fires onSelectionChanged with rowId + new value',
        (tester) async {
      String? capturedId;
      bool? capturedSel;
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenInventoryRowEditor(
          data: EdenInventoryRowFixtures.coffeeBeans,
          onSelectionChanged: (id, sel) {
            capturedId = id;
            capturedSel = sel;
          },
        )),
      );
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(capturedId, 'r-1');
      expect(capturedSel, true);
    });

    testWidgets('onSelectionChanged: null disables the checkbox',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(const EdenInventoryRowEditor(
          data: EdenInventoryRowFixtures.coffeeBeans,
        )),
      );
      final cb = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(cb.onChanged, isNull);
    });
  });

  group('EdenInventoryRowEditor — edit interactions', () {
    testWidgets('edit cost → Save fires onCommit with costCents change',
        (tester) async {
      EdenInventoryRowDraft? captured;
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenInventoryRowEditor(
          data: EdenInventoryRowFixtures.coffeeBeans,
          editable: true,
          onCommit: (d) => captured = d,
        )),
      );
      // Cost input is the first EdenInput in the row.
      final costField = find.byType(TextField).first;
      await tester.enterText(costField, '14.99');
      await tester.tap(find.byTooltip('Save'));
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!.costCents, 1499);
      expect(captured!.priceCents, isNull);
      expect(captured!.onHand, isNull);
    });

    testWidgets('edit price + onHand → Save → multi-field draft',
        (tester) async {
      EdenInventoryRowDraft? captured;
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenInventoryRowEditor(
          data: EdenInventoryRowFixtures.coffeeBeans,
          editable: true,
          onCommit: (d) => captured = d,
        )),
      );
      final fields = find.byType(TextField);
      // Field order: cost(0) price(1) onHand(2) reorder(3) location(4).
      await tester.enterText(fields.at(1), '29.95');
      await tester.enterText(fields.at(2), '50');
      await tester.tap(find.byTooltip('Save'));
      await tester.pump();
      expect(captured!.priceCents, 2995);
      expect(captured!.onHand, 50);
      expect(captured!.costCents, isNull);
      expect(captured!.reorderPoint, isNull);
      expect(captured!.location, isNull);
    });

    testWidgets('edit + Cancel does NOT fire onCommit', (tester) async {
      int commitCount = 0;
      bool cancelFired = false;
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenInventoryRowEditor(
          data: EdenInventoryRowFixtures.coffeeBeans,
          editable: true,
          onCommit: (_) => commitCount++,
          onCancel: () => cancelFired = true,
        )),
      );
      await tester.enterText(find.byType(TextField).first, '99.99');
      await tester.tap(find.byTooltip('Cancel'));
      await tester.pump();
      expect(commitCount, 0);
      expect(cancelFired, true);
    });

    testWidgets('no edits → Save fires onCommit with hasAnyChange=false',
        (tester) async {
      EdenInventoryRowDraft? captured;
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenInventoryRowEditor(
          data: EdenInventoryRowFixtures.coffeeBeans,
          editable: true,
          onCommit: (d) => captured = d,
        )),
      );
      await tester.tap(find.byTooltip('Save'));
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!.hasAnyChange, false);
    });
  });

  group('EdenInventoryRowEditor — compact mode', () {
    testWidgets('400pt constraint auto-derives compact', (tester) async {
      await tester.pumpWidget(
        wrap(
          const EdenInventoryRowEditor(
            data: EdenInventoryRowFixtures.coffeeBeans,
          ),
          width: 400,
        ),
      );
      expect(
        find.byKey(const ValueKey('eden-inventory-row-compact')),
        findsOneWidget,
      );
    });

    testWidgets('800pt constraint auto-derives expanded', (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(
          const EdenInventoryRowEditor(
            data: EdenInventoryRowFixtures.coffeeBeans,
          ),
          width: 800,
        ),
      );
      expect(
        find.byKey(const ValueKey('eden-inventory-row-expanded')),
        findsOneWidget,
      );
    });

    testWidgets('explicit compact: true at 1200pt still compact',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const EdenInventoryRowEditor(
            data: EdenInventoryRowFixtures.coffeeBeans,
            compact: true,
          ),
          width: 1200,
        ),
      );
      expect(
        find.byKey(const ValueKey('eden-inventory-row-compact')),
        findsOneWidget,
      );
    });

    testWidgets('explicit compact: false at 400pt still expanded',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const EdenInventoryRowEditor(
            data: EdenInventoryRowFixtures.coffeeBeans,
            compact: false,
          ),
          width: 400,
        ),
      );
      expect(
        find.byKey(const ValueKey('eden-inventory-row-expanded')),
        findsOneWidget,
      );
    });
  });

  group('EdenInventoryRowEditor — iPhone-narrow safety', () {
    testWidgets('390pt renders without RenderFlex overflow + uses compact mode',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EdenInventoryRowEditor(
              data: EdenInventoryRowFixtures.coffeeBeans,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('eden-inventory-row-compact')),
        findsOneWidget,
      );
    });
  });
}
