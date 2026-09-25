// ADVERSARIAL surfaces for the `expectUiSane` oracle.
//
// WHAT THIS IS AND WHY IT IS SEPARATE FROM `broken_surfaces.dart`.
// `test/testing/_fixtures/broken_surfaces.dart` holds one fixture per RULE:
// each tree trips a rule its author had already thought of, and the self-test
// asserts the rule names it. That proves the rules work. It does not measure
// the ENUMERATION — whether a rule covers every widget that produces the same
// defect. Fourteen oracle defects have been found on this branch and every
// one of them was found by someone breaking something ad hoc and noticing;
// `AbsorbPointer` sat one line from the `IgnorePointer` fixture and defeated
// the same check.
//
// So the trees below are organised by DEFECT CLASS, not by rule:
//
//   * UNREACHABLE — a control that is visually present and functionally dead.
//     Every distinct framework mechanism that returns a hit without the
//     target reaching the path, or removes the hit while keeping the
//     semantics node.
//   * UNREADABLE — text that is present in the tree, resolves to a
//     conformant `TextStyle`, and is not legible on the rendered frame.
//     Every distinct way the resolved style and the painted pixels disagree.
//
// SOME OF THESE ARE NOT CAUGHT. That is the point. A fixture the oracle
// misses is the most valuable row in the catalogue: it is a named, executable
// statement of a blind spot, and it turns red the day someone closes it. Do
// NOT "fix" a miss by weakening its row — promote the row to `caught` once
// the ORACLE changes.
//
// DELIBERATELY ABSENT — five shapes owned by the review-findings lane and
// fixtured in `broken_surfaces.dart`, not here: `AbsorbPointer`, ink ==
// background, `Opacity`-faded text, an `InkWell` publishing a tap route with
// no `button` flag, and hidden/invisible/merged nodes producing false
// viewport violations. The catalogue declares them as rows owned elsewhere so
// the table stays complete without two lanes editing one fixture file.
//
// HARNESS CONTRACT. Every tree is pumped through `wrap()` (1280x800, light
// EdenTheme, device pixel ratio 1), whose child slot is TIGHT at 1280 logical
// pixels — a bare `SizedBox(width: n)` is stretched straight back to 1280, so
// every fixture starts with a `Center`.
//
// IDENTIFIER CONVENTION: `adv-<slug>`. A fixture's identifier is quoted in
// the violation the catalogue asserts, so it must be unique across the file.
library;

import 'package:flutter/material.dart';

/// Opaque white: a background the pixel measurement can resolve without
/// depending on which scaffold colour the active theme happens to carry.
const Color _surface = Color(0xFFFFFFFF);

/// Near-black body ink: ~18.9:1 against [_surface], so no fixture here trips
/// the contrast rule by accident while demonstrating something else.
const Color _legibleInk = Color(0xFF111111);

/// A pale, fully opaque cover colour. Distinct from [_surface] so a
/// measurement that reads it can be told apart from one that read the page.
const Color _opaqueCover = Color(0xFFFFE9A8);

/// The span ink in [lowContrastRichSpan]: 1.06:1 against [_surface].
const Color _richSpanInk = Color(0xFFF7F7F7);

/// The colours above, re-exported for the catalogue's not-caught rows, which
/// assert against the RENDERED FRAME and so have to name the same values the
/// fixtures painted with.
const Color advSurface = _surface;

/// See [advSurface].
const Color advLegibleInk = _legibleInk;

/// See [advSurface].
const Color advOpaqueCover = _opaqueCover;

/// See [advSurface].
const Color advRichSpanInk = _richSpanInk;

/// The backdrop every fixture paints on, sized well inside the 1280x800 view.
Widget _surfaceFrame(Widget child) {
  return Center(
    child: ColoredBox(
      color: _surface,
      child: SizedBox(width: 600, height: 400, child: child),
    ),
  );
}

/// A 60x60 labelled button that is genuinely live: it publishes one tap
/// route, it is big enough for the touch floor, and its glyph is legible.
///
/// Every UNREACHABLE fixture below wraps exactly this widget. The control is
/// held constant on purpose — the only difference between a fixture that
/// passes and one that does not is the mechanism placed around it, so a
/// violation can only be about that mechanism.
Widget _liveButton(String identifier) {
  return Semantics(
    container: true,
    identifier: identifier,
    label: 'Go',
    button: true,
    onTap: () {},
    child: const SizedBox(
      width: 60,
      height: 60,
      child: Center(
        child: Text(
          'Go',
          style: TextStyle(fontSize: 20, color: _legibleInk),
        ),
      ),
    ),
  );
}

/// THE DIFFERENTIAL CONTROL: the same [_liveButton], on the same backdrop,
/// with no mechanism around it.
///
/// Every UNREACHABLE fixture is this tree plus one widget. If this one does
/// not pass, every violation the catalogue attributes to a mechanism is
/// really an artefact of the button, the harness or the theme, and the whole
/// table is measuring itself.
Widget liveControlSurface() {
  return _surfaceFrame(Center(child: _liveButton('adv-control')));
}

// -----------------------------------------------------------------------------
// UNREACHABLE
// -----------------------------------------------------------------------------

/// A live button laid out OUTSIDE its `Stack`'s box, with the stack not
/// clipping.
///
/// The classic "it renders, so it must work" shape: `clipBehavior: Clip.none`
/// means the child still PAINTS and still publishes an unclipped semantics
/// rect, while `RenderBox.hitTest` on the stack rejects any position its own
/// `size` does not contain, so the pointer never descends to the child at all.
/// An `OverflowBox` produces the same defect by the same mechanism.
///
/// FIX: `top: 40` — inside the stack's 120px height.
Widget overflowingStackChild() {
  return _surfaceFrame(
    Center(
      child: SizedBox(
        width: 200,
        height: 120,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned(
              left: 70,
              top: 140,
              child: _liveButton('adv-stack-overflow'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A live button moved by a `Transform` that does NOT move its hit test.
///
/// `transformHitTests: false` is the documented way to animate a widget
/// without moving its touch target, and it is a defect the moment the
/// transform is not transient: the semantics rect follows the PAINT, so the
/// accessibility tree publishes the control where the user sees it, and the
/// hit test still runs at the untransformed position.
///
/// FIX: delete `transformHitTests: false` (it defaults to true).
Widget transformHitTestsDetached() {
  return _surfaceFrame(
    Center(
      child: Transform.translate(
        offset: const Offset(0, -120),
        transformHitTests: false,
        child: _liveButton('adv-transform-hit'),
      ),
    ),
  );
}

/// A live button covered by a later, translucent sibling in a `Stack`.
///
/// The button is VISIBLE — the cover is 10% black — and completely dead:
/// `ColoredBox` renders a `RenderProxyBoxWithHitTestBehavior` with
/// `HitTestBehavior.opaque`, so the later sibling takes every pointer that
/// lands on it and the walk never reaches the button.
///
/// The cover publishes no semantics node, so this is NOT the overlap rule
/// wearing a different hat: no two identified rects intersect here.
///
/// FIX: give the cover `IgnorePointer`, or move it below the button.
Widget coveredByLaterSibling() {
  return _surfaceFrame(
    Stack(
      children: <Widget>[
        Positioned(
          left: 40,
          top: 40,
          child: _liveButton('adv-covered'),
        ),
        const Positioned.fill(
          child: ColoredBox(color: Color(0x1A000000)),
        ),
      ],
    ),
  );
}

/// A live button inside `Visibility(visible: false)` that keeps its size, its
/// state and its SEMANTICS, and loses only its interactivity.
///
/// This is the maintain-* combination that keeps the accessibility node
/// exactly as it was — same rect, same label, same `button: true` — while
/// `Visibility` wraps the subtree in an `IgnorePointer`. A screen reader
/// offers the control; a finger cannot take it; a golden shows an empty slot.
///
/// FIX: `maintainInteractivity: true`, or stop publishing semantics for a
/// control that is not there.
Widget maintainedInvisibleControl() {
  return _surfaceFrame(
    Center(
      child: Visibility(
        visible: false,
        maintainSize: true,
        maintainState: true,
        maintainAnimation: true,
        maintainSemantics: true,
        child: _liveButton('adv-maintained'),
      ),
    ),
  );
}

/// A live button laid out entirely outside an ancestor `ClipRect`.
///
/// Declared here to MEASURE what the semantics pipeline does with a
/// fully-clipped node rather than to assert a defect up front: Flutter's
/// semantics compilation intersects a node's rect with its ancestors' paint
/// clips, and what the oracle can then say about the result is exactly what
/// the catalogue records.
Widget clippedOutControl() {
  return _surfaceFrame(
    Center(
      child: SizedBox(
        width: 200,
        height: 120,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            maxHeight: double.infinity,
            child: Padding(
              padding: const EdgeInsets.only(top: 200),
              child: _liveButton('adv-clipped-out'),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A live button whose ancestor has collapsed to zero size.
///
/// The commonest layout regression there is — a `SizedBox.shrink` left in, a
/// `Flexible` that resolved to nothing — and the one that removes the control
/// from the screen entirely.
Widget zeroSizeAncestorControl() {
  return _surfaceFrame(
    Center(
      child: SizedBox.shrink(
        child: _liveButton('adv-zero-size'),
      ),
    ),
  );
}

/// A live button behind `Offstage`, beside a control that is genuinely there.
///
/// The sibling exists so the surface is not empty: `expectUiSane` passes a
/// surface with no identified controls by design, and a fixture that measured
/// nothing would look like a pass for the wrong reason.
Widget offstageControl() {
  return _surfaceFrame(
    Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _liveButton('adv-offstage-sibling'),
          const SizedBox(width: 40),
          Offstage(
            child: _liveButton('adv-offstage'),
          ),
        ],
      ),
    ),
  );
}

/// A live button pushed past the right edge of the view by a `Transform`.
///
/// Here the transform DOES move the hit test, so the pointer path is honest
/// and the only thing wrong with the surface is that part of the control is
/// not on the screen.
///
/// FIX: delete the `Transform.translate`.
Widget transformedOutOfViewport() {
  return Center(
    child: SizedBox(
      width: 1280,
      height: 200,
      child: Align(
        alignment: Alignment.centerRight,
        child: Transform.translate(
          offset: const Offset(40, 0),
          child: _liveButton('adv-offscreen'),
        ),
      ),
    ),
  );
}

/// A control that announces a button and a tap route over a subtree with no
/// hit surface in it at all.
///
/// `SizedBox` with no child renders a `RenderConstrainedBox` whose
/// `hitTestSelf` is false and which has no children to hit, so nothing under
/// the semantics owner ever enters the pointer path. The node is fully sized
/// and fully presented; there is simply nothing there to touch.
///
/// FIX: put the control's content back inside the box.
Widget emptyHitSurfaceControl() {
  return _surfaceFrame(
    Center(
      child: Semantics(
        container: true,
        identifier: 'adv-empty-hit',
        label: 'Go',
        button: true,
        onTap: () {},
        child: const SizedBox(width: 60, height: 60),
      ),
    ),
  );
}

// -----------------------------------------------------------------------------
// UNREADABLE
// -----------------------------------------------------------------------------

/// Text painted through a `ShaderMask` that fills every glyph with the
/// background colour.
///
/// The resolved `TextStyle` says near-black on white. The frame says white on
/// white. This is the whole UNREADABLE class in one line: the style and the
/// pixels disagree, and the oracle reads ink from the style.
///
/// FIX: delete the `ShaderMask`.
Widget shaderMaskedText() {
  return _surfaceFrame(
    Center(
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (Rect bounds) => const LinearGradient(
          colors: <Color>[_surface, _surface],
        ).createShader(bounds),
        child: const Text(
          'Payment overdue',
          style: TextStyle(fontSize: 16, color: _legibleInk),
        ),
      ),
    ),
  );
}

/// Text painted through a `ColorFiltered` that replaces the ink with the
/// background colour.
///
/// Same disagreement as [shaderMaskedText] through a different widget, and
/// the one a theming layer is most likely to introduce: a colour filter
/// applied to a whole subtree for a disabled or "ghosted" look.
///
/// FIX: delete the `ColorFiltered`.
Widget colorFilteredText() {
  return _surfaceFrame(
    const Center(
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(_surface, BlendMode.srcIn),
        child: Text(
          'Balance 4200',
          style: TextStyle(fontSize: 16, color: _legibleInk),
        ),
      ),
    ),
  );
}

/// A 20px paragraph clipped to a 6px slot.
///
/// The glyphs are not painted inside the box the measurement reads — the
/// paragraph's own paint bounds are 20-odd pixels tall, the clip shows six of
/// them, and what fills the rest of the measured region is the surface behind
/// the clip. Nothing about the resolved style has changed.
///
/// FIX: give the slot the paragraph's real height.
Widget clippedGlyphsText() {
  return _surfaceFrame(
    const Center(
      child: SizedBox(
        width: 240,
        height: 6,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            maxHeight: double.infinity,
            child: Text(
              'Overdue notice',
              style: TextStyle(fontSize: 20, color: _legibleInk),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Text whose ink is a `Paint` carrying a SHADER.
///
/// `TextStyle.foreground` leaves `TextStyle.color` null — `copyWith` nulls it
/// out whenever a foreground is present — so the ink has to come off the
/// paint, and a paint carrying a shader has no single colour to read. The
/// shader here fills every glyph with the background colour.
///
/// The SOLID-paint half of this shape is `broken_surfaces.dart`'s
/// `paintedForegroundText`, which the oracle resolves correctly; this is the
/// half it cannot.
///
/// FIX: use `color:`, or a solid `Paint()..color = ...`.
Widget shaderForegroundText() {
  return _surfaceFrame(
    Center(
      child: Text(
        'Amount due',
        style: TextStyle(
          fontSize: 16,
          foreground: Paint()
            ..shader = const LinearGradient(
              colors: <Color>[_surface, _surface],
            ).createShader(const Rect.fromLTWH(0, 0, 200, 24)),
        ),
      ),
    ),
  );
}

/// Conformant text with an opaque, non-modal sibling painted over it.
///
/// The paragraph is in the tree, its style resolves to ~18:1, and not one
/// pixel of it reaches the frame. The cover is NOT a modal barrier, so the
/// scrim exemption does not apply and the text is squarely in scope.
///
/// FIX: remove the cover, or take the text out of the tree with it.
Widget textUnderOpaqueSibling() {
  return _surfaceFrame(
    const Stack(
      children: <Widget>[
        Positioned(
          left: 40,
          top: 40,
          child: Text(
            'Payment failed',
            style: TextStyle(fontSize: 16, color: _legibleInk),
          ),
        ),
        Positioned.fill(child: ColoredBox(color: _opaqueCover)),
      ],
    ),
  );
}

/// A `Text.rich` whose second span is ~1.1:1 against the surface.
///
/// The span carries its own colour, which is the shape `Text.data` cannot
/// express and the measurement therefore never sees. Recorded in the oracle
/// as a known limit; fixtured here so the limit is executable rather than
/// asserted in a comment.
///
/// FIX: measure per span.
Widget lowContrastRichSpan() {
  return _surfaceFrame(
    const Center(
      child: Text.rich(
        TextSpan(
          children: <TextSpan>[
            TextSpan(
              text: 'Due ',
              style: TextStyle(fontSize: 16, color: _legibleInk),
            ),
            TextSpan(
              text: 'today',
              style: TextStyle(fontSize: 16, color: _richSpanInk),
            ),
          ],
        ),
      ),
    ),
  );
}

// -----------------------------------------------------------------------------
// OTHER
// -----------------------------------------------------------------------------

/// A surface whose build throws.
///
/// The overflow branch of the escaped-exception report has a fixture
/// (`broken_surfaces.dart`'s `overflowingRow`); the GENERIC branch — any
/// other exception `FlutterError` swallowed during build, layout or paint —
/// had none, and it is the branch that carries every error a screen can hit
/// in production.
///
/// FIX: do not throw.
Widget throwingBuild() {
  return _surfaceFrame(
    Center(
      child: Builder(
        builder: (BuildContext context) =>
            throw StateError('adv-throwing-build'),
      ),
    ),
  );
}
