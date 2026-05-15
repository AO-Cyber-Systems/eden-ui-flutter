import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_currency_display_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenCurrencyDisplay', () {
    testWidgets('renders positive USD cents as \$125.00', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCurrencyDisplay(cents: 12500),
      ));
      expect(find.text(r'$125.00'), findsOneWidget);
    });

    testWidgets('renders negative USD cents as -\$50.00', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCurrencyDisplay(cents: -5000),
      ));
      expect(find.text(r'-$50.00'), findsOneWidget);
    });

    testWidgets('renders zero as \$0.00', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCurrencyDisplay(cents: 0),
      ));
      expect(find.text(r'$0.00'), findsOneWidget);
    });

    testWidgets('renders +\$50.00 when showSign=true and positive',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCurrencyDisplay(cents: 5000, showSign: true),
      ));
      expect(find.text(r'+$50.00'), findsOneWidget);
    });

    testWidgets('renders \$50 (no cents) when showCents=false', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCurrencyDisplay(cents: 5000, showCents: false),
      ));
      expect(find.text(r'$50'), findsOneWidget);
    });

    testWidgets('renders thousands separator for \$12,345.00', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCurrencyDisplay(cents: 1234500),
      ));
      expect(find.text(r'$12,345.00'), findsOneWidget);
    });

    testWidgets('renders EUR symbol with currencyCode=EUR', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCurrencyDisplay(cents: 12500, currencyCode: 'EUR'),
      ));
      expect(find.text('€125.00'), findsOneWidget);
    });

    testWidgets('renders GBP symbol with currencyCode=GBP', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCurrencyDisplay(cents: 12500, currencyCode: 'GBP'),
      ));
      expect(find.text('£125.00'), findsOneWidget);
    });

    testWidgets('renders very large amount with separators correctly',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCurrencyDisplay(cents: 100000000),
      ));
      expect(find.text(r'$1,000,000.00'), findsOneWidget);
    });

    testWidgets('colorize=true uses primary color for positive', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCurrencyDisplay(cents: 5000, colorize: true),
      ));
      final textWidget = tester.widget<Text>(find.text(r'$50.00'));
      final BuildContext ctx = tester.element(find.text(r'$50.00'));
      expect(textWidget.style?.color, Theme.of(ctx).colorScheme.primary);
    });

    testWidgets('colorize=true uses error color for negative', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCurrencyDisplay(cents: -5000, colorize: true),
      ));
      final textWidget = tester.widget<Text>(find.text(r'-$50.00'));
      final BuildContext ctx = tester.element(find.text(r'-$50.00'));
      expect(textWidget.style?.color, Theme.of(ctx).colorScheme.error);
    });

    testWidgets('colorize=true on zero does not apply positive/negative override',
        (tester) async {
      // Capture the default (non-colorized) zero color.
      await tester.pumpWidget(wrap(
        const EdenCurrencyDisplay(cents: 0),
      ));
      final defaultColor =
          tester.widget<Text>(find.text(r'$0.00')).style?.color;

      // With colorize=true and zero, the rendered color matches default
      // (i.e., no positive/negative override is applied).
      await tester.pumpWidget(wrap(
        const EdenCurrencyDisplay(cents: 0, colorize: true),
      ));
      final colorizedZeroColor =
          tester.widget<Text>(find.text(r'$0.00')).style?.color;
      expect(colorizedZeroColor, defaultColor);
    });

    testWidgets(
        'iPhone-narrow safe: renders inside narrow SizedBox without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 200 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(wrap(
        const SizedBox(
          width: 60,
          child: EdenCurrencyDisplay(cents: 1234500),
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('all fixture expectations render expected strings',
        (tester) async {
      for (final exp in EdenCurrencyDisplayFixtures.expectations) {
        await tester.pumpWidget(wrap(
          EdenCurrencyDisplay(
            cents: exp.cents,
            currencyCode: exp.currencyCode,
            showSign: exp.showSign,
            showCents: exp.showCents,
          ),
        ));
        expect(
          find.text(exp.expected),
          findsOneWidget,
          reason:
              'cents=${exp.cents} code=${exp.currencyCode} showSign=${exp.showSign} showCents=${exp.showCents}',
        );
      }
    });
  });
}
