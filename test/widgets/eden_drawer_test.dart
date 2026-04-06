import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EdenDrawerPanel', () {
    testWidgets('shows title and child content', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => EdenDrawerPanel.show(
                context,
                child: const Text('Drawer Body'),
                title: 'Test Drawer',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Test Drawer'), findsOneWidget);
      expect(find.text('Drawer Body'), findsOneWidget);
    });

    testWidgets('closes when close icon tapped', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => EdenDrawerPanel.show(
                context,
                child: const Text('Content'),
                title: 'Close Me',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Close Me'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Close Me'), findsNothing);
    });

    testWidgets('renders without title', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => EdenDrawerPanel.show(
                context,
                child: const Text('No Title Drawer'),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('No Title Drawer'), findsOneWidget);
    });
  });
}
