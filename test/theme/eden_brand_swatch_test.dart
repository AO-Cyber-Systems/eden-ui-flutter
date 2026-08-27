// test/theme/eden_brand_swatch_test.dart
//
// EdenBrandSwatch parser + HSL-ramp contract tests (objective 022 TRD 02).
// Test list per TRD 022-02-TRD.md ## Test list section.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/brand_swatch_fixtures.dart';

void main() {
  group('EdenTheme integration — the reason shade 950 matters', () {
    testWidgets('EdenTheme.dark(brand:) constructs without throwing', (tester) async {
      // Test list item 1.
      final swatch = EdenBrandSwatch.tryParse('#0F62FE')!;
      expect(() => EdenTheme.dark(brand: swatch), returnsNormally);
    });

    testWidgets('EdenTheme.light(brand:) constructs without throwing', (tester) async {
      // Test list item 2.
      final swatch = EdenBrandSwatch.tryParse('#0F62FE')!;
      expect(() => EdenTheme.light(brand: swatch), returnsNormally);
    });

    testWidgets('EdenTheme.light(brand:).colorScheme.primary matches the supplied hex', (tester) async {
      // Test list item 3.
      final swatch = EdenBrandSwatch.tryParse('#0F62FE')!;
      final theme = EdenTheme.light(brand: swatch);
      expect(theme.colorScheme.primary.value, BrandSwatchFixtures.validFormsExpectedArgb);
    });
  });

  group('Generated swatch shape', () {
    test('exposes all eleven mandatory shade keys, none null', () {
      // Test list item 4.
      for (final hex in BrandSwatchFixtures.realPartnerHexes) {
        final swatch = EdenBrandSwatch.tryParse(hex)!;
        for (final shade in BrandSwatchFixtures.mandatoryShades) {
          expect(
            swatch[shade],
            isNotNull,
            reason: 'Shade $shade missing for $hex — a 10-shade swatch is a dark-mode boot crash.',
          );
        }
      }
    });

    test('shade 500 ARGB equals the input ARGB exactly', () {
      // Test list item 5.
      for (final hex in BrandSwatchFixtures.realPartnerHexes) {
        final seed = EdenBrandSwatch.tryParse(hex)!;
        final parsed = Color(seed.value);
        expect(
          seed[500]!.value,
          parsed.value,
          reason: 'Shade 500 must be the original parsed Color, not an HSL round trip, for $hex.',
        );
      }
    });

    test('swatch.value equals shade 500\'s ARGB', () {
      // Test list item 6.
      for (final hex in BrandSwatchFixtures.realPartnerHexes) {
        final swatch = EdenBrandSwatch.tryParse(hex)!;
        expect(swatch.value, swatch[500]!.value);
      }
    });
  });

  group('Lightness monotonicity', () {
    test('HSL lightness is monotonically non-increasing from shade 50 to 950', () {
      // Test list item 7.
      final hexes = [
        ...BrandSwatchFixtures.realPartnerHexes,
        ...BrandSwatchFixtures.degenerate,
      ];
      for (final hex in hexes) {
        final swatch = EdenBrandSwatch.tryParse(hex)!;
        double? previousLightness;
        for (final shade in BrandSwatchFixtures.mandatoryShades) {
          final lightness = HSLColor.fromColor(swatch[shade]!).lightness;
          if (previousLightness != null) {
            expect(
              lightness,
              lessThanOrEqualTo(previousLightness),
              reason: 'Lightness ramp inverted at shade $shade for $hex.',
            );
          }
          previousLightness = lightness;
        }
      }
    });
  });

  group('Hue and saturation preservation', () {
    test('hue and saturation are preserved within measured tolerance', () {
      // Test list item 8. Tolerance is FITTED to these hexes only — see
      // BrandSwatchFixtures doc comment (item 8a). Never assert plain
      // equality here — it goes RED on a correct implementation.
      final hexes = [
        ...BrandSwatchFixtures.realPartnerHexes,
        ...BrandSwatchFixtures.degenerate,
      ];
      for (final hex in hexes) {
        final swatch = EdenBrandSwatch.tryParse(hex)!;
        final seedHsl = HSLColor.fromColor(Color(swatch.value));
        for (final shade in BrandSwatchFixtures.mandatoryShades) {
          final shadeHsl = HSLColor.fromColor(swatch[shade]!);
          expect(
            shadeHsl.saturation,
            closeTo(seedHsl.saturation, 0.02),
            reason: 'Saturation drifted beyond tolerance at shade $shade for $hex.',
          );
          if (seedHsl.saturation == 0) {
            // Hue is meaningless for a zero-saturation (grey) colour —
            // skip the hue check per Test list item 8.
            continue;
          }
          expect(
            shadeHsl.hue,
            closeTo(seedHsl.hue, 1.0),
            reason: 'Hue drifted beyond tolerance at shade $shade for $hex.',
          );
        }
      }
    });

    test('#808080 (grey) hue and saturation are bit-exact on every shade', () {
      // Test list item 8b.
      final swatch = EdenBrandSwatch.tryParse('#808080')!;
      final seedHsl = HSLColor.fromColor(Color(swatch.value));
      for (final shade in BrandSwatchFixtures.mandatoryShades) {
        final shadeHsl = HSLColor.fromColor(swatch[shade]!);
        expect(shadeHsl.hue, seedHsl.hue);
        expect(shadeHsl.saturation, seedHsl.saturation);
      }
    });

    test('#FF0000 and #00FF00 hue are bit-exact; saturation within 1e-12', () {
      // Test list item 8b. Saturation is measurably 1-2 ULP low on shades
      // 400/900/950 due to 8-bit channel quantization — assert with
      // closeTo(..., 1e-12), never plain equality. Measure with
      // toStringAsPrecision(17), never toStringAsFixed(4).
      for (final hex in ['#FF0000', '#00FF00']) {
        final swatch = EdenBrandSwatch.tryParse(hex)!;
        final seedHsl = HSLColor.fromColor(Color(swatch.value));
        for (final shade in BrandSwatchFixtures.mandatoryShades) {
          final shadeHsl = HSLColor.fromColor(swatch[shade]!);
          expect(
            shadeHsl.hue,
            seedHsl.hue,
            reason: 'Hue must be bit-exact for fully-saturated primary $hex at shade $shade.',
          );
          expect(
            shadeHsl.saturation,
            closeTo(seedHsl.saturation, 1e-12),
            reason: 'Saturation for $hex at shade $shade: '
                '${shadeHsl.saturation.toStringAsPrecision(17)} vs '
                '${seedHsl.saturation.toStringAsPrecision(17)}',
          );
        }
      }
    });
  });

  group('Carbon Blue golden ramp', () {
    test('tryParse(#0F62FE) reproduces the verified golden ramp exactly', () {
      // Test list item 9.
      final swatch = EdenBrandSwatch.tryParse('#0F62FE')!;
      BrandSwatchFixtures.carbonBlueExpectedRamp.forEach((shade, expectedArgb) {
        expect(
          swatch[shade]!.value,
          expectedArgb,
          reason: 'Shade $shade of the Carbon Blue ramp: '
              'expected #${expectedArgb.toRadixString(16)}, '
              'got #${swatch[shade]!.value.toRadixString(16)}.',
        );
      });
    });
  });

  group('Degenerate inputs are usable, never null', () {
    test('#FFFFFF is monotonic, shade 500 is white, dark end is usable', () {
      // Test list item 10.
      final swatch = EdenBrandSwatch.tryParse('#FFFFFF')!;
      expect(swatch[500]!.value, 0xFFFFFFFF);
      final darkLightness = HSLColor.fromColor(swatch[950]!).lightness;
      expect(darkLightness, lessThan(1.0));
    });

    test('#000000 shade 500 is black and construction never throws', () {
      // Test list item 11.
      expect(() => EdenBrandSwatch.tryParse('#000000'), returnsNormally);
      final swatch = EdenBrandSwatch.tryParse('#000000')!;
      expect(swatch[500]!.value, 0xFF000000);
    });

    test('#FAFAFA shade 50 is not darker than shade 500 (no inversion)', () {
      // Test list item 12.
      final swatch = EdenBrandSwatch.tryParse('#FAFAFA')!;
      final l50 = HSLColor.fromColor(swatch[50]!).lightness;
      final l500 = HSLColor.fromColor(swatch[500]!).lightness;
      expect(l50, greaterThanOrEqualTo(l500));
    });

    test('#101010 shade 950 is not lighter than shade 500 (no inversion)', () {
      // Test list item 13.
      final swatch = EdenBrandSwatch.tryParse('#101010')!;
      final l950 = HSLColor.fromColor(swatch[950]!).lightness;
      final l500 = HSLColor.fromColor(swatch[500]!).lightness;
      expect(l950, lessThanOrEqualTo(l500));
    });
  });

  group('Accepted hex forms', () {
    test('all accepted textual forms yield an identical shade map', () {
      // Test list item 14.
      MaterialColor? reference;
      for (final form in BrandSwatchFixtures.validForms) {
        final swatch = EdenBrandSwatch.tryParse(form)!;
        expect(swatch.value, BrandSwatchFixtures.validFormsExpectedArgb, reason: 'Form "$form" parsed wrong.');
        if (reference != null) {
          for (final shade in BrandSwatchFixtures.mandatoryShades) {
            expect(
              swatch[shade]!.value,
              reference[shade]!.value,
              reason: 'Form "$form" disagrees with the reference form at shade $shade.',
            );
          }
        }
        reference = swatch;
      }
    });

    test('3-digit shorthand expands correctly', () {
      // Test list item 15.
      final swatch = EdenBrandSwatch.tryParse(BrandSwatchFixtures.shorthandInput)!;
      expect(swatch.value, BrandSwatchFixtures.shorthandExpectedArgb);
    });
  });

  group('tryParse never throws; malformed input returns null', () {
    test('tryParse(null) returns null', () {
      // Test list item 16.
      expect(EdenBrandSwatch.tryParse(null), isNull);
    });

    test('empty / blank / bare-hash inputs return null', () {
      // Test list item 17.
      expect(EdenBrandSwatch.tryParse(''), isNull);
      expect(EdenBrandSwatch.tryParse('   '), isNull);
      expect(EdenBrandSwatch.tryParse('#'), isNull);
    });

    test('non-hex words return null', () {
      // Test list item 18.
      expect(EdenBrandSwatch.tryParse('nope'), isNull);
      expect(EdenBrandSwatch.tryParse('blue'), isNull);
      expect(EdenBrandSwatch.tryParse('rgb(1,2,3)'), isNull);
    });

    test('invalid hex digits return null', () {
      // Test list item 19.
      expect(EdenBrandSwatch.tryParse('#GGGGGG'), isNull);
    });

    test('invalid lengths return null', () {
      // Test list item 20.
      expect(EdenBrandSwatch.tryParse('#12345'), isNull);
      expect(EdenBrandSwatch.tryParse('#1234567'), isNull);
    });

    test('signed hex-like forms return null', () {
      // Test list item 20b — the int.tryParse(radix: 16) signed-forms hole.
      expect(EdenBrandSwatch.tryParse('#-0F62FEE'), isNull);
      expect(EdenBrandSwatch.tryParse('#+0F62FEE'), isNull);
      expect(EdenBrandSwatch.tryParse('#-0F62F'), isNull);
      expect(EdenBrandSwatch.tryParse('#-F0'), isNull);
    });

    test('no malformed-fixture input ever throws', () {
      // Test list item 21.
      for (final input in BrandSwatchFixtures.malformed) {
        expect(() => EdenBrandSwatch.tryParse(input), returnsNormally, reason: 'Input: $input');
      }
    });
  });

  group('EdenBrandPresetRegistry is unaffected by this TRD', () {
    test('all() still returns exactly 15 presets', () {
      // Test list item 22.
      expect(EdenBrandPresetRegistry.all().length, 15);
    });

    test('byId(gold).color is still a MaterialColor', () {
      // Test list item 23.
      expect(EdenBrandPresetRegistry.byId('gold')!.color, isA<MaterialColor>());
    });
  });
}
