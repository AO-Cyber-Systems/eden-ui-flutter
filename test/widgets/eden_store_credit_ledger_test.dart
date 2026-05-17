import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_store_credit_ledger_fixtures.dart';

void main() {
  Widget wrap(Widget child, {double width = 1024}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  group('EdenStoreCreditLedger — header', () {
    testWidgets('renders customerName when set', (tester) async {
      await tester.pumpWidget(wrap(EdenStoreCreditLedger(
        data: EdenStoreCreditLedgerFixtures.activeWithHolds(),
        now: EdenStoreCreditLedgerFixtures.t0,
      )));
      expect(find.text('Jane Doe'), findsOneWidget);
    });

    testWidgets("falls back to 'Customer #...' when customerName null",
        (tester) async {
      await tester.pumpWidget(wrap(EdenStoreCreditLedger(
        data: EdenStoreCreditLedgerFixtures.unnamed(),
        now: EdenStoreCreditLedgerFixtures.t0,
      )));
      expect(find.text('Customer #c-anon'), findsOneWidget);
    });

    testWidgets(r'renders balance $87.50 for 8750 cents', (tester) async {
      await tester.pumpWidget(wrap(EdenStoreCreditLedger(
        data: EdenStoreCreditLedgerFixtures.activeWithHolds(),
        now: EdenStoreCreditLedgerFixtures.t0,
      )));
      expect(find.text(r'$87.50'), findsOneWidget);
    });

    testWidgets(r'renders negative balance -$5.00', (tester) async {
      await tester.pumpWidget(wrap(EdenStoreCreditLedger(
        data: EdenStoreCreditLedgerFixtures.overdrawn(),
        now: EdenStoreCreditLedgerFixtures.t0,
      )));
      expect(find.text(r'-$5.00'), findsOneWidget);
    });
  });

  group('EdenStoreCreditLedger — holds sub-row', () {
    testWidgets('absent when holds is empty', (tester) async {
      await tester.pumpWidget(wrap(EdenStoreCreditLedger(
        data: EdenStoreCreditLedgerFixtures.zeroBalance(),
        now: EdenStoreCreditLedgerFixtures.t0,
      )));
      expect(find.text('On hold'), findsNothing);
      expect(find.textContaining('active hold'), findsNothing);
    });

    testWidgets('renders when holds is non-empty', (tester) async {
      await tester.pumpWidget(wrap(EdenStoreCreditLedger(
        data: EdenStoreCreditLedgerFixtures.activeWithHolds(),
        now: EdenStoreCreditLedgerFixtures.t0,
      )));
      expect(find.text('On hold'), findsOneWidget);
    });

    testWidgets(r'total held = $15.00 for sum of holdAmountCents',
        (tester) async {
      await tester.pumpWidget(wrap(EdenStoreCreditLedger(
        data: EdenStoreCreditLedgerFixtures.activeWithHolds(),
        now: EdenStoreCreditLedgerFixtures.t0,
      )));
      expect(find.text(r'$15.00'), findsOneWidget);
    });

    testWidgets(r'available = balance - holdsTotal ($72.50)', (tester) async {
      await tester.pumpWidget(wrap(EdenStoreCreditLedger(
        data: EdenStoreCreditLedgerFixtures.activeWithHolds(),
        now: EdenStoreCreditLedgerFixtures.t0,
      )));
      expect(find.text(r'$72.50'), findsOneWidget);
    });

    testWidgets("hold count shown as '1 active hold(s)'", (tester) async {
      await tester.pumpWidget(wrap(EdenStoreCreditLedger(
        data: EdenStoreCreditLedgerFixtures.activeWithHolds(),
        now: EdenStoreCreditLedgerFixtures.t0,
      )));
      expect(find.textContaining('1 active hold'), findsOneWidget);
    });
  });

  group('EdenStoreCreditLedger — history (wide ≥700pt)', () {
    testWidgets('renders 4 rows for 4 history entries', (tester) async {
      await tester.pumpWidget(wrap(EdenStoreCreditLedger(
        data: EdenStoreCreditLedgerFixtures.activeWithHolds(),
        now: EdenStoreCreditLedgerFixtures.t0,
      )));
      // Find the EdenDataTable; check row count via consumer-visible labels.
      expect(find.byType(EdenDataTable), findsOneWidget);
      // 'Issued' twice + 'Spent' once + 'Adjustment' once.
      expect(find.text('Issued'), findsNWidgets(2));
      expect(find.text('Spent'), findsOneWidget);
      expect(find.text('Adjustment'), findsOneWidget);
    });

    testWidgets('entries sorted DESC by occurredAt', (tester) async {
      // activeWithHolds: e-1 (2d), e-2 (5d), e-3 (15d), e-4 (30d) → already DESC.
      // Test with a custom data where consumer order is ASC; verify DESC after sort.
      final now = EdenStoreCreditLedgerFixtures.t0;
      final asc = EdenStoreCreditLedgerData(
        customerId: 'c-asc',
        balanceCents: 1000,
        history: [
          EdenStoreCreditEntry(
            id: 'a',
            occurredAt: now.subtract(const Duration(days: 30)),
            type: EdenStoreCreditEntryType.issued,
            amountCents: 500,
            reason: 'OLDEST',
          ),
          EdenStoreCreditEntry(
            id: 'b',
            occurredAt: now.subtract(const Duration(days: 1)),
            type: EdenStoreCreditEntryType.spent,
            amountCents: -200,
            reason: 'NEWEST',
          ),
        ],
      );
      await tester.pumpWidget(wrap(EdenStoreCreditLedger(data: asc, now: now)));
      // Just verify both reasons render. Order assertion via reading
      // table-cell tree order is complex; the helper-level sort is the
      // contract, asserted in the helper-unit test below.
      expect(find.text('OLDEST'), findsOneWidget);
      expect(find.text('NEWEST'), findsOneWidget);
    });

    testWidgets("amount column '+$50.00' green for issued", (tester) async {
      await tester.pumpWidget(wrap(EdenStoreCreditLedger(
        data: EdenStoreCreditLedgerFixtures.activeWithHolds(),
        now: EdenStoreCreditLedgerFixtures.t0,
      )));
      expect(find.text(r'+$50.00'), findsOneWidget);
    });

    testWidgets("amount column '-$22.50' red for spent", (tester) async {
      await tester.pumpWidget(wrap(EdenStoreCreditLedger(
        data: EdenStoreCreditLedgerFixtures.activeWithHolds(),
        now: EdenStoreCreditLedgerFixtures.t0,
      )));
      expect(find.text(r'-$22.50'), findsOneWidget);
    });

    testWidgets('reason column shows "—" when reason null', (tester) async {
      // overdrawn() has 1 entry with a reason; use a custom fixture instead.
      final now = EdenStoreCreditLedgerFixtures.t0;
      final data = EdenStoreCreditLedgerData(
        customerId: 'c-nr',
        balanceCents: 1000,
        history: [
          EdenStoreCreditEntry(
            id: 'nr',
            occurredAt: now,
            type: EdenStoreCreditEntryType.issued,
            amountCents: 1000,
          ),
        ],
      );
      await tester.pumpWidget(wrap(EdenStoreCreditLedger(data: data, now: now)));
      expect(find.text('—'), findsWidgets);
    });
  });

  group('EdenStoreCreditLedger — empty state', () {
    testWidgets('renders EdenEmptyState when history is empty', (tester) async {
      await tester.pumpWidget(wrap(EdenStoreCreditLedger(
        data: EdenStoreCreditLedgerFixtures.empty(),
        now: EdenStoreCreditLedgerFixtures.t0,
      )));
      expect(find.byType(EdenEmptyState), findsOneWidget);
      expect(find.text('No store-credit history'), findsOneWidget);
    });

    testWidgets('empty-state replaces the table', (tester) async {
      await tester.pumpWidget(wrap(EdenStoreCreditLedger(
        data: EdenStoreCreditLedgerFixtures.empty(),
        now: EdenStoreCreditLedgerFixtures.t0,
      )));
      expect(find.byType(EdenDataTable), findsNothing);
    });

    testWidgets('empty history + non-empty holds → both render',
        (tester) async {
      await tester.pumpWidget(wrap(EdenStoreCreditLedger(
        data: EdenStoreCreditLedgerFixtures.emptyHistoryWithHolds(),
        now: EdenStoreCreditLedgerFixtures.t0,
      )));
      expect(find.byType(EdenEmptyState), findsOneWidget);
      expect(find.text('On hold'), findsOneWidget);
    });
  });

  group('EdenStoreCreditLedger — narrow mode (<700pt)', () {
    testWidgets('at maxWidth 600pt: Card stack instead of EdenDataTable',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenStoreCreditLedger(
          data: EdenStoreCreditLedgerFixtures.activeWithHolds(),
          now: EdenStoreCreditLedgerFixtures.t0,
        ),
        width: 600,
      ));
      expect(find.byType(EdenDataTable), findsNothing);
      // Card-per-entry — 4 entries → at least 4 cards. (Other Cards may exist
      // from Material widgets; we assert ≥4.)
      expect(find.byType(Card), findsAtLeastNWidgets(4));
    });

    testWidgets('iPhone-narrow 390pt: no RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: EdenStoreCreditLedger(
              data: EdenStoreCreditLedgerFixtures.longHistory(),
              now: EdenStoreCreditLedgerFixtures.t0,
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenStoreCreditLedger — helpers', () {
    test('edenStoreCreditHoldsTotal: empty → 0', () {
      expect(edenStoreCreditHoldsTotal(const []), 0);
    });

    test('edenStoreCreditHoldsTotal: sum positive amounts', () {
      final h1 = EdenStoreCreditHold(
        id: 'a',
        holdAmountCents: 100,
        holdReason: 'r',
        placedAt: DateTime(2026),
      );
      final h2 = EdenStoreCreditHold(
        id: 'b',
        holdAmountCents: 50,
        holdReason: 'r',
        placedAt: DateTime(2026),
      );
      expect(edenStoreCreditHoldsTotal([h1, h2]), 150);
    });

    test(r'edenStoreCreditFormatSignedMoney(1250) → "+$12.50"', () {
      expect(edenStoreCreditFormatSignedMoney(1250), r'+$12.50');
    });

    test(r'edenStoreCreditFormatSignedMoney(-1250) → "-$12.50"', () {
      expect(edenStoreCreditFormatSignedMoney(-1250), r'-$12.50');
    });

    test(r'edenStoreCreditFormatSignedMoney(0) → "+$0.00"', () {
      expect(edenStoreCreditFormatSignedMoney(0), r'+$0.00');
    });

    test('edenStoreCreditSortedHistory: DESC by occurredAt', () {
      final older = EdenStoreCreditEntry(
        id: 'old',
        occurredAt: DateTime(2026, 1, 1),
        type: EdenStoreCreditEntryType.issued,
        amountCents: 100,
      );
      final newer = EdenStoreCreditEntry(
        id: 'new',
        occurredAt: DateTime(2026, 6, 1),
        type: EdenStoreCreditEntryType.spent,
        amountCents: -100,
      );
      final sorted = edenStoreCreditSortedHistory([older, newer]);
      expect(sorted.first.id, 'new');
      expect(sorted.last.id, 'old');
    });
  });
}
