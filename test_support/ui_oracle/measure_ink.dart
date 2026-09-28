// MEASURING PAINTED INK FROM A REAL FRAME.
//
// WHY THIS EXISTS. A contrast test that asserts a hex value passes forever and
// says nothing the day the surface token moves underneath it. `expect(icon
// .color, EdenColors.neutral[900])` is green whether the row behind it is
// white or near-black; it is a spelling check, not a contrast check.
//
// So these helpers do what WCAG asks instead: take the ink the widget declares,
// take the surface it is ACTUALLY painted on out of the rasterised frame, and
// compute the ratio. When the band changes, the number changes, and the
// assertion is still measuring the thing it claims to.
//
// THE INK COMES FROM THE WIDGET, THE BACKGROUND COMES FROM THE PIXELS. Same
// split, and for the same reason, as `expectUiSane`'s painted-text rule: a
// 20px icon glyph in `MaterialIcons` has few full-coverage pixels, so a
// histogram-derived FOREGROUND reports the mode of the antialiased stroke
// shades and accuses conformant glyphs. The declared colour is not a guess —
// it is in the tree. Only the background has to be measured, and a glyph's box
// is mostly background, so its mode is reliable.
//
// SCOPE. This measures ONE node against the frame it was painted into. It is
// not a sweep: the sweep is `expectUiSane`'s job, and `Icon` is not in its walk
// yet (see eden-ui-flutter#55).
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.x contrast ratio between two OPAQUE colours.
///
/// Restated here rather than reached for: the copy inside `expectUiSane` is
/// private to it, and a test that computes its own number is the point.
double wcagContrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double hi = la > lb ? la : lb;
  final double lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// `#RRGGBB`, for a message a human can act on.
String hexOf(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).toUpperCase().padLeft(6, '0')}';

/// The colour the node found by [finder] is painted ON, read out of the
/// rasterised frame.
///
/// [ink] is excluded from the histogram — it and anything within rasteriser
/// rounding of it — so the answer is the surface and not the glyph.
///
/// Throws when the node paints nothing measurable, rather than answering a
/// value the caller would treat as a fact. A check that reports the same thing
/// for "fine" and "could not tell" is not a check.
Future<Color> paintedBackgroundOf(
  WidgetTester tester,
  Finder finder,
  Color ink,
) async {
  // GUARD (b): `_isNear` below compares ALL FOUR bytes of a candidate pixel
  // against `ink`'s own raw bytes, INCLUDING alpha. A rasterised frame is
  // opaque — every captured pixel's alpha byte is ~255 — so a translucent
  // `ink` (alpha < 1.0) can never be "near" anything the exclusion sees, the
  // exclusion never fires, and the ink's OWN composited pixels stay in the
  // histogram and can win the mode as "the background". The caller
  // (`expectInkContrast`) then does `Color.alphaBlend(ink, surface)` on TOP
  // of that already-composited value — blending the same translucent ink a
  // second time over its own appearance — and reports a ratio near 1.0:1
  // against a colour that was never the real surface. Refusing here, rather
  // than guessing, is the same principle `iconInk`'s `blendMode` guard
  // applies below: there is no single background this can recover from a
  // region that may be entirely the ink's own translucent fill, so it does
  // not answer one. Composite the ink against its actual background first
  // (`Color.alphaBlend`) and pass that OPAQUE colour instead.
  if (ink.a < 1.0) {
    throw StateError(
      'paintedBackgroundOf was asked to exclude a translucent ink '
      '(${hexOf(ink)}, alpha ${ink.a.toStringAsFixed(2)}). A translucent '
      "ink's own composited pixels never match its raw (unblended) bytes "
      'in a rasterised frame, so the exclusion cannot find them and they '
      'can win the histogram mode as "the background" — which reports a '
      'spurious near-1.0:1 ratio once the caller blends the same ink over '
      'it a second time. Composite the ink over its actual background '
      '(Color.alphaBlend) and pass that opaque colour instead.',
    );
  }

  final Element element = finder.evaluate().single;
  final RenderBox box = element.renderObject! as RenderBox;
  RenderObject? node = box;
  while (node != null && node is! RenderView) {
    node = node.parent;
  }
  final RenderView view = node! as RenderView;

  final Rect region = MatrixUtils.transformRect(
    box.getTransformTo(null),
    box.paintBounds,
  );

  ByteData? bytes;
  int width = 0;
  int height = 0;
  await tester.binding.runAsync<void>(() async {
    final ui.Image image =
        await (view.debugLayer! as OffsetLayer).toImage(
      view.paintBounds,
      // The INVERSE of the view's ratio, exactly as the stock guideline and
      // `expectUiSane` do it, or the image grid and the logical rects taken
      // from `getTransformTo(null)` are in different units.
      pixelRatio: 1 / view.flutterView.devicePixelRatio,
    );
    width = image.width;
    height = image.height;
    bytes = await image.toByteData();
    image.dispose();
  });
  final ByteData data = bytes!;

  final int inkArgb = ink.toARGB32();
  final Map<int, int> histogram = <int, int>{};
  for (int y = region.top.floor(); y < region.bottom.ceil(); y++) {
    for (int x = region.left.floor(); x < region.right.ceil(); x++) {
      // GUARD (c): `x` was never bounded to [0, width) — only the overall
      // buffer OFFSET was checked, which is row-agnostic. A node whose
      // paintBounds extend past the LEFT or RIGHT edge of the view lands an
      // offset that is still inside the buffer (it just addresses the
      // ADJACENT ROW), so the old check never caught it and the histogram
      // silently measured an unrelated region. Throwing on the node's own
      // geometry — not on the derived buffer offset — is what catches that;
      // clamping and continuing would answer a number for a node that was
      // only partially measured, which the caller would treat as a fact
      // about the whole one.
      if (x < 0 || x >= width || y < 0 || y >= height) {
        throw StateError(
          'the node found by $finder paints outside the frame: its rect is '
          '$region, and the view is (0, 0)-($width, $height). An off-frame '
          'pixel cannot be measured, so this refuses rather than silently '
          "reading whatever is at that offset in the buffer — which, for a "
          "row-wrapped x, is the ADJACENT ROW's colour, not this node's.",
        );
      }
      final int offset = (y * width + x) * 4;
      if (offset < 0 || offset + 3 >= data.lengthInBytes) {
        continue;
      }
      final int r = data.getUint8(offset);
      final int g = data.getUint8(offset + 1);
      final int b = data.getUint8(offset + 2);
      final int a = data.getUint8(offset + 3);
      final int argb = (a << 24) | (r << 16) | (g << 8) | b;
      histogram[argb] = (histogram[argb] ?? 0) + 1;
    }
  }

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
  if (best == null) {
    throw StateError(
      'every pixel inside ${element.widget.runtimeType} is the ink '
      '${hexOf(ink)} — there is no background to measure against. That is '
      '1.00:1, not an unmeasurable node.',
    );
  }
  return Color(best);
}

/// The colour the `Icon` found by [finder] is ACTUALLY PAINTED with,
/// including the `IconTheme` it would inherit when it declares none, and the
/// ancestor `IconTheme.opacity` it is dimmed by when one applies.
///
/// `Icon.build` (`packages/flutter/lib/src/widgets/icon.dart:293-297`)
/// applies the resolved `IconTheme.opacity` to the declared colour EVEN WHEN
/// `Icon.color` is set explicitly — Material installs a dimmed `IconTheme`
/// for disabled and secondary icon regions, so this is not a hypothetical.
/// Returning the declared colour unchanged under such a theme would report
/// the glyph MORE opaque than it is painted: the computed ratio reads HIGH
/// and the assertion passes a glyph that is actually failing. That is the
/// worst failure mode a conformance instrument has — it is not blind, it is
/// confidently wrong (`check-whose-failure-is-its-success`).
///
/// Throws when `Icon.blendMode` is set. `Icon.build` (same file, lines
/// 299-304) then paints through a `foreground` `Paint` instead of `color`,
/// and the painted result depends on the destination pixels beneath the
/// glyph — there is no single "ink" this can report, and answering one
/// anyway would be the same failure mode this guard exists to close.
Color iconInk(WidgetTester tester, Finder finder) {
  final Element element = finder.evaluate().single;
  final Icon icon = element.widget as Icon;
  if (icon.blendMode != null) {
    throw StateError(
      "iconInk cannot resolve ${icon.icon}'s ink: it declares a blendMode "
      '(${icon.blendMode}), and Icon.build paints it through a foreground '
      'Paint whose result depends on the destination pixels beneath it. '
      'There is no single colour to report.',
    );
  }
  final Color? declared = icon.color;
  final Color? inherited = IconTheme.of(element).color;
  final Color? base = declared ?? inherited;
  if (base == null) {
    throw StateError(
      'no resolvable ink for ${icon.icon} — neither Icon.color nor an '
      'ancestor IconTheme names one.',
    );
  }
  final double themeOpacity = IconTheme.of(element).opacity ?? 1.0;
  return themeOpacity == 1.0
      ? base
      : base.withValues(alpha: base.a * themeOpacity);
}

/// The colour the `Text` found by [finder] declares, including the
/// `DefaultTextStyle` it would inherit.
Color textInk(WidgetTester tester, Finder finder) {
  final Element element = finder.evaluate().single;
  final Text text = element.widget as Text;
  final TextStyle? declared = text.style;
  final TextStyle effective = declared == null || declared.inherit
      ? DefaultTextStyle.of(element).style.merge(declared)
      : declared;
  final Color? color = effective.color;
  if (color == null) {
    throw StateError('no resolvable ink for Text("${text.data}").');
  }
  return color;
}

/// The solid colour the `BoxDecoration` under [finder] declares.
///
/// The non-text counterpart of [iconInk]: a status dot, a rule, a swatch is a
/// `Container`, not an `Icon`, and 1.4.11 does not care which class painted it.
Color decorationInk(WidgetTester tester, Finder finder) {
  final Element element = finder.evaluate().first;
  RenderObject? node = element.renderObject;
  while (node != null && node is! RenderDecoratedBox) {
    node = node is RenderObjectWithChildMixin<RenderObject>
        ? node.child
        : null;
  }
  final Decoration? decoration = (node as RenderDecoratedBox?)?.decoration;
  if (decoration is! BoxDecoration || decoration.color == null) {
    throw StateError(
      'no solid BoxDecoration colour under $finder — nothing to measure.',
    );
  }
  return decoration.color!;
}

/// Measures [finder]'s declared [ink] against the surface it is painted on and
/// fails when the ratio is under [floor].
///
/// The failure message carries BOTH colours and the computed number, because a
/// contrast failure that only says "expected true" sends the reader back to
/// the frame to work out which of the two moved.
Future<void> expectInkContrast(
  WidgetTester tester,
  Finder finder,
  Color ink, {
  required double floor,
  required String what,
}) async {
  final Color surface = await paintedBackgroundOf(tester, finder, ink);
  final Color opaqueInk =
      ink.a == 1.0 ? ink : Color.alphaBlend(ink, surface);
  final double ratio = wcagContrast(opaqueInk, surface);
  expect(
    ratio,
    greaterThanOrEqualTo(floor),
    reason: '$what is ${ratio.toStringAsFixed(2)}:1 — ink ${hexOf(opaqueInk)} '
        'on the surface it is painted on, ${hexOf(surface)}. The floor is '
        '$floor:1. This ratio is COMPUTED from the resolved colours and the '
        'rasterised frame, so either the ink token or the surface token moved.',
  );
}

/// Whether two ARGB values are the same colour up to rasteriser rounding.
bool _isNear(int a, int b) {
  for (int shift = 0; shift <= 24; shift += 8) {
    final int ca = (a >> shift) & 0xFF;
    final int cb = (b >> shift) & 0xFF;
    if (ca - cb > 2 || cb - ca > 2) {
      return false;
    }
  }
  return true;
}
