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
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();

  // No test may reach the network for a font. Without this, google_fonts
  // still tries the 400-ing HttpOverrides on every theme construction: 264
  // failed fetches per full suite run, and ~60s of wall clock.
  GoogleFonts.config.allowRuntimeFetching = false;

  _serveEdenTestFonts(binding.defaultBinaryMessenger);

  await testMain();
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
