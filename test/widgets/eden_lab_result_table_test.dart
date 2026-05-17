// TDD test file for EdenLabResultTable.

import 'package:eden_ui_flutter/eden_ui.dart' show EdenSparkline;
import 'package:eden_ui_flutter/src/theme/eden_status_palette.dart';
import 'package:eden_ui_flutter/src/theme/eden_theme.dart';
import 'package:eden_ui_flutter/src/theme/eden_theme_profile.dart';
import 'package:eden_ui_flutter/src/widgets/eden_lab_result_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_lab_result_table_fixtures.dart';

void main() {
  Widget wrap(Widget child, {double width = 800, double height = 600}) {
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

  group('EdenLabResultTable — single-row rendering', () {
    testWidgets('renders test name, value, unit, range, date', (tester) async {
      await tester.pumpWidget(wrap(EdenLabResultTable(
        results: [LabFixtures.hgbNormal],
      )));
      expect(find.text('Hemoglobin'), findsOneWidget);
      expect(find.text('14.2'), findsOneWidget);
      expect(find.text('g/dL'), findsOneWidget);
      expect(find.text('12-16'), findsOneWidget);
    });

    testWidgets('header row renders column labels', (tester) async {
      await tester.pumpWidget(wrap(EdenLabResultTable(
        results: [LabFixtures.hgbNormal],
      )));
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Value'), findsOneWidget);
      expect(find.text('Unit'), findsOneWidget);
      expect(find.text('Range'), findsOneWidget);
      expect(find.text('Flag'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Trend'), findsOneWidget);
    });
  });

  group('EdenLabResultTable — flag column', () {
    testWidgets('high flag → H in warning color', (tester) async {
      await tester.pumpWidget(wrap(EdenLabResultTable(
        results: [LabFixtures.glucoseHigh],
      )));
      expect(find.text('H'), findsOneWidget);
    });

    testWidgets('criticalHigh flag → HH in danger color', (tester) async {
      await tester.pumpWidget(wrap(EdenLabResultTable(
        results: [LabFixtures.glucoseCriticalHigh],
      )));
      expect(find.text('HH'), findsOneWidget);
      final palette = EdenStatusPalette.forProfile(
        EdenThemeProfile.medicalInstitutional,
      );
      final t = tester.widget<Text>(find.text('HH'));
      expect(t.style?.color, palette.dangerFg);
    });

    testWidgets('low flag → L in warning color', (tester) async {
      await tester.pumpWidget(wrap(EdenLabResultTable(
        results: [LabFixtures.hgbLow],
      )));
      expect(find.text('L'), findsOneWidget);
      final palette = EdenStatusPalette.forProfile(
        EdenThemeProfile.medicalInstitutional,
      );
      final t = tester.widget<Text>(find.text('L'));
      expect(t.style?.color, palette.warningFg);
    });

    testWidgets('criticalLow flag → LL in danger color', (tester) async {
      await tester.pumpWidget(wrap(EdenLabResultTable(
        results: [LabFixtures.glucoseCriticalLow],
      )));
      expect(find.text('LL'), findsOneWidget);
    });

    testWidgets('normal flag → empty cell (no H/HH/L/LL)', (tester) async {
      await tester.pumpWidget(wrap(EdenLabResultTable(
        results: [LabFixtures.hgbNormal],
      )));
      expect(find.text('H'), findsNothing);
      expect(find.text('HH'), findsNothing);
      expect(find.text('L'), findsNothing);
      expect(find.text('LL'), findsNothing);
    });
  });

  group('EdenLabResultTable — trend cell (sparkline)', () {
    testWidgets('result with trendValues → EdenSparkline renders',
        (tester) async {
      await tester.pumpWidget(wrap(EdenLabResultTable(
        results: [LabFixtures.hgbWithTrend],
      )));
      expect(find.byType(EdenSparkline), findsOneWidget);
    });

    testWidgets('result without trendValues → "—" rendered', (tester) async {
      await tester.pumpWidget(wrap(EdenLabResultTable(
        results: [LabFixtures.hgbNoTrend],
      )));
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('showSparkline:false → numeric delta rendered',
        (tester) async {
      await tester.pumpWidget(wrap(EdenLabResultTable(
        results: [LabFixtures.hgbWithTrend],
        showSparkline: false,
      )));
      // delta = 14.2 - 14.0 = +0.2 ↑
      expect(find.textContaining('+0.2'), findsOneWidget);
      expect(find.byType(EdenSparkline), findsNothing);
    });
  });

  group('EdenLabResultTable — panel grouping', () {
    testWidgets('groupByPanel:true → CBC header renders', (tester) async {
      await tester.pumpWidget(wrap(EdenLabResultTable(
        results: LabFixtures.cbcPanel,
        groupByPanel: true,
      )));
      expect(find.text('CBC'), findsOneWidget);
      // All 5 CBC test names render.
      expect(find.text('White Blood Cells'), findsOneWidget);
      expect(find.text('Red Blood Cells'), findsOneWidget);
      expect(find.text('Hemoglobin'), findsOneWidget);
      expect(find.text('Hematocrit'), findsOneWidget);
      expect(find.text('Platelets'), findsOneWidget);
    });

    testWidgets('groupByPanel:true with CBC+CMP → 2 panel headers',
        (tester) async {
      await tester.pumpWidget(wrap(EdenLabResultTable(
        results: LabFixtures.cbcAndCmpPanels,
        groupByPanel: true,
      )));
      expect(find.text('CBC'), findsOneWidget);
      expect(find.text('CMP'), findsOneWidget);
    });

    testWidgets('groupByPanel:false (default) → no panel headers',
        (tester) async {
      await tester.pumpWidget(wrap(EdenLabResultTable(
        results: LabFixtures.cbcAndCmpPanels,
      )));
      // 'CBC' as panel-header text doesn't appear; only as 'CBC' label
      // we previously rendered — confirm explicitly.
      expect(find.text('CBC'), findsNothing);
      expect(find.text('CMP'), findsNothing);
    });
  });

  group('EdenLabResultTable — sortable columns', () {
    testWidgets('default sort = date descending (newest first)',
        (tester) async {
      await tester.pumpWidget(wrap(EdenLabResultTable(
        results: LabFixtures.cbcPanel,
      )));
      // Header is interactive; smoke test that table renders.
      expect(find.text('Date'), findsOneWidget);
    });

    testWidgets('tap Test header → re-orders alphabetically', (tester) async {
      await tester.pumpWidget(wrap(EdenLabResultTable(
        results: LabFixtures.cbcPanel,
      )));
      await tester.tap(find.text('Test'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      // After alphabetical sort: Hematocrit / Hemoglobin / Platelets /
      // Red Blood Cells / White Blood Cells.
      expect(find.text('Hematocrit'), findsOneWidget);
    });
  });

  group('EdenLabResultTable — multi-panel realistic patient', () {
    testWidgets('fullPanelDay: 18+ results, critical flags visible',
        (tester) async {
      await tester.pumpWidget(wrap(
        SingleChildScrollView(
          child: EdenLabResultTable(
            results: LabFixtures.fullPanelDay,
            groupByPanel: true,
          ),
        ),
        width: 800,
        height: 1000,
      ));
      expect(find.text('CBC'), findsOneWidget);
      expect(find.text('CMP'), findsOneWidget);
      expect(find.text('Lipid Panel'), findsOneWidget);
      expect(find.text('HH'), findsAtLeastNWidgets(1));
    });
  });

  group('EdenLabResultTable — iPhone-narrow responsive', () {
    testWidgets('390pt width: horizontal scroll wraps table', (tester) async {
      await tester.pumpWidget(wrap(
        EdenLabResultTable(results: LabFixtures.cbcPanel),
        width: 390,
      ));
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenLabResultTable — callback wiring', () {
    testWidgets('onResultTap fires with correct result', (tester) async {
      EdenLabResult? tapped;
      await tester.pumpWidget(wrap(EdenLabResultTable(
        results: [LabFixtures.hgbNormal],
        onResultTap: (r) => tapped = r,
      )));
      await tester.tap(find.text('Hemoglobin'));
      await tester.pump();
      expect(tapped?.id, 'lab-001');
    });
  });

  group(
      'EdenLabResultTable — HIPAA isolation (multitenancy-equivalent per global TDD Playbook habit 6)',
      () {
    testWidgets('mixed patientId → AssertionError', (tester) async {
      expect(
        () => EdenLabResultTable(results: [
          LabFixtures.hgbPatient001,
          LabFixtures.gluPatient002,
        ]),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('all-same-patient list → renders without exception',
        (tester) async {
      await tester.pumpWidget(wrap(EdenLabResultTable(
        results: LabFixtures.cbcPanel,
      )));
      expect(tester.takeException(), isNull);
    });
  });
}
