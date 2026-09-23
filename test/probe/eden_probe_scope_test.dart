// EdenProbeScope -- disables animations under EDEN_PROBE, inert without it.
//
// Cases 1 and 2 each carry their own negative control: the same surface
// WITHOUT the scope, asserted to still need more than one frame. A case
// without its control cannot tell "animations disabled" from "this
// animation was always one frame" -- memory
// scaffold-fab-exit-animation-widget-test is the FAB's control, inverted.
library;

import 'package:eden_ui_flutter/probe.dart';
import 'package:eden_ui_flutter/src/probe/eden_probe_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '_fixtures/animated_surfaces.dart';

/// The single timed pump this TRD's "settles in one frame" claim is
/// measured over: comfortably longer than a scaled (~5% of 200-450ms, so
/// 10-25ms) FAB/route duration, comfortably shorter than the real
/// (200-450ms) one.
const Duration _settleWindow = Duration(milliseconds: 50);

/// Advances past an interaction (FAB removal / route push) far enough to
/// observe whether it settled.
///
/// The two leading zero-duration `pump()`s are a MECHANICAL fact of
/// Flutter's own frame scheduling, identical with or without the scope: a
/// freshly-`.reverse()`d / freshly-pushed `AnimationController`'s ticker
/// reports NO elapsed progress until the frame after the one that started
/// it (proven empirically -- a single `pump(duration)` call, however long,
/// leaves a just-started controller at its initial value), and
/// `Navigator.push` mounts the new route's subtree one frame after that.
/// Only the FINAL, time-advancing pump is where the scope's
/// `disableAnimations` knob changes the outcome.
Future<void> _pumpPastInteraction(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(_settleWindow);
}

/// Wraps [child] in the testable [buildProbeScope] via a [Builder], since
/// [EdenProbeScope] itself always calls it with the compile-time
/// [kEdenProbe] (false under `flutter test`) and case 3 needs to observe
/// that split.
Widget _scoped(Widget child, {required bool enabled}) {
  return Builder(
    builder: (context) => buildProbeScope(context, child, enabled: enabled),
  );
}

void main() {
  // `debugSemanticsDisableAnimations` is process-global (the only
  // non-instance override this Flutter generation exposes -- see the
  // MECHANISM CAVEAT in eden_probe_scope.dart). Reset it after every test so
  // an `enabled: true` case cannot leak fast animations into a later
  // control.
  tearDown(() {
    debugSemanticsDisableAnimations = null;
  });

  group('case 1: FAB removal', () {
    testWidgets(
      'CONTROL: without the scope, one frame leaves the FAB present after removal',
      (WidgetTester tester) async {
        final GlobalKey<FabRemovalSurfaceState> stateKey =
            GlobalKey<FabRemovalSurfaceState>();
        await tester
            .pumpWidget(MaterialApp(home: FabRemovalSurface(key: stateKey)));
        expect(find.byKey(fabRemovalFabKey), findsOneWidget);

        stateKey.currentState!.removeFab();
        await _pumpPastInteraction(tester);

        expect(
          find.byKey(fabRemovalFabKey),
          findsOneWidget,
          reason: 'the FAB exit animation is 200ms; a 50ms settle window '
              'should not have completed it -- this is the '
              'scaffold-fab-exit-animation-widget-test trap, asserted here '
              'as the control',
        );
      },
    );

    testWidgets(
      'WITH EdenProbeScope, one frame is enough for the FAB to be gone',
      (WidgetTester tester) async {
        final GlobalKey<FabRemovalSurfaceState> stateKey =
            GlobalKey<FabRemovalSurfaceState>();
        await tester.pumpWidget(MaterialApp(
          home: _scoped(FabRemovalSurface(key: stateKey), enabled: true),
        ));
        expect(find.byKey(fabRemovalFabKey), findsOneWidget);

        stateKey.currentState!.removeFab();
        await _pumpPastInteraction(tester);

        expect(find.byKey(fabRemovalFabKey), findsNothing);
      },
    );
  });

  group('case 2: route push', () {
    testWidgets(
      'CONTROL: without the scope, one frame leaves the pushed route mid-transition',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: PushedRouteSurface()));
        await tester.tap(find.byKey(pushedRouteButtonKey));
        await _pumpPastInteraction(tester);

        final BuildContext pushed =
            tester.element(find.byKey(pushedRouteMarkerKey));
        final ModalRoute<void> route = ModalRoute.of(pushed)!;
        expect(
          route.animation!.status,
          isNot(AnimationStatus.completed),
          reason: 'the push transition is not one-frame long by default; '
              'this is the control',
        );
      },
    );

    testWidgets(
      'WITH EdenProbeScope, one frame settles the pushed route',
      (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: _scoped(const PushedRouteSurface(), enabled: true),
        ));
        await tester.tap(find.byKey(pushedRouteButtonKey));
        await _pumpPastInteraction(tester);

        final BuildContext pushed =
            tester.element(find.byKey(pushedRouteMarkerKey));
        final ModalRoute<void> route = ModalRoute.of(pushed)!;
        expect(route.animation!.status, AnimationStatus.completed);
      },
    );
  });

  testWidgets(
    'case 3: inert without the define -- MediaQuery.disableAnimations stays false',
    (WidgetTester tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(MaterialApp(
        home: EdenProbeScope(
          child: Builder(builder: (context) {
            capturedContext = context;
            return const SizedBox();
          }),
        ),
      ));

      expect(kEdenProbe, isFalse,
          reason: 'the default under flutter test and every production '
              'build -- this case is only meaningful while that holds');
      expect(MediaQuery.of(capturedContext).disableAnimations, isFalse);
    },
  );

  testWidgets(
    'case 4: child passthrough -- no layout change when inert',
    (WidgetTester tester) async {
      const Key childKey = ValueKey<String>('probe-passthrough-child');

      await tester.pumpWidget(const MaterialApp(
        home: SizedBox(key: childKey, width: 120, height: 40),
      ));
      final Rect withoutScope = tester.getRect(find.byKey(childKey));

      await tester.pumpWidget(MaterialApp(
        home: _scoped(
          const SizedBox(key: childKey, width: 120, height: 40),
          enabled: false,
        ),
      ));
      final Rect withScope = tester.getRect(find.byKey(childKey));

      expect(withScope, withoutScope);
    },
  );

  group('case 5: bundled fonts under probe', () {
    tearDown(() {
      // The package default -- Objective 022's runtime-font capability
      // depends on fetching staying on outside the probe path.
      GoogleFonts.config.allowRuntimeFetching = true;
    });

    testWidgets(
      'enabled: true turns GoogleFonts.config.allowRuntimeFetching off',
      (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: _scoped(const SizedBox(), enabled: true),
        ));

        expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
      },
    );

    testWidgets(
      'enabled: false leaves GoogleFonts.config.allowRuntimeFetching untouched',
      (WidgetTester tester) async {
        GoogleFonts.config.allowRuntimeFetching = true;

        await tester.pumpWidget(MaterialApp(
          home: _scoped(const SizedBox(), enabled: false),
        ));

        expect(GoogleFonts.config.allowRuntimeFetching, isTrue);
      },
    );

    testWidgets(
      'a runtime fetch attempt under the define fails loudly with the family name',
      (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: _scoped(const SizedBox(), enabled: true),
        ));
        expect(GoogleFonts.config.allowRuntimeFetching, isFalse);

        // The package's font path: Typography.displayFont / EdenTheme's
        // displayLarge both resolve through GoogleFonts.outfit(). A weight
        // not used anywhere else in this package (w300) keeps this test's
        // font+variant cache key from colliding with anything another test
        // in this FILE already loaded -- google_fonts' loaded-font set is
        // process-global.
        final TextStyle style = GoogleFonts.outfit(fontWeight: FontWeight.w300);
        expect(style.fontFamily, isNotNull,
            reason: 'GoogleFonts.getFont resolves the TextStyle '
                'synchronously and never throws here -- only the '
                'background load, awaited below, fails');

        await expectLater(
          GoogleFonts.pendingFonts(),
          throwsA(
            isA<Exception>().having(
              (Exception e) => e.toString(),
              'message naming the family',
              contains('Outfit'),
            ),
          ),
        );
      },
    );
  });
}
