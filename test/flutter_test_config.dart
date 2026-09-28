// Suite-wide bootstrap for `flutter test`. Dart's test runner calls
// [testExecutable] once per test FILE under this directory tree, before that
// file's `main()`, so everything set up here holds for every test in `test/`.
//
// WHY THIS FILE EXISTS — the UI Oracle's accessibility phase could not run.
//
// `EdenTheme` builds its type scale from `GoogleFonts.outfit(...)` and
// `GoogleFonts.plusJakartaSans(...)`. Each call fires an UNAWAITED font load.
// In `flutter test` that load cannot succeed on its own: `flutter_test`
// installs an `HttpOverrides` that answers every request with 400
// (flutter_test/src/_binding_io.dart), and `google_fonts` RE-THROWS the
// failure out of `loadFontIfNecessary`. Nobody awaits that future, so the
// error lands as an uncaught async error, and `flutter_test`'s per-test zone
// ends the test on the spot -- `FlutterError.onError` is reinstalled by the
// binding inside `runTest`, so no helper can intercept it. `expectUiSane`'s
// `textContrastGuideline` is the first thing in a widget test that lets a
// pending REAL-async future run (it captures the image through `runAsync`),
// which is why the oracle, and only the oracle, died on it.
//
// Turning runtime fetching OFF is NOT sufficient on its own, and the
// difference is worth stating because it is the obvious thing to try:
// `loadFontIfNecessary` then throws "allowRuntimeFetching is false but font X
// was not found in the application assets" and rethrows it down the same
// unawaited future. The error text changes; the uncaught async error does
// not. `EdenProfileFonts._resolveFamily`'s broad `catch` cannot help either --
// it guards `GoogleFonts.getFont`, which is not on `EdenTheme`'s path, and
// the failure is asynchronous, so a synchronous `catch` could never see it.
//
// The only fix is to make the load SUCCEED offline, so this bootstrap serves
// Eden's type families to `google_fonts` as ordinary assets, read from
// `test_support/fonts/`.
//
// DELIBERATELY NOT IN `pubspec.yaml`'s `flutter: assets:`. An entry there
// ships in every consumer app's bundle and changes production font delivery,
// which is a product decision (022's runtime-font capability depends on
// fetching staying on outside tests). These bytes are test-only: they reach
// `google_fonts` through a mock handler on the `flutter/assets` channel that
// delegates everything it does not own straight back to the real bundle.
//
// Mock handlers registered here survive for the life of the test binding --
// one per test FILE -- because nothing in `flutter_test` clears
// `TestDefaultBinaryMessenger`'s outbound handlers between tests, despite
// what `setMockMessageHandler`'s doc comment says.
//
// The fonts themselves are attributed in `test_support/fonts/NOTICE.txt`. If
// a `google_fonts` upgrade changes which variants `EdenTheme` resolves to,
// the new variant will not be in `test_support/fonts/` and the oracle tests
// fail LOUDLY with google_fonts' own "was not found in the application
// assets" message naming the missing file.
//
// SECOND JOB — ICON GLYPHS (eden-ui-flutter#52).
//
// Everything above is about TEXT. Icons were broken for a DIFFERENT reason
// and the two fixes must not be confused: `MaterialIcons` is not a
// google_fonts family and is never fetched. It ships with the framework, and
// `uses-material-design: true` in pubspec.yaml publishes it into the asset
// bundle -- including the one `flutter test` builds at
// `build/unit_test_assets/`, where `fonts/MaterialIcons-Regular.otf` (1.6MB)
// and a `FontManifest.json` naming it are both present on every run.
//
// What is missing is the REGISTRATION. In a real app the engine reads
// `FontManifest.json` at startup and registers each family with the text
// shaper. `flutter_tester` does not: nothing in `flutter_test` reads that
// manifest, so `MaterialIcons` is an unknown family, every `IconData`
// resolves to the fallback face, and each glyph rasterises as tofu -- the
// empty square. That square was pinned as correct in all 22 committed golden
// baselines, which means NO ICON COULD REGRESS: `Icons.close` and
// `Icons.check` are the same empty box, so swapping, mistheming or deleting
// an icon moved no baseline. `expectUiSane` cannot cover the gap either --
// it reads ink from the resolved `TextStyle` and never looks at a rasterised
// glyph (`painted-ink-not-measured` in ORACLE_COVERAGE.md).
//
// [_loadBundledFonts] does the registration `flutter_tester` skips, driven
// off the manifest rather than a hardcoded path so a font added to
// pubspec.yaml tomorrow is registered without editing this file. It is
// asserted non-vacuous: if `MaterialIcons` is not among the families it
// registered, bootstrap throws rather than letting the suite go green on
// squares again. The differential control that proves the registration
// actually reaches the rasteriser is
// `test/ui_oracle/icon_glyph_rasterises_test.dart`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Virtual asset directory the test fonts are published under.
///
/// Nothing real lives at this path; it exists only so `google_fonts`'
/// `_findFamilyWithVariantAssetPath` -- which matches an asset whose filename
/// (sans extension) ENDS WITH `Family-Variant` -- can find them.
const String kEdenTestFontAssetDir = 'eden_test_fonts';

/// Where the `.ttf` files actually live, relative to the package root.
/// `flutter test` runs with the package root as the working directory.
const String kEdenTestFontSourceDir = 'test_support/fonts';

/// Asset key the bundle manifest is published under.
const String _kAssetManifestKey = 'AssetManifest.bin';

/// Asset key the FONT manifest is published under. Generated from
/// `pubspec.yaml` by the tool and staged into `build/unit_test_assets/` for
/// every `flutter test` run.
const String _kFontManifestKey = 'FontManifest.json';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();

  // No test may reach the network for a font. Without this, google_fonts
  // still tries the 400-ing HttpOverrides on every theme construction: 264
  // failed fetches per full suite run, and ~60s of wall clock.
  GoogleFonts.config.allowRuntimeFetching = false;

  _serveEdenTestFonts(binding.defaultBinaryMessenger);
  await _loadBundledFonts();
  await _warmEdenTypeFamilies();

  await testMain();
}

/// Font families that MUST end up registered, or bootstrap fails.
///
/// A gate whose unmeasurable state is indistinguishable from its passing
/// state is not a gate. If `uses-material-design:` is dropped, or a future
/// `flutter test` stops staging the framework fonts into
/// `build/unit_test_assets/`, [_loadBundledFonts] would quietly register
/// nothing and every icon would silently go back to being an empty square
/// pinned as correct -- exactly the state #52 was filed about. So the absence
/// is named here and throws.
const List<String> kRequiredBundledFontFamilies = <String>['MaterialIcons'];

/// Registers every family declared in the bundle's own `FontManifest.json`.
///
/// This is the step `flutter_tester` does not do. See the header: the font
/// FILE is in the test asset bundle already; only the registration with the
/// text shaper is absent, and [FontLoader] is the test-side equivalent of the
/// engine's startup registration.
///
/// DRIVEN OFF THE MANIFEST, not off a hardcoded `fonts/MaterialIcons-*.otf`
/// path. The manifest is generated from `pubspec.yaml`, so a family added
/// there is registered here with no edit -- and an asset path that moves
/// between Flutter versions moves in the manifest too.
///
/// `testExecutable` is REAL async (it runs before the test binding installs a
/// fake clock), so [FontLoader.load] actually completes here. The same call
/// inside a `testWidgets` body would not.
Future<void> _loadBundledFonts() async {
  final String manifestJson;
  try {
    manifestJson = await rootBundle.loadString(_kFontManifestKey);
  } on Object catch (error) {
    throw StateError(
      'Could not read "$_kFontManifestKey" from the test asset bundle: '
      '$error. Without it no font family is registered with the text shaper, '
      'so every IconData rasterises as tofu and no icon in the catalogue can '
      'regress. See the header of test/flutter_test_config.dart '
      '(eden-ui-flutter#52).',
    );
  }

  final List<String> registered = <String>[];
  for (final Object? entry in json.decode(manifestJson) as List<Object?>) {
    if (entry is! Map<Object?, Object?>) {
      continue;
    }
    final Object? family = entry['family'];
    final Object? fonts = entry['fonts'];
    if (family is! String || fonts is! List<Object?> || fonts.isEmpty) {
      continue;
    }
    final FontLoader loader = FontLoader(family);
    int assets = 0;
    for (final Object? font in fonts) {
      if (font is! Map<Object?, Object?>) {
        continue;
      }
      final Object? asset = font['asset'];
      if (asset is! String) {
        continue;
      }
      loader.addFont(rootBundle.load(asset));
      assets++;
    }
    if (assets == 0) {
      continue;
    }
    await loader.load();
    registered.add(family);
  }

  final List<String> missing = <String>[
    for (final String family in kRequiredBundledFontFamilies)
      if (!registered.contains(family)) family,
  ];
  if (missing.isNotEmpty) {
    throw StateError(
      'These font families were NOT registered from "$_kFontManifestKey": '
      '${missing.join(', ')}. The manifest named ${registered.isEmpty ? 'no '
          'families at all' : 'only: ${registered.join(', ')}'}. '
      'MaterialIcons reaches the test bundle through '
      "pubspec.yaml's `uses-material-design: true`; without it every "
      'IconData rasterises as the empty-square fallback and the golden '
      'baselines pin squares, so no icon change can ever go red '
      '(eden-ui-flutter#52). Fix the bundle rather than relaxing this check.',
    );
  }
}

/// Completes every font load `EdenTheme` fires, BEFORE the first test renders.
///
/// WHY. `EdenTheme` builds its type scale from `GoogleFonts.outfit(...)` and
/// `GoogleFonts.plusJakartaSans(...)`, and each of those fires an UNAWAITED
/// load. A widget test's fake clock never lets that future run, so the first
/// test in a file lays out and paints in the FALLBACK face; the first thing
/// in a widget test that DOES let a real-async future complete is
/// `tester.runAsync` -- which is what `expectUiSane`'s contrast phase uses to
/// capture the frame. The load therefore landed during test #1 and every
/// later test in the same file used the real face.
///
/// Measured on the desktop shell before this ran: the top bar's search pill
/// was 863.1 logical pixels wide in the first test of a file and 904.7 in the
/// second -- 41.6px of layout movement from nothing but position in the file.
/// The oracle's GEOMETRY rules (tap target, overlap, containment, viewport)
/// all read that layout, and a golden baseline blessed without this would
/// bake in whichever face happened to have loaded. Pinned by
/// `test/ui_oracle/font_warmup_order_test.dart`.
///
/// `testExecutable` is REAL async -- it runs before the test binding installs
/// a fake clock -- so the awaits here actually complete.
///
/// CONSTRUCTING THE THEMES is the whole mechanism: `GoogleFonts.outfit()` and
/// friends resolve a DIFFERENT engine font family per weight
/// (`Outfit_w800`, `Outfit_w700`, ...), so only the exact set of calls
/// `EdenTheme` makes warms the exact set of families it then renders with.
/// Both brightnesses are built because each constructs its own type scale.
///
/// If a `google_fonts` upgrade resolves a variant that is not in
/// `test_support/fonts/`, this throws HERE, at bootstrap, naming the missing
/// file -- rather than silently leaving one weight cold.
Future<void> _warmEdenTypeFamilies() async {
  EdenTheme.light();
  EdenTheme.dark();
  await GoogleFonts.pendingFonts();
}

/// Publishes every `.ttf` in [kEdenTestFontSourceDir] into the asset bundle
/// that `google_fonts` sees, WITHOUT putting it in the real bundle.
void _serveEdenTestFonts(TestDefaultBinaryMessenger messenger) {
  final Directory source = Directory(kEdenTestFontSourceDir);
  if (!source.existsSync()) {
    throw StateError(
      'The UI Oracle test fonts are missing: expected .ttf files in '
      '"${source.absolute.path}". Without them google_fonts cannot resolve '
      "EdenTheme's type scale offline and every expectUiSane on a themed "
      'surface dies on an uncaught async font error instead of reaching a '
      'verdict. See the header of test/flutter_test_config.dart.',
    );
  }

  final Map<String, Uint8List> fonts = <String, Uint8List>{
    for (final File file in source
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.endsWith('.ttf')))
      '$kEdenTestFontAssetDir/${file.uri.pathSegments.last}':
          file.readAsBytesSync(),
  };
  if (fonts.isEmpty) {
    throw StateError(
      'No .ttf files found in "${source.absolute.path}" -- see the header of '
      'test/flutter_test_config.dart.',
    );
  }

  // Everything this handler does not own goes to the real bundle unchanged.
  final BinaryMessenger platform = messenger.delegate;

  messenger.setMockMessageHandler('flutter/assets', (ByteData? message) async {
    if (message == null) {
      return platform.send('flutter/assets', message);
    }
    final String key = utf8.decode(
      message.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes),
    );

    final Uint8List? font = fonts[key];
    if (font != null) {
      return ByteData.sublistView(font);
    }

    final ByteData? real = await platform.send('flutter/assets', message);
    if (key == _kAssetManifestKey) {
      return _manifestWith(real, fonts.keys);
    }
    return real;
  });
}

/// Returns [real] -- the bundle's own `AssetManifest.bin` -- with one entry
/// added per test font, so `AssetManifest.listAssets()` reports them.
///
/// The manifest is a `StandardMessageCodec` map of asset key to a list of
/// variant descriptors, each `{'asset': <key>, 'dpr': <double?>}`. A font has
/// no resolution variants, so it is its own single descriptor.
ByteData _manifestWith(ByteData? real, Iterable<String> fontKeys) {
  const StandardMessageCodec codec = StandardMessageCodec();
  final Map<Object?, Object?> data = real == null
      ? <Object?, Object?>{}
      : codec.decodeMessage(real)! as Map<Object?, Object?>;
  for (final String key in fontKeys) {
    data[key] = <Object?>[
      <Object?, Object?>{'asset': key},
    ];
  }
  return codec.encodeMessage(data)!;
}
