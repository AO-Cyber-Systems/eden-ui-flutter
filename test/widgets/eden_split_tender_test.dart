import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_split_tender_fixtures.dart';

Widget wrap(Widget child, {double width = 600}) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(width: width, child: child),
        ),
      ),
    );

void main() {
  // ─────────────────────────────────────────────────────────────────────
  // Initial state / summary header
  // ─────────────────────────────────────────────────────────────────────

  group('EdenSplitTender — initial state + summary header', () {
    testWidgets('no initialDrafts: renders 1 EdenPaymentEntry default-method-amount-of-total', (tester) async {
      await tester.pumpWidget(wrap(EdenSplitTender(
        total: 50.0,
        allowedMethods: const [EdenPaymentMethod.cash, EdenPaymentMethod.card],
        onDraftsChanged: (_) {},
      )));
      expect(find.byType(EdenPaymentEntry), findsOneWidget);
    });

    testWidgets('summary header: "Total: \$50.00", "Tendered: \$50.00", "Remaining: \$0.00"', (tester) async {
      await tester.pumpWidget(wrap(EdenSplitTender(
        total: 50.0,
        allowedMethods: const [EdenPaymentMethod.cash, EdenPaymentMethod.card],
        onDraftsChanged: (_) {},
      )));
      expect(find.text(r'Total: $50.00'), findsOneWidget);
      expect(find.text(r'Tendered: $50.00'), findsOneWidget);
      expect(find.text(r'Remaining: $0.00'), findsOneWidget);
    });

    testWidgets('balanced state shows banner with text "Balanced"', (tester) async {
      await tester.pumpWidget(wrap(EdenSplitTender(
        total: 50.0,
        allowedMethods: const [EdenPaymentMethod.cash, EdenPaymentMethod.card],
        onDraftsChanged: (_) {},
      )));
      expect(find.textContaining('Balanced'), findsOneWidget);
      expect(find.byType(EdenBanner), findsOneWidget);
    });

    testWidgets('initialDrafts=twoWayCashCard renders 2 rows', (tester) async {
      await tester.pumpWidget(wrap(EdenSplitTender(
        total: 50.0,
        allowedMethods: const [
          EdenPaymentMethod.cash,
          EdenPaymentMethod.card,
        ],
        onDraftsChanged: (_) {},
        initialDrafts: EdenSplitTenderFixtures.twoWayCashCard(),
      )));
      expect(find.byType(EdenPaymentEntry), findsNWidgets(2));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Aggregation math (under/over)
  // ─────────────────────────────────────────────────────────────────────

  group('EdenSplitTender — aggregation banners', () {
    testWidgets('balanced (30+20=50, total 50) → balanced success banner', (tester) async {
      await tester.pumpWidget(wrap(EdenSplitTender(
        total: 50.0,
        allowedMethods: const [
          EdenPaymentMethod.cash,
          EdenPaymentMethod.card,
        ],
        onDraftsChanged: (_) {},
        initialDrafts: EdenSplitTenderFixtures.twoWayCashCard(),
      )));
      expect(find.textContaining('Balanced'), findsOneWidget);
    });

    testWidgets('underCapacity (60 / 100) → Remaining banner with "\$40.00"', (tester) async {
      await tester.pumpWidget(wrap(EdenSplitTender(
        total: 100.0,
        allowedMethods: const [EdenPaymentMethod.card, EdenPaymentMethod.cash],
        onDraftsChanged: (_) {},
        initialDrafts: EdenSplitTenderFixtures.underCapacity(),
      )));
      // The summary header AND the banner can both surface "Remaining" —
      // assert at-least-one finder for the dollar amount.
      expect(find.textContaining(r'$40.00'), findsAtLeastNWidgets(1));
      expect(find.byType(EdenBanner), findsOneWidget);
    });

    testWidgets('overCapacity (70+50=120 / 100), allowOverCapacity=false → "Over total by \$20.00"', (tester) async {
      await tester.pumpWidget(wrap(EdenSplitTender(
        total: 100.0,
        allowedMethods: const [
          EdenPaymentMethod.cash,
          EdenPaymentMethod.card,
        ],
        onDraftsChanged: (_) {},
        initialDrafts: EdenSplitTenderFixtures.overCapacity(),
      )));
      expect(find.textContaining(r'Over total by $20.00'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Add row
  // ─────────────────────────────────────────────────────────────────────

  group('EdenSplitTender — add row', () {
    testWidgets('tap Add payment method → onDraftsChanged emits N+1 drafts', (tester) async {
      List<EdenPaymentDraft>? captured;
      await tester.pumpWidget(wrap(EdenSplitTender(
        total: 50.0,
        allowedMethods: const [
          EdenPaymentMethod.cash,
          EdenPaymentMethod.card,
        ],
        onDraftsChanged: (next) => captured = next,
      )));
      // Initial state: 1 row implicit.
      await tester.tap(find.text('Add payment method'));
      await tester.pumpAndSettle();
      expect(captured, isNotNull);
      expect(captured!.length, 2);
    });

    testWidgets('balanced state → new row default amount=0 (remaining is 0)', (tester) async {
      List<EdenPaymentDraft>? captured;
      await tester.pumpWidget(wrap(EdenSplitTender(
        total: 50.0,
        allowedMethods: const [
          EdenPaymentMethod.cash,
          EdenPaymentMethod.card,
        ],
        onDraftsChanged: (next) => captured = next,
      )));
      await tester.tap(find.text('Add payment method'));
      await tester.pumpAndSettle();
      expect(captured!.last.amount, closeTo(0.0, 0.0001));
    });

    testWidgets('under-capacity (remaining \$40) → new row amount=40', (tester) async {
      List<EdenPaymentDraft>? captured;
      await tester.pumpWidget(wrap(EdenSplitTender(
        total: 100.0,
        allowedMethods: const [EdenPaymentMethod.card, EdenPaymentMethod.cash],
        onDraftsChanged: (next) => captured = next,
        initialDrafts: EdenSplitTenderFixtures.underCapacity(),
      )));
      await tester.tap(find.text('Add payment method'));
      await tester.pumpAndSettle();
      expect(captured!.last.amount, closeTo(40.0, 0.0001));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Remove row
  // ─────────────────────────────────────────────────────────────────────

  group('EdenSplitTender — remove row', () {
    testWidgets('3-row → tap remove row 1 → onDraftsChanged with row 1 absent', (tester) async {
      List<EdenPaymentDraft>? captured;
      await tester.pumpWidget(wrap(EdenSplitTender(
        total: 120.0,
        allowedMethods: const [
          EdenPaymentMethod.cash,
          EdenPaymentMethod.card,
          EdenPaymentMethod.check,
        ],
        onDraftsChanged: (next) => captured = next,
        initialDrafts: EdenSplitTenderFixtures.threeWaySplit(),
      )));
      // 3 remove IconButtons present.
      final removeButtons = find.byTooltip('Remove payment row');
      expect(removeButtons, findsNWidgets(3));
      await tester.tap(removeButtons.at(1));
      await tester.pumpAndSettle();
      expect(captured, isNotNull);
      expect(captured!.length, 2);
      // The remaining drafts are first + third.
      expect(captured![0].method, EdenPaymentMethod.cash);
      expect(captured![1].method, EdenPaymentMethod.check);
    });

    testWidgets('1-row state → no remove IconButton', (tester) async {
      await tester.pumpWidget(wrap(EdenSplitTender(
        total: 50.0,
        allowedMethods: const [EdenPaymentMethod.cash, EdenPaymentMethod.card],
        onDraftsChanged: (_) {},
      )));
      expect(find.byTooltip('Remove payment row'), findsNothing);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Cash change-due rule (allowOverCapacity=true)
  // ─────────────────────────────────────────────────────────────────────

  group('EdenSplitTender — cash change-due rule', () {
    testWidgets('cash overpay, allowOverCapacity=true → "Change due: \$10.00"', (tester) async {
      await tester.pumpWidget(wrap(EdenSplitTender(
        total: 50.0,
        allowedMethods: const [EdenPaymentMethod.cash, EdenPaymentMethod.card],
        onDraftsChanged: (_) {},
        allowOverCapacity: true,
        initialDrafts: EdenSplitTenderFixtures.cashOverpayment(),
      )));
      expect(find.textContaining(r'Change due: $10.00'), findsOneWidget);
    });

    testWidgets('card overpay, allowOverCapacity=true → "Overage: \$10.00" (no change-due)', (tester) async {
      await tester.pumpWidget(wrap(EdenSplitTender(
        total: 50.0,
        allowedMethods: const [EdenPaymentMethod.cash, EdenPaymentMethod.card],
        onDraftsChanged: (_) {},
        allowOverCapacity: true,
        initialDrafts: EdenSplitTenderFixtures.cardOverpayment(),
      )));
      // Two matches: summary header ("Overage: $10.00") + EdenBanner.
      expect(find.textContaining(r'Overage: $10.00'), findsAtLeastNWidgets(1));
      expect(find.byType(EdenBanner), findsOneWidget);
      expect(find.textContaining('Change due'), findsNothing);
    });

    testWidgets('allowOverCapacity=false → over-error banner regardless of method', (tester) async {
      await tester.pumpWidget(wrap(EdenSplitTender(
        total: 50.0,
        allowedMethods: const [EdenPaymentMethod.cash, EdenPaymentMethod.card],
        onDraftsChanged: (_) {},
        initialDrafts: EdenSplitTenderFixtures.cashOverpayment(),
      )));
      expect(find.textContaining(r'Over total by'), findsOneWidget);
      expect(find.textContaining('Change due'), findsNothing);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // iPhone-narrow (390pt)
  // ─────────────────────────────────────────────────────────────────────

  group('EdenSplitTender — iPhone-narrow 390pt responsive', () {
    testWidgets('3-row split at width 390 — no RenderFlex overflow', (tester) async {
      await tester.pumpWidget(wrap(
        EdenSplitTender(
          total: 120.0,
          allowedMethods: const [
            EdenPaymentMethod.cash,
            EdenPaymentMethod.card,
            EdenPaymentMethod.check,
          ],
          onDraftsChanged: (_) {},
          initialDrafts: EdenSplitTenderFixtures.threeWaySplit(),
        ),
        width: 390,
      ));
      expect(tester.takeException(), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Section 508 a11y
  // ─────────────────────────────────────────────────────────────────────

  group('EdenSplitTender — Section 508 a11y', () {
    testWidgets('summary Semantics label contains "Total" + "Tendered" + "Remaining"', (tester) async {
      await tester.pumpWidget(wrap(EdenSplitTender(
        total: 50.0,
        allowedMethods: const [EdenPaymentMethod.cash, EdenPaymentMethod.card],
        onDraftsChanged: (_) {},
      )));
      expect(
        find.bySemanticsLabel(r'Total: $50.00. Tendered: $50.00. Remaining: $0.00.'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('add-row button has tooltip + Semantics "Add payment method"', (tester) async {
      await tester.pumpWidget(wrap(EdenSplitTender(
        total: 50.0,
        allowedMethods: const [EdenPaymentMethod.cash, EdenPaymentMethod.card],
        onDraftsChanged: (_) {},
      )));
      expect(find.byTooltip('Add payment method'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Add payment method'),
        findsAtLeastNWidgets(1),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Export surface
  // ─────────────────────────────────────────────────────────────────────

  group('EdenSplitTender — export surface', () {
    test('public name reachable from eden_ui.dart', () {
      final st = EdenSplitTender(
        total: 50.0,
        allowedMethods: const [EdenPaymentMethod.cash],
        onDraftsChanged: (_) {},
      );
      expect(st.total, 50.0);
    });
  });
}
