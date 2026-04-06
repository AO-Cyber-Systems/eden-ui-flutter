import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenCard', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCard(child: Text('Card content')),
      ));
      expect(find.text('Card content'), findsOneWidget);
    });

    testWidgets('renders title and subtitle text', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCard(title: 'Card Title', subtitle: 'Card Subtitle'),
      ));
      expect(find.text('Card Title'), findsOneWidget);
      expect(find.text('Card Subtitle'), findsOneWidget);
    });

    testWidgets('onTap callback fires when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        EdenCard(title: 'Tappable', onTap: () => tapped = true),
      ));
      await tester.tap(find.text('Tappable'));
      expect(tapped, true);
    });

    testWidgets('horizontal layout renders without error', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCard(title: 'Horizontal', horizontal: true),
      ));
      expect(find.text('Horizontal'), findsOneWidget);
    });

    testWidgets('gradient and glass variants render without error',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCard(title: 'Gradient', gradient: true),
      ));
      expect(find.text('Gradient'), findsOneWidget);

      await tester.pumpWidget(wrap(
        const EdenCard(title: 'Glass', glass: true),
      ));
      expect(find.text('Glass'), findsOneWidget);
    });
  });
}
