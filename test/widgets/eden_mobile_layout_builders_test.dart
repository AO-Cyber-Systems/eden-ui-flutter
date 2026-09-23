// Composition slots on EdenMobileLayout — TRD 23-06 Task 1 (mobile half),
// cases 10 and 11.
//
// Case 10 pins today's rule: the bottom bar is a list of DESTINATIONS, so the
// rail's decorations (captions, dividers) never reach it. Case 11 pins that
// the rule belongs to the LAYOUT, not to the renderer — supplying a consumer
// `itemBuilder` must not smuggle a caption or a divider into the bar.
//
// The desktop half of these slots lives in
// test/widgets/eden_desktop_layout_builders_test.dart (cases 6-9); the
// back-compat proof for "no builders renders unchanged" lives in
// test/widgets/eden_mobile_layout_test.dart, which stays byte-unmodified.
import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// --- hand-built fixtures (no generated data) -------------------------------

const _home = EdenNavItem(id: 'home', label: 'Home', icon: Icons.home);
const _reports =
    EdenNavItem(id: 'reports', label: 'Reports', icon: Icons.bar_chart);

/// A rail list shaped the way a consumer really writes one: a caption band, a
/// rule, and two real destinations. Both layouts are handed the SAME list.
List<EdenNavItem> _decoratedRail() => const [
      EdenNavItem.caption('Workspace'),
      _home,
      EdenNavItem.divider(),
      _reports,
    ];

Widget _host(Widget layout) => MaterialApp(home: layout);

void main() {
  group('EdenMobileLayout bottom bar excludes decorations', () {
    testWidgets(
        'case 10: with DEFAULT builders the bar renders no caption and no '
        'divider — only destinations', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(EdenMobileLayout(
        navItems: _decoratedRail(),
        selectedId: 'home',
        onNavChanged: (_) {},
        body: const Text('Body'),
      )));
      await tester.pumpAndSettle();

      // The two real destinations are in the bar, once each, each publishing
      // its own eden-nav-<id> node.
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.bySemanticsIdentifier('eden-nav-home'), findsOneWidget);
      expect(find.bySemanticsIdentifier('eden-nav-reports'), findsOneWidget);

      // The decorations reached neither the bar's labels nor its semantics.
      // Their ids match nothing a consumer can navigate to, so a tab built
      // from one fires onNavChanged with a dead id AND eats a bar slot.
      expect(find.text('Workspace'), findsNothing);
      expect(find.text('WORKSPACE'), findsNothing);
      expect(find.byType(Divider), findsNothing);
      expect(
        find.bySemanticsIdentifier('eden-nav-__caption__'),
        findsNothing,
        reason: 'a caption is a rail decoration, never a bottom-bar tab',
      );
      expect(
        find.bySemanticsIdentifier('eden-nav-__divider__'),
        findsNothing,
        reason: 'a divider is a rail decoration, never a bottom-bar tab',
      );
      handle.dispose();
    });

    testWidgets(
        'case 11: the exclusion is the LAYOUT\'s rule — a consumer itemBuilder '
        'is never offered a caption or a divider', (tester) async {
      final handle = tester.ensureSemantics();
      final offeredIds = <String>[];

      await tester.pumpWidget(_host(EdenMobileLayout(
        navItems: _decoratedRail(),
        selectedId: 'home',
        onNavChanged: (_) {},
        body: const Text('Body'),
        itemBuilder: (context, item, state) {
          offeredIds.add(item.id);
          // Deliberately naked: no Semantics, no identifier, no icon. If the
          // layout let a decoration through, this would render it as a tab.
          return Text('CUSTOM ${item.id}');
        },
      )));
      await tester.pumpAndSettle();

      // The builder saw the destinations and ONLY the destinations.
      expect(offeredIds, const ['home', 'reports']);

      // The consumer's widget really did render for both...
      expect(find.text('CUSTOM home'), findsOneWidget);
      expect(find.text('CUSTOM reports'), findsOneWidget);

      // ...and the identifier is still applied OUTSIDE the builder's result,
      // so the aodex / eden-biz E2E flows keep working whatever it returned.
      expect(find.bySemanticsIdentifier('eden-nav-home'), findsOneWidget);
      expect(find.bySemanticsIdentifier('eden-nav-reports'), findsOneWidget);

      // No decoration leaked in under the consumer builder either.
      expect(find.text('CUSTOM __caption__'), findsNothing);
      expect(find.text('CUSTOM __divider__'), findsNothing);
      expect(find.byType(Divider), findsNothing);
      handle.dispose();
    });
  });
}
