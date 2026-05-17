// test/theme/eden_theme_profile_test.dart
//
// EdenThemeProfile + EdenThemeProfileData contract tests (objective 009 TRD 01).
// Per global TDD Playbook habit 2: test-list-first; behavior cases enumerated
// in TRD 009-01-TRD.md before code was written.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EdenThemeProfile enum contract', () {
    test('has exactly 5 values in the locked order (Constraint 11)', () {
      // Test list item 1 — LOCKED order.
      expect(EdenThemeProfile.values, hasLength(5),
          reason: 'OBJECTIVE.md Constraint 11 locks the profile count at 5');
      expect(EdenThemeProfile.values, [
        EdenThemeProfile.commercialWarm,
        EdenThemeProfile.medicalInstitutional,
        EdenThemeProfile.govFederal,
        EdenThemeProfile.retailVibrant,
        EdenThemeProfile.legalProfessional,
      ]);
    });

    test('commercialWarm is the first (ordinal 0) — default-by-position', () {
      expect(EdenThemeProfile.values.first, EdenThemeProfile.commercialWarm);
      expect(EdenThemeProfile.commercialWarm.index, 0);
    });
  });

  group('EdenThemeProfileData lookup contract', () {
    test('every profile has a corresponding static data instance', () {
      // Test list item 7.
      final lookup = <EdenThemeProfile, EdenThemeProfileData>{
        EdenThemeProfile.commercialWarm: EdenThemeProfileData.commercialWarmData,
        EdenThemeProfile.medicalInstitutional:
            EdenThemeProfileData.medicalInstitutionalData,
        EdenThemeProfile.govFederal: EdenThemeProfileData.govFederalData,
        EdenThemeProfile.retailVibrant: EdenThemeProfileData.retailVibrantData,
        EdenThemeProfile.legalProfessional:
            EdenThemeProfileData.legalProfessionalData,
      };
      for (final profile in EdenThemeProfile.values) {
        expect(lookup[profile], isNotNull,
            reason: 'Missing static data instance for $profile');
      }
    });

    test('each data instance carries its own profile field correctly', () {
      // Test list item 8 — self-referential profile field.
      expect(EdenThemeProfileData.commercialWarmData.profile,
          EdenThemeProfile.commercialWarm);
      expect(EdenThemeProfileData.medicalInstitutionalData.profile,
          EdenThemeProfile.medicalInstitutional);
      expect(EdenThemeProfileData.govFederalData.profile,
          EdenThemeProfile.govFederal);
      expect(EdenThemeProfileData.retailVibrantData.profile,
          EdenThemeProfile.retailVibrant);
      expect(EdenThemeProfileData.legalProfessionalData.profile,
          EdenThemeProfile.legalProfessional);
    });

    test('all 5 instances expose non-null + valid token deltas', () {
      // Test list item 9 — basic sanity.
      final instances = [
        EdenThemeProfileData.commercialWarmData,
        EdenThemeProfileData.medicalInstitutionalData,
        EdenThemeProfileData.govFederalData,
        EdenThemeProfileData.retailVibrantData,
        EdenThemeProfileData.legalProfessionalData,
      ];
      for (final data in instances) {
        expect(data.primaryColor, isNotNull,
            reason: '${data.profile}: primaryColor');
        expect(data.surfaceTonalSeed, isNotNull,
            reason: '${data.profile}: surfaceTonalSeed');
        expect(data.radiusMultiplier, greaterThan(0),
            reason: '${data.profile}: radiusMultiplier must be > 0');
        expect(data.minimumTouchTargetPx, greaterThanOrEqualTo(0),
            reason: '${data.profile}: minimumTouchTargetPx must be >= 0');
        expect(data.density, isNotNull);
      }
    });

    test('EdenThemeProfileScope const constructor compiles', () {
      // Test list item 21 — const-ness check.
      // ignore: prefer_const_constructors
      const scope = EdenThemeProfileScope(
        profile: EdenThemeProfile.commercialWarm,
        child: SizedBox.shrink(),
      );
      expect(scope.profile, EdenThemeProfile.commercialWarm);
    });
  });

  group('commercialWarm back-compat anchor (Constraint 1)', () {
    // The CRITICAL group. Drift here breaks back-compat with today's behavior.
    // If any of these fail: roll back the offending change. Do NOT relax the test.
    test('primaryColor identity-equals EdenColors.gold', () {
      // Test list item 10.
      expect(
        identical(
          EdenThemeProfileData.commercialWarmData.primaryColor,
          EdenColors.gold,
        ),
        isTrue,
        reason:
            'commercialWarm.primaryColor MUST be EdenColors.gold — back-compat lock',
      );
    });

    test('surfaceTonalSeed hex matches EdenColors.neutral[50] (0xFFFAFAFA)', () {
      // Test list item 11.
      expect(
        EdenThemeProfileData.commercialWarmData.surfaceTonalSeed.value,
        0xFFFAFAFA,
        reason: 'commercialWarm.surfaceTonalSeed MUST equal neutral[50] hex',
      );
    });

    test('radiusMultiplier == 1.0', () {
      // Test list item 12.
      expect(EdenThemeProfileData.commercialWarmData.radiusMultiplier, 1.0);
    });

    test('minimumTouchTargetPx == 0', () {
      // Test list item 13.
      expect(EdenThemeProfileData.commercialWarmData.minimumTouchTargetPx, 0);
    });

    test('all font families are null (use defaults)', () {
      // Test list item 14.
      expect(EdenThemeProfileData.commercialWarmData.bodyFontFamily, isNull);
      expect(EdenThemeProfileData.commercialWarmData.displayFontFamily, isNull);
      expect(EdenThemeProfileData.commercialWarmData.monoFontFamily, isNull);
    });

    test('preferBorderOverShadow == false', () {
      // Test list item 15.
      expect(
        EdenThemeProfileData.commercialWarmData.preferBorderOverShadow,
        isFalse,
      );
    });

    test('density == comfortable', () {
      // Test list item 16.
      expect(
        EdenThemeProfileData.commercialWarmData.density,
        EdenThemeProfileDensity.comfortable,
      );
    });
  });

  group('medicalInstitutional data correctness', () {
    test('matches VERTICAL_UX_RESEARCH §2.4.2 spec', () {
      // Test list item 17.
      final data = EdenThemeProfileData.medicalInstitutionalData;
      expect(identical(data.primaryColor, EdenColors.cyan), isTrue);
      expect(data.radiusMultiplier, closeTo(0.667, 0.001),
          reason: '12pt lg → 8pt');
      expect(data.bodyFontFamily, 'IBM Plex Sans');
      expect(data.preferBorderOverShadow, isTrue);
    });
  });

  group('govFederal data correctness', () {
    test('matches USWDS approximation spec', () {
      // Test list item 18.
      final data = EdenThemeProfileData.govFederalData;
      expect(identical(data.primaryColor, EdenColors.blue), isTrue,
          reason: 'blue[900] == #1E3A8A federal navy');
      expect(data.radiusMultiplier, closeTo(0.333, 0.001),
          reason: '12pt lg → 4pt');
      expect(data.minimumTouchTargetPx, 48.0,
          reason: 'USWDS ≥48pt touch floor');
      expect(data.bodyFontFamily, 'Public Sans');
      expect(data.displayFontFamily, 'Public Sans');
      expect(data.preferBorderOverShadow, isTrue);
    });
  });

  group('retailVibrant data correctness', () {
    test('matches Shopify POS brand-expression spec', () {
      // Test list item 19.
      final data = EdenThemeProfileData.retailVibrantData;
      expect(identical(data.primaryColor, EdenColors.purple), isTrue);
      expect(data.radiusMultiplier, 1.0);
      expect(data.bodyFontFamily, isNull);
      expect(data.displayFontFamily, isNull);
      expect(data.monoFontFamily, isNull);
    });
  });

  group('legalProfessional data correctness', () {
    test('matches Clio-style legal-gravitas spec', () {
      // Test list item 20.
      final data = EdenThemeProfileData.legalProfessionalData;
      expect(identical(data.primaryColor, EdenColors.slate), isTrue);
      expect(data.displayFontFamily, 'Crimson Pro');
      expect(data.bodyFontFamily, isNull,
          reason: 'Body stays Plus Jakarta default — only display goes serif');
    });
  });

  group('EdenThemeProfileDataLookup extension', () {
    test('.data getter returns correct instance for each profile', () {
      expect(EdenThemeProfile.commercialWarm.data,
          same(EdenThemeProfileData.commercialWarmData));
      expect(EdenThemeProfile.medicalInstitutional.data,
          same(EdenThemeProfileData.medicalInstitutionalData));
      expect(EdenThemeProfile.govFederal.data,
          same(EdenThemeProfileData.govFederalData));
      expect(EdenThemeProfile.retailVibrant.data,
          same(EdenThemeProfileData.retailVibrantData));
      expect(EdenThemeProfile.legalProfessional.data,
          same(EdenThemeProfileData.legalProfessionalData));
    });
  });
}
