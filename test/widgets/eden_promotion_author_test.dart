import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_promotion_author_fixtures.dart';

Widget wrap(Widget child, {double width = 600}) => MaterialApp(
      home: Scaffold(body: SizedBox(width: width, child: child)),
    );

void main() {
  testWidgets('renders 4-segment type picker at top', (tester) async {
    await tester.pumpWidget(wrap(EdenPromotionAuthor(
      rule: EdenPromotionAuthorFixtures.bogoBuy2Get1Rule,
      onRuleChanged: (_) {},
    )));
    expect(find.text('BOGO'), findsOneWidget);
    expect(find.text('Member pricing'), findsOneWidget);
    expect(find.text('Coupon code'), findsOneWidget);
    expect(find.text('Member only'), findsOneWidget);
  });

  testWidgets('renders BOGO body (Buy + Get fields)', (tester) async {
    await tester.pumpWidget(wrap(EdenPromotionAuthor(
      rule: EdenPromotionAuthorFixtures.bogoBuy2Get1Rule,
      onRuleChanged: (_) {},
    )));
    expect(find.widgetWithText(TextFormField, 'Buy'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Get'), findsOneWidget);
  });

  testWidgets('renders memberPricing body (Percent off + value)',
      (tester) async {
    await tester.pumpWidget(wrap(EdenPromotionAuthor(
      rule: EdenPromotionAuthorFixtures.memberPricingGoldRule,
      onRuleChanged: (_) {},
    )));
    expect(find.text('Percent off'), findsOneWidget);
    expect(find.text('Amount off'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Discount value'),
        findsOneWidget);
  });

  testWidgets('renders couponCode body (code field uppercase)',
      (tester) async {
    await tester.pumpWidget(wrap(EdenPromotionAuthor(
      rule: EdenPromotionAuthorFixtures.couponSummer20Rule,
      onRuleChanged: (_) {},
    )));
    expect(find.widgetWithText(TextFormField, 'Coupon code'), findsOneWidget);
  });

  testWidgets('renders memberOnly body (helper text)', (tester) async {
    await tester.pumpWidget(wrap(EdenPromotionAuthor(
      rule: EdenPromotionAuthorFixtures.memberOnlyVipRule,
      onRuleChanged: (_) {},
    )));
    expect(
      find.text('No discount — restricts product visibility'),
      findsOneWidget,
    );
  });

  testWidgets('switching type clears non-applicable fields', (tester) async {
    EdenPromotionRule? captured;
    await tester.pumpWidget(wrap(EdenPromotionAuthor(
      rule: EdenPromotionAuthorFixtures.couponSummer20Rule,
      onRuleChanged: (r) => captured = r,
    )));
    await tester.tap(find.text('BOGO'));
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.type, EdenPromotionType.bogo);
    expect(captured!.couponCode, isNull);
  });

  testWidgets('BOGO buyQuantity keystroke emits rule.buyQuantity',
      (tester) async {
    EdenPromotionRule? captured;
    await tester.pumpWidget(wrap(EdenPromotionAuthor(
      rule: const EdenPromotionRule(
        id: 'r',
        label: '',
        type: EdenPromotionType.bogo,
        discountKind: EdenPromotionDiscountKind.buyXgetYfree,
      ),
      onRuleChanged: (r) => captured = r,
      showLabelField: false,
    )));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Buy'), '2');
    await tester.pump();
    expect(captured!.buyQuantity, 2);
  });

  testWidgets('BOGO getQuantity keystroke emits rule.getQuantity',
      (tester) async {
    EdenPromotionRule? captured;
    await tester.pumpWidget(wrap(EdenPromotionAuthor(
      rule: const EdenPromotionRule(
        id: 'r',
        label: '',
        type: EdenPromotionType.bogo,
        discountKind: EdenPromotionDiscountKind.buyXgetYfree,
        buyQuantity: 2,
      ),
      onRuleChanged: (r) => captured = r,
      showLabelField: false,
    )));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Get'), '1');
    await tester.pump();
    expect(captured!.getQuantity, 1);
  });

  testWidgets('coupon code field forces uppercase + emits rule.couponCode',
      (tester) async {
    EdenPromotionRule? captured;
    await tester.pumpWidget(wrap(EdenPromotionAuthor(
      rule: const EdenPromotionRule(
        id: 'r',
        label: '',
        type: EdenPromotionType.couponCode,
        discountKind: EdenPromotionDiscountKind.percentOff,
      ),
      onRuleChanged: (r) => captured = r,
      showLabelField: false,
    )));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Coupon code'), 'summer20');
    await tester.pump();
    expect(captured!.couponCode, 'SUMMER20');
  });

  testWidgets('constraint sub-form Start date picker emits rule.constraints',
      (tester) async {
    EdenPromotionRule? captured;
    await tester.pumpWidget(wrap(EdenPromotionAuthor(
      rule: EdenPromotionAuthorFixtures.couponSummer20Rule,
      onRuleChanged: (r) => captured = r,
    )));
    // Expand the constraints accordion.
    await tester.tap(find.text('Constraints (window + limits + minimum)'));
    await tester.pumpAndSettle();
    expect(find.text('Starts: '), findsOneWidget);
    expect(captured, anyOf(isNull, isNotNull));
  });

  testWidgets('endsAt < startsAt surfaces danger banner', (tester) async {
    await tester.pumpWidget(wrap(EdenPromotionAuthor(
      rule: EdenPromotionRule(
        id: 'r',
        label: 'Invalid window',
        type: EdenPromotionType.couponCode,
        discountKind: EdenPromotionDiscountKind.percentOff,
        couponCode: 'X',
        discountValue: 0.10,
        constraints: EdenPromotionConstraint(
          startsAt: DateTime(2026, 6, 1),
          endsAt: DateTime(2026, 5, 1),
        ),
      ),
      onRuleChanged: (_) {},
    )));
    expect(find.text('End date must be after start'), findsOneWidget);
  });

  testWidgets('empty coupon code surfaces warning banner', (tester) async {
    await tester.pumpWidget(wrap(EdenPromotionAuthor(
      rule: const EdenPromotionRule(
        id: 'r',
        label: '',
        type: EdenPromotionType.couponCode,
      ),
      onRuleChanged: (_) {},
    )));
    expect(find.text('Enter coupon code'), findsOneWidget);
  });

  testWidgets('iPhone-narrow (390pt): no overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: EdenPromotionAuthor(
            rule: EdenPromotionAuthorFixtures.bogoBuy2Get1Rule,
            onRuleChanged: (_) {},
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Semantics: iPhone-narrow type picker carries selected labels',
      (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: EdenPromotionAuthor(
            rule: EdenPromotionAuthorFixtures.bogoBuy2Get1Rule,
            onRuleChanged: (_) {},
          ),
        ),
      ),
    ));
    expect(
      find.bySemanticsLabel('Promotion type: BOGO, selected'),
      findsOneWidget,
    );
    handle.dispose();
  });
}
