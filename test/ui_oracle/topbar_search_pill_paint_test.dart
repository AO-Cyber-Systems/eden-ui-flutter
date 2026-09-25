// The top bar's search pill, held to what it actually PAINTS.
//
// THE DEFECT THIS PINS. `_TopBar` draws the search affordance as a
// `Container(height: 36)` with a `surfaceContainerHighest` fill and a full
// border radius — a rounded grey pill — and puts a `TextField` inside it. The
// field's own `InputDecoration` sets `border: InputBorder.none`,
// `isDense: true` and `contentPadding: EdgeInsets.zero`, but it does NOT turn
// the fill off, so it inherits `EdenTheme`'s `inputDecorationTheme`:
//
//     filled: true,
//     fillColor: isDark ? EdenColors.neutral[800] : Colors.white,
//
// and paints an OPAQUE rectangle on top of the pill. Measured on
// `desktop-layout/default` at 1280x800, light theme, from the same captured
// frame the oracle reads (device pixel ratio 1, so image rows are logical
// pixels):
//
//   the pill's DecoratedBox  Rect.fromLTRB(388.9, 9.5, 1252.0, 45.5)
//   the InputDecorator       Rect.fromLTRB(426.9, 9.5, 1240.0, 45.5)
//   pixels at x=410 (over the search icon, no decorator above it)
//                            #e4e4e7 for y = 9..44   — the full 36px pill
//   pixels at x=813 (over the hint text)
//                            #ffffff for y = 11..28  — the decorator's fill
//                            #e4e4e7 for y = 30..44  — the pill, below it
//
// So the pill IS 36px and IS painted 36px tall; what is short is the white
// rectangle the decorator paints over it. `_RenderDecoration` sizes that fill
// from the decorator's CONTENT height (the ~20px line box), not from the 36px
// the enclosing `SizedBox` forces on it, which is why the leftover pill fill
// reads as a ~16px band under the text instead of the text simply sitting on
// a white box.
//
// Same family as the `Semantics` defect `892ca8d` fixed on this very control
// — a wrapper inside `Container(height: 36)` around a `TextField` carrying
// `isDense: true` and `contentPadding: EdgeInsets.zero` — but through PAINT
// rather than through semantics.
//
// WHY THIS IS NOT A MEASUREMENT ARTIFACT. The oracle read the hint at 4.83:1
// where its token pair is 3.81:1, and the discrepancy was recorded as a
// possible artifact of how the frame is captured. It is not: the frame is
// right and the widget is wrong. The oracle measured the background the glyph
// is genuinely painted over — `Colors.white` — because that is what is there.
//
// AND IT WAS MASKING A REAL 1.4.3 FAILURE. Once the overpaint is gone the
// hint sits on the pill's own fill, which is what `surfaceContainerHighest`
// was for, and `onSurfaceVariant` on it is 3.81:1 at fontSize 13 — below the
// 4.5:1 floor. Case 2 is that failure, stated against the TOKENS so it is red
// whatever the frame happens to show, and case 3 is its dark-theme twin.
//
// LIGHT THEME ONLY for case 1, deliberately. In the dark theme
// `inputDecorationTheme.fillColor` is `neutral[800]` and
// `surfaceContainerHighest` is ALSO `neutral[800]`, so the overpaint is the
// same colour as the thing it covers and there is nothing a pixel assertion
// could see. A dark case here could not fail, and a case that cannot fail is
// not a case.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const String _kHint = 'Search orders…';

const EdenTopBarConfig _topBar = EdenTopBarConfig(
  title: 'Orders',
  showSearch: true,
  searchHint: _kHint,
);

Future<void> _pumpShell(WidgetTester tester, ThemeMode mode) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1280, 800);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    theme: EdenTheme.light(),
    darkTheme: EdenTheme.dark(),
    themeMode: mode,
    home: EdenDesktopLayout(
      navItems: const <EdenNavItem>[
        EdenNavItem(
          id: 'inventory',
          label: 'Inventory',
          icon: Icons.inventory_2,
        ),
      ],
      selectedId: 'inventory',
      onNavChanged: (_) {},
      topBar: _topBar,
      body: const SizedBox(),
    ),
  ));
  await tester.pumpAndSettle();
}

/// The hint's `Text` element, and the ink it resolves to — read off the
/// resolved `TextStyle` exactly as `expectUiSane`'s contrast rule does, so
/// this file and the oracle can never disagree about what colour the glyph is.
({Element element, Color ink, double fontSize}) _hint(WidgetTester tester) {
  final Element element = find.text(_kHint).evaluate().single;
  final Text widget = element.widget as Text;
  final TextStyle? declared = widget.style;
  final TextStyle effective = declared == null || declared.inherit
      ? DefaultTextStyle.of(element).style.merge(declared)
      : declared;
  return (
    element: element,
    ink: effective.color!,
    fontSize: effective.fontSize ?? 12,
  );
}

/// The captured frame, in the same units and at the same pixel ratio the
/// oracle captures it.
Future<({ByteData data, int width, int height})> _capture(
  WidgetTester tester,
) async {
  final RenderView renderView = tester.binding.renderViews.first;
  final OffsetLayer layer = renderView.debugLayer! as OffsetLayer;
  late ByteData data;
  late int width;
  late int height;
  await tester.binding.runAsync<void>(() async {
    final ui.Image image = await layer.toImage(
      renderView.paintBounds,
      pixelRatio: 1 / renderView.flutterView.devicePixelRatio,
    );
    width = image.width;
    height = image.height;
    data = (await image.toByteData())!;
    image.dispose();
  });
  return (data: data, width: width, height: height);
}

/// The most common colour inside [region] of the captured frame — the surface
/// a paragraph is painted on, since a line box is mostly background.
Color _dominantColour(
  ByteData data,
  int imageWidth,
  int imageHeight,
  Rect region,
) {
  final Map<int, int> counts = <int, int>{};
  final int left = region.left.floor().clamp(0, imageWidth - 1);
  final int right = region.right.ceil().clamp(0, imageWidth);
  final int top = region.top.floor().clamp(0, imageHeight - 1);
  final int bottom = region.bottom.ceil().clamp(0, imageHeight);
  for (int y = top; y < bottom; y++) {
    for (int x = left; x < right; x++) {
      final int offset = (y * imageWidth + x) * 4;
      final int argb = (data.getUint8(offset + 3) << 24) |
          (data.getUint8(offset) << 16) |
          (data.getUint8(offset + 1) << 8) |
          data.getUint8(offset + 2);
      counts[argb] = (counts[argb] ?? 0) + 1;
    }
  }
  int best = 0;
  int bestCount = -1;
  counts.forEach((int argb, int count) {
    if (count > bestCount) {
      best = argb;
      bestCount = count;
    }
  });
  return Color(best);
}

double _channel(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

/// WCAG 2.x relative-luminance contrast ratio.
double _contrastRatio(Color a, Color b) {
  final double la = _luminance(a);
  final double lb = _luminance(b);
  final double hi = la > lb ? la : lb;
  final double lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  testWidgets(
    'case 1: the search hint is painted on the PILL, not on the top bar — '
    'nothing opaque is drawn over the pill fill (light)',
    (WidgetTester tester) async {
      await _pumpShell(tester, ThemeMode.light);
      final ColorScheme scheme = EdenTheme.light().colorScheme;
      final RenderBox box = tester.renderObject<RenderBox>(find.text(_kHint));
      final Rect region = MatrixUtils.transformRect(
        box.getTransformTo(null),
        box.paintBounds,
      );
      final ({ByteData data, int width, int height}) frame =
          await _capture(tester);
      final Color painted = _dominantColour(
        frame.data,
        frame.width,
        frame.height,
        region,
      );

      expect(
        painted,
        scheme.surfaceContainerHighest,
        reason: 'the hint paragraph occupies $region, which is inside the '
            "search pill's 36px box, but the surface it is actually painted "
            'on is $painted instead of the pill fill '
            '${scheme.surfaceContainerHighest}. The TextField inherits '
            "EdenTheme's inputDecorationTheme (filled: true, fillColor: "
            'Colors.white) and paints an opaque rectangle over the pill. Set '
            'filled: false on the search field: the pill IS the fill.',
      );
    },
  );

  for (final (String mode, ThemeMode themeMode, ThemeData Function() build)
      in <(String, ThemeMode, ThemeData Function())>[
    ('light', ThemeMode.light, EdenTheme.light),
    ('dark', ThemeMode.dark, EdenTheme.dark),
  ]) {
    testWidgets(
      'case 2 ($mode): the search hint clears WCAG 1.4.3 against the fill of '
      'the pill it sits in',
      (WidgetTester tester) async {
        await _pumpShell(tester, themeMode);
        final ColorScheme scheme = build().colorScheme;
        final ({Element element, Color ink, double fontSize}) hint =
            _hint(tester);
        final double ratio =
            _contrastRatio(hint.ink, scheme.surfaceContainerHighest);

        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: 'the hint is ${hint.ink} at ${hint.fontSize}px on the '
              "pill's ${scheme.surfaceContainerHighest} fill — "
              '${ratio.toStringAsFixed(2)}:1, below 1.4.3\'s 4.5:1 floor for '
              'text under 18px. This pair was invisible while the field '
              'painted an opaque white rectangle over the pill: the oracle '
              'measured the hint at 4.83:1 against THAT, and the pill fill '
              'the design puts behind the hint was never the surface the '
              'glyph was on.',
        );
      },
    );
  }
}
