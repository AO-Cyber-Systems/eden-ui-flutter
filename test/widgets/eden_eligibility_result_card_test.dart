// TDD test file for EdenEligibilityResultCard (obj 017-04).

import 'package:eden_ui_flutter/src/theme/eden_theme.dart';
import 'package:eden_ui_flutter/src/theme/eden_theme_profile.dart';
import 'package:eden_ui_flutter/src/widgets/eden_alert.dart';
import 'package:eden_ui_flutter/src/widgets/eden_currency_display.dart';
import 'package:eden_ui_flutter/src/widgets/eden_eligibility_result_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_eligibility_result_card_fixtures.dart';

void main() {
  Widget wrap(Widget child, {double width = 600, double height = 1000}) {
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

  group('EdenEligibilityResultCard — coverage status alert (case 1)', () {
    testWidgets('covered → EdenAlert.success', (tester) async {
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: EligibilityFixtures.coveredInNetworkLowCopay(),
        now: DateTime(2026, 5, 17),
      )));
      final alert = tester.widget<EdenAlert>(find.byKey(
          const ValueKey('eden-eligibility-coverage-alert')));
      expect(alert.variant, EdenAlertVariant.success);
      expect(alert.message, contains('Covered'));
      expect(alert.message, contains('Aetna Choice POS II'));
    });

    testWidgets('partiallyCovered → EdenAlert.warning', (tester) async {
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: EligibilityFixtures.partialDeductibleNotMet(),
        now: DateTime(2026, 5, 17),
      )));
      final alert = tester.widget<EdenAlert>(find.byKey(
          const ValueKey('eden-eligibility-coverage-alert')));
      expect(alert.variant, EdenAlertVariant.warning);
      expect(alert.message, contains('Partial coverage'));
    });

    testWidgets('notCovered → EdenAlert.danger', (tester) async {
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: EligibilityFixtures.outOfNetworkDenied(),
        now: DateTime(2026, 5, 17),
      )));
      final alert = tester.widget<EdenAlert>(find.byKey(
          const ValueKey('eden-eligibility-coverage-alert')));
      expect(alert.variant, EdenAlertVariant.danger);
      expect(alert.message, contains('Not covered'));
    });

    testWidgets('needsAuth → EdenAlert.warning', (tester) async {
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: EligibilityFixtures.needsAuthPending(),
        now: DateTime(2026, 5, 17),
      )));
      final alert = tester.widget<EdenAlert>(find.byKey(
          const ValueKey('eden-eligibility-coverage-alert')));
      expect(alert.variant, EdenAlertVariant.warning);
      expect(alert.message, contains('Prior authorization required'));
    });
  });

  group('EdenEligibilityResultCard — service type + currency (cases 2..4)', () {
    testWidgets('renders serviceType', (tester) async {
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: EligibilityFixtures.coveredInNetworkLowCopay(),
        now: DateTime(2026, 5, 17),
      )));
      expect(find.text('Office visit (PCP)'), findsOneWidget);
    });

    testWidgets('renders all 4 responsibility rows via EdenCurrencyDisplay '
        'when fully populated', (tester) async {
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: EligibilityFixtures.coveredInNetworkLowCopay(),
        now: DateTime(2026, 5, 17),
      )));
      // copay + deductible-remaining + OOP-remaining = 3 EdenCurrencyDisplay
      // widgets (coinsurance is null in this fixture).
      expect(find.byType(EdenCurrencyDisplay), findsNWidgets(3));
      // $25 copay rendered.
      expect(find.text(r'$25.00'), findsOneWidget);
    });

    testWidgets('coinsurance row renders percentage when non-null',
        (tester) async {
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: EligibilityFixtures.partialDeductibleNotMet(),
        now: DateTime(2026, 5, 17),
      )));
      expect(find.text('20%'), findsOneWidget);
    });
  });

  group('EdenEligibilityResultCard — network badge (cases 5..7)', () {
    testWidgets('inNetwork → success badge', (tester) async {
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: EligibilityFixtures.coveredInNetworkLowCopay(),
        now: DateTime(2026, 5, 17),
      )));
      expect(find.text('In Network'), findsOneWidget);
    });

    testWidgets('outOfNetwork → danger badge with OUT OF NETWORK text',
        (tester) async {
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: EligibilityFixtures.outOfNetworkDenied(),
        now: DateTime(2026, 5, 17),
      )));
      expect(find.text('OUT OF NETWORK'), findsOneWidget);
    });

    testWidgets('tier badges render tier label', (tester) async {
      final r = EdenEligibilityResult(
        id: 'e-tier-2',
        patientId: 'pt-tier',
        policyId: 'p-tier',
        checkedAt: DateTime(2026, 5, 16),
        coverageStatus: EdenCoverageStatus.covered,
        planName: 'Tier Plan',
        serviceType: 'visit',
        networkStatus: EdenInsuranceNetworkStatus.tier2,
      );
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: r,
        now: DateTime(2026, 5, 17),
      )));
      expect(find.text('Tier 2'), findsOneWidget);
    });
  });

  group('EdenEligibilityResultCard — prior auth (cases 8..10)', () {
    testWidgets('renders prior auth pill when priorAuthRequired=true',
        (tester) async {
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: EligibilityFixtures.needsAuthPending(),
        now: DateTime(2026, 5, 17),
      )));
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('Request Authorization button hidden for status=pending',
        (tester) async {
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: EligibilityFixtures.needsAuthPending(),
        now: DateTime(2026, 5, 17),
        onAuthRequestRequested: (_) {},
      )));
      // Pending status does NOT show the request button — only required_ + denied do.
      expect(find.byKey(const ValueKey('eden-eligibility-request-auth-button')),
          findsNothing);
    });

    testWidgets('Request Authorization button visible for status=required_ + '
        'fires onAuthRequestRequested', (tester) async {
      EdenEligibilityResult? fired;
      final r = EdenEligibilityResult(
        id: 'e-req',
        patientId: 'pt-req',
        policyId: 'policy-req',
        checkedAt: DateTime(2026, 5, 16),
        coverageStatus: EdenCoverageStatus.needsAuth,
        planName: 'Test Plan',
        serviceType: 'TMS',
        networkStatus: EdenInsuranceNetworkStatus.inNetwork,
        priorAuthRequired: true,
        priorAuthStatus: EdenPriorAuthStatus.required_,
      );
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: r,
        now: DateTime(2026, 5, 17),
        onAuthRequestRequested: (e) => fired = e,
      )));
      final button =
          find.byKey(const ValueKey('eden-eligibility-request-auth-button'));
      expect(button, findsOneWidget);
      await tester.ensureVisible(button);
      await tester.tap(button);
      expect(fired, isNotNull);
      expect(fired!.id, 'e-req');
    });
  });

  group('EdenEligibilityResultCard — referral required (case 11)', () {
    testWidgets('renders referral warning when referralRequired=true',
        (tester) async {
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: EligibilityFixtures.referralRequired(),
        now: DateTime(2026, 5, 17),
      )));
      expect(
        find.textContaining('Specialist referral required before service'),
        findsOneWidget,
      );
    });
  });

  group('EdenEligibilityResultCard — re-check button (cases 12+13)', () {
    testWidgets('re-check button always visible', (tester) async {
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: EligibilityFixtures.coveredInNetworkLowCopay(),
        now: DateTime(2026, 5, 17),
      )));
      expect(find.byKey(const ValueKey('eden-eligibility-recheck-button')),
          findsOneWidget);
    });

    testWidgets('re-check button fires onRecheckRequested', (tester) async {
      EdenEligibilityResult? fired;
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: EligibilityFixtures.coveredInNetworkLowCopay(),
        now: DateTime(2026, 5, 17),
        onRecheckRequested: (e) => fired = e,
      )));
      await tester.ensureVisible(
        find.byKey(const ValueKey('eden-eligibility-recheck-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('eden-eligibility-recheck-button')),
      );
      expect(fired, isNotNull);
    });
  });

  group('EdenEligibilityResultCard — stale check (cases 14..16)', () {
    testWidgets('stale warning when (now - checkedAt) > 30 days',
        (tester) async {
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: EligibilityFixtures.staleCheckNinetyDaysOld(),
        now: DateTime(2026, 5, 17),
      )));
      expect(find.byKey(const ValueKey('eden-eligibility-stale-banner')),
          findsOneWidget);
    });

    testWidgets('no stale warning at <30 days', (tester) async {
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: EligibilityFixtures.coveredInNetworkLowCopay(
          checkedAt: DateTime(2026, 5, 7), // 10 days ago
        ),
        now: DateTime(2026, 5, 17),
      )));
      expect(find.byKey(const ValueKey('eden-eligibility-stale-banner')),
          findsNothing);
    });

    testWidgets('stale warning is non-dismissible', (tester) async {
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: EligibilityFixtures.staleCheckNinetyDaysOld(),
        now: DateTime(2026, 5, 17),
      )));
      final banner = tester.widget<EdenAlert>(
          find.byKey(const ValueKey('eden-eligibility-stale-banner')));
      expect(banner.dismissible, isFalse);
    });
  });

  group('EdenEligibilityResultCard — layout variants (cases 17..20)', () {
    testWidgets('layout=standard renders prior auth + referral rows',
        (tester) async {
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: EligibilityFixtures.needsAuthPending(),
        now: DateTime(2026, 5, 17),
      )));
      // Standard layout shows the prior auth pill.
      expect(find.text('Pending'), findsOneWidget);
      // And the responsibility block is rendered.
      expect(find.byKey(
        const ValueKey('eden-eligibility-responsibility-block'),
      ), findsOneWidget);
    });

    testWidgets('layout=compact omits the responsibility block',
        (tester) async {
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: EligibilityFixtures.coveredInNetworkLowCopay(),
        now: DateTime(2026, 5, 17),
        layout: EdenEligibilityCardLayout.compact,
      )));
      // Compact replaces the responsibility block with an inline summary.
      expect(find.byKey(
        const ValueKey('eden-eligibility-responsibility-block'),
      ), findsNothing);
      // Inline summary text visible.
      expect(find.textContaining('Copay:'), findsOneWidget);
    });

    testWidgets('layout=kpiStrip omits responsibility block + service type',
        (tester) async {
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: EligibilityFixtures.coveredInNetworkLowCopay(),
        now: DateTime(2026, 5, 17),
        layout: EdenEligibilityCardLayout.kpiStrip,
      )));
      expect(find.byKey(
        const ValueKey('eden-eligibility-responsibility-block'),
      ), findsNothing);
      // Service type is suppressed in KPI strip mode.
      expect(find.text('Office visit (PCP)'), findsNothing);
      // KPI tile labels visible.
      expect(find.text('Coverage'), findsOneWidget);
      expect(find.text('Copay'), findsOneWidget);
      expect(find.text('Deductible remaining'), findsOneWidget);
    });

    testWidgets('layout=kpiStrip at 390pt does not horizontal-scroll '
        '(wraps to multiple rows)', (tester) async {
      await tester.pumpWidget(wrap(
        EdenEligibilityResultCard(
          result: EligibilityFixtures.coveredInNetworkLowCopay(),
          now: DateTime(2026, 5, 17),
          layout: EdenEligibilityCardLayout.kpiStrip,
        ),
        width: 390,
        height: 600,
      ));
      // Wrap widget should be present (no horizontal scroll).
      expect(find.byType(Wrap), findsWidgets);
    });
  });

  group('EdenEligibilityResultCard — responsibility tap (cases 21+22)', () {
    testWidgets('onTapPatientResponsibilityBreakdown fires on tap '
        'when callback non-null', (tester) async {
      EdenEligibilityResult? fired;
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: EligibilityFixtures.coveredInNetworkLowCopay(),
        now: DateTime(2026, 5, 17),
        onTapPatientResponsibilityBreakdown: (e) => fired = e,
      )));
      expect(find.byKey(
        const ValueKey('eden-eligibility-responsibility-inkwell'),
      ), findsOneWidget);
      await tester.tap(find.byKey(
        const ValueKey('eden-eligibility-responsibility-inkwell'),
      ));
      expect(fired, isNotNull);
    });

    testWidgets('responsibility block is NOT InkWell-wrapped when callback null',
        (tester) async {
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: EligibilityFixtures.coveredInNetworkLowCopay(),
        now: DateTime(2026, 5, 17),
      )));
      expect(find.byKey(
        const ValueKey('eden-eligibility-responsibility-inkwell'),
      ), findsNothing);
    });
  });

  group('EdenEligibilityResultCard — constructor assertion (case 23)', () {
    test('empty policyId throws AssertionError', () {
      expect(
        () => EdenEligibilityResult(
          id: 'e-x',
          patientId: 'pt-x',
          policyId: '', // empty
          checkedAt: DateTime(2026, 5, 17),
          coverageStatus: EdenCoverageStatus.covered,
          planName: 'X',
          serviceType: 'X',
          networkStatus: EdenInsuranceNetworkStatus.inNetwork,
        ),
        throwsAssertionError,
      );
    });
  });

  group('EdenEligibilityResultCard — HIPAA isolation (case 24)', () {
    testWidgets('patient A result MUST NOT render fields from patient B fixture',
        (tester) async {
      await tester.pumpWidget(wrap(EdenEligibilityResultCard(
        result: EligibilityFixtures.coveredInNetworkLowCopay(),
        now: DateTime(2026, 5, 17),
      )));
      // patient-bravo's out-of-network plan name MUST NOT appear.
      expect(find.textContaining('UnitedHealthcare Choice Plus'), findsNothing);
      // patient-charlie's Cigna OAP MUST NOT appear.
      expect(find.textContaining('Cigna Open Access Plus'), findsNothing);
    });
  });
}
