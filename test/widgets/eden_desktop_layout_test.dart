import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final navItems = [
    const EdenNavItem(id: 'home', label: 'Home', icon: Icons.home),
    const EdenNavItem(id: 'settings', label: 'Settings', icon: Icons.settings),
  ];

  group('EdenDesktopLayout', () {
    testWidgets('renders nav item labels in sidebar', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: EdenDesktopLayout(
          navItems: navItems,
          selectedId: 'home',
          onNavChanged: (_) {},
          body: const Text('Main Content'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('renders body content', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: EdenDesktopLayout(
          navItems: navItems,
          selectedId: 'home',
          onNavChanged: (_) {},
          body: const Text('Body Area'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Body Area'), findsOneWidget);
    });

    testWidgets('onNavChanged fires with item id when nav item tapped',
        (tester) async {
      String? selected;
      await tester.pumpWidget(MaterialApp(
        home: EdenDesktopLayout(
          navItems: navItems,
          selectedId: 'home',
          onNavChanged: (id) => selected = id,
          body: const Text('Body'),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      expect(selected, 'settings');
    });

    testWidgets('renders user info when user provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: EdenDesktopLayout(
          navItems: navItems,
          selectedId: 'home',
          onNavChanged: (_) {},
          body: const Text('Body'),
          user: const EdenLayoutUser(
            name: 'John Doe',
            email: 'john@example.com',
            initials: 'JD',
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
    });

    testWidgets('sidebar collapse toggle exists', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: EdenDesktopLayout(
          navItems: navItems,
          selectedId: 'home',
          onNavChanged: (_) {},
          body: const Text('Body'),
        ),
      ));
      await tester.pumpAndSettle();

      // The collapse toggle uses Icons.menu_open
      expect(find.byIcon(Icons.menu_open), findsOneWidget);
    });
  });
}
