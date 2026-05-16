import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_fuel_price_ticker_fixtures.dart';

void main() {
  Widget wrap(Widget child, {double width = 400, double height = 200}) =>
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: width, height: height, child: child),
        ),
      );

  Color deltaChipColorOf(WidgetTester tester) {
    final container = tester.widget<Container>(
      find.byKey(const ValueKey('eden-fuel-price-delta-chip')),
    );
    return (container.decoration as BoxDecoration).color!;
  }

  // -----------------------------------------------------------------
  // Task 1 — Static rendering + delta chip (default polarity) +
  // relative-time formatter
  // -----------------------------------------------------------------
  group('EdenFuelPriceTicker static rendering', () {
    testWidgets('renders fuel-type label', (tester) async {
      await tester.pumpWidget(wrap(
        EdenFuelPriceTicker(
          data: EdenFuelPriceTickerFixtures.up5cents,
          now: EdenFuelPriceTickerFixtures.asOfRef.add(
            const Duration(minutes: 5),
          ),
        ),
      ));
      expect(find.text('Heating oil'), findsOneWidget);
    });

    testWidgets('composes EdenCurrencyDisplay with cents from data',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenFuelPriceTicker(
          data: EdenFuelPriceTickerFixtures.up5cents,
          now: EdenFuelPriceTickerFixtures.asOfRef,
        ),
      ));
      final cd = tester.widget<EdenCurrencyDisplay>(
        find.byType(EdenCurrencyDisplay),
      );
      expect(cd.cents, 250);
    });

    testWidgets('renders relative-time caption', (tester) async {
      await tester.pumpWidget(wrap(
        EdenFuelPriceTicker(
          data: EdenFuelPriceTickerFixtures.up5cents,
          now: EdenFuelPriceTickerFixtures.asOfRef.add(
            const Duration(hours: 1),
          ),
        ),
      ));
      expect(find.text('Updated 1h ago'), findsOneWidget);
    });
  });

  group('EdenFuelPriceTicker delta chip — default polarity (lowerIsBetter)',
      () {
    testWidgets('up5cents → red chip + up arrow + +\$0.05 label',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenFuelPriceTicker(
          data: EdenFuelPriceTickerFixtures.up5cents,
          now: EdenFuelPriceTickerFixtures.asOfRef,
        ),
      ));
      expect(deltaChipColorOf(tester), EdenColors.error);
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      expect(find.text(r'+$0.05'), findsOneWidget);
    });

    testWidgets('down10cents → green chip + down arrow + −\$0.10 label '
        '(unicode minus)', (tester) async {
      await tester.pumpWidget(wrap(
        EdenFuelPriceTicker(
          data: EdenFuelPriceTickerFixtures.down10cents,
          now: EdenFuelPriceTickerFixtures.asOfRef,
        ),
      ));
      expect(deltaChipColorOf(tester), EdenColors.success);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      // Unicode minus U+2212 — NOT ASCII hyphen.
      expect(find.text('−\$0.10'), findsOneWidget);
    });

    testWidgets('flat → grey chip + flat icon + "No change"', (tester) async {
      await tester.pumpWidget(wrap(
        EdenFuelPriceTicker(
          data: EdenFuelPriceTickerFixtures.flat,
          now: EdenFuelPriceTickerFixtures.asOfRef,
        ),
      ));
      expect(deltaChipColorOf(tester), const Color(0xFF94A3B8));
      expect(find.byIcon(Icons.trending_flat), findsOneWidget);
      expect(find.text('No change'), findsOneWidget);
    });

    testWidgets('largeUp1dollar → +\$1.00 label', (tester) async {
      await tester.pumpWidget(wrap(
        EdenFuelPriceTicker(
          data: EdenFuelPriceTickerFixtures.largeUp1dollar,
          now: EdenFuelPriceTickerFixtures.asOfRef,
        ),
      ));
      expect(find.text(r'+$1.00'), findsOneWidget);
    });
  });

  group('EdenFuelPriceTicker currency code', () {
    testWidgets('EUR renders € symbol', (tester) async {
      await tester.pumpWidget(wrap(
        EdenFuelPriceTicker(
          data: EdenFuelPriceTickerFixtures.euroPrice,
          now: EdenFuelPriceTickerFixtures.asOfRef,
        ),
      ));
      expect(find.textContaining('€'), findsOneWidget);
    });
  });

  group('EdenFuelPriceTicker.formatRelative', () {
    final asOf = DateTime(2026, 5, 16, 9, 0);

    test('asOf+3s → just now', () {
      expect(
        EdenFuelPriceTicker.formatRelative(
            asOf, asOf.add(const Duration(seconds: 3))),
        'Updated just now',
      );
    });

    test('asOf+45s → 45s ago', () {
      expect(
        EdenFuelPriceTicker.formatRelative(
            asOf, asOf.add(const Duration(seconds: 45))),
        'Updated 45s ago',
      );
    });

    test('asOf+5m → 5m ago', () {
      expect(
        EdenFuelPriceTicker.formatRelative(
            asOf, asOf.add(const Duration(minutes: 5))),
        'Updated 5m ago',
      );
    });

    test('asOf+2h → 2h ago', () {
      expect(
        EdenFuelPriceTicker.formatRelative(
            asOf, asOf.add(const Duration(hours: 2))),
        'Updated 2h ago',
      );
    });

    test('asOf+25h → 1d ago', () {
      expect(
        EdenFuelPriceTicker.formatRelative(
            asOf, asOf.add(const Duration(hours: 25))),
        'Updated 1d ago',
      );
    });

    test('asOf+72h → 3d ago', () {
      expect(
        EdenFuelPriceTicker.formatRelative(
            asOf, asOf.add(const Duration(hours: 72))),
        'Updated 3d ago',
      );
    });
  });
}
