import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_promotion_apply_fixtures.dart';
import '_fixtures/eden_promotion_author_fixtures.dart';

Widget wrap(Widget child, {double width = 600}) => MaterialApp(
      home: Scaffold(body: SizedBox(width: width, child: child)),
    );

void main() {
  testWidgets("renders 'Available promotions' header + cards",
      (tester) async {
    await tester.pumpWidget(wrap(EdenPromotionApply(
      context: EdenPromotionApplyFixtures.eligibleContext(
        tiers: ['gold'],
      ),
      availableRules: [
        EdenPromotionAuthorFixtures.memberPricingGoldRule,
      ],
      onPromotionApplied: (_) {},
    )));
    expect(find.text('Available promotions'), findsOneWidget);
    expect(find.byType(EdenCard), findsOneWidget);
  });

  testWidgets('eligible rule shows Apply button; ineligible shows reason',
      (tester) async {
    await tester.pumpWidget(wrap(EdenPromotionApply(
      context: EdenPromotionApplyFixtures.eligibleContext(
        tiers: ['gold'],
        at: DateTime(2026, 7, 1),
      ),
      availableRules: [
        EdenPromotionAuthorFixtures.memberPricingGoldRule, // eligible
        EdenPromotionAuthorFixtures.expiredRule, // ineligible
      ],
      onPromotionApplied: (_) {},
    )));
    expect(find.text('Apply'), findsOneWidget); // only on eligible
    expect(find.textContaining('Not eligible —'), findsOneWidget);
  });

  test('evaluatePromotionEligibility — expired rule', () {
    final result = evaluatePromotionEligibility(
      EdenPromotionAuthorFixtures.expiredRule,
      EdenPromotionApplyFixtures.eligibleContext(at: DateTime(2026, 7, 1)),
    );
    expect(result.eligible, isFalse);
    expect(result.ineligibleReason, 'Expired');
  });

  test('evaluatePromotionEligibility — below min subtotal', () {
    final result = evaluatePromotionEligibility(
      EdenPromotionAuthorFixtures.couponSummer20Rule,
      EdenPromotionApplyFixtures.ineligibleContextBelowMinSubtotal(),
    );
    expect(result.eligible, isFalse);
    expect(result.ineligibleReason, contains('Subtotal below'));
  });

  test('evaluatePromotionEligibility — memberPricing without tier', () {
    final result = evaluatePromotionEligibility(
      EdenPromotionAuthorFixtures.memberPricingGoldRule,
      EdenPromotionApplyFixtures.eligibleContext(),
    );
    expect(result.eligible, isFalse);
    expect(result.ineligibleReason, contains('Not a member'));
  });

  test('evaluatePromotionEligibility — BOGO with qty >= buy', () {
    final result = evaluatePromotionEligibility(
      EdenPromotionAuthorFixtures.bogoBuy2Get1Rule,
      EdenPromotionApplyFixtures.eligibleContext(),
    );
    // lineItems = 2+1 = 3 qty; buyQty=2 → eligible
    expect(result.eligible, isTrue);
    expect(result.computedDiscount, isNull); // free-item kind
  });

  test('evaluatePromotionEligibility — percentOff yields subtotal × value',
      () {
    final result = evaluatePromotionEligibility(
      EdenPromotionAuthorFixtures.memberPricingGoldRule,
      EdenPromotionApplyFixtures.eligibleContext(tiers: ['gold']),
    );
    expect(result.eligible, isTrue);
    expect(result.computedDiscount, closeTo(48.00 * 0.15, 0.001));
  });

  testWidgets('Apply tap on eligible rule emits Result with discountAmount',
      (tester) async {
    EdenPromotionApplyResult? captured;
    await tester.pumpWidget(wrap(EdenPromotionApply(
      context: EdenPromotionApplyFixtures.eligibleContext(
        tiers: ['gold'],
        at: DateTime(2026, 7, 1),
      ),
      availableRules: [
        EdenPromotionAuthorFixtures.memberPricingGoldRule,
      ],
      onPromotionApplied: (r) => captured = r,
      showCouponCodeEntry: false,
    )));
    await tester.tap(find.text('Apply'));
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.discountAmount, closeTo(48.00 * 0.15, 0.001));
  });

  testWidgets(
      'BOGO apply produces updatedLineItems with bogo-free- synthetic row',
      (tester) async {
    EdenPromotionApplyResult? captured;
    await tester.pumpWidget(wrap(EdenPromotionApply(
      context: EdenPromotionApplyFixtures.eligibleContext(
        at: DateTime(2026, 7, 1),
      ),
      availableRules: [
        EdenPromotionAuthorFixtures.bogoBuy2Get1Rule,
      ],
      onPromotionApplied: (r) => captured = r,
      showCouponCodeEntry: false,
    )));
    await tester.tap(find.text('Apply'));
    await tester.pump();
    expect(captured, isNotNull);
    final freeItems = captured!.updatedLineItems
        .where((i) => i.id.startsWith('bogo-free-'))
        .toList();
    expect(freeItems.length, 1);
  });

  testWidgets('Coupon code typed case-insensitively → applies', (tester) async {
    EdenPromotionApplyResult? captured;
    await tester.pumpWidget(wrap(EdenPromotionApply(
      context: EdenPromotionApplyFixtures.eligibleContext(
        at: DateTime(2026, 7, 1),
        // SUMMER20 requires minSubtotal: 50.00; bump above the bar.
        subtotal: 100.00,
      ),
      availableRules: [
        EdenPromotionAuthorFixtures.couponSummer20Rule,
      ],
      onPromotionApplied: (r) => captured = r,
    )));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter coupon code'),
        'summer20');
    await tester.tap(find.text('Apply code'));
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.appliedRule.couponCode, 'SUMMER20');
  });

  testWidgets('Coupon code mismatch shows warning banner', (tester) async {
    await tester.pumpWidget(wrap(EdenPromotionApply(
      context: EdenPromotionApplyFixtures.eligibleContext(
        at: DateTime(2026, 7, 1),
      ),
      availableRules: [
        EdenPromotionAuthorFixtures.couponSummer20Rule,
      ],
      onPromotionApplied: (_) {},
    )));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter coupon code'),
        'BOGUS');
    await tester.tap(find.text('Apply code'));
    await tester.pump();
    expect(find.text('Coupon code not recognized'), findsOneWidget);
  });

  testWidgets("'Remove promotion' clears applied + emits null",
      (tester) async {
    EdenPromotionApplyResult? captured;
    bool wasCleared = false;
    await tester.pumpWidget(wrap(EdenPromotionApply(
      context: EdenPromotionApplyFixtures.eligibleContext(
        tiers: ['gold'],
        at: DateTime(2026, 7, 1),
      ),
      availableRules: [
        EdenPromotionAuthorFixtures.memberPricingGoldRule,
      ],
      onPromotionApplied: (r) {
        captured = r;
        if (r == null) wasCleared = true;
      },
      showCouponCodeEntry: false,
    )));
    await tester.tap(find.text('Apply'));
    await tester.pump();
    expect(captured, isNotNull);
    await tester.tap(find.text('Remove promotion'));
    await tester.pump();
    expect(wasCleared, isTrue);
  });

  testWidgets('iPhone-narrow (390pt): no overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: EdenPromotionApply(
            context: EdenPromotionApplyFixtures.eligibleContext(
              tiers: ['gold'],
              at: DateTime(2026, 7, 1),
            ),
            availableRules: [
              EdenPromotionAuthorFixtures.memberPricingGoldRule,
              EdenPromotionAuthorFixtures.couponSummer20Rule,
            ],
            onPromotionApplied: (_) {},
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });

  testWidgets("Semantics: rule cards labeled with 'Promotion:' prefix",
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(EdenPromotionApply(
      context: EdenPromotionApplyFixtures.eligibleContext(
        tiers: ['gold'],
        at: DateTime(2026, 7, 1),
      ),
      availableRules: [
        EdenPromotionAuthorFixtures.memberPricingGoldRule,
      ],
      onPromotionApplied: (_) {},
    )));
    expect(
      find.bySemanticsLabel(RegExp(r'^Promotion: Gold-tier 15% off,.+')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
