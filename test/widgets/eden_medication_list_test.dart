// TDD test file for EdenMedicationList.

import 'package:eden_ui_flutter/src/theme/eden_theme.dart';
import 'package:eden_ui_flutter/src/theme/eden_theme_profile.dart';
import 'package:eden_ui_flutter/src/widgets/eden_medication_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_medication_list_fixtures.dart';

void main() {
  Widget wrap(Widget child, {double width = 390, double height = 700}) {
    final theme = EdenTheme.light(profile: EdenThemeProfile.medicalInstitutional);
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );
  }

  group('EdenMedicationList — single-row rendering', () {
    testWidgets('drug name + dose + route renders on line 1', (tester) async {
      await tester.pumpWidget(wrap(EdenMedicationList(
        medications: [MedFixtures.metformin500],
      )));
      expect(find.text('Metformin 500mg PO'), findsOneWidget);
    });

    testWidgets('frequency + prescriber + startDate caption renders on line 2',
        (tester) async {
      await tester.pumpWidget(wrap(EdenMedicationList(
        medications: [MedFixtures.metformin500],
      )));
      expect(find.textContaining('Twice daily'), findsOneWidget);
      expect(find.textContaining('Dr. Chen'), findsOneWidget);
      expect(find.textContaining('2024-03-12'), findsOneWidget);
    });

    testWidgets('drug-name line uses bold weight', (tester) async {
      await tester.pumpWidget(wrap(EdenMedicationList(
        medications: [MedFixtures.metformin500],
      )));
      final t = tester.widget<Text>(find.text('Metformin 500mg PO'));
      expect(t.style?.fontWeight, anyOf(FontWeight.w600, FontWeight.w700));
    });
  });

  group('EdenMedicationList — route abbreviation', () {
    testWidgets('oral → PO', (tester) async {
      await tester.pumpWidget(wrap(EdenMedicationList(
        medications: [MedFixtures.metformin500],
      )));
      expect(find.textContaining('PO'), findsWidgets);
    });

    testWidgets('injection → IV (default v1)', (tester) async {
      await tester.pumpWidget(wrap(EdenMedicationList(
        medications: [MedFixtures.insulinSc],
      )));
      expect(find.textContaining('IV'), findsWidgets);
    });

    testWidgets('inhaled → INH', (tester) async {
      await tester.pumpWidget(wrap(EdenMedicationList(
        medications: [MedFixtures.albuterolInh],
      )));
      expect(find.textContaining('INH'), findsWidgets);
    });
  });

  group('EdenMedicationList — interaction flag', () {
    testWidgets('interactionWarning → IXN danger badge renders',
        (tester) async {
      await tester.pumpWidget(wrap(EdenMedicationList(
        medications: [MedFixtures.aspirinWithWarfarinInteraction],
      )));
      expect(find.text('IXN'), findsOneWidget);
    });

    testWidgets('no warning → no IXN badge', (tester) async {
      await tester.pumpWidget(wrap(EdenMedicationList(
        medications: [MedFixtures.metformin500],
      )));
      expect(find.text('IXN'), findsNothing);
    });

    testWidgets('warning text wired as Tooltip message', (tester) async {
      await tester.pumpWidget(wrap(EdenMedicationList(
        medications: [MedFixtures.aspirinWithWarfarinInteraction],
      )));
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip).first);
      expect(tooltip.message,
          contains('Increased bleeding risk'));
    });
  });

  group('EdenMedicationList — refill state', () {
    testWidgets('needsRefill + refillsRemaining > 0 → "Refill needed" badge',
        (tester) async {
      await tester.pumpWidget(wrap(EdenMedicationList(
        medications: [MedFixtures.lisinoprilNeedsRefill],
      )));
      expect(find.text('Refill needed'), findsOneWidget);
    });

    testWidgets('needsRefill + refillsRemaining == 0 → "No refills left" badge',
        (tester) async {
      await tester.pumpWidget(wrap(EdenMedicationList(
        medications: [MedFixtures.atorvastatinNoRefills],
      )));
      expect(find.text('No refills left'), findsOneWidget);
    });

    testWidgets('no needsRefill → no refill badge', (tester) async {
      await tester.pumpWidget(wrap(EdenMedicationList(
        medications: [MedFixtures.metformin500],
      )));
      expect(find.text('Refill needed'), findsNothing);
      expect(find.text('No refills left'), findsNothing);
    });
  });

  group('EdenMedicationList — status styling', () {
    testWidgets('discontinued + showInactive:true → strikethrough text',
        (tester) async {
      await tester.pumpWidget(wrap(EdenMedicationList(
        medications: [MedFixtures.discontinuedSertraline],
        showInactive: true,
      )));
      final t = tester.widget<Text>(find.text('Sertraline 100mg PO'));
      expect(t.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('discontinued + showInactive:false (default) → filtered out',
        (tester) async {
      await tester.pumpWidget(wrap(EdenMedicationList(
        medications: [MedFixtures.discontinuedSertraline],
      )));
      expect(find.textContaining('Sertraline'), findsNothing);
    });

    testWidgets('paused → italic text', (tester) async {
      await tester.pumpWidget(wrap(EdenMedicationList(
        medications: [MedFixtures.pausedOmeprazole],
      )));
      final t = tester.widget<Text>(find.text('Omeprazole 20mg PO'));
      expect(t.style?.fontStyle, FontStyle.italic);
    });
  });

  group('EdenMedicationList — multi-row', () {
    testWidgets('polypharmacy elderly: 8 rows render, IXN on aspirin',
        (tester) async {
      await tester.pumpWidget(wrap(EdenMedicationList(
        medications: MedFixtures.polypharmacyElderly,
      )));
      expect(find.text('Warfarin 5mg PO'), findsOneWidget);
      expect(find.text('Aspirin 81mg PO'), findsOneWidget);
      expect(find.text('Levothyroxine 75mcg PO'), findsOneWidget);
      expect(find.text('IXN'), findsOneWidget); // only on aspirin
    });

    testWidgets('T2DM + HTN combo: 3 active meds', (tester) async {
      await tester.pumpWidget(wrap(EdenMedicationList(
        medications: MedFixtures.t2dmHtnCombo,
      )));
      expect(find.text('Metformin 500mg PO'), findsOneWidget);
      expect(find.text('Lisinopril 10mg PO'), findsOneWidget);
      expect(find.text('Atorvastatin 40mg PO'), findsOneWidget);
    });
  });

  group('EdenMedicationList — callback wiring', () {
    testWidgets('onMedicationTap fires with correct medication',
        (tester) async {
      EdenMedicationStatement? tapped;
      await tester.pumpWidget(wrap(EdenMedicationList(
        medications: [MedFixtures.metformin500],
        onMedicationTap: (m) => tapped = m,
      )));
      await tester.tap(find.text('Metformin 500mg PO'));
      await tester.pump();
      expect(tapped?.id, 'med-001');
    });

    testWidgets('onRefillTap fires when refill badge tapped', (tester) async {
      EdenMedicationStatement? refillFor;
      await tester.pumpWidget(wrap(EdenMedicationList(
        medications: [MedFixtures.lisinoprilNeedsRefill],
        onRefillTap: (m) => refillFor = m,
      )));
      await tester.tap(find.text('Refill needed'));
      await tester.pump();
      expect(refillFor?.id, 'med-009');
    });
  });

  group('EdenMedicationList — empty state', () {
    testWidgets('empty list → "No active medications" caption', (tester) async {
      await tester.pumpWidget(wrap(EdenMedicationList(medications: const [])));
      expect(find.text('No active medications'), findsOneWidget);
    });

    testWidgets(
        'all-discontinued + showInactive:false → empty-state text rendered',
        (tester) async {
      await tester.pumpWidget(wrap(EdenMedicationList(
        medications: [MedFixtures.discontinuedSertraline],
      )));
      expect(find.text('No active medications'), findsOneWidget);
    });
  });

  group(
      'EdenMedicationList — HIPAA isolation (multitenancy-equivalent per global TDD Playbook habit 6)',
      () {
    testWidgets('mixed patientId → AssertionError', (tester) async {
      expect(
        () => EdenMedicationList(medications: [
          MedFixtures.metforminPatient001,
          MedFixtures.lisinoprilPatient002,
        ]),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('all-same-patient list → no exception', (tester) async {
      await tester.pumpWidget(wrap(EdenMedicationList(
        medications: MedFixtures.t2dmHtnCombo,
      )));
      expect(tester.takeException(), isNull);
    });
  });
}
