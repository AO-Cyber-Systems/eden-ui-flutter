import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_mobile_ai_fab_fixtures.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Helper that opens the chat sheet via `showModalBottomSheet` so tests
/// exercise the real modal-mount path.
Future<void> openSheet(
  WidgetTester tester, {
  EdenAiPersona activePersona = EdenAiPersona.fieldTech,
  List<EdenMobileAiQuickAction>? quickActions,
  String? entityLabel,
  String? entityLabelPrefix,
  String pageContext = 'mobile_home',
  ValueChanged<EdenAiPersona>? onPersonaChanged,
  EdenChatStreamSender? sendMessage,
  EdenChatConversationCreator? createConversation,
  Color? accentColor,
  String? greeting,
}) async {
  await tester.pumpWidget(wrap(Builder(builder: (ctx) {
    return ElevatedButton(
      onPressed: () => showModalBottomSheet<void>(
        context: ctx,
        isScrollControlled: true,
        builder: (_) => EdenMobileAiChatSheet(
          pageContext: pageContext,
          entityLabel: entityLabel,
          entityLabelPrefix: entityLabelPrefix ?? 'Working on',
          activePersona: activePersona,
          onPersonaChanged: onPersonaChanged ?? (_) {},
          sendMessage: sendMessage ?? EdenMobileAiFabFixtures.inertSender(),
          createConversation:
              createConversation ?? EdenMobileAiFabFixtures.inertCreator(),
          quickActions: quickActions ?? EdenMobileAiFabFixtures.empty(),
          accentColor: accentColor ?? const Color(0xFFD4A853),
          greeting: greeting,
        ),
      ),
      child: const Text('Open'),
    );
  })));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  group('EdenMobileAiChatSheet — composition smoke', () {
    testWidgets('renders drag handle, AI Assistant title, sparkle, close',
        (tester) async {
      await openSheet(tester);
      expect(find.byType(EdenMobileAiChatSheet), findsOneWidget);
      // Drag handle (a Container with a known key).
      expect(find.byKey(const ValueKey('eden_mobile_ai_chat_sheet_drag_handle')),
          findsOneWidget);
      expect(find.text('AI Assistant'), findsOneWidget);
      // Sparkle icon (header) - at least one, may co-exist with input send icon.
      expect(find.byIcon(Icons.auto_awesome), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });

  group('EdenMobileAiChatSheet — entity chip', () {
    testWidgets('entityLabel non-null renders "Working on: $entityLabel"',
        (tester) async {
      await openSheet(tester, entityLabel: 'Smith Job — 9:00 AM');
      expect(find.text('Working on: Smith Job — 9:00 AM'), findsOneWidget);
    });

    testWidgets('entityLabel null hides the chip', (tester) async {
      await openSheet(tester);
      expect(find.textContaining('Working on'), findsNothing);
    });

    testWidgets('entityLabelPrefix override renders custom prefix',
        (tester) async {
      await openSheet(tester,
          entityLabel: 'Order #42', entityLabelPrefix: 'Tracking');
      expect(find.text('Tracking: Order #42'), findsOneWidget);
    });
  });

  group('EdenMobileAiChatSheet — persona badge', () {
    testWidgets('renders the active persona display label', (tester) async {
      await openSheet(tester, activePersona: EdenAiPersona.finance);
      expect(find.text(EdenAiPersona.finance.displayLabel),
          findsOneWidget);
    });
  });

  group('EdenMobileAiChatSheet — quick actions', () {
    testWidgets('renders one ActionChip per quick action', (tester) async {
      await openSheet(tester,
          quickActions: EdenMobileAiFabFixtures.tradesQuickActions());
      expect(find.byType(ActionChip), findsNWidgets(3));
      expect(find.text('Find Parts'), findsOneWidget);
      expect(find.text('Equipment Info'), findsOneWidget);
      expect(find.text('Report Issue'), findsOneWidget);
    });

    testWidgets(
        'tap on first quick action fires sendMessage with the label as content',
        (tester) async {
      final (captured, sender) = EdenMobileAiFabFixtures.recorder();
      await openSheet(tester,
          quickActions: EdenMobileAiFabFixtures.tradesQuickActions(),
          sendMessage: sender);
      await tester.tap(find.text('Find Parts'));
      await tester.pumpAndSettle();
      expect(captured, isNotEmpty);
      expect(captured.first.content, 'Find Parts');
    });
  });

  group('EdenMobileAiChatSheet — close', () {
    testWidgets('tap close button dismisses the sheet', (tester) async {
      await openSheet(tester);
      expect(find.byType(EdenMobileAiChatSheet), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(EdenMobileAiChatSheet), findsNothing);
    });
  });

  group('EdenMobileAiChatSheet — initial greeting', () {
    testWidgets('default greeting renders an assistant message',
        (tester) async {
      await openSheet(tester, activePersona: EdenAiPersona.fieldTech);
      // Greeting contains the persona display label.
      expect(
          find.textContaining(EdenAiPersona.fieldTech.displayLabel),
          findsAtLeastNWidgets(1));
    });

    testWidgets('explicit empty greeting renders no initial assistant message',
        (tester) async {
      await openSheet(tester,
          activePersona: EdenAiPersona.fieldTech, greeting: '');
      // We assert the EdenChatMessageBubble count is 0 by looking
      // at the inner ListView body — but to keep this resilient we just
      // confirm that no greeting-shaped text is rendered.
      // (The persona display label still appears in the header badge.)
      // So we check there's exactly one occurrence of the label (the badge),
      // not two (badge + greeting).
      final count = find
          .text(EdenAiPersona.fieldTech.displayLabel)
          .evaluate()
          .length;
      expect(count, 1);
    });
  });

  group('EdenMobileAiChatSheet — iPhone-narrow ≥390pt', () {
    testWidgets('renders at 390x800 without overflow (default size)',
        (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await openSheet(tester,
          entityLabel: 'Smith Job — 9:00 AM',
          quickActions: EdenMobileAiFabFixtures.tradesQuickActions());
      expect(find.byType(EdenMobileAiChatSheet), findsOneWidget);
      expect(find.text('AI Assistant'), findsOneWidget);
    });

    testWidgets(
        'renders with longest available persona label without header overflow',
        (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // Find the longest available persona label.
      final longestPersona = EdenAiPersona.values.reduce((a, b) =>
          a.displayLabel.length >= b.displayLabel.length ? a : b);
      await openSheet(tester, activePersona: longestPersona);
      expect(find.byType(EdenMobileAiChatSheet), findsOneWidget);
    });
  });
}
