import 'package:eden_ui_flutter/src/widgets/eden_delivery_variance_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_delivery_variance_card_fixtures.dart';

Widget wrap(Widget child, {double width = 500}) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(width: width, child: child),
        ),
      ),
    );

Future<void> pumpWide(WidgetTester tester, Widget child,
    {double width = 500}) async {
  await tester.binding.setSurfaceSize(Size(width + 100, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(wrap(child, width: width));
}

void main() {
  group('computeVariancePct helper', () {
    test('returns correct fraction', () {
      expect(computeVariancePct(100, 110), closeTo(0.10, 1e-9));
      expect(computeVariancePct(850, 700), closeTo(-0.1764, 1e-3));
    });

    test('handles divide-by-zero', () {
      expect(computeVariancePct(0, 100), 0);
    });

    test('returns 0 when equal', () {
      expect(computeVariancePct(100, 100), 0);
    });
  });

  group('classifyVariance helper', () {
    test('within threshold (inclusive)', () {
      expect(classifyVariance(0.10, 0.10),
          EdenVarianceSeverity.withinThreshold);
      expect(classifyVariance(0.05, 0.10),
          EdenVarianceSeverity.withinThreshold);
    });

    test('borderline (between 1x and 2x)', () {
      expect(classifyVariance(0.15, 0.10), EdenVarianceSeverity.borderline);
      expect(classifyVariance(0.20, 0.10), EdenVarianceSeverity.borderline);
    });

    test('exceeds threshold (>2x)', () {
      expect(classifyVariance(0.25, 0.10),
          EdenVarianceSeverity.exceedsThreshold);
    });
  });

  group('EdenDeliveryVarianceCard — static rendering', () {
    testWidgets('renders Scheduled + Actual labels', (tester) async {
      await pumpWide(
        tester,
        EdenDeliveryVarianceCard(
          data: VarianceFixtures.underFill(),
          onSubmit: (_) {},
        ),
      );
      expect(find.text('Scheduled'), findsOneWidget);
      expect(find.text('Actual'), findsOneWidget);
    });

    testWidgets('renders variance percentage with sign and magnitude',
        (tester) async {
      await pumpWide(
        tester,
        EdenDeliveryVarianceCard(
          data: VarianceFixtures.underFill(),
          onSubmit: (_) {},
        ),
      );
      expect(find.textContaining('Variance: -17.6%'), findsOneWidget);
    });

    testWidgets('renders threshold band color key', (tester) async {
      await pumpWide(
        tester,
        EdenDeliveryVarianceCard(
          data: VarianceFixtures.underFill(),
          onSubmit: (_) {},
        ),
      );
      expect(find.byKey(const Key('variance-band-color')), findsOneWidget);
    });
  });

  group('EdenDeliveryVarianceCard — metric unit labels', () {
    testWidgets('gallons metric shows "gal"', (tester) async {
      await pumpWide(
        tester,
        EdenDeliveryVarianceCard(
          data: VarianceFixtures.overFill(),
          onSubmit: (_) {},
        ),
      );
      expect(find.textContaining('gal'), findsAtLeastNWidgets(1));
    });

    testWidgets('hours metric shows "hr"', (tester) async {
      await pumpWide(
        tester,
        EdenDeliveryVarianceCard(
          data: VarianceFixtures.laborHours(),
          onSubmit: (_) {},
        ),
      );
      expect(find.textContaining('hr'), findsAtLeastNWidgets(1));
    });

    testWidgets('fee metric shows "\$" prefix', (tester) async {
      await pumpWide(
        tester,
        EdenDeliveryVarianceCard(
          data: VarianceFixtures.feeVariance(),
          onSubmit: (_) {},
        ),
      );
      expect(find.textContaining('\$25.00'), findsOneWidget);
      expect(find.textContaining('\$28.50'), findsOneWidget);
    });

    testWidgets('custom metric uses unitLabel', (tester) async {
      await pumpWide(
        tester,
        EdenDeliveryVarianceCard(
          data: VarianceFixtures.customLbs(),
          onSubmit: (_) {},
        ),
      );
      expect(find.textContaining('lbs'), findsAtLeastNWidgets(1));
    });
  });

  group('EdenDeliveryVarianceCard — submit gating', () {
    testWidgets('within threshold + no reason → submit enabled',
        (tester) async {
      await pumpWide(
        tester,
        EdenDeliveryVarianceCard(
          data: VarianceFixtures.overFill(),
          onSubmit: (_) {},
        ),
      );
      final btn = tester.widget<ElevatedButton>(
          find.byKey(const Key('variance-submit')));
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('exceeds threshold + no reason → submit disabled',
        (tester) async {
      await pumpWide(
        tester,
        EdenDeliveryVarianceCard(
          data: VarianceFixtures.underFill(),
          onSubmit: (_) {},
        ),
      );
      final btn = tester.widget<ElevatedButton>(
          find.byKey(const Key('variance-submit')));
      expect(btn.onPressed, isNull);
    });

    testWidgets('exceeds threshold + tap submit (after reason set) fires onSubmit',
        (tester) async {
      EdenDeliveryVarianceDraft? captured;
      await pumpWide(
        tester,
        EdenDeliveryVarianceCard(
          data: VarianceFixtures.underFill(),
          onSubmit: (d) => captured = d,
          initialDraft: EdenDeliveryVarianceDraft(
            data: VarianceFixtures.underFill(),
            reason: EdenDeliveryVarianceReason.tankCapEarly,
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('variance-submit')));
      await tester.pumpAndSettle();
      expect(captured, isNotNull);
      expect(captured!.reason, EdenDeliveryVarianceReason.tankCapEarly);
    });
  });

  group('EdenDeliveryVarianceCard — photo gallery', () {
    testWidgets('onPickPhoto null → no Add Photo button', (tester) async {
      await pumpWide(
        tester,
        EdenDeliveryVarianceCard(
          data: VarianceFixtures.underFill(),
          onSubmit: (_) {},
        ),
      );
      expect(find.byKey(const Key('variance-add-photo')), findsNothing);
    });

    testWidgets('onPickPhoto set → Add Photo button visible; tap appends URL',
        (tester) async {
      await pumpWide(
        tester,
        EdenDeliveryVarianceCard(
          data: VarianceFixtures.underFill(),
          onSubmit: (_) {},
          onPickPhoto: (ctx) async => 'https://example.com/test.jpg',
        ),
      );
      expect(find.byKey(const Key('variance-add-photo')), findsOneWidget);
      await tester.tap(find.byKey(const Key('variance-add-photo')));
      await tester.pumpAndSettle();
      // Photo placeholder thumbnail rendered
      expect(find.byIcon(Icons.photo), findsOneWidget);
    });
  });

  group('EdenDeliveryVarianceCard — read-only mode', () {
    testWidgets('hides reason picker / submit button / disposition picker',
        (tester) async {
      await pumpWide(
        tester,
        EdenDeliveryVarianceCard(
          data: VarianceFixtures.underFill(),
          onSubmit: (_) {},
          readOnly: true,
          initialDraft: VarianceFixtures.acceptedDraft(),
        ),
      );
      expect(find.byKey(const Key('variance-submit')), findsNothing);
      expect(find.text('Reason'), findsNothing);
      expect(find.textContaining('Disposition: Accepted'), findsOneWidget);
    });

    testWidgets('still shows variance summary in read-only', (tester) async {
      await pumpWide(
        tester,
        EdenDeliveryVarianceCard(
          data: VarianceFixtures.underFill(),
          onSubmit: (_) {},
          readOnly: true,
        ),
      );
      expect(find.text('Scheduled'), findsOneWidget);
      expect(find.text('Actual'), findsOneWidget);
    });
  });

  group('EdenDeliveryVarianceCard — responsive', () {
    testWidgets('side-by-side at >=500pt', (tester) async {
      await pumpWide(
        tester,
        EdenDeliveryVarianceCard(
          data: VarianceFixtures.underFill(),
          onSubmit: (_) {},
        ),
        width: 600,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('iPhone-narrow (390pt) renders without overflow',
        (tester) async {
      await pumpWide(
        tester,
        EdenDeliveryVarianceCard(
          data: VarianceFixtures.underFill(),
          onSubmit: (_) {},
        ),
        width: 390,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
