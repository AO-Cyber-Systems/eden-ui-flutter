// TRD 40-11 — POS & payments purpose sweep (10 widgets, 31 field sites).
//
// Every field in this TRD's files carries an EXPLICIT EdenFieldPurpose. These
// tests assert the semantics each purpose resolves, so a silent regression
// (a dropped purpose, a purpose swapped for another) fails here rather than
// shipping as a wrong keyboard or a wrong password-manager offer.
//
// Two traps this file is written around:
//
//   1. `_inferKeyboardType` is UNREACHABLE through TextField
//      (material/text_field.dart:355 resolves `keyboardType` in the
//      constructor initializer list). A field carrying `autofillHints` but no
//      explicit `keyboardType` still resolves to TextInputType.text. So every
//      case below asserts BOTH halves — hints alone prove nothing.
//
//   2. `copyEnabled` is `!obscureText && !selection.isCollapsed`
//      (editable_text.dart:2641-2646). The clipboard cases therefore set a
//      NON-COLLAPSED selection first; without it the assertion passes for
//      every field, obscured or not, and proves nothing.
//
// `pasteEnabled` is deliberately never asserted — it is false in the test
// environment regardless of field configuration.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Wrappers ────────────────────────────────────────────────────────────────

/// Scrolling wrapper, for widgets whose bodies are intrinsically sized.
Widget wrapScroll(Widget child, {double width = 800}) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, child: SingleChildScrollView(child: child)),
      ),
    );

/// Fixed-box wrapper, for widgets that use `Spacer()` and therefore need a
/// bounded height.
Widget wrapBox(Widget child, {double width = 1024, double height = 900}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );

// ── Finders ─────────────────────────────────────────────────────────────────
//
// Always by a distinguishing decoration property, never `.at(index)` — an
// index-based finder silently retargets on the next layout change.

Finder byLabel(String label) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == label,
      description: 'TextField(labelText: "$label")',
    );

Finder byHint(String hint) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == hint,
      description: 'TextField(hintText: "$hint")',
    );

Finder bySuffix(String suffix) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.suffixText == suffix,
      description: 'TextField(suffixText: "$suffix")',
    );

Finder get obscuredField => find.byWidgetPredicate(
      (w) => w is TextField && w.obscureText,
      description: 'TextField(obscureText: true)',
    );

TextField one(WidgetTester tester, Finder f) {
  expect(f, findsOneWidget, reason: 'expected exactly one match for $f');
  return tester.widget<TextField>(f);
}

// ── Shared expectations ─────────────────────────────────────────────────────

const TextInputType kDecimal = TextInputType.numberWithOptions(decimal: true);

/// Asserts a field claims NO autofill identity.
///
/// Two legitimate resolved shapes, both meaning "nothing to classify by":
///   * `null`  — a purpose was spread onto the widget and that purpose is one
///     of the TYPED-BUT-UNFILLED members (quantity / decimalAmount /
///     multilineText), whose `autofillHints` is deliberately null; also what
///     `EdenInput(purpose: none)` and any `TextFormField` resolve to.
///   * `const <String>[]` — `none` was applied as a marker comment only, so a
///     raw `TextField` keeps its own untouched default.
///
/// Either way the web engine emits `autocomplete="on"` with no `name` and no
/// `id` (text_editing.dart:514-531) — no purpose is ever CLAIMED. What must
/// never happen is a populated hint list on one of these fields.
void expectNoAutofillIdentity(TextField f, String why) {
  final Iterable<String>? hints = f.autofillHints;
  expect(hints == null || hints.isEmpty, isTrue,
      reason: '$why — expected no autofill identity, got: $hints');
}

/// A purpose that is TYPED but deliberately UNFILLED — quantity, decimalAmount,
/// multilineText, none. It must carry a keyboard and NO autofill identity.
void expectUnfilled(TextField f, TextInputType keyboard, String why) {
  expectNoAutofillIdentity(f, why);
  expect(f.keyboardType, keyboard, reason: why);
}

void main() {
  // ══════════════════════════════════════════════════════════════════════
  // 1 — EdenCashDrawerClose (7 fields)
  // ══════════════════════════════════════════════════════════════════════

  group('EdenCashDrawerClose', () {
    EdenCashDrawerClose build() => EdenCashDrawerClose(
          initialSession: EdenDrawerSession(
            drawerId: 'reg-1',
            openedAt: DateTime(2026, 5, 17, 9, 0),
            startingFloat: 200.0,
            transactions: const <EdenCashTransaction>[],
          ),
          onSessionChanged: (_) {},
          onSubmit: (_) {},
        );

    Future<void> goTo(WidgetTester tester, String step) async {
      await tester.tap(find.widgetWithText(ChoiceChip, step));
      await tester.pump();
    }

    testWidgets('every denomination count is quantity, not money and not a card',
        (tester) async {
      await tester.pumpWidget(wrapScroll(build()));
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields, hasLength(10),
          reason: 'the COUNT step renders one field per USD denomination');
      for (final f in fields) {
        expect(f.keyboardType, TextInputType.number,
            reason: 'a bill/coin count is a whole number — `quantity`, so NOT '
                'the decimal keyboard `decimalAmount` would resolve');
        expectNoAutofillIdentity(
            f,
            'a denomination count has no autofill identity; a card hint here '
            'would offer a PAN for a count of pennies');
        expect(f.textInputAction, TextInputAction.next);
      }
    });

    testWidgets('paid-out Amount is decimalAmount; Reason is an explicit none',
        (tester) async {
      await tester.pumpWidget(wrapScroll(build()));
      await goTo(tester, 'transactions');
      await tester.tap(find.text('Add cash drop'));
      await tester.pump();

      expectUnfilled(one(tester, byLabel('Amount')), kDecimal,
          'cash moving out of the drawer is money — decimal keyboard');
      final reason = one(tester, byLabel('Reason'));
      expectUnfilled(reason, TextInputType.text,
          'a single-line free-text reason: `none`, so TextField keeps its own '
          'text default rather than the multiline keyboard');
      expect(reason.textInputAction, isNull,
          reason: '`none` is applied as a marker comment only, so the Enter '
              'key behaviour of this field is untouched by the sweep');
    });

    testWidgets('deposit fields split money from counts; Memo is an explicit none',
        (tester) async {
      await tester.pumpWidget(wrapScroll(build()));
      await goTo(tester, 'deposit');

      expectUnfilled(one(tester, byLabel('Cash to deposit')), kDecimal,
          'cash deposited is money');
      expectUnfilled(one(tester, byLabel('Check amount')), kDecimal,
          'a check amount is money');
      expectUnfilled(one(tester, byLabel('#')), TextInputType.number,
          'the number OF checks is a count, not an amount — `quantity`');
      expectUnfilled(one(tester, byLabel('Memo')), TextInputType.text,
          'a single-line free-text memo: `none`');
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // 2 — EdenGiftCardManager (6 fields)
  // ══════════════════════════════════════════════════════════════════════

  group('EdenGiftCardManager', () {
    testWidgets('ISSUE: amount is money, recipient name is a real person name',
        (tester) async {
      await tester.pumpWidget(wrapScroll(EdenGiftCardManager(
        mode: EdenGiftCardMode.issue,
        onDraftChanged: (_) {},
      )));

      expectUnfilled(one(tester, byLabel('Initial amount')), kDecimal,
          'the loaded value is money');

      final name = one(tester, byLabel('Recipient name'));
      expect(name.autofillHints?.first, AutofillHints.name,
          reason: 'iOS and web read ONLY the first hint '
              '(autofill.dart:688-694)');
      expect(name.keyboardType, TextInputType.name,
          reason: 'AutofillHints.name requires TextInputType.name '
              '(editable_text.dart:1855-1858); a hint without this keyboard '
              'silently breaks iOS autofill');
      expect(name.textCapitalization, TextCapitalization.words);
      expect(name.decoration?.hintText, 'Recipient full name',
          reason: 'hintText becomes the DOM placeholder '
              '(text_editing.dart:471) and password managers read it');
    });

    testWidgets('ISSUE: Recipient contact is an explicit none — it is not an email',
        (tester) async {
      await tester.pumpWidget(wrapScroll(EdenGiftCardManager(
        mode: EdenGiftCardMode.issue,
        onDraftChanged: (_) {},
      )));
      final contact = one(tester, byLabel('Recipient contact'));
      expectNoAutofillIdentity(
          contact,
          'the field accepts an email OR a phone number, so claiming either '
          'would offer the wrong saved value for half the uses');
      expect(contact.keyboardType, TextInputType.text,
          reason: 'NOT emailAddress — a phone number must stay typeable here');
    });

    testWidgets('ISSUE: Notes is multilineText and takes the newline action',
        (tester) async {
      await tester.pumpWidget(wrapScroll(EdenGiftCardManager(
        mode: EdenGiftCardMode.issue,
        onDraftChanged: (_) {},
      )));
      final notes = one(tester, byLabel('Notes'));
      expectUnfilled(notes, TextInputType.multiline,
          'a genuinely multi-line note (maxLines: 2)');
      expect(notes.textInputAction, TextInputAction.newline,
          reason: 'Enter must insert a line, not submit the form');
      expect(notes.maxLines, 2,
          reason: 'multilineText resolves the keyboard, never maxLines — that '
              'stays the widget’s own layout decision');
    });

    testWidgets('REDEEM: amount to apply is money', (tester) async {
      await tester.pumpWidget(wrapScroll(EdenGiftCardManager(
        mode: EdenGiftCardMode.redeem,
        record: EdenGiftCardRecord(
          code: 'GC123456789',
          initialAmount: 100.0,
          currentBalance: 67.50,
          issuedAt: DateTime(2026, 1, 15),
        ),
        onDraftChanged: (_) {},
      )));
      expectUnfilled(one(tester, byLabel('Amount to apply')), kDecimal,
          'a redemption is money');
    });

    testWidgets('LOOKUP: a gift-card code is an explicit none, NOT a card number',
        (tester) async {
      await tester.pumpWidget(wrapScroll(EdenGiftCardManager(
        mode: EdenGiftCardMode.lookup,
        onDraftChanged: (_) {},
      )));
      final code = one(tester, byLabel('Gift card code'));
      expectNoAutofillIdentity(
          code,
          'tagging a stored-value code `creditCardNumber` would invite a '
          'password manager to fill a real PAN into it');
      expect(code.keyboardType, TextInputType.text,
          reason: 'gift-card codes are alphanumeric');
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // 3 — EdenPaymentEntry (3 fields)
  // ══════════════════════════════════════════════════════════════════════

  group('EdenPaymentEntry', () {
    testWidgets('tendered Amount is decimalAmount; Note is an explicit none',
        (tester) async {
      await tester.pumpWidget(wrapScroll(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.cash],
        onDraftChanged: (_) {},
      ), width: 420));
      expectUnfilled(one(tester, byLabel('Amount')), kDecimal,
          'a tendered amount is money, not a card number');
      expectUnfilled(one(tester, byLabel('Note (optional)')),
          TextInputType.text, 'a single-line free-text note: `none`');
    });

    testWidgets("the card reference field is none — 'Last 4 of card' is not a PAN",
        (tester) async {
      await tester.pumpWidget(wrapScroll(EdenPaymentEntry(
        allowedMethods: const [EdenPaymentMethod.card],
        onDraftChanged: (_) {},
      ), width: 420));
      final ref = one(tester, byLabel('Last 4 of card'));
      expectNoAutofillIdentity(
          ref,
          'the label is chosen at runtime by _referenceHint() — '
          "'Check #', 'Gift card #', 'Account ID' — so no single purpose "
          'is true for it, and a 4-digit receipt reference must never be '
          'offered a 16-digit PAN');
      expect(ref.keyboardType, TextInputType.text,
          reason: "references are alphanumeric ('Account ID')");
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // 4 — EdenLayawayFlow (3 fields)
  // ══════════════════════════════════════════════════════════════════════

  group('EdenLayawayFlow', () {
    const cart = <EdenLayawayCartItem>[
      EdenLayawayCartItem(
        lineId: 'L-1',
        sku: 'SKU-1',
        name: 'Leather jacket',
        qty: 1,
        unitPriceCents: 25000,
        taxCents: 2000,
      ),
    ];

    testWidgets('deposit amount is money; installment COUNT is a quantity',
        (tester) async {
      await tester.pumpWidget(wrapBox(EdenLayawayFlow.create(
        cartItems: cart,
        onSubmit: (_) {},
      )));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pump();

      expectUnfilled(one(tester, byLabel('Deposit amount')), kDecimal,
          'a deposit is money');

      await tester.enterText(byLabel('Deposit amount'), '100.00');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pump();

      expectUnfilled(one(tester, byLabel('Installment count (optional)')),
          TextInputType.number,
          'how MANY instalments is a count, not an amount — `quantity`, so '
          'NOT the decimal keyboard');
    });

    testWidgets('recorded installment amount is money', (tester) async {
      await tester.pumpWidget(wrapBox(EdenLayawayFlow.manage(
        state: EdenLayawayState(
          id: 'LAY-001',
          cartItems: cart,
          depositCents: 10000,
          balanceCents: 17000,
          pickupByDate: DateTime(2026, 8, 1),
          status: EdenLayawayStatus.active,
        ),
        onSubmit: (_) {},
      )));
      await tester.tap(find.byType(EdenSelect<EdenLayawayAction>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Record installment').last);
      await tester.pumpAndSettle();

      expectUnfilled(one(tester, byLabel('Amount')), kDecimal,
          'an instalment payment is money');
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // 5 — EdenTipSplitEditor (2 fields)
  // ══════════════════════════════════════════════════════════════════════

  group('EdenTipSplitEditor', () {
    const staff = <EdenTipRecipient>[
      EdenTipRecipient(id: 's-1', displayName: 'Sarah'),
      EdenTipRecipient(id: 's-2', displayName: 'Mia'),
    ];

    testWidgets('a share PERCENT is a quantity, not a decimal amount',
        (tester) async {
      await tester.pumpWidget(wrapScroll(EdenTipSplitEditor(
        totalTip: 20.0,
        recipients: staff,
        onAllocationsChanged: (_) {},
      ), width: 640));
      final pct = tester.widgetList<TextField>(bySuffix('%')).toList();
      expect(pct, hasLength(2), reason: 'one percent box per recipient');
      for (final f in pct) {
        expect(f.keyboardType, TextInputType.number,
            reason: 'the input formatter rejects "." — a decimal keyboard '
                'would offer a key that does nothing');
        expectNoAutofillIdentity(f, 'a share percentage identifies nothing');
      }
    });

    testWidgets('a fixed allocation is a decimal amount', (tester) async {
      await tester.pumpWidget(wrapScroll(EdenTipSplitEditor(
        totalTip: 20.0,
        recipients: staff,
        mode: EdenTipSplitMode.fixedAmount,
        onAllocationsChanged: (_) {},
      ), width: 640));
      final amounts = tester.widgetList<TextField>(byLabel('Allocation')).toList();
      expect(amounts, hasLength(2));
      for (final f in amounts) {
        expectUnfilled(f, kDecimal, 'a dollar allocation is money');
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // 6 — EdenTippingSelector (1 field)
  // ══════════════════════════════════════════════════════════════════════

  group('EdenTippingSelector', () {
    testWidgets('custom tip amount is a decimal amount', (tester) async {
      await tester.pumpWidget(wrapScroll(EdenTippingSelector(
        subtotal: 100.0,
        onDraftChanged: (_) {},
      ), width: 420));
      await tester.tap(find.text('Custom'));
      await tester.pump();
      expectUnfilled(one(tester, byLabel('Custom tip amount')), kDecimal,
          'a tip is money');
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // 7 — EdenRefundFlow (1 field)
  // ══════════════════════════════════════════════════════════════════════

  group('EdenRefundFlow', () {
    testWidgets('refundable line qty is a quantity', (tester) async {
      await tester.pumpWidget(wrapBox(EdenRefundFlow(
        onLookupSale: (_) async => EdenSaleRecord(
          saleId: 'S-1042',
          occurredAt: DateTime(2026, 5, 1),
          originalTender: EdenPaymentMethod.card,
          originalTotalCents: 5000,
          lines: const [
            EdenSaleLine(
              lineId: 'L-1',
              sku: 'SKU-1',
              name: 'Widget',
              originalQty: 2,
              unitPriceCents: 2500,
              taxCents: 0,
              refundableQty: 2,
            ),
          ],
        ),
        onSubmit: (_) {},
      )));
      await tester.enterText(
        find.descendant(
          of: find.byType(EdenSearchInput),
          matching: find.byType(TextField),
        ),
        'S-1042',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Lookup'));
      await tester.pumpAndSettle();

      final qty = one(tester, find.byKey(const ValueKey('refundQty-L-1')));
      expect(qty.keyboardType, TextInputType.number,
          reason: 'a refundable line quantity is a whole count — the value is '
              'read with int.tryParse, so a decimal keyboard would offer a '
              'key the parser rejects');
      expectNoAutofillIdentity(qty, 'a line quantity identifies nothing');
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // 8 — EdenBarcodeScanner (1 field)
  // ══════════════════════════════════════════════════════════════════════

  group('EdenBarcodeScanner', () {
    testWidgets('manual barcode entry is an explicit none with autocorrect off',
        (tester) async {
      // A bounded box, NOT a scroll view: the scanner contains a Stack, which
      // asserts on the unbounded height a SingleChildScrollView would give it.
      await tester.pumpWidget(wrapBox(EdenBarcodeScanner(
        cameraPreview: const SizedBox(width: 300, height: 300),
        showManualEntry: true,
        onManualEntry: (_) {},
      ), width: 500, height: 1000));
      final f = one(tester, byHint('Type barcode value...'));
      expectNoAutofillIdentity(f, 'a scanned code has no autofill identity');
      expect(f.autocorrect, isFalse,
          reason: 'autocorrect must never rewrite a scanned barcode');
      expect(f.enableSuggestions, isFalse,
          reason: 'suggestions must never rewrite a scanned barcode');
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // 9 — EdenFuelCardPaymentEntry (6 EdenInput sites)
  // ══════════════════════════════════════════════════════════════════════

  group('EdenFuelCardPaymentEntry', () {
    const panHint = 'PAN — securely retained as last 4 only';
    const prompts = <EdenFuelCardPromptSpec>[
      EdenFuelCardPromptSpec(
        fieldKey: 'pin',
        label: 'Driver PIN',
        kind: EdenFuelCardPromptKind.numericPin,
        required: false,
      ),
      EdenFuelCardPromptSpec(
        fieldKey: 'odometer',
        label: 'Odometer',
        kind: EdenFuelCardPromptKind.odometer,
        required: false,
        hint: 'Miles',
      ),
      EdenFuelCardPromptSpec(
        fieldKey: 'driverId',
        label: 'Driver ID',
        kind: EdenFuelCardPromptKind.text,
        required: false,
        hint: 'Badge number',
      ),
    ];

    Widget build() => EdenFuelCardPaymentEntry(
          network: EdenFuelCardNetwork.generic,
          promptsOverride: prompts,
          onSubmit: (_) {},
        );

    Future<void> toPrompts(WidgetTester tester) async {
      await tester.enterText(byHint(panHint), '4111111111111111');
      await tester.pump();
      await tester.tap(find.byKey(const Key('fuel-card-next')));
      await tester.pump();
    }

    testWidgets('the PAN field is a real creditCardNumber', (tester) async {
      await tester.pumpWidget(wrapScroll(build(), width: 520));
      final pan = one(tester, byHint(panHint));
      expect(pan.autofillHints?.first, AutofillHints.creditCardNumber,
          reason: 'iOS and web read only the first hint');
      expect(pan.keyboardType, TextInputType.number,
          reason: 'the hint and the keyboard are resolved together, so they '
              'cannot drift (editable_text.dart:1855-1858)');
      expect(pan.obscureText, isFalse,
          reason: 'card fields are deliberately NOT obscured — obscuring '
              'hard-disables copy and cut (editable_text.dart:2641-2646) and '
              'gives no benefit, since web derives DOM type="password" from '
              'the hint string, not from obscureText '
              '(text_editing.dart:514-531), and cc-number is not a password');
    });

    testWidgets('a driver PIN is an explicit none — never a password hint',
        (tester) async {
      await tester.pumpWidget(wrapScroll(build(), width: 520));
      await toPrompts(tester);
      final pin = one(tester, obscuredField);
      expectNoAutofillIdentity(
          pin,
          'a fleet-card PIN is not an account password; a password hint here '
          'would offer the user’s saved logins');
      expect(pin.keyboardType, TextInputType.number,
          reason: '`currentPassword` would have forced a TEXT keyboard onto a '
              'numeric PIN — the reason this field keeps manual control');
      expect(pin.obscureText, isTrue,
          reason: 'the PIN stays masked; only its autofill identity is none');
    });

    testWidgets('an odometer reading is a quantity, not a card number',
        (tester) async {
      await tester.pumpWidget(wrapScroll(build(), width: 520));
      await toPrompts(tester);
      expectUnfilled(one(tester, byHint('Miles')), TextInputType.number,
          'a meter reading is a whole number with no autofill identity');
    });

    testWidgets('a free-form fleet prompt is an explicit none', (tester) async {
      await tester.pumpWidget(wrapScroll(build(), width: 520));
      await toPrompts(tester);
      expectUnfilled(one(tester, byHint('Badge number')), TextInputType.text,
          'an arbitrary caller-defined prompt identifies no fillable value');
    });

    testWidgets('amount is money and the receipt email is a real email',
        (tester) async {
      await tester.pumpWidget(wrapScroll(build(), width: 520));
      await toPrompts(tester);
      await tester.tap(find.byKey(const Key('fuel-card-next')));
      await tester.pump();

      expectUnfilled(one(tester, byHint('0.00')), kDecimal,
          'a fuel purchase amount is money');

      final email = one(tester, byHint('you@example.com'));
      expect(email.autofillHints?.first, AutofillHints.email,
          reason: 'index 0 is the only hint iOS and web consume; '
              'AutofillHints.username follows as an Android-only extra');
      expect(email.keyboardType, TextInputType.emailAddress,
          reason: 'AutofillHints.email works ONLY with '
              'TextInputType.emailAddress (editable_text.dart:1855-1858)');
      expect(email.autocorrect, isFalse,
          reason: 'autocorrect must not rewrite an address');
    });

    testWidgets(
        'clipboard posture: the PAN copies, the obscured PIN does not '
        '(non-collapsed selection required)', (tester) async {
      await tester.pumpWidget(wrapScroll(build(), width: 520));
      await tester.enterText(byHint(panHint), '4111111111111111');
      await tester.pump();

      // A COLLAPSED selection makes copyEnabled false for EVERY field, so the
      // assertion below would be vacuous without this (Appendix A).
      one(tester, byHint(panHint)).controller!.selection =
          const TextSelection(baseOffset: 0, extentOffset: 4);
      await tester.pump();
      final panState = tester.state<EditableTextState>(find.descendant(
        of: byHint(panHint),
        matching: find.byType(EditableText),
      ));
      expect(panState.copyEnabled, isTrue,
          reason: 'an unobscured card field keeps copy/cut working');

      await tester.tap(find.byKey(const Key('fuel-card-next')));
      await tester.pump();
      await tester.enterText(obscuredField, '1234');
      await tester.pump();
      one(tester, obscuredField).controller!.selection =
          const TextSelection(baseOffset: 0, extentOffset: 4);
      await tester.pump();
      final pinState = tester.state<EditableTextState>(find.descendant(
        of: obscuredField,
        matching: find.byType(EditableText),
      ));
      expect(pinState.copyEnabled, isFalse,
          reason: 'obscureText hard-disables copy even with a real selection '
              '(editable_text.dart:2641-2646) — this is why the PIN keeps '
              'obscureText and the PAN does not');
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // 10 — EdenDeliveryVarianceCard (1 EdenInput site)
  // ══════════════════════════════════════════════════════════════════════

  group('EdenDeliveryVarianceCard', () {
    testWidgets('the reason note is multilineText and takes the newline action',
        (tester) async {
      await tester.pumpWidget(wrapScroll(EdenDeliveryVarianceCard(
        data: const EdenDeliveryVarianceData(
          scheduled: 850.0,
          actual: 700.0,
          metric: EdenVarianceMetric.gallons,
        ),
        initialDraft: const EdenDeliveryVarianceDraft(
          data: EdenDeliveryVarianceData(
            scheduled: 850.0,
            actual: 700.0,
            metric: EdenVarianceMetric.gallons,
          ),
          reason: EdenDeliveryVarianceReason.meterReadError,
        ),
        onSubmit: (_) {},
      ), width: 520));

      final note = one(tester, find.byWidgetPredicate(
        (w) => w is TextField && w.maxLines == 3,
        description: 'the 3-line reason note',
      ));
      expectUnfilled(note, TextInputType.multiline,
          'a genuinely multi-line note (maxLines: 3)');
      expect(note.textInputAction, TextInputAction.newline,
          reason: 'Enter must insert a line, not submit');
      expect(note.textCapitalization, TextCapitalization.sentences,
          reason: 'prose, so sentence capitalisation');
    });
  });
}
