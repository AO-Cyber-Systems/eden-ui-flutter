import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenEmptyState', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenEmptyState(title: 'No items found'),
      ));

      expect(find.text('No items found'), findsOneWidget);
    });

    testWidgets('renders description', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenEmptyState(
          title: 'No results',
          description: 'Try adjusting your search',
        ),
      ));

      expect(find.text('No results'), findsOneWidget);
      expect(find.text('Try adjusting your search'), findsOneWidget);
    });

    testWidgets('renders with icon', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenEmptyState(
          title: 'Empty',
          icon: Icons.inbox,
        ),
      ));

      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('renders action button from actionLabel and onAction',
        (tester) async {
      var actionCalled = false;
      await tester.pumpWidget(wrap(
        EdenEmptyState(
          title: 'No items',
          actionLabel: 'Create one',
          onAction: () => actionCalled = true,
        ),
      ));

      expect(find.text('Create one'), findsOneWidget);
      await tester.tap(find.text('Create one'));
      expect(actionCalled, isTrue);
    });

    testWidgets('renders custom action widget', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenEmptyState(
          title: 'Custom',
          action: Text('Custom Action Widget'),
        ),
      ));

      expect(find.text('Custom Action Widget'), findsOneWidget);
    });

    testWidgets('prefers action widget over actionLabel', (tester) async {
      await tester.pumpWidget(wrap(
        EdenEmptyState(
          title: 'Test',
          action: const Text('Widget Action'),
          actionLabel: 'Label Action',
          onAction: () {},
        ),
      ));

      expect(find.text('Widget Action'), findsOneWidget);
      // The actionLabel button should not appear since action widget takes priority
      expect(find.widgetWithText(ElevatedButton, 'Label Action'), findsNothing);
    });

    testWidgets('renders without optional fields', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenEmptyState(title: 'Nothing here'),
      ));

      expect(find.text('Nothing here'), findsOneWidget);
      // No icon, no description, no action
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('does not show action button when only actionLabel without onAction',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenEmptyState(
          title: 'Test',
          actionLabel: 'Add',
          // onAction is null
        ),
      ));

      expect(find.widgetWithText(ElevatedButton, 'Add'), findsNothing);
    });
  });
}
