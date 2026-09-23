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

import 'semantics_geometry.dart';

/// What a surface is DRIVEN WITH. Selects the tap-target floor, and nothing
/// else.
///
/// WHY THIS EXISTS. The 48dp Material floor
/// (`androidTapTargetGuideline`) and the 44pt iOS HIG floor
/// (`iOSTapTargetGuideline`) are TOUCH guidance — they size a control for a
/// fingertip. For pointer-driven UI the applicable standard is WCAG 2.5.8
/// Target Size (Minimum), which is 24x24 CSS px at AA; 2.5.5 Target Size
/// (Enhanced), 44x44, is AAA. Asserting a touch floor on a pointer surface is
/// therefore not a STRICTER standard, it is the WRONG standard — and the only
/// pressure it can create is to weaken the oracle, which is how oracles rot.
///
/// This is NOT a suppression or exception mechanism. There is deliberately no
/// way to waive the tap-target rule for a surface; there is only a way to
/// declare, honestly, what input that surface takes. It is the same
/// state-conditional shape the Surface Spec uses for `behaviors[]`/`when`: the
/// rule that applies is a function of declared state, and every path still
/// asserts a real floor (compare case 7 and case 8 in
/// `test/testing/expect_ui_sane_test.dart` — the pointer floor rejects 20x20
/// and accepts 40px, so it is neither vacuous nor the touch rule in disguise).
///
/// A surface that ships to BOTH is [touch]: the stricter floor is the honest
/// answer when a fingertip can reach the control at all. [touch] is also the
/// default of [expectUiSane], so an author who says nothing gets the stricter
/// rule rather than the looser one.
enum EdenInputModality {
  /// Mouse, trackpad, stylus or keyboard-driven. Asserts WCAG 2.5.8 Target
  /// Size (Minimum): 24x24.
  ///
  /// The worked example is the Eden desktop rail: 40px nav rows on a 42px
  /// pitch (`eden_desktop_layout.dart`). 40px clears 24x24 comfortably, and
  /// it is not reachable by a fingertip on the surfaces that use it.
  pointer,

  /// Finger-driven, or reachable by a finger on any surface this ships to.
  /// Asserts BOTH `androidTapTargetGuideline` (48dp) and
  /// `iOSTapTargetGuideline` (44pt).
  ///
  /// Both floors are checked, deliberately — a 46px target is a real defect on
  /// Android, and tuning a fixture to sit between the two would hide it.
  touch,
}

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
/// 4. **One tap action per control.** A control that declares `tap` on its own
///    node AND again on a non-identified descendant fires twice.
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
    violations.addAll(_tapRouteViolations(tester));
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

  // KNOWN LIMITATION — see 23-02-SUMMARY.md "Issues Encountered".
  // `textContrastGuideline` captures the rendered image through
  // `tester.runAsync`, which lets futures that were ALREADY PENDING before
  // expectUiSane was called finally run. `EdenTheme` resolves its type scale
  // through google_fonts, which fires an HTTP fetch at theme-construction
  // time; in a widget test that request can never succeed, and the resulting
  // UNCAUGHT ASYNC error completes the test with an error directly — it never
  // reaches `tester.takeException()`, so this helper cannot swallow it.
  //
  // Consequence: on a surface pumped with EdenTheme in an environment where
  // the Outfit font is not bundled as an asset, expectUiSane fails with a
  // gstatic.com fetch error rather than a verdict about the surface. The fix
  // belongs in the test environment (bundle the font, or stub the fetch in
  // `test/flutter_test_config.dart`), not here. Everything below the exception
  // check still works; only the guideline phase is affected.
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

List<String> _tapRouteViolations(WidgetTester tester) {
  final SemanticsNode root = rootSemanticsNodeOf(tester);
  final List<String> out = <String>[];

  void walk(SemanticsNode node) {
    final String identifier = node.getSemanticsData().identifier;
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
