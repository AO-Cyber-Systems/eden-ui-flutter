// TDD test file for EdenPatientChartScaffold.
// Scaffold-level concerns only — composition correctness, tab switching,
// tier responsiveness, HIPAA bleed isolation.

import 'package:eden_ui_flutter/src/theme/eden_theme.dart';
import 'package:eden_ui_flutter/src/theme/eden_theme_profile.dart';
import 'package:eden_ui_flutter/src/widgets/eden_lab_result_table.dart';
import 'package:eden_ui_flutter/src/widgets/eden_medication_list.dart';
import 'package:eden_ui_flutter/src/widgets/eden_patient_chart_scaffold.dart';
import 'package:eden_ui_flutter/src/widgets/eden_tabs.dart';
import 'package:eden_ui_flutter/src/widgets/eden_vitals_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_patient_chart_scaffold_fixtures.dart';

void main() {
  Widget wrap(Widget child, {double width = 1200, double height = 900}) {
    final theme = EdenTheme.light(profile: EdenThemeProfile.medicalInstitutional);
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );
  }

  setUp(() {
    // Default test surface is 800×600. Force wider viewport so
    // Expanded-tier layouts (width ≥ 840pt) can fit.
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize =
        const Size(1600, 1200);
    binding.platformDispatcher.views.first.devicePixelRatio = 1;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  group('EdenPatientChartScaffold — full smoke (Expanded ≥840pt)', () {
    testWidgets('renders 3 panes + header + tabs without exception',
        (tester) async {
      await tester.pumpWidget(wrap(EdenPatientChartScaffold(
        data: ChartFixtures.polychronicPatient5Year,
        patientId: 'pt-001',
      )));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('left-rail')), findsOneWidget);
      expect(find.byKey(const Key('center-pane')), findsOneWidget);
      expect(find.byKey(const Key('right-rail')), findsOneWidget);
    });

    testWidgets('header renders patient name + MRN + age', (tester) async {
      await tester.pumpWidget(wrap(EdenPatientChartScaffold(
        data: ChartFixtures.polychronicPatient5Year,
        patientId: 'pt-001',
      )));
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.textContaining('MRN 123456'), findsOneWidget);
      expect(find.textContaining('y F'), findsOneWidget);
    });
  });

  group('EdenPatientChartScaffold — tab switching', () {
    testWidgets('Overview tab default → vitals row visible', (tester) async {
      await tester.pumpWidget(wrap(EdenPatientChartScaffold(
        data: ChartFixtures.polychronicPatient5Year,
        patientId: 'pt-001',
      )));
      // EdenVitalsRow rendered in center pane (Overview tab is index 0).
      expect(find.byType(EdenVitalsRow), findsAtLeastNWidgets(1));
    });

    testWidgets('tap Labs tab → lab result table visible in center',
        (tester) async {
      await tester.pumpWidget(wrap(EdenPatientChartScaffold(
        data: ChartFixtures.polychronicPatient5Year,
        patientId: 'pt-001',
      )));
      // Tab text appears twice on screen (tab strip + ChartTimeline filter
      // chip on Overview). Tap the EdenTabs descendant only.
      final tabsLabsFinder = find.descendant(
        of: find.byType(EdenTabs),
        matching: find.text('Labs'),
      );
      await tester.tap(tabsLabsFinder);
      await tester.pumpAndSettle();
      expect(find.byType(EdenLabResultTable), findsAtLeastNWidgets(1));
    });

    testWidgets('tap Meds tab → meds list visible in center', (tester) async {
      await tester.pumpWidget(wrap(EdenPatientChartScaffold(
        data: ChartFixtures.polychronicPatient5Year,
        patientId: 'pt-001',
      )));
      final tabsMedsFinder = find.descendant(
        of: find.byType(EdenTabs),
        matching: find.text('Meds'),
      );
      await tester.tap(tabsMedsFinder);
      await tester.pumpAndSettle();
      expect(find.byType(EdenMedicationList), findsAtLeastNWidgets(2));
    });

    testWidgets('onTabChange fires with index', (tester) async {
      int? lastIdx;
      await tester.pumpWidget(wrap(EdenPatientChartScaffold(
        data: ChartFixtures.polychronicPatient5Year,
        patientId: 'pt-001',
        onTabChange: (i) => lastIdx = i,
      )));
      final tabsLabsFinder = find.descendant(
        of: find.byType(EdenTabs),
        matching: find.text('Labs'),
      );
      await tester.tap(tabsLabsFinder);
      await tester.pumpAndSettle();
      expect(lastIdx, 3);
    });
  });

  group('EdenPatientChartScaffold — left rail composition (Expanded)', () {
    testWidgets('left rail shows Problem List / Medications / Allergies',
        (tester) async {
      await tester.pumpWidget(wrap(EdenPatientChartScaffold(
        data: ChartFixtures.polychronicPatient5Year,
        patientId: 'pt-001',
      )));
      // Search within left-rail subtree only — these headers are
      // rendered in the left rail; other panes may have similar text.
      expect(
        find.descendant(
          of: find.byKey(const Key('left-rail')),
          matching: find.text('Problem List'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('left-rail')),
          matching: find.text('Medications'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('left-rail')),
          matching: find.text('Allergies'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('left rail shows PCN high-criticality banner', (tester) async {
      await tester.pumpWidget(wrap(EdenPatientChartScaffold(
        data: ChartFixtures.polychronicPatient5Year,
        patientId: 'pt-001',
      )));
      expect(find.textContaining('HIGH-CRITICALITY'), findsOneWidget);
    });
  });

  group('EdenPatientChartScaffold — right rail composition (Expanded)', () {
    testWidgets('right rail shows Active Alerts + Audit Trail',
        (tester) async {
      await tester.pumpWidget(wrap(EdenPatientChartScaffold(
        data: ChartFixtures.polychronicPatient5Year,
        patientId: 'pt-001',
      )));
      expect(find.text('Active Alerts'), findsOneWidget);
      expect(find.text('Audit Trail'), findsOneWidget);
    });

    testWidgets('aiInsightSlot rendered when non-null in right rail',
        (tester) async {
      await tester.pumpWidget(wrap(EdenPatientChartScaffold(
        data: ChartFixtures.polychronicPatient5Year,
        patientId: 'pt-001',
        aiInsightSlot: Container(key: const Key('ai-slot')),
      )));
      expect(find.byKey(const Key('ai-slot')), findsOneWidget);
      expect(find.text('AI Insights'), findsOneWidget);
    });
  });

  group('EdenPatientChartScaffold — tier responsiveness', () {
    testWidgets('Medium 720pt: no left rail; center + right rail visible',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenPatientChartScaffold(
          data: ChartFixtures.polychronicPatient5Year,
          patientId: 'pt-001',
        ),
        width: 720,
      ));
      expect(find.byKey(const Key('left-rail')), findsNothing);
      expect(find.byKey(const Key('center-pane')), findsOneWidget);
      expect(find.byKey(const Key('right-rail')), findsOneWidget);
    });

    testWidgets('Compact 390pt: no three-pane; compact-pane present',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenPatientChartScaffold(
          data: ChartFixtures.polychronicPatient5Year,
          patientId: 'pt-001',
        ),
        width: 390,
      ));
      expect(find.byKey(const Key('left-rail')), findsNothing);
      expect(find.byKey(const Key('right-rail')), findsNothing);
      expect(find.byKey(const Key('compact-pane')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Compact tier shows Summary tab as first tab',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenPatientChartScaffold(
          data: ChartFixtures.polychronicPatient5Year,
          patientId: 'pt-001',
        ),
        width: 390,
      ));
      expect(find.text('Summary'), findsOneWidget);
    });
  });

  group(
      'EdenPatientChartScaffold — HIPAA bleed isolation (per global TDD Playbook habit 6)',
      () {
    testWidgets('data.patientId mismatch → AssertionError', (tester) async {
      expect(
        () => EdenPatientChartScaffold(
          data: ChartFixtures.polychronicPatient5Year,
          patientId: 'pt-002', // mismatch
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('one med with foreign patientId → AssertionError',
        (tester) async {
      expect(
        () => EdenPatientChartScaffold(
          data: ChartFixtures.polychronicWithBleededMed,
          patientId: 'pt-001',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('matching all-patient data → no exception, no PHI bleed text',
        (tester) async {
      await tester.pumpWidget(wrap(EdenPatientChartScaffold(
        data: ChartFixtures.polychronicPatient5Year,
        patientId: 'pt-001',
      )));
      expect(tester.takeException(), isNull);
      // The bleed-fixture drug name MUST NEVER appear when rendering a
      // properly-isolated scaffold.
      expect(find.textContaining('BLEED-DRUG-PT002'), findsNothing);
    });
  });

  group('EdenPatientChartScaffold — callback wiring', () {
    testWidgets('onPatientHeaderTap fires when header tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(EdenPatientChartScaffold(
        data: ChartFixtures.polychronicPatient5Year,
        patientId: 'pt-001',
        onPatientHeaderTap: () => tapped = true,
      )));
      await tester.tap(find.text('Jane Doe'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}
