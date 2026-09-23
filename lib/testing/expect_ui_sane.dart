/// The UI Oracle's single callable assertion.
///
/// TEST-ONLY. This library imports `package:flutter_test` and must be imported
/// from a consumer's `test/` directory only, via the public entry point:
///
/// ```dart
/// import 'package:eden_ui_flutter/testing.dart';
/// ```
///
/// Importing it from production code pulls `flutter_test` into the release
/// graph and breaks the build. Nothing in `lib/eden_ui.dart` or `lib/src/`
/// references it, and a grep gate in TRD 23-02 keeps it that way.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
// `flutter_test` is a dev_dependency and is imported here DELIBERATELY — see
// the note in semantics_geometry.dart.
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';

import '../src/a11y/eden_input_modality.dart';
import 'semantics_geometry.dart';

/// Re-exported so a test that imports only
/// `package:eden_ui_flutter/testing.dart` can name the modality it is
/// declaring. The enum itself lives outside `lib/testing/` because
/// production code (EdenStory) declares it too, and this library imports
/// `package:flutter_test`.
export '../src/a11y/eden_input_modality.dart';

/// WCAG 2.5.8 Target Size (Minimum), AA: 24x24 CSS px.
///
/// Built from `flutter_test`'s own public [MinimumTapTargetGuideline] rather
/// than a hand-rolled traversal, so the pointer path inherits every exemption
/// the stock guidelines already encode (merged nodes, nodes at a scrollable's
/// boundary, device-pixel-ratio scaling) and the failure message reads
/// identically to the touch path's.
const AccessibilityGuideline wcagMinimumTargetSizeGuideline =
    MinimumTapTargetGuideline(
  size: Size(24, 24),
  link: 'https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html',
);

/// Asserts that the surface currently pumped into [tester] is not visibly
/// broken, and fails NAMING the offending widget when it is.
///
/// Add one line after the final pump of an existing screen test, declaring
/// what the surface is driven with:
///
/// ```dart
/// await tester.pumpWidget(const MyScreen());
/// await tester.pumpAndSettle();
/// await expectUiSane(tester, inputModality: EdenInputModality.touch);
/// ```
///
/// [inputModality] defaults to [EdenInputModality.touch] — the stricter floor —
/// so that omitting it can only ever be safe. Pass it explicitly anyway: the
/// standard a surface is held to should be readable at the assertion, not
/// inherited from a default. See [EdenInputModality] for why the floor is
/// conditional at all.
///
/// Checks, in order:
///
/// 1. **No escaped exception.** A `RenderFlex overflowed by N pixels` is
///    reported through `FlutterError` during layout/paint, not thrown at the
///    call site, so a screen test can be green while the screen is visibly
///    broken. `tester.takeException()` is called EXACTLY ONCE here; a second
///    call anywhere returns null and the overflow disappears.
/// 2. **Viewport containment.** Every identified control's semantics rect lies
///    inside the view.
/// 3. **Disjointness.** No two identified controls' rects intersect. On web the
///    semantics node — not the widget — receives the click, so an overlap means
///    one control silently eats the other's taps. [allowOverlap] lists the
///    identifiers permitted to intersect (a deliberate overlay, a badge sitting
///    on its host); it is the escape hatch that makes adoption across 600+
///    consumer screens possible without editing the screens.
/// 4. **Exactly one WORKING tap action per control that announces one.** The
///    rule is two-sided, and the lower bound is the one that matters: an
///    oracle that is silent on zero goes GREEN on a surface whose controls are
///    all dead, and reports FEWER violations the more broken the surface is.
///    A control that declares `tap` on its own node AND again on a
///    non-identified descendant fires twice; a control that announces
///    `button: true` (or `link: true`) with NO tap route announces an
///    affordance that does not exist; and a control whose single tap route no
///    pointer can reach — `IgnorePointer` blocks the subtree's hit test while
///    leaving the outer node's action in place — is inert to a real finger
///    even though the count reads a healthy 1. Nodes that announce no
///    affordance are exempt: a caption band carries an identifier and nothing
///    to activate, and the top-bar search announces `textField: true`, whose
///    affordance is focus, not tap.
/// 5. **Accessibility guidelines.** `labeledTapTargetGuideline`,
///    `textContrastGuideline`, and a tap-target floor chosen by
///    [inputModality]: WCAG 2.5.8's 24x24 for [EdenInputModality.pointer],
///    `androidTapTargetGuideline` (48px) + `iOSTapTargetGuideline` (44px) for
///    [EdenInputModality.touch]. Each failure is folded into the same
///    aggregated report, prefixed with the guideline's name.
///
/// Violations are AGGREGATED: one run lists everything wrong with the surface,
/// so a consumer fixing a screen does not play whack-a-mole.
///
/// A surface with no identified controls is not a failure — it has nothing to
/// check. `expectUiSane` must be adoptable without a triage backlog.
///
/// Note on `container: true`: a nested `Semantics` WITHOUT `container: true` is
/// not published as its own node at all (Flutter 3.41.9; pinned by TRD 23-01
/// case 7). Its identifier vanishes and the enclosing node's identifier wins,
/// so this oracle cannot see it. Give every control you want checked
/// `container: true`.
Future<void> expectUiSane(
  WidgetTester tester, {
  EdenInputModality inputModality = EdenInputModality.touch,
  Set<String> allowOverlap = const <String>{},
}) async {
  final List<String> violations = <String>[];

  // (1) Exactly one takeException() call. Keep the value and re-report it.
  final Object? escaped = tester.takeException();
  if (escaped != null) {
    violations.add(_describeEscapedException(tester, escaped));
  }

  // The handle is disposed in a `finally` before returning, NOT via
  // addTearDown: flutter_test verifies handle disposal BEFORE addTearDown
  // callbacks run (TRD 23-01, Deviation 1).
  final SemanticsHandle handle = tester.ensureSemantics();
  try {
    final List<SemanticsGeometryNode> nodes = identifiedNodes(tester);

    violations.addAll(_viewportViolations(tester, nodes));
    violations.addAll(_overlapViolations(nodes, allowOverlap));
    violations.addAll(_tapRouteViolations(tester, nodes));
    violations.addAll(await _guidelineViolations(tester, inputModality));
  } finally {
    handle.dispose();
  }

  if (violations.isNotEmpty) {
    throw TestFailure(
      'expectUiSane found ${violations.length} violation(s) on this surface:\n'
      '${violations.map((String v) => '  - $v').join('\n')}',
    );
  }
}

// -----------------------------------------------------------------------------
// Checks
// -----------------------------------------------------------------------------

String _describeEscapedException(WidgetTester tester, Object escaped) {
  final String text = escaped.toString();
  final RegExp overflow = RegExp(
    r'A (\w+) overflowed by ([\d.]+) pixels on the (\w+)',
  );
  final RegExpMatch? match = overflow.firstMatch(text);
  if (match == null) {
    return 'an exception escaped during layout/paint: $text';
  }

  // CRITICAL: the exception itself is ONLY the summary line. The creator chain
  // that names the offending widget lives in the FlutterErrorDetails'
  // `informationCollector`, which `tester.takeException()` throws away — so a
  // naive re-report says "A RenderFlex overflowed by 215 pixels" and never
  // tells the consumer WHICH Row. Recover the name from the render tree
  // instead: RenderFlex.toStringShort() appends ' OVERFLOWING' while it is
  // overflowing, so the element that owns it can be found and asked for its
  // creator chain.
  final List<String> culprits = _overflowingCreatorChains(tester);
  final String named = culprits.isEmpty
      ? 'the overflowing render object could not be located in the tree'
      : culprits.map((String c) => '\n      $c').join();
  return '${match.group(1)} overflow of ${match.group(2)} pixels on the '
      '${match.group(3)}. Offending widget(s):$named';
}

/// Creator chains of every render object currently reporting an overflow.
///
/// Dedupes by render object and keeps the DEEPEST element that owns it —
/// `Element.renderObject` walks down to the nearest descendant render object,
/// so a whole stack of ancestor elements answers the same RenderFlex.
List<String> _overflowingCreatorChains(WidgetTester tester) {
  final Map<RenderObject, String> byRenderObject = <RenderObject, String>{};

  void visit(Element element) {
    final RenderObject? renderObject = element.renderObject;
    if (renderObject != null &&
        renderObject.toStringShort().contains('OVERFLOWING')) {
      byRenderObject[renderObject] = element.debugGetCreatorChain(6);
    }
    element.visitChildren(visit);
  }

  tester.binding.rootElement?.visitChildren(visit);
  return byRenderObject.values.toList();
}

/// The guidelines that hold on EVERY surface, whatever drives it.
///
/// GOTCHA: `textContrastGuideline` silently PASSES on a region it cannot
/// resolve a background for (a transparent or single-colour area). A
/// contrast fixture must use opaque colours or the check proves nothing.
const List<AccessibilityGuideline> _modalityIndependentGuidelines =
    <AccessibilityGuideline>[
  labeledTapTargetGuideline,
  textContrastGuideline,
];

/// The tap-target floor for [modality]. There is exactly one arm per enum
/// value and no default arm — a new modality is a compile error here, not a
/// surface that silently gets no floor at all.
///
/// GOTCHA (touch): the Android floor is 48 and the iOS floor is 44. Both are
/// checked, deliberately — a 46px target is a real defect on Android, and
/// tuning a fixture to sit between the two floors would hide it.
List<AccessibilityGuideline> _tapTargetGuidelinesFor(
  EdenInputModality modality,
) =>
    switch (modality) {
      EdenInputModality.pointer => const <AccessibilityGuideline>[
          wcagMinimumTargetSizeGuideline,
        ],
      EdenInputModality.touch => const <AccessibilityGuideline>[
          androidTapTargetGuideline,
          iOSTapTargetGuideline,
        ],
    };

/// Runs the guideline matchers and folds each failure into the SAME aggregated
/// violation list as the geometry checks, prefixed with the guideline's name.
Future<List<String>> _guidelineViolations(
  WidgetTester tester,
  EdenInputModality inputModality,
) async {
  final List<String> out = <String>[];
  final List<AccessibilityGuideline> guidelines = <AccessibilityGuideline>[
    ..._tapTargetGuidelinesFor(inputModality),
    ..._modalityIndependentGuidelines,
  ];
  for (final AccessibilityGuideline guideline in guidelines) {
    try {
      await expectLater(tester, meetsGuideline(guideline));
    } on TestFailure catch (failure) {
      out.add('${guideline.description}: ${failure.message}');
    }
  }

  // WHY THE GUIDELINE PHASE NEEDS A FONT-CLEAN TEST ENVIRONMENT (was a KNOWN
  // LIMITATION; fixed by `test/flutter_test_config.dart`).
  //
  // `textContrastGuideline` captures the rendered image through
  // `tester.runAsync`, which lets futures that were ALREADY PENDING before
  // expectUiSane was called finally run. `EdenTheme` resolves its type scale
  // through google_fonts, which fires an unawaited font load at
  // theme-construction time; in a widget test that load cannot succeed on its
  // own, and google_fonts rethrows the failure down that unawaited future.
  // The resulting UNCAUGHT ASYNC error ends the test directly — it never
  // reaches `tester.takeException()`, so this helper cannot swallow it, and
  // flutter_test reinstalls `FlutterError.onError` per test so nothing else
  // can either.
  //
  // That is why a consumer repo MUST make the font load succeed offline
  // before this phase means anything. This package does it in
  // `test/flutter_test_config.dart`, which serves the Eden type families to
  // google_fonts from `test_support/fonts/`. Without an equivalent, an
  // EdenTheme surface fails here with a font error instead of a verdict.
  //
  // Anything the guideline phase DID route through the pending-exception
  // channel is reported here rather than discarded.
  Object? provoked = tester.takeException();
  while (provoked != null) {
    out.add(
      'an exception escaped while evaluating accessibility guidelines: '
      '$provoked',
    );
    provoked = tester.takeException();
  }

  return out;
}

List<String> _viewportViolations(
  WidgetTester tester,
  List<SemanticsGeometryNode> nodes,
) {
  final Size viewport =
      tester.view.physicalSize / tester.view.devicePixelRatio;
  final Rect viewportRect = Offset.zero & viewport;
  final List<String> out = <String>[];
  for (final SemanticsGeometryNode node in nodes) {
    final Rect r = node.globalRect;
    final bool inside = r.left >= viewportRect.left - _epsilon &&
        r.top >= viewportRect.top - _epsilon &&
        r.right <= viewportRect.right + _epsilon &&
        r.bottom <= viewportRect.bottom + _epsilon;
    if (!inside) {
      out.add(
        'control "${node.identifier}" is outside the viewport: its rect is $r, '
        'the viewport is $viewportRect',
      );
    }
  }
  return out;
}

List<String> _overlapViolations(
  List<SemanticsGeometryNode> nodes,
  Set<String> allowOverlap,
) {
  final List<String> out = <String>[];
  for (int i = 0; i < nodes.length; i++) {
    for (int j = i + 1; j < nodes.length; j++) {
      final SemanticsGeometryNode a = nodes[i];
      final SemanticsGeometryNode b = nodes[j];
      final String aId = a.identifier ?? '';
      final String bId = b.identifier ?? '';
      if (allowOverlap.contains(aId) || allowOverlap.contains(bId)) {
        continue;
      }
      if (rectsOverlap(a.globalRect, b.globalRect)) {
        out.add(
          'controls "$aId" and "$bId" overlap: "$aId" is ${a.globalRect}, '
          '"$bId" is ${b.globalRect}, they share '
          '${a.globalRect.intersect(b.globalRect)}. On web the semantics node '
          'is the click target, so one of these eats the other\'s taps. Pass '
          'allowOverlap: {\'$aId\'} if the overlap is deliberate.',
        );
      }
    }
  }
  return out;
}

// -----------------------------------------------------------------------------
// Tap routes: the rule is TWO-SIDED
// -----------------------------------------------------------------------------
//
// WHY THE LOWER BOUND EXISTS. This check used to fire only on `routes > 1` and
// was silent on zero. That made the instrument itself capable of a false
// green: replacing `ExcludeSemantics` with `IgnorePointer` in
// `EdenMobileLayout._navRow` killed all four bottom-nav buttons and the whole
// mobile-layout story oracle went GREEN — the contrast violation vanished too,
// because `textContrastGuideline` locates its paragraph by HIT TEST and a
// surface that takes no pointer offers nothing to hit. The oracle reported
// FEWER violations the more broken the surface was. An oracle that can go
// green on dead UI is worse than no oracle, because it is trusted.
//
// The measured mechanism, pinned here because it is counter-intuitive and it
// decides the shape of the rule (Flutter 3.41.9, `RenderIgnorePointer`):
//
//   * `hitTest` returns `!ignoring && super.hitTest(...)` — the subtree takes
//     no pointer at all; and
//   * `describeSemanticsConfiguration` sets `isBlockingUserActions`, which
//     strips the inner `GestureDetector`'s IMPLICIT tap route from the
//     published tree.
//
// So the outer `Semantics(onTap:)` survives and the route count reads exactly
// 1. The zero arm alone does NOT catch that case; reachability is what does.
// Both arms are kept because they are different defects: zero is "nothing was
// ever wired up", unreachable is "it was wired up and something in between
// eats the pointer".
//
// SCOPE — `button: true` or `link: true`, nothing else. Not every identified
// node is interactive. `EdenMobileLayout._navSection` publishes no identifier
// and no affordance flag by design, and `EdenDesktopLayout`'s top-bar search
// publishes `identifier: 'eden-topbar-search', textField: true` — a text
// field's affordance is focus, not tap, and reddening it would be the wrong
// rule. `toggled:`/`checked:` are deliberately OUT of scope: they annotate
// STATE rather than an affordance, every site in this library pairs them with
// `button: true` (eden_reaction_bar, eden_label_picker) or hands the route to
// an InkWell that owns it (eden_multi_select), and none of them publishes an
// identifier — so including them would add no coverage today and would redden
// a legitimately read-only checked row. `link: true` IS in scope: it has no
// site in `lib/src` today, but it is the same lie through the other flag, and
// it is executed by a fixture rather than merely asserted.

List<String> _tapRouteViolations(
  WidgetTester tester,
  List<SemanticsGeometryNode> nodes,
) {
  final SemanticsNode root = rootSemanticsNodeOf(tester);
  final Map<int, Rect> rectById = <int, Rect>{
    for (final SemanticsGeometryNode node in nodes) node.id: node.globalRect,
  };
  final Map<int, RenderObject> ownerById = _semanticsOwners(tester);
  final List<String> out = <String>[];

  void walk(SemanticsNode node) {
    final SemanticsData data = node.getSemanticsData();
    final String identifier = data.identifier;
    if (identifier.isNotEmpty) {
      final int routes = _countTapRoutes(node, isOwner: true);
      if (routes > 1) {
        out.add(
          'control "$identifier" declares $routes tap actions (its own '
          'semantics node plus ${routes - 1} unidentified descendant node(s) '
          'that also advertise SemanticsAction.tap). A tap fires every route. '
          'Wrap the inner widget in ExcludeSemantics, or drop the outer '
          'Semantics(onTap:).',
        );
      } else if (_announcedAffordance(data) case final String affordance) {
        if (routes == 0) {
          out.add(
            'control "$identifier" announces itself as $affordance but has no '
            'tap action — it is inert. A screen reader offers it for '
            'activation and nothing happens. Give the node an onTap, or drop '
            'the ${affordance == 'a link' ? 'link' : 'button'} flag if it is '
            'not interactive.',
          );
        } else if (!_pointerReaches(
          tester,
          ownerById[node.id],
          rectById[node.id],
        )) {
          out.add(
            'control "$identifier" announces itself as $affordance and '
            'declares a tap action, but a pointer dropped in the middle of '
            'the rect it publishes never reaches it — it is inert to a '
            'real tap. Something between the node and its content refuses the '
            'hit test (IgnorePointer/AbsorbPointer, a zero-size or offset '
            'child, a sibling painted over it). ExcludeSemantics is the '
            'wrapper that silences a duplicate route WITHOUT taking the '
            'pointer away.',
          );
        }
      }
    }
    node.visitChildren((SemanticsNode child) {
      walk(child);
      return true;
    });
  }

  walk(root);
  return out;
}

/// The affordance [data] advertises, phrased for a message, or null when it
/// advertises none. Button wins when both flags are set — a node that is both
/// is described by the stronger, more common word.
String? _announcedAffordance(SemanticsData data) {
  if (data.flagsCollection.isButton) {
    return 'a button';
  }
  if (data.flagsCollection.isLink) {
    return 'a link';
  }
  return null;
}

/// Every [RenderObject] that OWNS a semantics node, keyed by that node's id.
///
/// `RenderObject.debugSemantics` is non-null only on the render object the
/// node was built from, which is exactly the mapping needed: it is that render
/// object's presence in a hit-test path that says whether a pointer landing on
/// the node's pixels reaches the control the node describes.
///
/// `putIfAbsent`, not `[]=`: `Element.renderObject` walks DOWN to the nearest
/// descendant render object, so a whole stack of ancestor elements answers the
/// same one. Keeping the first is keeping the shallowest element for a render
/// object that is identical either way.
Map<int, RenderObject> _semanticsOwners(WidgetTester tester) {
  final Map<int, RenderObject> owners = <int, RenderObject>{};

  void visit(Element element) {
    final RenderObject? renderObject = element.renderObject;
    if (renderObject != null) {
      final SemanticsNode? semantics = renderObject.debugSemantics;
      if (semantics != null) {
        owners.putIfAbsent(semantics.id, () => renderObject);
      }
    }
    element.visitChildren(visit);
  }

  tester.binding.rootElement?.visitChildren(visit);
  return owners;
}

/// Whether a pointer landing in the middle of [globalRect] reaches [owner].
///
/// Returns true — "no accusation" — when either input is missing: a rule that
/// cannot establish the fact must stay silent rather than name a control it
/// did not measure.
///
/// COORDINATES. `SemanticsGeometryNode.globalRect` composes the root semantics
/// transform, which carries the device-pixel-ratio scale, so it is in PHYSICAL
/// pixels; `hitTestOnBinding` takes LOGICAL ones. The division is the whole
/// conversion (the root transform is a uniform scale). Under `wrap()` the
/// ratio is pinned to 1 and the two are the same number, which is why nothing
/// else in this file has had to care.
///
/// A location outside the view is not probed: `_viewportViolations` has
/// already named that control, and hit-testing off-view would add a second,
/// less useful message about the same defect.
bool _pointerReaches(
  WidgetTester tester,
  RenderObject? owner,
  Rect? globalRect,
) {
  if (owner == null || globalRect == null) {
    return true;
  }
  final double ratio = tester.view.devicePixelRatio;
  final Offset location = globalRect.center / ratio;
  final Size viewport = tester.view.physicalSize / ratio;
  if (location.dx < 0 ||
      location.dy < 0 ||
      location.dx > viewport.width ||
      location.dy > viewport.height) {
    return true;
  }
  final HitTestResult result = tester.hitTestOnBinding(location);
  return result.path.any((HitTestEntry e) => identical(e.target, owner));
}

/// Counts `SemanticsAction.tap` on [node] and on its descendants, stopping at
/// any descendant that carries its own identifier — that node is a separate
/// control and owns its own routes.
int _countTapRoutes(SemanticsNode node, {required bool isOwner}) {
  final SemanticsData data = node.getSemanticsData();
  if (!isOwner && data.identifier.isNotEmpty) {
    return 0;
  }
  int count = data.hasAction(SemanticsAction.tap) ? 1 : 0;
  node.visitChildren((SemanticsNode child) {
    count += _countTapRoutes(child, isOwner: false);
    return true;
  });
  return count;
}

/// Sub-pixel slack for the viewport containment check: a control laid out flush
/// against the right edge can land at 1280.0000000001 after a matrix compose.
const double _epsilon = 0.01;
