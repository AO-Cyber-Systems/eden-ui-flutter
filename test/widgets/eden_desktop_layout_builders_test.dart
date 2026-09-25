// Composition slots on EdenDesktopLayout — TRD 23-06 Task 1, cases 6-9.
//
// The point of these cases is that a consumer expresses new rail behaviour
// WITHOUT a library change and a pin bump: it passes an `itemBuilder` /
// `sectionBuilder` instead of waiting for another flag on `EdenNavItem`.
//
// The back-compat proof for "a consumer that passes no builders renders
// unchanged" lives in test/widgets/eden_desktop_layout_test.dart, which must
// stay byte-unmodified.
import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

// --- hand-built fixtures (no generated data) -------------------------------

const _home = EdenNavItem(id: 'home', label: 'Home', icon: Icons.home);
const _settings =
    EdenNavItem(id: 'settings', label: 'Settings', icon: Icons.settings);

List<EdenNavItem> _twoLeaves() => const [_home, _settings];

Widget _host(Widget layout) => MaterialApp(home: layout);

void main() {
  group('EdenDesktopLayout composition slots', () {
    testWidgets(
        'case 6: itemBuilder replaces ONE item and leaves the others on the '
        'default renderer', (tester) async {
      await tester.pumpWidget(_host(EdenDesktopLayout(
        navItems: _twoLeaves(),
        selectedId: 'home',
        onNavChanged: (_) {},
        body: const Text('Body'),
        itemBuilder: (context, item, state) {
          if (item.id != 'settings') return null;
          return const Text('CUSTOM SETTINGS ROW');
        },
      )));
      await tester.pumpAndSettle();

      // The consumer's widget replaced exactly that one row...
      expect(find.text('CUSTOM SETTINGS ROW'), findsOneWidget);
      expect(find.text('Settings'), findsNothing);

      // ...and the untouched item still renders through the default builder,
      // icon and all.
      expect(find.text('Home'), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets(
        'case 7: a builder that returns a bare Text still carries the '
        'eden-nav-<id> identifier — the builder cannot bypass it',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(EdenDesktopLayout(
        navItems: _twoLeaves(),
        selectedId: 'home',
        onNavChanged: (_) {},
        body: const Text('Body'),
        itemBuilder: (context, item, state) => item.id == 'settings'
            // Deliberately naked: no Semantics, no button, no identifier.
            ? const Text('bare')
            : null,
      )));
      await tester.pumpAndSettle();

      // The E2E tooling in aodex and eden-biz keys off exactly this string.
      expect(
        find.bySemanticsIdentifier('eden-nav-settings'),
        findsOneWidget,
        reason: 'the layout applies the identifier OUTSIDE the builder result',
      );
      // ...and the default path publishes exactly one too — same wrapper.
      expect(find.bySemanticsIdentifier('eden-nav-home'), findsOneWidget);
      handle.dispose();
    });

    testWidgets(
        'case 8: sectionBuilder replaces a caption while isDivider still '
        'renders the default divider', (tester) async {
      await tester.pumpWidget(_host(EdenDesktopLayout(
        navItems: const [
          EdenNavItem.caption('Workspace'),
          EdenNavItem.divider(),
          _home,
        ],
        selectedId: 'home',
        onNavChanged: (_) {},
        body: const Text('Body'),
        sectionBuilder: (context, item) =>
            item.isCaption ? const Text('CUSTOM CAPTION') : null,
      )));
      await tester.pumpAndSettle();

      expect(find.text('CUSTOM CAPTION'), findsOneWidget);
      expect(find.text('WORKSPACE'), findsNothing);
      // The divider flag still renders through the DEFAULT section renderer.
      expect(find.byType(Divider), findsWidgets);
      // And an ordinary item is untouched by a sectionBuilder.
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets(
        'case 9: with NO builders supplied, every rail row publishes exactly '
        'one semantics node carrying its identifier', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(EdenDesktopLayout(
        navItems: _twoLeaves(),
        selectedId: 'home',
        onNavChanged: (_) {},
        body: const Text('Body'),
      )));
      await tester.pumpAndSettle();

      for (final id in const ['home', 'settings']) {
        expect(
          find.bySemanticsIdentifier('eden-nav-$id'),
          findsOneWidget,
          reason: 'one node per row — never a nested pair (finding F5)',
        );
      }
      // The row is still announced as a selectable, tappable button carrying
      // its label — the annotations that used to live inside _NavTile, now
      // published once at the emission point.
      //
      // (The label reads 'Home\nHome': the wrapper's own label plus the child
      // Text merging up. That is PRE-EXISTING — the old tree was the same
      // Semantics-over-GestureDetector-over-Text shape — and is asserted here
      // rather than tidied, so a future change that alters it is visible.)
      final node = tester.getSemantics(
        find.bySemanticsIdentifier('eden-nav-home'),
      );
      expect(node.identifier, 'eden-nav-home');
      expect(node.label, 'Home\nHome');
      final data = node.getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isSelected.name, 'isTrue');
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });
  });
}
