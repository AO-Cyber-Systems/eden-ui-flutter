// Hand-built surfaces for the `expectUiSane` oracle.
//
// DO NOT REGENERATE. Every tree below was written by hand so that each one
// trips EXACTLY ONE `expectUiSane` rule. A generated or copy-pasted variant
// will trip two (an overflowing surface also overlaps, a tiny target is also
// unlabelled) and the test then proves nothing about the rule it names.
//
// Each fixture is pumped through `wrap()` (1280x800, light EdenTheme), whose
// child slot is TIGHT at 1280 logical pixels. Every fixture therefore starts
// with a `Center` so its inner `SizedBox` can actually shrink — a bare
// `SizedBox(width: 195)` under a tight 1280 constraint is silently stretched
// back to 1280 and the defect disappears.
//
// `FIX:` comments mark the single edit that repairs each fixture. The RED
// proof for every case is: run the case on the broken tree, capture the
// non-zero exit and the message; apply the marked FIX in place; watch the same
// case go green; restore. Not "assert that an assertion exists".
library;

import 'package:flutter/material.dart';

/// Opaque white, so `textContrastGuideline` has a real background to resolve.
const Color _surface = Color(0xFFFFFFFF);

/// Near-black body text: ~18:1 against [_surface].
const Color _legibleInk = Color(0xFF111111);

/// A 48x48 labelled, tappable control with visible high-contrast glyph.
///
/// Used by the CLEAN fixture and by the overlap fixture, so that the only
/// difference between "passes" and "overlaps" is the geometry.
Widget _control(String identifier, String label, String glyph) {
  return Semantics(
    container: true,
    identifier: identifier,
    label: label,
    button: true,
    onTap: () {},
    child: SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: Text(
          glyph,
          style: const TextStyle(fontSize: 20, color: _legibleInk),
        ),
      ),
    ),
  );
}

/// CLEAN. Violates nothing. This is the adoption gate: if `expectUiSane`
/// cannot pass here it cannot be turned on across 600+ consumer screen tests.
Widget cleanSurface() {
  return Center(
    child: ColoredBox(
      color: _surface,
      child: SizedBox(
        width: 400,
        height: 300,
        child: Stack(
          children: <Widget>[
            Positioned(left: 24, top: 24, child: _control('fx-clean-a', 'Save', 'S')),
            Positioned(left: 240, top: 24, child: _control('fx-clean-b', 'Cancel', 'C')),
          ],
        ),
      ),
    ),
  );
}

/// DEFECT 1 — RenderFlex overflow.
///
/// A 40-character label at fontSize 10 measures 400 logical pixels in the
/// flutter_test font (one em of advance per glyph). The `Row` hands its only
/// child an UNBOUNDED width slot, so the Text lays out at its full 400 inside a
/// 195-wide box: `A RenderFlex overflowed by 215 pixels on the right.`
///
/// Rule violated: "no exception escaped during layout/paint".
Widget overflowingRow() {
  return const Center(
    child: ColoredBox(
      color: _surface,
      child: SizedBox(
        width: 195,
        height: 48,
        child: Row(
          children: <Widget>[
            // FIX: wrap this Text in `Expanded(` ... `)` and give it
            // `overflow: TextOverflow.ellipsis` — a bounded slot cannot
            // overflow.
            Text(
              'Delivery window for the Riverside depot!',
              maxLines: 1,
              style: TextStyle(fontSize: 10, color: _legibleInk),
            ),
          ],
        ),
      ),
    ),
  );
}

/// DEFECT 2 — two identified controls whose rects intersect.
///
/// Both are 48x48 and both are laid out at top 0; the second starts at left 24,
/// so 24x48 of `fx-overlap-b` sits on top of `fx-overlap-a`. On web the
/// semantics node is the click target, so the top one silently eats the other's
/// taps.
///
/// Rule violated: "identified controls are pairwise disjoint".
Widget overlappingControls() {
  return Center(
    child: ColoredBox(
      color: _surface,
      child: SizedBox(
        width: 200,
        height: 100,
        child: Stack(
          children: <Widget>[
            Positioned(left: 0, top: 0, child: _control('fx-overlap-a', 'Approve', 'A')),
            // FIX: change `left: 24` to `left: 96` — 48 wide at x=0 and 48 wide
            // at x=96 do not intersect.
            Positioned(left: 24, top: 0, child: _control('fx-overlap-b', 'Reject', 'R')),
          ],
        ),
      ),
    ),
  );
}

/// DEFECT 3 — one control declaring two tap actions.
///
/// `ElevatedButton` publishes its own `Semantics(container: true)` node
/// carrying `SemanticsAction.tap` (from the InkWell inside it). Wrapping it in
/// an outer `Semantics(onTap:)` adds a SECOND tap route to the same control.
/// A tap therefore fires twice — the double-submit bug class this repo has
/// shipped before.
///
/// Rule violated: "one tap action per identified control".
Widget doubleTapAction() {
  return Center(
    child: ColoredBox(
      color: _surface,
      child: Semantics(
        container: true,
        identifier: 'fx-double-tap',
        label: 'Confirm order',
        button: true,
        onTap: () {},
        // FIX: wrap this ElevatedButton in `ExcludeSemantics(child: ... )` so
        // the button's own tap node is not published and the outer
        // declaration is the only route.
        child: ElevatedButton(
          onPressed: () {},
          child: const Text('Confirm'),
        ),
      ),
    ),
  );
}

/// DEFECT 4 — sub-24px tap target.
///
/// 20x20 is under both the Android floor (48) and the iOS floor (44).
///
/// Rule violated: `androidTapTargetGuideline` / `iOSTapTargetGuideline`.
Widget tinyTapTarget() {
  return Center(
    child: ColoredBox(
      color: _surface,
      child: Semantics(
        container: true,
        identifier: 'fx-tiny-tap',
        label: 'Dismiss banner',
        button: true,
        onTap: () {},
        // FIX: change both dimensions to 48.
        child: const SizedBox(width: 20, height: 20),
      ),
    ),
  );
}

/// DEFECT 5 — dark-on-dark text.
///
/// #2A2A2A on #1E1E1E is a contrast ratio of ~1.15:1. Both colours are OPAQUE
/// on purpose: `textContrastGuideline` silently passes when it cannot resolve
/// a background, so a translucent fixture would prove nothing.
///
/// Rule violated: `textContrastGuideline`.
Widget darkOnDark() {
  return const Center(
    child: ColoredBox(
      color: Color(0xFF1E1E1E),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Storage almost full',
          // FIX: change this to `Color(0xFFF5F5F5)`.
          style: TextStyle(fontSize: 16, color: Color(0xFF2A2A2A)),
        ),
      ),
    ),
  );
}

/// MODALITY-CONDITIONAL — a rail-shaped nav row: 235 wide, 40 tall.
///
/// This is the desktop rail's real geometry (eden_desktop_layout.dart's
/// `_NavTile`: a 40px row on a 42px pitch). It is NOT "broken": 40px clears
/// WCAG 2.5.8 Target Size (Minimum)'s 24x24 pointer floor with room to spare,
/// and fails the Material 48dp / iOS 44pt TOUCH floors.
///
/// It exists so the two modality paths can be told apart by a test rather than
/// by reading the implementation: `EdenInputModality.pointer` must PASS this
/// surface and `EdenInputModality.touch` must FAIL it. There is no `FIX:` line
/// — what changes here is the declared modality, never the geometry.
Widget railRow() {
  return Center(
    child: ColoredBox(
      color: _surface,
      child: Semantics(
        container: true,
        identifier: 'fx-rail-row',
        label: 'Reports',
        button: true,
        onTap: () {},
        child: const SizedBox(
          width: 235,
          height: 40,
          child: Center(
            child: Text(
              'Reports',
              style: TextStyle(fontSize: 13, color: _legibleInk),
            ),
          ),
        ),
      ),
    ),
  );
}

/// DEFECT 6 — a control that announces `button: true` and has NO tap action.
///
/// The node identifies itself, a screen reader announces "Retry sync, button",
/// and nothing is wired to it in either tree: no `onTap` on the node, no
/// gesture recogniser under it. Activating it — by pointer or by assistive
/// tech — does nothing at all.
///
/// Before the zero arm existed, `_tapRouteViolations` only fired on MORE than
/// one route, so this surface passed the oracle in silence.
///
/// Rule violated: "a control that announces an affordance must have exactly
/// one tap route" (zero arm).
Widget inertButton() {
  return Center(
    child: ColoredBox(
      color: _surface,
      // FIX: add `onTap: () {},` below — the node then has exactly one tap
      // route, and the glyph under it takes the pointer.
      child: Semantics(
        container: true,
        identifier: 'fx-inert-button',
        label: 'Retry sync',
        button: true,
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Text('R', style: TextStyle(fontSize: 20, color: _legibleInk)),
          ),
        ),
      ),
    ),
  );
}

/// DEFECT 7 — a control that announces `button: true`, declares exactly ONE
/// tap action, and still cannot be tapped.
///
/// This is the shape that produced the false green on the real mobile shell.
/// [IgnorePointer] sets `isBlockingUserActions` on the subtree (so the inner
/// `GestureDetector`'s implicit tap route disappears and the count reads a
/// healthy 1) AND returns false from `hitTest` (so no pointer ever reaches the
/// row). The node advertises a button with a tap action; a real finger gets
/// nothing.
///
/// Rule violated: "a control that announces an affordance must have exactly
/// one tap route" (unreachable arm).
Widget unreachableButton() {
  return Center(
    child: ColoredBox(
      color: _surface,
      child: Semantics(
        container: true,
        identifier: 'fx-unreachable-button',
        label: 'Confirm order',
        button: true,
        onTap: () {},
        // FIX: change `IgnorePointer` to `ExcludeSemantics`. Both stop the
        // inner GestureDetector publishing a second tap route; only
        // ExcludeSemantics leaves it able to take the pointer.
        child: IgnorePointer(
          child: GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child:
                    Text('C', style: TextStyle(fontSize: 20, color: _legibleInk)),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// DEFECT 8 — a control that announces `link: true` and has no tap action.
///
/// The same class as [inertButton], through the other affordance flag. It is
/// here because the rule keys on the AFFORDANCE the node advertises, not on
/// the word "button": a link that announces itself and goes nowhere is the
/// same lie.
///
/// Rule violated: "a control that announces an affordance must have exactly
/// one tap route" (zero arm, link).
Widget inertLink() {
  return Center(
    child: ColoredBox(
      color: _surface,
      // FIX: add `onTap: () {},` below.
      child: Semantics(
        container: true,
        identifier: 'fx-inert-link',
        label: 'Open the invoice',
        link: true,
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Text('L', style: TextStyle(fontSize: 20, color: _legibleInk)),
          ),
        ),
      ),
    ),
  );
}

/// NOT A DEFECT — identified nodes that are deliberately NON-interactive.
///
/// The exemption the affordance rule has to keep. Both shapes are real and
/// both are correct as written:
///
///  * a caption band (`EdenMobileLayout._navSection`'s analogue): identified
///    and labelled, no `button`, no tap action, nothing to activate;
///  * a text field (`EdenDesktopLayout`'s top-bar search publishes
///    `identifier: 'eden-topbar-search', textField: true`): it announces a
///    TEXT FIELD, not a button, and a text field's affordance is focus, not
///    tap.
///
/// There is no `FIX:` line — a rule that reddens either of these is the wrong
/// rule. This fixture is the differential control for the predicate: widen it
/// from `button || link` to "any identified node" and this case goes red.
Widget nonInteractiveIdentifiedControls() {
  return Center(
    child: ColoredBox(
      color: _surface,
      child: SizedBox(
        width: 400,
        height: 160,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Semantics(
              container: true,
              identifier: 'fx-caption',
              label: 'Reports',
              child: const SizedBox(
                width: 200,
                height: 48,
                child: Center(
                  child: Text('Reports',
                      style: TextStyle(fontSize: 16, color: _legibleInk)),
                ),
              ),
            ),
            Semantics(
              container: true,
              identifier: 'fx-textfield',
              textField: true,
              label: 'Search',
              child: const SizedBox(
                width: 200,
                height: 48,
                child: Center(
                  child: Text('Search',
                      style: TextStyle(fontSize: 16, color: _legibleInk)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// DEFECT 6 — low-contrast text that the SEMANTICS TREE CANNOT SEE.
///
/// This is the mobile/desktop nav row's exact shape: ONE semantics node
/// carrying the row's identifier, label, button flag and tap action, wrapping
/// an [ExcludeSemantics] so the renderer's own `GestureDetector` cannot
/// publish a second tap route (eden_mobile_layout.dart `_navRow`, commit
/// d2af9d1). The badge `Text` lives inside that excluded subtree.
///
/// `textContrastGuideline` walks the SEMANTICS tree and resolves each node's
/// text with `find.text(<the node's label>)`. The only label here is
/// "Orders" — the row's. The string "99" is the label of nothing, so stock
/// Flutter never looks it up and the badge is never contrast-checked, however
/// illegible it is. `Colors.white` on `#D4A853` is 2.20:1 against a 4.5:1
/// floor and the stock guideline is SILENT on it.
///
/// The row's own label is deliberately legible (near-black on white, ~18:1):
/// the ONLY failing text on this surface is the one the semantics tree hides,
/// so a green run means the blind spot, not a lucky pass.
///
/// Rule violated: the oracle's own painted-text contrast walk.
Widget excludedBadgeText() {
  return Center(
    child: ColoredBox(
      color: _surface,
      child: Semantics(
        container: true,
        identifier: 'fx-badge-row',
        label: 'Orders',
        button: true,
        onTap: () {},
        child: const ExcludeSemantics(
          child: SizedBox(
            width: 240,
            height: 48,
            child: Row(
              children: <Widget>[
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Orders',
                    style: TextStyle(fontSize: 14, color: _legibleInk),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFD4A853),
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    child: Text(
                      '99',
                      // FIX: change this to `Color(0xFF171717)`.
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// DEFECT 9 — a control that announces `button: true`, declares exactly ONE
/// tap action, and is made untappable by [AbsorbPointer] rather than by
/// [IgnorePointer].
///
/// The SAME false green as [unreachableButton], one widget over, and the one
/// the reachability arm's own message named as a cause it detects while the
/// implementation did not. Measured mechanism:
///
///   * `RenderAbsorbPointer.hitTest` returns `absorbing ? size.contains(...)`
///     — TRUE without adding itself or anything below it to the hit path. The
///     enclosing `RenderSemanticsAnnotations` therefore still adds ITSELF, so
///     a check that only asks "is the owner in the path?" passes; and
///   * `describeSemanticsConfiguration` sets `isBlockingUserActions`, which
///     strips the inner `GestureDetector`'s implicit tap route, so the count
///     reads a healthy 1.
///
/// A real finger gets nothing.
///
/// Rule violated: "a control that announces an affordance must have exactly
/// one tap route" (unreachable arm), via a DESCENDANT of the owner having to
/// be in the hit path.
Widget absorbedButton() {
  return Center(
    child: ColoredBox(
      color: _surface,
      child: Semantics(
        container: true,
        identifier: 'fx-absorbed-button',
        label: 'Confirm order',
        button: true,
        onTap: () {},
        // FIX: change `AbsorbPointer(absorbing: true,` to `ExcludeSemantics(`.
        // Both stop the inner GestureDetector publishing a second tap route;
        // only ExcludeSemantics leaves it able to take the pointer.
        child: AbsorbPointer(
          absorbing: true,
          child: GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child:
                    Text('C', style: TextStyle(fontSize: 20, color: _legibleInk)),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// DEFECT 10 — text painted in EXACTLY its background colour.
///
/// #1E1E1E on #1E1E1E is 1.00:1 — completely invisible, the maximum-severity
/// WCAG 1.4.3 failure. The contrast rule used to read this as "the region was
/// not resolvable": every pixel inside the paragraph's box is within
/// rasteriser rounding of the ink, so the dominant-background search returned
/// null and the paragraph was silently skipped. Backwards — the one
/// measurement it can be most certain about is the one it declined to report.
///
/// Rule violated: the oracle's own painted-text contrast walk.
Widget invisibleText() {
  return const Center(
    child: ColoredBox(
      color: Color(0xFF1E1E1E),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Storage almost full',
          // FIX: change this to `Color(0xFFF5F5F5)`.
          style: TextStyle(fontSize: 16, color: Color(0xFF1E1E1E)),
        ),
      ),
    ),
  );
}

/// DEFECT 11 — conformant token colours made illegible by PAINT-TIME opacity.
///
/// #111111 on #FFFFFF is 18.9:1 and passes on the colour pair alone. Wrapped
/// in `Opacity(0.3)` the glyphs composite to ~#B7B7B7, which is ~2.0:1 — a
/// real 1.4.3 failure that reading the ink off `TextStyle.color` alone cannot
/// see. `AnimatedOpacity` and `FadeTransition` are the same shape through
/// `RenderAnimatedOpacity`; `lib/src` has 38 `Opacity(` sites.
///
/// Rule violated: the oracle's own painted-text contrast walk (ancestor
/// opacity composed into the ink).
Widget fadedText() {
  return const Center(
    child: ColoredBox(
      color: _surface,
      child: Padding(
        padding: EdgeInsets.all(24),
        // FIX: change `opacity: 0.3` to `opacity: 1.0`.
        child: Opacity(
          opacity: 0.3,
          child: Text(
            'Storage almost full',
            style: TextStyle(fontSize: 16, color: _legibleInk),
          ),
        ),
      ),
    ),
  );
}

/// DEFECT 12 — ink declared through `TextStyle.foreground` instead of
/// `TextStyle.color`.
///
/// A `foreground` [Paint] leaves `TextStyle.color` NULL, so a rule that reads
/// only `color` skipped this paragraph without a word. #2A2A2A on #1E1E1E is
/// ~1.15:1.
///
/// Rule violated: the oracle's own painted-text contrast walk (solid
/// `TextStyle.foreground` resolved as ink).
Widget paintedForegroundText() {
  return Center(
    child: ColoredBox(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Storage almost full',
          style: TextStyle(
            fontSize: 16,
            // FIX: change this to `Color(0xFFF5F5F5)`.
            foreground: Paint()..color = const Color(0xFF2A2A2A),
          ),
        ),
      ),
    ),
  );
}

/// DEFECT 13 — an UNFLAGGED identified control whose one tap route no pointer
/// can reach.
///
/// `InkWell`/`InkResponse` publish `Semantics(onTap: …)` with NO `button`
/// flag, and that is the commonest interactive shape in a consumer screen. The
/// liveness rule used to run only for a node announcing `button: true` or
/// `link: true`, so this control — identified, tappable, and completely dead —
/// was checked by NEITHER arm.
///
/// [IgnorePointer] both blocks the subtree's hit test and strips the inner
/// `GestureDetector`'s implicit route, so the count reads a healthy 1 on a
/// node that announces no affordance at all.
///
/// Rule violated: "an identified control that declares a tap route must be
/// reachable by a pointer", regardless of which flags it announces.
Widget unreachableUnflaggedControl() {
  return Center(
    child: ColoredBox(
      color: _surface,
      child: Semantics(
        container: true,
        identifier: 'fx-unflagged-row',
        label: 'Row 3',
        // Deliberately NO `button: true` — this is what InkWell publishes.
        onTap: () {},
        // FIX: change `IgnorePointer` to `ExcludeSemantics`.
        child: IgnorePointer(
          child: GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child:
                    Text('R', style: TextStyle(fontSize: 20, color: _legibleInk)),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// NOT A DEFECT — the differential control for [unreachableUnflaggedControl].
///
/// The same unflagged, identified, tappable shape with NOTHING between the
/// node and its content. Widening the liveness rule to every identified node
/// that declares a tap route must leave this green, or the rule is not a rule
/// but a ban on `InkWell`.
///
/// There is no `FIX:` line.
Widget reachableUnflaggedControl() {
  return Center(
    child: ColoredBox(
      color: _surface,
      child: Semantics(
        container: true,
        identifier: 'fx-live-row',
        label: 'Row 4',
        onTap: () {},
        child: ExcludeSemantics(
          child: GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child:
                    Text('L', style: TextStyle(fontSize: 20, color: _legibleInk)),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// NOT A DEFECT — a 30-row `ListView` in a 300px viewport.
///
/// Every row is correct: identified, labelled, 400x48, with an OPAQUE gesture
/// surface filling it (the shape `EdenMobileLayout._navRow` uses — one
/// semantics node over an `ExcludeSemantics`'d detector). Only six rows fit;
/// Flutter builds a few more inside the cache extent and publishes them with
/// `isHidden: true`.
///
/// Those hidden rows carry identifiers and tap routes, and no pointer can
/// reach them — because no user can see them. The stock
/// `MinimumTapTargetGuideline` and `LabeledTapTargetGuideline` both skip
/// nodes flagged `isHidden`/`isInvisible`/`isMergedIntoParent`; this oracle's
/// own walks did not, so a correct list reported one "inert to a real tap"
/// violation per off-screen row. Measured on this fixture: FIVE false
/// accusations on a screen with nothing wrong with it.
///
/// THAT is the pressure that gets an oracle switched off — or gets identifier
/// sets dumped into `allowOverlap`, which is its own defect (see
/// [twoOverlapPairs]).
///
/// There is no `FIX:` line — a rule that reddens an off-screen row is the
/// wrong rule.
Widget scrolledListRows() {
  return Center(
    child: ColoredBox(
      color: _surface,
      child: SizedBox(
        width: 400,
        height: 300,
        child: ListView.builder(
          itemCount: 30,
          itemExtent: 48,
          itemBuilder: (BuildContext context, int i) => Semantics(
            container: true,
            identifier: 'fx-row-$i',
            label: 'Row $i',
            button: true,
            onTap: () {},
            child: ExcludeSemantics(
              child: GestureDetector(
                onTap: () {},
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: 48,
                  child: Center(
                    child: Text(
                      'Row $i',
                      style: const TextStyle(fontSize: 14, color: _legibleInk),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// DEFECT 14 — one control overlapping TWO others.
///
/// `fx-ov-a` is a 200x48 strip at the origin; `fx-ov-b` and `fx-ov-c` are
/// 48x48 controls at x=0 and x=140, both inside it. `b` and `c` do not touch
/// each other. So the surface states exactly two overlapping PAIRS, (a,b) and
/// (a,c), which is what makes it able to tell a per-pair exemption from a
/// per-identifier one: exempting (a,b) must leave (a,c) reported.
///
/// There is no single `FIX:` line — the fixture exists to be run twice, once
/// with `allowOverlap: {}` and once with `allowOverlap: {('fx-ov-a',
/// 'fx-ov-b')}`.
Widget twoOverlapPairs() {
  return Center(
    child: ColoredBox(
      color: _surface,
      child: SizedBox(
        width: 200,
        height: 100,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 0,
              top: 0,
              child: Semantics(
                container: true,
                identifier: 'fx-ov-a',
                label: 'Row',
                button: true,
                onTap: () {},
                child: const SizedBox(
                  width: 200,
                  height: 48,
                  child: Center(
                    child: Text('Row',
                        style: TextStyle(fontSize: 14, color: _legibleInk)),
                  ),
                ),
              ),
            ),
            Positioned(left: 0, top: 0, child: _control('fx-ov-b', 'Badge', 'B')),
            Positioned(
                left: 140, top: 0, child: _control('fx-ov-c', 'Close', 'X')),
          ],
        ),
      ),
    ),
  );
}
