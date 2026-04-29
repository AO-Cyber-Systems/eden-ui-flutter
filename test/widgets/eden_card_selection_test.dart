import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenCard text selection', () {
    testWidgets('title text is selectable via SelectableText', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCard(title: 'Test Title'),
      ));
      await tester.pump();

      // SelectableText must be present in the tree for the title
      final selectableTexts = tester
          .widgetList<SelectableText>(find.byType(SelectableText))
          .where((w) => w.data == 'Test Title')
          .toList();

      expect(
        selectableTexts,
        isNotEmpty,
        reason:
            'EdenCard title must be rendered with SelectableText so users '
            'can select and copy the text on Flutter web.',
      );
    });

    testWidgets('subtitle text is selectable via SelectableText',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCard(title: 'Card Title', subtitle: 'Test Subtitle'),
      ));
      await tester.pump();

      final selectableTexts = tester
          .widgetList<SelectableText>(find.byType(SelectableText))
          .where((w) => w.data == 'Test Subtitle')
          .toList();

      expect(
        selectableTexts,
        isNotEmpty,
        reason:
            'EdenCard subtitle must be rendered with SelectableText so users '
            'can select and copy the text on Flutter web.',
      );
    });
  });
}
