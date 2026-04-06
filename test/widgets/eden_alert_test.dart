import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenAlert', () {
    testWidgets('renders message text', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenAlert(message: 'Something happened'),
      ));
      expect(find.text('Something happened'), findsOneWidget);
    });

    testWidgets('renders with each variant without error', (tester) async {
      for (final variant in EdenAlertVariant.values) {
        await tester.pumpWidget(wrap(
          EdenAlert(message: 'Test', variant: variant),
        ));
        expect(find.text('Test'), findsOneWidget);
      }
    });

    testWidgets('shows dismiss button when dismissible=true', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenAlert(message: 'Dismiss me', dismissible: true),
      ));
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('calls onDismiss when dismiss button tapped', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(wrap(
        EdenAlert(
          message: 'Dismiss me',
          dismissible: true,
          onDismiss: () => dismissed = true,
        ),
      ));
      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, true);
    });

    testWidgets('hides dismiss button when dismissible=false', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenAlert(message: 'No dismiss'),
      ));
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });
}
