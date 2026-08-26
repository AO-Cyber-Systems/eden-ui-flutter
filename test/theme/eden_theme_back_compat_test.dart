// test/theme/eden_theme_back_compat_test.dart
//
// Back-compat spine for objective 022 (022-CONTEXT.md LOCKED decision 1).
//
// Asserts EdenTheme.light()/.dark() (no brand argument), EdenTheme.light(profile: P)
// for all 5 LOCKED profiles, and EdenAdaptiveTheme.light(P)/.dark(P) for all 5 LOCKED
// profiles against the RECORDED constants in
// test/theme/_fixtures/theme_back_compat_baseline.dart.
//
// This test is GREEN on first run by construction: the fixture was transcribed
// directly from this same production code's live output. A RED result here means the
// fixture transcription is wrong — fix the fixture, never "fix" it by editing
// production code. From TRD 022-02 onward, a RED result means a runtime-brand change
// leaked into the static (no-brand) path and must be fixed in lib/, not here.
//
// Every assertion below is per-key (map-keyed expectations), not a whole-object `==`
// or a digest/hash comparison — see 022-01-TRD.md <anti_patterns>. Each failure names
// the exact field that drifted.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/theme_back_compat_baseline.dart';

void main() {
  const profiles = <EdenThemeProfile>[
    EdenThemeProfile.commercialWarm,
    EdenThemeProfile.medicalInstitutional,
    EdenThemeProfile.govFederal,
    EdenThemeProfile.retailVibrant,
    EdenThemeProfile.legalProfessional,
  ];

  const colorSchemeRoleReaders = <String, Color Function(ColorScheme)>{
    'primary': _primary,
    'onPrimary': _onPrimary,
    'primaryContainer': _primaryContainer,
    'onPrimaryContainer': _onPrimaryContainer,
    'secondary': _secondary,
    'onSecondary': _onSecondary,
    'surface': _surface,
    'onSurface': _onSurface,
    'onSurfaceVariant': _onSurfaceVariant,
    'outline': _outline,
    'outlineVariant': _outlineVariant,
    'surfaceContainerLowest': _surfaceContainerLowest,
    'surfaceContainerLow': _surfaceContainerLow,
    'surfaceContainer': _surfaceContainer,
    'surfaceContainerHigh': _surfaceContainerHigh,
    'surfaceContainerHighest': _surfaceContainerHighest,
    'error': _error,
    'onError': _onError,
  };

  const textThemeRoleReaders = <String, TextStyle? Function(TextTheme)>{
    'displayLarge': _displayLarge,
    'displayMedium': _displayMedium,
    'displaySmall': _displaySmall,
    'headlineLarge': _headlineLarge,
    'headlineMedium': _headlineMedium,
    'headlineSmall': _headlineSmall,
    'titleLarge': _titleLarge,
    'titleMedium': _titleMedium,
    'titleSmall': _titleSmall,
    'bodyLarge': _bodyLarge,
    'bodyMedium': _bodyMedium,
    'bodySmall': _bodySmall,
    'labelLarge': _labelLarge,
    'labelMedium': _labelMedium,
    'labelSmall': _labelSmall,
  };

  const statusPaletteFieldReaders = <String, Color Function(EdenStatusPalette)>{
    'successBg': _successBg,
    'successFg': _successFg,
    'successBorder': _successBorder,
    'warningBg': _warningBg,
    'warningFg': _warningFg,
    'warningBorder': _warningBorder,
    'dangerBg': _dangerBg,
    'dangerFg': _dangerFg,
    'dangerBorder': _dangerBorder,
    'infoBg': _infoBg,
    'infoFg': _infoFg,
    'infoBorder': _infoBorder,
    'neutralBg': _neutralBg,
    'neutralFg': _neutralFg,
    'neutralBorder': _neutralBorder,
  };

  /// Asserts every 'role.property' entry in [expected] against [textTheme],
  /// naming the exact drifted role+property on failure.
  void expectTextThemeParity(
    TextTheme textTheme,
    Map<String, Object?> expected,
    String contextLabel,
  ) {
    for (final entry in expected.entries) {
      final parts = entry.key.split('.');
      final role = parts[0];
      final property = parts[1];
      final style = textThemeRoleReaders[role]!(textTheme);
      final Object? actual = switch (property) {
        'fontFamily' => style?.fontFamily,
        'fontSize' => style?.fontSize,
        'fontWeight' => style?.fontWeight?.index,
        'height' => style?.height,
        _ => throw StateError('Unknown TextTheme property: $property'),
      };
      expect(
        actual,
        entry.value,
        reason: '$contextLabel textTheme.$role.$property drifted from the '
            'recorded baseline',
      );
    }
  }

  group('EdenTheme.light() / .dark() colour parity (LOCKED decision 1)', () {
    testWidgets('light() ColorScheme matches the recorded baseline',
        (tester) async {
      final theme = EdenTheme.light();
      for (final entry in ThemeBackCompatBaseline.lightColorScheme.entries) {
        if (entry.key == 'scaffoldBackgroundColor') {
          expect(theme.scaffoldBackgroundColor.value, entry.value,
              reason: 'EdenTheme.light().scaffoldBackgroundColor drifted');
          continue;
        }
        final reader = colorSchemeRoleReaders[entry.key]!;
        expect(reader(theme.colorScheme).value, entry.value,
            reason: 'EdenTheme.light().colorScheme.${entry.key} drifted');
      }
      expect(theme.brightness.name, ThemeBackCompatBaseline.lightBrightness,
          reason: 'EdenTheme.light().brightness drifted');
    });

    testWidgets('dark() ColorScheme matches the recorded baseline',
        (tester) async {
      final theme = EdenTheme.dark();
      for (final entry in ThemeBackCompatBaseline.darkColorScheme.entries) {
        if (entry.key == 'scaffoldBackgroundColor') {
          expect(theme.scaffoldBackgroundColor.value, entry.value,
              reason: 'EdenTheme.dark().scaffoldBackgroundColor drifted');
          continue;
        }
        final reader = colorSchemeRoleReaders[entry.key]!;
        expect(reader(theme.colorScheme).value, entry.value,
            reason: 'EdenTheme.dark().colorScheme.${entry.key} drifted');
      }
      expect(theme.brightness.name, ThemeBackCompatBaseline.darkBrightness,
          reason: 'EdenTheme.dark().brightness drifted');
    });

    testWidgets(
        'EdenTheme.light(profile: P).colorScheme is identical across all '
        'profiles (profile feeds only the status palette — 022-CONTEXT finding 1)',
        (tester) async {
      final reference = EdenTheme.light();
      for (final profile in profiles) {
        final themed = EdenTheme.light(profile: profile);
        for (final role in colorSchemeRoleReaders.keys) {
          final reader = colorSchemeRoleReaders[role]!;
          expect(
            reader(themed.colorScheme).value,
            reader(reference.colorScheme).value,
            reason:
                'EdenTheme.light(profile: ${profile.name}).colorScheme.$role '
                'must equal the no-profile baseline',
          );
        }
      }
    });
  });

  group('TextTheme parity', () {
    testWidgets('light() TextTheme matches the recorded baseline',
        (tester) async {
      final theme = EdenTheme.light();
      expectTextThemeParity(theme.textTheme,
          ThemeBackCompatBaseline.lightTextTheme, 'EdenTheme.light()');
    });

    testWidgets('dark() TextTheme matches the recorded baseline',
        (tester) async {
      final theme = EdenTheme.dark();
      expectTextThemeParity(
          theme.textTheme, ThemeBackCompatBaseline.darkTextTheme, 'EdenTheme.dark()');
    });

    testWidgets(
        'EdenTheme.light(profile: P).textTheme is identical across all '
        'profiles (profile feeds only the status palette — 022-CONTEXT finding 1)',
        (tester) async {
      final reference = EdenTheme.light();
      for (final profile in profiles) {
        final themed = EdenTheme.light(profile: profile);
        for (final role in textThemeRoleReaders.keys) {
          final referenceStyle = textThemeRoleReaders[role]!(reference.textTheme);
          final themedStyle = textThemeRoleReaders[role]!(themed.textTheme);
          expect(themedStyle?.fontFamily, referenceStyle?.fontFamily,
              reason: 'EdenTheme.light(profile: ${profile.name}).textTheme.$role.'
                  'fontFamily must equal the no-profile baseline');
          expect(themedStyle?.fontSize, referenceStyle?.fontSize,
              reason: 'EdenTheme.light(profile: ${profile.name}).textTheme.$role.'
                  'fontSize must equal the no-profile baseline');
          expect(themedStyle?.fontWeight, referenceStyle?.fontWeight,
              reason: 'EdenTheme.light(profile: ${profile.name}).textTheme.$role.'
                  'fontWeight must equal the no-profile baseline');
          expect(themedStyle?.height, referenceStyle?.height,
              reason: 'EdenTheme.light(profile: ${profile.name}).textTheme.$role.'
                  'height must equal the no-profile baseline');
        }
      }
    });
  });

  group('Per-profile EdenStatusPalette parity', () {
    for (final profile in profiles) {
      testWidgets(
          'EdenTheme.light(profile: ${profile.name}) status palette matches '
          'the recorded baseline', (tester) async {
        final theme = EdenTheme.light(profile: profile);
        final palette = theme.extension<EdenStatusPalette>();
        expect(palette, isNotNull,
            reason: 'EdenTheme.light(profile: ${profile.name}) must carry an '
                'EdenStatusPalette extension');
        final expected =
            ThemeBackCompatBaseline.statusPaletteByProfile[profile.name]!;
        for (final entry in expected.entries) {
          final reader = statusPaletteFieldReaders[entry.key]!;
          expect(reader(palette!).value, entry.value,
              reason: 'EdenTheme.light(profile: ${profile.name}) '
                  'statusPalette.${entry.key} drifted');
        }
      });
    }
  });

  group('EdenAdaptiveTheme per-profile parity', () {
    for (final profile in profiles) {
      for (final brightnessLabel in <String>['light', 'dark']) {
        final isLight = brightnessLabel == 'light';

        testWidgets(
            'EdenAdaptiveTheme.${isLight ? 'light' : 'dark'}(${profile.name}) '
            'primary matches the recorded baseline', (tester) async {
          final theme = isLight
              ? EdenAdaptiveTheme.light(profile)
              : EdenAdaptiveTheme.dark(profile);
          final expected = ThemeBackCompatBaseline
              .adaptivePrimary['${profile.name}.$brightnessLabel']!;
          expect(theme.colorScheme.primary.value, expected,
              reason: 'EdenAdaptiveTheme.$brightnessLabel(${profile.name})'
                  '.colorScheme.primary drifted');
        });

        testWidgets(
            'EdenAdaptiveTheme.${isLight ? 'light' : 'dark'}(${profile.name}) '
            'TextTheme matches the recorded baseline (fontFamily, fontSize, '
            'fontWeight, height — not family-only, see gotcha on merge '
            'direction inversion)', (tester) async {
          final theme = isLight
              ? EdenAdaptiveTheme.light(profile)
              : EdenAdaptiveTheme.dark(profile);
          final prefix = '${profile.name}.$brightnessLabel.';
          final expected = <String, Object?>{
            for (final entry in ThemeBackCompatBaseline.adaptiveTextTheme.entries)
              if (entry.key.startsWith(prefix))
                entry.key.substring(prefix.length): entry.value,
          };
          expect(expected, isNotEmpty,
              reason: 'No recorded adaptiveTextTheme entries for prefix $prefix');
          expectTextThemeParity(theme.textTheme, expected,
              'EdenAdaptiveTheme.$brightnessLabel(${profile.name})');
        });
      }
    }
  });
}

// ColorScheme role readers — top-level so they can populate a const Map.
Color _primary(ColorScheme c) => c.primary;
Color _onPrimary(ColorScheme c) => c.onPrimary;
Color _primaryContainer(ColorScheme c) => c.primaryContainer;
Color _onPrimaryContainer(ColorScheme c) => c.onPrimaryContainer;
Color _secondary(ColorScheme c) => c.secondary;
Color _onSecondary(ColorScheme c) => c.onSecondary;
Color _surface(ColorScheme c) => c.surface;
Color _onSurface(ColorScheme c) => c.onSurface;
Color _onSurfaceVariant(ColorScheme c) => c.onSurfaceVariant;
Color _outline(ColorScheme c) => c.outline;
Color _outlineVariant(ColorScheme c) => c.outlineVariant;
Color _surfaceContainerLowest(ColorScheme c) => c.surfaceContainerLowest;
Color _surfaceContainerLow(ColorScheme c) => c.surfaceContainerLow;
Color _surfaceContainer(ColorScheme c) => c.surfaceContainer;
Color _surfaceContainerHigh(ColorScheme c) => c.surfaceContainerHigh;
Color _surfaceContainerHighest(ColorScheme c) => c.surfaceContainerHighest;
Color _error(ColorScheme c) => c.error;
Color _onError(ColorScheme c) => c.onError;

// TextTheme role readers.
TextStyle? _displayLarge(TextTheme t) => t.displayLarge;
TextStyle? _displayMedium(TextTheme t) => t.displayMedium;
TextStyle? _displaySmall(TextTheme t) => t.displaySmall;
TextStyle? _headlineLarge(TextTheme t) => t.headlineLarge;
TextStyle? _headlineMedium(TextTheme t) => t.headlineMedium;
TextStyle? _headlineSmall(TextTheme t) => t.headlineSmall;
TextStyle? _titleLarge(TextTheme t) => t.titleLarge;
TextStyle? _titleMedium(TextTheme t) => t.titleMedium;
TextStyle? _titleSmall(TextTheme t) => t.titleSmall;
TextStyle? _bodyLarge(TextTheme t) => t.bodyLarge;
TextStyle? _bodyMedium(TextTheme t) => t.bodyMedium;
TextStyle? _bodySmall(TextTheme t) => t.bodySmall;
TextStyle? _labelLarge(TextTheme t) => t.labelLarge;
TextStyle? _labelMedium(TextTheme t) => t.labelMedium;
TextStyle? _labelSmall(TextTheme t) => t.labelSmall;

// EdenStatusPalette field readers.
Color _successBg(EdenStatusPalette p) => p.successBg;
Color _successFg(EdenStatusPalette p) => p.successFg;
Color _successBorder(EdenStatusPalette p) => p.successBorder;
Color _warningBg(EdenStatusPalette p) => p.warningBg;
Color _warningFg(EdenStatusPalette p) => p.warningFg;
Color _warningBorder(EdenStatusPalette p) => p.warningBorder;
Color _dangerBg(EdenStatusPalette p) => p.dangerBg;
Color _dangerFg(EdenStatusPalette p) => p.dangerFg;
Color _dangerBorder(EdenStatusPalette p) => p.dangerBorder;
Color _infoBg(EdenStatusPalette p) => p.infoBg;
Color _infoFg(EdenStatusPalette p) => p.infoFg;
Color _infoBorder(EdenStatusPalette p) => p.infoBorder;
Color _neutralBg(EdenStatusPalette p) => p.neutralBg;
Color _neutralFg(EdenStatusPalette p) => p.neutralFg;
Color _neutralBorder(EdenStatusPalette p) => p.neutralBorder;
