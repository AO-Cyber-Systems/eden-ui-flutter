import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_agent_chat_fixtures.dart';

void main() {
  setUp(EdenAgentChatFixtures.resetCallCounters);

  Widget mountChat({
    EdenAiPersona persona = EdenAiPersona.operations,
    void Function(EdenAiPersona)? onPersonaChanged,
    EdenChatStreamSender? sendMessage,
    EdenChatConversationCreator? createConversation,
    String pageContext = 'Test page',
    String? entityLabel,
    bool isOnline = true,
    String? offlineMessage,
    Widget? proposalCard,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: EdenAgentChat(
          activePersona: persona,
          onPersonaChanged: onPersonaChanged ?? (_) {},
          sendMessage: sendMessage ?? EdenAgentChatFixtures.noopStreamSender,
          createConversation:
              createConversation ?? EdenAgentChatFixtures.noopCreator,
          pageContext: pageContext,
          entityLabel: entityLabel,
          isOnline: isOnline,
          offlineMessage:
              offlineMessage ?? 'AI unavailable — showing offline state',
          proposalCard: proposalCard,
        ),
      ),
    );
  }

  group('EdenAgentChatFab', () {
    testWidgets('FAB opens the EdenAgentChat sheet on tap',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          floatingActionButton: EdenAgentChatFab(
            activePersona: EdenAiPersona.operations,
            onPersonaChanged: (_) {},
            sendMessage: EdenAgentChatFixtures.noopStreamSender,
            createConversation: EdenAgentChatFixtures.noopCreator,
            pageContext: 'Test page',
          ),
        ),
      ));
      expect(find.byType(EdenAgentChat), findsNothing);
      await tester.tap(find.byType(EdenAgentChatFab));
      await tester.pumpAndSettle();
      expect(find.byType(EdenAgentChat), findsOneWidget);
    });
  });

  group('EdenAgentChat — structure', () {
    testWidgets("renders sparkle + 'AI Assistant' + persona selector + close button",
        (tester) async {
      await tester.pumpWidget(mountChat());
      expect(find.text('AI Assistant'), findsOneWidget);
      expect(find.byType(EdenPersonaSelector), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('greeting message renders persona displayLabel',
        (tester) async {
      await tester.pumpWidget(mountChat(persona: EdenAiPersona.finance));
      expect(
        find.textContaining("Hi! I'm your Finance assistant. How can I help?"),
        findsOneWidget,
      );
    });
  });

  group('EdenAgentChat — offline banner', () {
    testWidgets("offline shows offlineMessage with cloud_off icon",
        (tester) async {
      await tester.pumpWidget(mountChat(
        isOnline: false,
        offlineMessage: 'AODex unavailable — mock responses',
      ));
      expect(find.text('AODex unavailable — mock responses'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('online state hides the banner',
        (tester) async {
      await tester.pumpWidget(mountChat());
      expect(find.byIcon(Icons.cloud_off), findsNothing);
    });
  });

  group('EdenAgentChat — entity context chip', () {
    testWidgets("entityLabel non-null renders 'Viewing: ...' chip",
        (tester) async {
      await tester.pumpWidget(mountChat(entityLabel: 'Customer #42'));
      expect(find.text('Viewing: Customer #42'), findsOneWidget);
    });

    testWidgets('entityLabel null hides chip',
        (tester) async {
      await tester.pumpWidget(mountChat());
      expect(find.textContaining('Viewing:'), findsNothing);
    });
  });

  group('EdenAgentChat — proposal slot', () {
    testWidgets('proposalCard non-null renders above the input',
        (tester) async {
      await tester.pumpWidget(mountChat(
        proposalCard: const Card(
          key: ValueKey('test-proposal-card'),
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Text('Switch persona?'),
          ),
        ),
      ));
      expect(find.byKey(const ValueKey('test-proposal-card')), findsOneWidget);
      expect(find.text('Switch persona?'), findsOneWidget);
    });

    testWidgets('proposalCard null → no proposal widget',
        (tester) async {
      await tester.pumpWidget(mountChat());
      expect(find.byKey(const ValueKey('test-proposal-card')), findsNothing);
    });
  });

  group('EdenAgentChat — send happy path', () {
    testWidgets(
        'send fires createConversation (once) + sendMessage; bubble accumulates',
        (tester) async {
      EdenChatRequest? capturedRequest;
      Stream<EdenChatStreamChunk> sender(EdenChatRequest req) {
        capturedRequest = req;
        return EdenAgentChatFixtures.happyPathStreamSender(req);
      }

      await tester.pumpWidget(mountChat(sendMessage: sender));
      await tester.enterText(find.byType(TextField), 'Hi there');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // createConversation invoked exactly once.
      expect(EdenAgentChatFixtures.createConversationCallCount, 1);
      // sendMessage was given the captured conv id + content.
      expect(capturedRequest?.conversationId, 'conv-test-1');
      expect(capturedRequest?.content, 'Hi there');
      // User bubble + accumulated assistant bubble visible.
      expect(find.text('Hi there'), findsOneWidget);
      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('second send REUSES the conversation id (lazy creation)',
        (tester) async {
      await tester.pumpWidget(mountChat(
        sendMessage: EdenAgentChatFixtures.happyPathStreamSender,
      ));
      await tester.enterText(find.byType(TextField), 'first');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'second');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      expect(EdenAgentChatFixtures.createConversationCallCount, 1);
    });
  });

  group('EdenAgentChat — send error path', () {
    testWidgets(
        'error appends [Error: connection interrupted] to accumulated text',
        (tester) async {
      await tester.pumpWidget(mountChat(
        sendMessage: EdenAgentChatFixtures.errorStreamSender,
      ));
      await tester.enterText(find.byType(TextField), 'q');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      expect(
        find.text('Hello\n\n[Error: connection interrupted]'),
        findsOneWidget,
      );
    });
  });

  group('EdenAgentChat — send guards', () {
    testWidgets('empty input → no createConversation, no sendMessage',
        (tester) async {
      var sendCount = 0;
      Stream<EdenChatStreamChunk> sender(EdenChatRequest req) {
        sendCount += 1;
        return const Stream<EdenChatStreamChunk>.empty();
      }

      await tester.pumpWidget(mountChat(sendMessage: sender));
      // Empty text; tap send.
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      expect(EdenAgentChatFixtures.createConversationCallCount, 0);
      expect(sendCount, 0);
    });
  });

  group('EdenAgentChat — persona switch', () {
    testWidgets(
        'tapping persona selector dropdown item fires onPersonaChanged',
        (tester) async {
      EdenAiPersona? lastPersona;
      await tester.pumpWidget(mountChat(
        onPersonaChanged: (p) => lastPersona = p,
      ));
      await tester.tap(find.byType(EdenPersonaSelector));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finance').last);
      await tester.pumpAndSettle();
      expect(lastPersona, EdenAiPersona.finance);
    });
  });

  group('EdenAgentChat — close button', () {
    testWidgets('tapping close button pops the route',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          floatingActionButton: EdenAgentChatFab(
            activePersona: EdenAiPersona.operations,
            onPersonaChanged: (_) {},
            sendMessage: EdenAgentChatFixtures.noopStreamSender,
            createConversation: EdenAgentChatFixtures.noopCreator,
            pageContext: 'Test',
          ),
        ),
      ));
      await tester.tap(find.byType(EdenAgentChatFab));
      await tester.pumpAndSettle();
      expect(find.byType(EdenAgentChat), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(EdenAgentChat), findsNothing);
    });
  });

  group('EdenAgentChat — iPhone-narrow safety', () {
    testWidgets('renders at 390pt without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3.0, 800 * 3.0);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(mountChat(
        entityLabel: 'Customer #42',
        isOnline: false,
        offlineMessage: 'AI unavailable',
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
