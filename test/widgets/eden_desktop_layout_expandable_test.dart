import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Tests for the OPT-IN disclosure added to EdenNavItem / EdenDesktopLayout.
//
// The governing constraint is additivity: `expandable`, `initiallyExpanded` and
// `isCaption` all default to today's behaviour, so `eden_desktop_layout_test.dart`
// passes byte-unchanged. Cases 18-20 below assert that property directly rather
// than leaning only on "the old tests still pass".

// --- hand-built fixtures -----------------------------------------------------
// Deliberately hand-written literals with names chosen so ordering assertions
// read clearly. No generated data.

EdenNavItem _aurora({
  bool expandable = true,
  bool initiallyExpanded = false,
  String? badge,
}) =>
    EdenNavItem(
      id: 'proj-aurora',
      label: 'Aurora',
      icon: Icons.folder_outlined,
      badge: badge,
      expandable: expandable,
      initiallyExpanded: initiallyExpanded,
      children: const [
        EdenNavItem(id: 'conv-kickoff', label: 'Kickoff notes', icon: Icons.chat_bubble_outline),
        EdenNavItem(id: 'conv-retro', label: 'Retro', icon: Icons.chat_bubble_outline),
      ],
    );

/// A group that never opts in — the path that must stay byte-identical.
const EdenNavItem _workspace = EdenNavItem(
  id: 'workspace',
  label: 'Workspace',
  icon: Icons.dashboard_outlined,
  children: [
    EdenNavItem(id: 'inbox', label: 'Inbox', icon: Icons.inbox_outlined),
    EdenNavItem(id: 'drafts', label: 'Drafts', icon: Icons.edit_outlined),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  required List<EdenNavItem> navItems,
  String selectedId = 'none',
  ValueChanged<String>? onNavChanged,
  bool initiallyCollapsed = false,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: EdenDesktopLayout(
      navItems: navItems,
      selectedId: selectedId,
      onNavChanged: onNavChanged ?? (_) {},
      body: const Text('Body'),
      initiallyCollapsed: initiallyCollapsed,
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('EdenDesktopLayout expandable groups', () {
    testWidgets('1. collapsed group shows its label and hides every child',
        (tester) async {
      await _pump(tester, navItems: [_aurora()]);

      expect(find.text('Aurora'), findsOneWidget);
      expect(find.text('Kickoff notes'), findsNothing);
      expect(find.text('Retro'), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_right), findsOneWidget);
    });

    testWidgets('2. tapping the disclosure header reveals every child',
        (tester) async {
      await _pump(tester, navItems: [_aurora()]);

      await tester.tap(find.text('Aurora'));
      await tester.pumpAndSettle();

      expect(find.text('Kickoff notes'), findsOneWidget);
      expect(find.text('Retro'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });

    testWidgets('3. the disclosure is a toggle, not a one-way reveal',
        (tester) async {
      await _pump(tester, navItems: [_aurora()]);

      await tester.tap(find.text('Aurora'));
      await tester.pumpAndSettle();
      expect(find.text('Kickoff notes'), findsOneWidget);

      await tester.tap(find.text('Aurora'));
      await tester.pumpAndSettle();
      expect(find.text('Kickoff notes'), findsNothing);
      expect(find.text('Retro'), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_right), findsOneWidget);
    });

    testWidgets('4. initiallyExpanded renders children on the first frame',
        (tester) async {
      await _pump(tester, navItems: [_aurora(initiallyExpanded: true)]);

      expect(find.text('Kickoff notes'), findsOneWidget);
      expect(find.text('Retro'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });

    testWidgets('5. header announces Semantics(expanded:) matching its state',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, navItems: [_aurora()]);

      expect(
        tester.getSemantics(find.text('Aurora')).flagsCollection.isExpanded.toBoolOrNull(),
        isFalse,
        reason: 'collapsed header must announce expanded=false',
      );

      await tester.tap(find.text('Aurora'));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.text('Aurora')).flagsCollection.isExpanded.toBoolOrNull(),
        isTrue,
        reason: 'the expanded flag must flip on tap',
      );
      handle.dispose();
    });

    testWidgets('5b. the disclosure header is a semantics button with the group label',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, navItems: [_aurora()]);

      final node = tester.getSemantics(find.text('Aurora'));
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.label, 'Aurora');
      handle.dispose();
    });

    // --- 18/19/20: the additivity net ---------------------------------------

    testWidgets(
        '18. a group that did NOT opt in keeps the static uppercase header and a flat child list',
        (tester) async {
      await _pump(tester, navItems: [_workspace]);

      expect(find.text('WORKSPACE'), findsOneWidget);
      expect(find.text('Inbox'), findsOneWidget);
      expect(find.text('Drafts'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_right), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
    });

    testWidgets(
        '18b. a non-expandable group header exposes no expanded state to semantics',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, navItems: [_workspace]);

      expect(
        tester.getSemantics(find.text('WORKSPACE')).flagsCollection.isExpanded.toBoolOrNull(),
        isNull,
        reason: 'a passive band must not claim a disclosure state',
      );
      handle.dispose();
    });

    testWidgets(
        '19. an expandable and a non-expandable group coexist without leaking state',
        (tester) async {
      await _pump(tester, navItems: [_workspace, _aurora()]);

      // Non-expandable: static band, children always visible.
      expect(find.text('WORKSPACE'), findsOneWidget);
      expect(find.text('Inbox'), findsOneWidget);
      // Expandable: sentence-case header, children hidden.
      expect(find.text('Aurora'), findsOneWidget);
      expect(find.text('AURORA'), findsNothing);
      expect(find.text('Kickoff notes'), findsNothing);

      await tester.tap(find.text('Aurora'));
      await tester.pumpAndSettle();

      // Expanding one must not disturb the other.
      expect(find.text('Kickoff notes'), findsOneWidget);
      expect(find.text('WORKSPACE'), findsOneWidget);
      expect(find.text('Inbox'), findsOneWidget);
      expect(find.text('Drafts'), findsOneWidget);
    });

    testWidgets(
        '20. the 72px collapsed rail renders a group the same whether expandable or not',
        (tester) async {
      await _pump(tester, navItems: [_aurora()], initiallyCollapsed: true);

      // D5: collapsed rail is icons only — one synthesised tile, no chevron,
      // no children, no nesting.
      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_right), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
      expect(find.byIcon(Icons.chat_bubble_outline), findsNothing);
    });

    testWidgets('20b. collapsed rail still reports the first child id, unchanged by expandable',
        (tester) async {
      String? tapped;
      await _pump(
        tester,
        navItems: [_aurora()],
        initiallyCollapsed: true,
        onNavChanged: (id) => tapped = id,
      );

      await tester.tap(find.byIcon(Icons.folder_outlined));
      // Pre-existing collapsed-branch behaviour (D4), deliberately NOT changed here.
      expect(tapped, 'conv-kickoff');
    });
  });
}
