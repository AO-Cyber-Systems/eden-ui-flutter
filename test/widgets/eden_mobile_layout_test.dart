import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final navItems = [
    const EdenNavItem(id: 'home', label: 'Home', icon: Icons.home),
    const EdenNavItem(id: 'search', label: 'Search', icon: Icons.search),
    const EdenNavItem(id: 'profile', label: 'Profile', icon: Icons.person),
  ];

  group('EdenMobileLayout', () {
    testWidgets('renders body content', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: EdenMobileLayout(
          navItems: navItems,
          selectedId: 'home',
          onNavChanged: (_) {},
          body: const Text('Mobile Body'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Mobile Body'), findsOneWidget);
    });

    testWidgets('shows bottom navigation items', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: EdenMobileLayout(
          navItems: navItems,
          selectedId: 'home',
          onNavChanged: (_) {},
          body: const Text('Body'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('onNavChanged fires when bottom nav item tapped',
        (tester) async {
      String? selected;
      await tester.pumpWidget(MaterialApp(
        home: EdenMobileLayout(
          navItems: navItems,
          selectedId: 'home',
          onNavChanged: (id) => selected = id,
          body: const Text('Body'),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Search'));
      expect(selected, 'search');
    });

    testWidgets('overflow items handled without error', (tester) async {
      final manyItems = List.generate(
        7,
        (i) => EdenNavItem(
          id: 'item-$i',
          label: 'Item $i',
          icon: Icons.circle,
        ),
      );

      await tester.pumpWidget(MaterialApp(
        home: EdenMobileLayout(
          navItems: manyItems,
          selectedId: 'item-0',
          onNavChanged: (_) {},
          body: const Text('Body'),
          maxBottomItems: 5,
        ),
      ));
      await tester.pumpAndSettle();

      // With 7 items and max 5, should show 4 items + "More"
      expect(find.text('More'), findsOneWidget);
    });
  });
}
