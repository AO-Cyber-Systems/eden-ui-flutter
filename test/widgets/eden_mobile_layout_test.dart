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

  // --- caption / divider: desktop-only decorations must not become mobile
  // destinations ------------------------------------------------------------
  //
  // aocore and aosentry share ONE navItems list across EdenDesktopLayout and
  // EdenMobileLayout, so anything the rail understands and the bar does not
  // ships as a broken bottom bar the moment they adopt it.

  group('EdenMobileLayout — captions and dividers', () {
    const decorated = <EdenNavItem>[
      EdenNavItem.caption('Projects'),
      EdenNavItem(id: 'home', label: 'Home', icon: Icons.home),
      EdenNavItem(id: 'search', label: 'Search', icon: Icons.search),
      EdenNavItem.divider(),
      EdenNavItem(id: 'profile', label: 'Profile', icon: Icons.person),
      EdenNavItem(id: 'alerts', label: 'Alerts', icon: Icons.notifications),
      EdenNavItem(id: 'settings', label: 'Settings', icon: Icons.settings),
    ];

    Future<void> pumpPhone(
      WidgetTester tester, {
      List<EdenNavItem> navItems = decorated,
      ValueChanged<String>? onNavChanged,
      int maxBottomItems = 5,
    }) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: EdenMobileLayout(
          navItems: navItems,
          selectedId: 'home',
          onNavChanged: onNavChanged ?? (_) {},
          maxBottomItems: maxBottomItems,
          body: const Text('Body'),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('a caption is not a bottom-bar destination', (tester) async {
      final fired = <String>[];
      await pumpPhone(tester, onNavChanged: fired.add);

      expect(find.byIcon(Icons.label_outline), findsNothing,
          reason: 'a caption rendered as a tab with the placeholder icon it '
              'only carries because EdenNavItem needs one');
      expect(find.text('Projects'), findsNothing);

      // Nothing may claim the caption sentinel as a destination: '__caption__'
      // matches no route in any consumer.
      expect(_navIdentifier(tester, '__caption__'), findsNothing);
      expect(fired, isNot(contains('__caption__')));
    });

    testWidgets('a divider is not a bottom-bar destination', (tester) async {
      final fired = <String>[];
      await pumpPhone(tester, onNavChanged: fired.add);

      expect(find.byIcon(Icons.horizontal_rule), findsNothing,
          reason: 'a divider rendered as a tab with a horizontal_rule icon');
      expect(_navIdentifier(tester, '__divider__'), findsNothing);
      expect(fired, isNot(contains('__divider__')));
    });

    testWidgets(
        'captions and dividers do not consume maxBottomItems slots',
        (tester) async {
      await pumpPhone(tester);

      // Five REAL destinations and maxBottomItems: 5 — everything fits, so no
      // More tab. Counting the caption and the divider makes it seven, which
      // pushes two real destinations into overflow.
      expect(find.text('More'), findsNothing,
          reason: 'decorations consumed slots and forced an overflow tab');
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets(
        'the drawer renders a caption as a section label and a divider as a rule',
        (tester) async {
      final fired = <String>[];
      await pumpPhone(tester, onNavChanged: fired.add);

      final dividersBefore =
          tester.widgetList<Divider>(find.byType(Divider)).length;

      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();

      // Caption: the same uppercase band the drawer already draws for a group.
      expect(find.text('PROJECTS'), findsOneWidget);
      expect(find.text('Projects'), findsNothing);
      expect(find.byIcon(Icons.label_outline), findsNothing);

      // Divider: a rule, not a tile.
      expect(find.byIcon(Icons.horizontal_rule), findsNothing);
      expect(tester.widgetList<Divider>(find.byType(Divider)).length,
          greaterThan(dividersBefore),
          reason: 'the divider must actually draw a rule in the drawer');

      // Neither is tappable.
      await tester.tap(find.text('PROJECTS'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(fired, isEmpty);
    });
  });
}

/// Finds the Semantics wrapper a layout puts on a nav destination, by the
/// `eden-nav-<id>` identifier convention both layouts follow.
Finder _navIdentifier(WidgetTester tester, String id) =>
    find.byWidgetPredicate((w) =>
        w is Semantics && w.properties.identifier == 'eden-nav-$id');
