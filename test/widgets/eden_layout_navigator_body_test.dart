// test/widgets/eden_layout_navigator_body_test.dart
//
// TRD 23-06 — regression test for eden-ui-flutter#33.
//
// `EdenDesktopLayout` / `EdenMobileLayout` used to default `selectableBody` to
// TRUE, which wraps [body] in an `EdenSelectableRegion` (a `SelectionArea`).
// Every go_router shell app puts a Navigator in [body]. When such an app is
// deep-linked straight into a NESTED route, the Navigator seeds more than one
// route at once and the covered page underneath is never laid out. The
// SelectionArea then walks its registered selectables to order them on screen,
// and `_compareScreenOrder` calls `getTransformTo` on that never-laid-out
// render object — which asserts.
//
// Upstream: flutter#151536. The fix, flutter#184900, is UNMERGED.
// Measured downstream in aodex#611: six routing tests red; aodex took the
// `selectableBody: false` opt-out by hand.
//
// ## Where the differential control lives, and why it is not a test here
//
// These cases HAVE been seen to fail. Before the default was flipped, all of
// them failed on this exact tree with the real upstream assertion, exit 1:
//
//   RenderBox was not laid out: RenderFractionalTranslation#f3390
//     NEEDS-LAYOUT NEEDS-PAINT
//   'package:flutter/src/rendering/box.dart':
//   Failed assertion: line 2251 pos 12: 'hasSize'
//     #4  RenderObject.getTransformTo (rendering/object.dart:3579)
//     #5  _SelectionContainerState.getTransformTo (selection_container.dart:208)
//     #6  MultiSelectableSelectionContainerDelegate._compareScreenOrder
//         (widgets/selectable_region.dart:2566)
//
// To re-run that control by hand: set `selectableBody = true` back in BOTH
// layout constructors and run this file — it must go red with the trace above.
//
// A `selectableBody: true` + Navigator-body case CANNOT be written as a passing
// test: the assertion is raised in a microtask, FakeAsync hands it to the test
// zone's uncaught-error handler, and `TestWidgetsFlutterBinding` fails the test
// outright. It is reachable by neither `try/catch` (both were measured: the
// catch never fires) nor `tester.takeException()` (returns null — the test body
// has already been aborted), and overriding `FlutterError.onError` to swallow
// it trips `binding.dart:1641 '_pendingExceptionDetails != null'`. So the
// in-suite control is STRUCTURAL instead: the third case below asserts there is
// no `SelectableRegion` over the Navigator, which is the precondition
// flutter#151536 needs, and it goes red the moment the default is flipped back.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const navItems = <EdenNavItem>[
    EdenNavItem(id: 'home', label: 'Home', icon: Icons.home),
    EdenNavItem(id: 'settings', label: 'Settings', icon: Icons.settings),
  ];

  /// A shell body shaped like a go_router shell: a nested [Navigator] seeded
  /// straight at a nested route, so `/` and `/a` are pushed UNDER `/a/b` and
  /// never laid out. Hand-built, not generated — the route table is three
  /// named routes and nothing else.
  Widget navigatorBody() => Navigator(
        initialRoute: '/a/b',
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(child: Text('route ${settings.name}')),
          ),
        ),
      );

  /// `selectableBody` is OMITTED on purpose — these probe the declared default.
  Widget desktop() => MaterialApp(
        home: EdenDesktopLayout(
          navItems: navItems,
          selectedId: 'home',
          onNavChanged: (_) {},
          body: navigatorBody(),
        ),
      );

  /// `selectableBody` is OMITTED on purpose — these probe the declared default.
  Widget mobile() => MaterialApp(
        home: EdenMobileLayout(
          navItems: navItems,
          selectedId: 'home',
          onNavChanged: (_) {},
          body: navigatorBody(),
        ),
      );

  /// Pumps [app] and returns whatever blew up, or null.
  ///
  /// The flutter#151536 assertion is raised in a microtask that `FakeAsync`
  /// re-throws SYNCHRONOUSLY out of `tester.pump`, so it never lands in the
  /// binding's pending-exception slot and `tester.takeException()` returns
  /// null for it. Catching it here is the only way to assert on it; both
  /// sources are drained so the helper is honest whichever route it takes.
  Future<Object?> pumpAndCatch(WidgetTester tester, Widget app) async {
    Object? caught;
    try {
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
    } catch (e) {
      caught = e;
    }
    return caught ?? tester.takeException();
  }

  group('EdenDesktopLayout with a Navigator body (eden-ui-flutter#33)', () {
    testWidgets('deep-link into a nested route does not assert, by default',
        (tester) async {
      expect(await pumpAndCatch(tester, desktop()), isNull,
          reason: 'selectableBody is opt-in, so no SelectionArea wraps the '
              'Navigator and flutter#151536 cannot fire');
      expect(find.text('route /a/b'), findsOneWidget,
          reason: 'the deep-linked nested route really did render — otherwise '
              'the no-exception assertion above proves nothing');
    });

    testWidgets('STRUCTURAL CONTROL: no SelectableRegion sits over the body',
        (tester) async {
      expect(await pumpAndCatch(tester, desktop()), isNull);

      expect(find.byType(SelectableRegion), findsNothing,
          reason: 'a SelectableRegion ANCESTOR of the Navigator is exactly the '
              'precondition flutter#151536 needs. This is the differential '
              'control: flip selectableBody back to true and this goes red '
              'before the assertion above even gets a chance to.');
      expect(
        find.ancestor(
          of: find.byType(Navigator).last,
          matching: find.byType(SelectableRegion),
        ),
        findsNothing,
      );
    });
  });

  group('EdenMobileLayout with a Navigator body (eden-ui-flutter#33)', () {
    testWidgets('deep-link into a nested route does not assert, by default',
        (tester) async {
      expect(await pumpAndCatch(tester, mobile()), isNull,
          reason: 'selectableBody is opt-in on the mobile layout too');
      expect(find.text('route /a/b'), findsOneWidget,
          reason: 'the deep-linked nested route really did render');
    });

    testWidgets('STRUCTURAL CONTROL: no SelectableRegion sits over the body',
        (tester) async {
      expect(await pumpAndCatch(tester, mobile()), isNull);

      expect(find.byType(SelectableRegion), findsNothing,
          reason: 'the mobile layout shares the exposure: one SelectableRegion '
              'over a Navigator body');
    });
  });
}
