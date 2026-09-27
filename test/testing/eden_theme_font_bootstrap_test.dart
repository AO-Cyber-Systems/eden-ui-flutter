// The precondition the UI Oracle's accessibility phase depends on.
//
// `expectUiSane` runs `textContrastGuideline`, which captures the rendered
// image through `tester.runAsync`. That is the first thing in a widget test
// that lets an ALREADY-PENDING real-async future run — and `EdenTheme`
// leaves one pending on every construction, because its type scale is built
// from `GoogleFonts.outfit(...)` / `GoogleFonts.plusJakartaSans(...)`, each of
// which fires an unawaited font load at call time.
//
// In `flutter test` that load can never succeed on its own:
//
//   * `flutter_test` installs an `HttpOverrides` that answers EVERY request
//     with 400 (see flutter_test/src/_binding_io.dart), so the gstatic fetch
//     fails whether or not the machine has a network; and
//   * `google_fonts` RE-THROWS that failure out of `loadFontIfNecessary`,
//     from a future nobody awaits, so the error arrives as an UNCAUGHT ASYNC
//     ERROR. `flutter_test`'s per-test zone turns that straight into a test
//     failure — `FlutterError.onError` is reinstalled by the binding inside
//     `runTest`, and the zone's uncaught-error handler ends the test on the
//     spot, so NO helper (`expectUiSane` included) can intercept it.
//
// The consequence is the reason this file exists: the accessibility gate was
// unobservable on every themed surface. Not failing — unable to reach a
// verdict at all.
//
// The fix is `test/flutter_test_config.dart`, which serves Eden's three type
// families to `google_fonts` from `test_support/fonts/` as ordinary assets.
// These two cases pin BOTH halves of it: the fetch is off, and real font
// bytes are actually in play.
library;

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  test(
    'case 1: the suite bootstrap turns google_fonts runtime fetching OFF',
    () {
      expect(
        GoogleFonts.config.allowRuntimeFetching,
        isFalse,
        reason: 'test/flutter_test_config.dart must disable runtime fetching '
            'for the whole suite. With it on, every EdenTheme construction '
            'queues an HTTP fetch that flutter_test answers with 400 and '
            'google_fonts rethrows into an uncaught async error.',
      );
    },
  );

  testWidgets(
    "case 2: EdenTheme's type scale resolves to REAL font bytes, not a "
    'silent fallback',
    (WidgetTester tester) async {
      final ThemeData theme = EdenTheme.light();
      final String? family = theme.textTheme.bodyMedium?.fontFamily;
      expect(
        family,
        isNotNull,
        reason: "EdenTheme's bodyMedium is built by google_fonts and always "
            'carries a family name',
      );

      await tester.pumpWidget(MaterialApp(theme: theme, home: const SizedBox()));
      await tester.pumpAndSettle();

      // The load EdenTheme() queued is REAL async, so it does not advance
      // under the fake clock a plain `pump` drives -- it needs a `runAsync`
      // window. That is not a workaround: it is precisely the window
      // `textContrastGuideline` opens to capture the rendered image, which is
      // why the oracle was the only caller that ever reached this code path.
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // DIFFERENTIAL CONTROL, built in. A family that is not registered with
      // the engine falls back to the default test font. If Eden's family were
      // ALSO unregistered, both measurements would come from that same
      // fallback and be identical — which is exactly what a green-but-vacuous
      // version of this check would look like. They must differ.
      final double eden = _widthOf('Handgloves 123', family);
      final double absent = _widthOf('Handgloves 123', 'EdenNoSuchFamily');
      expect(
        eden,
        isNot(closeTo(absent, 0.01)),
        reason: 'text laid out in "$family" measured $eden, identical to an '
            'unregistered family at $absent — the font never loaded, so the '
            "oracle's contrast verdict would be measured against the wrong "
            'rasterisation.',
      );
    },
  );
}

double _widthOf(String text, String? fontFamily) {
  final TextPainter painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: fontFamily, fontSize: 32),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final double width = painter.width;
  painter.dispose();
  return width;
}
