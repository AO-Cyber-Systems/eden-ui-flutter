import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EdenToast', () {
    testWidgets('shows message text', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => EdenToast.show(context, message: 'Success!'),
              child: const Text('Toast'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Toast'));
      await tester.pump(); // one pump for SnackBar to appear

      expect(find.text('Success!'), findsOneWidget);
    });

    testWidgets('shows with each variant', (tester) async {
      for (final variant in EdenToastVariant.values) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => EdenToast.show(
                  context,
                  message: 'Msg',
                  variant: variant,
                ),
                child: const Text('Toast'),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Toast'));
        await tester.pump();

        expect(find.text('Msg'), findsOneWidget);
      }
    });

    testWidgets('shows action button when actionLabel provided',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => EdenToast.show(
                context,
                message: 'Undo?',
                actionLabel: 'UNDO',
                onAction: () {},
              ),
              child: const Text('Toast'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Toast'));
      await tester.pump();

      expect(find.text('UNDO'), findsOneWidget);
    });

    testWidgets('calls onAction when action tapped', (tester) async {
      var actionCalled = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => EdenToast.show(
                context,
                message: 'Action?',
                actionLabel: 'DO IT',
                onAction: () => actionCalled = true,
              ),
              child: const Text('Toast'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Toast'));
      await tester.pumpAndSettle();

      // SnackBarAction renders as a TextButton — tap it directly
      await tester.tap(find.widgetWithText(TextButton, 'DO IT'));
      await tester.pumpAndSettle();
      expect(actionCalled, true);
    });
  });
}
