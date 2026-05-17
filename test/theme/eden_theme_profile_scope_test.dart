// test/theme/eden_theme_profile_scope_test.dart
//
// EdenThemeProfileScope InheritedWidget contract tests (objective 009 TRD 01).

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/profile_fixtures.dart';

void main() {
  group('EdenThemeProfileScope.maybeOf', () {
    testWidgets('returns null when no scope ancestor exists', (tester) async {
      // Test list item 2.
      EdenThemeProfile? captured =
          EdenThemeProfile.commercialWarm; // non-null sentinel
      await tester.pumpWidget(
        ProfileFixtures.wrap(
          ProfileFixtures.captureBuilder((p) => captured = p),
        ),
      );
      expect(captured, isNull,
          reason:
              'maybeOf must return null when no scope is in the ancestor chain');
    });

    testWidgets('returns the wrapped profile when scope ancestor exists',
        (tester) async {
      // Test list item 3.
      EdenThemeProfile? captured;
      await tester.pumpWidget(
        ProfileFixtures.wrapWithProfile(
          EdenThemeProfile.medicalInstitutional,
          ProfileFixtures.captureBuilder((p) => captured = p),
        ),
      );
      expect(captured, EdenThemeProfile.medicalInstitutional);
    });
  });

  group('EdenThemeProfileScope.of', () {
    testWidgets('returns the wrapped profile when scope is present',
        (tester) async {
      // Test list item 4.
      EdenThemeProfile? captured;
      await tester.pumpWidget(
        ProfileFixtures.wrapWithProfile(
          EdenThemeProfile.govFederal,
          Builder(builder: (context) {
            captured = EdenThemeProfileScope.of(context);
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(captured, EdenThemeProfile.govFederal);
    });

    testWidgets('asserts in debug when no scope is present', (tester) async {
      // Test list item 5 — assert-in-debug branch.
      await tester.pumpWidget(
        ProfileFixtures.wrap(
          Builder(builder: (context) {
            // In debug, this should throw AssertionError.
            expect(() => EdenThemeProfileScope.of(context),
                throwsAssertionError);
            return const SizedBox.shrink();
          }),
        ),
      );
    });
  });

  group('EdenThemeProfileScope rebuild behavior', () {
    testWidgets('descendants rebuild when wrapped profile changes',
        (tester) async {
      // Test list item 6 — updateShouldNotify true on profile change.
      final captures = <EdenThemeProfile?>[];
      Widget app(EdenThemeProfile profile) => MaterialApp(
            home: Scaffold(
              body: EdenThemeProfileScope(
                profile: profile,
                child: ProfileFixtures.captureBuilder((p) => captures.add(p)),
              ),
            ),
          );

      await tester.pumpWidget(app(EdenThemeProfile.commercialWarm));
      expect(captures.last, EdenThemeProfile.commercialWarm);

      await tester.pumpWidget(app(EdenThemeProfile.medicalInstitutional));
      expect(captures.last, EdenThemeProfile.medicalInstitutional,
          reason: 'Descendant must rebuild when profile changes');
    });

    testWidgets('updateShouldNotify true on diff, false on same', (tester) async {
      // Test list item 6 (direct check on updateShouldNotify).
      const a = EdenThemeProfileScope(
        profile: EdenThemeProfile.commercialWarm,
        child: SizedBox.shrink(),
      );
      const b = EdenThemeProfileScope(
        profile: EdenThemeProfile.commercialWarm,
        child: SizedBox.shrink(),
      );
      expect(a.updateShouldNotify(b), isFalse,
          reason: 'Same profile must NOT notify');
      const c = EdenThemeProfileScope(
        profile: EdenThemeProfile.medicalInstitutional,
        child: SizedBox.shrink(),
      );
      expect(a.updateShouldNotify(c), isTrue,
          reason: 'Different profile must notify');
    });
  });
}
