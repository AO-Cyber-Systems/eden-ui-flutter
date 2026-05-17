// test/theme/eden_status_palette_test.dart
//
// EdenStatusPalette ThemeExtension contract + back-compat tests (objective 009 TRD 02).
// Test list per TRD 009-02 ## Test list section.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EdenStatusPalette ThemeExtension contract', () {
    test('extends ThemeExtension<EdenStatusPalette>', () {
      // Test list item 1 — compile-time type check.
      final p = EdenStatusPalette.commercial();
      expect(p, isA<ThemeExtension<EdenStatusPalette>>());
    });

    test('commercial() exposes 15 non-null Color fields', () {
      // Test list item 2.
      final p = EdenStatusPalette.commercial();
      expect(p.successBg, isA<Color>());
      expect(p.successFg, isA<Color>());
      expect(p.successBorder, isA<Color>());
      expect(p.warningBg, isA<Color>());
      expect(p.warningFg, isA<Color>());
      expect(p.warningBorder, isA<Color>());
      expect(p.dangerBg, isA<Color>());
      expect(p.dangerFg, isA<Color>());
      expect(p.dangerBorder, isA<Color>());
      expect(p.infoBg, isA<Color>());
      expect(p.infoFg, isA<Color>());
      expect(p.infoBorder, isA<Color>());
      expect(p.neutralBg, isA<Color>());
      expect(p.neutralFg, isA<Color>());
      expect(p.neutralBorder, isA<Color>());
    });
  });

  group('EdenStatusPalette.forProfile dispatch', () {
    test('commercialWarm returns commercial palette (back-compat)', () {
      // Test list item 3.
      final byProfile =
          EdenStatusPalette.forProfile(EdenThemeProfile.commercialWarm);
      final commercial = EdenStatusPalette.commercial();
      expect(byProfile.successFg, commercial.successFg);
      expect(byProfile.dangerFg, commercial.dangerFg);
      expect(byProfile.neutralFg, commercial.neutralFg);
    });

    test('retailVibrant uses standard semantic colors (research §2.4.4)', () {
      // Test list item 4.
      final retail =
          EdenStatusPalette.forProfile(EdenThemeProfile.retailVibrant);
      final commercial = EdenStatusPalette.commercial();
      expect(retail.successFg, commercial.successFg,
          reason: 'Retail vibrancy = primary color, NOT status palette');
      expect(retail.dangerFg, commercial.dangerFg);
    });

    test('legalProfessional uses restrained (= commercial) palette (research §1.6)',
        () {
      // Test list item 5.
      final legal =
          EdenStatusPalette.forProfile(EdenThemeProfile.legalProfessional);
      final commercial = EdenStatusPalette.commercial();
      expect(legal.warningFg, commercial.warningFg);
    });

    test('medicalInstitutional differs from commercial (border opacity 40% vs 30%)',
        () {
      // Test list item 6.
      final med =
          EdenStatusPalette.forProfile(EdenThemeProfile.medicalInstitutional);
      final commercial = EdenStatusPalette.commercial();
      expect(med.dangerBorder, isNot(commercial.dangerBorder),
          reason: 'Medical danger border must differ from commercial');
      expect(med.dangerBorder.alpha, greaterThan(commercial.dangerBorder.alpha));
    });

    test('govFederal uses USWDS-spec hex values (research §1.7)', () {
      // Test list item 7.
      final gov = EdenStatusPalette.forProfile(EdenThemeProfile.govFederal);
      expect(gov.successFg, const Color(0xFF00A91C), reason: 'USWDS green');
      expect(gov.warningFg, const Color(0xFFFFBE2E), reason: 'USWDS amber');
      expect(gov.dangerFg, const Color(0xFFB50909),
          reason: 'USWDS red (deeper)');
      expect(gov.infoFg, const Color(0xFF005EA2),
          reason: 'USWDS blue (deeper)');
    });
  });

  group('EdenStatusPalette.copyWith', () {
    test('returns clone when no overrides given', () {
      // Test list item 8.
      final original = EdenStatusPalette.commercial();
      final clone = original.copyWith();
      expect(clone.successFg, original.successFg);
      expect(clone.dangerBg, original.dangerBg);
      expect(clone.neutralBorder, original.neutralBorder);
    });

    test('applies field overrides while preserving other fields', () {
      // Test list item 9.
      final original = EdenStatusPalette.commercial();
      final overridden = original.copyWith(successFg: const Color(0xFFFF00FF));
      expect(overridden.successFg, const Color(0xFFFF00FF));
      expect(overridden.successBg, original.successBg,
          reason: 'Unspecified fields preserved');
      expect(overridden.dangerFg, original.dangerFg);
    });
  });

  group('EdenStatusPalette.lerp', () {
    test('t=0 returns equivalent of this', () {
      // Test list item 10.
      final a = EdenStatusPalette.commercial();
      final b = EdenStatusPalette.forProfile(EdenThemeProfile.govFederal);
      final lerped = a.lerp(b, 0.0);
      expect(lerped.successFg, a.successFg);
    });

    test('t=1 returns equivalent of other', () {
      // Test list item 11.
      final a = EdenStatusPalette.commercial();
      final b = EdenStatusPalette.forProfile(EdenThemeProfile.govFederal);
      final lerped = a.lerp(b, 1.0);
      expect(lerped.successFg, b.successFg);
    });

    test('t=0.5 produces Color.lerp midpoint per field', () {
      // Test list item 12.
      final a = EdenStatusPalette.commercial();
      final b = EdenStatusPalette.forProfile(EdenThemeProfile.govFederal);
      final lerped = a.lerp(b, 0.5);
      final expectedSuccessFg = Color.lerp(a.successFg, b.successFg, 0.5)!;
      expect(lerped.successFg, expectedSuccessFg);
    });

    test('lerp(null, t) returns this (null-safety)', () {
      // Test list item 13.
      final a = EdenStatusPalette.commercial();
      final lerped = a.lerp(null, 0.5);
      expect(lerped.successFg, a.successFg);
      expect(lerped.dangerFg, a.dangerFg);
    });
  });

  group('Back-compat anchor — commercial() values match EdenColors (Constraint 1)',
      () {
    test('successFg matches EdenColors.success', () {
      // Test list item 14.
      expect(
        EdenStatusPalette.commercial().successFg.value,
        EdenColors.success.value,
        reason:
            'commercial().successFg MUST equal EdenColors.success — back-compat lock',
      );
    });

    test('successBg matches EdenColors.successBg', () {
      // Test list item 15.
      expect(
        EdenStatusPalette.commercial().successBg.value,
        EdenColors.successBg.value,
      );
    });

    test('warningFg + warningBg match EdenColors equivalents', () {
      // Test list item 16.
      expect(EdenStatusPalette.commercial().warningFg.value,
          EdenColors.warning.value);
      expect(EdenStatusPalette.commercial().warningBg.value,
          EdenColors.warningBg.value);
    });

    test('dangerFg + dangerBg match EdenColors.error equivalents', () {
      // Test list item 17.
      expect(EdenStatusPalette.commercial().dangerFg.value,
          EdenColors.error.value);
      expect(EdenStatusPalette.commercial().dangerBg.value,
          EdenColors.errorBg.value);
    });

    test('infoFg + infoBg match EdenColors equivalents', () {
      // Test list item 18.
      expect(EdenStatusPalette.commercial().infoFg.value,
          EdenColors.info.value);
      expect(EdenStatusPalette.commercial().infoBg.value,
          EdenColors.infoBg.value);
    });
  });

  group('EdenColors static constants UNCHANGED (Constraint 1)', () {
    test('all 8 status static constants still expose the canonical hex values',
        () {
      // Test list item 25.
      expect(EdenColors.success, const Color(0xFF10B981));
      expect(EdenColors.successBg, const Color(0x1A10B981));
      expect(EdenColors.warning, const Color(0xFFF59E0B));
      expect(EdenColors.warningBg, const Color(0x1AF59E0B));
      expect(EdenColors.error, const Color(0xFFEF4444));
      expect(EdenColors.errorBg, const Color(0x1AEF4444));
      expect(EdenColors.info, const Color(0xFF3B82F6));
      expect(EdenColors.infoBg, const Color(0x1A3B82F6));
    });
  });
}
