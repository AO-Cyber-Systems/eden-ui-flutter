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

import 'dart:typed_data';
import 'dart:ui' as ui;

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
/// 5. **Accessibility guidelines.** `labeledTapTargetGuideline` and a
///    tap-target floor chosen by
///    [inputModality]: WCAG 2.5.8's 24x24 for [EdenInputModality.pointer],
///    `androidTapTargetGuideline` (48px) + `iOSTapTargetGuideline` (44px) for
///    [EdenInputModality.touch]. Each failure is folded into the same
///    aggregated report, prefixed with the guideline's name.
///
/// 6. **Painted-text contrast (WCAG 1.4.3).** Every `Text` and `EditableText`
///    in the tree is measured: its ink comes from the resolved `TextStyle`,
///    the surface it sits on from the rendered pixels. This REPLACES Flutter's
///    `textContrastGuideline`, which could not see badge text at all — it
///    looks text up by a semantics node's LABEL, and a badge inside an
///    `ExcludeSemantics` is the label of nothing — and which misreads small
///    text, because it derives the ink from a pixel histogram that a 10px
///    glyph has no full-coverage pixels in. Text behind a modal barrier and
///    text inside a disabled control are exempt, as they were under the stock
///    rule and as WCAG 1.4.3 allows.
///
/// Violations are AGGREGATED: one run lists everything wrong with the surface,
/// so a consumer fixing a screen does not play whack-a-mole.
///
/// A surface with no identified controls is not a failure — it has nothing to
/// check. `expectUiSane` must be adoptable without a triage backlog.
///
/// Note on `container: true`: give every control you want checked
/// `container: true`. The penalty for omitting it is SDK-dependent, and both
/// ends are measured by `test/ui_oracle/semantics_geometry_test.dart` case 7:
/// on Flutter 3.41.9 a nested `Semantics` without it published no node at all
/// — its identifier vanished into the enclosing node and this oracle could
/// not see the control; on 3.47.4, which CI pins, it publishes its own node
/// with its own rect and the oracle DOES see it. The rule stands either way,
/// because this package's declared SDK floor still spans versions with the
/// old behaviour and because `container: true` states the boundary rather
/// than inheriting whichever one a consumer's SDK gives it.
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
    violations.addAll(await _paintedTextContrastViolations(tester));
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
/// `textContrastGuideline` IS NOT HERE, deliberately. Contrast is measured by
/// this library's own painted-text walk instead — see the block above
/// `_paintedTextContrastViolations` for why the stock rule could not be kept
/// alongside it, and what it could not see.
const List<AccessibilityGuideline> _modalityIndependentGuidelines =
    <AccessibilityGuideline>[
  labeledTapTargetGuideline,
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

  // WHY AN IMAGE-CAPTURING CHECK NEEDS A FONT-CLEAN TEST ENVIRONMENT (was a
  // KNOWN LIMITATION; fixed by `test/flutter_test_config.dart`).
  //
  // The painted-text phase below captures the rendered image through
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
  // before the contrast rule means anything. This package does it in
  // `test/flutter_test_config.dart`, which serves the Eden type families to
  // google_fonts from `test_support/fonts/` AND awaits them before the first
  // test renders — otherwise the first test in every file rasterises in a
  // different face from the rest and any pixel measurement is decided by
  // position in the file.
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

/// UNITS: this check has TWO coordinate systems in it and they are not the
/// same one.
///
/// `SemanticsGeometryNode.globalRect` composes the root semantics transform,
/// which carries the device-pixel-ratio scale, so it is in PHYSICAL pixels —
/// the same fact `_pointerReaches` below already has to divide out.
/// `tester.view.physicalSize / tester.view.devicePixelRatio` is LOGICAL. This
/// function used to compare the two directly.
///
/// That was correct only by accident of the harness: `wrap()` pins
/// `devicePixelRatio` to 1, where the two numbers coincide. At any other
/// ratio EVERY control on EVERY surface fails — a control at logical x=680 on
/// a dpr-2 device publishes a rect at 1360, and a 1280-wide viewport rejects
/// it. The oracle would have cried wolf on the whole app the first time
/// someone pumped at a real device ratio, and a check that fires on
/// everything gets switched off, which is how an oracle dies.
///
/// The rect is converted to LOGICAL rather than the viewport to physical
/// because the violation message quotes both, and logical pixels are the unit
/// the reader's layout code is written in. Pinned by
/// `expect_ui_sane_dpr_test.dart` at ratios 2 and 3.
List<String> _viewportViolations(
  WidgetTester tester,
  List<SemanticsGeometryNode> nodes,
) {
  final double ratio = tester.view.devicePixelRatio;
  final Size viewport = tester.view.physicalSize / ratio;
  final Rect viewportRect = Offset.zero & viewport;
  final List<String> out = <String>[];
  for (final SemanticsGeometryNode node in nodes) {
    final Rect r = _toLogical(node.globalRect, ratio);
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

/// UNITS (audited alongside `_viewportViolations`' physical/logical bug, and
/// clean): this rule compares node rects only to EACH OTHER, and every rect
/// comes out of the same physical-pixel transform, so the ratio cancels and
/// the verdict is identical at every device pixel ratio. `_pointerReaches` is
/// the third rect consumer and already divides the ratio out explicitly.
/// Those three are all of them — no other check in this file reads a rect.
///
/// The rects QUOTED in the message below are therefore physical while
/// `_viewportViolations`' are logical. Cosmetic, not a correctness defect, and
/// left alone on purpose: normalising them would mean converting rects the
/// rule itself does not need converted.
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
//
// KNOWN LIMIT, recorded rather than fixed: the walk only inspects nodes that
// carry an IDENTIFIER, so a `button: true` node with NO identifier is never
// checked for liveness — it can be inert and this rule stays silent. Left as
// is because the identifier is what lets a violation NAME the offending
// control, and an unnamed "some button somewhere is dead" is not actionable;
// the repo's convention is that a control worth checking carries one.

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

/// [physical] expressed in LOGICAL pixels.
///
/// The root semantics transform is a uniform scale by the device pixel ratio,
/// so dividing every edge by [ratio] is the whole conversion. `Rect` has no
/// division operator, which is the only reason this is a function.
Rect _toLogical(Rect physical, double ratio) => Rect.fromLTRB(
      physical.left / ratio,
      physical.top / ratio,
      physical.right / ratio,
      physical.bottom / ratio,
    );

/// Sub-pixel slack for the viewport containment check, in LOGICAL pixels: a
/// control laid out flush against the right edge can land at 1280.0000000001
/// after a matrix compose.
const double _epsilon = 0.01;

// -----------------------------------------------------------------------------
// Painted-text contrast: the check that does NOT go through the semantics tree
// -----------------------------------------------------------------------------
//
// WHY THIS EXISTS. `textContrastGuideline` walks the SEMANTICS tree. For every
// node it resolves the text to measure with `find.text(<the node's label>)`.
// That makes a node's LABEL the only key it can look text up by, and it means
// any painted string that is not some node's label is never contrast-checked —
// however illegible it is.
//
// The mobile shell's nav rows are exactly that shape, and not by accident:
// each row publishes ONE semantics node carrying the row's label, and the
// renderer's subtree is wrapped in `ExcludeSemantics` so the inner
// `GestureDetector` cannot publish a second tap route (commit d2af9d1). The
// badge `Text` lives inside that excluded subtree. Its string ("3", "99") is
// the label of nothing, so `find.text` is never asked for it.
//
// Badges are where small, tinted, bold-at-9px text lives. That made them the
// single worst blind spot the oracle had, and it was not theoretical: three
// badge contrast defects on this branch (drawer 2.20:1 light / 2.33:1 dark,
// the "More" sheet's, and the bottom bar's 3.76:1) were all found by hand and
// held by hand-written computed cases, because the oracle could not report a
// single one of them.
//
// WHY THE WIDGET TREE AND NOT MORE SEMANTICS. The alternative was to publish
// badge text into the accessibility tree. It cannot be done without breaking
// something load-bearing: `ExcludeSemantics` blocks its whole subtree (
// `RenderExcludeSemantics.visitChildrenForSemantics` does not descend), there
// is no re-entry from inside it, and hoisting the badge out to a sibling node
// would both put two nodes on one row — the single-node-per-row contract the
// `eden-nav-<id>` identifier depends on — and give the row a second click
// target on web. Folding the badge into the row's LABEL does not help either:
// the guideline would then look for `find.text('Orders, 3')`, and no `Text`
// widget carries that string.
//
// Walking the widget tree costs none of that. `ExcludeSemantics` touches the
// SEMANTICS tree only — it changes neither layout, nor paint, nor the widget
// tree — so d2af9d1 stands exactly as written and this rule still sees the
// badge. The measurement is taken from the RENDERED PIXELS, the same source
// the stock guideline measures from.
//
// WHY THE STOCK RULE IS GONE RATHER THAN KEPT ALONGSIDE. Running both was the
// first shape of this change, and the stock rule failed on its own terms the
// moment the suite started rasterising in Eden's real type families: it
// derives BOTH colours from a pixel histogram, and an 11px label or a 10px
// badge digit has no full-coverage pixels for it to find, so it reports the
// mode of the antialiased stroke shades as the ink. The mobile bar's labels
// came back at 2.20-4.38:1 against a colour pair of 4.83:1, and the rail's
// badge at 2.52:1 against 8.04:1 — four false accusations on conformant text.
// It is not a rule that can be left switched on beside a correct one.
//
// SCOPE is therefore every `Text` and `EditableText` in the tree.
//
// EXEMPTION, encoded rather than assumed: WCAG 1.4.3 exempts "text that is
// part of an inactive user interface component". The stock guideline gets that
// for free by skipping semantics nodes whose `isEnabled` is false; this rule
// has to do it explicitly, by skipping any `Text` painted inside a disabled
// node's rect.
//
// KNOWN LIMIT, recorded rather than fixed: the background is the dominant
// colour inside the paragraph's OWN box, so a paragraph that does not sit on
// the component it visually belongs to is measured against whatever it does
// sit on.
//
// THE ONE CANDIDATE INSTANCE TURNED OUT TO BE A REAL DEFECT, NOT A LIMIT.
// The desktop top bar's search hint was reported at 4.83:1 where its token
// pair against the pill is 3.81:1, and that was recorded here as this limit
// biting. It was not: the field was inheriting `filled: true` from
// `EdenTheme`'s `inputDecorationTheme` and painting an opaque white rectangle
// over the pill, so white WAS the surface the glyph was painted on and the
// rule was right. Fixed in `_TopBar`; pinned by
// `test/ui_oracle/topbar_search_pill_paint_test.dart`. When this rule and a
// token pair disagree, the frame is the thing to go and look at — the
// disagreement is evidence about the widget, not only about the rule.
//
// KNOWN LIMIT, recorded rather than fixed: a `Text` whose ink cannot be
// resolved from its style — `TextStyle.color` null with no `DefaultTextStyle`
// to inherit from, or a `Text.rich` whose spans carry their own colours — is
// not measured. `Text.rich` is the real one: `Text.data` is null there, so
// those are skipped by the empty-string test and a low-contrast span inside a
// rich paragraph goes unreported. Every low-contrast defect this branch found
// was a plain `Text`; a per-span walk is the fix when one is not.

/// WCAG 1.4.3 AA floors, and the size at which "large text" begins. Same
/// numbers `MinimumTextContrastGuideline` uses, restated rather than reached
/// for because they are private to it.
const double _kMinimumRatioNormalText = 4.5;
const double _kMinimumRatioLargeText = 3.0;
const double _kLargeTextMinimumSize = 18.0;
const double _kBoldTextMinimumSize = 14.0;
const double _kDefaultFontSize = 12.0;

/// Same tolerance as `MinimumTextContrastGuideline`: a ratio within 0.01 of
/// the floor passes, so a colour pair that computes to 4.4999 is not a defect.
const double _kContrastTolerance = 0.01;

/// Measures the contrast of every painted `Text` the semantics-driven
/// `textContrastGuideline` did not evaluate, and names each one that fails.
Future<List<String>> _paintedTextContrastViolations(WidgetTester tester) async {
  final List<String> out = <String>[];

  final List<Rect> disabledRegions = _disabledRegions(tester);
  final _PaintOrder paintOrder = _PaintOrder.of(tester);

  for (final RenderView renderView in tester.binding.renderViews) {
    final List<Element> candidates = _textElements(
      tester,
      disabledRegions,
      paintOrder,
    );
    if (candidates.isEmpty) {
      continue;
    }

    // One capture per view, not one per element: `toImage` is the expensive
    // part and every element reads the same frame.
    final OffsetLayer layer = renderView.debugLayer! as OffsetLayer;
    ByteData? bytes;
    int imageWidth = 0;
    int imageHeight = 0;
    await tester.binding.runAsync<void>(() async {
      // The pixel ratio must be the INVERSE of the view's, exactly as the
      // stock guideline does it, or the image's pixel grid and the logical
      // rects taken from `getTransformTo(null)` are in different units and
      // every histogram reads the wrong region.
      final ui.Image image = await layer.toImage(
        renderView.paintBounds,
        pixelRatio: 1 / renderView.flutterView.devicePixelRatio,
      );
      imageWidth = image.width;
      imageHeight = image.height;
      bytes = await image.toByteData();
      image.dispose();
    });
    final ByteData? data = bytes;
    if (data == null) {
      continue;
    }

    for (final Element element in candidates) {
      final String? violation = _measureText(
        element,
        data,
        imageWidth,
        imageHeight,
      );
      if (violation != null) {
        out.add(violation);
      }
    }
  }

  return out;
}

/// Every `Text` element in the pumped tree that the stock guideline has NOT
/// already measured and that WCAG does not exempt.
List<Element> _textElements(
  WidgetTester tester,
  List<Rect> disabledRegions,
  _PaintOrder paintOrder,
) {
  final List<Element> out = <Element>[];
  // `find.byType` skips offstage subtrees by default, which is what keeps an
  // inactive route's text out of the measurement.
  for (final Element element in <Element>[
    ...find.byType(Text).evaluate(),
    ...find.byType(EditableText).evaluate(),
  ]) {
    if (_stringOf(element.widget).trim().isEmpty) {
      continue;
    }
    final RenderObject? renderObject = element.renderObject;
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      continue;
    }
    if (paintOrder.isBehindAModal(element)) {
      continue;
    }
    final Rect bounds = _globalPaintBounds(renderObject);
    if (bounds.isEmpty) {
      continue;
    }
    // CONTAINS THE CENTRE, not "overlaps". A disabled node that merely
    // touches a paragraph's box must not exempt it — one large disabled
    // region would then silence most of a screen, and an exemption that wide
    // is how a gate stops being one.
    if (disabledRegions.any((Rect r) => r.contains(bounds.center))) {
      continue;
    }
    out.add(element);
  }
  return out;
}

/// The string [widget] paints, for a `Text` or an `EditableText`.
String _stringOf(Widget widget) => switch (widget) {
      Text(:final String? data) => data ?? '',
      EditableText(:final TextEditingController controller) => controller.text,
      _ => '',
    };

/// [renderObject]'s paint bounds in the coordinate space the captured image is
/// in — logical pixels, origin at the view's top-left.
Rect _globalPaintBounds(RenderBox renderObject) => MatrixUtils.transformRect(
      renderObject.getTransformTo(null),
      renderObject.paintBounds,
    );

/// Measures one element and returns a violation string, or null when it
/// conforms or cannot be measured.
///
/// WHY THE FOREGROUND IS READ OFF THE STYLE AND NOT OFF THE PIXELS. The stock
/// guideline derives BOTH colours from a histogram: it splits the region's
/// pixels at their mean HSL lightness and takes the mode of each half. That
/// works on a paragraph with a solid stroke and falls apart on exactly the
/// text this rule exists for. A 10px badge digit in Eden's real type families
/// rasterises to about nine ANTIALIASED pixels and no full-coverage core, so
/// the "dark" mode comes back as a 40%-coverage blend of ink over gold and
/// the badge reports 2.52:1 where its colour pair is 8.04:1. Measured, on the
/// desktop rail, with the correct ink already in place.
///
/// The author's colour is not a guess — it is in the resolved [TextStyle].
/// Reading it there and measuring only the BACKGROUND from the pixels answers
/// the question WCAG 1.4.3 actually asks, is stable across font warm-up and
/// stroke weight, and is the same thing this repo's hand-written computed
/// cases assert — except derived from the real tree instead of restated per
/// case.
String? _measureText(
  Element element,
  ByteData data,
  int imageWidth,
  int imageHeight,
) {
  final Widget widget = element.widget;
  final RenderBox box = element.renderObject! as RenderBox;
  final String string = _stringOf(widget);

  final TextStyle? declared = switch (widget) {
    Text(:final TextStyle? style) => style,
    EditableText(:final TextStyle style) => style,
    _ => null,
  };
  final TextStyle effective = declared == null || declared.inherit
      ? DefaultTextStyle.of(element).style.merge(declared)
      : declared;
  final Color? foreground = effective.color;
  if (foreground == null || foreground.a == 0) {
    // No resolvable ink, or fully transparent. A rule that cannot establish
    // the fact stays silent rather than accusing a control it did not measure.
    return null;
  }
  final double fontSize = effective.fontSize ?? _kDefaultFontSize;
  // Same predicate as the stock guideline: WCAG's "bold" is FontWeight.bold
  // exactly, not "anything heavier than normal".
  final bool isBold = effective.fontWeight == FontWeight.bold;
  final double target =
      (isBold && fontSize >= _kBoldTextMinimumSize) ||
              fontSize >= _kLargeTextMinimumSize
          ? _kMinimumRatioLargeText
          : _kMinimumRatioNormalText;

  // The paragraph's OWN box, uninflated. The stock guideline inflates by 4 to
  // find a background in the ring around the glyphs; this rule does not need
  // to, because a line box is already taller than its glyphs and the tracking
  // between them is background. Not inflating is what keeps the measurement
  // inside the component the text actually sits on — a 4px ring around a 10px
  // badge reaches past the pill and onto the surface behind it, and the
  // background then comes back as the pill fill rather than as the fill the
  // glyph is painted over.
  final Rect region = MatrixUtils.transformRect(
    box.getTransformTo(null),
    box.paintBounds,
  );
  if (region.right < 0 ||
      region.bottom < 0 ||
      region.left > imageWidth ||
      region.top > imageHeight) {
    // Entirely off the captured frame. Not measured, so not accused.
    return null;
  }

  final Map<int, int> histogram =
      _argbHistogram(data, region, imageWidth, imageHeight);
  final Color? background = _dominantBackground(histogram, foreground);
  if (background == null) {
    // Every pixel in the region is the ink itself — there is no background to
    // compare against, which means the region was not resolvable rather than
    // that it failed.
    return null;
  }

  // A translucent ink has no contrast ratio of its own; composite it over what
  // it is painted on first, or the answer is meaningless.
  final Color ink = foreground.a == 1.0
      ? foreground
      : Color.alphaBlend(foreground, background);
  final double ratio = _contrastRatio(ink, background);
  if (ratio - target >= -_kContrastTolerance) {
    return null;
  }

  return 'painted text "$string" is ${ratio.toStringAsFixed(2)}:1 '
      'against its background, below the WCAG 1.4.3 floor of $target:1 for '
      '${fontSize}px${isBold ? ' bold' : ''} text. Its ink is ${_hex(ink)} and '
      'the surface it is painted on measures ${_hex(background)}. '
      'Painted by:\n      '
      '${element.debugGetCreatorChain(6)}';
}

/// The colour a paragraph is painted ON: the most frequent colour in its box
/// that is not the ink itself.
///
/// Antialiased edge pixels are blends of ink and background and are therefore
/// candidates, but on any real paragraph the untouched background outnumbers
/// them by an order of magnitude — a line box is taller than its glyphs and
/// the tracking between them is background — so the mode is the background.
/// That is the one assumption this rule makes about pixels, and it is a far
/// weaker one than "the glyph has full-coverage pixels", which is what the
/// stock guideline needs and what small text does not have.
Color? _dominantBackground(Map<int, int> histogram, Color foreground) {
  final int inkArgb = foreground.toARGB32();
  int? best;
  int bestCount = 0;
  for (final MapEntry<int, int> entry in histogram.entries) {
    if (_isNear(entry.key, inkArgb)) {
      continue;
    }
    if (entry.value > bestCount) {
      best = entry.key;
      bestCount = entry.value;
    }
  }
  return best == null ? null : Color(best);
}

/// Whether two ARGB values are the same colour up to rasteriser rounding.
bool _isNear(int a, int b) {
  for (int shift = 0; shift <= 24; shift += 8) {
    if (((a >> shift) & 0xFF) - ((b >> shift) & 0xFF) > 2 ||
        ((b >> shift) & 0xFF) - ((a >> shift) & 0xFF) > 2) {
      return false;
    }
  }
  return true;
}

/// WCAG 2.x contrast ratio between two OPAQUE colours.
double _contrastRatio(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double hi = la > lb ? la : lb;
  final double lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Screen rects of every DISABLED semantics node, in logical pixels.
///
/// WCAG 1.4.3 exempts text that is part of an inactive user-interface
/// component. The stock guideline gets the exemption by refusing to descend
/// into a disabled node; this rule reads the widget tree instead, so the
/// exemption has to be stated as geometry.
List<Rect> _disabledRegions(WidgetTester tester) {
  final double ratio = tester.view.devicePixelRatio;
  final List<Rect> out = <Rect>[];

  void walk(SemanticsNode node, Matrix4 inherited) {
    final Matrix4 transform = node.transform == null
        ? inherited
        : (inherited.clone()..multiply(node.transform!));
    if (node.flagsCollection.isEnabled == ui.Tristate.isFalse) {
      out.add(
        _toLogical(MatrixUtils.transformRect(transform, node.rect), ratio),
      );
    }
    node.visitChildren((SemanticsNode child) {
      walk(child, transform);
      return true;
    });
  }

  walk(rootSemanticsNodeOf(tester), Matrix4.identity());
  return out;
}

/// Colour histogram of the pixels inside [region] of an RGBA byte buffer,
/// keyed by ARGB.
Map<int, int> _argbHistogram(
  ByteData data,
  Rect region,
  int width,
  int height,
) {
  final Rect clipped = region.intersect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
  );
  if (clipped.isEmpty) {
    return const <int, int>{};
  }
  final int left = clipped.left.floor();
  final int right = clipped.right.ceil();
  final int top = clipped.top.floor();
  final int bottom = clipped.bottom.ceil();

  final Map<int, int> counts = <int, int>{};
  for (int x = left; x < right; x++) {
    for (int y = top; y < bottom; y++) {
      if (x < 0 || y < 0 || x >= width || y >= height) {
        continue;
      }
      // Big-endian read gives RGBA packed; rotate to ARGB.
      final int rgba = data.getUint32((y * width + x) * 4);
      final int argb = (rgba << 24) | ((rgba >> 8) & 0xFFFFFF);
      counts.update(argb, (int c) => c + 1, ifAbsent: () => 1);
    }
  }
  return counts;
}

/// `#AARRGGBB`, so a violation quotes a colour a reader can paste into a token
/// file rather than `Color(0xff...)`.
String _hex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0').toUpperCase()}';

/// Where each element sits in the tree's pre-order walk, and where the last
/// modal barrier sits in it.
///
/// WHY THIS EXISTS — the scrim exemption. `textContrastGuideline` never
/// measures the page behind an open drawer or a modal bottom sheet, because
/// both overlays wrap in [BlockSemantics] and the stock walk is a SEMANTICS
/// walk: the blocked nodes are simply not in the tree it reads. A widget-tree
/// walk has no such luck. It finds the bottom bar's labels sitting under
/// `Colors.black54` and measures them THROUGH the scrim, which is neither the
/// colour pair the author wrote nor a ratio anyone can act on: the mobile
/// shell's open-drawer surface reported its body copy at 4.15:1 light and its
/// bar labels at 1.01:1 dark, all of them 16:1 pairs with a scrim over them.
///
/// WCAG agrees with the stock rule here — obscured content is not the content
/// under test — so the exemption is encoded rather than argued with.
///
/// THE APPROXIMATION, stated because it is one: [BlockSemantics] blocks what
/// was painted BEFORE it, and this uses "earlier in the pre-order element
/// walk" as the proxy for "painted earlier". The two coincide for a Stack, an
/// Overlay and a Scaffold's slot list, which is every modal surface Material
/// builds — `DrawerController` puts the scrim's `BlockSemantics` in a `Stack`
/// with the drawer panel after it, and `ModalBarrier` is an overlay entry
/// inserted below its route's. They would diverge for a child painted out of
/// order by a custom render object, which nothing in this library does.
class _PaintOrder {
  const _PaintOrder._(this._indexOf, this._lastBarrier);

  factory _PaintOrder.of(WidgetTester tester) {
    final Map<Element, int> indexOf = <Element, int>{};
    int next = 0;
    int lastBarrier = -1;

    void visit(Element element) {
      final int index = next++;
      indexOf[element] = index;
      final Widget widget = element.widget;
      if (widget is BlockSemantics && widget.blocking && index > lastBarrier) {
        lastBarrier = index;
      }
      element.visitChildren(visit);
    }

    tester.binding.rootElement?.visitChildren(visit);
    return _PaintOrder._(indexOf, lastBarrier);
  }

  final Map<Element, int> _indexOf;
  final int _lastBarrier;

  /// Whether [element] is painted behind the last modal barrier in the tree.
  bool isBehindAModal(Element element) {
    if (_lastBarrier < 0) {
      return false;
    }
    final int? index = _indexOf[element];
    return index != null && index < _lastBarrier;
  }
}
