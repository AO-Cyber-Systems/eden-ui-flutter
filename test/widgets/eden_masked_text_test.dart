import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('EdenMaskedText', () {
    testWidgets('renders default mask for long secret', (tester) async {
      const secret = 'aoc_live_abcdefghijklmnopqrstuvwxyz';
      await tester.pumpWidget(wrap(const EdenMaskedText(text: secret)));

      // Default mask: first 4 + 8 stars + last 4
      expect(find.text('aoc_********wxyz'), findsOneWidget);
      // Original text not visible by default
      expect(find.text(secret), findsNothing);
    });

    testWidgets('renders 4-star mask for short secret', (tester) async {
      await tester.pumpWidget(wrap(const EdenMaskedText(text: 'short')));
      expect(find.text('****'), findsOneWidget);
    });

    testWidgets('renders custom maskedText override', (tester) async {
      await tester.pumpWidget(wrap(const EdenMaskedText(
        text: 'aoc_secret',
        maskedText: '***hidden***',
      )));
      expect(find.text('***hidden***'), findsOneWidget);
    });

    testWidgets('reveal toggle swaps mask and full text', (tester) async {
      const secret = 'aoc_live_abcdefghijklmnopqrstuvwxyz';
      await tester.pumpWidget(wrap(const EdenMaskedText(text: secret)));

      expect(find.byIcon(Icons.visibility), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      expect(find.text(secret), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();
      expect(find.text(secret), findsNothing);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('renders copy icon when copyable=true (default)',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenMaskedText(text: 'secret123')));
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('omits copy icon when copyable=false', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenMaskedText(text: 'secret123', copyable: false),
      ));
      expect(find.byIcon(Icons.copy), findsNothing);
    });
  });
}
