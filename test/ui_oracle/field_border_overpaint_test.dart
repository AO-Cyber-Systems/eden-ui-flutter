// Fields that let their parent be the chrome, held to what they actually
// PAINT at their own edge.
//
// THE CLASS THIS PINS, and why it is the SECOND file about it.
// `EdenTheme`'s `inputDecorationTheme` declares SIX things, library-wide:
//
//     filled: true,
//     fillColor: isDark ? EdenColors.neutral[800] : Colors.white,
//     border:        OutlineInputBorder(radius lg, colorScheme.outline),
//     enabledBorder: OutlineInputBorder(radius lg, colorScheme.outline),
//     focusedBorder: OutlineInputBorder(radius lg, colorScheme.primary, 2),
//     errorBorder:   OutlineInputBorder(radius lg, colorScheme.error),
//     contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//
// `field_fill_overpaint_test.dart` pinned the FILL half: a widget that draws
// its own background and puts a `TextField` in it gets an opaque rectangle
// over that background unless it says `filled: false`. Five widgets were
// fixed that way (`c5f367e`, `d3691f1`).
//
// That fix was property-by-property, and the next property leaked
// immediately. `border: InputBorder.none` does NOT stop
// `InputDecorationTheme.enabledBorder` resolving: `InputDecoration
// .applyDefaults` fills each of THIRTY-ONE properties independently
// (`input_decorator.dart:4024`), and `_InputDecoratorState` picks the border
// for the current state — `enabledBorder` while the field is enabled and
// unfocused — so a field that nulls only `border` still paints a
// `colorScheme.outline` ring over its parent's chrome.
//
// FIXING IT ONE PROPERTY AT A TIME GUARANTEES A THIRD ROUND. `focusedBorder`,
// `disabledBorder`, `errorBorder`, `focusedErrorBorder`, `contentPadding`,
// `hintStyle`, `isDense`, `constraints`, `visualDensity` and twenty more are
// all waiting behind the same door. So the fix is `EdenBareFieldTheme`: one
// wrapper that REPLACES the ambient `InputDecorationTheme` for its subtree
// with a bare one, so a field inside it inherits nothing from `EdenTheme` at
// all — not the properties that leak today and not the ones a future edit
// adds. See `lib/src/theme/eden_bare_field_theme.dart` for why the two
// obvious alternatives (`InputDecoration.collapsed`, a shared const
// `InputDecoration`) do not close the class.
//
// WHAT EACH CASE ASSERTS, and why it needs no hand-computed colour. The ring
// is painted INSIDE the decorator's own box, one pixel in from its top edge.
// A field with no border of its own therefore has exactly one truth: the
// colour at its edge is the colour of its interior. Each case captures the
// frame the oracle captures, samples the first row at or inside the
// decorator's top edge, and compares it to the DOMINANT colour of the same
// decorator's interior in the SAME frame. Nothing is predicted; the two
// measurements simply have to agree. Where the parent declares its chrome in
// a token, that token is asserted too, so "the ring is gone" cannot be
// satisfied by the chrome also vanishing.
//
// THE SEVEN, and what the ring measured before the fix (edge pixel vs
// interior, at dpr 1):
//
//   _TopBar               #dcdcdf on the #e4e4e7 pill (light) — the ring is
//                         half-pixel aligned, so it blends rather than
//                         painting #d4d4d8 flat; #333338 on #27272a (dark).
//   EdenPhotoCapturePage  #d4d4d8 on the black scrim over the photo (light),
//                         #3f3f46 (dark). A light-grey rounded rectangle
//                         drawn across a photograph.
//   EdenEnvEditor         #e7e7e9 on the #fafafa card (light), #2c2c31 on
//                         #18181b (dark) — one ring per cell per row.
//   EdenMessageInput      #d4d4d8 immediately inside the composer's OWN
//                         #e4e4e7 border (light): a doubled ring. In dark the
//                         ring and the composer's border are both #3f3f46, so
//                         what the case measures there is the ring sitting on
//                         the #27272a fill.
//   EdenMapView           #d4d4d8 inside the white floating search card
//                         (light), #3f3f46 inside #27272a (dark).
//   EdenMarkdownEditor    #d4d4d8 immediately inside the editor frame's own
//                         #d4d4d8 border (light) — a 1px line rendered 2px
//                         thick; #3f3f46 inside #3f3f46 (dark), same.
//   EdenLineItemEditor    #d4d4d8 (light) / #3f3f46 (dark) around every
//                         editable cell of the table.
//
// TWO OF THE NINE NAMED IN `d3691f1` ARE NOT HERE, because the frame says
// they do not carry the ring:
//
//   EdenRichTextEditor    already declares `border`, `enabledBorder`,
//                         `focusedBorder` AND `disabledBorder` as
//                         `InputBorder.none`, so nothing resolves from the
//                         theme in the enabled state. Its edge measures its
//                         own frame, before and after. It still adopts
//                         `EdenBareFieldTheme` — `errorBorder` and
//                         `focusedErrorBorder` were still the theme's — but a
//                         pixel case for it could not fail and is not written.
//   EdenSecretField       declares its own `OutlineInputBorder` in
//                         `borderColor`; the ring at its edge is the border
//                         the widget asked for. Asserting edge == interior
//                         there would assert the widget's own design away.
//
// `EdenCommandPalette` is likewise not a pixel case — it had already nulled
// `border`, `enabledBorder` and `focusedBorder` by hand — but it is the tenth
// site that means "my parent owns the chrome", so it adopts the wrapper and
// is covered by `bare_field_theme_guard_test.dart` instead.
library;

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

Color _pixel(ByteData data, int imageWidth, int x, int y) {
  final int offset = (y * imageWidth + x) * 4;
  return Color(
    (data.getUint8(offset + 3) << 24) |
        (data.getUint8(offset) << 16) |
        (data.getUint8(offset + 1) << 8) |
        data.getUint8(offset + 2),
  );
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

/// What the field's own box paints at its top edge, and what it paints
/// inside, measured from ONE frame.
Future<({Color edge, Color interior, Rect rect})> _edgeAndInterior(
  WidgetTester tester,
) async {
  final RenderBox box = tester.renderObject<RenderBox>(
    find.byType(InputDecorator).first,
  );
  final Rect rect = MatrixUtils.transformRect(
    box.getTransformTo(null),
    Offset.zero & box.size,
  );
  final ({ByteData data, int width, int height}) frame = await _capture(tester);
  final int x = rect.center.dx.round().clamp(0, frame.width - 1);
  final int y = rect.top.ceil().clamp(0, frame.height - 1);
  return (
    edge: _pixel(frame.data, frame.width, x, y),
    interior: _dominantColour(
      frame.data,
      frame.width,
      frame.height,
      rect.deflate(4),
    ),
    rect: rect,
  );
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

/// One surface, in one theme, with the chrome its parent declares.
class _Case {
  const _Case({
    required this.widget,
    required this.build,
    required this.mode,
    this.chrome,
    this.chromeName,
    this.size = const Size(900, 700),
    this.after,
    required this.parent,
  });

  final String widget;
  final Widget Function(ThemeMode mode) build;
  final ThemeMode mode;

  /// The colour the PARENT declares behind the field, where the parent
  /// declares one. Asserted alongside the ring so that "no ring" cannot be
  /// satisfied by the chrome disappearing too.
  final Color? chrome;
  final String? chromeName;

  /// What the parent is, in the failure message.
  final String parent;

  final Size size;
  final Future<void> Function(WidgetTester tester)? after;

  String get name => '$widget (${mode == ThemeMode.light ? 'light' : 'dark'})';
}

Widget _topBar(ThemeMode mode) => EdenDesktopLayout(
      navItems: const <EdenNavItem>[
        EdenNavItem(id: 'i', label: 'Inventory', icon: Icons.inventory_2),
      ],
      selectedId: 'i',
      onNavChanged: (_) {},
      topBar: const EdenTopBarConfig(
        title: 'Orders',
        showSearch: true,
        searchHint: 'Search orders…',
      ),
      body: const SizedBox(),
    );

Widget _photoCapture(ThemeMode mode) => EdenPhotoCapturePage(
      cameraPreviewBuilder: (_) => const ColoredBox(color: Color(0xFF3366AA)),
      onCapture: (EdenPhotoCaptureRequest r) async => EdenCapturedPhoto(
        // An empty path renders `ColoredBox(color: Colors.black)`, so the
        // surface under the scrim is a known, fixed colour.
        filePath: '',
        capturedAt: DateTime(2026),
      ),
    );

Widget _envEditor(ThemeMode mode) => const Align(
      alignment: Alignment.topCenter,
      child: EdenEnvEditor(entries: <EdenEnvEntry>[
        EdenEnvEntry(key: 'API_URL', value: 'https://example.test'),
      ]),
    );

Widget _messageInput(ThemeMode mode) => const Align(
      alignment: Alignment.topCenter,
      child: EdenMessageInput(placeholder: 'Message…'),
    );

Widget _mapView(ThemeMode mode) =>
    const EdenMapView(mapBuilder: ColoredBox(color: Color(0xFFEEEEEE)));

Widget _markdownEditor(ThemeMode mode) =>
    const EdenMarkdownEditor(placeholder: 'Write markdown…');

Widget _lineItemEditor(ThemeMode mode) => EdenLineItemEditor<void>(
      items: const <EdenLineItem<void>>[
        EdenLineItem<void>(
          id: 'a',
          payload: null,
          description: 'Widget',
          quantity: 1,
          unitPrice: 10,
        ),
      ],
      onItemsChanged: (_) {},
    );

List<_Case> _cases() {
  final List<_Case> out = <_Case>[];
  for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
    final bool dark = mode == ThemeMode.dark;
    out.addAll(<_Case>[
      _Case(
        widget: '_TopBar',
        build: _topBar,
        mode: mode,
        size: const Size(1280, 800),
        parent: 'the search pill — Container(height: 36, '
            'colorScheme.surfaceContainerHighest, radius full)',
        chrome: (dark ? EdenTheme.dark() : EdenTheme.light())
            .colorScheme
            .surfaceContainerHighest,
        chromeName: 'colorScheme.surfaceContainerHighest',
      ),
      _Case(
        widget: 'EdenPhotoCapturePage',
        build: _photoCapture,
        mode: mode,
        parent: 'the caption scrim — Container(color: '
            'Colors.black.withValues(alpha: 0.55)) over a black photo',
        chrome: const Color(0xFF000000),
        chromeName: 'the scrim over a black photo',
        after: (WidgetTester tester) async {
          await tester
              .tap(find.byKey(const ValueKey('eden_photo_capture_shutter')));
          await tester.pumpAndSettle();
        },
      ),
      _Case(
        widget: 'EdenEnvEditor',
        build: _envEditor,
        mode: mode,
        parent: "the editor's card",
        chrome: dark ? EdenColors.neutral[900] : EdenColors.neutral[50],
        chromeName: dark ? 'neutral[900]' : 'neutral[50]',
      ),
      _Case(
        widget: 'EdenMessageInput',
        build: _messageInput,
        mode: mode,
        parent: "the composer — Container(neutral[50]/neutral[800], "
            'Border.all(neutral[200]/neutral[700]), radius lg)',
        chrome: dark ? EdenColors.neutral[800] : EdenColors.neutral[50],
        chromeName: dark ? 'neutral[800]' : 'neutral[50]',
      ),
      _Case(
        widget: 'EdenMapView',
        build: _mapView,
        mode: mode,
        parent: 'the floating search card — Container(white/neutral[800], '
            'radius lg, shadow)',
        chrome: dark ? EdenColors.neutral[800] : Colors.white,
        chromeName: dark ? 'neutral[800]' : 'Colors.white',
      ),
      _Case(
        widget: 'EdenMarkdownEditor',
        build: _markdownEditor,
        mode: mode,
        // The editor's frame declares a BORDER and no fill, so the body's
        // background is whatever the host paints. No `chrome` token to
        // assert; the ring is still the ring.
        parent: "the editor frame's border, one pixel further out",
      ),
      _Case(
        widget: 'EdenLineItemEditor',
        build: _lineItemEditor,
        mode: mode,
        size: const Size(1200, 700),
        parent: 'the table row the cell sits in',
      ),
    ]);
  }
  return out;
}

void main() {
  for (final _Case c in _cases()) {
    testWidgets(
      '${c.name}: no theme border is painted inside the field\'s own box',
      (WidgetTester tester) async {
        await _pump(tester, c.build(c.mode), c.mode, size: c.size);
        await c.after?.call(tester);

        final ({Color edge, Color interior, Rect rect}) m =
            await _edgeAndInterior(tester);

        expect(
          m.edge,
          m.interior,
          reason: 'the field declares its parent to be its chrome '
              '(${c.parent}), and declares no border of its own — so the '
              'first row inside its box must be the same colour as the rest '
              'of its box. It painted ${m.edge} at the edge and ${m.interior} '
              'inside, across ${m.rect}. That edge is '
              "EdenTheme.inputDecorationTheme's enabledBorder — an "
              'OutlineInputBorder in colorScheme.outline — which '
              '`border: InputBorder.none` does NOT turn off: applyDefaults '
              'resolves enabledBorder from the theme independently, and the '
              'enabled state prefers it over `border`. Wrap the field in '
              'EdenBareFieldTheme, which replaces the whole '
              'InputDecorationTheme for its subtree.',
        );

        final Color? chrome = c.chrome;
        if (chrome != null) {
          expect(
            m.interior,
            chrome,
            reason: "the parent's chrome must still be there once the ring "
                'is gone — ${c.chromeName} — not merely replaced by something '
                'else uniform. The field\'s box painted ${m.interior}.',
          );
        }
      },
    );
  }
}
