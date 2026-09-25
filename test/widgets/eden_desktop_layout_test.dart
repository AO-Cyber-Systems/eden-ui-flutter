import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

    // -----------------------------------------------------------------
    // Collapse-toggle hit area.
    //
    // The glyph is a 20px Icon. A bare Icon inside a GestureDetector makes
    // the HIT TARGET 20x20 too, which is under WCAG 2.5.8 Target Size
    // (Minimum)'s 24x24 — the POINTER floor, the most permissive standard
    // that applies to anything. This control is therefore undersized under
    // every reading, independent of the input-modality ruling that lets the
    // 40px nav rows stand.
    //
    // 44x44 is the floor asserted here rather than 24x24: the header is
    // already 56px tall, so the larger box costs no layout at all, and it
    // clears WCAG 2.5.5 Target Size (Enhanced) as well.
    // -----------------------------------------------------------------

    testWidgets('collapse toggle hit target is at least 44x44',
        (tester) async {
      // Disposed INLINE, not via addTearDown: flutter_test verifies handle
      // disposal BEFORE addTearDown callbacks run.
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(MaterialApp(
        home: EdenDesktopLayout(
          navItems: navItems,
          selectedId: 'home',
          onNavChanged: (_) {},
          body: const Text('Body'),
        ),
      ));
      await tester.pumpAndSettle();

      final SemanticsNode node =
          tester.getSemantics(find.bySemanticsLabel('Collapse sidebar'));

      // `node.rect.size` is exactly what MinimumTapTargetGuideline compares,
      // and what the oracle's failure reported as Size(20.0, 20.0).
      expect(node.rect.width, greaterThanOrEqualTo(44.0),
          reason: 'collapse toggle is ${node.rect.size}; a 20x20 hit target '
              'is under even the 24x24 WCAG 2.5.8 pointer minimum');
      expect(node.rect.height, greaterThanOrEqualTo(44.0),
          reason: 'collapse toggle is ${node.rect.size}; a 20x20 hit target '
              'is under even the 24x24 WCAG 2.5.8 pointer minimum');
      handle.dispose();
    });

    testWidgets('collapse toggle fires from the CORNER of its hit area',
        (tester) async {
      // Disposed INLINE, not via addTearDown: flutter_test verifies handle
      // disposal BEFORE addTearDown callbacks run.
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(MaterialApp(
        home: EdenDesktopLayout(
          navItems: navItems,
          selectedId: 'home',
          onNavChanged: (_) {},
          body: const Text('Body'),
        ),
      ));
      await tester.pumpAndSettle();

      // Growing the box is worthless if the new area does not hit-test: a
      // GestureDetector over a transparent gap needs
      // HitTestBehavior.opaque, which the collapsed variant of this header
      // already carries and the expanded one did not. Tap 2px inside the
      // top-left corner — inside the enlarged box, outside the 20px glyph.
      final Rect hitArea =
          tester.getRect(find.bySemanticsLabel('Collapse sidebar'));
      await tester.tapAt(hitArea.topLeft + const Offset(2, 2));
      await tester.pumpAndSettle();

      // Collapsed: the menu_open glyph is gone, the expand chevron is in.
      expect(find.byIcon(Icons.menu_open), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      handle.dispose();
    });
  });
}
