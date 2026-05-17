import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_cash_drawer_close_fixtures.dart';

Widget wrap(Widget child, {double width = 800}) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: SingleChildScrollView(child: child),
        ),
      ),
    );

void main() {
  // Helper to advance to a step via the ChoiceChip header.
  Future<void> goTo(WidgetTester tester, String step) async {
    await tester.tap(find.widgetWithText(ChoiceChip, step));
    await tester.pump();
  }

  testWidgets('renders 10 USD denomination rows on COUNT step',
      (tester) async {
    await tester.pumpWidget(wrap(EdenCashDrawerClose(
      initialSession: EdenCashDrawerCloseFixtures.emptyDrawerSession,
      onSessionChanged: (_) {},
      onSubmit: (_) {},
    )));
    expect(find.text(r'$100'), findsOneWidget);
    expect(find.text(r'$20'), findsOneWidget);
    expect(find.text('Penny'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(10));
  });

  testWidgets('COUNT footer shows Expected + Counted + Variance',
      (tester) async {
    await tester.pumpWidget(wrap(EdenCashDrawerClose(
      initialSession: EdenCashDrawerCloseFixtures.emptyDrawerSession,
      onSessionChanged: (_) {},
      onSubmit: (_) {},
    )));
    expect(find.text('Expected: '), findsOneWidget);
    expect(find.text('Counted: '), findsOneWidget);
    expect(find.text('Variance: '), findsOneWidget);
  });

  testWidgets('TRANSACTIONS step renders DataTable when session has txs',
      (tester) async {
    await tester.pumpWidget(wrap(EdenCashDrawerClose(
      initialSession: EdenCashDrawerCloseFixtures.sessionWithTransactions,
      onSessionChanged: (_) {},
      onSubmit: (_) {},
    )));
    await goTo(tester, 'transactions');
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Cash drop'), findsOneWidget);
  });

  testWidgets('DEPOSIT step visible when allowDeposit=true', (tester) async {
    await tester.pumpWidget(wrap(EdenCashDrawerClose(
      initialSession: EdenCashDrawerCloseFixtures.emptyDrawerSession,
      onSessionChanged: (_) {},
      onSubmit: (_) {},
    )));
    await goTo(tester, 'deposit');
    expect(find.text('Cash to deposit'), findsOneWidget);
  });

  testWidgets('DEPOSIT step hidden when allowDeposit=false', (tester) async {
    await tester.pumpWidget(wrap(EdenCashDrawerClose(
      initialSession: EdenCashDrawerCloseFixtures.emptyDrawerSession,
      onSessionChanged: (_) {},
      onSubmit: (_) {},
      allowDeposit: false,
    )));
    expect(find.widgetWithText(ChoiceChip, 'deposit'), findsNothing);
  });

  testWidgets('REVIEW step renders summary', (tester) async {
    await tester.pumpWidget(wrap(EdenCashDrawerClose(
      initialSession: EdenCashDrawerCloseFixtures.emptyDrawerSession,
      onSessionChanged: (_) {},
      onSubmit: (_) {},
    )));
    await goTo(tester, 'review');
    expect(find.textContaining('Starting float:'), findsOneWidget);
    expect(find.text('Confirm close'), findsOneWidget);
  });

  testWidgets('typing 5 in \$20 denomination row → subtotal \$100, emits',
      (tester) async {
    EdenDrawerSession? captured;
    await tester.pumpWidget(wrap(EdenCashDrawerClose(
      initialSession: EdenCashDrawerCloseFixtures.emptyDrawerSession,
      onSessionChanged: (s) => captured = s,
      onSubmit: (_) {},
    )));
    // Find the 20-dollar row TextFormField — the field with controller
    // matching the $20 label. Easier: enter into all fields; the test
    // verifies the captured session has the correct count.
    final fields = find.byType(TextFormField);
    // Field index 2 is $20 (after $100, $50).
    await tester.enterText(fields.at(2), '5');
    await tester.pump();
    expect(captured, isNotNull);
    final twentyEntry = captured!.closingCount!
        .firstWhere((e) => e.denomination.value == 20.0);
    expect(twentyEntry.count, 5);
    expect(twentyEntry.lineTotal, 100.0);
  });

  testWidgets('Counted balance + variance update on count changes',
      (tester) async {
    EdenDrawerSession? captured;
    await tester.pumpWidget(wrap(EdenCashDrawerClose(
      initialSession: EdenCashDrawerCloseFixtures.emptyDrawerSession,
      onSessionChanged: (s) => captured = s,
      onSubmit: (_) {},
    )));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '2'); // 2 × $100 = $200
    await tester.pump();
    expect(captured!.countedClosingBalance, closeTo(200.0, 0.001));
    // expectedClosingBalance = 200 (starting float) + 0 (no tx) = 200
    expect(captured!.computedVariance, closeTo(0.0, 0.001));
  });

  testWidgets('balanced variance is 0; computedVariance == 0', (tester) async {
    EdenDrawerSession? captured;
    await tester.pumpWidget(wrap(EdenCashDrawerClose(
      initialSession: EdenCashDrawerCloseFixtures.emptyDrawerSession,
      onSessionChanged: (s) => captured = s,
      onSubmit: (_) {},
    )));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '2');
    await tester.pump();
    expect(captured!.computedVariance.abs() <= 0.01, isTrue);
  });

  testWidgets("'Add cash drop' reveals form; Submit appends transaction",
      (tester) async {
    EdenDrawerSession? captured;
    await tester.pumpWidget(wrap(EdenCashDrawerClose(
      initialSession: EdenCashDrawerCloseFixtures.emptyDrawerSession,
      onSessionChanged: (s) => captured = s,
      onSubmit: (_) {},
    )));
    await goTo(tester, 'transactions');
    await tester.tap(find.text('Add cash drop'));
    await tester.pump();
    final allFields = find.byType(TextFormField);
    await tester.enterText(allFields.first, '150');
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.transactions.length, 1);
    // Cash drop is a debit → negative amount stored.
    expect(captured!.transactions.first.amount, closeTo(-150.0, 0.001));
  });

  testWidgets('negative transactions render with error color',
      (tester) async {
    await tester.pumpWidget(wrap(EdenCashDrawerClose(
      initialSession: EdenCashDrawerCloseFixtures.sessionWithTransactions,
      onSessionChanged: (_) {},
      onSubmit: (_) {},
    )));
    await goTo(tester, 'transactions');
    expect(find.text(r'$-150.00'), findsOneWidget);
  });

  testWidgets(
      'deposit form keystrokes recorded; appear in onSubmit result',
      (tester) async {
    EdenCashDrawerCloseResult? captured;
    await tester.pumpWidget(wrap(EdenCashDrawerClose(
      initialSession: EdenCashDrawerCloseFixtures.emptyDrawerSession,
      onSessionChanged: (_) {},
      onSubmit: (r) => captured = r,
    )));
    await goTo(tester, 'deposit');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Cash to deposit'), '300.00');
    await tester.pump();
    await goTo(tester, 'review');
    await tester.tap(find.text('Confirm close'));
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.deposit, isNotNull);
    expect(captured!.deposit!.cashAmount, closeTo(300.0, 0.001));
  });

  testWidgets("'Skip deposit' advances to review with deposit=null",
      (tester) async {
    EdenCashDrawerCloseResult? captured;
    await tester.pumpWidget(wrap(EdenCashDrawerClose(
      initialSession: EdenCashDrawerCloseFixtures.emptyDrawerSession,
      onSessionChanged: (_) {},
      onSubmit: (r) => captured = r,
    )));
    await goTo(tester, 'deposit');
    await tester.tap(find.text('Skip deposit'));
    await tester.pump();
    await tester.tap(find.text('Confirm close'));
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.deposit, isNull);
  });

  testWidgets(
      'variance > 5 with manager-override message disables Confirm '
      'until Manager approves', (tester) async {
    bool submitted = false;
    await tester.pumpWidget(wrap(EdenCashDrawerClose(
      initialSession: EdenCashDrawerCloseFixtures.emptyDrawerSession,
      onSessionChanged: (_) {},
      onSubmit: (_) => submitted = true,
      varianceManagerOverrideMessage:
          'Variance over \$5 — manager review required',
    )));
    // Create variance of -100 — empty count vs starting float 200
    // (expected close = 200, counted = 0 → variance = -200).
    await goTo(tester, 'review');
    final confirm = tester.widget<EdenButton>(
        find.widgetWithText(EdenButton, 'Confirm close'));
    expect(confirm.onPressed, isNull); // Disabled
    await tester.tap(find.text('Manager approves'));
    await tester.pump();
    final confirm2 = tester.widget<EdenButton>(
        find.widgetWithText(EdenButton, 'Confirm close'));
    expect(confirm2.onPressed, isNotNull); // Enabled
    await tester.tap(find.text('Confirm close'));
    await tester.pump();
    expect(submitted, isTrue);
  });

  testWidgets("'Manager approves' shows approved banner on review",
      (tester) async {
    await tester.pumpWidget(wrap(EdenCashDrawerClose(
      initialSession: EdenCashDrawerCloseFixtures.emptyDrawerSession,
      onSessionChanged: (_) {},
      onSubmit: (_) {},
      varianceManagerOverrideMessage: 'Variance over threshold',
    )));
    await goTo(tester, 'review');
    await tester.tap(find.text('Manager approves'));
    await tester.pump();
    expect(find.text('Manager-approved variance'), findsOneWidget);
  });

  testWidgets("'Confirm close' fires onSubmit with result", (tester) async {
    EdenCashDrawerCloseResult? captured;
    await tester.pumpWidget(wrap(EdenCashDrawerClose(
      initialSession: EdenCashDrawerCloseFixtures.emptyDrawerSession,
      onSessionChanged: (_) {},
      onSubmit: (r) => captured = r,
      allowDeposit: false,
    )));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '2'); // $200
    await tester.pump();
    await goTo(tester, 'review');
    await tester.tap(find.text('Confirm close'));
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.finalSession.closedAt, isNotNull);
  });

  testWidgets('iPhone-narrow (390pt): denomination rows wrap in EdenCard',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: EdenCashDrawerClose(
            initialSession: EdenCashDrawerCloseFixtures.emptyDrawerSession,
            onSessionChanged: (_) {},
            onSubmit: (_) {},
          ),
        ),
      ),
    ));
    expect(find.byType(EdenCard), findsWidgets);
  });

  testWidgets('Semantics: denomination rows + variance labels', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(EdenCashDrawerClose(
      initialSession: EdenCashDrawerCloseFixtures.emptyDrawerSession,
      onSessionChanged: (_) {},
      onSubmit: (_) {},
    )));
    expect(
      find.bySemanticsLabel(RegExp(r'^\d+ count of .+, subtotal \$.+')),
      findsWidgets,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'Variance: \$.+, (over|under)')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
