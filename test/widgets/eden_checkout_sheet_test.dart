import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_checkout_sheet_fixtures.dart';

Widget wrap(Widget child, {double width = 700, double height = 800}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );

void main() {
  testWidgets('renders 4-step EdenStepper at currentStep=lineItems',
      (tester) async {
    await tester.pumpWidget(wrap(EdenCheckoutSheet(
      initialDraft: EdenCheckoutSheetFixtures.draftWithLineItems,
      onDraftChanged: (_) {},
      onComplete: (_) {},
    )));
    expect(find.byType(EdenStepper), findsOneWidget);
  });

  testWidgets('step lineItems shows EdenLineItemEditor', (tester) async {
    await tester.pumpWidget(wrap(EdenCheckoutSheet(
      initialDraft: EdenCheckoutSheetFixtures.draftWithLineItems,
      onDraftChanged: (_) {},
      onComplete: (_) {},
    )));
    expect(find.byType(EdenLineItemEditor<dynamic>), findsOneWidget);
  });

  testWidgets('step tip shows EdenTippingSelector', (tester) async {
    await tester.pumpWidget(wrap(EdenCheckoutSheet(
      initialDraft: EdenCheckoutSheetFixtures.draftAtTipStep,
      onDraftChanged: (_) {},
      onComplete: (_) {},
    )));
    expect(find.byType(EdenTippingSelector), findsOneWidget);
  });

  testWidgets('step payment shows EdenSplitTender', (tester) async {
    await tester.pumpWidget(wrap(EdenCheckoutSheet(
      initialDraft: EdenCheckoutSheetFixtures.draftAtPaymentStep,
      onDraftChanged: (_) {},
      onComplete: (_) {},
    )));
    expect(find.byType(EdenSplitTender), findsOneWidget);
  });

  testWidgets('step review shows Total + Complete button', (tester) async {
    await tester.pumpWidget(wrap(EdenCheckoutSheet(
      initialDraft: EdenCheckoutSheetFixtures.draftAtReviewStep,
      onDraftChanged: (_) {},
      onComplete: (_) {},
    )));
    expect(find.text('Order summary'), findsOneWidget);
    expect(find.text('Complete'), findsOneWidget);
  });

  testWidgets("'Continue' present on lineItems",
      (tester) async {
    await tester.pumpWidget(wrap(EdenCheckoutSheet(
      initialDraft: EdenCheckoutSheetFixtures.draftWithLineItems,
      onDraftChanged: (_) {},
      onComplete: (_) {},
    )));
    expect(find.byKey(const ValueKey('checkout-continue')), findsOneWidget);
  });

  testWidgets("'Continue' absent on review",
      (tester) async {
    await tester.pumpWidget(wrap(EdenCheckoutSheet(
      initialDraft: EdenCheckoutSheetFixtures.draftAtReviewStep,
      onDraftChanged: (_) {},
      onComplete: (_) {},
    )));
    expect(find.byKey(const ValueKey('checkout-continue')), findsNothing);
  });

  testWidgets("'Back' absent on lineItems", (tester) async {
    await tester.pumpWidget(wrap(EdenCheckoutSheet(
      initialDraft: EdenCheckoutSheetFixtures.draftWithLineItems,
      onDraftChanged: (_) {},
      onComplete: (_) {},
    )));
    expect(find.widgetWithText(EdenButton, 'Back'), findsNothing);
  });

  testWidgets("'Back' present on tip", (tester) async {
    await tester.pumpWidget(wrap(EdenCheckoutSheet(
      initialDraft: EdenCheckoutSheetFixtures.draftAtTipStep,
      onDraftChanged: (_) {},
      onComplete: (_) {},
    )));
    expect(find.widgetWithText(EdenButton, 'Back'), findsOneWidget);
  });

  testWidgets("'Continue' on lineItems advances to tip + emits", (tester) async {
    EdenCheckoutDraft? captured;
    await tester.pumpWidget(wrap(EdenCheckoutSheet(
      initialDraft: EdenCheckoutSheetFixtures.draftWithLineItems,
      onDraftChanged: (d) => captured = d,
      onComplete: (_) {},
    )));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.currentStep, EdenCheckoutStep.tip);
  });

  testWidgets("'Continue' on tip advances to payment", (tester) async {
    EdenCheckoutDraft? captured;
    await tester.pumpWidget(wrap(EdenCheckoutSheet(
      initialDraft: EdenCheckoutSheetFixtures.draftAtTipStep,
      onDraftChanged: (d) => captured = d,
      onComplete: (_) {},
    )));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(captured!.currentStep, EdenCheckoutStep.payment);
  });

  testWidgets("'Continue' on payment advances to review when balance is met",
      (tester) async {
    final draft = EdenCheckoutSheetFixtures.draftWithLineItems.copyWith(
      currentStep: EdenCheckoutStep.payment,
      payments: const [
        EdenPaymentDraft(method: EdenPaymentMethod.cash, amount: 173.2),
      ],
    );
    EdenCheckoutDraft? captured;
    await tester.pumpWidget(wrap(EdenCheckoutSheet(
      initialDraft: draft,
      onDraftChanged: (d) => captured = d,
      onComplete: (_) {},
    )));
    // Total = 65 + 95 = 160 + tax (0.0825 of 160 = 13.20) = 173.20.
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(captured!.currentStep, EdenCheckoutStep.review);
  });

  testWidgets("'Back' on tip returns to lineItems", (tester) async {
    EdenCheckoutDraft? captured;
    await tester.pumpWidget(wrap(EdenCheckoutSheet(
      initialDraft: EdenCheckoutSheetFixtures.draftAtTipStep,
      onDraftChanged: (d) => captured = d,
      onComplete: (_) {},
    )));
    await tester.tap(find.text('Back'));
    await tester.pump();
    expect(captured!.currentStep, EdenCheckoutStep.lineItems);
  });

  testWidgets('tip selector emits draft.tip on preset tap', (tester) async {
    EdenCheckoutDraft? captured;
    await tester.pumpWidget(wrap(EdenCheckoutSheet(
      initialDraft: EdenCheckoutSheetFixtures.draftAtTipStep,
      onDraftChanged: (d) => captured = d,
      onComplete: (_) {},
    )));
    await tester.tap(find.text('18%'));
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.tip.mode, EdenTipMode.percent);
  });

  testWidgets("'Continue' disabled on payment when balance != 0", (tester) async {
    final draft = EdenCheckoutSheetFixtures.draftWithLineItems
        .copyWith(currentStep: EdenCheckoutStep.payment);
    await tester.pumpWidget(wrap(EdenCheckoutSheet(
      initialDraft: draft,
      onDraftChanged: (_) {},
      onComplete: (_) {},
    )));
    final btn = tester.widget<EdenButton>(
        find.widgetWithText(EdenButton, 'Continue'));
    expect(btn.onPressed, isNull);
  });

  testWidgets('review total math = subtotal - discount + tip + tax',
      (tester) async {
    const draft = EdenCheckoutDraft(
      lineItems: [
        EdenLineItem<dynamic>(
          id: '1',
          payload: null,
          description: 'Item',
          quantity: 1,
          unitPrice: 100.0,
        ),
      ],
      tip: EdenTipDraft(
          mode: EdenTipMode.percent, tipAmount: 18, selectedPercent: 0.18),
      payments: <EdenPaymentDraft>[],
      taxRate: 0.10,
      currentStep: EdenCheckoutStep.review,
    );
    expect(draft.subtotal, 100.0);
    expect(draft.discount, 0.0);
    expect(draft.taxAmount, closeTo(10.0, 0.001));
    expect(draft.total, closeTo(128.0, 0.001));
  });

  testWidgets("'Complete' tap calls onComplete with final draft",
      (tester) async {
    EdenCheckoutDraft? captured;
    await tester.pumpWidget(wrap(EdenCheckoutSheet(
      initialDraft: EdenCheckoutSheetFixtures.draftAtReviewStep,
      onDraftChanged: (_) {},
      onComplete: (d) => captured = d,
    )));
    await tester.tap(find.text('Complete'));
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.currentStep, EdenCheckoutStep.review);
  });

  testWidgets('iPhone-narrow (390pt): EdenStepper collapses to Chip variant',
      (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EdenCheckoutSheet(
          initialDraft: EdenCheckoutSheetFixtures.draftWithLineItems,
          onDraftChanged: (_) {},
          onComplete: (_) {},
        ),
      ),
    ));
    // EdenStepper not used at narrow; Chip-based dots used instead.
    expect(find.byType(EdenStepper), findsNothing);
    expect(find.byType(Chip), findsWidgets);
  });

  testWidgets('sheet body content is Scrollable', (tester) async {
    await tester.pumpWidget(wrap(EdenCheckoutSheet(
      initialDraft: EdenCheckoutSheetFixtures.draftWithLineItems,
      onDraftChanged: (_) {},
      onComplete: (_) {},
    )));
    expect(find.byType(SingleChildScrollView), findsWidgets);
  });

  testWidgets("Semantics: 'Complete checkout, total \$X.XX' label on review",
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(EdenCheckoutSheet(
      initialDraft: EdenCheckoutSheetFixtures.draftAtReviewStep,
      onDraftChanged: (_) {},
      onComplete: (_) {},
    )));
    expect(
      find.bySemanticsLabel(
          RegExp(r'Complete checkout, total \$.+')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
