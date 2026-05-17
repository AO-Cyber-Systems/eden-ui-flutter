// TDD test file for EdenAllergyList.

import 'package:eden_ui_flutter/src/theme/eden_theme.dart';
import 'package:eden_ui_flutter/src/theme/eden_theme_profile.dart';
import 'package:eden_ui_flutter/src/widgets/eden_allergy_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_allergy_list_fixtures.dart';

void main() {
  Widget wrap(Widget child, {double width = 500, double height = 700}) {
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

  group('EdenAllergyList — single-row rendering', () {
    testWidgets('icon + allergen + severity pill on line 1', (tester) async {
      await tester.pumpWidget(wrap(EdenAllergyList(
        allergies: [AllergyFixtures.penicillinAnaphylaxis],
      )));
      expect(find.text('Penicillin'), findsOneWidget);
      expect(find.byIcon(Icons.medication_outlined), findsOneWidget);
      expect(find.text('Severe'), findsAtLeastNWidgets(1));
    });

    testWidgets('line 2 renders severity + verification + verified-by',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAllergyList(
        allergies: [AllergyFixtures.penicillinAnaphylaxis],
      )));
      expect(find.textContaining('Confirmed'), findsOneWidget);
      expect(find.textContaining('Dr. Chen'), findsOneWidget);
    });
  });

  group('EdenAllergyList — severity pills', () {
    testWidgets('lifeThreatening → "Life-threatening" pill', (tester) async {
      await tester.pumpWidget(wrap(EdenAllergyList(
        allergies: [AllergyFixtures.peanutLifeThreatening],
      )));
      expect(find.text('Life-threatening'), findsAtLeastNWidgets(1));
    });

    testWidgets('moderate → "Moderate" pill', (tester) async {
      await tester.pumpWidget(wrap(EdenAllergyList(
        allergies: [AllergyFixtures.sulfaRashModerate],
      )));
      expect(find.text('Moderate'), findsAtLeastNWidgets(1));
    });

    testWidgets('mild → "Mild" pill', (tester) async {
      await tester.pumpWidget(wrap(EdenAllergyList(
        allergies: [AllergyFixtures.codeineMildNausea],
      )));
      expect(find.text('Mild'), findsAtLeastNWidgets(1));
    });
  });

  group('EdenAllergyList — criticality banner (non-dismissible)', () {
    testWidgets('high criticality → banner renders with allergen + reaction',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAllergyList(
        allergies: [AllergyFixtures.penicillinAnaphylaxis],
      )));
      expect(find.textContaining('HIGH-CRITICALITY'), findsOneWidget);
      expect(find.textContaining('Penicillin (Anaphylaxis)'), findsOneWidget);
    });

    testWidgets('banner has NO close icon (non-dismissible)', (tester) async {
      await tester.pumpWidget(wrap(EdenAllergyList(
        allergies: [AllergyFixtures.penicillinAnaphylaxis],
      )));
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('only low criticality → NO banner', (tester) async {
      await tester.pumpWidget(wrap(EdenAllergyList(
        allergies: [AllergyFixtures.codeineMildNausea],
      )));
      expect(find.textContaining('HIGH-CRITICALITY'), findsNothing);
    });

    testWidgets('two high criticality → banner lists both', (tester) async {
      await tester.pumpWidget(wrap(EdenAllergyList(
        allergies: [
          AllergyFixtures.penicillinAnaphylaxis,
          AllergyFixtures.latexHivesHigh,
        ],
      )));
      expect(find.textContaining('Penicillin (Anaphylaxis)'), findsOneWidget);
      expect(find.textContaining('Latex (Hives)'), findsOneWidget);
    });

    testWidgets('5+ high criticality → banner shows first 3 + "(+N more)"',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAllergyList(
        allergies: AllergyFixtures.fiveHighCriticality,
      )));
      expect(find.textContaining('+2 more'), findsOneWidget);
    });
  });

  group('EdenAllergyList — type icon prefix', () {
    testWidgets('medication → Icons.medication_outlined', (tester) async {
      await tester.pumpWidget(wrap(EdenAllergyList(
        allergies: [AllergyFixtures.penicillinAnaphylaxis],
      )));
      expect(find.byIcon(Icons.medication_outlined), findsOneWidget);
    });

    testWidgets('food → Icons.restaurant_outlined', (tester) async {
      await tester.pumpWidget(wrap(EdenAllergyList(
        allergies: [AllergyFixtures.peanutLifeThreatening],
      )));
      expect(find.byIcon(Icons.restaurant_outlined), findsOneWidget);
    });

    testWidgets('environmental → Icons.eco_outlined', (tester) async {
      await tester.pumpWidget(wrap(EdenAllergyList(
        allergies: [AllergyFixtures.pollenSeasonalMild],
      )));
      expect(find.byIcon(Icons.eco_outlined), findsOneWidget);
    });
  });

  group('EdenAllergyList — verification status', () {
    testWidgets('unconfirmed → italic "Unconfirmed" rendered', (tester) async {
      await tester.pumpWidget(wrap(EdenAllergyList(
        allergies: [AllergyFixtures.shellfishUnconfirmed],
      )));
      expect(find.textContaining('Unconfirmed'), findsOneWidget);
    });

    testWidgets('refuted → strikethrough description', (tester) async {
      await tester.pumpWidget(wrap(EdenAllergyList(
        allergies: [AllergyFixtures.penicillinRefuted],
      )));
      final t = tester.widget<Text>(find.text('Penicillin'));
      expect(t.style?.decoration, TextDecoration.lineThrough);
    });
  });

  group('EdenAllergyList — filtering', () {
    testWidgets('default (showInactive:false): only active render',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAllergyList(
        allergies: AllergyFixtures.mixedActiveAndInactive,
      )));
      // 5 allergies, 2 inactive → 3 active render
      expect(find.text('Penicillin'), findsOneWidget);
      expect(find.text('Codeine'), findsOneWidget);
      expect(find.text('Sulfa drugs'), findsOneWidget);
      expect(find.textContaining('Aspirin'), findsNothing);
    });

    testWidgets('showInactive:true → all render with strikethrough on inactive',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAllergyList(
        allergies: AllergyFixtures.mixedActiveAndInactive,
        showInactive: true,
      )));
      expect(find.textContaining('Aspirin'), findsOneWidget);
    });
  });

  group('EdenAllergyList — empty / NKDA state', () {
    testWidgets('empty list → "No known drug allergies (NKDA)" rendered',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAllergyList(allergies: const [])));
      expect(find.text('No known drug allergies (NKDA)'), findsOneWidget);
    });

    testWidgets(
        'only-inactive + showInactive:false → NKDA caption rendered',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAllergyList(
        allergies: [AllergyFixtures.inactiveAllergyOnly],
      )));
      expect(find.text('No known drug allergies (NKDA)'), findsOneWidget);
    });
  });

  group('EdenAllergyList — multi-allergy realistic patient', () {
    testWidgets('multiAllergyElderly: 4 rows + banner with 3 high-crit',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenAllergyList(allergies: AllergyFixtures.multiAllergyElderly),
        width: 500,
        height: 900,
      ));
      expect(find.textContaining('HIGH-CRITICALITY'), findsOneWidget);
      expect(find.text('Penicillin'), findsOneWidget);
      expect(find.text('Codeine'), findsOneWidget);
      expect(find.text('Latex'), findsOneWidget);
      expect(find.text('Peanuts'), findsOneWidget);
    });
  });

  group('EdenAllergyList — callback wiring', () {
    testWidgets('onAllergyTap fires with correct allergy', (tester) async {
      EdenAllergyIntolerance? tapped;
      await tester.pumpWidget(wrap(EdenAllergyList(
        allergies: [AllergyFixtures.penicillinAnaphylaxis],
        onAllergyTap: (a) => tapped = a,
      )));
      await tester.tap(find.text('Penicillin'));
      await tester.pump();
      expect(tapped?.id, 'all-001');
    });
  });

  group(
      'EdenAllergyList — HIPAA isolation (multitenancy-equivalent per global TDD Playbook habit 6)',
      () {
    testWidgets('mixed patientId → AssertionError', (tester) async {
      expect(
        () => EdenAllergyList(allergies: [
          AllergyFixtures.penicillinPatient001,
          AllergyFixtures.peanutPatient002,
        ]),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('all-same-patient list → no exception', (tester) async {
      await tester.pumpWidget(wrap(EdenAllergyList(
        allergies: AllergyFixtures.multiAllergyAdult,
      )));
      expect(tester.takeException(), isNull);
    });
  });
}
