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
    bytes = await image.toByteData();
    image.dispose();
  });
  final ByteData data = bytes!;

  final int inkArgb = ink.toARGB32();
  final Map<int, int> histogram = <int, int>{};
  for (int y = region.top.floor(); y < region.bottom.ceil(); y++) {
    for (int x = region.left.floor(); x < region.right.ceil(); x++) {
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

/// The colour the `Icon` found by [finder] declares, including the
/// `IconTheme` it would inherit when it declares none.
Color iconInk(WidgetTester tester, Finder finder) {
  final Element element = finder.evaluate().single;
  final Icon icon = element.widget as Icon;
  final Color? declared = icon.color;
  if (declared != null) {
    return declared;
  }
  final Color? inherited = IconTheme.of(element).color;
  if (inherited == null) {
    throw StateError(
      'no resolvable ink for ${icon.icon} — neither Icon.color nor an '
      'ancestor IconTheme names one.',
    );
  }
  return inherited;
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
