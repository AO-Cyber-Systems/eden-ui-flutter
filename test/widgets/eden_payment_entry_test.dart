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

  // ─────────────────────────────────────────────────────────────────────
  // Quick-tender denomination buttons (PCF-12 audit drift fix)
  // ─────────────────────────────────────────────────────────────────────

  group('EdenPaymentEntry — quick-tender denominations', () {
  // 1. No quick-tender row in legacy mode (quickTenderDenominations = null).
  testWidgets('no quick-tender row when quickTenderDenominations is null (legacy mode)', (tester) async {
    await tester.pumpWidget(wrap(EdenPaymentEntry(
      allowedMethods: const [EdenPaymentMethod.cash],
      onDraftChanged: (_) {},
    )));
    // No denomination buttons should be present.
    expect(find.text(r'$5'), findsNothing);
    expect(find.text(r'$10'), findsNothing);
    expect(find.text(r'$20'), findsNothing);
    expect(find.text(r'$50'), findsNothing);
    expect(find.text(r'$100'), findsNothing);
  });

  // 2. Quick-tender row renders $5/$10/$20/$50/$100 buttons.
  testWidgets('renders denomination buttons when quickTenderDenominations provided', (tester) async {
    await tester.pumpWidget(wrap(EdenPaymentEntry(
      allowedMethods: const [EdenPaymentMethod.cash],
      onDraftChanged: (_) {},
      quickTenderDenominations: const [500, 1000, 2000, 5000, 10000],
    )));
    expect(denominationButton(r'$5'), findsOneWidget);
    expect(denominationButton(r'$10'), findsOneWidget);
    expect(denominationButton(r'$20'), findsOneWidget);
    expect(denominationButton(r'$50'), findsOneWidget);
    expect(denominationButton(r'$100'), findsOneWidget);
  });

  // 3. Tap a denomination → tendered amount field increments by that amount.
  testWidgets('tapping a denomination button adds its amount to the tendered field', (tester) async {
    EdenPaymentDraft? captured;
    await tester.pumpWidget(wrap(EdenPaymentEntry(
      allowedMethods: const [EdenPaymentMethod.cash],
      onDraftChanged: (d) => captured = d,
      quickTenderDenominations: const [500, 1000, 2000, 5000, 10000],
    )));
    await tester.tap(denominationButton(r'$20'));
    await tester.pump();
    // $20 = 2000 cents = 20.00
    expect(captured, isNotNull);
    expect(captured!.amount, closeTo(20.0, 0.001));
  });

  // 4. Tap multiple denominations → accumulated (additive, not replace).
  testWidgets('tapping multiple denominations accumulates the total', (tester) async {
    EdenPaymentDraft? captured;
    await tester.pumpWidget(wrap(EdenPaymentEntry(
      allowedMethods: const [EdenPaymentMethod.cash],
      onDraftChanged: (d) => captured = d,
      quickTenderDenominations: const [500, 1000, 2000, 5000, 10000],
    )));
    await tester.tap(denominationButton(r'$20'));
    await tester.pump();
    await tester.tap(denominationButton(r'$10'));
    await tester.pump();
    // $20 + $10 = $30
    expect(captured!.amount, closeTo(30.0, 0.001));
  });

  // 5. showChangeDue=false → no change-due row rendered.
  testWidgets('showChangeDue=false hides the change-due row', (tester) async {
    await tester.pumpWidget(wrap(EdenPaymentEntry(
      allowedMethods: const [EdenPaymentMethod.cash],
      onDraftChanged: (_) {},
      quickTenderDenominations: const [500, 1000, 2000, 5000, 10000],
      // showChangeDue defaults to false
    )));
    expect(find.text('Change due'), findsNothing);
    expect(find.text('Owed'), findsNothing);
    expect(find.textContaining('Change:'), findsNothing);
    expect(find.textContaining('Owed:'), findsNothing);
  });

  // 6. showChangeDue=true + tendered > total → displays "Change: $X.XX".
  testWidgets('showChangeDue=true with tendered > total shows change due', (tester) async {
    await tester.pumpWidget(wrap(EdenPaymentEntry(
      allowedMethods: const [EdenPaymentMethod.cash],
      onDraftChanged: (_) {},
      expectedAmount: 15.0,
      showChangeDue: true,
      quickTenderDenominations: const [500, 1000, 2000, 5000, 10000],
    )));
    // Tap $20 → tendered=20, total=15, change=5
    await tester.tap(denominationButton(r'$20'));
    await tester.pump();
    expect(find.textContaining('Change:'), findsOneWidget);
  });

  // 7. showChangeDue=true + tendered < total → "Owed: $X.XX" in danger styling.
  testWidgets('showChangeDue=true with tendered < total shows owed amount', (tester) async {
    await tester.pumpWidget(wrap(EdenPaymentEntry(
      allowedMethods: const [EdenPaymentMethod.cash],
      onDraftChanged: (_) {},
      expectedAmount: 50.0,
      showChangeDue: true,
      quickTenderDenominations: const [500, 1000, 2000, 5000, 10000],
    )));
    // Tap $20 → tendered=20, total=50, owed=30
    await tester.tap(denominationButton(r'$20'));
    await tester.pump();
    expect(find.textContaining('Owed:'), findsOneWidget);
  });

  // 8. Custom denominations list renders correctly.
  testWidgets('custom denominations list renders the specified buttons only', (tester) async {
    await tester.pumpWidget(wrap(EdenPaymentEntry(
      allowedMethods: const [EdenPaymentMethod.cash],
      onDraftChanged: (_) {},
      quickTenderDenominations: const [200, 500], // $2, $5 only
    )));
    expect(denominationButton(r'$2'), findsOneWidget);
    expect(denominationButton(r'$5'), findsOneWidget);
    // Standard denominations not in this list should be absent.
    expect(denominationButton(r'$10'), findsNothing);
    expect(denominationButton(r'$20'), findsNothing);
    expect(denominationButton(r'$100'), findsNothing);
  });
  });

  // ─────────────────────────────────────────────────────────────────────
  // quickTenderMode: replace semantics + Exact button
  // ─────────────────────────────────────────────────────────────────────

  group('EdenPaymentEntry — quickTenderMode replace', () {
    // 1. Default (no quickTenderMode passed) still accumulates — backward compat.
    testWidgets('default mode (omitted) accumulates on tap', (tester) async {
      EdenPaymentDraft? captured;
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.cash],
        onDraftChanged: (d) => captured = d,
        quickTenderDenominations: const [2000, 5000],
      )));
      await tester.tap(denominationButton(r'$20'));
      await tester.pump();
      await tester.tap(denominationButton(r'$50'));
      await tester.pump();
      // accumulate: 20 + 50 = 70
      expect(captured!.amount, closeTo(70.0, 0.001));
    });

    // 2. replace mode: tap denomination sets tendered to that exact amount.
    testWidgets('replace mode: tap denomination sets tendered (not adds)', (tester) async {
      EdenPaymentDraft? captured;
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.cash],
        onDraftChanged: (d) => captured = d,
        quickTenderDenominations: const [2000, 5000],
        quickTenderMode: EdenQuickTenderMode.replace,
      )));
      await tester.tap(denominationButton(r'$20'));
      await tester.pump();
      expect(captured!.amount, closeTo(20.0, 0.001));
    });

    // 3. replace mode: second tap replaces (does not accumulate).
    testWidgets('replace mode: second tap replaces first, not accumulates', (tester) async {
      EdenPaymentDraft? captured;
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.cash],
        onDraftChanged: (d) => captured = d,
        quickTenderDenominations: const [2000, 5000],
        quickTenderMode: EdenQuickTenderMode.replace,
      )));
      await tester.tap(denominationButton(r'$20'));
      await tester.pump();
      await tester.tap(denominationButton(r'$50'));
      await tester.pump();
      // replace: last tap wins — tendered = $50, NOT $70
      expect(captured!.amount, closeTo(50.0, 0.001));
    });

    // 4. replace mode + expectedAmount: Exact button is visible.
    testWidgets('replace mode with expectedAmount renders Exact button', (tester) async {
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.cash],
        onDraftChanged: (_) {},
        quickTenderDenominations: const [2000, 5000],
        quickTenderMode: EdenQuickTenderMode.replace,
        expectedAmount: 37.50,
      )));
      expect(find.widgetWithText(OutlinedButton, 'Exact'), findsOneWidget);
    });

    // 5. replace mode + Exact button tap sets tendered = expectedAmount.
    testWidgets('replace mode: tap Exact sets tendered = expectedAmount', (tester) async {
      EdenPaymentDraft? captured;
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.cash],
        onDraftChanged: (d) => captured = d,
        quickTenderDenominations: const [2000, 5000],
        quickTenderMode: EdenQuickTenderMode.replace,
        expectedAmount: 37.50,
      )));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Exact'));
      await tester.pump();
      expect(captured!.amount, closeTo(37.50, 0.001));
    });

    // 6. accumulate mode with expectedAmount: Exact button is NOT rendered.
    testWidgets('accumulate mode: Exact button is absent even with expectedAmount', (tester) async {
      await tester.pumpWidget(wrap(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.cash],
        onDraftChanged: (_) {},
        quickTenderDenominations: const [2000, 5000],
        quickTenderMode: EdenQuickTenderMode.accumulate,
        expectedAmount: 37.50,
      )));
      expect(find.widgetWithText(OutlinedButton, 'Exact'), findsNothing);
    });
  });
}

void _noop(EdenPaymentDraft _) {}

/// Helper: finds denomination buttons by their display text using OutlinedButton.
Finder denominationButton(String label) => find.widgetWithText(OutlinedButton, label);
