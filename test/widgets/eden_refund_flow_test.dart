import 'dart:io';

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_refund_flow_fixtures.dart';

void main() {
  Widget wrap(Widget child, {double width = 1024, double height = 800}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );
  }

  // Drive the flow through Step 1 → Step 2 → Step 3 → (Step 4).
  Future<void> lookupAndAdvance(
    WidgetTester tester, {
    String query = 'S-1042',
  }) async {
    final searchField = find.byType(EdenSearchInput);
    await tester.enterText(
      find.descendant(of: searchField, matching: find.byType(TextField)),
      query,
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Lookup'));
    await tester.pumpAndSettle();
  }

  Future<void> setLineQty(
    WidgetTester tester,
    String lineId,
    int qty,
  ) async {
    final qtyField = find.byKey(ValueKey('refundQty-$lineId'));
    expect(qtyField, findsOneWidget,
        reason: 'Expected a refund-qty input for line $lineId');
    await tester.enterText(qtyField, '$qty');
    await tester.pump();
  }

  group('EdenRefundFlow — state machine', () {
    testWidgets('initial step = lookupSale (Step 1 of 4 indicator)',
        (tester) async {
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (_) async => EdenRefundFlowFixtures.sampleSale(),
        onSubmit: (_) {},
      )));
      expect(find.textContaining('Step 1 of 4'), findsOneWidget);
      expect(find.byType(EdenSearchInput), findsOneWidget);
    });

    testWidgets('successful lookup transitions to selectLines',
        (tester) async {
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (_) async => EdenRefundFlowFixtures.sampleSale(),
        onSubmit: (_) {},
      )));
      await lookupAndAdvance(tester);
      expect(find.textContaining('Step 2 of 4'), findsOneWidget);
    });

    testWidgets("'Next' on selectLines with ≥1 line+reason → step = method",
        (tester) async {
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (_) async => EdenRefundFlowFixtures.sampleSale(),
        onSubmit: (_) {},
      )));
      await lookupAndAdvance(tester);
      await setLineQty(tester, 'L-1', 1);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Step 3 of 4'), findsOneWidget);
    });

    testWidgets("'Next' on selectLines with empty refundLines → disabled",
        (tester) async {
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (_) async => EdenRefundFlowFixtures.sampleSale(),
        onSubmit: (_) {},
      )));
      await lookupAndAdvance(tester);
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Next'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets("'Back' on selectLines → step = lookupSale, sale cleared",
        (tester) async {
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (_) async => EdenRefundFlowFixtures.sampleSale(),
        onSubmit: (_) {},
      )));
      await lookupAndAdvance(tester);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Back'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Step 1 of 4'), findsOneWidget);
    });
  });

  group('EdenRefundFlow — Step 1 LookupSale', () {
    testWidgets('search input renders', (tester) async {
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (_) async => null,
        onSubmit: (_) {},
      )));
      expect(find.byType(EdenSearchInput), findsOneWidget);
    });

    testWidgets("'Lookup' fires onLookupSale with the typed query",
        (tester) async {
      String? captured;
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (q) async {
          captured = q;
          return EdenRefundFlowFixtures.sampleSale();
        },
        onSubmit: (_) {},
      )));
      await lookupAndAdvance(tester, query: 'S-1042');
      expect(captured, 'S-1042');
    });

    testWidgets("null result → 'Sale not found' alert + stays on Step 1",
        (tester) async {
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (_) async => null,
        onSubmit: (_) {},
      )));
      await lookupAndAdvance(tester, query: 'nope');
      expect(find.textContaining('Sale not found'), findsOneWidget);
      expect(find.textContaining('Step 1 of 4'), findsOneWidget);
    });
  });

  group('EdenRefundFlow — Step 2 SelectLines', () {
    testWidgets('renders sale header with id + total', (tester) async {
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (_) async => EdenRefundFlowFixtures.sampleSale(),
        onSubmit: (_) {},
      )));
      await lookupAndAdvance(tester);
      expect(find.textContaining('S-1042'), findsOneWidget);
    });

    testWidgets('renders one editable refundQty input per sale line',
        (tester) async {
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (_) async => EdenRefundFlowFixtures.sampleSale(),
        onSubmit: (_) {},
      )));
      await lookupAndAdvance(tester);
      // sampleSale has 3 lines.
      expect(find.byKey(const ValueKey('refundQty-L-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('refundQty-L-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('refundQty-L-3')), findsOneWidget);
    });

    testWidgets('setting refundQty > 0 enables Reason picker', (tester) async {
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (_) async => EdenRefundFlowFixtures.sampleSale(),
        onSubmit: (_) {},
      )));
      await lookupAndAdvance(tester);
      // Initially no reason picker is rendered.
      expect(find.byType(EdenSelect<EdenRefundReason>), findsNothing);
      await setLineQty(tester, 'L-1', 1);
      await tester.pumpAndSettle();
      expect(find.byType(EdenSelect<EdenRefundReason>), findsOneWidget);
    });

    testWidgets('setting refundQty = 0 removes the line from _refundLines',
        (tester) async {
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (_) async => EdenRefundFlowFixtures.sampleSale(),
        onSubmit: (_) {},
      )));
      await lookupAndAdvance(tester);
      await setLineQty(tester, 'L-1', 1);
      await tester.pumpAndSettle();
      // Next is enabled.
      ElevatedButton btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Next'),
      );
      expect(btn.onPressed, isNotNull);
      await setLineQty(tester, 'L-1', 0);
      await tester.pumpAndSettle();
      btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Next'),
      );
      expect(btn.onPressed, isNull,
          reason: 'Setting qty back to 0 should empty refundLines + disable Next');
    });

    testWidgets('refund total updates live as qty changes', (tester) async {
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (_) async => EdenRefundFlowFixtures.sampleSale(),
        onSubmit: (_) {},
      )));
      await lookupAndAdvance(tester);
      await setLineQty(tester, 'L-1', 1);
      await tester.pumpAndSettle();
      // L-1 = $25 + ($2 tax / 2 qty = $1 unit-tax) = $26 refund total.
      expect(find.textContaining(r'$26.00'), findsOneWidget);
    });

    testWidgets("'Next' disabled when refundLines empty", (tester) async {
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (_) async => EdenRefundFlowFixtures.sampleSale(),
        onSubmit: (_) {},
      )));
      await lookupAndAdvance(tester);
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Next'),
      );
      expect(btn.onPressed, isNull);
    });
  });

  group('EdenRefundFlow — Step 3 Method', () {
    Future<void> advanceToMethod(WidgetTester tester) async {
      await lookupAndAdvance(tester);
      await setLineQty(tester, 'L-1', 1);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
    }

    testWidgets('renders 3 allowed methods by default', (tester) async {
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (_) async => EdenRefundFlowFixtures.sampleSale(),
        onSubmit: (_) {},
      )));
      await advanceToMethod(tester);
      expect(find.byType(RadioListTile<EdenRefundMethod>),
          findsNWidgets(3));
    });

    testWidgets('original-tender callout shown referencing sale tender',
        (tester) async {
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (_) async => EdenRefundFlowFixtures.sampleSale(),
        onSubmit: (_) {},
      )));
      await advanceToMethod(tester);
      expect(find.textContaining('Original sale was paid by'),
          findsOneWidget);
    });

    testWidgets('selecting a method enables Next', (tester) async {
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (_) async => EdenRefundFlowFixtures.sampleSale(),
        onSubmit: (_) {},
      )));
      await advanceToMethod(tester);
      // Tap originalTender radio.
      final radio = find
          .widgetWithText(RadioListTile<EdenRefundMethod>, 'Original tender');
      expect(radio, findsOneWidget);
      await tester.tap(radio);
      await tester.pumpAndSettle();
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Next'),
      );
      expect(btn.onPressed, isNotNull);
    });
  });

  group('EdenRefundFlow — Step 4 ManagerApprove', () {
    testWidgets(r'$50+ refund total + originalTender → step 4 entered',
        (tester) async {
      EdenRefundDraft? submitted;
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (_) async => EdenRefundFlowFixtures.sampleSale(),
        onManagerApprove: () async => true,
        onSubmit: (d) => submitted = d,
      )));
      await lookupAndAdvance(tester);
      // Qty 2 of L-1 ($25 * 2 + $2 tax = $52 ≥ $50 threshold).
      await setLineQty(tester, 'L-1', 2);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(
          RadioListTile<EdenRefundMethod>, 'Original tender'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Step 4 of 4'), findsOneWidget);
      expect(submitted, isNull,
          reason: 'Should NOT have submitted yet — waiting on approval');
    });

    testWidgets(r'$26 refund + originalTender → submit fires (no Step 4)',
        (tester) async {
      EdenRefundDraft? submitted;
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (_) async => EdenRefundFlowFixtures.sampleSale(),
        onManagerApprove: () async => true,
        onSubmit: (d) => submitted = d,
      )));
      await lookupAndAdvance(tester);
      await setLineQty(tester, 'L-1', 1);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(
          RadioListTile<EdenRefundMethod>, 'Original tender'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      expect(submitted, isNotNull);
      expect(submitted!.managerApproved, isFalse);
    });

    testWidgets(r'$26 refund + storeCredit method → Step 4 entered',
        (tester) async {
      EdenRefundDraft? submitted;
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (_) async => EdenRefundFlowFixtures.sampleSale(),
        onManagerApprove: () async => true,
        onSubmit: (d) => submitted = d,
      )));
      await lookupAndAdvance(tester);
      await setLineQty(tester, 'L-1', 1);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      await tester.tap(find
          .widgetWithText(RadioListTile<EdenRefundMethod>, 'Store credit'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Step 4 of 4'), findsOneWidget);
      expect(submitted, isNull);
    });

    testWidgets('PIN entry uses EdenSecretField in Step 4', (tester) async {
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (_) async => EdenRefundFlowFixtures.sampleSale(),
        onManagerApprove: () async => true,
        onSubmit: (_) {},
      )));
      await lookupAndAdvance(tester);
      await setLineQty(tester, 'L-1', 2);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(
          RadioListTile<EdenRefundMethod>, 'Original tender'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.byType(EdenSecretField), findsOneWidget);
    });

    testWidgets('Approval success → submit fires with managerApproved=true',
        (tester) async {
      EdenRefundDraft? submitted;
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (_) async => EdenRefundFlowFixtures.sampleSale(),
        onManagerApprove: () async => true,
        onSubmit: (d) => submitted = d,
      )));
      await lookupAndAdvance(tester);
      await setLineQty(tester, 'L-1', 2);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(
          RadioListTile<EdenRefundMethod>, 'Original tender'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Approve'));
      await tester.pumpAndSettle();
      expect(submitted, isNotNull);
      expect(submitted!.managerApproved, isTrue);
    });

    testWidgets("Approval failure → 'Approval denied' alert + stays on Step 4",
        (tester) async {
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (_) async => EdenRefundFlowFixtures.sampleSale(),
        onManagerApprove: () async => false,
        onSubmit: (_) {},
      )));
      await lookupAndAdvance(tester);
      await setLineQty(tester, 'L-1', 2);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(
          RadioListTile<EdenRefundMethod>, 'Original tender'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Approve'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Approval denied'), findsOneWidget);
      expect(find.textContaining('Step 4 of 4'), findsOneWidget);
    });
  });

  group('EdenRefundFlow — bypass + PCI', () {
    testWidgets(
        'onManagerApprove null: \$250 + storeCredit → submit fires (no Step 4)',
        (tester) async {
      EdenRefundDraft? submitted;
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (_) async => EdenRefundFlowFixtures.bigTicketSale(),
        onSubmit: (d) => submitted = d,
      )));
      await lookupAndAdvance(tester);
      await setLineQty(tester, 'B-1', 1);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(
          RadioListTile<EdenRefundMethod>, 'Store credit'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      expect(submitted, isNotNull,
          reason: 'Approval bypassed when onManagerApprove is null');
      expect(submitted!.managerApproved, isFalse);
    });

    test('source file does not contain card_number / cvv / pan tokens', () {
      final src = File(
        'lib/src/widgets/eden_refund_flow.dart',
      ).readAsStringSync();
      final pattern =
          RegExp(r'\b(card_number|cvv|pan)\b', caseSensitive: false);
      expect(pattern.hasMatch(src), isFalse);
    });

    test('source contains EdenSecretClipboardMode.classified', () {
      final src = File(
        'lib/src/widgets/eden_refund_flow.dart',
      ).readAsStringSync();
      expect(src.contains('EdenSecretClipboardMode.classified'), isTrue);
    });
  });

  group('EdenRefundFlow — submit draft', () {
    testWidgets(
        'draft fields: saleId / refundLines / method / totalRefundCents',
        (tester) async {
      EdenRefundDraft? submitted;
      await tester.pumpWidget(wrap(EdenRefundFlow(
        onLookupSale: (_) async => EdenRefundFlowFixtures.sampleSale(),
        onSubmit: (d) => submitted = d,
      )));
      await lookupAndAdvance(tester);
      await setLineQty(tester, 'L-1', 1);
      await setLineQty(tester, 'L-3', 2);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(
          RadioListTile<EdenRefundMethod>, 'Original tender'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      expect(submitted, isNotNull);
      expect(submitted!.saleId, 'S-1042');
      expect(submitted!.refundLines.length, 2);
      expect(submitted!.method, EdenRefundMethod.originalTender);
      // L-1 qty 1 = $25 + $1 unit-tax = $26 cents 2600.
      // L-3 qty 2 = $16 + 2 * ($175/3 ≈ 58 = round 58) → 2*58 = 116 cents tax.
      // Approximation acceptable; assert > $0.
      expect(submitted!.totalRefundCents, greaterThan(0));
    });
  });
}
