// Tests for EdenThemeProfileData.copyWith and EdenThemeProfileData.runtime
// (TRD 022-03). These build profile data from runtime values without adding
// a sixth profile and without exposing the four inert tokens
// (surfaceTonalSeed, radiusMultiplier, minimumTouchTargetPx,
// preferBorderOverShadow) as settable parameters. See
// .planning/objectives/022-runtime-brand-tokens/022-03-TRD.md and
// 022-CONTEXT.md for the locked rules this suite enforces.
//
// Plain `test(...)` is sufficient here — nothing in this file touches
// GoogleFonts or needs the widget binding, unlike the theme-building suites
// that require `testWidgets`.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/profile_fixtures.dart';

void main() {
  group('const instances unchanged', () {
    test('commercialWarmData.primaryColor is EdenColors.gold', () {
      expect(
        EdenThemeProfileData.commercialWarmData.primaryColor,
        EdenColors.gold,
      );
    });

    test(
      'commercialWarmData.surfaceTonalSeed is Color(0xFFFAFAFA)',
      () {
        expect(
          EdenThemeProfileData.commercialWarmData.surfaceTonalSeed,
          const Color(0xFFFAFAFA),
        );
      },
    );

    test('each static instance reports its own profile enum value', () {
      expect(
        EdenThemeProfileData.commercialWarmData.profile,
        EdenThemeProfile.commercialWarm,
      );
      expect(
        EdenThemeProfileData.medicalInstitutionalData.profile,
        EdenThemeProfile.medicalInstitutional,
      );
      expect(
        EdenThemeProfileData.govFederalData.profile,
        EdenThemeProfile.govFederal,
      );
      expect(
        EdenThemeProfileData.retailVibrantData.profile,
        EdenThemeProfile.retailVibrant,
      );
      expect(
        EdenThemeProfileData.legalProfessionalData.profile,
        EdenThemeProfile.legalProfessional,
      );
    });

    test('EdenThemeProfile.values has exactly 5 members in LOCKED order', () {
      expect(EdenThemeProfile.values, ProfileFixtures.allProfilesInLockedOrder);
      expect(EdenThemeProfile.values.length, 5);
    });

    test(
      'EdenThemeProfile.govFederal.data is identical() to EdenThemeProfileData.govFederalData',
      () {
        expect(
          identical(
            EdenThemeProfile.govFederal.data,
            EdenThemeProfileData.govFederalData,
          ),
          isTrue,
        );
      },
    );
  });

  group('copyWith pass-through', () {
    test('commercialWarmData.copyWith() with no args equals original in all fields', () {
      final original = EdenThemeProfileData.commercialWarmData;
      final copy = original.copyWith();

      expect(copy.profile, original.profile);
      expect(copy.primaryColor, original.primaryColor);
      expect(copy.surfaceTonalSeed, original.surfaceTonalSeed);
      expect(copy.radiusMultiplier, original.radiusMultiplier);
      expect(copy.density, original.density);
      expect(copy.minimumTouchTargetPx, original.minimumTouchTargetPx);
      expect(copy.bodyFontFamily, original.bodyFontFamily);
      expect(copy.displayFontFamily, original.displayFontFamily);
      expect(copy.monoFontFamily, original.monoFontFamily);
      expect(copy.preferBorderOverShadow, original.preferBorderOverShadow);
    });

    test('copyWith(primaryColor: EdenColors.blue) changes only primaryColor', () {
      final original = EdenThemeProfileData.commercialWarmData;
      final copy = original.copyWith(primaryColor: EdenColors.blue);

      expect(copy.primaryColor, EdenColors.blue);
      expect(copy.profile, original.profile);
      expect(copy.surfaceTonalSeed, original.surfaceTonalSeed);
      expect(copy.radiusMultiplier, original.radiusMultiplier);
      expect(copy.density, original.density);
      expect(copy.minimumTouchTargetPx, original.minimumTouchTargetPx);
      expect(copy.bodyFontFamily, original.bodyFontFamily);
      expect(copy.displayFontFamily, original.displayFontFamily);
      expect(copy.monoFontFamily, original.monoFontFamily);
      expect(copy.preferBorderOverShadow, original.preferBorderOverShadow);
    });

    test("copyWith(bodyFontFamily: 'Inter') changes only that field", () {
      final original = EdenThemeProfileData.commercialWarmData;
      final copy = original.copyWith(bodyFontFamily: 'Inter');

      expect(copy.bodyFontFamily, 'Inter');
      expect(copy.profile, original.profile);
      expect(copy.primaryColor, original.primaryColor);
      expect(copy.surfaceTonalSeed, original.surfaceTonalSeed);
      expect(copy.radiusMultiplier, original.radiusMultiplier);
      expect(copy.density, original.density);
      expect(copy.minimumTouchTargetPx, original.minimumTouchTargetPx);
      expect(copy.displayFontFamily, original.displayFontFamily);
      expect(copy.monoFontFamily, original.monoFontFamily);
      expect(copy.preferBorderOverShadow, original.preferBorderOverShadow);
    });

    test(
      'govFederalData.copyWith(primaryColor: EdenColors.red) preserves the inert tokens',
      () {
        final copy = EdenThemeProfileData.govFederalData.copyWith(
          primaryColor: EdenColors.red,
        );

        expect(copy.primaryColor, EdenColors.red);
        expect(copy.radiusMultiplier, 0.333);
        expect(copy.minimumTouchTargetPx, 48);
        expect(copy.preferBorderOverShadow, isTrue);
      },
    );

    test(
      "medicalInstitutionalData.copyWith(displayFontFamily: 'Inter') preserves bodyFontFamily and surfaceTonalSeed",
      () {
        final original = EdenThemeProfileData.medicalInstitutionalData;
        final copy = original.copyWith(displayFontFamily: 'Inter');

        expect(copy.displayFontFamily, 'Inter');
        expect(copy.bodyFontFamily, 'IBM Plex Sans');
        expect(copy.surfaceTonalSeed, original.surfaceTonalSeed);
      },
    );

    test('copyWith never mutates the receiver', () {
      final source = EdenThemeProfileData.commercialWarmData;
      final beforePrimary = source.primaryColor;
      final beforeBody = source.bodyFontFamily;

      source.copyWith(primaryColor: EdenColors.blue, bodyFontFamily: 'Inter');

      expect(source.primaryColor, beforePrimary);
      expect(source.bodyFontFamily, beforeBody);
      // Re-assert against the canonical const instance too, in case `source`
      // were ever accidentally a mutable alias.
      expect(
        EdenThemeProfileData.commercialWarmData.primaryColor,
        beforePrimary,
      );
      expect(
        EdenThemeProfileData.commercialWarmData.bodyFontFamily,
        beforeBody,
      );
    });
  });

  group('runtime() factory', () {
    test('runtime() with no args equals commercialWarmData field-by-field', () {
      final built = EdenThemeProfileData.runtime();
      final base = EdenThemeProfileData.commercialWarmData;

      expect(built.profile, base.profile);
      expect(built.primaryColor, base.primaryColor);
      expect(built.surfaceTonalSeed, base.surfaceTonalSeed);
      expect(built.radiusMultiplier, base.radiusMultiplier);
      expect(built.density, base.density);
      expect(built.minimumTouchTargetPx, base.minimumTouchTargetPx);
      expect(built.bodyFontFamily, base.bodyFontFamily);
      expect(built.displayFontFamily, base.displayFontFamily);
      expect(built.monoFontFamily, base.monoFontFamily);
      expect(built.preferBorderOverShadow, base.preferBorderOverShadow);
    });

    test(
      'runtime(primaryColor: <MaterialColor>) yields that primaryColor and the commercialWarm profile',
      () {
        final built = EdenThemeProfileData.runtime(primaryColor: EdenColors.blue);

        expect(built.primaryColor, EdenColors.blue);
        expect(built.profile, EdenThemeProfile.commercialWarm);
      },
    );

    test(
      'runtime(base: EdenThemeProfile.govFederal) inherits govFederal enum + inert-token values',
      () {
        final built = EdenThemeProfileData.runtime(base: EdenThemeProfile.govFederal);

        expect(built.profile, EdenThemeProfile.govFederal);
        expect(built.radiusMultiplier, 0.333);
        expect(built.minimumTouchTargetPx, 48);
        expect(built.preferBorderOverShadow, isTrue);
      },
    );

    test(
      'runtime(base: govFederal, bodyFontFamily: Inter) overrides font but keeps govFederal enum',
      () {
        final built = EdenThemeProfileData.runtime(
          base: EdenThemeProfile.govFederal,
          bodyFontFamily: 'Inter',
        );

        expect(built.bodyFontFamily, 'Inter');
        expect(built.profile, EdenThemeProfile.govFederal);

        // EdenStatusPalette.forProfile must still resolve the USWDS palette
        // because the runtime instance carries a real enum value.
        final palette = EdenStatusPalette.forProfile(built.profile);
        expect(palette, EdenStatusPalette.forProfile(EdenThemeProfile.govFederal));
      },
    );

    test(
      'runtime(bodyFontFamily:, displayFontFamily:, monoFontFamily:) sets all three in one call',
      () {
        final built = EdenThemeProfileData.runtime(
          bodyFontFamily: 'Inter',
          displayFontFamily: 'Outfit',
          monoFontFamily: 'Fira Code',
        );

        expect(built.bodyFontFamily, 'Inter');
        expect(built.displayFontFamily, 'Outfit');
        expect(built.monoFontFamily, 'Fira Code');
      },
    );
  });

  group('inert tokens preserved, not settable', () {
    // copyWith's full parameter list is exactly:
    //   {profile, primaryColor, density, bodyFontFamily, displayFontFamily,
    //    monoFontFamily}
    // runtime's full parameter list is exactly:
    //   {base, primaryColor, bodyFontFamily, displayFontFamily,
    //    monoFontFamily}
    // Neither exposes surfaceTonalSeed, radiusMultiplier,
    // minimumTouchTargetPx, or preferBorderOverShadow as a parameter name —
    // there is no keyword argument for any of the four on either member.
    // This group asserts that by construction (no such named argument
    // compiles) and by checking that every base's inert-token values survive
    // copyWith/runtime untouched. It does NOT assert anything about the
    // inert tokens reaching a widget — they reach no widget today (objective
    // 022 CONTEXT finding 6), and wiring them up is objective 0b's job, not
    // this TRD's.
    for (final profile in ProfileFixtures.allProfilesInLockedOrder) {
      test(
        'copyWith() on ${profile.name}.data preserves all four inert tokens',
        () {
          final original = profile.data;
          final copy = original.copyWith();

          expect(copy.surfaceTonalSeed, original.surfaceTonalSeed);
          expect(copy.radiusMultiplier, original.radiusMultiplier);
          expect(copy.minimumTouchTargetPx, original.minimumTouchTargetPx);
          expect(copy.preferBorderOverShadow, original.preferBorderOverShadow);
        },
      );
    }

    for (final profile in ProfileFixtures.allProfilesInLockedOrder) {
      test(
        'runtime(base: ${profile.name}) preserves density (copyWith exposes it, runtime does not)',
        () {
          final built = EdenThemeProfileData.runtime(base: profile);

          expect(built.density, profile.data.density);
        },
      );
    }

    test(
      "runtime(monoFontFamily: 'Fira Code').monoFontFamily carries the value as DATA only",
      () {
        // monoFontFamily is carried through as a plain data field. It is not
        // applied to any ThemeData by runtime() or by anything in this file
        // — Material's TextTheme has no mono role. The consumer route for
        // rendering it is EdenProfileFonts.monoTextStyleForFamily, called
        // explicitly by whoever wants mono type. The same reasoning is why
        // monoFontFamily stays OFF EdenAdaptiveTheme.lightFromConfig in TRD
        // 022-05: a data field a consumer reads is honest, a theme-building
        // parameter that themes nothing is not.
        final built = EdenThemeProfileData.runtime(monoFontFamily: 'Fira Code');

        expect(built.monoFontFamily, 'Fira Code');
      },
    );
  });
}
