import 'dart:async';

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_gift_card_manager_fixtures.dart';

Widget wrap(Widget child, {double width = 600}) => MaterialApp(
      home: Scaffold(body: SizedBox(width: width, child: child)),
    );

void main() {
  // ─────────────────────────────────────────────────────────────────────
  // Test #1 — Renders ISSUE mode body
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('renders ISSUE mode body (amount + name + contact + notes)',
      (tester) async {
    await tester.pumpWidget(wrap(EdenGiftCardManager(
      mode: EdenGiftCardMode.issue,
      onDraftChanged: (_) {},
    )));
    expect(find.text('Initial amount'), findsOneWidget);
    expect(find.text('Recipient name'), findsOneWidget);
    expect(find.text('Recipient contact'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #2 — Renders REDEEM mode body
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('renders REDEEM mode body (masked code + balance + amount)',
      (tester) async {
    await tester.pumpWidget(wrap(EdenGiftCardManager(
      mode: EdenGiftCardMode.redeem,
      record: EdenGiftCardManagerFixtures.sampleGiftCard,
      onDraftChanged: (_) {},
    )));
    expect(find.text('Amount to apply'), findsOneWidget);
    expect(find.textContaining('6789'), findsOneWidget); // last-4 visible
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #3 — Renders LOOKUP mode body
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('renders LOOKUP mode body (code field + Scan + Lookup)',
      (tester) async {
    await tester.pumpWidget(wrap(EdenGiftCardManager(
      mode: EdenGiftCardMode.lookup,
      onLookup: (_) async => EdenGiftCardManagerFixtures.sampleGiftCard,
      onDraftChanged: (_) {},
    )));
    expect(find.text('Gift card code'), findsOneWidget);
    expect(find.text('Lookup'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #4 — Renders BALANCE mode body
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('renders BALANCE mode body (read-only headline + meta)',
      (tester) async {
    await tester.pumpWidget(wrap(EdenGiftCardManager(
      mode: EdenGiftCardMode.balance,
      record: EdenGiftCardManagerFixtures.sampleGiftCard,
      onDraftChanged: (_) {},
    )));
    expect(find.textContaining('Maya Rivera'), findsOneWidget);
    expect(find.textContaining('Initial:'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #5 — Renders LEDGER mode body with rows
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('renders LEDGER mode body with 4 entries (table at wide)',
      (tester) async {
    await tester.pumpWidget(wrap(EdenGiftCardManager(
      mode: EdenGiftCardMode.ledger,
      record: EdenGiftCardManagerFixtures.sampleGiftCard,
      ledgerEntries: EdenGiftCardManagerFixtures.sampleLedger,
      onDraftChanged: (_) {},
    ), width: 800));
    expect(find.byType(DataTable), findsOneWidget);
    // 4 rows in the ledger.
    expect(find.text('Original sale'), findsOneWidget);
    expect(find.text('Haircut'), findsOneWidget);
    expect(find.text('Tip add-on'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #6 — Renders LEDGER empty state
  // ─────────────────────────────────────────────────────────────────────

  testWidgets("renders LEDGER 'No activity yet.' on empty list",
      (tester) async {
    await tester.pumpWidget(wrap(EdenGiftCardManager(
      mode: EdenGiftCardMode.ledger,
      record: EdenGiftCardManagerFixtures.sampleGiftCard,
      ledgerEntries: const [],
      onDraftChanged: (_) {},
    )));
    expect(find.text('No activity yet.'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #7 — maskGiftCardCode helper
  // ─────────────────────────────────────────────────────────────────────

  test('maskGiftCardCode returns last-4 padded prefix', () {
    expect(maskGiftCardCode('GC123456789'), '•••• 6789');
    expect(maskGiftCardCode('XX'), '•••• XX');
    expect(maskGiftCardCode(''), '•••• ');
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #8 — ISSUE amount keystroke emits draft
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('ISSUE: typing 50.00 emits IssueDraft(amount: 50)',
      (tester) async {
    dynamic captured;
    await tester.pumpWidget(wrap(EdenGiftCardManager(
      mode: EdenGiftCardMode.issue,
      onDraftChanged: (d) => captured = d,
    )));
    final amount = find.widgetWithText(TextFormField, 'Initial amount');
    await tester.enterText(amount, '50.00');
    await tester.pump();
    expect(captured, isA<EdenGiftCardIssueDraft>());
    expect((captured as EdenGiftCardIssueDraft).amount, closeTo(50.0, 0.001));
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #9 — ISSUE filling all fields emits complete draft
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('ISSUE: filling all fields emits complete draft on last keystroke',
      (tester) async {
    EdenGiftCardIssueDraft? captured;
    await tester.pumpWidget(wrap(EdenGiftCardManager(
      mode: EdenGiftCardMode.issue,
      onDraftChanged: (d) => captured = d as EdenGiftCardIssueDraft,
    )));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Initial amount'), '100');
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Recipient name'), 'Ava');
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Recipient contact'),
        'ava@example.com');
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.amount, 100);
    expect(captured!.recipientName, 'Ava');
    expect(captured!.recipientContact, 'ava@example.com');
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #10 — REDEEM amount keystroke emits draft
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('REDEEM: typing 15.00 emits RedeemDraft(code, amount, balance)',
      (tester) async {
    EdenGiftCardRedeemDraft? captured;
    await tester.pumpWidget(wrap(EdenGiftCardManager(
      mode: EdenGiftCardMode.redeem,
      record: EdenGiftCardManagerFixtures.sampleGiftCard,
      onDraftChanged: (d) => captured = d as EdenGiftCardRedeemDraft,
    )));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount to apply'), '15.00');
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.amountToApply, closeTo(15.0, 0.001));
    expect(captured!.balanceBefore,
        closeTo(EdenGiftCardManagerFixtures.sampleGiftCard.currentBalance, 0.001));
    expect(captured!.code,
        EdenGiftCardManagerFixtures.sampleGiftCard.code);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #11 — REDEEM amountToApply prefilled to min(balance, subtotal)
  // ─────────────────────────────────────────────────────────────────────

  testWidgets(
      'REDEEM: amountToApply prefilled to min(currentBalance, checkoutSubtotal)',
      (tester) async {
    await tester.pumpWidget(wrap(EdenGiftCardManager(
      mode: EdenGiftCardMode.redeem,
      record: EdenGiftCardManagerFixtures.sampleGiftCard,
      checkoutSubtotal: 20.00,
      onDraftChanged: (_) {},
    )));
    final field =
        tester.widget<TextFormField>(find.byType(TextFormField).first);
    expect(field.controller!.text, '20.00');
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #12 — REDEEM amountToApply > balance shows warning
  // ─────────────────────────────────────────────────────────────────────

  testWidgets(
      'REDEEM: amountToApply > balance surfaces EdenBanner.warning',
      (tester) async {
    await tester.pumpWidget(wrap(EdenGiftCardManager(
      mode: EdenGiftCardMode.redeem,
      record: EdenGiftCardManagerFixtures.sampleGiftCard,
      onDraftChanged: (_) {},
    )));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount to apply'), '500.00');
    await tester.pump();
    expect(find.byType(EdenBanner), findsOneWidget);
    final banner = tester.widget<EdenBanner>(find.byType(EdenBanner));
    expect(banner.variant, EdenBannerVariant.warning);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #13 — LOOKUP Lookup button calls onLookup
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('LOOKUP: Lookup button calls onLookup with typed code',
      (tester) async {
    final completer = Completer<EdenGiftCardRecord?>();
    String? receivedCode;
    Future<EdenGiftCardRecord?> fakeLookup(String code) {
      receivedCode = code;
      return completer.future;
    }

    await tester.pumpWidget(wrap(EdenGiftCardManager(
      mode: EdenGiftCardMode.lookup,
      onLookup: fakeLookup,
      onDraftChanged: (_) {},
    )));
    await tester.enterText(
        find.byType(TextFormField), 'GC555444333');
    await tester.tap(find.text('Lookup'));
    await tester.pump();
    expect(receivedCode, 'GC555444333');
    completer.complete(null); // unblock async
    await tester.pumpAndSettle();
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #14 — LOOKUP non-null result renders balance body
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('LOOKUP: onLookup result renders BALANCE body inline',
      (tester) async {
    Future<EdenGiftCardRecord?> fakeLookup(String code) async {
      return EdenGiftCardManagerFixtures.sampleGiftCard;
    }

    await tester.pumpWidget(wrap(EdenGiftCardManager(
      mode: EdenGiftCardMode.lookup,
      onLookup: fakeLookup,
      onDraftChanged: (_) {},
    )));
    await tester.enterText(find.byType(TextFormField), 'GC');
    await tester.tap(find.text('Lookup'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Maya Rivera'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #15 — LOOKUP null result shows 'Card not found' banner
  // ─────────────────────────────────────────────────────────────────────

  testWidgets("LOOKUP: null result shows 'Card not found' danger banner",
      (tester) async {
    Future<EdenGiftCardRecord?> fakeLookup(String code) async => null;

    await tester.pumpWidget(wrap(EdenGiftCardManager(
      mode: EdenGiftCardMode.lookup,
      onLookup: fakeLookup,
      onDraftChanged: (_) {},
    )));
    await tester.enterText(find.byType(TextFormField), 'BAD');
    await tester.tap(find.text('Lookup'));
    await tester.pumpAndSettle();
    expect(find.text('Card not found'), findsOneWidget);
    final banner = tester.widget<EdenBanner>(find.byType(EdenBanner));
    expect(banner.variant, EdenBannerVariant.danger);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #16 — iPhone-narrow safe across all 5 modes
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('iPhone-narrow (390pt): all 5 modes render without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    for (final mode in EdenGiftCardMode.values) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EdenGiftCardManager(
            mode: mode,
            record: EdenGiftCardManagerFixtures.sampleGiftCard,
            ledgerEntries:
                mode == EdenGiftCardMode.ledger
                    ? EdenGiftCardManagerFixtures.sampleLedger
                    : null,
            onLookup: (_) async => null,
            onDraftChanged: (_) {},
          ),
        ),
      ));
      expect(tester.takeException(), isNull, reason: 'mode=$mode');
    }
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #17 — iPhone-narrow ledger collapses to EdenCard rows
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('iPhone-narrow LEDGER: rows render as EdenCards (no DataTable)',
      (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EdenGiftCardManager(
          mode: EdenGiftCardMode.ledger,
          record: EdenGiftCardManagerFixtures.sampleGiftCard,
          ledgerEntries: EdenGiftCardManagerFixtures.sampleLedger,
          onDraftChanged: (_) {},
        ),
      ),
    ));
    expect(find.byType(DataTable), findsNothing);
    expect(find.byType(EdenCard), findsNWidgets(4));
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #18 — Semantics: balance label
  // ─────────────────────────────────────────────────────────────────────

  testWidgets("Semantics: balance display has 'Current balance: \$X.XX' label",
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(EdenGiftCardManager(
      mode: EdenGiftCardMode.balance,
      record: EdenGiftCardManagerFixtures.sampleGiftCard,
      onDraftChanged: (_) {},
    )));
    expect(
      find.bySemanticsLabel('Current balance: \$67.50'),
      findsOneWidget,
    );
    handle.dispose();
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #19 — Semantics: masked code label
  // ─────────────────────────────────────────────────────────────────────

  testWidgets("Semantics: masked code carries 'Card ending in <last4>'",
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(EdenGiftCardManager(
      mode: EdenGiftCardMode.balance,
      record: EdenGiftCardManagerFixtures.sampleGiftCard,
      onDraftChanged: (_) {},
    )));
    expect(
      find.bySemanticsLabel('Card ending in 6789'),
      findsOneWidget,
    );
    handle.dispose();
  });
}
