// TDD test file for EdenProblemList.

import 'package:eden_ui_flutter/src/theme/eden_theme.dart';
import 'package:eden_ui_flutter/src/theme/eden_theme_profile.dart';
import 'package:eden_ui_flutter/src/widgets/eden_problem_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_problem_list_fixtures.dart';

void main() {
  Widget wrap(Widget child, {double width = 600, double height = 700}) {
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

  group('EdenProblemList — single-row rendering', () {
    testWidgets('code (mono) + description on line 1; onset+provider line 2',
        (tester) async {
      await tester.pumpWidget(wrap(EdenProblemList(
        conditions: [ProblemFixtures.t2dm],
      )));
      expect(find.text('E11.9'), findsOneWidget);
      expect(find.textContaining('Type 2 diabetes mellitus'), findsOneWidget);
      expect(find.textContaining('Onset 2022-08-14'), findsOneWidget);
      expect(find.textContaining('Dr. Chen'), findsOneWidget);
    });
  });

  group('EdenProblemList — status pill', () {
    testWidgets('active → "Active" pill', (tester) async {
      await tester.pumpWidget(wrap(EdenProblemList(
        conditions: [ProblemFixtures.t2dm],
      )));
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('recurrence → "Recurrence" pill', (tester) async {
      await tester.pumpWidget(wrap(EdenProblemList(
        conditions: [ProblemFixtures.copdRecurrence],
      )));
      expect(find.text('Recurrence'), findsOneWidget);
    });

    testWidgets('resolved + showResolved:true → "Resolved" pill',
        (tester) async {
      await tester.pumpWidget(wrap(EdenProblemList(
        conditions: [ProblemFixtures.appendicitisResolved],
        showResolved: true,
      )));
      expect(find.text('Resolved'), findsOneWidget);
    });

    testWidgets('inactive + showResolved:true → "Inactive" pill',
        (tester) async {
      await tester.pumpWidget(wrap(EdenProblemList(
        conditions: [ProblemFixtures.htnInactive],
        showResolved: true,
      )));
      expect(find.text('Inactive'), findsOneWidget);
    });
  });

  group('EdenProblemList — verification status', () {
    testWidgets('provisional → "(provisional)" italic suffix', (tester) async {
      await tester.pumpWidget(wrap(EdenProblemList(
        conditions: [ProblemFixtures.chestPainProvisional],
      )));
      expect(find.text(' (provisional)'), findsOneWidget);
    });

    testWidgets('refuted (with status=inactive, showResolved:true) → strikethrough description',
        (tester) async {
      await tester.pumpWidget(wrap(EdenProblemList(
        conditions: [ProblemFixtures.gerdRefuted],
        showResolved: true,
      )));
      final t = tester.widget<Text>(find.text('— GERD without esophagitis'));
      expect(t.style?.decoration, TextDecoration.lineThrough);
    });
  });

  group('EdenProblemList — filtering', () {
    testWidgets('default (showResolved:false): only active + recurrence render',
        (tester) async {
      await tester.pumpWidget(wrap(EdenProblemList(
        conditions: ProblemFixtures.polychronic,
      )));
      // 5 conditions, of which: t2dm/htn/hyperlipidemia=active, appendicitis=resolved,
      // copd=recurrence → 4 should render. Resolved+inactive filtered.
      expect(find.text('Resolved'), findsNothing);
      expect(find.text('Inactive'), findsNothing);
      expect(find.text('Active'), findsAtLeastNWidgets(1));
      expect(find.text('Recurrence'), findsOneWidget);
    });

    testWidgets('showResolved:true → all conditions render', (tester) async {
      await tester.pumpWidget(wrap(EdenProblemList(
        conditions: ProblemFixtures.polychronic,
        showResolved: true,
      )));
      expect(find.text('Resolved'), findsOneWidget);
      expect(find.text('Recurrence'), findsOneWidget);
    });
  });

  group('EdenProblemList — sorting', () {
    testWidgets('default sortAscending:false → most recent onset first',
        (tester) async {
      await tester.pumpWidget(wrap(EdenProblemList(
        conditions: ProblemFixtures.polychronicPatient,
      )));
      // polychronicPatient onsetDates:
      //   t2dm: 2022-08-14, htn: 2021-03-02, hyperlipidemia: 2023-05-10,
      //   gerd: 2024-01-18, osa: 2024-09-01
      // Descending → osa first
      final codes = tester.widgetList<Text>(find.byWidgetPredicate(
        (w) => w is Text && (w.data?.startsWith('G47.33') == true ||
            w.data?.startsWith('K21.9') == true ||
            w.data?.startsWith('E78.5') == true ||
            w.data?.startsWith('E11.9') == true ||
            w.data?.startsWith('I10') == true),
      ));
      expect(codes.first.data, 'G47.33'); // osa first
    });

    testWidgets('sortAscending:true → oldest onset first', (tester) async {
      await tester.pumpWidget(wrap(EdenProblemList(
        conditions: ProblemFixtures.polychronicPatient,
        sortAscending: true,
      )));
      // ascending → I10 (htn 2021) first
      final codes = tester.widgetList<Text>(find.byWidgetPredicate(
        (w) => w is Text && (w.data?.startsWith('G47.33') == true ||
            w.data?.startsWith('K21.9') == true ||
            w.data?.startsWith('E78.5') == true ||
            w.data?.startsWith('E11.9') == true ||
            w.data?.startsWith('I10') == true),
      ));
      expect(codes.first.data, 'I10');
    });

    testWidgets('null onsetDate sorts last', (tester) async {
      await tester.pumpWidget(wrap(EdenProblemList(
        conditions: ProblemFixtures.nullOnsetMixed,
      )));
      // descending: t2dm (2022) first, null F33.0 last.
      final codes = tester.widgetList<Text>(find.byWidgetPredicate(
        (w) => w is Text && (w.data == 'E11.9' || w.data == 'F33.0'),
      ));
      expect(codes.last.data, 'F33.0');
    });
  });

  group('EdenProblemList — multi-condition', () {
    testWidgets('polychronic patient: 5 conditions all active', (tester) async {
      await tester.pumpWidget(wrap(EdenProblemList(
        conditions: ProblemFixtures.polychronicPatient,
      )));
      expect(find.textContaining('Type 2 diabetes mellitus'), findsOneWidget);
      expect(find.textContaining('Essential (primary) hypertension'),
          findsOneWidget);
      expect(find.textContaining('Hyperlipidemia'), findsOneWidget);
    });
  });

  group('EdenProblemList — empty state', () {
    testWidgets('empty list → "No active problems"', (tester) async {
      await tester.pumpWidget(wrap(EdenProblemList(conditions: const [])));
      expect(find.text('No active problems'), findsOneWidget);
    });

    testWidgets(
        'only resolved + showResolved:false → empty-state text rendered',
        (tester) async {
      await tester.pumpWidget(wrap(EdenProblemList(
        conditions: [ProblemFixtures.appendicitisResolved],
      )));
      expect(find.text('No active problems'), findsOneWidget);
    });
  });

  group('EdenProblemList — callback wiring', () {
    testWidgets('onProblemTap fires with correct condition', (tester) async {
      EdenCondition? tapped;
      await tester.pumpWidget(wrap(EdenProblemList(
        conditions: [ProblemFixtures.t2dm],
        onProblemTap: (c) => tapped = c,
      )));
      await tester.tap(find.text('E11.9'));
      await tester.pump();
      expect(tapped?.id, 'cond-001');
    });
  });

  group(
      'EdenProblemList — HIPAA isolation (multitenancy-equivalent per global TDD Playbook habit 6)',
      () {
    testWidgets('mixed patientId → AssertionError', (tester) async {
      expect(
        () => EdenProblemList(conditions: [
          ProblemFixtures.t2dmPatient001,
          ProblemFixtures.htnPatient002,
        ]),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('all-same-patient list → no exception', (tester) async {
      await tester.pumpWidget(wrap(EdenProblemList(
        conditions: ProblemFixtures.polychronicPatient,
      )));
      expect(tester.takeException(), isNull);
    });
  });
}
