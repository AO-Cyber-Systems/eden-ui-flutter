// test/widgets/eden_purpose_sweep_12_test.dart
//
// TRD 40-12 — merchandising / inventory / orders purpose sweep.
//
// WHY THESE ASSERTIONS LOOK LIKE THIS
//
// 40-RESEARCH.md B1: `material/text_field.dart:355` resolves `keyboardType` in
// TextField's own INITIALIZER LIST:
//
//     keyboardType = keyboardType ?? (maxLines == 1 ? text : multiline)
//
// so `EditableText`'s `_inferKeyboardType` never fires for anything built on
// TextField. Adding `autofillHints:` alone therefore fixes NOTHING — the field
// still resolves `TextInputType.text`. The only assertion that proves a purpose
// was really applied is the RESOLVED `keyboardType`, so every case below asserts
// it explicitly rather than trusting the hint half.
//
// 40-RESEARCH.md B6: `TextField.autofillHints` defaults to `const <String>[]`,
// NOT null. A `== null` assertion fails on a correctly-unpurposed shape-C field,
// and a `!= null` assertion passes on a field with no hints at all. Every
// no-hint assertion below therefore tests EMPTINESS, in both directions.
//
// 40-RESEARCH.md B7: every purpose used in this sweep (none, quantity,
// decimalAmount, multilineText) resolves `autofillHints == null`. Nothing in
// these 11 files emits a hint string, so the duplicate-DOM-id hazard that
// constrains REPEATED rows cannot arise here — which is what makes it safe to
// purpose the per-row editors (line items, tiers, splits, packout cards,
// receiving lines, inventory rows) at all. `expectNoAutofillIdentity` is the
// assertion that pins that property.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_commissions_editor_fixtures.dart';
import '_fixtures/eden_equipment_record_card_fixtures.dart';
import '_fixtures/eden_inventory_row_editor_fixtures.dart';
import '_fixtures/eden_packout_page_fixtures.dart';
import '_fixtures/eden_price_book_builder_fixtures.dart';
import '_fixtures/eden_promotion_author_fixtures.dart';
import '_fixtures/eden_receiving_flow_fixtures.dart';
import '_fixtures/eden_store_transfer_fixtures.dart';

// ── Resolved keyboards, named once ───────────────────────────────────────────
const TextInputType kText = TextInputType.text;
const TextInputType kNumber = TextInputType.number;
const TextInputType kDecimal = TextInputType.numberWithOptions(decimal: true);
const TextInputType kMultiline = TextInputType.multiline;

Widget wrap(Widget child, {double width = 800, double height = 1400}) =>
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(width: width, child: child),
        ),
      ),
    );

Widget wrapTight(Widget child, {double width = 1024, double height = 800}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );

/// B6: assert EMPTINESS, never nullness. A shape-C field keeps TextField's
/// `const <String>[]` default; a shape-B field is handed the enum's explicit
/// `null`. Both mean "no autofill identity" and both must pass here.
void expectNoAutofillIdentity(TextField f, String what) {
  final Iterable<String>? hints = f.autofillHints;
  expect(
    hints == null || hints.isEmpty,
    isTrue,
    reason: '$what must carry NO autofill identity. Flutter web derives '
        'element.name and element.id from hints.first '
        '(text_editing.dart:514-531), so a hint here would be both a false '
        'semantic claim and, on a repeated row, a duplicate DOM id (B7). '
        'Got: $hints',
  );
}

/// Assert that NOT ONE TextField on screen carries an autofill identity.
///
/// The histogram cases below pin the keyboard half; without this they would
/// pass with a hint injected into any cell, which is precisely the B1 failure
/// mode (perfect hints, wrong keyboard) read backwards. Mutation probes
/// CE-tier-H, CE-split-H and LI-*-H survived until this existed.
void expectNoAutofillIdentityAnywhere(WidgetTester tester, String what) {
  int n = 0;
  for (final TextField f in tester.widgetList<TextField>(
    find.byType(TextField),
  )) {
    expectNoAutofillIdentity(f, '$what (field ${n++})');
  }
  expect(n, greaterThan(0), reason: 'scanned no fields at all');
}

/// Locate a raw TextField / TextFormField by its own decoration label — a
/// distinguishing property, never an index.
TextField byLabel(WidgetTester tester, String labelText) =>
    tester.widget<TextField>(find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == labelText,
      description: 'TextField(decoration.labelText: "$labelText")',
    ));

/// Locate the TextField inside the EdenInput whose sibling label `Text` reads
/// [label]. EdenInput renders its label as a sibling Text inside a
/// MergeSemantics/Column (eden_input.dart), not as an InputDecoration label.
TextField byEdenInputLabel(WidgetTester tester, String label) =>
    tester.widget<TextField>(find.descendant(
      of: find.ancestor(
        of: find.text(label),
        matching: find.byType(EdenInput),
      ),
      matching: find.byType(TextField),
    ));

/// Locate a field by its own `hintText`, which EdenInput fills from `hint:`.
TextField byEdenInputHint(WidgetTester tester, String hint) =>
    tester.widget<TextField>(find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == hint,
      description: 'TextField(decoration.hintText: "$hint")',
    ));

TextField byKey(WidgetTester tester, Key key) =>
    tester.widget<TextField>(find.descendant(
      of: find.byKey(key),
      matching: find.byType(TextField),
      matchRoot: true,
    ));

/// The multiset of resolved keyboards across every TextField on screen. Used
/// where a widget renders several structurally identical cells that carry no
/// label, key or other distinguishing property to finder-match on.
Map<String, int> keyboardHistogram(WidgetTester tester) {
  final Map<String, int> out = <String, int>{};
  for (final TextField f in tester.widgetList<TextField>(
    find.byType(TextField),
  )) {
    final String k = f.keyboardType.toString();
    out[k] = (out[k] ?? 0) + 1;
  }
  return out;
}

void main() {
  // ───────────────────────────────────────────────────────────────────────
  // eden_promotion_author.dart — 8 fields
  // ───────────────────────────────────────────────────────────────────────
  group('TRD 40-12 — EdenPromotionAuthor', () {
    testWidgets('BOGO Buy/Get resolve quantity (number), not decimal',
        (tester) async {
      await tester.pumpWidget(wrap(EdenPromotionAuthor(
        rule: EdenPromotionAuthorFixtures.bogoBuy2Get1Rule,
        onRuleChanged: (_) {},
      )));
      for (final String label in <String>['Buy', 'Get']) {
        final TextField f = byLabel(tester, label);
        expect(f.keyboardType, kNumber,
            reason: '"$label" is digitsOnly-filtered, so decimalAmount would '
                'offer a decimal key that the formatter rejects.');
        expect(f.textInputAction, TextInputAction.next);
        expectNoAutofillIdentity(f, '"$label" count');
      }
    });

    testWidgets('BOGO Get-percent-off resolves decimalAmount', (tester) async {
      await tester.pumpWidget(wrap(EdenPromotionAuthor(
        rule: const EdenPromotionRule(
          id: 'p-pct',
          label: 'Buy 2 get 1 half off',
          type: EdenPromotionType.bogo,
          discountKind: EdenPromotionDiscountKind.buyXgetYPercentOff,
          discountValue: 50,
          buyQuantity: 2,
          getQuantity: 1,
        ),
        onRuleChanged: (_) {},
      )));
      final TextField f = byLabel(tester, 'Get-percent-off');
      expect(f.keyboardType, kDecimal,
          reason: 'the formatter RegExp(r"^\\d{0,3}\\.?\\d{0,2}") accepts ".", '
              'so the decimal key is usable here unlike Buy/Get');
      expectNoAutofillIdentity(f, 'Get-percent-off');
    });

    testWidgets('Minimum subtotal resolves decimalAmount', (tester) async {
      await tester.pumpWidget(wrap(EdenPromotionAuthor(
        rule: EdenPromotionAuthorFixtures.bogoBuy2Get1Rule,
        onRuleChanged: (_) {},
      )));
      // The constraint form lives in a collapsed ExpansionTile, whose children
      // are not built until it is opened.
      await tester.tap(find.text('Constraints (window + limits + minimum)'));
      await tester.pumpAndSettle();
      final TextField f = byLabel(tester, 'Minimum subtotal');
      expect(f.keyboardType, kDecimal);
      expectNoAutofillIdentity(f, 'Minimum subtotal');
    });

    testWidgets('Promotion label resolves none (plain text keyboard)',
        (tester) async {
      await tester.pumpWidget(wrap(EdenPromotionAuthor(
        rule: EdenPromotionAuthorFixtures.bogoBuy2Get1Rule,
        onRuleChanged: (_) {},
      )));
      final TextField f = byLabel(tester, 'Promotion label');
      expect(f.keyboardType, kText);
      expectNoAutofillIdentity(f, 'Promotion label');
    });

    testWidgets('member-pricing Discount value resolves decimalAmount',
        (tester) async {
      await tester.pumpWidget(wrap(EdenPromotionAuthor(
        rule: EdenPromotionAuthorFixtures.memberPricingGoldRule,
        onRuleChanged: (_) {},
      )));
      final TextField f = byLabel(tester, 'Discount value');
      expect(f.keyboardType, kDecimal);
      expectNoAutofillIdentity(f, 'Discount value');
    });

    testWidgets('Coupon code stays none and keeps uppercase + autocorrect off',
        (tester) async {
      await tester.pumpWidget(wrap(EdenPromotionAuthor(
        rule: EdenPromotionAuthorFixtures.couponSummer20Rule,
        onRuleChanged: (_) {},
      )));
      final TextField f = byLabel(tester, 'Coupon code');
      expect(f.keyboardType, kText);
      expectNoAutofillIdentity(f,
          'Coupon code (NOT oneTimeCode: it is not a delivered passcode)');
      expect(f.textCapitalization, TextCapitalization.characters,
          reason: 'shape C must not disturb the deliberate uppercase entry');
      expect(f.autocorrect, isFalse,
          reason: 'autocorrect mangles an opaque code as it is typed');
      expect(f.enableSuggestions, isFalse);
    });

    testWidgets('Coupon-body Discount value resolves decimalAmount',
        (tester) async {
      // The coupon-code body renders its OWN 'Discount value' field from a
      // separate build method, so it is a distinct site from the
      // member-pricing one and needs its own case.
      await tester.pumpWidget(wrap(EdenPromotionAuthor(
        rule: EdenPromotionAuthorFixtures.couponSummer20Rule,
        onRuleChanged: (_) {},
      )));
      final TextField f = byLabel(tester, 'Discount value');
      expect(f.keyboardType, kDecimal);
      expectNoAutofillIdentity(f, 'coupon-body Discount value');
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // eden_commissions_editor.dart — 6 fields
  // ───────────────────────────────────────────────────────────────────────
  group('TRD 40-12 — EdenCommissionsEditor', () {
    testWidgets('Percent resolves decimalAmount; label field stays none',
        (tester) async {
      await tester.pumpWidget(wrap(EdenCommissionsEditor(
        rule: EdenCommissionsEditorFixtures.percentRuleSalon,
        onRuleChanged: (_) {},
      )));
      final TextField pct = byLabel(tester, 'Percent');
      expect(pct.keyboardType, kDecimal);
      expectNoAutofillIdentity(pct, 'Percent');

      final TextField label = byLabel(tester, 'Commission rule label');
      expect(label.keyboardType, kText);
      expectNoAutofillIdentity(label, 'Commission rule label');
    });

    testWidgets('fixed Amount resolves decimalAmount', (tester) async {
      await tester.pumpWidget(wrap(EdenCommissionsEditor(
        rule: EdenCommissionsEditorFixtures.fixedRuleRetail,
        onRuleChanged: (_) {},
      )));
      final TextField f = byLabel(tester, 'Amount');
      expect(f.keyboardType, kDecimal);
      expectNoAutofillIdentity(f, 'Amount');
    });

    testWidgets('all 4 tier rows resolve decimalAmount on BOTH cells',
        (tester) async {
      // 4 tiers x (threshold + rate) = 8 unlabelled decimal cells, plus the
      // one 'Commission rule label' text field. Asserting the whole histogram
      // catches a purpose applied to only SOME of the repeated rows, which a
      // single-row fixture could never detect.
      await tester.pumpWidget(wrap(EdenCommissionsEditor(
        rule: EdenCommissionsEditorFixtures.tieredRuleTrades,
        onRuleChanged: (_) {},
      )));
      expect(keyboardHistogram(tester), <String, int>{
        kDecimal.toString(): 8,
        kText.toString(): 1,
      });
      expectNoAutofillIdentityAnywhere(tester, 'commission tier cell');
    });

    testWidgets('split share resolves quantity (formatter rejects ".")',
        (tester) async {
      await tester.pumpWidget(wrap(EdenCommissionsEditor(
        rule: EdenCommissionsEditorFixtures.splitRuleSalonChair,
        onRuleChanged: (_) {},
      )));
      final Map<String, int> hist = keyboardHistogram(tester);
      expect(hist[kNumber.toString()], 3,
          reason: '3 participants, each a whole-number share percentage; '
              'the RegExp(r"^\\d{0,3}") formatter rejects ".", so '
              'decimalAmount would offer a dead decimal key.');
      expect(hist[kDecimal.toString()], isNull,
          reason: 'no decimal cell exists in split mode');
      expectNoAutofillIdentityAnywhere(tester, 'split share cell');
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // eden_line_item_editor.dart — 5 fields, rendered ONCE PER ROW
  // ───────────────────────────────────────────────────────────────────────
  group('TRD 40-12 — EdenLineItemEditor', () {
    List<EdenLineItem<String>> twoRows() => const <EdenLineItem<String>>[
          EdenLineItem<String>(
            id: 'r1',
            payload: 'SKU-1',
            description: 'Coffee',
            quantity: 2,
            unitPrice: 4.5,
            discountAmount: 1,
            taxRate: 0.08,
          ),
          EdenLineItem<String>(
            id: 'r2',
            payload: 'SKU-2',
            description: 'Beans',
            quantity: 1.5,
            unitPrice: 12.0,
            discountAmount: 2,
            taxRate: 0.08,
          ),
        ];

    testWidgets('every numeric cell of every row resolves decimalAmount',
        (tester) async {
      await tester.pumpWidget(wrapTight(
        EdenLineItemEditor<String>(
          items: twoRows(),
          onItemsChanged: (_) {},
          visibleColumns: const <EdenLineItemColumn>[
            EdenLineItemColumn.description,
            EdenLineItemColumn.quantity,
            EdenLineItemColumn.unitPrice,
            EdenLineItemColumn.discount,
            EdenLineItemColumn.tax,
          ],
        ),
        width: 900,
      ));
      // 2 rows x 4 numeric cells = 8 decimal, 2 rows x 1 description = 2 text.
      // A TWO-row fixture is deliberate: with one row a widget that purposed
      // only the first row would still pass.
      expect(keyboardHistogram(tester), <String, int>{
        kText.toString(): 2,
        kDecimal.toString(): 8,
      });
      expectNoAutofillIdentityAnywhere(tester, 'line item cell');
    });

    testWidgets('quantity is decimalAmount, NOT quantity — the model is double',
        (tester) async {
      await tester.pumpWidget(wrapTight(
        EdenLineItemEditor<String>(
          items: twoRows(),
          onItemsChanged: (_) {},
          visibleColumns: const <EdenLineItemColumn>[
            EdenLineItemColumn.quantity,
          ],
        ),
        width: 900,
      ));
      final Iterable<TextField> cells =
          tester.widgetList<TextField>(find.byType(TextField));
      expect(cells.length, 2);
      for (final TextField f in cells) {
        expect(f.keyboardType, kDecimal,
            reason: 'EdenLineItem.quantity is a double and _decimalFormatter() '
                'is RegExp(r"[0-9.]"), so "1.5" must stay typeable. '
                'EdenFieldPurpose.quantity would strip the decimal key.');
        expectNoAutofillIdentity(f, 'line quantity cell');
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // eden_store_transfer.dart — 3 fields
  // ───────────────────────────────────────────────────────────────────────
  group('TRD 40-12 — EdenStoreTransferFlow', () {
    testWidgets('received qty resolves quantity on EVERY transfer line',
        (tester) async {
      await tester.pumpWidget(wrapTight(EdenStoreTransferFlow.receive(
        initialTransfer: EdenStoreTransferFixtures.sampleInTransitTransfer(),
        onSubmit: (_) {},
      )));
      for (final String id in <String>['I-1', 'I-2']) {
        final TextField f = byKey(tester, ValueKey<String>('receivedQty-$id'));
        expect(f.keyboardType, kNumber,
            reason: 'a received unit count; quantity preserves the '
                'TextInputType.number this field already had');
        expectNoAutofillIdentity(f, 'receivedQty-$id');
      }
    });

    testWidgets('shipping carrier and tracking stay none', (tester) async {
      await tester.pumpWidget(wrapTight(EdenStoreTransferFlow.dispatch(
        availableLocations: EdenStoreTransferFixtures.locations,
        onSubmit: (_) {},
        onItemLookup: EdenStoreTransferFixtures.okLookupFn(
          EdenStoreTransferFixtures.sampleItem(),
        ),
      )));
      // Advance to step 3 (Shipping).
      final Finder selects = find.byType(EdenSelect<EdenLocation>);
      await tester.tap(selects.at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Downtown').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(EdenSelect<EdenLocation>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Airport').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(EdenSearchInput),
          matching: find.byType(TextField),
        ),
        'SKU-A',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Scan'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();

      final TextField carrier = byLabel(tester, 'Shipping carrier');
      expect(carrier.keyboardType, kText);
      expectNoAutofillIdentity(
          carrier,
          'Shipping carrier (the CARRIER company, not the user employer, so '
          'organizationName would be a false claim)');

      final TextField tracking = byLabel(tester, 'Tracking #');
      expect(tracking.keyboardType, kText);
      expectNoAutofillIdentity(tracking, 'Tracking #');
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // eden_packout_page.dart — 3 fields
  // ───────────────────────────────────────────────────────────────────────
  group('TRD 40-12 — EdenPackoutPage', () {
    Future<void> pumpExpanded(WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        home: EdenPackoutPage(items: EdenPackoutPageFixtures.twoItems()),
      ));
      await tester.tap(find.text('3/4" copper pipe'));
      await tester.pumpAndSettle();
    }

    testWidgets('Used and Returned resolve quantity', (tester) async {
      await pumpExpanded(tester);
      for (final String label in <String>['Used', 'Returned']) {
        final TextField f = byLabel(tester, label);
        expect(f.keyboardType, kNumber,
            reason: '"$label" is digitsOnly-filtered');
        expectNoAutofillIdentity(f, '"$label" count');
      }
    });

    testWidgets('Notes resolves multilineText and Enter still inserts newline',
        (tester) async {
      await pumpExpanded(tester);
      final TextField f = byLabel(tester, 'Notes (optional)');
      expect(f.maxLines, 2, reason: 'maxLines is the multiline discriminator');
      expect(f.keyboardType, kMultiline);
      expect(f.textInputAction, TextInputAction.newline,
          reason: 'TextInputAction.done here would make Enter submit instead '
              'of inserting a newline in a 2-line notes box');
      expect(f.textCapitalization, TextCapitalization.sentences);
      expectNoAutofillIdentity(f, 'packout notes');
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // eden_promotion_apply.dart — 1 field
  // ───────────────────────────────────────────────────────────────────────
  group('TRD 40-12 — EdenPromotionApply', () {
    testWidgets('coupon entry stays none with autocorrect off', (tester) async {
      await tester.pumpWidget(wrap(EdenPromotionApply(
        context: EdenPromotionApplyContext(
          lineItems: const <EdenLineItem<String>>[
            EdenLineItem<String>(
              id: 'r1',
              payload: 'SKU-1',
              description: 'Coffee',
              quantity: 1,
              unitPrice: 10,
            ),
          ],
          subtotal: 10,
          currentTime: DateTime(2026, 1, 1),
        ),
        availableRules: const <EdenPromotionRule>[],
        onPromotionApplied: (_) {},
      )));
      final TextField f = byLabel(tester, 'Enter coupon code');
      expect(f.keyboardType, kText);
      expect(f.textInputAction, isNull,
          reason: 'null resolves to TextInputAction.done for a single-line, '
              'non-multiline keyboard, which is what this field wants');
      expect(f.autocorrect, isFalse);
      expect(f.enableSuggestions, isFalse);
      expectNoAutofillIdentity(
          f, 'coupon code (NOT oneTimeCode, NOT creditCardNumber)');
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // eden_price_book_builder.dart — 6 sites
  // ───────────────────────────────────────────────────────────────────────
  group('TRD 40-12 — EdenPriceBookBuilder', () {
    testWidgets('tax-rate cells resolve decimalAmount on every row',
        (tester) async {
      await tester.pumpWidget(wrapTight(
        EdenPriceBookBuilder(
          initialData: PriceBookFixtures.hvac(),
          onSave: (_) {},
          initialSection: EdenPriceBookSection.taxes,
        ),
        width: 1100,
        height: 900,
      ));
      final Iterable<TextField> cells =
          tester.widgetList<TextField>(find.byType(TextField));
      expect(cells, isNotEmpty, reason: 'the taxes section must render cells');
      for (final TextField f in cells) {
        expect(f.keyboardType, kDecimal,
            reason: 'a tax RATE is parsed with double.tryParse and shown to 2 '
                'decimal places, so TextInputType.number was wrong');
        expectNoAutofillIdentity(f, 'tax-rate cell');
      }
    });

    testWidgets('tier markup inputs resolve decimalAmount', (tester) async {
      await tester.pumpWidget(wrapTight(
        EdenPriceBookBuilder(
          initialData: PriceBookFixtures.hvac(),
          onSave: (_) {},
          initialSection: EdenPriceBookSection.tiers,
        ),
        width: 1100,
        height: 900,
      ));
      final Iterable<TextField> cells =
          tester.widgetList<TextField>(find.byType(TextField));
      expect(cells, isNotEmpty, reason: 'the tiers section must render inputs');
      for (final TextField f in cells) {
        expect(f.keyboardType, kDecimal);
        expectNoAutofillIdentity(f, 'tier markup input');
      }
    });

    testWidgets('item base flat rate resolves decimalAmount', (tester) async {
      await tester.pumpWidget(wrapTight(
        EdenPriceBookBuilder(
          initialData: PriceBookFixtures.hvac(),
          onSave: (_) {},
          initialSection: EdenPriceBookSection.items,
        ),
        width: 1100,
        height: 900,
      ));
      final Iterable<TextField> cells =
          tester.widgetList<TextField>(find.byType(TextField));
      expect(cells, isNotEmpty, reason: 'the items section must render rates');
      for (final TextField f in cells) {
        expect(f.keyboardType, kDecimal,
            reason: 'baseFlatRate is seeded with toStringAsFixed(2), so the '
                'old TextInputType.number made those 2 places untypeable');
        expectNoAutofillIdentity(f, 'base flat rate');
      }
    });

    testWidgets('rename-category dialog Name stays none', (tester) async {
      await tester.pumpWidget(wrapTight(
        EdenPriceBookBuilder(
          initialData: PriceBookFixtures.hvac(),
          onSave: (_) {},
          initialSection: EdenPriceBookSection.categories,
        ),
        width: 1100,
        height: 900,
      ));
      await tester.tap(find.byKey(const Key('cat-rename-cat-repair')));
      await tester.pumpAndSettle();
      final TextField f = byEdenInputLabel(tester, 'Name');
      expect(f.keyboardType, kText,
          reason: 'a CATEGORY name is not a person or organisation name');
      expectNoAutofillIdentity(f, 'category Name');
    });

    testWidgets('Good/Better/Best modal: 3 labels none, 3 prices decimal',
        (tester) async {
      // The GBB modal is a tall overlay; give the window room so EdenModal's
      // Column does not overflow at the default test surface.
      await tester.binding.setSurfaceSize(const Size(1400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrapTight(
        EdenPriceBookBuilder(
          initialData: PriceBookFixtures.hvac(),
          onSave: (_) {},
          initialSection: EdenPriceBookSection.items,
        ),
        width: 1100,
        height: 900,
      ));
      await tester.tap(find.byKey(const Key('item-gbb-item-compressor-repair')));
      await tester.pumpAndSettle();
      // Good / Better / Best each contribute one Label and one Price. Scope
      // by the EdenInput's own label Text so the items page still mounted
      // BEHIND the modal cannot inflate the counts.
      final Iterable<TextField> labels =
          tester.widgetList<TextField>(find.descendant(
        of: find.ancestor(
          of: find.text('Label'),
          matching: find.byType(EdenInput),
        ),
        matching: find.byType(TextField),
      ));
      expect(labels.length, 3, reason: '3 tier Label fields');
      for (final TextField f in labels) {
        expect(f.keyboardType, kText);
        expectNoAutofillIdentity(f, 'GBB tier Label');
      }

      final Iterable<TextField> prices =
          tester.widgetList<TextField>(find.descendant(
        of: find.ancestor(
          of: find.text('Price'),
          matching: find.byType(EdenInput),
        ),
        matching: find.byType(TextField),
      ));
      expect(prices.length, 3, reason: '3 tier Price fields');
      for (final TextField f in prices) {
        expect(f.keyboardType, kDecimal,
            reason: 'a money price; TextInputType.number gave no decimal key');
        expectNoAutofillIdentity(f, 'GBB tier Price');
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // eden_inventory_row_editor.dart — 5 EdenInput sites, ONE PER ROW
  // ───────────────────────────────────────────────────────────────────────
  group('TRD 40-12 — EdenInventoryRowEditor', () {
    testWidgets('cost/price decimal, onHand/reorder number, location text',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrapTight(
        const EdenInventoryRowEditor(
          data: EdenInventoryRowFixtures.coffeeBeans,
          editable: true,
        ),
        width: 1200,
        height: 200,
      ));
      // The 5 editable cells carry no label, key or hint that distinguishes
      // all of them, so pin the whole multiset instead of indexing.
      expect(keyboardHistogram(tester), <String, int>{
        kDecimal.toString(): 2, // cost + price (money)
        kNumber.toString(): 2, // onHand + reorderPoint (int? counts)
        kText.toString(): 1, // location: a bin code, NOT a postal address
      });
      for (final TextField f
          in tester.widgetList<TextField>(find.byType(TextField))) {
        expectNoAutofillIdentity(f, 'inventory row cell');
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // eden_receiving_flow.dart — 2 EdenInput sites
  // ───────────────────────────────────────────────────────────────────────
  group('TRD 40-12 — EdenReceivingFlow', () {
    testWidgets('received qty resolves decimalAmount', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrapTight(
        EdenReceivingFlow(
          onPoLookup: (_) async => EdenReceivingFixtures.smallPo(),
          onSubmit: (_) {},
          initialDoc: EdenReceivingFixtures.smallPo(),
        ),
        width: 1000,
        height: 700,
      ));
      final TextField f =
          byKey(tester, const ValueKey<String>('received-qty-L-A'));
      expect(f.keyboardType, kDecimal,
          reason: 'parsed with num.tryParse and the cell already used a '
              'decimal keyboard; quantity would remove the decimal key');
      expectNoAutofillIdentity(f, 'received-qty-L-A');
    });

    testWidgets('cost-update New cost resolves decimalAmount', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrapTight(
        EdenReceivingFlow(
          onPoLookup: (_) async => EdenReceivingFixtures.smallPo(),
          onSubmit: (_) {},
          initialDoc: EdenReceivingFixtures.smallPo(),
        ),
        width: 1000,
        height: 700,
      ));
      // Force a variance so the flow routes through the costUpdate step.
      await tester.enterText(
          find.byKey(const ValueKey<String>('received-qty-L-A')), '0');
      await tester.pump();
      await tester.tap(find.byType(EdenSelect<EdenVarianceReason>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Short qty').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('eden-receiving-step-costUpdate')),
          findsOneWidget);

      final TextField f = byEdenInputHint(tester, 'New cost');
      expect(f.keyboardType, kDecimal,
          reason: 'a money unit cost converted to cents via double.tryParse');
      expectNoAutofillIdentity(f, 'New cost');
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // eden_warranty_claim.dart — 3 EdenInput sites
  // ───────────────────────────────────────────────────────────────────────
  group('TRD 40-12 — EdenWarrantyClaim', () {
    Future<void> pumpClaim(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(700, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(
        EdenWarrantyClaim(
          equipment: EquipmentRecordFixtures.hvacCompressor(),
          submittedBy: 'tech-1',
          onSubmit: (_) {},
        ),
        width: 600,
      ));
    }

    testWidgets('Part label stays none (single-line free text)',
        (tester) async {
      await pumpClaim(tester);
      final TextField f = byEdenInputLabel(tester, 'Part label');
      expect(f.maxLines, 1);
      expect(f.keyboardType, kText);
      expectNoAutofillIdentity(f, 'Part label');
    });

    testWidgets('step 2 description and notes resolve multilineText',
        (tester) async {
      await pumpClaim(tester);
      await tester.enterText(find.byType(TextField).first, 'Run capacitor');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('warranty-next')));
      await tester.pumpAndSettle();

      final TextField desc =
          byEdenInputLabel(tester, 'Failure description');
      expect(desc.maxLines, 4);
      expect(desc.keyboardType, kMultiline);
      expect(desc.textInputAction, TextInputAction.newline);
      expectNoAutofillIdentity(desc, 'Failure description');

      final TextField notes =
          byEdenInputLabel(tester, 'Technician notes (optional)');
      expect(notes.maxLines, 3);
      expect(notes.keyboardType, kMultiline);
      expect(notes.textInputAction, TextInputAction.newline);
      expectNoAutofillIdentity(notes, 'Technician notes');
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // eden_intake_form_builder.dart — 2 EdenInput sites
  // ───────────────────────────────────────────────────────────────────────
  group('TRD 40-12 — EdenIntakeFormBuilder', () {
    const EdenIntakeFormSchema schema = EdenIntakeFormSchema(
      id: 's1',
      name: 'Intake',
      fields: <EdenIntakeFieldSchema>[
        EdenIntakeFieldSchema(
          id: 'f1',
          type: EdenIntakeFieldType.singleChoice,
          label: 'Preferred stylist',
          options: <String>['Ana', 'Ben'],
        ),
      ],
    );

    testWidgets('Label stays none; Options resolves multilineText',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrapTight(
        EdenIntakeFormBuilder(schema: schema, onSchemaChanged: (_) {}),
        width: 1300,
        height: 850,
      ));
      await tester.tap(find.byKey(const ValueKey<String>('canvas-f1')));
      await tester.pumpAndSettle();

      final TextField label = byEdenInputLabel(tester, 'Label');
      expect(label.maxLines, 1);
      expect(label.keyboardType, kText);
      expectNoAutofillIdentity(label, 'field Label');

      final TextField options =
          byEdenInputLabel(tester, 'Options (comma-separated)');
      expect(options.maxLines, 3);
      expect(options.keyboardType, kMultiline);
      expect(options.textInputAction, TextInputAction.newline,
          reason: 'EdenFieldPurpose.none would resolve TextInputAction.done '
              'and make Enter submit instead of inserting a newline');
      expectNoAutofillIdentity(options, 'Options list');
    });
  });
}
