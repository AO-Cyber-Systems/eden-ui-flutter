import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  EdenChatMessage userMessage(String content) => EdenChatMessage(
        id: 'u',
        role: EdenChatRole.user,
        content: content,
        timestamp: DateTime(2026, 5, 15),
      );

  EdenChatMessage assistantMessage(String content) => EdenChatMessage(
        id: 'a',
        role: EdenChatRole.assistant,
        content: content,
        timestamp: DateTime(2026, 5, 15, 0, 1),
      );

  group('EdenChatMessageBubble', () {
    testWidgets('user message: right-aligned + primary background + onPrimary text',
        (tester) async {
      final theme = ThemeData.light();
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
          body: EdenChatMessageBubble(message: userMessage('Hello')),
        ),
      ));
      // Right-aligned Align widget.
      final align = tester.widget<Align>(find.byType(Align));
      expect(align.alignment, Alignment.centerRight);
      // Primary background.
      final container = tester.widget<Container>(find.descendant(
        of: find.byType(EdenChatMessageBubble),
        matching: find.byType(Container),
      ));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, theme.colorScheme.primary);
      // onPrimary text.
      final text = tester.widget<Text>(find.text('Hello'));
      expect(text.style?.color, theme.colorScheme.onPrimary);
    });

    testWidgets(
        'assistant message: left-aligned + surfaceContainerHighest + onSurface text',
        (tester) async {
      final theme = ThemeData.light();
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
          body:
              EdenChatMessageBubble(message: assistantMessage('How can I help?')),
        ),
      ));
      final align = tester.widget<Align>(find.byType(Align));
      expect(align.alignment, Alignment.centerLeft);
      final container = tester.widget<Container>(find.descendant(
        of: find.byType(EdenChatMessageBubble),
        matching: find.byType(Container),
      ));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, theme.colorScheme.surfaceContainerHighest);
      final text = tester.widget<Text>(find.text('How can I help?'));
      expect(text.style?.color, theme.colorScheme.onSurface);
    });

    testWidgets('long content (200 chars) respects maxWidth=280',
        (tester) async {
      final longContent =
          'A really long assistant response that should wrap inside the bubble '
          'rather than overflow its 280-pixel maxWidth ' * 2;
      await tester.pumpWidget(wrap(
        EdenChatMessageBubble(message: assistantMessage(longContent)),
      ));
      final container = tester.widget<Container>(find.descendant(
        of: find.byType(EdenChatMessageBubble),
        matching: find.byType(Container),
      ));
      expect(container.constraints?.maxWidth, 280);
      expect(tester.takeException(), isNull);
    });
  });
}
