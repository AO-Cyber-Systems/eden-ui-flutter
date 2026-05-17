// test/theme/eden_adaptive_theme_test.dart
//
// EdenAdaptiveTheme composition wrapper + static factory contract tests
// (objective 009 TRD 05).

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // GoogleFonts in the test env stores fontFamily as PascalCase-no-spaces +
  // a weight suffix ('Plus Jakarta Sans' → 'PlusJakartaSans_regular').
  // Use startsWith on the PascalCase form. Same matcher pattern as TRD 009-04.
  Matcher hasFontFamilyPrefix(String googleFontsFamily) {
    final pascal = googleFontsFamily.replaceAll(' ', '');
    return predicate<String?>(
      (value) => value != null && value.startsWith(pascal),
      'fontFamily starting with "$pascal" (canonical family: "$googleFontsFamily")',
    );
  }

  group('EdenAdaptiveTheme widget — in-tree composition', () {
    testWidgets('descendants can resolve EdenThemeProfileScope.of',
        (tester) async {
      // Test list item 6.
      EdenThemeProfile? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: EdenAdaptiveTheme(
            profile: EdenThemeProfile.medicalInstitutional,
            child: Builder(builder: (context) {
              captured = EdenThemeProfileScope.of(context);
              return const SizedBox.shrink();
            }),
          ),
        ),
      );
      expect(captured, EdenThemeProfile.medicalInstitutional);
    });

    testWidgets('descendants resolve Theme.of(...).colorScheme.primary from profile',
        (tester) async {
      // Test list item 7.
      Color? capturedPrimary;
      await tester.pumpWidget(
        MaterialApp(
          home: EdenAdaptiveTheme(
            profile: EdenThemeProfile.govFederal,
            child: Builder(builder: (context) {
              capturedPrimary = Theme.of(context).colorScheme.primary;
              return const SizedBox.shrink();
            }),
          ),
        ),
      );
      expect(capturedPrimary, EdenColors.blue);
    });

    testWidgets('different profiles yield different colorScheme.primary',
        (tester) async {
      // Test list item 8.
      final captures = <Color>[];
      Future<void> pumpWith(EdenThemeProfile profile) async {
        await tester.pumpWidget(
          MaterialApp(
            home: EdenAdaptiveTheme(
              profile: profile,
              child: Builder(builder: (context) {
                captures.add(Theme.of(context).colorScheme.primary);
                return const SizedBox.shrink();
              }),
            ),
          ),
        );
      }

      await pumpWith(EdenThemeProfile.commercialWarm);
      await pumpWith(EdenThemeProfile.medicalInstitutional);
      expect(captures, hasLength(2));
      expect(captures[0], isNot(captures[1]),
          reason: 'Commercial gold vs Medical cyan must differ');
    });
  });

  group('EdenAdaptiveTheme.light static factory', () {
    testWidgets('commercialWarm has gold primary', (tester) async {
      // Test list item 9.
      final theme = EdenAdaptiveTheme.light(EdenThemeProfile.commercialWarm);
      expect(theme.colorScheme.primary, EdenColors.gold);
    });

    testWidgets('govFederal has blue (federal navy) primary', (tester) async {
      // Test list item 10.
      final theme = EdenAdaptiveTheme.light(EdenThemeProfile.govFederal);
      expect(theme.colorScheme.primary, EdenColors.blue);
    });

    testWidgets('brand preset overrides primary', (tester) async {
      // Test list item 11.
      final theme = EdenAdaptiveTheme.light(
        EdenThemeProfile.medicalInstitutional,
        brand: EdenBrandPresetRegistry.byId('medical-teal'),
      );
      // medical-teal wraps EdenColors.cyan.
      expect(theme.colorScheme.primary, EdenColors.cyan);
    });

    testWidgets('dark factory returns Brightness.dark theme', (tester) async {
      // Test list item 12.
      final theme = EdenAdaptiveTheme.dark(EdenThemeProfile.commercialWarm);
      expect(theme.brightness, Brightness.dark);
    });
  });

  group('Profile-aware TextTheme overlay', () {
    testWidgets('commercialWarm body uses Plus Jakarta Sans (no overlay)',
        (tester) async {
      // Test list item 13.
      final theme = EdenAdaptiveTheme.light(EdenThemeProfile.commercialWarm);
      expect(theme.textTheme.bodyLarge?.fontFamily,
          hasFontFamilyPrefix('Plus Jakarta Sans'));
    });

    testWidgets('medicalInstitutional body uses IBM Plex Sans (overlay)',
        (tester) async {
      // Test list item 14.
      final theme =
          EdenAdaptiveTheme.light(EdenThemeProfile.medicalInstitutional);
      expect(theme.textTheme.bodyLarge?.fontFamily,
          hasFontFamilyPrefix('IBM Plex Sans'));
    });

    testWidgets(
        'medicalInstitutional display keeps Outfit (display null in profile data)',
        (tester) async {
      // Test list item 15.
      final theme =
          EdenAdaptiveTheme.light(EdenThemeProfile.medicalInstitutional);
      expect(theme.textTheme.displayLarge?.fontFamily,
          hasFontFamilyPrefix('Outfit'));
    });

    testWidgets('govFederal body uses Public Sans', (tester) async {
      // Test list item 16.
      final theme = EdenAdaptiveTheme.light(EdenThemeProfile.govFederal);
      expect(theme.textTheme.bodyLarge?.fontFamily,
          hasFontFamilyPrefix('Public Sans'));
    });

    testWidgets('govFederal display uses Public Sans (body AND display)',
        (tester) async {
      // Test list item 17.
      final theme = EdenAdaptiveTheme.light(EdenThemeProfile.govFederal);
      expect(theme.textTheme.displayLarge?.fontFamily,
          hasFontFamilyPrefix('Public Sans'));
    });

    testWidgets('legalProfessional display uses Crimson Pro', (tester) async {
      // Test list item 18.
      final theme = EdenAdaptiveTheme.light(EdenThemeProfile.legalProfessional);
      expect(theme.textTheme.displayLarge?.fontFamily,
          hasFontFamilyPrefix('Crimson Pro'));
    });

    testWidgets('legalProfessional body keeps Plus Jakarta Sans',
        (tester) async {
      // Test list item 19.
      final theme = EdenAdaptiveTheme.light(EdenThemeProfile.legalProfessional);
      expect(theme.textTheme.bodyLarge?.fontFamily,
          hasFontFamilyPrefix('Plus Jakarta Sans'));
    });

    testWidgets('fontSize/fontWeight preserved through .merge overlay',
        (tester) async {
      // Test list item 22 — .merge doesn't drop base fontSize.
      final theme =
          EdenAdaptiveTheme.light(EdenThemeProfile.medicalInstitutional);
      expect(theme.textTheme.displayLarge?.fontSize, 48,
          reason:
              'Base TextTheme.displayLarge fontSize = 48; overlay must preserve');
      expect(theme.textTheme.displayLarge?.fontWeight, FontWeight.w800);
    });
  });

  group('EdenStatusPalette flows through composition', () {
    testWidgets('govFederal exposes USWDS successFg via extension',
        (tester) async {
      // Test list item 20.
      final theme = EdenAdaptiveTheme.light(EdenThemeProfile.govFederal);
      final palette = theme.extension<EdenStatusPalette>();
      expect(palette, isNotNull);
      expect(palette!.successFg, const Color(0xFF00A91C),
          reason: 'USWDS green flows through EdenAdaptiveTheme composition');
    });
  });

  group('Back-compat anchor (Constraint 1)', () {
    testWidgets(
        'commercialWarm matches EdenTheme.light() across all observable fields',
        (tester) async {
      // Test list item 21 — THE big one.
      final adaptive = EdenAdaptiveTheme.light(EdenThemeProfile.commercialWarm);
      final plain = EdenTheme.light();

      expect(adaptive.colorScheme.primary, plain.colorScheme.primary,
          reason: 'commercialWarm primary must match EdenTheme.light()');
      expect(adaptive.textTheme.bodyLarge?.fontFamily,
          plain.textTheme.bodyLarge?.fontFamily,
          reason: 'Body font family parity');
      expect(adaptive.textTheme.displayLarge?.fontFamily,
          plain.textTheme.displayLarge?.fontFamily,
          reason: 'Display font family parity');
      final adaptivePalette = adaptive.extension<EdenStatusPalette>();
      final plainPalette = plain.extension<EdenStatusPalette>();
      expect(adaptivePalette, isNotNull);
      expect(plainPalette, isNotNull);
      expect(adaptivePalette!.successFg.value, plainPalette!.successFg.value);
    });

    testWidgets('commercialWarm fontSize parity — base TextTheme preserved',
        (tester) async {
      final adaptive = EdenAdaptiveTheme.light(EdenThemeProfile.commercialWarm);
      final plain = EdenTheme.light();
      expect(adaptive.textTheme.displayLarge?.fontSize,
          plain.textTheme.displayLarge?.fontSize);
      expect(adaptive.textTheme.bodyMedium?.fontSize,
          plain.textTheme.bodyMedium?.fontSize);
    });
  });
}
