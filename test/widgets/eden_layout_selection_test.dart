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
//
// TRD 23-06 INVERTED those two cases. `selectableBody` now defaults to FALSE
// (eden-ui-flutter#33): a SelectionArea over a subtree containing a Navigator
// asserts on deep-link to a nested route (flutter#151536, fix #184900
// unmerged), and every go_router shell app has a Navigator in `body`. The
// default-value probes therefore assert that omitting the flag installs NO
// region; two new cases cover the `selectableBody: true` opt-in.
//
// The two load-bearing "nav labels are NOT inside the selection region" cases
// moved onto the OPTED-IN tree in the same TRD. Left on the default tree they
// would have become vacuous — there is no region at all now, so `findsNothing`
// would pass for the wrong reason and the containment rule would stop being
// tested (see the objective's finding F1: a gate that cannot fail).

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

  Widget desktopOptedIn() => MaterialApp(
        home: EdenDesktopLayout(
          navItems: navItems,
          selectedId: 'home',
          onNavChanged: (_) {},
          selectableBody: true,
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

  Widget mobileOptedIn() => MaterialApp(
        home: EdenMobileLayout(
          navItems: navItems,
          selectedId: 'home',
          onNavChanged: (_) {},
          selectableBody: true,
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
    testWidgets('body is NOT selectable by default', (tester) async {
      await tester.pumpWidget(desktopDefault());
      await tester.pumpAndSettle();

      expect(find.byType(SelectableRegion), findsNothing,
          reason: 'selectableBody defaults to FALSE since eden-ui-flutter#33 — '
              'a SelectionArea over a Navigator body asserts on deep-link to a '
              'nested route (flutter#151536)');
      expect(find.text('body content'), findsOneWidget,
          reason: 'the default must still render the caller-supplied body');
    });

    testWidgets('selectableBody: true installs exactly one region',
        (tester) async {
      await tester.pumpWidget(desktopOptedIn());
      await tester.pumpAndSettle();

      expect(find.byType(SelectableRegion), findsOneWidget,
          reason: 'the opt-in must actually opt in — exactly one region, not '
              'zero and not a nested pair');
      expect(inRegion(find.text('body content')), findsOneWidget,
          reason: 'the caller-supplied body must be INSIDE the region, or the '
              'opt-in buys nothing');
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
      // Opted IN on purpose: with no region on the tree at all, the
      // `findsNothing` assertions below would pass vacuously and this — the
      // load-bearing case of the whole file — would stop testing containment.
      await tester.pumpWidget(desktopOptedIn());
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
    testWidgets('body is NOT selectable by default', (tester) async {
      await tester.pumpWidget(mobileDefault());
      await tester.pumpAndSettle();

      expect(find.byType(SelectableRegion), findsNothing,
          reason: 'selectableBody defaults to FALSE on the mobile layout too — '
              'eden-ui-flutter#33 / flutter#151536');
      expect(find.text('body content'), findsOneWidget,
          reason: 'the default must still render the caller-supplied body');
    });

    testWidgets('selectableBody: true installs exactly one region',
        (tester) async {
      await tester.pumpWidget(mobileOptedIn());
      await tester.pumpAndSettle();

      expect(find.byType(SelectableRegion), findsOneWidget,
          reason: 'the opt-in must actually opt in on mobile too');
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
      // Opted IN on purpose — see the desktop twin above.
      await tester.pumpWidget(mobileOptedIn());
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
