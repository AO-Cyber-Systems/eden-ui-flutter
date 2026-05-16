import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_mobile_ai_fab_fixtures.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

EdenMobileAiFab _fab({
  Color? accentColor,
  int unreadCount = 0,
  EdenAiPersona activePersona = EdenAiPersona.fieldTech,
  List<EdenMobileAiQuickAction>? quickActions,
  String? entityLabel,
  String? entityType,
  String? entityId,
  String pageContext = 'mobile_home',
  ValueChanged<EdenAiPersona>? onPersonaChanged,
  EdenChatStreamSender? sendMessage,
  EdenChatConversationCreator? createConversation,
  Object heroTag = 'eden_mobile_ai_fab',
}) {
  return EdenMobileAiFab(
    pageContext: pageContext,
    entityType: entityType,
    entityId: entityId,
    entityLabel: entityLabel,
    activePersona: activePersona,
    onPersonaChanged: onPersonaChanged ?? (_) {},
    sendMessage: sendMessage ?? EdenMobileAiFabFixtures.inertSender(),
    createConversation:
        createConversation ?? EdenMobileAiFabFixtures.inertCreator(),
    quickActions: quickActions ?? EdenMobileAiFabFixtures.empty(),
    unreadCount: unreadCount,
    accentColor: accentColor ?? const Color(0xFFD4A853),
    heroTag: heroTag,
  );
}

void main() {
  group('EdenMobileAiFab — composition', () {
    testWidgets('renders FloatingActionButton + sparkle icon',
        (tester) async {
      await tester.pumpWidget(wrap(_fab()));
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('default accentColor is gold (0xFFD4A853)', (tester) async {
      await tester.pumpWidget(wrap(_fab()));
      final fab = tester.widget<FloatingActionButton>(
          find.byType(FloatingActionButton));
      expect(fab.backgroundColor, const Color(0xFFD4A853));
    });

    testWidgets('accentColor override is honored', (tester) async {
      await tester
          .pumpWidget(wrap(_fab(accentColor: const Color(0xFF00AA00))));
      final fab = tester.widget<FloatingActionButton>(
          find.byType(FloatingActionButton));
      expect(fab.backgroundColor, const Color(0xFF00AA00));
    });
  });

  group('EdenMobileAiFab — badge', () {
    testWidgets('unreadCount: 0 — no badge text', (tester) async {
      await tester.pumpWidget(wrap(_fab()));
      // No badge text rendered.
      expect(find.text('1'), findsNothing);
      expect(find.text('9+'), findsNothing);
    });

    testWidgets('unreadCount: 1 — badge text "1"', (tester) async {
      await tester.pumpWidget(wrap(_fab(unreadCount: 1)));
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('unreadCount: 5 — badge text "5"', (tester) async {
      await tester.pumpWidget(wrap(_fab(unreadCount: 5)));
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('unreadCount: 10 — badge text "9+"', (tester) async {
      await tester.pumpWidget(wrap(_fab(unreadCount: 10)));
      expect(find.text('9+'), findsOneWidget);
    });

    testWidgets('unreadCount: 99 — badge text "9+"', (tester) async {
      await tester.pumpWidget(wrap(_fab(unreadCount: 99)));
      expect(find.text('9+'), findsOneWidget);
    });
  });

  group('EdenMobileAiFab — tap opens sheet', () {
    testWidgets('tap on FAB opens an EdenMobileAiChatSheet', (tester) async {
      await tester.pumpWidget(wrap(_fab(
        entityLabel: 'Smith Job — 9:00 AM',
        quickActions: EdenMobileAiFabFixtures.tradesQuickActions(),
      )));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.byType(EdenMobileAiChatSheet), findsOneWidget);

      final sheet =
          tester.widget<EdenMobileAiChatSheet>(find.byType(EdenMobileAiChatSheet));
      expect(sheet.pageContext, 'mobile_home');
      expect(sheet.entityLabel, 'Smith Job — 9:00 AM');
      expect(sheet.activePersona, EdenAiPersona.fieldTech);
      expect(sheet.quickActions.length, 3);
    });
  });
}
