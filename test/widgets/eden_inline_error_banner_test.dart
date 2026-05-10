import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: child));

  group('EdenInlineErrorBanner', () {
    testWidgets('renders the message', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInlineErrorBanner(message: 'send failed'),
      ));
      expect(find.text('send failed'), findsOneWidget);
    });

    testWidgets('renders default warning icon', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInlineErrorBanner(message: 'oops'),
      ));
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('renders custom icon when provided', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInlineErrorBanner(
          message: 'offline',
          icon: Icons.wifi_off,
        ),
      ));
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('hides dismiss button when onDismiss is null',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInlineErrorBanner(message: 'no dismiss'),
      ));
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('shows dismiss icon and fires callback when tapped',
        (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(wrap(
        EdenInlineErrorBanner(
          message: 'tap to dismiss',
          onDismiss: () => dismissed++,
        ),
      ));

      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(dismissed, 1);
    });
  });
}
