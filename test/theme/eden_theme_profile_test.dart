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
}
