// Regression tests OF THE INSTRUMENT, not of a widget.
//
// WHY THIS FILE EXISTS. `measure_ink.dart`'s helpers are what every contrast
// assertion in this suite trusts to read "what colour is actually painted
// here" out of a rasterised frame. Three defects in those helpers survived
// an audit that was looking straight at the surfaces they measure, because
// nobody had ever tested the MEASURING TOOL itself against a case built to
// fool it (eden-ui-flutter#58 code review).
//
// (a) and (b) are opposite failure modes on the same axis. (a) is SILENT —
// `iconInk` reports a colour MORE opaque than what is actually painted, so a
// real defect passes. (b) is NOISY — `paintedBackgroundOf` given a
// translucent ink reports a spurious ~1.0:1 against the wrong colour, so a
// real pass can read as a failure. Both are wrong; only (a) is dangerous,
// because a check that fails loudly gets noticed and a check that passes
// silently does not — see `check-whose-failure-is-its-success`.
//
// (c) is a geometry bug: a node whose paintBounds extend past the view's
// edge is read as if it were fully on-frame, silently sampling the ADJACENT
// ROW's pixels and answering a number for a node that was never actually
// measured in full.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/ui_oracle/measure_ink.dart';
import '../../test_support/ui_oracle/wrap.dart';

void main() {
  group('(a) iconInk under a dimming ancestor IconTheme', () {
    testWidgets(
        'does not report a glyph more opaque than it is actually painted',
        (WidgetTester tester) async {
      const Color declared = Color(0xFF112233);
      await wrap(
        tester,
        const IconTheme(
          data: IconThemeData(opacity: 0.5),
          child: Icon(
            Icons.home,
            key: ValueKey<String>('probe-dimmed-icon'),
            color: declared,
          ),
        ),
      );
      final Finder icon =
          find.byKey(const ValueKey<String>('probe-dimmed-icon'));
      final Color resolved = iconInk(tester, icon);
      expect(
        resolved,
        isNot(equals(declared)),
        reason: 'Icon.build '
            '(packages/flutter/lib/src/widgets/icon.dart:293-297) applies '
            "the ancestor IconTheme's opacity to the declared colour EVEN "
            'WHEN Icon.color is set explicitly. iconInk must report what is '
            'actually painted — a glyph dimmed by IconTheme(opacity: 0.5) '
            "is not painted at its declared colour's full alpha, and "
            'reporting it as such measures the glyph MORE opaque than the '
            'pixels: the ratio reads HIGH and the assertion passes on a '
            'glyph that is actually failing.',
      );
      expect(
        resolved.a,
        closeTo(declared.a * 0.5, 0.01),
        reason: 'the painted alpha is the declared alpha times the '
            "ancestor IconTheme's opacity.",
      );
    });

    testWidgets('throws for an Icon with a blendMode rather than guessing',
        (WidgetTester tester) async {
      await wrap(
        tester,
        const Icon(
          Icons.home,
          key: ValueKey<String>('probe-blendmode-icon'),
          color: Color(0xFF112233),
          blendMode: BlendMode.srcIn,
        ),
      );
      expect(
        () => iconInk(tester,
            find.byKey(const ValueKey<String>('probe-blendmode-icon'))),
        throwsA(isA<StateError>()),
        reason: 'Icon.build paints through a foreground Paint when '
            'blendMode is set, and the painted result depends on the '
            'destination pixels beneath it — there is no single ink to '
            'report, and answering one anyway is the failure mode this '
            'file exists to close.',
      );
    });
  });

  group('(b) paintedBackgroundOf given a translucent ink', () {
    testWidgets(
        'refuses rather than reporting a spurious ~1.0:1 against its own '
        'composited pixels', (WidgetTester tester) async {
      // Alpha 0x1A — the same shape as `successBg`/`warningBg`, and the rail
      // band this review flagged (`primary` at 10% alpha) is the same class.
      const Color translucentInk = Color(0x1A10B981);
      await wrap(
        tester,
        Container(
          key: const ValueKey<String>('probe-translucent-fill'),
          width: 80,
          height: 80,
          color: translucentInk,
        ),
      );
      final Finder probe =
          find.byKey(const ValueKey<String>('probe-translucent-fill'));
      expect(
        () => paintedBackgroundOf(tester, probe, translucentInk),
        throwsA(isA<StateError>()),
        reason: '_isNear compares ALL FOUR bytes including alpha, so a '
            'translucent ink never matches any opaque frame pixel in a '
            "rasterised capture: the exclusion never fires, the ink's own "
            'composited pixels stay in the histogram and win the mode, and '
            'the caller (expectInkContrast) then double-blends the SAME '
            'ink a second time over its own already-composited appearance '
            'and reports ~1.0:1 against the WRONG colour — a spurious '
            'failure pointing at nothing. paintedBackgroundOf must refuse a '
            'translucent ink rather than silently mis-measure one; the '
            'caller composites it against its actual background '
            '(Color.alphaBlend) and passes that opaque colour instead.',
      );
    });
  });

  group('(c) paintedBackgroundOf given an off-frame node', () {
    testWidgets('throws rather than reading the adjacent row',
        (WidgetTester tester) async {
      await wrap(
        tester,
        const SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 80,
                top: 10,
                child: ColoredBox(
                  key: ValueKey<String>('probe-off-frame'),
                  color: Color(0xFF00FF00),
                  child: SizedBox(width: 50, height: 50),
                ),
              ),
            ],
          ),
        ),
        width: 100,
      );
      final Finder probe =
          find.byKey(const ValueKey<String>('probe-off-frame'));
      expect(
        () => paintedBackgroundOf(tester, probe, const Color(0xFF00FF00)),
        throwsA(isA<StateError>()),
        reason: 'the sampling loop guards offset < 0 and offset + 3 >= '
            'lengthInBytes — both row-agnostic — but never bounds x to '
            '[0, width). This probe paints at x=80..130 against a '
            '100px-wide frame: without the bound, x=100..129 silently '
            "reads the NEXT ROW's bytes at an offset that is still inside "
            "the buffer, rather than crashing or being skipped, and the "
            "histogram mode can be an unrelated region's colour. A node "
            'whose paintBounds leave the view must throw, naming the '
            "node's rect and the view's, rather than answering a number "
            'for a node that was only partially measured.',
      );
    });
  });
}
