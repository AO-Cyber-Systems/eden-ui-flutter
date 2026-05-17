// test/theme/eden_theme_status_palette_attach_test.dart
//
// Verifies EdenTheme.light/dark accept an optional profile param and attach
// the corresponding EdenStatusPalette ThemeExtension. Covers back-compat:
// today's no-args call site continues to work.
//
// Implementation note: tests use `testWidgets` (not plain `test`) because
// EdenTheme.{light,dark} construct TextStyles via GoogleFonts, which require
// the TestWidgetsFlutterBinding to be initialized (asset loader hooked) and
// runtime font-fetching disabled (no network in test env). Both are wired by
// `testWidgets` automatically. See existing test/widgets/support_panel_test.dart
// which also calls EdenTheme.dark() from within testWidgets.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EdenTheme.light status palette attach', () {
    testWidgets('no-args call attaches commercial palette (back-compat)',
        (tester) async {
      // Test list items 19 + 20.
      final theme = EdenTheme.light();
      final palette = theme.extension<EdenStatusPalette>();
      expect(palette, isNotNull,
          reason: 'EdenStatusPalette MUST be attached even with no args');
      final commercial = EdenStatusPalette.commercial();
      expect(palette!.successFg.value, commercial.successFg.value);
      expect(palette.dangerFg.value, commercial.dangerFg.value);
    });

    testWidgets('profile arg attaches correct palette (govFederal)',
        (tester) async {
      // Test list item 21.
      final theme = EdenTheme.light(profile: EdenThemeProfile.govFederal);
      final palette = theme.extension<EdenStatusPalette>();
      expect(palette, isNotNull);
      expect(palette!.successFg, const Color(0xFF00A91C),
          reason: 'gov palette successFg = USWDS green');
      expect(palette.dangerFg, const Color(0xFFB50909));
    });

    testWidgets('existing brand-only call site still works', (tester) async {
      // Test list item 22.
      final theme = EdenTheme.light(brand: EdenColors.blue);
      final palette = theme.extension<EdenStatusPalette>();
      expect(palette, isNotNull);
      final commercial = EdenStatusPalette.commercial();
      expect(palette!.successFg.value, commercial.successFg.value);
      expect(theme.colorScheme.primary, EdenColors.blue);
    });

    testWidgets('profile + brand combined', (tester) async {
      final theme = EdenTheme.light(
        profile: EdenThemeProfile.medicalInstitutional,
        brand: EdenColors.cyan,
      );
      final palette = theme.extension<EdenStatusPalette>();
      expect(palette, isNotNull);
      expect(palette!.dangerBorder.alpha, 0x66);
      expect(theme.colorScheme.primary, EdenColors.cyan);
    });
  });

  group('EdenTheme.dark status palette attach', () {
    testWidgets('no-args dark call attaches commercial palette',
        (tester) async {
      // Test list item 23.
      final theme = EdenTheme.dark();
      final palette = theme.extension<EdenStatusPalette>();
      expect(palette, isNotNull,
          reason: 'Dark theme also receives the extension');
      final commercial = EdenStatusPalette.commercial();
      expect(palette!.successFg.value, commercial.successFg.value,
          reason:
              'v1: no per-profile dark tuning (Out-of-Scope per OBJECTIVE.md)');
    });

    testWidgets('govFederal profile attaches USWDS palette in dark mode too',
        (tester) async {
      final theme = EdenTheme.dark(profile: EdenThemeProfile.govFederal);
      final palette = theme.extension<EdenStatusPalette>();
      expect(palette, isNotNull);
      expect(palette!.dangerFg, const Color(0xFFB50909));
    });
  });

  group('Full library regression sanity (Constraint 1)', () {
    testWidgets(
        'EdenTheme.light() returns a usable ThemeData with all existing fields',
        (tester) async {
      // Test list item 24.
      final theme = EdenTheme.light();
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, EdenColors.gold);
      expect(theme.brightness, Brightness.light);
      expect(theme.cardTheme, isNotNull);
      expect(theme.appBarTheme, isNotNull);
      expect(theme.textTheme.bodyMedium, isNotNull);
    });

    testWidgets('EdenTheme.dark() preserves dark-mode contrast tunings',
        (tester) async {
      final theme = EdenTheme.dark();
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.surface, EdenColors.neutral[900]);
      expect(theme.colorScheme.surfaceContainerHighest,
          EdenColors.neutral[800]);
    });
  });
}
