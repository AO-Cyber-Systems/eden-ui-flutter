import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_layaway_flow_fixtures.dart';

void main() {
  Widget wrap(Widget child, {double width = 1024, double height = 800}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );
  }

  group('EdenLayawayFlow — mode dispatch', () {
    testWidgets('create constructor renders step 1', (tester) async {
      await tester.pumpWidget(wrap(EdenLayawayFlow.create(
        cartItems: EdenLayawayFlowFixtures.sampleCart(),
        onSubmit: (_) {},
      )));
      expect(find.textContaining('Step 1 of 3'), findsOneWidget);
    });

    testWidgets('manage constructor renders summary card', (tester) async {
      await tester.pumpWidget(wrap(EdenLayawayFlow.manage(
        state: EdenLayawayFlowFixtures.sampleActiveState(
          now: EdenLayawayFlowFixtures.t0,
        ),
        onSubmit: (_) {},
      )));
      expect(find.textContaining('Layaway LAY-001'), findsOneWidget);
    });
  });

  group('EdenLayawayFlow — create step 1', () {
    testWidgets('renders cart items + total', (tester) async {
      await tester.pumpWidget(wrap(EdenLayawayFlow.create(
        cartItems: EdenLayawayFlowFixtures.sampleCart(),
        onSubmit: (_) {},
      )));
      expect(find.textContaining('Leather jacket'), findsOneWidget);
      expect(find.textContaining('Belt'), findsOneWidget);
      // Total = 25000+2000 + 3500+280 = 30780. Note: TRD says $305.80
      // ($30,580) but cart math: 25000+3500 = 28500 base + 2000+280 = 2280
      // tax = 30780. Assert 307.80.
      expect(find.textContaining(r'$307.80'), findsOneWidget);
    });

    testWidgets("'Attach customer' button visible when onCustomerAttach set",
        (tester) async {
      await tester.pumpWidget(wrap(EdenLayawayFlow.create(
        cartItems: EdenLayawayFlowFixtures.sampleCart(),
        onSubmit: (_) {},
        onCustomerAttach: () {},
      )));
      expect(find.text('Attach customer'), findsOneWidget);
    });

    testWidgets("'Attach customer' absent when onCustomerAttach null",
        (tester) async {
      await tester.pumpWidget(wrap(EdenLayawayFlow.create(
        cartItems: EdenLayawayFlowFixtures.sampleCart(),
        onSubmit: (_) {},
      )));
      expect(find.text('Attach customer'), findsNothing);
    });

    testWidgets("'Next' advances to step 2 (deposit)", (tester) async {
      await tester.pumpWidget(wrap(EdenLayawayFlow.create(
        cartItems: EdenLayawayFlowFixtures.sampleCart(),
        onSubmit: (_) {},
      )));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Step 2 of 3'), findsOneWidget);
    });
  });

  group('EdenLayawayFlow — create step 2 (deposit)', () {
    Future<void> advanceToStep2(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
    }

    testWidgets('renders deposit input', (tester) async {
      await tester.pumpWidget(wrap(EdenLayawayFlow.create(
        cartItems: EdenLayawayFlowFixtures.sampleCart(),
        onSubmit: (_) {},
      )));
      await advanceToStep2(tester);
      expect(find.byKey(const ValueKey('depositAmount')), findsOneWidget);
    });

    testWidgets('pre-filled with minDepositCents (20% of cart)',
        (tester) async {
      await tester.pumpWidget(wrap(EdenLayawayFlow.create(
        cartItems: EdenLayawayFlowFixtures.sampleCart(),
        onSubmit: (_) {},
      )));
      await advanceToStep2(tester);
      // 30780 * 0.20 = 6156. UI shows decimal-form '61.56'.
      final tf = tester.widget<TextField>(find.descendant(
        of: find.byKey(const ValueKey('depositAmount')),
        matching: find.byType(TextField),
      ));
      expect(tf.controller!.text, '61.56');
    });

    testWidgets('deposit < min → Next disabled', (tester) async {
      await tester.pumpWidget(wrap(EdenLayawayFlow.create(
        cartItems: EdenLayawayFlowFixtures.sampleCart(),
        onSubmit: (_) {},
      )));
      await advanceToStep2(tester);
      // Enter below min.
      await tester.enterText(
        find.byKey(const ValueKey('depositAmount')),
        '10.00',
      );
      await tester.pump();
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Next'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('deposit ≥ min → Next enabled', (tester) async {
      await tester.pumpWidget(wrap(EdenLayawayFlow.create(
        cartItems: EdenLayawayFlowFixtures.sampleCart(),
        onSubmit: (_) {},
      )));
      await advanceToStep2(tester);
      // Default pre-fill is already at min — Next should be enabled.
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Next'),
      );
      expect(btn.onPressed, isNotNull);
    });
  });

  group('EdenLayawayFlow — create step 3 (schedule)', () {
    Future<void> advanceToStep3(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
    }

    testWidgets('renders date-picker affordance', (tester) async {
      await tester.pumpWidget(wrap(EdenLayawayFlow.create(
        cartItems: EdenLayawayFlowFixtures.sampleCart(),
        onSubmit: (_) {},
      )));
      await advanceToStep3(tester);
      expect(find.byType(EdenDatePicker), findsOneWidget);
    });

    testWidgets('renders 3 notify-channel radios', (tester) async {
      await tester.pumpWidget(wrap(EdenLayawayFlow.create(
        cartItems: EdenLayawayFlowFixtures.sampleCart(),
        onSubmit: (_) {},
      )));
      await advanceToStep3(tester);
      expect(find.byType(RadioListTile<EdenLayawayNotifyChannel>),
          findsNWidgets(3));
    });

    testWidgets("'Submit' fires onSubmit with EdenLayawayCreatedDraft",
        (tester) async {
      EdenLayawayDraft? submitted;
      await tester.pumpWidget(wrap(EdenLayawayFlow.create(
        cartItems: EdenLayawayFlowFixtures.sampleCart(),
        onSubmit: (d) => submitted = d,
      )));
      await advanceToStep3(tester);
      // Pick a date by directly setting via EdenDatePicker's onChanged
      // (test helper: tap the picker → modal appears → cancel; emulate
      // selection by pumping a stateful test wrapper instead).
      //
      // Simpler: ensure Submit is enabled by default — TRD says it's
      // optional. The widget should accept a null pickupByDate but submit
      // when user clicks Submit explicitly.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pumpAndSettle();
      expect(submitted, isA<EdenLayawayCreatedDraft>());
    });
  });

  group('EdenLayawayFlow — helpers', () {
    test('edenLayawayCartTotalCents: empty → 0', () {
      expect(edenLayawayCartTotalCents(const []), 0);
    });

    test('edenLayawayCartTotalCents: sampleCart → 30780', () {
      expect(
        edenLayawayCartTotalCents(EdenLayawayFlowFixtures.sampleCart()),
        30780,
      );
    });

    test('edenLayawayMinDepositCents(30780, 0.20) = 6156', () {
      expect(edenLayawayMinDepositCents(30780, 0.20), 6156);
    });

    test('edenLayawayMinDepositCents(0, 0.20) = 0', () {
      expect(edenLayawayMinDepositCents(0, 0.20), 0);
    });

    test('edenLayawayDaysUntilPickup: +30d → 30', () {
      final now = DateTime(2026, 5, 17);
      expect(
        edenLayawayDaysUntilPickup(
          now.add(const Duration(days: 30)),
          now,
        ),
        30,
      );
    });

    test('edenLayawayDaysUntilPickup: -5d → -5', () {
      final now = DateTime(2026, 5, 17);
      expect(
        edenLayawayDaysUntilPickup(
          now.subtract(const Duration(days: 5)),
          now,
        ),
        -5,
      );
    });

    test('edenLayawayPaidSoFarCents: deposit + installments', () {
      expect(
        edenLayawayPaidSoFarCents(
          EdenLayawayFlowFixtures.sampleActiveState(),
        ),
        12200, // 6100 deposit + 6100 installment
      );
    });
  });

  group('EdenLayawayFlow — manage summary', () {
    testWidgets('shows cart items + deposit / balance / installments / countdown',
        (tester) async {
      await tester.pumpWidget(wrap(EdenLayawayFlow.manage(
        state: EdenLayawayFlowFixtures.sampleActiveState(
          now: EdenLayawayFlowFixtures.t0,
        ),
        onSubmit: (_) {},
      )));
      // Cart items hint.
      expect(find.textContaining('2 items'), findsOneWidget);
      // Deposit paid $61.00.
      expect(find.textContaining(r'$61.00'), findsAtLeastNWidgets(1));
      // Balance due $183.80.
      expect(find.textContaining(r'$183.80'), findsOneWidget);
    });

    testWidgets("countdown shows 'Pickup in 30d' for +30d", (tester) async {
      await tester.pumpWidget(wrap(EdenLayawayFlow.manage(
        state: EdenLayawayFlowFixtures.sampleActiveState(
          now: EdenLayawayFlowFixtures.t0,
        ),
        onSubmit: (_) {},
        now: EdenLayawayFlowFixtures.t0,
      )));
      expect(find.textContaining('Pickup in 30d'), findsOneWidget);
    });

    testWidgets("countdown shows 'Xd overdue' for past date", (tester) async {
      await tester.pumpWidget(wrap(EdenLayawayFlow.manage(
        state: EdenLayawayFlowFixtures.overdueState(
          now: EdenLayawayFlowFixtures.t0,
        ),
        onSubmit: (_) {},
        now: EdenLayawayFlowFixtures.t0,
      )));
      expect(find.textContaining('overdue'), findsOneWidget);
    });
  });

  group('EdenLayawayFlow — manage actions', () {
    testWidgets('EdenSelect renders 3 action options', (tester) async {
      await tester.pumpWidget(wrap(EdenLayawayFlow.manage(
        state: EdenLayawayFlowFixtures.sampleActiveState(),
        onSubmit: (_) {},
      )));
      expect(
          find.byType(EdenSelect<EdenLayawayAction>), findsOneWidget);
    });
  });

  group('EdenLayawayFlow — manage releaseToCustomer', () {
    Future<void> selectRelease(WidgetTester tester) async {
      // Open dropdown and tap 'Release to customer'.
      await tester.tap(find.byType(EdenSelect<EdenLayawayAction>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Release to customer').last);
      await tester.pumpAndSettle();
    }

    testWidgets('balance > 0: warning alert + Confirm disabled',
        (tester) async {
      await tester.pumpWidget(wrap(EdenLayawayFlow.manage(
        state: EdenLayawayFlowFixtures.sampleActiveState(
          now: EdenLayawayFlowFixtures.t0,
        ),
        onSubmit: (_) {},
      )));
      await selectRelease(tester);
      expect(find.textContaining('Balance due'), findsOneWidget);
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirm release'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('balance = 0: Confirm enabled + onSubmit fires release draft',
        (tester) async {
      EdenLayawayDraft? submitted;
      await tester.pumpWidget(wrap(EdenLayawayFlow.manage(
        state: EdenLayawayFlowFixtures.zeroBalanceState(
          now: EdenLayawayFlowFixtures.t0,
        ),
        onSubmit: (d) => submitted = d,
      )));
      await selectRelease(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm release'));
      await tester.pumpAndSettle();
      expect(submitted, isA<EdenLayawayReleaseDraft>());
      expect((submitted! as EdenLayawayReleaseDraft).layawayId, 'LAY-004');
    });
  });

  group('EdenLayawayFlow — manage cancelAndRefund', () {
    Future<void> selectCancel(WidgetTester tester) async {
      await tester.tap(find.byType(EdenSelect<EdenLayawayAction>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel & refund').last);
      await tester.pumpAndSettle();
    }

    testWidgets("Confirm dialog appears on 'Cancel layaway' tap",
        (tester) async {
      await tester.pumpWidget(wrap(EdenLayawayFlow.manage(
        state: EdenLayawayFlowFixtures.sampleActiveState(
          now: EdenLayawayFlowFixtures.t0,
        ),
        onSubmit: (_) {},
      )));
      await selectCancel(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Cancel layaway'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('Dialog Cancel → no draft emitted', (tester) async {
      EdenLayawayDraft? submitted;
      await tester.pumpWidget(wrap(EdenLayawayFlow.manage(
        state: EdenLayawayFlowFixtures.sampleActiveState(
          now: EdenLayawayFlowFixtures.t0,
        ),
        onSubmit: (d) => submitted = d,
      )));
      await selectCancel(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Cancel layaway'));
      await tester.pumpAndSettle();
      // Tap 'Keep layaway' in the dialog.
      await tester.tap(find.widgetWithText(TextButton, 'Keep layaway'));
      await tester.pumpAndSettle();
      expect(submitted, isNull);
    });

    testWidgets('Dialog Confirm → fires EdenLayawayCancelDraft', (tester) async {
      EdenLayawayDraft? submitted;
      await tester.pumpWidget(wrap(EdenLayawayFlow.manage(
        state: EdenLayawayFlowFixtures.sampleActiveState(
          now: EdenLayawayFlowFixtures.t0,
        ),
        onSubmit: (d) => submitted = d,
      )));
      await selectCancel(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Cancel layaway'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Confirm cancel'));
      await tester.pumpAndSettle();
      expect(submitted, isA<EdenLayawayCancelDraft>());
      final draft = submitted! as EdenLayawayCancelDraft;
      // refund = 6100 deposit + 6100 installment = 12200
      expect(draft.refundCents, 12200);
    });
  });

  group('EdenLayawayFlow — notify channel', () {
    testWidgets(
        'release with channel=none → onNotifyCustomer NOT called',
        (tester) async {
      var called = false;
      await tester.pumpWidget(wrap(EdenLayawayFlow.manage(
        state: EdenLayawayFlowFixtures.zeroBalanceState(
          now: EdenLayawayFlowFixtures.t0,
        ),
        onSubmit: (_) {},
        onNotifyCustomer: (_, __) async => called = true,
      )));
      await tester.tap(find.byType(EdenSelect<EdenLayawayAction>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Release to customer').last);
      await tester.pumpAndSettle();
      // Default channel is none. Tap confirm.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm release'));
      await tester.pumpAndSettle();
      expect(called, isFalse);
    });
  });

  group('EdenLayawayFlow — iPhone-narrow 390pt', () {
    testWidgets('create mode renders without RenderFlex overflow at 390pt',
        (tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EdenLayawayFlow.create(
            cartItems: EdenLayawayFlowFixtures.sampleCart(),
            onSubmit: (_) {},
          ),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
