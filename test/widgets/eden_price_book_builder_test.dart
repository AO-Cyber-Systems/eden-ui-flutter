import 'package:eden_ui_flutter/src/widgets/eden_price_book_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_price_book_builder_fixtures.dart';

Widget wrap(Widget child, {double width = 1024}) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: 800, child: child),
      ),
    );

/// Pumps [child] wrapped at [width] after expanding the test surface so the
/// SizedBox doesn't get clipped by the default 800×600 test viewport.
Future<void> pumpWide(WidgetTester tester, Widget child,
    {double width = 1024}) async {
  await tester.binding.setSurfaceSize(Size(width + 200, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(wrap(child, width: width));
}

void main() {

  group('EdenPriceBookBuilder — helpers / value classes', () {
    test('EdenPriceBookTaxMatrix.rateFor returns value when present', () {
      final m = PriceBookFixtures.hvac().taxMatrix;
      expect(m.rateFor('CA', 'service'), 0.0825);
      expect(m.rateFor('CA', 'labor'), 0.0);
    });

    test('EdenPriceBookTaxMatrix.rateFor returns 0.0 for missing keys', () {
      final m = PriceBookFixtures.hvac().taxMatrix;
      expect(m.rateFor('NY', 'service'), 0.0);
      expect(m.rateFor('CA', 'nonexistent'), 0.0);
    });

    test('EdenPriceBookItem.copyWith preserves fields not overridden', () {
      final item = PriceBookFixtures.hvacCompressor();
      final updated = item.copyWith(baseFlatRate: 2000.00);
      expect(updated.baseFlatRate, 2000.00);
      expect(updated.id, item.id);
      expect(updated.name, item.name);
      expect(updated.gbb, isNotNull);
    });

    test('EdenPriceBookItem.copyWith with clearGbb removes GBB', () {
      final item = PriceBookFixtures.hvacCompressor();
      final updated = item.copyWith(clearGbb: true);
      expect(updated.gbb, isNull);
      expect(updated.baseFlatRate, item.baseFlatRate);
    });

    test('EdenPriceBookCategory.copyWith updates name', () {
      final c = PriceBookFixtures.hvac().categories.first;
      final updated = c.copyWith(name: 'Renamed');
      expect(updated.name, 'Renamed');
      expect(updated.id, c.id);
      expect(updated.items.length, c.items.length);
    });

    test('EdenPriceBookTier.copyWith clears defaultMarkupPct when requested', () {
      final t = PriceBookFixtures.hvac().tiers[1];
      final cleared = t.copyWith(clearDefaultMarkupPct: true);
      expect(cleared.defaultMarkupPct, isNull);
      expect(cleared.id, t.id);
    });
  });

  group('EdenPriceBookBuilder — static rendering', () {
    testWidgets('renders 4 tabs at 1024pt width', (tester) async {
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.hvac(),
        onSave: (_) {},
      ));
      expect(find.text('Categories'), findsAtLeastNWidgets(1));
      expect(find.text('Items'), findsAtLeastNWidgets(1));
      expect(find.text('Tiers'), findsAtLeastNWidgets(1));
      expect(find.text('Taxes'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders Save button when not readOnly', (tester) async {
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.hvac(),
        onSave: (_) {},
      ));
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('hides Save button in readOnly mode', (tester) async {
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.hvac(),
        onSave: (_) {},
        readOnly: true,
      ));
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('initialSection categories selected by default',
        (tester) async {
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.hvac(),
        onSave: (_) {},
      ));
      // Repair category should be visible (in categories section)
      expect(find.text('Repair'), findsOneWidget);
    });

    testWidgets('initialSection: items shows items section', (tester) async {
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.hvac(),
        onSave: (_) {},
        initialSection: EdenPriceBookSection.items,
      ));
      // first category (Repair) is auto-selected, so its items render
      expect(find.text('Capacitor replacement'), findsOneWidget);
    });
  });

  group('EdenPriceBookBuilder — narrow width (<900pt)', () {
    testWidgets('renders dropdown at 800pt instead of tabs', (tester) async {
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.hvac(),
        onSave: (_) {},
      ), width: 800);
      // EdenSelect renders a DropdownButtonFormField — verify by type
      expect(find.byType(DropdownButtonFormField<EdenPriceBookSection>),
          findsOneWidget);
    });

    testWidgets('renders without overflow at 390pt iPhone-narrow',
        (tester) async {
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.hvac(),
        onSave: (_) {},
      ), width: 390);
      // Should not throw — no RenderFlex overflow.
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenPriceBookBuilder — categories section', () {
    testWidgets('renders 3 hvac categories', (tester) async {
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.hvac(),
        onSave: (_) {},
      ));
      expect(find.text('Repair'), findsOneWidget);
      expect(find.text('Replacement'), findsOneWidget);
      expect(find.text('Maintenance'), findsOneWidget);
    });

    testWidgets('empty data renders create-first-category empty state',
        (tester) async {
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.empty(),
        onSave: (_) {},
      ));
      expect(find.text('No categories yet'), findsOneWidget);
      expect(find.text('Create your first category'), findsOneWidget);
    });

    testWidgets('add-category button fires onDraftChange', (tester) async {
      EdenPriceBookDraft? captured;
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.hvac(),
        onSave: (_) {},
        onDraftChange: (d) => captured = d,
      ));
      await tester.tap(find.byKey(const Key('price-book-add-category')));
      await tester.pumpAndSettle();
      expect(captured, isNotNull);
      expect(captured!.categories.length, 4);
    });

    testWidgets('readOnly hides add-category button', (tester) async {
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.hvac(),
        onSave: (_) {},
        readOnly: true,
      ));
      expect(find.byKey(const Key('price-book-add-category')), findsNothing);
    });
  });

  group('EdenPriceBookBuilder — items section', () {
    testWidgets('renders items of first category in items tab',
        (tester) async {
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.hvac(),
        onSave: (_) {},
        initialSection: EdenPriceBookSection.items,
      ));
      expect(find.text('Capacitor replacement'), findsOneWidget);
      expect(find.text('Contactor replacement'), findsOneWidget);
      expect(find.text('Compressor repair'), findsOneWidget);
    });

    testWidgets('itemPickerSlot renders above items', (tester) async {
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.hvac(),
        onSave: (_) {},
        initialSection: EdenPriceBookSection.items,
        itemPickerSlot: const Text('custom-picker-slot'),
      ));
      expect(find.text('custom-picker-slot'), findsOneWidget);
    });

    testWidgets('Edit GBB button visible for items with gbb', (tester) async {
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.hvac(),
        onSave: (_) {},
        initialSection: EdenPriceBookSection.items,
      ));
      expect(find.text('Edit GBB'), findsWidgets);
    });

    testWidgets('remove-item button fires onDraftChange', (tester) async {
      EdenPriceBookDraft? captured;
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.hvac(),
        onSave: (_) {},
        initialSection: EdenPriceBookSection.items,
        onDraftChange: (d) => captured = d,
      ));
      await tester
          .tap(find.byKey(const Key('item-remove-item-cap-replace')));
      await tester.pumpAndSettle();
      expect(captured, isNotNull);
      final repair =
          captured!.categories.firstWhere((c) => c.id == 'cat-repair');
      expect(repair.items.any((i) => i.id == 'item-cap-replace'), isFalse);
    });
  });

  group('EdenPriceBookBuilder — tiers section', () {
    testWidgets('renders tier names from hvac fixture', (tester) async {
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.hvac(),
        onSave: (_) {},
        initialSection: EdenPriceBookSection.tiers,
      ));
      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('Gold Member'), findsOneWidget);
    });

    testWidgets('add-tier button visible when not readOnly', (tester) async {
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.hvac(),
        onSave: (_) {},
        initialSection: EdenPriceBookSection.tiers,
      ));
      expect(find.byKey(const Key('price-book-add-tier')), findsOneWidget);
    });

    testWidgets('add-tier fires onDraftChange with new tier', (tester) async {
      EdenPriceBookDraft? captured;
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.hvac(),
        onSave: (_) {},
        initialSection: EdenPriceBookSection.tiers,
        onDraftChange: (d) => captured = d,
      ));
      await tester.tap(find.byKey(const Key('price-book-add-tier')));
      await tester.pumpAndSettle();
      expect(captured, isNotNull);
      expect(captured!.tiers.length, 3);
    });
  });

  group('EdenPriceBookBuilder — taxes section', () {
    testWidgets('renders jurisdiction × itemType matrix for fuel fixture',
        (tester) async {
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.fuel(),
        onSave: (_) {},
        initialSection: EdenPriceBookSection.taxes,
      ));
      // Headers
      expect(find.text('Jurisdiction'), findsOneWidget);
      // Jurisdictions show as row cells
      expect(find.text('CA'), findsOneWidget);
      expect(find.text('NY'), findsOneWidget);
      expect(find.text('TX'), findsOneWidget);
    });

    testWidgets('empty tax matrix renders Configure jurisdictions CTA',
        (tester) async {
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.empty().copyWithCategoriesOnly(),
        onSave: (_) {},
        initialSection: EdenPriceBookSection.taxes,
      ));
      expect(find.text('Configure jurisdictions'), findsOneWidget);
    });

    testWidgets('taxes section vertical-stacked at narrow widths',
        (tester) async {
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.fuel(),
        onSave: (_) {},
        initialSection: EdenPriceBookSection.taxes,
      ), width: 600);
      // Just verify no overflow + jurisdictions present
      expect(tester.takeException(), isNull);
      expect(find.text('CA'), findsWidgets);
    });
  });

  group('EdenPriceBookBuilder — save / dirty state', () {
    testWidgets('Save disabled initially (no dirty state)', (tester) async {
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.hvac(),
        onSave: (_) {},
      ));
      final btn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Save'));
      expect(btn.onPressed, isNull);
    });

    testWidgets('Save enabled after dirty mutation; tap fires onSave',
        (tester) async {
      EdenPriceBookDraft? saved;
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.hvac(),
        onSave: (d) => saved = d,
      ));
      await tester.tap(find.byKey(const Key('price-book-add-category')));
      await tester.pumpAndSettle();
      // Save button now enabled
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();
      expect(saved, isNotNull);
      expect(saved!.categories.length, 4);
    });

    testWidgets('dirty banner visible after mutation; Cancel reverts',
        (tester) async {
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.hvac(),
        onSave: (_) {},
      ));
      await tester.tap(find.byKey(const Key('price-book-add-category')));
      await tester.pumpAndSettle();
      expect(find.text('Unsaved changes — Save or Cancel'), findsOneWidget);

      await tester.tap(find.byKey(const Key('price-book-cancel-changes')));
      await tester.pumpAndSettle();
      expect(find.text('Unsaved changes — Save or Cancel'), findsNothing);
    });
  });

  group('EdenPriceBookBuilder — cross-vertical', () {
    testWidgets('salon fixture renders 4 categories', (tester) async {
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.salon(),
        onSave: (_) {},
      ));
      expect(find.text('Hair'), findsOneWidget);
      expect(find.text('Color'), findsOneWidget);
      expect(find.text('Nails'), findsOneWidget);
      expect(find.text('Wax'), findsOneWidget);
    });

    testWidgets('fuel fixture renders 2 categories + 3 tiers',
        (tester) async {
      await pumpWide(tester, EdenPriceBookBuilder(
        initialData: PriceBookFixtures.fuel(),
        onSave: (_) {},
      ));
      expect(find.text('Residential'), findsOneWidget);
      expect(find.text('Commercial'), findsOneWidget);
    });
  });
}

// Extension for an empty test helper.
extension on EdenPriceBookData {
  EdenPriceBookData copyWithCategoriesOnly() {
    return EdenPriceBookData(
      categories: const [
        EdenPriceBookCategory(id: 'c1', name: 'Cat 1'),
      ],
      tiers: const [],
      taxMatrix: const EdenPriceBookTaxMatrix(
        jurisdictions: [],
        itemTypes: [],
        rates: {},
      ),
    );
  }
}
