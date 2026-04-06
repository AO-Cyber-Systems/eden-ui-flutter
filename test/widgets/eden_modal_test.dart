import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EdenModal', () {
    testWidgets('shows title and child content', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => EdenModal.show(
                context,
                child: const Text('Modal Body'),
                title: 'Test Modal',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Test Modal'), findsOneWidget);
      expect(find.text('Modal Body'), findsOneWidget);
    });

    testWidgets('dismisses when close icon tapped', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => EdenModal.show(
                context,
                child: const Text('Content'),
                title: 'Dismiss Me',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Dismiss Me'), findsOneWidget);

      // Tap the close icon
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Dismiss Me'), findsNothing);
    });

    testWidgets('renders actions when provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => EdenModal.show(
                context,
                child: const Text('Body'),
                title: 'With Actions',
                actions: [
                  TextButton(onPressed: () {}, child: const Text('Cancel')),
                  ElevatedButton(onPressed: () {}, child: const Text('Confirm')),
                ],
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('does not dismiss on barrier tap when dismissible is false',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => EdenModal.show(
                context,
                child: const Text('Persistent'),
                title: 'Sticky Modal',
                dismissible: false,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Sticky Modal'), findsOneWidget);

      // Tap the barrier (outside the dialog)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Modal should still be visible
      expect(find.text('Sticky Modal'), findsOneWidget);
    });
  });
}
