// The INDEPENDENT frame reader, read independently.
//
// WHY THIS FILE EXISTS. `frame_probe.dart` is what makes a `notCaught` row in
// the adversarial catalogue two-sided: the oracle says nothing AND the frame
// is provably wrong. A row is only worth reading if the second half is at
// least as trustworthy as the first, and this reader had a hole the thing it
// checks did not: it clamped x and y at ZERO and never at the image's width.
//
// The buffer is one flat scanline array, so `x >= width` is not an invalid
// offset — it is the pixel at `(x - width, y + 1)`. A region that runs past
// the right edge therefore folded the NEXT ROW's left-hand pixels into the
// histogram, silently, and the "independent proof" for every not-caught row
// was the weaker reader of the two. `_argbHistogram` in `expect_ui_sane.dart`
// has always clipped the region to the image and bounded both axes.
//
// The surface below is built so the wrap is UNAMBIGUOUS: the overhanging box
// is one flat colour, the pixels it wraps onto are a DIFFERENT flat colour,
// and the two are nowhere near each other on the frame. Counting one red
// pixel inside a blue box's histogram is not a tolerance question.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/ui_oracle/_fixtures/frame_probe.dart';
import '../../test_support/ui_oracle/wrap.dart';

/// The overhanging box. 200 wide starting at x=1200 in a 1280 viewport, so
/// 80 columns are on the frame and 120 are past its right edge.
const Color _overhang = Color(0xFF0033CC);

/// What the overhanging columns would wrap ONTO: the left 200px of the next
/// scanline, which is a different flat colour at the same rows.
const Color _wrapTarget = Color(0xFFCC0000);

const Color _page = Color(0xFFFFFFFF);

const Key _overhangKey = ValueKey<String>('fp-overhang');

/// A 1280x400 page carrying a red band flush against the LEFT edge and a blue
/// box overhanging the RIGHT edge, at the same rows.
///
/// `Stack(clipBehavior: Clip.none)` is what lets the blue box keep a paint
/// bounds that extends past the viewport — which is the whole premise. If the
/// stack ever starts clipping, the first assertion in the test (the region
/// really does run past the frame) fails and says so, rather than the test
/// quietly measuring a box that fits.
Widget overhangingBoxSurface() {
  return const SizedBox(
    height: 400,
    child: Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(child: ColoredBox(color: _page)),
        Positioned(
          left: 0,
          top: 40,
          width: 200,
          height: 200,
          child: ColoredBox(color: _wrapTarget),
        ),
        Positioned(
          left: 1200,
          top: 40,
          width: 200,
          height: 200,
          child: ColoredBox(color: _overhang, key: _overhangKey),
        ),
      ],
    ),
  );
}

void main() {
  testWidgets(
      'case 1: a region running past the right edge does not wrap onto the '
      'next scanline', (WidgetTester tester) async {
    await wrap(tester, overhangingBoxSurface());

    final Finder finder = find.byKey(_overhangKey);
    final RenderBox box = tester.renderObject<RenderBox>(finder);
    final Rect region = MatrixUtils.transformRect(
      box.getTransformTo(null),
      box.paintBounds,
    );

    // THE PREMISE, asserted rather than assumed. A clipped or relaid-out
    // surface would make every assertion below pass for the wrong reason.
    expect(
      region.right,
      greaterThan(1280),
      reason: 'the box no longer overhangs the frame, so this case is not '
          'exercising the bound it exists for',
    );
    expect(region.left, 1200);
    expect(region.width, 200);
    expect(region.height, 200);

    final Map<int, int> histogram = await frameHistogramOf(tester, finder);

    // RED (before the `x >= width` bound): the 120 off-frame columns are read
    // as `(x - 1280, y + 1)`, which lands inside the red band, and this is
    // ~23,880 rather than 0.
    expect(
      pixelsNear(histogram, _wrapTarget, tolerance: 0),
      0,
      reason: 'the histogram of a BLUE box contains RED pixels. The only red '
          'on this frame is 1200 logical pixels to the left, on the next '
          'scanline — the offset wrapped.',
    );

    // The 80 columns that ARE on the frame, all 200 rows of them. Asserted so
    // a bound that clamped too hard (and read nothing at all) is a failure
    // too, not a silent pass on an empty histogram.
    expect(pixelsNear(histogram, _overhang, tolerance: 0), 80 * 200);
    expect(
      histogram.values.fold<int>(0, (int a, int b) => a + b),
      80 * 200,
      reason: 'the histogram counted pixels that are neither the box nor '
          'nothing — something else was swept in',
    );
  });
}
