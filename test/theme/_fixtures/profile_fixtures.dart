// test/theme/_fixtures/profile_fixtures.dart
//
// Hand-built test fixtures for EdenThemeProfile work (objective 009).
// Do NOT regenerate via LLM — mutate in-place when the profile contract changes.
// Per global TDD Playbook habit 4 + resolver no_llm_test_data constraint.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

class ProfileFixtures {
  ProfileFixtures._();

  /// Every profile in the LOCKED order from OBJECTIVE.md Constraint 11.
  /// If this list drifts from the enum definition, the contract has been broken.
  static const List<EdenThemeProfile> allProfilesInLockedOrder = [
    EdenThemeProfile.commercialWarm,
    EdenThemeProfile.medicalInstitutional,
    EdenThemeProfile.govFederal,
    EdenThemeProfile.retailVibrant,
    EdenThemeProfile.legalProfessional,
  ];

  /// Minimal MaterialApp wrapper for InheritedWidget tests.
  /// Mirror of the lib's standard `wrap()` test pattern (PROJECT.md test pattern).
  static Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: child));

  /// Wrapper with an EdenThemeProfileScope ancestor.
  static Widget wrapWithProfile(EdenThemeProfile profile, Widget child) =>
      MaterialApp(
        home: Scaffold(
          body: EdenThemeProfileScope(
            profile: profile,
            child: child,
          ),
        ),
      );

  /// A descendant widget that records the resolved profile from `.maybeOf`
  /// into a capture variable. Use:
  ///   EdenThemeProfile? captured;
  ///   await tester.pumpWidget(wrapWithProfile(
  ///     EdenThemeProfile.medicalInstitutional,
  ///     ProfileFixtures.captureBuilder((p) => captured = p),
  ///   ));
  ///   expect(captured, EdenThemeProfile.medicalInstitutional);
  static Widget captureBuilder(void Function(EdenThemeProfile?) onBuild) {
    return Builder(
      builder: (context) {
        onBuild(EdenThemeProfileScope.maybeOf(context));
        return const SizedBox.shrink();
      },
    );
  }
}
