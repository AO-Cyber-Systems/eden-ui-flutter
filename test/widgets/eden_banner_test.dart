import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenBanner', () {
    testWidgets('renders message text', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenBanner(message: 'Important notice'),
      ));
      expect(find.text('Important notice'), findsOneWidget);
    });

    testWidgets('renders with each variant without error', (tester) async {
      for (final variant in EdenBannerVariant.values) {
        await tester.pumpWidget(wrap(
          EdenBanner(message: 'Test', variant: variant),
        ));
        expect(find.text('Test'), findsOneWidget);
      }
    });

    testWidgets('shows dismiss button and calls onDismiss', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(wrap(
        EdenBanner(
          message: 'Dismiss me',
          dismissible: true,
          onDismiss: () => dismissed = true,
        ),
      ));
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, true);
    });

    testWidgets('shows action button and calls onAction', (tester) async {
      var actionCalled = false;
      await tester.pumpWidget(wrap(
        EdenBanner(
          message: 'Action banner',
          actionLabel: 'Learn More',
          onAction: () => actionCalled = true,
        ),
      ));
      expect(find.text('Learn More'), findsOneWidget);

      await tester.tap(find.text('Learn More'));
      expect(actionCalled, true);
    });
  });
}
