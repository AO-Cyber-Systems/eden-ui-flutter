// THE DIFFERENTIAL CONTROL for eden-ui-flutter#52.
//
// The defect this file exists to keep closed is one that looks IDENTICAL
// whether or not it is closed, which is why asserting the fix is not enough
// and a control is required.
//
// Before #52, `MaterialIcons` was never registered with the text shaper in
// `flutter test` (the font file is in the test asset bundle; nothing reads
// `FontManifest.json` to register it — see test/flutter_test_config.dart).
// Every `IconData` therefore rasterised as tofu, the empty-square fallback.
// That square was blessed into all 22 golden baselines, and the consequence
// is the part worth restating: AN ICON COULD NOT REGRESS. `Icons.close` and
// `Icons.check` paint the same empty box, so swapping one for the other,
// theming one wrongly, or deleting one entirely moved no baseline and the
// golden suite reported green.
//
// `expectUiSane` cannot cover the gap either: it reads ink from the RESOLVED
// `TextStyle` and never looks at a rasterised glyph — `painted-ink-not-
// measured`, already recorded in ORACLE_COVERAGE.md. Both visual layers were
// blind to the same class for the same reason at the same time.
//
// So this file does not check that a FontLoader was called. It checks the
// only thing that matters downstream: that changing an icon changes pixels.
//
//   case 1  two different icons rasterise to different pixels  (the control)
//   case 2  the same icon rasterises identically twice         (non-vacuity)
//   case 3  a real icon differs from an UNDEFINED code point   (not tofu)
//   case 4  wrap() paints no debug banner
//   case 5  the banner was really painting                     (non-vacuity)
//
// Case 2 is what makes case 1 mean something: without it, "the two captures
// differ" could be capture noise. Case 3 is what makes case 1 mean it for
// the RIGHT reason: two glyphs could in principle differ while both were
// junk, and 0x1 is a code point MaterialIcons does not define, so it IS the
// fallback square — a real icon equalling it is the #52 state exactly.
//
// RUNS EVERYWHERE. Unlike the golden comparison (Linux/CI only,
// eden-ui-flutter#32) this reads the frame it just rendered, so a macOS
// `flutter test` proves the font registration on the spot rather than
// deferring the whole question to a CI dispatch.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/ui_oracle/wrap.dart';

/// A code point `MaterialIcons` does not define, rendered through the same
/// family every `Icons.*` constant uses. It rasterises as the fallback
/// square — which is what EVERY icon in this repo rasterised as before #52.
const IconData kUndefinedGlyph = IconData(0x1, fontFamily: 'MaterialIcons');

/// The viewport these captures use. Small on purpose: the assertion is about
/// one glyph, and a 1280x800 frame is 4MB of bytes to compare per capture.
const double _kProbeWidth = 200;
const double _kProbeHeight = 200;

/// A large glyph. Antialiasing at 24px would still differ between two icons,
/// but at 96px the difference is a difference a HUMAN would also call
/// obvious, so a failure reads as "the icon changed" and not "the renderer
/// moved a sub-pixel".
const double _kProbeIconSize = 96;

/// The raw RGBA bytes of the frame currently rendered.
///
/// Mirrors `frame_probe.dart`'s capture (the oracle's own independent
/// reader): `toImage` off the `RenderView`'s layer, inside `runAsync`,
/// because a widget test's fake clock never lets the real-async encode
/// complete otherwise.
Future<Uint8List> _frameBytes(WidgetTester tester) async {
  final RenderView renderView = tester.binding.renderViews.first;
  final OffsetLayer layer = renderView.debugLayer! as OffsetLayer;
  ByteData? bytes;
  await tester.runAsync<void>(() async {
    final ui.Image image = await layer.toImage(
      renderView.paintBounds,
      pixelRatio: 1 / renderView.flutterView.devicePixelRatio,
    );
    bytes = await image.toByteData();
    image.dispose();
  });
  final ByteData? data = bytes;
  expect(
    data,
    isNotNull,
    reason: 'the frame could not be captured, so nothing below proves '
        'anything. A capture that fails must fail this test and never read '
        'as "no difference found".',
  );
  return data!.buffer.asUint8List();
}

/// Pumps a single [icon] through the real [wrap] helper and returns the
/// frame.
///
/// THROUGH `wrap()` DELIBERATELY. The registration under test happens in
/// `test/flutter_test_config.dart`, and `wrap()` is the helper every story
/// golden goes through, so this captures the same pipeline the baselines are
/// blessed from rather than a parallel one that could be fixed while theirs
/// stayed broken.
Future<Uint8List> _iconFrame(WidgetTester tester, IconData icon) async {
  await wrap(
    tester,
    Icon(icon, size: _kProbeIconSize),
    width: _kProbeWidth,
    height: _kProbeHeight,
  );
  return _frameBytes(tester);
}

/// How many bytes differ between two equal-length captures.
int _differingBytes(Uint8List a, Uint8List b) {
  expect(
    a.length,
    b.length,
    reason: 'two captures of the same viewport must be the same size; a '
        'length difference means the comparison below is meaningless',
  );
  int n = 0;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      n++;
    }
  }
  return n;
}

void main() {
  testWidgets(
    'case 1: two different icons rasterise to DIFFERENT pixels',
    (WidgetTester tester) async {
      final Uint8List close = await _iconFrame(tester, Icons.close);
      final Uint8List check = await _iconFrame(tester, Icons.check);

      expect(
        _differingBytes(close, check),
        greaterThan(0),
        reason: 'Icons.close and Icons.check rasterised to IDENTICAL pixels. '
            'That is the eden-ui-flutter#52 state: MaterialIcons is not '
            'registered with the text shaper, both glyphs are the empty-'
            'square fallback, and every golden baseline in this repo is '
            'pinning squares — so no icon change can ever turn one red. Fix '
            'the registration in test/flutter_test_config.dart; do not '
            'weaken this assertion.',
      );
    },
  );

  testWidgets(
    'case 2 (non-vacuity): the same icon rasterises IDENTICALLY twice',
    (WidgetTester tester) async {
      final Uint8List first = await _iconFrame(tester, Icons.close);
      final Uint8List second = await _iconFrame(tester, Icons.close);

      expect(
        _differingBytes(first, second),
        0,
        reason: 'two captures of the SAME icon differ, so case 1 above '
            'cannot distinguish "the icon changed" from capture noise and '
            'proves nothing. Something is nondeterministic in the pump or '
            'the capture — find it rather than loosening case 1.',
      );
    },
  );

  testWidgets(
    'case 3: a real icon is NOT the undefined-code-point fallback square',
    (WidgetTester tester) async {
      final Uint8List home = await _iconFrame(tester, Icons.home);
      final Uint8List tofu = await _iconFrame(tester, kUndefinedGlyph);

      expect(
        _differingBytes(home, tofu),
        greaterThan(0),
        reason: 'Icons.home rasterised to the same pixels as code point 0x1, '
            'which MaterialIcons does not define. The real glyph IS the '
            'fallback square, which is eden-ui-flutter#52 exactly: the font '
            'is not registered, every icon is a box, and the golden '
            'baselines pin boxes.',
      );
    },
  );

  testWidgets(
    'case 4: wrap() paints no debug banner over the surface',
    (WidgetTester tester) async {
      await wrap(
        tester,
        const Icon(Icons.close, size: _kProbeIconSize),
        width: _kProbeWidth,
        height: _kProbeHeight,
      );

      expect(
        find.byType(CheckedModeBanner),
        findsNothing,
        reason: 'the MaterialApp debug ribbon is back. It is PAINTED OVER '
            'the top-right corner of the surface, so a control that sits '
            'there is hidden behind it and the occlusion gets blessed as the '
            'correct baseline — in list-appointments/populated it covered '
            "the first row's cancel control (eden-ui-flutter#52). Set "
            'debugShowCheckedModeBanner: false in wrap().',
      );
    },
  );

  testWidgets(
    'case 5 (non-vacuity): the banner really does paint pixels',
    (WidgetTester tester) async {
      // Without this, case 4 could be asserting the absence of something
      // that never painted anything — a green check that proves nothing.
      //
      // BOTH SIDES ARE BUILT HERE, identical in every respect except the one
      // flag. Comparing against `wrap()`'s output instead would differ by the
      // theme as well, and then the inequality would not be evidence about
      // the banner.
      final Uint8List withoutBanner =
          await _bannerProbeFrame(tester, showBanner: false);
      final Uint8List withBanner =
          await _bannerProbeFrame(tester, showBanner: true);

      expect(
        _differingBytes(withoutBanner, withBanner),
        greaterThan(0),
        reason: 'turning the debug banner ON changed no pixels, so case 4 is '
            'guarding against nothing and the re-blessing of every baseline '
            'in this PR had some other cause. Investigate before trusting '
            'either.',
      );
    },
  );
}

/// Pumps the banner probe: one tree, one flag, nothing else different.
Future<Uint8List> _bannerProbeFrame(
  WidgetTester tester, {
  required bool showBanner,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(_kProbeWidth, _kProbeHeight);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: showBanner,
      home: const Scaffold(
        body: Center(
          child: SizedBox(
            width: _kProbeWidth,
            child: Icon(Icons.close, size: _kProbeIconSize),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _frameBytes(tester);
}
