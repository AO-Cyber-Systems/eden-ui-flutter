// One nav row, ONE tap route — EdenMobileLayout's bottom bar and drawer.
//
// THE DEFECT THIS PINS. `EdenMobileLayout._navRow` is the single point that
// publishes a row's semantics: it wraps whatever rendered the row in
// `Semantics(identifier: 'eden-nav-<id>', button: true, onTap: …)`. Its
// default renderers (`_BottomItem`, `_DrawerTile`) carry no `Semantics` of
// their own — but each is a bare `GestureDetector(onTap:)`, and a
// GestureDetector contributes `SemanticsAction.tap` to the tree IMPLICITLY.
// So the identified node advertised one tap and an unidentified descendant
// advertised a second:
//
//   control "eden-nav-home" declares 2 tap actions (its own semantics node
//   plus 1 unidentified descendant node(s) that also advertise
//   SemanticsAction.tap).
//
// On web the DOM semantics node is what receives the click
// (memory: flutter-web-semantics-node-is-the-click-target), so two nested
// nodes both advertising tap is two click targets stacked on one row.
//
// CASE 2 IS THE ONE THAT MATTERS. Silencing the oracle is trivial and
// useless — dropping the inner `onTap` outright leaves ONE tap action and a
// row a pointer cannot activate, and dropping the OUTER `onTap` leaves the
// identified node announcing `button: true` with nothing to activate. Case 2
// therefore counts callback INVOCATIONS on a real pointer tap and requires
// exactly one: a fix that reports one tap action while still firing the
// route twice (or zero times) is worse than the bug.
//
// CASE 4 IS THE OTHER HALF. `eden-nav-<id>` is what the probe and both
// consuming apps address. A fix that drops the outer `Semantics` would
// satisfy cases 1-2 and silently break every E2E flow keyed on the
// identifier, so it is asserted explicitly — node present, and the tap
// action is on THAT node, not somewhere under it.
library;

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:eden_ui_flutter/testing/semantics_geometry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

// --- hand-built fixtures (no generated data) -------------------------------

const List<EdenNavItem> _navItems = <EdenNavItem>[
  EdenNavItem(id: 'home', label: 'Home', icon: Icons.home),
  EdenNavItem(id: 'orders', label: 'Orders', icon: Icons.receipt_long),
  EdenNavItem(id: 'reports', label: 'Reports', icon: Icons.bar_chart),
  EdenNavItem(id: 'settings', label: 'Settings', icon: Icons.settings),
];

/// Pumps the mobile shell and returns the list every `onNavChanged` id lands
/// in, so a case can count INVOCATIONS rather than trust a last-write-wins
/// `String?`.
Future<List<String>> _pumpShell(WidgetTester tester) async {
  final List<String> fired = <String>[];
  await tester.pumpWidget(MaterialApp(
    theme: EdenTheme.light(),
    home: EdenMobileLayout(
      navItems: _navItems,
      selectedId: 'home',
      onNavChanged: fired.add,
      body: const Text('Body'),
    ),
  ));
  await tester.pumpAndSettle();
  return fired;
}

/// EVERY node carrying [identifier], or a named failure listing what IS there.
///
/// A list, not a single node: the Scaffold builds its drawer eagerly even
/// while it is closed, so `eden-nav-home` is published TWICE — once by the bar
/// and once by the drawer tile. Asserting on "the" node would silently pick
/// one and leave the other's defect unmeasured.
List<SemanticsNode> _nodesWithIdentifier(
  WidgetTester tester,
  String identifier,
) {
  final SemanticsNode root = rootSemanticsNodeOf(tester);
  final List<String> seen = <String>[];
  final List<SemanticsNode> hits = <SemanticsNode>[];

  void walk(SemanticsNode node) {
    final String id = node.getSemanticsData().identifier;
    if (id.isNotEmpty) {
      seen.add(id);
      if (id == identifier) hits.add(node);
    }
    node.visitChildren((SemanticsNode child) {
      walk(child);
      return true;
    });
  }

  walk(root);
  if (hits.isEmpty) {
    fail(
      'no semantics node with identifier "$identifier" — the probe and both '
      'consuming apps key off that identifier and it must survive any fix. '
      'Identifiers present: $seen',
    );
  }
  return hits;
}

/// Counts `SemanticsAction.tap` on [node] and on its descendants, stopping at
/// any descendant that carries its own identifier.
///
/// This is `expectUiSane`'s own rule, restated here so the case fails on this
/// specific defect rather than on whatever else the whole-surface oracle
/// happens to find on the day.
int _tapRoutes(SemanticsNode node, {required bool isOwner}) {
  final SemanticsData data = node.getSemanticsData();
  if (!isOwner && data.identifier.isNotEmpty) return 0;
  int count = data.hasAction(SemanticsAction.tap) ? 1 : 0;
  node.visitChildren((SemanticsNode child) {
    count += _tapRoutes(child, isOwner: false);
    return true;
  });
  return count;
}

/// The tap-route count of each node published under [identifier] — one entry
/// per node, so a defect on the drawer copy cannot hide behind a clean bar
/// copy (or the reverse).
List<int> _tapRoutesFor(WidgetTester tester, String identifier) =>
    _nodesWithIdentifier(tester, identifier)
        .map((SemanticsNode n) => _tapRoutes(n, isOwner: true))
        .toList();

void main() {
  testWidgets(
    'case 1: every bottom-bar row declares exactly ONE tap action',
    (WidgetTester tester) async {
      await _pumpShell(tester);
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpAndSettle();

      for (final EdenNavItem item in _navItems) {
        final String identifier = 'eden-nav-${item.id}';
        expect(
          _tapRoutesFor(tester, identifier),
          everyElement(1),
          reason: 'control "$identifier" advertises more than one tap route. '
              'Its own node carries onTap AND an unidentified descendant (the '
              'default renderer GestureDetector) advertises one too. On web '
              'the semantics node IS the click target, so that is two stacked '
              'click targets on one row.',
        );
      }
      handle.dispose();
    },
  );

  testWidgets(
    'case 2: a real pointer tap on a bottom-bar row fires the route EXACTLY '
    'once',
    (WidgetTester tester) async {
      final List<String> fired = await _pumpShell(tester);

      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();

      expect(
        fired,
        <String>['orders'],
        reason: 'a fix that silences the tap-action count while double-firing '
            '(or no longer firing) onNavChanged is worse than the bug. '
            'ExcludeSemantics removes a subtree from the SEMANTICS tree only '
            '— the GestureDetector under it must still take the pointer.',
      );
    },
  );

  testWidgets(
    'case 3: every drawer row declares exactly ONE tap action, and a tap '
    'fires the route once',
    (WidgetTester tester) async {
      final List<String> fired = await _pumpShell(tester);
      final ScaffoldState scaffold =
          tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffold.openDrawer();
      await tester.pumpAndSettle();

      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpAndSettle();
      for (final EdenNavItem item in _navItems) {
        final String identifier = 'eden-nav-${item.id}';
        expect(
          _tapRoutesFor(tester, identifier),
          everyElement(1),
          reason: '_DrawerTile has the same shape as _BottomItem — a bare '
              'GestureDetector under the row Semantics(onTap:) — so it '
              'carries the same defect and takes the same fix.',
        );
      }
      handle.dispose();

      await tester.tap(find.text('Reports').last);
      await tester.pumpAndSettle();
      expect(fired, <String>['reports']);
    },
  );

  testWidgets(
    'case 4: the eden-nav-<id> identifier is still published, and the tap '
    'action is on THAT node',
    (WidgetTester tester) async {
      await _pumpShell(tester);
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpAndSettle();

      for (final EdenNavItem item in _navItems) {
        final String identifier = 'eden-nav-${item.id}';
        expect(
          find.bySemanticsIdentifier(identifier),
          findsWidgets,
          reason: 'the probe and both consuming apps address rows by '
              '"$identifier"; it must stay addressable.',
        );
        for (final SemanticsNode node
            in _nodesWithIdentifier(tester, identifier)) {
          final SemanticsData data = node.getSemanticsData();
          expect(
            data.hasAction(SemanticsAction.tap),
            isTrue,
            reason: 'the identified node announces button: true, so assistive '
                'tech activates THIS node. If the only tap route moved to an '
                'unidentified descendant the row would announce a button that '
                'does nothing.',
          );
          expect(data.label, item.label);
        }
      }
      handle.dispose();
    },
  );
}
