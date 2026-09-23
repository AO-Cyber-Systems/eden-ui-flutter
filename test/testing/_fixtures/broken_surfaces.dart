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
