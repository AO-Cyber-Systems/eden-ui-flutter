import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

/// A second expandable group, so seed-sync can be tested per id rather than
/// per whole-set. Child labels are distinct from Aurora's on purpose.
EdenNavItem _borealis({bool initiallyExpanded = false}) => EdenNavItem(
      id: 'proj-borealis',
      label: 'Borealis',
      icon: Icons.folder_outlined,
      expandable: true,
      initiallyExpanded: initiallyExpanded,
      children: const [
        EdenNavItem(id: 'conv-standup', label: 'Standup', icon: Icons.chat_bubble_outline),
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

const EdenNavItem _leafHome =
    EdenNavItem(id: 'home', label: 'Home', icon: Icons.home_outlined);
const EdenNavItem _leafSettings =
    EdenNavItem(id: 'settings', label: 'Settings', icon: Icons.settings_outlined);

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
      // A control a reader can FIND but not ACTIVATE is worse than one it
      // cannot find: `button: true` is a promise that a double-tap does
      // something. Without SemanticsAction.tap on the node the promise is a lie
      // and the children are permanently unreachable.
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
        reason: 'the header announces button:true, so it must accept a tap',
      );
      handle.dispose();
    });

    testWidgets(
        '5c. the disclosure header carries the same tap action a plain nav tile does',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, navItems: [_aurora(), _leafHome]);

      // Differential control: the leaf tile is the same Semantics(button:true)
      // shape WITHOUT ExcludeSemantics, and it has always been actionable.
      final leaf = tester.getSemantics(find.text('Home'));
      expect(leaf.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

      final header = tester.getSemantics(find.text('Aurora'));
      expect(
        header.getSemanticsData().hasAction(SemanticsAction.tap),
        leaf.getSemanticsData().hasAction(SemanticsAction.tap),
        reason: 'header and leaf must be equally activatable by a screen reader',
      );

      // And the announced action must actually disclose the children.
      // tester.semantics.tap drives the SEMANTICS action, not a hit test, and
      // throws if the node does not offer it — which is the defect itself.
      tester.semantics.tap(find.semantics.byLabel('Aurora'));
      await tester.pumpAndSettle();
      expect(find.text('Kickoff notes'), findsOneWidget);
      handle.dispose();
    });

    // --- 9-12: the cases the numbering skipped -------------------------------
    // 5b jumps to 18 and 17 back to 6, so 9-12 were planned and never written.
    // They are exactly the ground review findings 2 and 3 landed on: selection
    // hidden inside a closed group (9, 9b) and seed re-sync clobbering the
    // user's own disclosure gestures (10, 11, 12).

    testWidgets(
        '9. a CLOSED group reads as selected when it owns the selected child',
        (tester) async {
      final handle = tester.ensureSemantics();

      // Control: nothing in this sidebar is selected.
      await _pump(tester, navItems: [_aurora()], selectedId: 'none');
      expect(tester.widget<Text>(find.text('Aurora')).style?.fontWeight,
          FontWeight.w500);
      expect(tester.getSemantics(find.text('Aurora')).flagsCollection.isSelected.toBoolOrNull(),
          isFalse);

      // The defect: 'conv-retro' IS the selected route, but it lives inside a
      // closed group, so the sidebar showed selection NOWHERE.
      await _pump(tester, navItems: [_aurora()], selectedId: 'conv-retro');
      expect(find.text('Retro'), findsNothing, reason: 'group is still closed');

      final node = tester.getSemantics(find.text('Aurora'));
      expect(node.flagsCollection.isSelected.toBoolOrNull(), isTrue,
          reason: 'a closed group stands in for the selected child it hides — '
              'the same substitution the 72px rail already makes');
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue,
          reason: 'and it must still be activatable');
      expect(tester.widget<Text>(find.text('Aurora')).style?.fontWeight,
          FontWeight.w600);
      handle.dispose();
    });

    testWidgets(
        '9b. an OPEN group leaves the selection on the child, not on both rows',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        navItems: [_aurora(initiallyExpanded: true)],
        selectedId: 'conv-retro',
      );

      // The child is visible and owns the highlight.
      expect(tester.widget<Text>(find.text('Retro')).style?.fontWeight,
          FontWeight.w600);
      expect(tester.getSemantics(find.text('Retro')).flagsCollection.isSelected.toBoolOrNull(),
          isTrue);

      // The header does not duplicate it: substitution exists only while the
      // child is HIDDEN.
      expect(tester.widget<Text>(find.text('Aurora')).style?.fontWeight,
          FontWeight.w500);
      expect(tester.getSemantics(find.text('Aurora')).flagsCollection.isSelected.toBoolOrNull(),
          isFalse);

      // A header that is itself the selected id still reads selected, open or not.
      await _pump(
        tester,
        navItems: [_aurora(initiallyExpanded: true)],
        selectedId: 'proj-aurora',
      );
      expect(tester.widget<Text>(find.text('Aurora')).style?.fontWeight,
          FontWeight.w600);
      handle.dispose();
    });

    testWidgets(
        '10. a rebuild driven by ANOTHER group must not reopen one the user closed',
        (tester) async {
      // aodex rebuilds navItems from live data, so didUpdateWidget runs
      // constantly with the same seeds and one moving part.
      await _pump(tester,
          navItems: [_aurora(initiallyExpanded: true), _borealis()]);
      expect(find.text('Kickoff notes'), findsOneWidget);

      // The user tidies the sidebar.
      await tester.tap(find.text('Aurora'));
      await tester.pumpAndSettle();
      expect(find.text('Kickoff notes'), findsNothing);

      // A rebuild arrives in which only BOREALIS's seed changed. Aurora's own
      // seed is byte-identical to the one it already had.
      await _pump(tester, navItems: [
        _aurora(initiallyExpanded: true),
        _borealis(initiallyExpanded: true),
      ]);

      expect(find.text('Standup'), findsOneWidget,
          reason: "borealis's own seed changed, so borealis opens");
      expect(find.text('Kickoff notes'), findsNothing,
          reason: 'aurora\'s seed did NOT change, so the user\'s close stands — '
              'a whole-set comparison springs it back open under the cursor');
    });

    testWidgets(
        '11. a seed that DOES change for a group still moves that group',
        (tester) async {
      // The over-fix guard for 10: per-id diffing must not become "ignore the
      // parent forever".
      await _pump(tester, navItems: [_aurora(), _borealis()]);
      expect(find.text('Kickoff notes'), findsNothing);

      await _pump(
          tester, navItems: [_aurora(initiallyExpanded: true), _borealis()]);
      expect(find.text('Kickoff notes'), findsOneWidget,
          reason: 'false -> true on this id opens it');

      await _pump(tester, navItems: [_aurora(), _borealis()]);
      expect(find.text('Kickoff notes'), findsNothing,
          reason: 'true -> false on this id closes it');
    });

    testWidgets(
        '12. expansion state for a group that no longer exists is pruned',
        (tester) async {
      await _pump(tester, navItems: [_aurora(), _borealis()]);

      // User-driven expansion, so nothing about it is derivable from the seeds.
      await tester.tap(find.text('Aurora'));
      await tester.pumpAndSettle();
      expect(find.text('Kickoff notes'), findsOneWidget);

      // Aurora is deleted upstream. Seeds are unchanged (both still false), so
      // a whole-set comparison sees no difference and never drops the id.
      await _pump(tester, navItems: [_borealis()]);
      expect(find.text('Aurora'), findsNothing);

      // Aurora comes back as a fresh group that asks to be CLOSED.
      await _pump(tester, navItems: [_aurora(), _borealis()]);
      expect(find.text('Aurora'), findsOneWidget);
      expect(find.text('Kickoff notes'), findsNothing,
          reason: 'a stale id left in _expandedGroupIds resurrects an old '
              'disclosure on a group that arrived asking to be closed');
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


    // --- 13-17: caption and divider -----------------------------------------

    testWidgets('13. EdenNavItem.caption renders as an uppercase section label',
        (tester) async {
      await _pump(tester, navItems: const [EdenNavItem.caption('Projects')]);

      expect(find.text('PROJECTS'), findsOneWidget);
      final style = tester.widget<Text>(find.text('PROJECTS')).style;
      expect(style?.fontSize, 10);
      expect(style?.fontWeight, FontWeight.w700);
      expect(style?.letterSpacing, 0.8);
    });

    testWidgets(
        '13b. a caption is styled identically to the existing static group band',
        (tester) async {
      await _pump(
        tester,
        navItems: const [EdenNavItem.caption('Projects'), _workspace],
      );

      final caption = tester.widget<Text>(find.text('PROJECTS')).style;
      final band = tester.widget<Text>(find.text('WORKSPACE')).style;
      expect(caption, band,
          reason: 'one extracted style, not two copies of the literals');
    });

    testWidgets('14. a caption has no tap target and never fires onNavChanged',
        (tester) async {
      final fired = <String>[];
      await _pump(
        tester,
        navItems: const [EdenNavItem.caption('Projects')],
        onNavChanged: fired.add,
      );

      expect(
        find.ancestor(
            of: find.text('PROJECTS'), matching: find.byType(GestureDetector)),
        findsNothing,
      );
      expect(
        find.ancestor(of: find.text('PROJECTS'), matching: find.byType(InkWell)),
        findsNothing,
      );

      await tester.tap(find.text('PROJECTS'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(fired, isEmpty);
    });

    testWidgets('15. a caption is not offered as a button to a screen reader',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, navItems: const [EdenNavItem.caption('Projects')]);

      expect(tester.getSemantics(find.text('PROJECTS')).flagsCollection.isButton,
          isFalse);
      handle.dispose();
    });

    testWidgets('16. EdenNavItem.divider renders a Divider, not a blank tappable row',
        (tester) async {
      // Baseline: the sidebar already draws one Divider under its header.
      await _pump(tester, navItems: const [_leafHome]);
      expect(find.byType(Divider), findsOneWidget);

      await _pump(
        tester,
        navItems: const [_leafHome, EdenNavItem.divider(), _leafSettings],
      );

      expect(find.byType(Divider), findsNWidgets(2));
      // The defect being corrected: a _NavTile with an empty label and a
      // horizontal_rule icon.
      expect(find.byIcon(Icons.horizontal_rule), findsNothing);
      expect(find.text(''), findsNothing);
    });

    testWidgets('17. neither a caption nor a divider renders in the 72px rail',
        (tester) async {
      await _pump(
        tester,
        navItems: const [
          EdenNavItem.caption('Projects'),
          _leafHome,
          EdenNavItem.divider(),
        ],
        initiallyCollapsed: true,
      );

      expect(find.text('PROJECTS'), findsNothing);
      expect(find.text('Projects'), findsNothing);
      expect(find.byIcon(Icons.horizontal_rule), findsNothing);
      // Only the sidebar's own structural Divider remains.
      expect(find.byType(Divider), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    // --- 6/7/8: header count, no id substitution, empty children ------------

    testWidgets('6. a count rides on the header and adds no phantom child row',
        (tester) async {
      await _pump(tester, navItems: [_aurora(initiallyExpanded: true)]);
      expect(find.byIcon(Icons.chat_bubble_outline), findsNWidgets(2));

      await _pump(
        tester,
        navItems: [_aurora(initiallyExpanded: true, badge: '2')],
      );

      expect(find.text('2'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsNWidgets(2),
          reason: 'the badge must not become a third child row');
      expect(find.text('Kickoff notes'), findsOneWidget);
      expect(find.text('Retro'), findsOneWidget);
    });

    testWidgets('7. tapping the header reports the GROUP id, never a child id',
        (tester) async {
      final fired = <String>[];
      await _pump(tester, navItems: [_aurora()], onNavChanged: fired.add);

      await tester.tap(find.text('Aurora'));
      await tester.pumpAndSettle();

      expect(fired, ['proj-aurora']);
      expect(fired, isNot(contains('conv-kickoff')));

      // And a child still reports itself once disclosed.
      await tester.tap(find.text('Retro'));
      await tester.pumpAndSettle();
      expect(fired, ['proj-aurora', 'conv-retro']);
    });

    testWidgets('8. an expandable group with no children is harmless',
        (tester) async {
      final fired = <String>[];
      await _pump(
        tester,
        navItems: const [
          EdenNavItem(
            id: 'projects',
            label: 'Projects',
            icon: Icons.folder_outlined,
            expandable: true,
          ),
        ],
        onNavChanged: fired.add,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Projects'), findsOneWidget);
      // DECISION: the chevron is ABSENT, not inert. No children means no
      // disclosure, so the item renders exactly as a leaf does today — which is
      // also what aodex needs for PROJECTS on a fresh account (BCP-R8).
      expect(find.byIcon(Icons.keyboard_arrow_right), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);

      await tester.tap(find.text('Projects'));
      expect(fired, ['projects']);
    });

    // --- 21: closing is a tidy-up, not a navigation --------------------------

    testWidgets(
        '21. only the EXPAND half of the toggle reports; closing keeps the user put',
        (tester) async {
      final fired = <String>[];
      await _pump(tester, navItems: [_aurora()], onNavChanged: fired.add);

      // Open: the documented requirement — a consumer scopes on the same tap
      // that discloses (aodex's PROJECTS header).
      await tester.tap(find.text('Aurora'));
      await tester.pumpAndSettle();
      expect(fired, ['proj-aurora']);

      // Close: the user is tidying the sidebar, not asking to go anywhere.
      await tester.tap(find.text('Aurora'));
      await tester.pumpAndSettle();
      expect(find.text('Kickoff notes'), findsNothing, reason: 'it did close');
      expect(fired, ['proj-aurora'],
          reason: 'closing a group must not navigate away from wherever the '
              'user currently is');

      // Re-open reports again — the expand half is not one-shot.
      await tester.tap(find.text('Aurora'));
      await tester.pumpAndSettle();
      expect(fired, ['proj-aurora', 'proj-aurora']);
    });

    testWidgets(
        '21b. a group that starts open reports nothing on the tap that closes it',
        (tester) async {
      final fired = <String>[];
      await _pump(
        tester,
        navItems: [_aurora(initiallyExpanded: true)],
        onNavChanged: fired.add,
      );

      await tester.tap(find.text('Aurora'));
      await tester.pumpAndSettle();

      expect(find.text('Kickoff notes'), findsNothing);
      expect(fired, isEmpty,
          reason: 'the very first gesture on a seeded-open group is a close');
    });

    // --- 22: geometry. Widget tests cannot SEE this, so assert the numbers ---

    testWidgets(
        '22. children of an expanded group are indented at least to their header',
        (tester) async {
      await _pump(tester, navItems: [_aurora(initiallyExpanded: true)]);

      final headerIconDx =
          tester.getTopLeft(find.byIcon(Icons.folder_outlined)).dx;
      final childIconDx =
          tester.getTopLeft(find.byIcon(Icons.chat_bubble_outline).first).dx;
      final headerLabelDx = tester.getTopLeft(find.text('Aurora')).dx;
      final childLabelDx = tester.getTopLeft(find.text('Kickoff notes')).dx;

      // The header sits behind a 4px pad + an 18px chevron + a 4px gap, so its
      // icon starts at 38 inside a sidebar whose ListView pads by 12.
      expect(headerIconDx, 38.0, reason: 'header geometry is the baseline');
      expect(headerLabelDx, 70.0);

      // The defect: children were laid out at the plain _NavTile inset (24/56),
      // LESS than their own header, so an expanded group read as a heading
      // followed by unrelated top-level rows.
      expect(childIconDx, greaterThanOrEqualTo(headerIconDx),
          reason: 'a child must never start left of its own header');
      expect(childLabelDx, greaterThanOrEqualTo(headerLabelDx));
      expect(childIconDx, 38.0);
      expect(childLabelDx, 70.0);

      // Both children, not just the first.
      expect(tester.getTopLeft(find.byIcon(Icons.chat_bubble_outline).last).dx,
          38.0);
    });

    testWidgets(
        '22b. a group that did NOT opt in keeps its exact original geometry',
        (tester) async {
      // The indent is a property of the disclosure, not of grouping. Additivity
      // is a number here too.
      await _pump(tester, navItems: [_workspace]);

      expect(tester.getTopLeft(find.byIcon(Icons.inbox_outlined)).dx, 24.0);
      expect(tester.getTopLeft(find.text('Inbox')).dx, 56.0);
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
