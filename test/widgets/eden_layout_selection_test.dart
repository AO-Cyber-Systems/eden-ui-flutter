// test/widgets/eden_layout_selection_test.dart
//
// TRD 40-06 — "page-level selection ON BY DEFAULT", proved against the carrier
// that actually reaches consumer apps: EdenDesktopLayout / EdenMobileLayout.
//
// The load-bearing cases are the two 'nav labels are NOT inside the selection
// region' tests. Without them, "wrap `body`" and "wrap the whole `Scaffold`"
// BOTH pass and the wrong one ships — a drag that runs from the sidebar into
// the page would copy 'HomeSettings' along with the content, which is a worse
// experience than no selection at all.
//
// The "by default" cases deliberately OMIT `selectableBody`, so they assert the
// declared default rather than a value the test passed itself.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const navItems = <EdenNavItem>[
    EdenNavItem(id: 'home', label: 'Home', icon: Icons.home),
    EdenNavItem(id: 'settings', label: 'Settings', icon: Icons.settings),
  ];

  /// `selectableBody` omitted on purpose — this is the default-value probe.
  Widget desktopDefault() => MaterialApp(
        home: EdenDesktopLayout(
          navItems: navItems,
          selectedId: 'home',
          onNavChanged: (_) {},
          body: const Text('body content'),
        ),
      );

  Widget desktopOptedOut() => MaterialApp(
        home: EdenDesktopLayout(
          navItems: navItems,
          selectedId: 'home',
          onNavChanged: (_) {},
          selectableBody: false,
          body: const Text('body content'),
        ),
      );

  /// `selectableBody` omitted on purpose — this is the default-value probe.
  Widget mobileDefault() => MaterialApp(
        home: EdenMobileLayout(
          navItems: navItems,
          selectedId: 'home',
          onNavChanged: (_) {},
          body: const Text('body content'),
        ),
      );

  Widget mobileOptedOut() => MaterialApp(
        home: EdenMobileLayout(
          navItems: navItems,
          selectedId: 'home',
          onNavChanged: (_) {},
          selectableBody: false,
          body: const Text('body content'),
        ),
      );

  Finder inRegion(Finder matching) => find.descendant(
        of: find.byType(SelectableRegion),
        matching: matching,
      );

  group('EdenDesktopLayout selection', () {
    testWidgets('body is selectable by default', (tester) async {
      await tester.pumpWidget(desktopDefault());
      await tester.pumpAndSettle();

      expect(find.byType(SelectableRegion), findsOneWidget,
          reason: 'selectableBody defaults to true, so exactly one region is '
              'installed around the body');
      expect(inRegion(find.text('body content')), findsOneWidget,
          reason: 'the caller-supplied body must be INSIDE the region, or the '
              'default buys nothing');
    });

    testWidgets('selectableBody: false installs no region', (tester) async {
      await tester.pumpWidget(desktopOptedOut());
      await tester.pumpAndSettle();

      expect(find.byType(SelectableRegion), findsNothing,
          reason: 'the opt-out must actually opt out');
      expect(find.text('body content'), findsOneWidget,
          reason: 'opting out of selection must not drop the body');
    });

    testWidgets('nav labels are NOT inside the selection region',
        (tester) async {
      await tester.pumpWidget(desktopDefault());
      await tester.pumpAndSettle();

      // Sanity: the sidebar really did render these, so findsNothing below is
      // about containment and not about the labels being absent.
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      expect(inRegion(find.text('Home')), findsNothing,
          reason: 'chrome is not data; a drag-select must not pick up '
              'navigation');
      expect(inRegion(find.text('Settings')), findsNothing,
          reason: 'chrome is not data; a drag-select must not pick up '
              'navigation');
    });
  });

  group('EdenMobileLayout selection', () {
    testWidgets('body is selectable by default', (tester) async {
      await tester.pumpWidget(mobileDefault());
      await tester.pumpAndSettle();

      expect(find.byType(SelectableRegion), findsOneWidget,
          reason: 'selectableBody defaults to true on the mobile layout too');
      expect(inRegion(find.text('body content')), findsOneWidget,
          reason: 'the caller-supplied body must be INSIDE the region');
    });

    testWidgets('selectableBody: false installs no region', (tester) async {
      await tester.pumpWidget(mobileOptedOut());
      await tester.pumpAndSettle();

      expect(find.byType(SelectableRegion), findsNothing,
          reason: 'the opt-out must actually opt out');
      expect(find.text('body content'), findsOneWidget,
          reason: 'opting out of selection must not drop the body');
    });

    testWidgets('bottom-bar nav labels are NOT inside the selection region',
        (tester) async {
      await tester.pumpWidget(mobileDefault());
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      expect(inRegion(find.text('Home')), findsNothing,
          reason: 'the bottom bar is chrome and stays outside the region');
      expect(inRegion(find.text('Settings')), findsNothing,
          reason: 'the bottom bar is chrome and stays outside the region');
    });
  });
}
