// Fields that let their parent be the chrome, held to what they actually
// PAINT.
//
// THE CLASS THIS PINS. `EdenTheme`'s `inputDecorationTheme` is
//
//     filled: true,
//     fillColor: isDark ? EdenColors.neutral[800] : Colors.white,
//
// which is library-wide. A widget that draws its own background — a
// `Container` with a fill, a scrim, a card the field is meant to sit flat on
// — and then puts a `TextField` inside it WITHOUT turning that fill off gets
// an opaque rectangle painted over the background it just declared. The
// background is still in the widget tree and still in the code; it is simply
// never seen.
//
// `_TopBar`'s search pill was the first instance (`c5f367e`, pinned by
// `topbar_search_pill_paint_test.dart`). This file is the sweep of the rest.
// Each case below was confirmed from the RENDERED FRAME before it was fixed —
// the painted colour inside the field's own box disagreed with the fill the
// parent declares — and the assertion is written against the frame, not
// against the widget tree, so it stays true of what a user sees.
//
// FOUR INSTANCES, and what the overpaint measured:
//
//   eden_photo_capture_page  caption over a `Colors.black.withValues(alpha:
//                            0.55)` scrim on the photo. Light theme: an
//                            OPAQUE WHITE box, and the caption's own ink is
//                            `Colors.white` with a `Colors.white70` hint — so
//                            both rendered at 1.00:1. Invisible text on an
//                            invisible scrim. Against the scrim the same ink
//                            is 21.00:1 and the hint 9.90:1.
//   eden_rich_text_editor    body over the editor frame's
//                            `neutral[900]` (dark). Every border on that
//                            field is explicitly `InputBorder.none`, so the
//                            frame is unambiguously meant to be the chrome;
//                            the fill painted `neutral[800]` over it, a
//                            1.19:1 step, and the toolbar directly above kept
//                            the frame colour — a visible seam.
//   eden_secret_field        the `Container(color: surfaceBg)` that wraps this
//                            field has the SAME border radius as the field
//                            and holds nothing else: it exists to be the
//                            field's background, and was 100% covered.
//                            neutral[800] over neutral[900] in dark (1.19:1),
//                            white over neutral[50] in light (1.04:1).
//   eden_env_editor          KEY and value cells declare
//                            `border: InputBorder.none` — inline cells on the
//                            editor's card — and painted boxes over it.
//
// LIGHT-ONLY AND DARK-ONLY CASES ARE DELIBERATE. Where the theme's fill and
// the parent's fill are the SAME colour there is nothing a pixel assertion
// could see, and a case that cannot fail is not a case. `EdenRichTextEditor`'s
// frame is `Colors.white` in light and the theme's light fill is also
// `Colors.white`, so only its dark case exists.
//
// NOT IN THIS FILE, recorded so the gap is known rather than assumed:
//
//   * The theme's `enabledBorder` leaks the same way the fill did. A field
//     that sets only `border: InputBorder.none` still resolves
//     `InputDecorationTheme.enabledBorder` for the enabled state, so an
//     `OutlineInputBorder` in `colorScheme.outline` is painted over the
//     parent's chrome — measured at the decorator's top edge in
//     `EdenPhotoCapturePage` (#d4d4d8 over the scrim), `EdenEnvEditor`,
//     `EdenMessageInput`, `EdenMapView`, `EdenMarkdownEditor`,
//     `EdenLineItemEditor` — and in `_TopBar` itself, whose pill still carries
//     a faint #d4d4d8 ring inside it after `c5f367e`. That is a BORDER, not a
//     fill; it is the same root cause and a separate change.
//   * `EdenMessageInput` and `EdenBarcodeScanner` do overpaint in light, but
//     white over `neutral[50]` is a 1.04:1 step — below anything an eye or a
//     golden threshold resolves. Reported, not changed.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

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

/// The most common colour inside [region] of the captured frame.
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

Future<void> _pump(
  WidgetTester tester,
  Widget surface,
  ThemeMode mode, {
  Size size = const Size(900, 700),
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    theme: EdenTheme.light(),
    darkTheme: EdenTheme.dark(),
    themeMode: mode,
    home: Scaffold(body: surface),
  ));
  await tester.pumpAndSettle();
}

/// The colour actually painted inside the single [InputDecorator] on screen,
/// sampled over the field's own box and away from its border and its text.
Future<Color> _paintedFieldSurface(WidgetTester tester) async {
  final RenderBox box = tester.renderObject<RenderBox>(
    find.byType(InputDecorator),
  );
  final Rect rect = MatrixUtils.transformRect(
    box.getTransformTo(null),
    Offset.zero & box.size,
  );
  final ({ByteData data, int width, int height}) frame = await _capture(tester);
  return _dominantColour(
    frame.data,
    frame.width,
    frame.height,
    rect.deflate(4),
  );
}

void main() {
  group('EdenPhotoCapturePage — the caption sits on the photo scrim', () {
    Widget surface() => EdenPhotoCapturePage(
          cameraPreviewBuilder: (_) => const ColoredBox(color: Color(0xFF3366AA)),
          onCapture: (EdenPhotoCaptureRequest r) async => EdenCapturedPhoto(
            // An empty path renders `ColoredBox(color: Colors.black)`, so the
            // surface under the scrim is a known, fixed colour.
            filePath: '',
            capturedAt: DateTime(2026),
          ),
        );

    Future<void> capture(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('eden_photo_capture_shutter')));
      await tester.pumpAndSettle();
    }

    for (final (String name, ThemeMode mode)
        in <(String, ThemeMode)>[('light', ThemeMode.light), ('dark', ThemeMode.dark)]) {
      testWidgets(
        '$name: nothing opaque is painted over the scrim the caption sits on',
        (WidgetTester tester) async {
          await _pump(tester, surface(), mode);
          await capture(tester);
          final Color painted = await _paintedFieldSurface(tester);

          expect(
            painted,
            const Color(0xFF000000),
            reason: 'the caption field sits inside '
                'Container(color: Colors.black.withValues(alpha: 0.55)) over a '
                'black photo, so the surface under it is black. It painted '
                '$painted instead, because the field inherits EdenTheme\'s '
                'inputDecorationTheme (filled: true) and covers the scrim with '
                'an opaque rectangle. Set filled: false — the scrim is the '
                'fill.',
          );
        },
      );
    }

    // LIGHT ONLY, deliberately. In the dark theme the overpaint is
    // `neutral[800]` and `Colors.white70` on it is 8.02:1 — this case was
    // GREEN before the fix and stays green after it, so as a RED case it
    // could not fail. The light theme is where the overpaint is white and the
    // hint composites to 1.00:1.
    testWidgets(
        'light: the caption hint clears WCAG 1.4.3 against what it is '
        'painted on',
        (WidgetTester tester) async {
          await _pump(tester, surface(), ThemeMode.light);
          await capture(tester);
          final Color painted = await _paintedFieldSurface(tester);

          final Element element = find.text('Add a note (optional)')
              .evaluate()
              .single;
          final Text widget = element.widget as Text;
          final TextStyle? declared = widget.style;
          final TextStyle effective = declared == null || declared.inherit
              ? DefaultTextStyle.of(element).style.merge(declared)
              : declared;
          final Color ink = Color.alphaBlend(effective.color!, painted);
          final double ratio = _contrastRatio(ink, painted);

          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: 'the hint is ${effective.color} at '
                '${effective.fontSize}px and composites to $ink on the $painted '
                'the field actually paints — ${ratio.toStringAsFixed(2)}:1. '
                'Colors.white70 on an opaque white fill is 1.00:1: the hint is '
                'not low-contrast, it is INVISIBLE. Against the scrim the '
                'design puts behind it the same ink is 9.90:1.',
          );
        },
      );
  });

  testWidgets(
    'EdenRichTextEditor (dark): the body is painted on the frame it sits in, '
    'not on a box of its own',
    (WidgetTester tester) async {
      await _pump(
        tester,
        const EdenRichTextEditor(placeholder: 'Write…'),
        ThemeMode.dark,
      );
      final Color painted = await _paintedFieldSurface(tester);

      expect(
        painted,
        EdenColors.neutral[900],
        reason: 'the editor frame is Container(color: neutral[900]) and every '
            "border on the field is InputBorder.none, so the frame is the "
            'editor\'s chrome. The body painted $painted — the theme\'s '
            "neutral[800] fill — over it, a 1.19:1 step that leaves the "
            'toolbar directly above it a different colour from the body '
            'below. Set filled: false.',
      );
    },
  );

  for (final (String name, ThemeMode mode, Color? expected)
      in <(String, ThemeMode, Color?)>[
    ('light', ThemeMode.light, EdenColors.neutral[50]),
    ('dark', ThemeMode.dark, EdenColors.neutral[900]),
  ]) {
    testWidgets(
      'EdenSecretField ($name): the field is painted on the container that '
      'exists to be its background',
      (WidgetTester tester) async {
        await _pump(
          tester,
          const Align(
            alignment: Alignment.topCenter,
            child: EdenSecretField(value: 'sk-123', label: 'API key'),
          ),
          mode,
        );
        final Color painted = await _paintedFieldSurface(tester);

        expect(
          painted,
          expected,
          reason: 'EdenSecretField wraps its field in '
              'Container(color: surfaceBg, borderRadius: md) — the same radius '
              'as the field, holding nothing else. That fill is the field\'s '
              'background and it is 100% covered: the frame shows $painted '
              'where it declares $expected. Set filled: false.',
        );
      },
    );

    testWidgets(
      'EdenEnvEditor ($name): the KEY and value cells are painted on the '
      'editor card',
      (WidgetTester tester) async {
        await _pump(
          tester,
          const Align(
            alignment: Alignment.topCenter,
            child: EdenEnvEditor(entries: <EdenEnvEntry>[
              EdenEnvEntry(key: 'API_URL', value: 'https://example.test'),
            ]),
          ),
          mode,
        );
        final RenderBox box = tester.renderObject<RenderBox>(
          find.byType(InputDecorator).first,
        );
        final Rect rect = MatrixUtils.transformRect(
          box.getTransformTo(null),
          Offset.zero & box.size,
        );
        final ({ByteData data, int width, int height}) frame =
            await _capture(tester);
        final Color painted = _dominantColour(
          frame.data,
          frame.width,
          frame.height,
          rect.deflate(4),
        );

        expect(
          painted,
          expected,
          reason: 'the KEY cell declares border: InputBorder.none — an inline '
              'cell on the editor\'s $expected card — and painted $painted '
              'over it. Set filled: false on both cells.',
        );
      },
    );
  }
}
