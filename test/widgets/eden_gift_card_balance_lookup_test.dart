import 'dart:async';
import 'dart:io';

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_gift_card_balance_lookup_fixtures.dart';

void main() {
  Widget wrap(Widget child, {double width = 1024}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  Future<void> enterCardNumber(WidgetTester tester, String text) async {
    final field = find.byType(EdenSecretField);
    expect(field, findsOneWidget,
        reason: 'Expected one EdenSecretField for gift-card # entry');
    final textField = find.descendant(
      of: field,
      matching: find.byType(TextField),
    );
    await tester.enterText(textField, text);
    await tester.pump();
  }

  group('EdenGiftCardBalanceLookup — idle state', () {
    testWidgets("title 'Gift card balance lookup' rendered", (tester) async {
      await tester.pumpWidget(wrap(EdenGiftCardBalanceLookup(
        onLookup: EdenGiftCardLookupFixtures.notFoundLookupFn(),
      )));
      expect(find.text('Gift card balance lookup'), findsOneWidget);
    });

    testWidgets("EdenSecretField rendered with label 'Gift card #'",
        (tester) async {
      await tester.pumpWidget(wrap(EdenGiftCardBalanceLookup(
        onLookup: EdenGiftCardLookupFixtures.notFoundLookupFn(),
      )));
      expect(find.byType(EdenSecretField), findsOneWidget);
      expect(find.text('Gift card #'), findsOneWidget);
    });

    testWidgets("'Lookup' button rendered", (tester) async {
      await tester.pumpWidget(wrap(EdenGiftCardBalanceLookup(
        onLookup: EdenGiftCardLookupFixtures.notFoundLookupFn(),
      )));
      expect(find.widgetWithText(ElevatedButton, 'Lookup'), findsOneWidget);
    });

    testWidgets('Lookup button disabled initially (empty input)',
        (tester) async {
      await tester.pumpWidget(wrap(EdenGiftCardBalanceLookup(
        onLookup: EdenGiftCardLookupFixtures.notFoundLookupFn(),
      )));
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Lookup'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('no result section initially', (tester) async {
      await tester.pumpWidget(wrap(EdenGiftCardBalanceLookup(
        onLookup: EdenGiftCardLookupFixtures.notFoundLookupFn(),
      )));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(EdenAlert), findsNothing);
      expect(find.byType(EdenActivityFeedItem), findsNothing);
    });
  });

  group('EdenGiftCardBalanceLookup — Lookup button gating', () {
    testWidgets('typing 3 chars: button still disabled', (tester) async {
      await tester.pumpWidget(wrap(EdenGiftCardBalanceLookup(
        onLookup: EdenGiftCardLookupFixtures.notFoundLookupFn(),
      )));
      await enterCardNumber(tester, '123');
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Lookup'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('typing 4 chars: button enabled', (tester) async {
      await tester.pumpWidget(wrap(EdenGiftCardBalanceLookup(
        onLookup: EdenGiftCardLookupFixtures.notFoundLookupFn(),
      )));
      await enterCardNumber(tester, '1234');
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Lookup'),
      );
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('tapping Lookup fires onLookup with the typed value',
        (tester) async {
      String? capturedQuery;
      await tester.pumpWidget(wrap(EdenGiftCardBalanceLookup(
        onLookup: (cardNumber) async {
          capturedQuery = cardNumber;
          return EdenGiftCardLookupFixtures.activeWithActivity();
        },
      )));
      await enterCardNumber(tester, '1234567890123456');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Lookup'));
      await tester.pump();
      // Microtask completion + final state.
      await tester.pumpAndSettle();
      expect(capturedQuery, '1234567890123456');
    });

    testWidgets('during lookup: CircularProgressIndicator visible + button disabled',
        (tester) async {
      // onLookup never completes within this test → exercise loading state.
      final pending = Completer<EdenGiftCardBalanceResult?>();
      await tester.pumpWidget(wrap(EdenGiftCardBalanceLookup(
        onLookup: (_) => pending.future,
      )));
      await enterCardNumber(tester, '1234');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Lookup'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Lookup'),
      );
      expect(btn.onPressed, isNull,
          reason: 'Lookup button stays disabled during loading');
      // Drain the future so the test exits cleanly.
      pending.complete(null);
      await tester.pumpAndSettle();
    });
  });

  group('EdenGiftCardBalanceLookup — PCI constraint', () {
    test('source file contains EdenSecretClipboardMode.classified', () {
      final src = File(
        'lib/src/widgets/eden_gift_card_balance_lookup.dart',
      ).readAsStringSync();
      expect(
        src.contains('EdenSecretClipboardMode.classified'),
        isTrue,
        reason:
            'Gift-card # entry MUST go through the classified clipboard-mode of EdenSecretField',
      );
    });

    test('source file does not contain card_number / cvv / pan tokens', () {
      final src = File(
        'lib/src/widgets/eden_gift_card_balance_lookup.dart',
      ).readAsStringSync();
      // Word-bounded — 'pan' as a standalone token, not 'Expanded'.
      final pattern =
          RegExp(r'\b(card_number|cvv|pan)\b', caseSensitive: false);
      expect(
        pattern.hasMatch(src),
        isFalse,
        reason:
            'Hand-rolled card-handling tokens forbidden — PCI surface must compose EdenSecretField only',
      );
    });
  });

  group('EdenGiftCardBalanceLookup — helpers', () {
    test("defaultMask('1234567890123456') → '****-****-****-3456'", () {
      expect(
        edenGiftCardDefaultMask('1234567890123456'),
        '****-****-****-3456',
      );
    });

    test("defaultMask('12') → '****'", () {
      expect(edenGiftCardDefaultMask('12'), '****');
    });

    test("defaultMask('') → '****'", () {
      expect(edenGiftCardDefaultMask(''), '****');
    });
  });

  group('EdenGiftCardBalanceLookup — active result', () {
    testWidgets('masked card # shown (last 4 visible)', (tester) async {
      await tester.pumpWidget(wrap(EdenGiftCardBalanceLookup(
        onLookup: EdenGiftCardLookupFixtures.okLookupFn(
          EdenGiftCardLookupFixtures.activeWithActivity(),
        ),
        now: EdenGiftCardLookupFixtures.t0,
      )));
      await enterCardNumber(tester, '1234567890123456');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Lookup'));
      await tester.pumpAndSettle();
      expect(find.text('****-****-****-3456'), findsOneWidget);
    });

    testWidgets(r'balance $42.50 rendered', (tester) async {
      await tester.pumpWidget(wrap(EdenGiftCardBalanceLookup(
        onLookup: EdenGiftCardLookupFixtures.okLookupFn(
          EdenGiftCardLookupFixtures.activeWithActivity(),
        ),
        now: EdenGiftCardLookupFixtures.t0,
      )));
      await enterCardNumber(tester, '1234567890123456');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Lookup'));
      await tester.pumpAndSettle();
      expect(find.text(r'$42.50'), findsOneWidget);
    });

    testWidgets("status badge 'Active' rendered", (tester) async {
      await tester.pumpWidget(wrap(EdenGiftCardBalanceLookup(
        onLookup: EdenGiftCardLookupFixtures.okLookupFn(
          EdenGiftCardLookupFixtures.activeWithActivity(),
        ),
        now: EdenGiftCardLookupFixtures.t0,
      )));
      await enterCardNumber(tester, '1234567890123456');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Lookup'));
      await tester.pumpAndSettle();
      expect(find.text('Active'), findsOneWidget);
      expect(find.byType(EdenBadge), findsOneWidget);
    });

    testWidgets('lastUsedAt footer shown when set', (tester) async {
      await tester.pumpWidget(wrap(EdenGiftCardBalanceLookup(
        onLookup: EdenGiftCardLookupFixtures.okLookupFn(
          EdenGiftCardLookupFixtures.activeWithActivity(),
        ),
        now: EdenGiftCardLookupFixtures.t0,
      )));
      await enterCardNumber(tester, '1234567890123456');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Lookup'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Last used'), findsOneWidget);
    });

    testWidgets('3 EdenActivityFeedItem rendered for 3 recent entries',
        (tester) async {
      await tester.pumpWidget(wrap(EdenGiftCardBalanceLookup(
        onLookup: EdenGiftCardLookupFixtures.okLookupFn(
          EdenGiftCardLookupFixtures.activeWithActivity(),
        ),
        now: EdenGiftCardLookupFixtures.t0,
      )));
      await enterCardNumber(tester, '1234567890123456');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Lookup'));
      await tester.pumpAndSettle();
      expect(find.byType(EdenActivityFeedItem), findsNWidgets(3));
    });
  });

  group('EdenGiftCardBalanceLookup — deactivated / expired', () {
    testWidgets("Deactivated: 'Deactivated' badge + warning alert visible",
        (tester) async {
      await tester.pumpWidget(wrap(EdenGiftCardBalanceLookup(
        onLookup: EdenGiftCardLookupFixtures.okLookupFn(
          EdenGiftCardLookupFixtures.deactivated(),
        ),
      )));
      await enterCardNumber(tester, '4444333322221111');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Lookup'));
      await tester.pumpAndSettle();
      expect(find.text('Deactivated'), findsOneWidget);
      expect(find.byType(EdenAlert), findsOneWidget);
    });

    testWidgets("Expired: 'Expired' badge + warning alert visible",
        (tester) async {
      await tester.pumpWidget(wrap(EdenGiftCardBalanceLookup(
        onLookup: EdenGiftCardLookupFixtures.okLookupFn(
          EdenGiftCardLookupFixtures.expired(),
        ),
      )));
      await enterCardNumber(tester, '9999888877776666');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Lookup'));
      await tester.pumpAndSettle();
      expect(find.text('Expired'), findsOneWidget);
      expect(find.byType(EdenAlert), findsOneWidget);
    });

    testWidgets('balance still rendered for deactivated', (tester) async {
      // Deactivated fixture has balance 0 → render '$0.00'.
      await tester.pumpWidget(wrap(EdenGiftCardBalanceLookup(
        onLookup: EdenGiftCardLookupFixtures.okLookupFn(
          EdenGiftCardLookupFixtures.deactivated(),
        ),
      )));
      await enterCardNumber(tester, '4444333322221111');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Lookup'));
      await tester.pumpAndSettle();
      expect(find.byType(EdenCurrencyDisplay), findsOneWidget);
    });
  });

  group('EdenGiftCardBalanceLookup — notFound', () {
    testWidgets("onLookup null → 'Card not found' warning", (tester) async {
      await tester.pumpWidget(wrap(EdenGiftCardBalanceLookup(
        onLookup: EdenGiftCardLookupFixtures.notFoundLookupFn(),
      )));
      await enterCardNumber(tester, '1234');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Lookup'));
      await tester.pumpAndSettle();
      expect(find.byType(EdenAlert), findsOneWidget);
      expect(find.textContaining('Card not found'), findsOneWidget);
    });

    testWidgets('notFound: no balance, no activity rendered', (tester) async {
      await tester.pumpWidget(wrap(EdenGiftCardBalanceLookup(
        onLookup: EdenGiftCardLookupFixtures.notFoundLookupFn(),
      )));
      await enterCardNumber(tester, '1234');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Lookup'));
      await tester.pumpAndSettle();
      expect(find.byType(EdenCurrencyDisplay), findsNothing);
      expect(find.byType(EdenActivityFeedItem), findsNothing);
    });

    testWidgets('after notFound: typing re-enables Lookup', (tester) async {
      await tester.pumpWidget(wrap(EdenGiftCardBalanceLookup(
        onLookup: EdenGiftCardLookupFixtures.notFoundLookupFn(),
      )));
      await enterCardNumber(tester, '1234');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Lookup'));
      await tester.pumpAndSettle();
      // After result clears, the controller is cleared (draft empty), so
      // re-entering chars must re-enable the button.
      await enterCardNumber(tester, '5555');
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Lookup'),
      );
      expect(btn.onPressed, isNotNull);
    });
  });

  group('EdenGiftCardBalanceLookup — activity edge cases', () {
    testWidgets("renders 'No recent activity' when empty", (tester) async {
      await tester.pumpWidget(wrap(EdenGiftCardBalanceLookup(
        onLookup: EdenGiftCardLookupFixtures.okLookupFn(
          EdenGiftCardLookupFixtures.zeroBalanceActive(),
        ),
      )));
      await enterCardNumber(tester, '1111222233334444');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Lookup'));
      await tester.pumpAndSettle();
      expect(find.text('No recent activity'), findsOneWidget);
    });

    testWidgets('renders maxRecent=2 rows when activity has 5 entries',
        (tester) async {
      final now = EdenGiftCardLookupFixtures.t0;
      final five = [
        for (var i = 0; i < 5; i++)
          EdenGiftCardActivity(
            id: 'a$i',
            occurredAt: now.subtract(Duration(days: i + 1)),
            type: EdenGiftCardActivityType.redeemed,
            amountCents: -(100 + i * 50),
          ),
      ];
      await tester.pumpWidget(wrap(EdenGiftCardBalanceLookup(
        maxRecent: 2,
        now: now,
        onLookup: (_) async => EdenGiftCardBalanceResult(
          cardNumber: '5555666677778888',
          balanceCents: 10000,
          status: EdenGiftCardStatus.active,
          recentActivity: five,
        ),
      )));
      await enterCardNumber(tester, '5555666677778888');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Lookup'));
      await tester.pumpAndSettle();
      expect(find.byType(EdenActivityFeedItem), findsNWidgets(2));
    });
  });

  group('EdenGiftCardBalanceLookup — responsive (iPhone-narrow 390pt)', () {
    testWidgets('no RenderFlex overflow at 390pt with active fixture',
        (tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: EdenGiftCardBalanceLookup(
              now: EdenGiftCardLookupFixtures.t0,
              onLookup: EdenGiftCardLookupFixtures.okLookupFn(
                EdenGiftCardLookupFixtures.activeWithActivity(),
              ),
            ),
          ),
        ),
      ));
      await enterCardNumber(tester, '1234567890123456');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Lookup'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
