import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eden_ui_flutter/eden_ui.dart';

import '_fixtures/eden_client_sms_thread_fixtures.dart';

Widget wrap(Widget child, {double width = 600, double height = 600}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );

void main() {
  group('formatSmsDateSeparator', () {
    test('returns "Today" for same-day date', () {
      final now = DateTime(2026, 5, 17, 14, 30);
      expect(formatSmsDateSeparator(now, now), 'Today');
    });

    test('returns "Yesterday" for 1 day prior', () {
      final now = DateTime(2026, 5, 17, 14, 30);
      final yesterday = DateTime(2026, 5, 16, 8, 0);
      expect(formatSmsDateSeparator(yesterday, now), 'Yesterday');
    });

    test('returns formatted weekday + month + day for older', () {
      final now = DateTime(2026, 5, 17, 14, 30);
      final twoDaysAgo = DateTime(2026, 5, 15, 8, 0);
      // 2026-05-15 is a Friday
      expect(formatSmsDateSeparator(twoDaysAgo, now), 'Fri, May 15');
    });

    test('handles 23:59 yesterday as "Yesterday" at midnight today', () {
      final now = DateTime(2026, 5, 17, 0, 5);
      final yesterdayLate = DateTime(2026, 5, 16, 23, 59);
      expect(formatSmsDateSeparator(yesterdayLate, now), 'Yesterday');
    });
  });

  group('EdenClientSmsThread static rendering', () {
    testWidgets('renders 1 EdenMessageBubble for single inbound message',
        (tester) async {
      await tester.pumpWidget(wrap(EdenClientSmsThread(
        messages: EdenClientSmsThreadFixtures.singleInbound(),
        onSend: (_) {},
        nowOverride: EdenClientSmsThreadFixtures.kFixedNow,
      )));
      expect(find.byType(EdenMessageBubble), findsOneWidget);
      expect(find.text('Confirming my 3pm Thursday?'), findsOneWidget);
    });

    testWidgets('renders 2 bubbles for inbound + outbound mix',
        (tester) async {
      await tester.pumpWidget(wrap(EdenClientSmsThread(
        messages: [
          EdenSmsMessage(
            id: 'm1',
            body: 'In',
            direction: EdenSmsDirection.inbound,
            sentAt: EdenClientSmsThreadFixtures.kFixedNow,
          ),
          EdenSmsMessage(
            id: 'm2',
            body: 'Out',
            direction: EdenSmsDirection.outbound,
            sentAt: EdenClientSmsThreadFixtures.kFixedNow,
          ),
        ],
        onSend: (_) {},
        nowOverride: EdenClientSmsThreadFixtures.kFixedNow,
      )));
      expect(find.byType(EdenMessageBubble), findsNWidgets(2));
    });

    testWidgets('empty messages renders "No messages yet"', (tester) async {
      await tester.pumpWidget(wrap(EdenClientSmsThread(
        messages: const [],
        onSend: (_) {},
        nowOverride: EdenClientSmsThreadFixtures.kFixedNow,
      )));
      expect(find.text('No messages yet'), findsOneWidget);
    });
  });

  group('EdenClientSmsThread delivery-status icons', () {
    testWidgets('outbound sent → Icon(Icons.check)', (tester) async {
      await tester.pumpWidget(wrap(EdenClientSmsThread(
        messages: EdenClientSmsThreadFixtures.singleOutboundSent(),
        onSend: (_) {},
        nowOverride: EdenClientSmsThreadFixtures.kFixedNow,
      )));
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('outbound delivered → Icon(Icons.done_all)', (tester) async {
      await tester.pumpWidget(wrap(EdenClientSmsThread(
        messages: EdenClientSmsThreadFixtures.singleOutboundDelivered(),
        onSend: (_) {},
        nowOverride: EdenClientSmsThreadFixtures.kFixedNow,
      )));
      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });

    testWidgets('outbound failed → Icon(Icons.error_outline)',
        (tester) async {
      await tester.pumpWidget(wrap(EdenClientSmsThread(
        messages: EdenClientSmsThreadFixtures.singleOutboundFailed(),
        onSend: (_) {},
        nowOverride: EdenClientSmsThreadFixtures.kFixedNow,
      )));
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('inbound message → no delivery-status icon', (tester) async {
      await tester.pumpWidget(wrap(EdenClientSmsThread(
        messages: EdenClientSmsThreadFixtures.singleInbound(),
        onSend: (_) {},
        nowOverride: EdenClientSmsThreadFixtures.kFixedNow,
      )));
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byIcon(Icons.done_all), findsNothing);
    });
  });

  group('EdenClientSmsThread media thumbnails', () {
    testWidgets('1 mediaUrl renders 1 Image widget', (tester) async {
      await tester.pumpWidget(wrap(EdenClientSmsThread(
        messages: EdenClientSmsThreadFixtures.withMedia(),
        onSend: (_) {},
        nowOverride: EdenClientSmsThreadFixtures.kFixedNow,
      )));
      expect(find.byType(Image), findsAtLeastNWidgets(1));
    });

    testWidgets('empty mediaUrls renders no media Image', (tester) async {
      await tester.pumpWidget(wrap(EdenClientSmsThread(
        messages: EdenClientSmsThreadFixtures.singleInbound(),
        onSend: (_) {},
        nowOverride: EdenClientSmsThreadFixtures.kFixedNow,
      )));
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('tap on thumbnail fires onMediaTap', (tester) async {
      String? tappedUrl;
      await tester.pumpWidget(wrap(EdenClientSmsThread(
        messages: EdenClientSmsThreadFixtures.withMedia(),
        onSend: (_) {},
        onMediaTap: (url) => tappedUrl = url,
        nowOverride: EdenClientSmsThreadFixtures.kFixedNow,
      )));
      await tester.tap(find.byType(Image).first, warnIfMissed: false);
      expect(tappedUrl, 'https://example.com/photo.jpg');
    });
  });

  group('EdenClientSmsThread date separators', () {
    testWidgets('3 messages across 3 days → 3 separators', (tester) async {
      await tester.pumpWidget(wrap(EdenClientSmsThread(
        messages: EdenClientSmsThreadFixtures.threeSpanningDays(),
        onSend: (_) {},
        nowOverride: EdenClientSmsThreadFixtures.kFixedNow,
      )));
      // 3 distinct dates: Today + Yesterday + Thu, May 14
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('Thu, May 14'), findsOneWidget);
    });

    testWidgets('2 same-day messages → 1 separator', (tester) async {
      await tester.pumpWidget(wrap(EdenClientSmsThread(
        messages: EdenClientSmsThreadFixtures.twoSameDay(),
        onSend: (_) {},
        nowOverride: EdenClientSmsThreadFixtures.kFixedNow,
      )));
      expect(find.text('Today'), findsOneWidget);
    });
  });

  group('EdenClientSmsThread send callback', () {
    testWidgets('input "Hello" + send fires onSend with draft',
        (tester) async {
      EdenSmsDraft? captured;
      await tester.pumpWidget(wrap(EdenClientSmsThread(
        messages: EdenClientSmsThreadFixtures.singleInbound(),
        onSend: (d) => captured = d,
        nowOverride: EdenClientSmsThreadFixtures.kFixedNow,
      )));
      // Find the input field — EdenMessageInput wraps a TextField.
      await tester.enterText(find.byType(TextField), 'Hello');
      // Submit via send icon
      final sendIcon = find.byIcon(Icons.send);
      expect(sendIcon, findsOneWidget);
      await tester.tap(sendIcon);
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!.body, 'Hello');
      expect(captured!.mediaUrls, isEmpty);
    });
  });

  group('EdenClientSmsThread auto-scroll', () {
    testWidgets('grows scroll offset when message appended', (tester) async {
      List<EdenSmsMessage> msgs = [
        for (var i = 0; i < 12; i++)
          EdenSmsMessage(
            id: 'm$i',
            body: 'Msg $i ${'x' * 30}',
            direction: EdenSmsDirection.inbound,
            sentAt: EdenClientSmsThreadFixtures.kFixedNow,
          ),
      ];

      Widget build(List<EdenSmsMessage> messages) => wrap(
            EdenClientSmsThread(
              messages: messages,
              onSend: (_) {},
              nowOverride: EdenClientSmsThreadFixtures.kFixedNow,
            ),
            width: 400,
            height: 400,
          );

      await tester.pumpWidget(build(msgs));
      await tester.pumpAndSettle();

      msgs = [
        ...msgs,
        EdenSmsMessage(
          id: 'new',
          body: 'New one ${'y' * 30}',
          direction: EdenSmsDirection.inbound,
          sentAt: EdenClientSmsThreadFixtures.kFixedNow,
        ),
      ];
      await tester.pumpWidget(build(msgs));
      await tester.pumpAndSettle();
      // Verify scroll controller reaches max scroll extent.
      final state = tester.state<State<EdenClientSmsThread>>(
          find.byType(EdenClientSmsThread)) as dynamic;
      final ctrl = state.scrollController as ScrollController;
      expect(ctrl.hasClients, isTrue);
      expect(ctrl.offset, closeTo(ctrl.position.maxScrollExtent, 1.0));
    });

    testWidgets('does NOT auto-scroll when messages shrink', (tester) async {
      List<EdenSmsMessage> msgs = [
        for (var i = 0; i < 12; i++)
          EdenSmsMessage(
            id: 'm$i',
            body: 'Msg $i',
            direction: EdenSmsDirection.inbound,
            sentAt: EdenClientSmsThreadFixtures.kFixedNow,
          ),
      ];

      Widget build(List<EdenSmsMessage> messages) => wrap(
            EdenClientSmsThread(
              messages: messages,
              onSend: (_) {},
              nowOverride: EdenClientSmsThreadFixtures.kFixedNow,
            ),
            width: 400,
            height: 400,
          );

      await tester.pumpWidget(build(msgs));
      await tester.pumpAndSettle();

      // Shrink list
      final shorter = msgs.sublist(0, 5);
      await tester.pumpWidget(build(shorter));
      await tester.pumpAndSettle();
      // No exception thrown; scroll did not need to animate.
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenClientSmsThread iPhone-narrow (390pt)', () {
    testWidgets('8 messages render without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 800,
            child: EdenClientSmsThread(
              messages: EdenClientSmsThreadFixtures.salonStarterThread(),
              onSend: (_) {},
              nowOverride: EdenClientSmsThreadFixtures.kFixedNow,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(EdenMessageBubble), findsAtLeastNWidgets(1));
    });
  });
}
