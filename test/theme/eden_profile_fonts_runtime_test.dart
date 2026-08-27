// test/theme/eden_profile_fonts_runtime_test.dart
//
// EdenProfileFonts runtime-family contract tests (objective 022 TRD 04).
// Test list per 022-04-TRD.md ## Test list section (items 1-20, four groups).
//
// Covers the three additive `*ForFamily` methods (bodyTextStyleForFamily /
// displayTextStyleForFamily / monoTextStyleForFamily) plus a byte-identity
// proof that the existing enum-taking methods are unchanged and routed
// through the same guarded resolver.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Matches a GoogleFonts-resolved [TextStyle.fontFamily] against its
/// canonical human name, tolerant of the weight/style suffix GoogleFonts
/// appends (e.g. 'Plus Jakarta Sans' -> 'PlusJakartaSans_regular').
/// Same pattern as objective 009's `hasFontFamilyPrefix` helper.
Matcher hasFontFamilyPrefix(String googleFontsFamily) {
  final pascal = googleFontsFamily.replaceAll(' ', '');
  return predicate<String?>(
    (value) => value != null && value.startsWith(pascal),
    'has fontFamily starting with "$pascal"',
  );
}

/// Malformed / unresolvable family names exercised throughout the
/// "unknown family falls back" group. Inline per TRD `fixture_strategy:
/// inline` — no separate fixture file.
const List<String?> kMalformedFamilies = <String?>[
  'Definitely Not A Real Font 9000',
  'Nope Nope 9000',
  'Intr',
  '',
  '   ',
  null,
];

void main() {
  group('profile path unchanged', () {
    // Test list 1: commercialWarm body unchanged (Plus Jakarta Sans fallback).
    testWidgets('bodyTextStyle(commercialWarm).fontFamily is unchanged',
        (tester) async {
      final style =
          EdenProfileFonts.bodyTextStyle(EdenThemeProfile.commercialWarm);
      expect(style.fontFamily, hasFontFamilyPrefix('Plus Jakarta Sans'));
    });

    // Test list 2: medicalInstitutional body still resolves IBM Plex Sans.
    testWidgets('bodyTextStyle(medicalInstitutional) still resolves IBM Plex Sans',
        (tester) async {
      final style = EdenProfileFonts.bodyTextStyle(
          EdenThemeProfile.medicalInstitutional);
      expect(style.fontFamily, hasFontFamilyPrefix('IBM Plex Sans'));
    });

    // Test list 3: govFederal body + display still resolve Public Sans.
    testWidgets('bodyTextStyle(govFederal) and displayTextStyle(govFederal) still resolve Public Sans',
        (tester) async {
      final body =
          EdenProfileFonts.bodyTextStyle(EdenThemeProfile.govFederal);
      final display =
          EdenProfileFonts.displayTextStyle(EdenThemeProfile.govFederal);
      expect(body.fontFamily, hasFontFamilyPrefix('Public Sans'));
      expect(display.fontFamily, hasFontFamilyPrefix('Public Sans'));
    });

    // Test list 4: legalProfessional display still resolves Crimson Pro.
    testWidgets('displayTextStyle(legalProfessional) still resolves Crimson Pro',
        (tester) async {
      final style = EdenProfileFonts.displayTextStyle(
          EdenThemeProfile.legalProfessional);
      expect(style.fontFamily, hasFontFamilyPrefix('Crimson Pro'));
    });

    // Test list 5: monoTextStyle for all five profiles still resolves JetBrains Mono.
    testWidgets('monoTextStyle for all five profiles still resolves JetBrains Mono',
        (tester) async {
      for (final profile in EdenThemeProfile.values) {
        final style = EdenProfileFonts.monoTextStyle(profile);
        expect(style.fontFamily, hasFontFamilyPrefix('JetBrains Mono'),
            reason: 'profile=$profile');
      }
    });

    // Test list 6: fontFamily never contains 'Roboto', for all profiles x roles.
    testWidgets('fontFamily never contains Roboto, for all profiles x roles',
        (tester) async {
      for (final profile in EdenThemeProfile.values) {
        final body = EdenProfileFonts.bodyTextStyle(profile);
        final display = EdenProfileFonts.displayTextStyle(profile);
        final mono = EdenProfileFonts.monoTextStyle(profile);
        for (final style in [body, display, mono]) {
          expect(style.fontFamily, isNotNull, reason: 'profile=$profile');
          expect(style.fontFamily, isNot(contains('Roboto')),
              reason: 'profile=$profile');
        }
      }
    });

    // Test list 7: fontSize/fontWeight/height/color are carried onto the
    // returned style, for both the known-family and fallback branches.
    testWidgets('fontSize/fontWeight/height/color pass through for known and fallback families',
        (tester) async {
      // Fallback branch: commercialWarm body family is null.
      final fallbackStyle = EdenProfileFonts.bodyTextStyle(
        EdenThemeProfile.commercialWarm,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: Colors.deepPurple,
      );
      expect(fallbackStyle.fontSize, 18);
      expect(fallbackStyle.fontWeight, FontWeight.w600);
      expect(fallbackStyle.height, 1.4);
      expect(fallbackStyle.color, Colors.deepPurple);

      // Known-family branch: medicalInstitutional body family is IBM Plex Sans.
      final knownStyle = EdenProfileFonts.bodyTextStyle(
        EdenThemeProfile.medicalInstitutional,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: Colors.teal,
      );
      expect(knownStyle.fontSize, 20);
      expect(knownStyle.fontWeight, FontWeight.w700);
      expect(knownStyle.height, 1.2);
      expect(knownStyle.color, Colors.teal);
    });
  });

  group('runtime family resolves', () {
    // Test list 8: bodyTextStyleForFamily('Inter').fontFamily == 'Inter_regular'.
    testWidgets("bodyTextStyleForFamily('Inter').fontFamily == 'Inter_regular'",
        (tester) async {
      final style = EdenProfileFonts.bodyTextStyleForFamily('Inter');
      expect(style.fontFamily, 'Inter_regular');
    });

    // Test list 9: displayTextStyleForFamily and monoTextStyleForFamily also resolve Inter.
    testWidgets('displayTextStyleForFamily and monoTextStyleForFamily also resolve Inter',
        (tester) async {
      final display = EdenProfileFonts.displayTextStyleForFamily('Inter');
      final mono = EdenProfileFonts.monoTextStyleForFamily('Inter');
      expect(display.fontFamily, 'Inter_regular');
      expect(mono.fontFamily, 'Inter_regular');
    });

    // Test list 10: bodyTextStyleForFamily('IBM Plex Sans') matches
    // bodyTextStyle(medicalInstitutional) -- one code path, not two.
    testWidgets("bodyTextStyleForFamily('IBM Plex Sans') matches bodyTextStyle(medicalInstitutional)",
        (tester) async {
      final viaFamily =
          EdenProfileFonts.bodyTextStyleForFamily('IBM Plex Sans');
      final viaProfile = EdenProfileFonts.bodyTextStyle(
          EdenThemeProfile.medicalInstitutional);
      expect(viaFamily.fontFamily, viaProfile.fontFamily);
      expect(viaFamily.fontFamily, 'IBMPlexSans_regular');
    });
  });

  group('unknown family falls back', () {
    // Test list 11: bodyTextStyleForFamily('Definitely Not A Real Font 9000')
    // returns normally and yields the Plus Jakarta Sans fallback.
    testWidgets("bodyTextStyleForFamily('Definitely Not A Real Font 9000') falls back to Plus Jakarta Sans",
        (tester) async {
      late TextStyle style;
      expect(() {
        style = EdenProfileFonts.bodyTextStyleForFamily(
            'Definitely Not A Real Font 9000');
      }, returnsNormally);
      expect(style.fontFamily, hasFontFamilyPrefix('Plus Jakarta Sans'));
    });

    // Test list 12: displayTextStyleForFamily('Nope Nope 9000') falls back to Outfit.
    testWidgets("displayTextStyleForFamily('Nope Nope 9000') falls back to Outfit",
        (tester) async {
      final style =
          EdenProfileFonts.displayTextStyleForFamily('Nope Nope 9000');
      expect(style.fontFamily, hasFontFamilyPrefix('Outfit'));
    });

    // Test list 13: monoTextStyleForFamily('Nope Nope 9000') falls back to JetBrains Mono.
    testWidgets("monoTextStyleForFamily('Nope Nope 9000') falls back to JetBrains Mono",
        (tester) async {
      final style =
          EdenProfileFonts.monoTextStyleForFamily('Nope Nope 9000');
      expect(style.fontFamily, hasFontFamilyPrefix('JetBrains Mono'));
    });

    // Test list 14: null, '' and '   ' each fall back to Plus Jakarta Sans
    // without throwing.
    testWidgets("bodyTextStyleForFamily(null), ('') and ('   ') each fall back without throwing",
        (tester) async {
      for (final family in <String?>[null, '', '   ']) {
        late TextStyle style;
        expect(() {
          style = EdenProfileFonts.bodyTextStyleForFamily(family);
        }, returnsNormally, reason: 'family=$family');
        expect(style.fontFamily, hasFontFamilyPrefix('Plus Jakarta Sans'),
            reason: 'family=$family');
      }
    });

    // Test list 15: a fallback result's fontFamily never contains 'Roboto'.
    testWidgets('a fallback result never contains Roboto', (tester) async {
      for (final family in kMalformedFamilies) {
        final body = EdenProfileFonts.bodyTextStyleForFamily(family);
        final display = EdenProfileFonts.displayTextStyleForFamily(family);
        final mono = EdenProfileFonts.monoTextStyleForFamily(family);
        for (final style in [body, display, mono]) {
          expect(style.fontFamily, isNotNull, reason: 'family=$family');
          expect(style.fontFamily, isNot(contains('Roboto')),
              reason: 'family=$family');
        }
      }
    });

    // Test list 16: across every malformed family, returnsNormally holds
    // for all three roles.
    testWidgets('every malformed family returns normally for all three roles',
        (tester) async {
      for (final family in kMalformedFamilies) {
        expect(() => EdenProfileFonts.bodyTextStyleForFamily(family),
            returnsNormally,
            reason: 'body family=$family');
        expect(() => EdenProfileFonts.displayTextStyleForFamily(family),
            returnsNormally,
            reason: 'display family=$family');
        expect(() => EdenProfileFonts.monoTextStyleForFamily(family),
            returnsNormally,
            reason: 'mono family=$family');
      }
    });

    // Test list 17: fallback preserves the caller's fontSize/fontWeight/height/color.
    testWidgets('fallback preserves fontSize/fontWeight/height/color',
        (tester) async {
      final style = EdenProfileFonts.bodyTextStyleForFamily(
        'Definitely Not A Real Font 9000',
        fontSize: 22,
        fontWeight: FontWeight.w500,
        height: 1.6,
        color: Colors.orange,
      );
      expect(style.fontSize, 22);
      expect(style.fontWeight, FontWeight.w500);
      expect(style.height, 1.6);
      expect(style.color, Colors.orange);
    });

    // Test list 18: calling bodyTextStyleForFamily with the same unknown
    // family repeatedly returns the same fallback every time and does not
    // throw on any call.
    testWidgets('repeated calls with the same unknown family always return the same fallback',
        (tester) async {
      for (var i = 0; i < 5; i++) {
        late TextStyle style;
        expect(() {
          style = EdenProfileFonts.bodyTextStyleForFamily('Intr');
        }, returnsNormally, reason: 'call #$i');
        expect(style.fontFamily, hasFontFamilyPrefix('Plus Jakarta Sans'),
            reason: 'call #$i');
      }
    });
  });

  group('fallback log is deduped', () {
    // Test list 19: three consecutive calls with the same unknown family
    // emit EXACTLY ONE debug line naming the family.
    testWidgets('three consecutive calls with the same unknown family emit exactly one debug line',
        (tester) async {
      final captured = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) captured.add(message);
      };
      addTearDown(() => debugPrint = original);

      EdenProfileFonts.resetMissingFamilyLog();
      for (var i = 0; i < 3; i++) {
        EdenProfileFonts.bodyTextStyleForFamily('Nope Nope 9000');
      }
      expect(
        captured.where((m) => m.contains('Nope Nope 9000')).length,
        1,
        reason: 'EdenAdaptiveTheme.build() re-resolves fonts every frame; an '
            'undeduped log would spam a partner console once per frame.',
      );
    });

    // Test list 20: resetMissingFamilyLog() actually resets, and two
    // distinct families log separately (keyed per family, not one global
    // latch).
    testWidgets('resetMissingFamilyLog resets the dedupe, keyed per distinct family',
        (tester) async {
      final captured = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) captured.add(message);
      };
      addTearDown(() => debugPrint = original);

      EdenProfileFonts.resetMissingFamilyLog();
      EdenProfileFonts.bodyTextStyleForFamily('Nope Nope 9000');
      EdenProfileFonts.bodyTextStyleForFamily('Nope Nope 9000');
      expect(
        captured.where((m) => m.contains('Nope Nope 9000')).length,
        1,
      );

      EdenProfileFonts.resetMissingFamilyLog();
      EdenProfileFonts.bodyTextStyleForFamily('Nope Nope 9000');
      expect(
        captured.where((m) => m.contains('Nope Nope 9000')).length,
        2,
        reason: 'resetMissingFamilyLog() must clear the dedupe set so a '
            'second distinct fallback event logs again.',
      );

      // A second, distinct family must log on its own -- proving the
      // dedupe is keyed per family name, not a single global latch.
      EdenProfileFonts.bodyTextStyleForFamily('Intr');
      expect(
        captured.where((m) => m.contains('Intr')).length,
        1,
      );
    });
  });
}
