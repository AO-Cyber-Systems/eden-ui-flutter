// test/theme/eden_adaptive_theme_runtime_test.dart
//
// Objective 022 TRD 05 — runtime-composition spec for EdenAdaptiveTheme.
//
// Covers the data-taking core (lightFromData/darkFromData), the
// window.APP_CONFIG-shaped entry points (lightFromConfig/darkFromConfig),
// and proof that the existing enum-taking API (light/dark) is unchanged
// after being refactored to delegate onto the same core.
//
// Do NOT touch eden_adaptive_theme_test.dart (objective 009's control) or
// eden_theme_back_compat_test.dart (TRD 022-01's protected baseline).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eden_ui_flutter/eden_ui.dart';

import '_fixtures/profile_fixtures.dart';

void main() {
  group('window.APP_CONFIG boot path', () {
    testWidgets('lightFromConfig(brandHex) sets colorScheme.primary to the exact hex',
        (tester) async {
      final theme = EdenAdaptiveTheme.lightFromConfig(brandHex: '#0F62FE');
      expect(theme.colorScheme.primary.value, 0xFF0F62FE);
    });

    testWidgets(
        'darkFromConfig(brandHex) builds without throwing on a generated swatch',
        (tester) async {
      expect(
        () => EdenAdaptiveTheme.darkFromConfig(brandHex: '#0F62FE'),
        returnsNormally,
      );
      final theme = EdenAdaptiveTheme.darkFromConfig(brandHex: '#0F62FE');
      expect(theme, isA<ThemeData>());
    });

    testWidgets(
        'lightFromConfig(bodyFontFamily) overlays body and pins the exact '
        'Outfit_regular display family (not a contains() check)', (tester) async {
      final theme = EdenAdaptiveTheme.lightFromConfig(bodyFontFamily: 'Inter');
      expect(theme.textTheme.bodyLarge?.fontFamily, 'Inter_regular');
      expect(theme.textTheme.displayLarge?.fontFamily, 'Outfit_regular');
    });

    testWidgets(
        'the same call preserves base fontSize/fontWeight on displayLarge '
        '(merge-direction assertion)', (tester) async {
      final theme = EdenAdaptiveTheme.lightFromConfig(bodyFontFamily: 'Inter');
      expect(theme.textTheme.displayLarge?.fontSize, 48.0);
      expect(theme.textTheme.displayLarge?.fontWeight, FontWeight.w800);
    });

    testWidgets(
        'lightFromConfig(displayFontFamily) changes display roles and leaves '
        'body on Plus Jakarta Sans', (tester) async {
      final theme = EdenAdaptiveTheme.lightFromConfig(displayFontFamily: 'Inter');
      expect(theme.textTheme.displayLarge?.fontFamily, 'Inter_regular');
      expect(theme.textTheme.bodyLarge?.fontFamily, contains('PlusJakartaSans'));
    });

    testWidgets('lightFromConfig applies brandHex and bodyFontFamily together',
        (tester) async {
      final theme = EdenAdaptiveTheme.lightFromConfig(
        brandHex: '#0F62FE',
        bodyFontFamily: 'Inter',
      );
      expect(theme.colorScheme.primary.value, 0xFF0F62FE);
      expect(theme.textTheme.bodyLarge?.fontFamily, 'Inter_regular');
    });

    testWidgets(
        'lightFromConfig(base: govFederal, brandHex:) keeps govFederal\'s '
        'USWDS status palette while taking the runtime primary', (tester) async {
      final theme = EdenAdaptiveTheme.lightFromConfig(
        base: EdenThemeProfile.govFederal,
        brandHex: '#0F62FE',
      );
      expect(theme.colorScheme.primary.value, 0xFF0F62FE);
      final baseline = EdenAdaptiveTheme.light(EdenThemeProfile.govFederal);
      expect(
        theme.extension<EdenStatusPalette>(),
        baseline.extension<EdenStatusPalette>(),
      );
    });

    testWidgets(
        'font sizes, weights and heights from the base TextTheme survive a '
        'runtime font override', (tester) async {
      final theme = EdenAdaptiveTheme.lightFromConfig(bodyFontFamily: 'Inter');
      final base = EdenTheme.light();
      expect(theme.textTheme.bodyLarge?.fontSize, base.textTheme.bodyLarge?.fontSize);
      expect(
        theme.textTheme.bodyLarge?.fontWeight,
        base.textTheme.bodyLarge?.fontWeight,
      );
      expect(theme.textTheme.bodyLarge?.height, base.textTheme.bodyLarge?.height);
    });
  });

  group('malformed config survives boot', () {
    testWidgets('brandHex: "not-a-colour" falls back to the base primaryColor',
        (tester) async {
      expect(
        () => EdenAdaptiveTheme.lightFromConfig(brandHex: 'not-a-colour'),
        returnsNormally,
      );
      final theme = EdenAdaptiveTheme.lightFromConfig(brandHex: 'not-a-colour');
      expect(
        theme.colorScheme.primary.value,
        EdenThemeProfile.commercialWarm.data.primaryColor.value,
      );
    });

    testWidgets(
        'brandHex: "", "#12345", null each fall back to the base primaryColor',
        (tester) async {
      for (final badHex in ['', '#12345', null]) {
        expect(
          () => EdenAdaptiveTheme.lightFromConfig(brandHex: badHex),
          returnsNormally,
        );
        final theme = EdenAdaptiveTheme.lightFromConfig(brandHex: badHex);
        expect(
          theme.colorScheme.primary.value,
          EdenThemeProfile.commercialWarm.data.primaryColor.value,
        );
      }
    });

    testWidgets(
        'bodyFontFamily: "Intr" falls back to Plus Jakarta Sans, never Roboto',
        (tester) async {
      expect(
        () => EdenAdaptiveTheme.lightFromConfig(bodyFontFamily: 'Intr'),
        returnsNormally,
      );
      final theme = EdenAdaptiveTheme.lightFromConfig(bodyFontFamily: 'Intr');
      expect(theme.textTheme.bodyLarge?.fontFamily, contains('PlusJakartaSans'));
      expect(theme.textTheme.bodyLarge?.fontFamily, isNot(contains('Roboto')));
    });

    testWidgets(
        'brandHex + bodyFontFamily both garbage falls back to the base '
        'primary color and body font, but a non-null bodyFontFamily still '
        'defeats the overlay short-circuit (pre-existing objective-009 '
        'Outfit_800 -> Outfit_regular display-weight-file downgrade, '
        'pinned here, not fixed)', (tester) async {
      expect(
        () => EdenAdaptiveTheme.lightFromConfig(
          brandHex: 'garbage',
          bodyFontFamily: 'garbage',
        ),
        returnsNormally,
      );
      final theme = EdenAdaptiveTheme.lightFromConfig(
        brandHex: 'garbage',
        bodyFontFamily: 'garbage',
      );
      final baseline = EdenAdaptiveTheme.light(EdenThemeProfile.commercialWarm);
      expect(theme.colorScheme.primary.value, baseline.colorScheme.primary.value);
      expect(theme.textTheme.bodyLarge?.fontFamily, baseline.textTheme.bodyLarge?.fontFamily);
      // `bodyFontFamily: 'garbage'` is non-null, so it defeats
      // `_withDataTextTheme`'s short-circuit (which only skips the overlay
      // when BOTH body and display family are null) even though
      // `displayFontFamily` itself is null here. The overlay then runs for
      // every TextTheme role, including display ones, resolving the null
      // displayFontFamily through `EdenProfileFonts.displayTextStyleForFamily`
      // -> `GoogleFonts.outfit()`'s fallback, which is the Regular-weight
      // FILE ('Outfit_regular') — not the ExtraBold FILE ('Outfit_800') the
      // baseline (no-override) theme carries. This is pre-existing,
      // unrelated-to-this-TRD behavior from objective 009 (the FontWeight.w800
      // *request* survives `.merge()`; only the underlying font *file*
      // silently downgrades). Pinned to the exact literal on purpose — do
      // NOT loosen this to `baseline.textTheme.displayLarge?.fontFamily` or
      // to a `contains('Outfit')` check, and do not "fix" the downgrade here.
      expect(theme.textTheme.displayLarge?.fontFamily, 'Outfit_regular');
    });

    testWidgets('darkFromConfig satisfies the same malformed-input fallbacks',
        (tester) async {
      for (final badHex in ['not-a-colour', '', '#12345', null, 'garbage']) {
        expect(
          () => EdenAdaptiveTheme.darkFromConfig(brandHex: badHex),
          returnsNormally,
        );
        final theme = EdenAdaptiveTheme.darkFromConfig(brandHex: badHex);
        expect(theme, isA<ThemeData>());
      }
      expect(
        () => EdenAdaptiveTheme.darkFromConfig(bodyFontFamily: 'garbage'),
        returnsNormally,
      );
      final theme = EdenAdaptiveTheme.darkFromConfig(bodyFontFamily: 'garbage');
      expect(theme.textTheme.bodyLarge?.fontFamily, contains('PlusJakartaSans'));
    });
  });

  group('data-taking core', () {
    testWidgets('lightFromData(EdenThemeProfileData.runtime()) equals EdenTheme.light()',
        (tester) async {
      final theme = EdenAdaptiveTheme.lightFromData(EdenThemeProfileData.runtime());
      final base = EdenTheme.light();
      expect(theme.colorScheme.primary.value, base.colorScheme.primary.value);
      _expectSameFontFamilies(theme.textTheme, base.textTheme);
    });

    testWidgets('lightFromData(profile.data) equals light(profile) for all five profiles',
        (tester) async {
      for (final profile in ProfileFixtures.allProfilesInLockedOrder) {
        final fromData = EdenAdaptiveTheme.lightFromData(profile.data);
        final fromEnum = EdenAdaptiveTheme.light(profile);
        expect(
          fromData.colorScheme.primary.value,
          fromEnum.colorScheme.primary.value,
          reason: 'primary mismatch for $profile',
        );
        _expectSameFontFamilies(fromData.textTheme, fromEnum.textTheme, reason: '$profile');
        expect(
          fromData.extension<EdenStatusPalette>(),
          fromEnum.extension<EdenStatusPalette>(),
          reason: 'status palette mismatch for $profile',
        );
      }
    });

    testWidgets('darkFromData(profile.data) equals dark(profile) for all five profiles',
        (tester) async {
      for (final profile in ProfileFixtures.allProfilesInLockedOrder) {
        final fromData = EdenAdaptiveTheme.darkFromData(profile.data);
        final fromEnum = EdenAdaptiveTheme.dark(profile);
        expect(
          fromData.colorScheme.primary.value,
          fromEnum.colorScheme.primary.value,
          reason: 'primary mismatch for $profile',
        );
        _expectSameFontFamilies(fromData.textTheme, fromEnum.textTheme, reason: '$profile');
      }
    });
  });

  group('existing API unchanged', () {
    testWidgets('light(commercialWarm) still equals EdenTheme.light() (the spine)',
        (tester) async {
      final theme = EdenAdaptiveTheme.light(EdenThemeProfile.commercialWarm);
      final base = EdenTheme.light();
      expect(theme.colorScheme.primary.value, base.colorScheme.primary.value);
      expect(theme.textTheme.bodyLarge?.fontFamily, base.textTheme.bodyLarge?.fontFamily);
      expect(theme.textTheme.displayLarge?.fontFamily, base.textTheme.displayLarge?.fontFamily);
    });

    testWidgets(
        'light(profile, brand: medical-teal) still overrides primary for all '
        'five profiles', (tester) async {
      final brand = EdenBrandPresetRegistry.byId('medical-teal');
      expect(brand, isNotNull);
      for (final profile in ProfileFixtures.allProfilesInLockedOrder) {
        final theme = EdenAdaptiveTheme.light(profile, brand: brand);
        expect(
          theme.colorScheme.primary.value,
          brand!.color.value,
          reason: 'brand override failed for $profile',
        );
      }
    });

    testWidgets(
        'the overlay short-circuit still holds for commercialWarm and '
        'retailVibrant', (tester) async {
      final base = EdenTheme.light();
      for (final profile in [
        EdenThemeProfile.commercialWarm,
        EdenThemeProfile.retailVibrant,
      ]) {
        final theme = EdenAdaptiveTheme.light(profile);
        _expectSameFontFamilies(theme.textTheme, base.textTheme, reason: '$profile');
      }
    });

    testWidgets('EdenAdaptiveTheme as a widget still themes its subtree',
        (tester) async {
      await tester.pumpWidget(
        ProfileFixtures.wrapWithProfile(
          EdenThemeProfile.commercialWarm,
          Builder(
            builder: (context) => Text(
              'themed',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
      expect(find.text('themed'), findsOneWidget);
    });
  });

  group('mono is data, not a theme parameter', () {
    testWidgets(
        'EdenProfileFonts.monoTextStyleForFamily resolves a runtime family '
        'directly — mono is reachable, just not on the theme entry point',
        (tester) async {
      final style = EdenProfileFonts.monoTextStyleForFamily('Fira Code');
      expect(style.fontFamily, isNotNull);
      expect(style.fontFamily, contains('FiraCode'));
      // lightFromConfig has no monoFontFamily parameter because
      // _withDataTextTheme overlays body and display roles only — Material's
      // TextTheme has no mono role, so such a parameter would return a
      // ThemeData identical to one built without it. Mono stays reachable
      // via this resolver and via EdenThemeProfileData.runtime's data field.
    });
  });
}

Iterable<String?> _allFontFamilies(TextTheme t) => [
      t.displayLarge?.fontFamily,
      t.displayMedium?.fontFamily,
      t.displaySmall?.fontFamily,
      t.headlineLarge?.fontFamily,
      t.headlineMedium?.fontFamily,
      t.headlineSmall?.fontFamily,
      t.titleLarge?.fontFamily,
      t.titleMedium?.fontFamily,
      t.titleSmall?.fontFamily,
      t.bodyLarge?.fontFamily,
      t.bodyMedium?.fontFamily,
      t.bodySmall?.fontFamily,
      t.labelLarge?.fontFamily,
      t.labelMedium?.fontFamily,
      t.labelSmall?.fontFamily,
    ];

void _expectSameFontFamilies(TextTheme a, TextTheme b, {String? reason}) {
  final aFamilies = _allFontFamilies(a).toList();
  final bFamilies = _allFontFamilies(b).toList();
  expect(aFamilies, bFamilies, reason: reason);
}
