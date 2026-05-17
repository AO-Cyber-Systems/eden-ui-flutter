// TDD test file for EdenInsuranceCard (obj 017-02).

import 'package:eden_ui_flutter/src/theme/eden_theme.dart';
import 'package:eden_ui_flutter/src/theme/eden_theme_profile.dart';
import 'package:eden_ui_flutter/src/widgets/eden_alert.dart';
import 'package:eden_ui_flutter/src/widgets/eden_authenticated_image.dart';
import 'package:eden_ui_flutter/src/widgets/eden_insurance_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_insurance_card_fixtures.dart';

void main() {
  Widget wrap(Widget child, {double width = 600, double height = 800}) {
    final theme = EdenTheme.light(profile: EdenThemeProfile.medicalInstitutional);
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: SizedBox(width: width, height: height, child: child),
          ),
        ),
      ),
    );
  }

  group('EdenInsuranceCard — image composition (case 1)', () {
    testWidgets('front + back render via EdenAuthenticatedImage when both URLs '
        'are non-null', (tester) async {
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: InsuranceCardFixtures.primaryAetnaPpoActive(),
      )));
      // Pump only one frame so EdenAuthenticatedImage doesn't reach network.
      expect(find.byType(EdenAuthenticatedImage), findsNWidgets(2));
    });

    testWidgets('Medicare single-sided: 1 EdenAuthenticatedImage + 1 '
        'placeholder', (tester) async {
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: InsuranceCardFixtures.medicareTraditional(),
      )));
      expect(find.byType(EdenAuthenticatedImage), findsOneWidget);
      expect(find.text('Back image not available'), findsOneWidget);
    });
  });

  group('EdenInsuranceCard — extracted fields grid (case 2)', () {
    testWidgets('renders planName, payerId, memberId, group, subscriber, '
        'priority', (tester) async {
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: InsuranceCardFixtures.primaryAetnaPpoActive(),
      )));
      expect(find.textContaining('Aetna Choice POS II'), findsWidgets);
      expect(find.textContaining('60054'), findsWidgets);
      expect(find.textContaining('W123456789'), findsWidgets);
      expect(find.textContaining('12345-ABC'), findsWidgets);
      expect(find.textContaining('Alex Alpha'), findsWidgets);
      expect(find.textContaining('Self'), findsWidgets);
    });

    testWidgets('null groupNumber renders em-dash placeholder',
        (tester) async {
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: InsuranceCardFixtures.medicareTraditional(),
      )));
      // Medicare fixture has no groupNumber → "—" placeholder.
      expect(find.text('—'), findsOneWidget);
    });
  });

  group('EdenInsuranceCard — planType badge (case 3 + 7)', () {
    testWidgets('PPO label for planType=ppo', (tester) async {
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: InsuranceCardFixtures.primaryAetnaPpoActive(),
      )));
      expect(find.text('PPO'), findsOneWidget);
    });

    testWidgets('HDHP label for planType=hdhp', (tester) async {
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: InsuranceCardFixtures.secondaryBcbsHdhpActive(),
      )));
      expect(find.text('HDHP'), findsOneWidget);
    });

    testWidgets('Medicare label for planType=medicare', (tester) async {
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: InsuranceCardFixtures.medicareTraditional(),
      )));
      expect(find.text('Medicare'), findsOneWidget);
    });

    testWidgets('customPlanTypeLabel override when planType=other',
        (tester) async {
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: InsuranceCardFixtures.crossVerticalDriverLicense(),
      )));
      expect(find.text('Driver License — CDL Class A'), findsOneWidget);
      // The default 'Other' text MUST NOT be rendered when the override is set.
      expect(find.text('Other'), findsNothing);
    });
  });

  group('EdenInsuranceCard — priorityRank badge (case 4)', () {
    testWidgets('primary renders "Primary" pill', (tester) async {
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: InsuranceCardFixtures.primaryAetnaPpoActive(),
      )));
      expect(find.text('Primary'), findsOneWidget);
    });

    testWidgets('secondary renders "Secondary" pill', (tester) async {
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: InsuranceCardFixtures.secondaryBcbsHdhpActive(),
      )));
      expect(find.text('Secondary'), findsOneWidget);
    });

    testWidgets('tertiary renders "Tertiary" pill', (tester) async {
      const tertiary = EdenInsurancePolicy(
        id: 'p-3',
        patientId: 'patient-tertiary',
        planName: 'Tertiary Plan',
        planType: EdenInsurancePlanType.ppo,
        payerId: '999',
        memberId: 'T999',
        priorityRank: EdenInsurancePriority.tertiary,
      );
      await tester.pumpWidget(wrap(const EdenInsuranceCard(policy: tertiary)));
      expect(find.text('Tertiary'), findsOneWidget);
    });
  });

  group('EdenInsuranceCard — verified-at + not-verified (cases 5+6)', () {
    testWidgets('"Verified {date}" when verifiedAt non-null', (tester) async {
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: InsuranceCardFixtures.primaryAetnaPpoActive(),
      )));
      expect(find.text('Verified 2026-05-17'), findsOneWidget);
    });

    testWidgets('"Not verified" warning chip when verifiedAt is null',
        (tester) async {
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: InsuranceCardFixtures.secondaryBcbsHdhpActive(),
      )));
      expect(find.text('Not verified'), findsOneWidget);
    });
  });

  group('EdenInsuranceCard — layout responsive (cases 8+9+10)', () {
    testWidgets('layout=stacked at 390pt: Column structure', (tester) async {
      await tester.pumpWidget(wrap(
        EdenInsuranceCard(
          policy: InsuranceCardFixtures.primaryAetnaPpoActive(),
        ),
        width: 390,
        height: 1000,
      ));
      // In stacked mode, front + back images should be in a Column (not Row).
      // Find the EdenAuthenticatedImage widgets and walk ancestors to verify
      // their common ancestor is a Column.
      final imgs = find.byType(EdenAuthenticatedImage);
      expect(imgs, findsNWidgets(2));
      // No Row contains both EdenAuthenticatedImage widgets in stacked mode.
      final firstImgRowAncestors =
          find.ancestor(of: imgs.at(0), matching: find.byType(Row));
      var sharedRowFound = false;
      for (final rowElement in firstImgRowAncestors.evaluate()) {
        final descendants = find.descendant(
            of: find.byWidget(rowElement.widget),
            matching: find.byType(EdenAuthenticatedImage));
        if (descendants.evaluate().length >= 2) {
          sharedRowFound = true;
          break;
        }
      }
      expect(sharedRowFound, isFalse,
          reason: 'stacked layout MUST NOT put front+back in same Row');
    });

    testWidgets('layout=sideBySide at 800pt: front+back share a Row',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenInsuranceCard(
          policy: InsuranceCardFixtures.primaryAetnaPpoActive(),
          layout: EdenInsuranceCardLayout.sideBySide,
        ),
        width: 800,
        height: 800,
      ));
      final imgs = find.byType(EdenAuthenticatedImage);
      expect(imgs, findsNWidgets(2));
      final firstImgRowAncestors =
          find.ancestor(of: imgs.at(0), matching: find.byType(Row));
      var sharedRowFound = false;
      for (final rowElement in firstImgRowAncestors.evaluate()) {
        final descendants = find.descendant(
            of: find.byWidget(rowElement.widget),
            matching: find.byType(EdenAuthenticatedImage));
        if (descendants.evaluate().length >= 2) {
          sharedRowFound = true;
          break;
        }
      }
      expect(sharedRowFound, isTrue,
          reason: 'sideBySide @ >=600pt MUST place front+back in same Row');
    });

    testWidgets('layout=sideBySide at 500pt: collapses to stacked',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenInsuranceCard(
          policy: InsuranceCardFixtures.primaryAetnaPpoActive(),
          layout: EdenInsuranceCardLayout.sideBySide,
        ),
        width: 500,
        height: 1000,
      ));
      final imgs = find.byType(EdenAuthenticatedImage);
      expect(imgs, findsNWidgets(2));
      final firstImgRowAncestors =
          find.ancestor(of: imgs.at(0), matching: find.byType(Row));
      var sharedRowFound = false;
      for (final rowElement in firstImgRowAncestors.evaluate()) {
        final descendants = find.descendant(
            of: find.byWidget(rowElement.widget),
            matching: find.byType(EdenAuthenticatedImage));
        if (descendants.evaluate().length >= 2) {
          sharedRowFound = true;
          break;
        }
      }
      expect(sharedRowFound, isFalse,
          reason: 'sideBySide @ <600pt MUST collapse to Column');
    });
  });

  group('EdenInsuranceCard — empty-image state (case 11)', () {
    testWidgets('both URLs null: empty placeholder rendered', (tester) async {
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: InsuranceCardFixtures.secondaryBcbsHdhpActive(),
      )));
      expect(
          find.byKey(const ValueKey('eden-insurance-card-empty-placeholder')),
          findsOneWidget);
    });

    testWidgets('empty placeholder + add-image affordance when callback non-null',
        (tester) async {
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: InsuranceCardFixtures.secondaryBcbsHdhpActive(),
        onReplaceImageRequested: (_) {},
      )));
      expect(find.text('Add insurance card images'), findsOneWidget);
    });

    testWidgets('empty placeholder WITHOUT add-image affordance when callback null',
        (tester) async {
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: InsuranceCardFixtures.secondaryBcbsHdhpActive(),
      )));
      expect(find.text('Add insurance card images'), findsNothing);
      expect(find.text('No insurance card images'), findsOneWidget);
    });
  });

  group('EdenInsuranceCard — expired-policy banner (cases 12+13+14)', () {
    testWidgets('renders EdenAlert.warning when planTerminationDate < now',
        (tester) async {
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: InsuranceCardFixtures.expiredHdhp(),
        now: DateTime(2026, 5, 17),
      )));
      final banner =
          find.byKey(const ValueKey('eden-insurance-card-expired-banner'));
      expect(banner, findsOneWidget);
      // Confirm it's an EdenAlert with warning variant.
      final alert = tester.widget<EdenAlert>(find.byType(EdenAlert));
      expect(alert.variant, EdenAlertVariant.warning);
      expect(alert.message, contains('Policy expired'));
      expect(alert.message, contains('2020-01-01'));
    });

    testWidgets('expired banner is non-dismissible (no close button)',
        (tester) async {
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: InsuranceCardFixtures.expiredHdhp(),
        now: DateTime(2026, 5, 17),
      )));
      final alert = tester.widget<EdenAlert>(find.byType(EdenAlert));
      expect(alert.dismissible, isFalse);
    });

    testWidgets('no expired banner when planTerminationDate is in the future',
        (tester) async {
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: InsuranceCardFixtures.primaryAetnaPpoActive(),
        now: DateTime(2026, 5, 17),
      )));
      expect(
          find.byKey(const ValueKey('eden-insurance-card-expired-banner')),
          findsNothing);
    });

    testWidgets('no expired banner when planTerminationDate is null',
        (tester) async {
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: InsuranceCardFixtures.medicareTraditional(),
        now: DateTime(2026, 5, 17),
      )));
      expect(
          find.byKey(const ValueKey('eden-insurance-card-expired-banner')),
          findsNothing);
    });
  });

  group('EdenInsuranceCard — callback wiring (cases 15..19)', () {
    testWidgets('onEditRequested fires with current policy on edit-icon tap',
        (tester) async {
      EdenInsurancePolicy? fired;
      final policy = InsuranceCardFixtures.primaryAetnaPpoActive();
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: policy,
        onEditRequested: (p) => fired = p,
      )));
      await tester.tap(find.byKey(
        const ValueKey('eden-insurance-card-edit-button'),
      ));
      expect(fired, isNotNull);
      expect(fired!.id, policy.id);
    });

    testWidgets('onReplaceImageRequested fires on front overlay tap',
        (tester) async {
      EdenInsurancePolicy? fired;
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: InsuranceCardFixtures.primaryAetnaPpoActive(),
        onReplaceImageRequested: (p) => fired = p,
      )));
      await tester.tap(find.byKey(
        const ValueKey('eden-insurance-card-replace-front'),
      ));
      expect(fired, isNotNull);
    });

    testWidgets('onReplaceImageRequested fires on back overlay tap',
        (tester) async {
      EdenInsurancePolicy? fired;
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: InsuranceCardFixtures.primaryAetnaPpoActive(),
        onReplaceImageRequested: (p) => fired = p,
      )));
      await tester.tap(find.byKey(
        const ValueKey('eden-insurance-card-replace-back'),
      ));
      expect(fired, isNotNull);
    });

    testWidgets('edit-icon affordance hidden when onEditRequested is null',
        (tester) async {
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: InsuranceCardFixtures.primaryAetnaPpoActive(),
      )));
      expect(find.byKey(const ValueKey('eden-insurance-card-edit-button')),
          findsNothing);
    });

    testWidgets('replace-image overlay hidden when callback null',
        (tester) async {
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: InsuranceCardFixtures.primaryAetnaPpoActive(),
      )));
      expect(find.byKey(const ValueKey('eden-insurance-card-replace-front')),
          findsNothing);
      expect(find.byKey(const ValueKey('eden-insurance-card-replace-back')),
          findsNothing);
    });
  });

  group('EdenInsuranceCard — HIPAA isolation (cases 20+21)', () {
    testWidgets('patient A policy MUST NOT render patient B identifiers',
        (tester) async {
      // Render patient-alpha (Aetna PPO) only.
      await tester.pumpWidget(wrap(EdenInsuranceCard(
        policy: InsuranceCardFixtures.primaryAetnaPpoActive(),
      )));
      // patient-bravo's Medicare member ID MUST NOT appear.
      expect(find.textContaining('1AB2-CD3-EF45'), findsNothing);
      // patient-charlie's expired plan name MUST NOT appear.
      expect(find.textContaining('Anthem HDHP Bronze'), findsNothing);
    });
  });
}
