// An INDEPENDENT reading of the rendered frame, for the adversarial
// catalogue's not-caught rows.
//
// WHY IT DOES NOT REUSE THE ORACLE. A row that says "the oracle misses this"
// is only worth reading if something OTHER than the oracle establishes that
// there was something to miss. Measuring the miss with the oracle's own
// private histogram would prove nothing — a shared bug would cancel out on
// both sides and the row would read green while the surface was fine, or red
// while it was broken, for reasons neither side could see.
//
// So this file captures the frame and counts pixels itself, in about thirty
// lines, and the catalogue asserts BOTH halves of every not-caught row:
//
//   * `expectUiSane` says nothing, and
//   * the frame is provably wrong — no ink pixel of the paragraph reaches it,
//     or the ink that does reach it is below the WCAG floor.
//
// It is deliberately small and deliberately dumb. It is not a second oracle.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';

/// The ARGB colour histogram of the rendered frame inside [finder]'s paint
/// bounds, keyed by packed ARGB and counted in device pixels.
///
/// The capture mirrors what any screenshot of this surface would contain:
/// `wrap()` pins the device pixel ratio to 1, so the image's pixel grid and
/// the logical rect below are in the same units.
Future<Map<int, int>> frameHistogramOf(
  WidgetTester tester,
  Finder finder,
) async {
  final RenderBox box = tester.renderObject<RenderBox>(finder);
  final Rect region = MatrixUtils.transformRect(
    box.getTransformTo(null),
    box.paintBounds,
  );
  final RenderView renderView = tester.binding.renderViews.first;
  final OffsetLayer layer = renderView.debugLayer! as OffsetLayer;

  ByteData? bytes;
  int width = 0;
  await tester.runAsync<void>(() async {
    final ui.Image image = await layer.toImage(
      renderView.paintBounds,
      pixelRatio: 1 / renderView.flutterView.devicePixelRatio,
    );
    width = image.width;
    bytes = await image.toByteData();
    image.dispose();
  });
  final ByteData? data = bytes;
  if (data == null) {
    return const <int, int>{};
  }

  final Map<int, int> counts = <int, int>{};
  for (int x = region.left.floor(); x < region.right.ceil(); x++) {
    for (int y = region.top.floor(); y < region.bottom.ceil(); y++) {
      if (x < 0 || y < 0) {
        continue;
      }
      final int offset = (y * width + x) * 4;
      if (offset < 0 || offset + 4 > data.lengthInBytes) {
        continue;
      }
      final int rgba = data.getUint32(offset);
      final int argb = (rgba << 24) | ((rgba >> 8) & 0xFFFFFF);
      counts.update(argb, (int c) => c + 1, ifAbsent: () => 1);
    }
  }
  return counts;
}

/// How many pixels in [histogram] are [colour], within [tolerance] per
/// channel.
///
/// A tolerance is required and not a convenience: a glyph is antialiased, so
/// asking for an exact match would answer "no ink" on text that is plainly
/// painted. Counting near-matches is what makes "zero ink pixels" mean the
/// glyph is genuinely not on the frame.
int pixelsNear(
  Map<int, int> histogram,
  Color colour, {
  int tolerance = 8,
}) {
  final int want = colour.toARGB32();
  int total = 0;
  for (final MapEntry<int, int> entry in histogram.entries) {
    bool near = true;
    for (int shift = 0; shift <= 24; shift += 8) {
      final int a = (entry.key >> shift) & 0xFF;
      final int b = (want >> shift) & 0xFF;
      if ((a - b).abs() > tolerance) {
        near = false;
        break;
      }
    }
    if (near) {
      total += entry.value;
    }
  }
  return total;
}

/// The most frequent colour in [histogram], or null when it is empty.
Color? dominantColour(Map<int, int> histogram) {
  int? best;
  int bestCount = -1;
  for (final MapEntry<int, int> entry in histogram.entries) {
    if (entry.value > bestCount) {
      best = entry.key;
      bestCount = entry.value;
    }
  }
  return best == null ? null : Color(best);
}

/// The WCAG 2.x contrast ratio between two opaque colours.
double contrastRatio(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double hi = la > lb ? la : lb;
  final double lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
