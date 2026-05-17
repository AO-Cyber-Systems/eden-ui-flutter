// TDD test file for EdenAVSGenerator (obj 017-01).

import 'package:eden_ui_flutter/src/theme/eden_theme.dart';
import 'package:eden_ui_flutter/src/theme/eden_theme_profile.dart';
import 'package:eden_ui_flutter/src/widgets/eden_avs_generator.dart';
import 'package:eden_ui_flutter/src/widgets/eden_medication_list.dart';
import 'package:eden_ui_flutter/src/widgets/eden_problem_list.dart';
import 'package:eden_ui_flutter/src/widgets/eden_soap_note.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_avs_generator_fixtures.dart';

void main() {
  Widget wrap(Widget child, {double width = 600, double height = 1600}) {
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

  group('EdenAVSGenerator — header (case 1)', () {
    testWidgets('renders patient + provider + encounter date + facility',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAVSGenerator(
        document: AvsFixtures.behavioralHealthFollowUp(),
      )));
      expect(find.text('Alex Alpha'), findsOneWidget);
      // Provider + credentials + facility + encounter date all appear
      // somewhere in the header subtitle.
      expect(
        find.textContaining('Dr. Jane Smith'),
        findsWidgets,
      );
      expect(find.textContaining('PsyD'), findsWidgets);
      expect(
        find.textContaining('Eden Behavioral Health Center'),
        findsWidgets,
      );
      expect(find.textContaining('2026-05-17'), findsWidgets);
    });
  });

  group('EdenAVSGenerator — patient-readable section headers (case 5)', () {
    testWidgets('renders plain-language headers; suppresses SOAP jargon',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAVSGenerator(
        document: AvsFixtures.behavioralHealthFollowUp(),
      )));
      expect(find.text('Why you came in'), findsOneWidget);
      expect(find.text('What we measured'), findsOneWidget);
      expect(find.text('What we found'), findsOneWidget);
      expect(find.text('What to do next'), findsOneWidget);
      // Clinical SOAP jargon MUST NOT appear as section headers in the AVS.
      expect(find.text('Subjective'), findsNothing);
      expect(find.text('Objective'), findsNothing);
      expect(find.text('Assessment'), findsNothing);
      expect(find.text('Plan'), findsNothing);
    });
  });

  group('EdenAVSGenerator — SOAP body content (case 2)', () {
    testWidgets('renders soapData subjective/objective/assessment/plan content',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAVSGenerator(
        document: AvsFixtures.behavioralHealthFollowUp(),
      )));
      expect(
        find.textContaining('GAD-7 score down from 14 to 8'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Affect brighter'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Generalized anxiety disorder'),
        findsWidgets,
      );
      expect(
        find.textContaining('Continue sertraline 50mg daily'),
        findsWidgets,
      );
    });

    testWidgets('renders patient-friendly visit reason in "Why you came in"',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAVSGenerator(
        document: AvsFixtures.behavioralHealthFollowUp(),
      )));
      expect(find.textContaining('Anxiety follow-up'), findsWidgets);
    });
  });

  group('EdenAVSGenerator — active medications filter (case 3)', () {
    testWidgets('renders active drug names; discontinued drugs not rendered',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAVSGenerator(
        document: AvsFixtures.behavioralHealthFollowUp(),
      )));
      expect(find.textContaining('Sertraline'), findsWidgets);
      // Trazodone is discontinued in the fixture — must NOT render as drug name.
      expect(find.textContaining('Trazodone'), findsNothing);
    });

    testWidgets('renders two active drugs for concierge annual physical',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAVSGenerator(
        document: AvsFixtures.conciergeAnnualPhysical(),
      )));
      expect(find.textContaining('Atorvastatin'), findsWidgets);
      expect(find.textContaining('Lisinopril'), findsWidgets);
    });
  });

  group('EdenAVSGenerator — active problems filter (case 4)', () {
    testWidgets('renders active conditions only; resolved problems excluded',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAVSGenerator(
        document: AvsFixtures.conciergeAnnualPhysical(),
      )));
      // E78.5 + I10 are active; J06.9 URI is resolved → URI MUST NOT render.
      expect(find.textContaining('Hyperlipidemia'), findsWidgets);
      expect(find.textContaining('Essential (primary) hypertension'), findsWidgets);
      expect(find.textContaining('Acute upper respiratory infection'), findsNothing);
    });
  });

  group('EdenAVSGenerator — follow-up + next-appointment (cases 6+7)', () {
    testWidgets('renders follow-up instructions block when present',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAVSGenerator(
        document: AvsFixtures.behavioralHealthFollowUp(),
      )));
      expect(find.text('Follow-up instructions'), findsOneWidget);
      expect(
        find.textContaining('Continue sertraline 50mg daily, follow up in 4 weeks'),
        findsOneWidget,
      );
    });

    testWidgets('renders next-appointment pill when present',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAVSGenerator(
        document: AvsFixtures.behavioralHealthFollowUp(),
      )));
      // Pill shows formatted next appointment time.
      expect(
        find.textContaining('Next appointment: 2026-06-14'),
        findsOneWidget,
      );
    });

    testWidgets('no next-appointment pill when nextAppointmentAt is null',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAVSGenerator(
        document: AvsFixtures.cashPayNewPatientEval(),
      )));
      expect(find.textContaining('Next appointment'), findsNothing);
    });
  });

  group('EdenAVSGenerator — empty states (cases 18+19)', () {
    testWidgets('empty medications: renders "No active medications"',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAVSGenerator(
        document: AvsFixtures.cashPayNewPatientEval(),
      )));
      expect(find.text('No active medications'), findsOneWidget);
    });

    testWidgets('empty problems: renders "No active problems"',
        (tester) async {
      // Build a doc with zero problems by overriding the cash-pay fixture's
      // problems via copying it (cash-pay has 1 problem; we want zero here).
      final doc = AvsFixtures.cashPayNewPatientEval();
      final emptyProblemsDoc = EdenAvsDocument(
        patientId: doc.patientId,
        patientDisplayName: doc.patientDisplayName,
        encounterDate: doc.encounterDate,
        providerName: doc.providerName,
        providerCredentials: doc.providerCredentials,
        facilityName: doc.facilityName,
        visitReason: doc.visitReason,
        soapData: doc.soapData,
        medications: doc.medications,
        problems: const [],
        followUpInstructions: doc.followUpInstructions,
      );
      await tester.pumpWidget(wrap(EdenAVSGenerator(
        document: emptyProblemsDoc,
      )));
      expect(find.text('No active problems'), findsOneWidget);
    });
  });

  group('EdenAVSGenerator — typography (cases 11+12)', () {
    testWidgets('body text >=14pt', (tester) async {
      await tester.pumpWidget(wrap(EdenAVSGenerator(
        document: AvsFixtures.behavioralHealthFollowUp(),
      )));
      // Section body text uses bodyMedium with explicit fontSize: 14.
      final bodyText = tester.widget<Text>(
        find.textContaining('GAD-7 score down from 14 to 8'),
      );
      expect(bodyText.style?.fontSize, greaterThanOrEqualTo(14));
    });

    testWidgets('section headers >=18pt', (tester) async {
      await tester.pumpWidget(wrap(EdenAVSGenerator(
        document: AvsFixtures.behavioralHealthFollowUp(),
      )));
      final header = tester.widget<Text>(find.text('Why you came in'));
      expect(header.style?.fontSize, greaterThanOrEqualTo(18));
    });
  });

  group('EdenAVSGenerator — layout (cases 8+9+10)', () {
    testWidgets('compact at 390pt: no Row splitting body sections',
        (tester) async {
      tester.view.physicalSize = const Size(390, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(wrap(
        EdenAVSGenerator(
          document: AvsFixtures.behavioralHealthFollowUp(),
        ),
        width: 390,
        height: 2000,
      ));
      // No row that contains BOTH the "Why you came in" + "What we found"
      // headers (those would only co-exist in a Row in printFriendly @ >=600).
      // In compact, all sections stack in a Column.
      final whyText = find.text('Why you came in');
      final whatFoundText = find.text('What we found');
      expect(whyText, findsOneWidget);
      expect(whatFoundText, findsOneWidget);
      // Walk up from whyText: ancestor Row must NOT contain whatFoundText.
      final whyAncestorRows = find.ancestor(of: whyText, matching: find.byType(Row));
      // Test that the closest Row ancestor does NOT also contain whatFoundText.
      // (compact layout: no Row contains both section headers).
      for (final rowElement in whyAncestorRows.evaluate()) {
        final rowDescendants =
            find.descendant(of: find.byWidget(rowElement.widget), matching: whatFoundText);
        expect(rowDescendants.evaluate().isEmpty, isTrue,
            reason: 'compact layout MUST NOT put "Why you came in" + '
                '"What we found" in the same Row');
      }
    });

    testWidgets('printFriendly at 800pt: two-column body via Row',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(wrap(
        EdenAVSGenerator(
          document: AvsFixtures.behavioralHealthFollowUp(),
          layout: EdenAvsLayout.printFriendly,
        ),
        width: 800,
        height: 1800,
      ));
      // Find a Row that contains BOTH "Why you came in" + "What we found".
      final whyText = find.text('Why you came in');
      final whatFoundText = find.text('What we found');
      final whyRowAncestors =
          find.ancestor(of: whyText, matching: find.byType(Row));
      var sharedRowFound = false;
      for (final rowElement in whyRowAncestors.evaluate()) {
        final rowDescendants = find.descendant(
            of: find.byWidget(rowElement.widget), matching: whatFoundText);
        if (rowDescendants.evaluate().isNotEmpty) {
          sharedRowFound = true;
          break;
        }
      }
      expect(sharedRowFound, isTrue,
          reason: 'printFriendly layout at 800pt MUST place "Why you came in" '
              '+ "What we found" in the same Row');
    });

    testWidgets('printFriendly at 500pt: collapses to single-column',
        (tester) async {
      tester.view.physicalSize = const Size(500, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(wrap(
        EdenAVSGenerator(
          document: AvsFixtures.behavioralHealthFollowUp(),
          layout: EdenAvsLayout.printFriendly,
        ),
        width: 500,
        height: 2000,
      ));
      // Below 600pt threshold, printFriendly MUST collapse — no Row contains
      // both section headers.
      final whyText = find.text('Why you came in');
      final whatFoundText = find.text('What we found');
      final whyRowAncestors =
          find.ancestor(of: whyText, matching: find.byType(Row));
      for (final rowElement in whyRowAncestors.evaluate()) {
        final rowDescendants = find.descendant(
            of: find.byWidget(rowElement.widget), matching: whatFoundText);
        expect(rowDescendants.evaluate().isEmpty, isTrue,
            reason: 'printFriendly @ <600pt MUST collapse to single-column');
      }
    });
  });

  group('EdenAVSGenerator — callback gating (cases 13..17)', () {
    testWidgets('print button hidden when onPrintRequested is null',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAVSGenerator(
        document: AvsFixtures.behavioralHealthFollowUp(),
      )));
      expect(find.byKey(const ValueKey('eden-avs-print-button')), findsNothing);
    });

    testWidgets('print button visible + fires callback on tap',
        (tester) async {
      var fired = 0;
      await tester.pumpWidget(wrap(EdenAVSGenerator(
        document: AvsFixtures.behavioralHealthFollowUp(),
        onPrintRequested: () => fired++,
      )));
      final button = find.byKey(const ValueKey('eden-avs-print-button'));
      expect(button, findsOneWidget);
      await tester.ensureVisible(button);
      await tester.tap(button);
      expect(fired, 1);
    });

    testWidgets('email button hidden when onEmailRequested is null',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAVSGenerator(
        document: AvsFixtures.behavioralHealthFollowUp(),
        onPrintRequested: () {},
      )));
      expect(find.byKey(const ValueKey('eden-avs-email-button')), findsNothing);
    });

    testWidgets('email button emits EdenAvsExport with format=email + document',
        (tester) async {
      EdenAvsExport? received;
      final doc = AvsFixtures.behavioralHealthFollowUp();
      await tester.pumpWidget(wrap(EdenAVSGenerator(
        document: doc,
        onEmailRequested: (e) => received = e,
      )));
      final button = find.byKey(const ValueKey('eden-avs-email-button'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      expect(received, isNotNull);
      expect(received!.format, EdenAvsExportFormat.email);
      expect(received!.document.patientId, doc.patientId);
      expect(received!.plainTextBody, contains('Alex Alpha'));
    });

    testWidgets('portal button mirrors email gating + emits format=portal',
        (tester) async {
      EdenAvsExport? received;
      final doc = AvsFixtures.behavioralHealthFollowUp();

      // Step 1: portal button hidden when callback is null.
      await tester.pumpWidget(wrap(EdenAVSGenerator(document: doc)));
      expect(find.byKey(const ValueKey('eden-avs-portal-button')), findsNothing);

      // Step 2: portal button visible + emits format=portal on tap.
      await tester.pumpWidget(wrap(EdenAVSGenerator(
        document: doc,
        onPortalShareRequested: (e) => received = e,
      )));
      final button = find.byKey(const ValueKey('eden-avs-portal-button'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      expect(received, isNotNull);
      expect(received!.format, EdenAvsExportFormat.portal);
    });
  });

  group('EdenAVSGenerator — HIPAA isolation (cases 22..25)', () {
    testWidgets('mismatched soapData.patientId throws AssertionError',
        (tester) async {
      expect(
        () => EdenAVSGenerator(
          document: EdenAvsDocument(
            patientId: 'patient-alpha',
            patientDisplayName: 'Alex Alpha',
            encounterDate: DateTime(2026, 5, 17),
            providerName: 'Dr. Smith',
            visitReason: 'Test',
            soapData: const EdenSoapNoteData(patientId: 'patient-bravo'),
          ),
        ),
        throwsAssertionError,
      );
    });

    testWidgets('mismatched medications[].patientId throws AssertionError',
        (tester) async {
      expect(
        () => EdenAVSGenerator(
          document: EdenAvsDocument(
            patientId: 'patient-alpha',
            patientDisplayName: 'Alex Alpha',
            encounterDate: DateTime(2026, 5, 17),
            providerName: 'Dr. Smith',
            visitReason: 'Test',
            soapData: const EdenSoapNoteData(patientId: 'patient-alpha'),
            medications: const [
              EdenMedicationStatement(
                id: 'med-x',
                patientId: 'patient-bravo', // mismatched
                drugName: 'Test Med',
                doseLabel: '10mg',
                route: EdenMedicationRoute.oral,
                frequency: 'QD',
              ),
            ],
          ),
        ),
        throwsAssertionError,
      );
    });

    testWidgets('mismatched problems[].patientId throws AssertionError',
        (tester) async {
      expect(
        () => EdenAVSGenerator(
          document: EdenAvsDocument(
            patientId: 'patient-alpha',
            patientDisplayName: 'Alex Alpha',
            encounterDate: DateTime(2026, 5, 17),
            providerName: 'Dr. Smith',
            visitReason: 'Test',
            soapData: const EdenSoapNoteData(patientId: 'patient-alpha'),
            problems: const [
              EdenCondition(
                id: 'cond-x',
                patientId: 'patient-bravo', // mismatched
                code: 'F41.1',
                codeSystem: 'ICD-10-CM',
                description: 'Test',
                status: EdenConditionStatus.active,
              ),
            ],
          ),
        ),
        throwsAssertionError,
      );
    });

    testWidgets('wrong-patient bleed isolation: patient B fixture text '
        'not present when patient A document is rendered', (tester) async {
      // Render patient-alpha document only.
      await tester.pumpWidget(wrap(EdenAVSGenerator(
        document: AvsFixtures.behavioralHealthFollowUp(),
      )));
      // patient-bravo's drug names + problems MUST NOT appear in patient-alpha's
      // widget tree.
      expect(find.textContaining('Other fatigue'), findsNothing);
      expect(find.textContaining('Blake Bravo'), findsNothing);
    });
  });
}
