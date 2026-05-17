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

    // -----------------------------------------------------------------------
    // Obj 010 — illustration slot + secondary action
    // -----------------------------------------------------------------------

    testWidgets('illustration replaces icon when supplied', (tester) async {
      await tester.pumpWidget(wrap(
        EdenEmptyState(
          title: 'X',
          icon: Icons.inbox,
          illustration: Container(
            key: const ValueKey('illust'),
            width: 80,
            height: 80,
            color: const Color(0xFFEE0000),
          ),
        ),
      ));
      expect(find.byKey(const ValueKey('illust')), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsNothing);
    });

    testWidgets('illustration without icon renders illustration', (tester) async {
      await tester.pumpWidget(wrap(
        EdenEmptyState(
          title: 'X',
          illustration: Container(
            key: const ValueKey('illust2'),
            width: 80,
            height: 80,
          ),
        ),
      ));
      expect(find.byKey(const ValueKey('illust2')), findsOneWidget);
    });

    testWidgets('icon without illustration: existing behavior', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenEmptyState(title: 'X', icon: Icons.inbox),
      ));
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('neither illustration nor icon: no leading visual', (tester) async {
      await tester.pumpWidget(wrap(const EdenEmptyState(title: 'X')));
      expect(find.byIcon(Icons.inbox), findsNothing);
    });

    testWidgets('secondary action renders when label + callback both supplied', (tester) async {
      await tester.pumpWidget(wrap(
        EdenEmptyState(
          title: 'X',
          actionLabel: 'Primary',
          onAction: () {},
          secondaryActionLabel: 'Secondary',
          onSecondaryAction: () {},
        ),
      ));
      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Secondary'), findsOneWidget);
    });

    testWidgets('secondary action does NOT render when callback missing', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenEmptyState(
          title: 'X',
          secondaryActionLabel: 'Secondary',
          // onSecondaryAction is null
        ),
      ));
      expect(find.text('Secondary'), findsNothing);
    });

    testWidgets('WRONG-ACTION ISOLATION: primary fires only onAction; secondary fires only onSecondaryAction',
        (tester) async {
      final fired = <String>[];
      await tester.pumpWidget(wrap(
        EdenEmptyState(
          title: 'X',
          actionLabel: 'Try again',
          onAction: () => fired.add('primary'),
          secondaryActionLabel: 'Learn more',
          onSecondaryAction: () => fired.add('secondary'),
        ),
      ));
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(fired, equals(['primary']));
      fired.clear();
      await tester.tap(find.text('Learn more'));
      await tester.pump();
      expect(fired, equals(['secondary']));
    });

    testWidgets('iPhone-narrow 390pt: long labels do not overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 700 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(
        EdenEmptyState(
          title: 'X',
          actionLabel: 'Try again with verbose explanation',
          onAction: () {},
          secondaryActionLabel: 'Learn more about this empty state',
          onSecondaryAction: () {},
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
