// test/theme/eden_profile_fonts_test.dart
//
// EdenProfileFonts contract tests (objective 009 TRD 04).
// Test list per TRD 009-04-TRD.md ## Test list section.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EdenProfileFonts.bodyFontFamily', () {
    test('commercialWarm returns null (use default Plus Jakarta Sans)', () {
      expect(EdenProfileFonts.bodyFontFamily(EdenThemeProfile.commercialWarm),
          isNull);
    });
    test('medicalInstitutional returns IBM Plex Sans', () {
      expect(
          EdenProfileFonts.bodyFontFamily(
              EdenThemeProfile.medicalInstitutional),
          'IBM Plex Sans');
    });
    test('govFederal returns Public Sans', () {
      expect(EdenProfileFonts.bodyFontFamily(EdenThemeProfile.govFederal),
          'Public Sans');
    });
    test('retailVibrant returns null', () {
      expect(EdenProfileFonts.bodyFontFamily(EdenThemeProfile.retailVibrant),
          isNull);
    });
    test('legalProfessional returns null (body stays Plus Jakarta default)',
        () {
      expect(
          EdenProfileFonts.bodyFontFamily(EdenThemeProfile.legalProfessional),
          isNull);
    });
  });

  group('EdenProfileFonts.displayFontFamily', () {
    test('commercialWarm returns null', () {
      expect(
          EdenProfileFonts.displayFontFamily(EdenThemeProfile.commercialWarm),
          isNull);
    });
    test('medicalInstitutional returns null (display stays Outfit)', () {
      expect(
          EdenProfileFonts.displayFontFamily(
              EdenThemeProfile.medicalInstitutional),
          isNull);
    });
    test('govFederal returns Public Sans (body AND display)', () {
      expect(EdenProfileFonts.displayFontFamily(EdenThemeProfile.govFederal),
          'Public Sans');
    });
    test('legalProfessional returns Crimson Pro', () {
      expect(
          EdenProfileFonts.displayFontFamily(
              EdenThemeProfile.legalProfessional),
          'Crimson Pro');
    });
    test('retailVibrant returns null', () {
      expect(EdenProfileFonts.displayFontFamily(EdenThemeProfile.retailVibrant),
          isNull);
    });
  });

  group('EdenProfileFonts.monoFontFamily', () {
    test('all 5 profiles return null in v1 (universal JetBrains Mono)', () {
      // Test list item 11.
      for (final profile in EdenThemeProfile.values) {
        expect(EdenProfileFonts.monoFontFamily(profile), isNull,
            reason: '$profile mono should be null in v1');
      }
    });
  });

  // GoogleFonts in the test environment populates TextStyle.fontFamily with
  // a PascalCase-no-spaces variant of the family name plus a weight suffix
  // (e.g., 'Plus Jakarta Sans' → 'PlusJakartaSans_regular'). The actual
  // rendered family is correct; the assertion needs to match the test-env
  // shape, not the canonical Google Fonts catalog string. Use a startsWith
  // matcher built from the family name with spaces stripped.
  Matcher hasFontFamilyPrefix(String googleFontsFamily) {
    final pascal = googleFontsFamily.replaceAll(' ', '');
    return predicate<String?>(
      (value) => value != null && value.startsWith(pascal),
      'fontFamily starting with "$pascal" (canonical family: "$googleFontsFamily")',
    );
  }

  group('EdenProfileFonts.bodyTextStyle (TextStyle builder)', () {
    testWidgets('commercialWarm body has fontFamily Plus Jakarta Sans',
        (tester) async {
      // Test list item 12 — back-compat fallback.
      final style =
          EdenProfileFonts.bodyTextStyle(EdenThemeProfile.commercialWarm);
      expect(style.fontFamily, hasFontFamilyPrefix('Plus Jakarta Sans'));
    });

    testWidgets('medicalInstitutional body has fontFamily IBM Plex Sans',
        (tester) async {
      // Test list item 13.
      final style = EdenProfileFonts.bodyTextStyle(
          EdenThemeProfile.medicalInstitutional);
      expect(style.fontFamily, hasFontFamilyPrefix('IBM Plex Sans'));
    });

    testWidgets('govFederal body has fontFamily Public Sans', (tester) async {
      // Test list item 14.
      final style =
          EdenProfileFonts.bodyTextStyle(EdenThemeProfile.govFederal);
      expect(style.fontFamily, hasFontFamilyPrefix('Public Sans'));
    });
  });

  group('EdenProfileFonts.displayTextStyle', () {
    testWidgets('commercialWarm display has fontFamily Outfit', (tester) async {
      // Test list item 15 — back-compat fallback.
      final style =
          EdenProfileFonts.displayTextStyle(EdenThemeProfile.commercialWarm);
      expect(style.fontFamily, hasFontFamilyPrefix('Outfit'));
    });

    testWidgets('govFederal display has fontFamily Public Sans',
        (tester) async {
      // Test list item 16.
      final style =
          EdenProfileFonts.displayTextStyle(EdenThemeProfile.govFederal);
      expect(style.fontFamily, hasFontFamilyPrefix('Public Sans'));
    });

    testWidgets('legalProfessional display has fontFamily Crimson Pro',
        (tester) async {
      // Test list item 17.
      final style = EdenProfileFonts.displayTextStyle(
          EdenThemeProfile.legalProfessional);
      expect(style.fontFamily, hasFontFamilyPrefix('Crimson Pro'));
    });
  });

  group('EdenProfileFonts.monoTextStyle', () {
    testWidgets('all 5 profiles return fontFamily JetBrains Mono',
        (tester) async {
      // Test list item 18.
      for (final profile in EdenThemeProfile.values) {
        final style = EdenProfileFonts.monoTextStyle(profile);
        expect(style.fontFamily, hasFontFamilyPrefix('JetBrains Mono'),
            reason: '$profile mono should fall back to JetBrains Mono in v1');
      }
    });
  });

  group('Back-compat + parameter passthrough', () {
    testWidgets(
        'bodyTextStyle commercialWarm with no params has Plus Jakarta family + null sizing',
        (tester) async {
      // Test list item 19.
      final ours =
          EdenProfileFonts.bodyTextStyle(EdenThemeProfile.commercialWarm);
      expect(ours.fontFamily, hasFontFamilyPrefix('Plus Jakarta Sans'));
      expect(ours.fontSize, isNull);
      expect(ours.fontWeight, isNull);
    });

    testWidgets('bodyTextStyle commercialWarm with sized params returns sized style',
        (tester) async {
      // Test list item 20.
      final ours = EdenProfileFonts.bodyTextStyle(
        EdenThemeProfile.commercialWarm,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: Colors.black,
      );
      expect(ours.fontFamily, hasFontFamilyPrefix('Plus Jakarta Sans'));
      expect(ours.fontSize, 16);
      expect(ours.fontWeight, FontWeight.w600);
      expect(ours.height, 1.5);
      expect(ours.color, Colors.black);
    });

    testWidgets('bodyTextStyle medical with fontSize 14 retains IBM Plex Sans family',
        (tester) async {
      // Test list item 21.
      final style = EdenProfileFonts.bodyTextStyle(
        EdenThemeProfile.medicalInstitutional,
        fontSize: 14,
      );
      expect(style.fontFamily, hasFontFamilyPrefix('IBM Plex Sans'));
      expect(style.fontSize, 14);
    });

    testWidgets(
        'NEVER returns fontFamily Roboto for any profile × style combination',
        (tester) async {
      // Test list item 22 — back-compat blast-shield.
      for (final profile in EdenThemeProfile.values) {
        for (final style in [
          EdenProfileFonts.bodyTextStyle(profile),
          EdenProfileFonts.displayTextStyle(profile),
          EdenProfileFonts.monoTextStyle(profile),
        ]) {
          // 'Roboto' is the Material default fallback that we must never see.
          // The GoogleFonts test-env suffix means we check for a Roboto prefix.
          expect(style.fontFamily, isNot(startsWith('Roboto')),
              reason:
                  '$profile produced Roboto fallback — back-compat broken');
          expect(style.fontFamily, isNotNull,
              reason: '$profile produced null fontFamily');
        }
      }
    });
  });
}
