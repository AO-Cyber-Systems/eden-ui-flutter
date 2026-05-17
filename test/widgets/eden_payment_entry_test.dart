import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_payment_entry_fixtures.dart';

Widget wrap(Widget child, {double width = 400}) => MaterialApp(
      home: Scaffold(body: SizedBox(width: width, child: child)),
    );

void main() {
  // ─────────────────────────────────────────────────────────────────────
  // Enum + value class
  // ─────────────────────────────────────────────────────────────────────

  group('EdenPaymentMethod enum', () {
    test('displayLabel maps for all 8 methods', () {
      expect(EdenPaymentMethod.cash.displayLabel, 'Cash');
      expect(EdenPaymentMethod.card.displayLabel, 'Card');
      expect(EdenPaymentMethod.ach.displayLabel, 'ACH');
      expect(EdenPaymentMethod.check.displayLabel, 'Check');
      expect(EdenPaymentMethod.portal.displayLabel, 'Portal');
      expect(EdenPaymentMethod.giftCard.displayLabel, 'Gift card');
      expect(EdenPaymentMethod.accountOnFile.displayLabel, 'Account');
      expect(EdenPaymentMethod.other.displayLabel, 'Other');
    });

    test('iconData maps for all 8 methods', () {
      expect(EdenPaymentMethod.cash.iconData, Icons.payments_outlined);
      expect(EdenPaymentMethod.card.iconData, Icons.credit_card);
      expect(EdenPaymentMethod.ach.iconData, Icons.account_balance_outlined);
      expect(EdenPaymentMethod.check.iconData, Icons.receipt_long_outlined);
      expect(EdenPaymentMethod.portal.iconData, Icons.public);
      expect(EdenPaymentMethod.giftCard.iconData, Icons.card_giftcard);
      expect(EdenPaymentMethod.accountOnFile.iconData, Icons.person_outline);
      expect(EdenPaymentMethod.other.iconData, Icons.more_horiz);
    });
  });

  group('EdenPaymentDraft value class', () {
    test('roundtrip preserves required + optional fields', () {
      const d = EdenPaymentDraft(
        method: EdenPaymentMethod.cash,
        amount: 20.0,
        reference: '4242',
        note: 'tip included',
      );
      expect(d.method, EdenPaymentMethod.cash);
      expect(d.amount, 20.0);
      expect(d.reference, '4242');
      expect(d.note, 'tip included');
      expect(d.capturedAt, isNull);
    });

    test('copyWith(amount: 25) preserves other fields', () {
      const d = EdenPaymentDraft(
        method: EdenPaymentMethod.card,
        amount: 20.0,
        reference: '4242',
      );
      final updated = d.copyWith(amount: 25);
      expect(updated.amount, 25);
      expect(updated.method, EdenPaymentMethod.card);
      expect(updated.reference, '4242');
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Method picker
  // ─────────────────────────────────────────────────────────────────────

  group('EdenPaymentEntry — method picker', () {
    testWidgets('renders one chip per allowed method (POS = 3)', (tester) async {
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: EdenPaymentEntryFixtures.posAllowedMethods(),
        onDraftChanged: (_) {},
      )));
      expect(find.byType(EdenChoiceChip), findsNWidgets(3));
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('Card'), findsOneWidget);
      expect(find.text('Gift card'), findsOneWidget);
    });

    testWidgets('disallowed methods not rendered (POS does NOT show ACH)', (tester) async {
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: EdenPaymentEntryFixtures.posAllowedMethods(),
        onDraftChanged: (_) {},
      )));
      expect(find.text('ACH'), findsNothing);
    });

    testWidgets('tap chip → onDraftChanged fires with new method', (tester) async {
      EdenPaymentDraft? captured;
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: EdenPaymentEntryFixtures.posAllowedMethods(),
        onDraftChanged: (d) => captured = d,
      )));
      await tester.tap(find.text('Card'));
      await tester.pumpAndSettle();
      expect(captured, isNotNull);
      expect(captured!.method, EdenPaymentMethod.card);
    });

    testWidgets('chip Semantics label reflects selection state', (tester) async {
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: EdenPaymentEntryFixtures.posAllowedMethods(),
        onDraftChanged: (_) {},
      )));
      // First method is the default selection (cash for POS).
      expect(
        find.bySemanticsLabel('Cash payment method, selected'),
        findsAtLeastNWidgets(1),
      );
      expect(
        find.bySemanticsLabel('Card payment method, not selected'),
        findsAtLeastNWidgets(1),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Amount entry
  // ─────────────────────────────────────────────────────────────────────

  group('EdenPaymentEntry — amount entry', () {
    testWidgets('amount field has labelText "Amount" and "\$" prefix (USD default)', (tester) async {
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: EdenPaymentEntryFixtures.posAllowedMethods(),
        onDraftChanged: (_) {},
      )));
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text(r'$'), findsOneWidget);
    });

    testWidgets('EUR currencyCode → € prefix', (tester) async {
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: EdenPaymentEntryFixtures.posAllowedMethods(),
        onDraftChanged: (_) {},
        currencyCode: 'EUR',
      )));
      expect(find.text('€'), findsOneWidget);
    });

    testWidgets('entering 20.50 → onDraftChanged with amount 20.5', (tester) async {
      EdenPaymentDraft? captured;
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: EdenPaymentEntryFixtures.posAllowedMethods(),
        onDraftChanged: (d) => captured = d,
      )));
      await tester.enterText(find.byType(TextFormField), '20.50');
      await tester.pump();
      expect(captured!.amount, closeTo(20.5, 0.0001));
    });

    testWidgets('negative -5 stripped to 5 by decimal-only formatter', (tester) async {
      EdenPaymentDraft? captured;
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: EdenPaymentEntryFixtures.posAllowedMethods(),
        onDraftChanged: (d) => captured = d,
      )));
      await tester.enterText(find.byType(TextFormField), '-5');
      await tester.pump();
      expect(captured!.amount, closeTo(5.0, 0.0001));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Initial draft hydration
  // ─────────────────────────────────────────────────────────────────────

  group('EdenPaymentEntry — initial draft hydration', () {
    testWidgets('initialDraft pre-populates chip selection + amount + reference', (tester) async {
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: EdenPaymentEntryFixtures.posAllowedMethods(),
        onDraftChanged: (_) {},
        initialDraft: EdenPaymentEntryFixtures.cardWithLast4(),
      )));
      expect(
        find.bySemanticsLabel('Card payment method, selected'),
        findsAtLeastNWidgets(1),
      );
      // Amount controller text reflects 47.5 (formatted as '47.5').
      expect(find.text('47.5'), findsOneWidget);
      // Reference field shows the last-4.
      expect(find.text('4242'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Reference visibility per method
  // ─────────────────────────────────────────────────────────────────────

  group('EdenPaymentEntry — reference visibility', () {
    testWidgets('cash → no reference field', (tester) async {
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.cash],
        onDraftChanged: (_) {},
      )));
      // The only TextFields are amount + note (no reference).
      expect(find.text('Last 4 of card'), findsNothing);
      expect(find.text('Check #'), findsNothing);
      expect(find.text('Account last 4'), findsNothing);
    });

    testWidgets('card → reference hint "Last 4 of card"', (tester) async {
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.card],
        onDraftChanged: (_) {},
      )));
      expect(find.text('Last 4 of card'), findsOneWidget);
    });

    testWidgets('ach → reference hint "Account last 4"', (tester) async {
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.ach],
        onDraftChanged: (_) {},
      )));
      expect(find.text('Account last 4'), findsOneWidget);
    });

    testWidgets('check → reference hint "Check #"', (tester) async {
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.check],
        onDraftChanged: (_) {},
      )));
      expect(find.text('Check #'), findsOneWidget);
    });

    testWidgets('portal → reference hint "Confirmation #"', (tester) async {
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.portal],
        onDraftChanged: (_) {},
      )));
      expect(find.text('Confirmation #'), findsOneWidget);
    });

    testWidgets('giftCard → reference hint "Gift card #"', (tester) async {
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.giftCard],
        onDraftChanged: (_) {},
      )));
      expect(find.text('Gift card #'), findsOneWidget);
    });

    testWidgets('accountOnFile + requireReference=false → NO reference field', (tester) async {
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.accountOnFile],
        onDraftChanged: (_) {},
      )));
      expect(find.text('Account ID'), findsNothing);
    });

    testWidgets('accountOnFile + requireReference=true → "Account ID" hint', (tester) async {
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.accountOnFile],
        onDraftChanged: (_) {},
        requireReference: true,
      )));
      expect(find.text('Account ID'), findsOneWidget);
    });

    testWidgets('other + requireReference=false → NO reference field', (tester) async {
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.other],
        onDraftChanged: (_) {},
      )));
      expect(find.text('Reference'), findsNothing);
    });

    testWidgets('other + requireReference=true → "Reference" hint', (tester) async {
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.other],
        onDraftChanged: (_) {},
        requireReference: true,
      )));
      expect(find.text('Reference'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Reference + note entry
  // ─────────────────────────────────────────────────────────────────────

  group('EdenPaymentEntry — reference + note entry', () {
    // Locate a TextField via its labelText. TextFormField's inner
    // TextField inherits the decoration from the FormField's builder,
    // so this predicate matches both TextField and TextFormField-under-
    // the-hood TextFields after build.
    Finder fieldByLabel(String labelText) => find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == labelText,
        );

    testWidgets('entering 4242 into reference field → onDraftChanged with reference="4242"', (tester) async {
      EdenPaymentDraft? captured;
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.card],
        onDraftChanged: (d) => captured = d,
      )));
      await tester.enterText(fieldByLabel('Last 4 of card'), '4242');
      await tester.pump();
      expect(captured?.reference, '4242');
    });

    testWidgets('note field always visible (cash + note works)', (tester) async {
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.cash],
        onDraftChanged: (_) {},
      )));
      expect(find.text('Note (optional)'), findsOneWidget);
    });

    testWidgets('entering note → onDraftChanged with note value', (tester) async {
      EdenPaymentDraft? captured;
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.cash],
        onDraftChanged: (d) => captured = d,
      )));
      await tester.enterText(fieldByLabel('Note (optional)'), 'tip included');
      await tester.pump();
      expect(captured?.note, 'tip included');
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Amount-mismatch banner
  // ─────────────────────────────────────────────────────────────────────

  group('EdenPaymentEntry — amount-mismatch banner', () {
    testWidgets('expected=100, amount=100 → no banner', (tester) async {
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.cash],
        onDraftChanged: (_) {},
        expectedAmount: 100.0,
        initialDraft: const EdenPaymentDraft(
          method: EdenPaymentMethod.cash,
          amount: 100.0,
        ),
      )));
      await tester.enterText(find.byType(TextFormField), '100');
      await tester.pump();
      expect(find.byType(EdenBanner), findsNothing);
    });

    testWidgets('expected=100, amount=99.99 → no banner (tolerance)', (tester) async {
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.cash],
        onDraftChanged: (_) {},
        expectedAmount: 100.0,
      )));
      await tester.enterText(find.byType(TextFormField), '99.99');
      await tester.pump();
      expect(find.byType(EdenBanner), findsNothing);
    });

    testWidgets('expected=100, amount=95 → banner with "differs from expected" and "\$100.00"', (tester) async {
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.cash],
        onDraftChanged: (_) {},
        expectedAmount: 100.0,
      )));
      await tester.enterText(find.byType(TextFormField), '95');
      await tester.pump();
      expect(find.byType(EdenBanner), findsOneWidget);
      expect(
        find.textContaining('differs from expected'),
        findsOneWidget,
      );
      expect(
        find.textContaining(r'$100.00'),
        findsOneWidget,
      );
    });

    testWidgets('expected=null → no banner regardless of amount', (tester) async {
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.cash],
        onDraftChanged: (_) {},
      )));
      await tester.enterText(find.byType(TextFormField), '95');
      await tester.pump();
      expect(find.byType(EdenBanner), findsNothing);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // iPhone-narrow (390pt) responsive
  // ─────────────────────────────────────────────────────────────────────

  group('EdenPaymentEntry — iPhone-narrow 390pt responsive', () {
    testWidgets('all 8 methods at width 390 — Wrap reflows, no overflow', (tester) async {
      await tester.pumpWidget(wrap(
        EdenPaymentEntry(
          allowedMethods: EdenPaymentMethod.values,
          onDraftChanged: (_) {},
          requireReference: true,
        ),
        width: 390,
      ));
      expect(tester.takeException(), isNull);
      expect(find.byType(EdenChoiceChip), findsNWidgets(8));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Export surface
  // ─────────────────────────────────────────────────────────────────────

  group('EdenPaymentEntry — export surface', () {
    test('public API names reachable from eden_ui.dart', () {
      const m = EdenPaymentMethod.card;
      const d = EdenPaymentDraft(method: m, amount: 0.0);
      expect(m, EdenPaymentMethod.card);
      expect(d.method, m);
      // EdenPaymentEntry reachable via const construction.
      const entry = EdenPaymentEntry(
        allowedMethods: [EdenPaymentMethod.cash],
        onDraftChanged: _noop,
      );
      expect(entry.allowedMethods.length, 1);
    });
  });
}

void _noop(EdenPaymentDraft _) {}
