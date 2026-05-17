// TDD test file for EdenVitalsRow.
//
// Outside-in order:
//   1. Static rendering — single tile (label/value/unit).
//   2. Reference-range coloring via EdenStatusPalette (or fallback).
//   3. BP composite ('128/82').
//   4. Trend arrow (up/down/flat/none) + color = tint.
//   5. Empty / partial state.
//   6. Multi-vital strip (real patient scenarios).
//   7. Responsive (iPhone-narrow ≥390pt) + horizontal scroll.
//   8. Timestamp display.
//   9. HIPAA isolation (multitenancy-equivalent per global TDD Playbook habit 6).
//  10. Catalog smoke test.

import 'package:eden_ui_flutter/src/theme/eden_status_palette.dart';
import 'package:eden_ui_flutter/src/theme/eden_theme.dart';
import 'package:eden_ui_flutter/src/theme/eden_theme_profile.dart';
import 'package:eden_ui_flutter/src/widgets/eden_vitals_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_vitals_row_fixtures.dart';

void main() {
  // wrap() helper — matches obj 005 pattern.
  Widget wrap(
    Widget child, {
    double width = 390,
    double height = 200,
    EdenThemeProfile profile = EdenThemeProfile.medicalInstitutional,
  }) {
    final theme = EdenTheme.light(profile: profile);
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );
  }

  group('EdenVitalsRow — single-tile static rendering', () {
    testWidgets('BP tile renders label "BP", value "128/82", unit "mmHg"',
        (tester) async {
      await tester.pumpWidget(wrap(EdenVitalsRow(vitals: [
        VitalsFixtures.bpNormal,
      ])));
      expect(find.text('BP'), findsOneWidget);
      expect(find.text('128/82'), findsOneWidget);
      expect(find.text('mmHg'), findsOneWidget);
    });

    testWidgets('HR tile renders "HR" / "72" / "bpm"', (tester) async {
      await tester.pumpWidget(wrap(EdenVitalsRow(vitals: [
        VitalsFixtures.heartRateNormal,
      ])));
      expect(find.text('HR'), findsOneWidget);
      expect(find.text('72'), findsOneWidget);
      expect(find.text('bpm'), findsOneWidget);
    });

    testWidgets('Temp tile renders "Temp" / "98.6" / "°F"', (tester) async {
      await tester.pumpWidget(wrap(EdenVitalsRow(vitals: [
        VitalsFixtures.tempNormal,
      ])));
      expect(find.text('Temp'), findsOneWidget);
      expect(find.text('98.6'), findsOneWidget);
      expect(find.text('°F'), findsOneWidget);
    });

    testWidgets('SpO2 tile renders "SpO2" / "98" / "%"', (tester) async {
      await tester.pumpWidget(wrap(EdenVitalsRow(vitals: [
        VitalsFixtures.spo2Normal,
      ])));
      expect(find.text('SpO2'), findsOneWidget);
      expect(find.text('98'), findsOneWidget);
      expect(find.text('%'), findsOneWidget);
    });
  });

  group('EdenVitalsRow — reference-range coloring', () {
    Color bgOfTile(WidgetTester tester) {
      // First _VitalsTile root Container holds the tint surface.
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(EdenVitalsRow),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      return decoration.color!;
    }

    testWidgets('BP normal (128/82) → success surface', (tester) async {
      await tester.pumpWidget(wrap(EdenVitalsRow(vitals: [
        VitalsFixtures.bpNormal,
      ])));
      final palette = EdenStatusPalette.forProfile(
        EdenThemeProfile.medicalInstitutional,
      );
      expect(bgOfTile(tester), palette.successBg);
    });

    testWidgets('BP stage-1 (148/94) → warning surface', (tester) async {
      await tester.pumpWidget(wrap(EdenVitalsRow(vitals: [
        VitalsFixtures.bpHypertensiveCaution,
      ])));
      final palette = EdenStatusPalette.forProfile(
        EdenThemeProfile.medicalInstitutional,
      );
      expect(bgOfTile(tester), palette.warningBg);
    });

    testWidgets('BP crisis (192/124) → danger surface', (tester) async {
      await tester.pumpWidget(wrap(EdenVitalsRow(vitals: [
        VitalsFixtures.bpHypertensiveCrisis,
      ])));
      final palette = EdenStatusPalette.forProfile(
        EdenThemeProfile.medicalInstitutional,
      );
      expect(bgOfTile(tester), palette.dangerBg);
    });

    testWidgets('BP hypotensive (78/52) → danger surface', (tester) async {
      await tester.pumpWidget(wrap(EdenVitalsRow(vitals: [
        VitalsFixtures.bpHypotensive,
      ])));
      final palette = EdenStatusPalette.forProfile(
        EdenThemeProfile.medicalInstitutional,
      );
      expect(bgOfTile(tester), palette.dangerBg);
    });

    testWidgets('SpO2 critical (87%, criticalMin=90) → danger surface',
        (tester) async {
      await tester.pumpWidget(wrap(EdenVitalsRow(vitals: [
        VitalsFixtures.spo2Critical,
      ])));
      final palette = EdenStatusPalette.forProfile(
        EdenThemeProfile.medicalInstitutional,
      );
      expect(bgOfTile(tester), palette.dangerBg);
    });

    testWidgets('Temp febrile (101.8°F, ref max 99.5) → warning surface',
        (tester) async {
      await tester.pumpWidget(wrap(EdenVitalsRow(vitals: [
        VitalsFixtures.tempFebrile,
      ])));
      final palette = EdenStatusPalette.forProfile(
        EdenThemeProfile.medicalInstitutional,
      );
      expect(bgOfTile(tester), palette.warningBg);
    });

    testWidgets('HR with no range → neutral surface', (tester) async {
      await tester.pumpWidget(wrap(EdenVitalsRow(vitals: [
        VitalsFixtures.heartRateNoRange,
      ])));
      final palette = EdenStatusPalette.forProfile(
        EdenThemeProfile.medicalInstitutional,
      );
      expect(bgOfTile(tester), palette.neutralBg);
    });
  });

  group('EdenVitalsRow — empty / partial state', () {
    testWidgets('empty list renders without exception', (tester) async {
      await tester.pumpWidget(wrap(EdenVitalsRow(vitals: [])));
      expect(tester.takeException(), isNull);
      // No tile labels exist.
      expect(find.text('BP'), findsNothing);
    });

    testWidgets('SpO2 with no reading renders "—" placeholder', (tester) async {
      await tester.pumpWidget(wrap(EdenVitalsRow(vitals: [
        VitalsFixtures.spo2NoReading,
      ])));
      expect(find.text('—'), findsOneWidget);
      // Unit still shown.
      expect(find.text('%'), findsOneWidget);
      // No trend arrow.
      expect(find.byIcon(Icons.arrow_upward), findsNothing);
      expect(find.byIcon(Icons.arrow_downward), findsNothing);
      expect(find.byIcon(Icons.remove), findsNothing);
    });
  });

  group('EdenVitalsRow — trend arrow', () {
    testWidgets('priorValue lower than current → up arrow', (tester) async {
      await tester.pumpWidget(wrap(EdenVitalsRow(vitals: [
        VitalsFixtures.bpTrendingUp,
      ])));
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('priorValue higher than current → down arrow', (tester) async {
      await tester.pumpWidget(wrap(EdenVitalsRow(vitals: [
        VitalsFixtures.bpTrendingDown,
      ])));
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('priorValue ≈ current (within 5%) → flat arrow', (tester) async {
      await tester.pumpWidget(wrap(EdenVitalsRow(vitals: [
        VitalsFixtures.bpFlat,
      ])));
      expect(find.byIcon(Icons.remove), findsOneWidget);
    });

    testWidgets('priorValue null → no arrow', (tester) async {
      await tester.pumpWidget(wrap(EdenVitalsRow(vitals: [
        VitalsFixtures.bpNoPrior,
      ])));
      expect(find.byIcon(Icons.arrow_upward), findsNothing);
      expect(find.byIcon(Icons.arrow_downward), findsNothing);
      expect(find.byIcon(Icons.remove), findsNothing);
    });

    testWidgets('arrow color = tile tint (warning tile → warning fg)',
        (tester) async {
      await tester.pumpWidget(wrap(EdenVitalsRow(vitals: [
        VitalsFixtures.bpTrendingUp, // 148/94 → warning
      ])));
      final palette = EdenStatusPalette.forProfile(
        EdenThemeProfile.medicalInstitutional,
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_upward));
      expect(icon.color, palette.warningFg);
    });
  });

  group('EdenVitalsRow — multi-vital row', () {
    testWidgets('healthyAdultStrip renders 6 tiles', (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenVitalsRow(vitals: VitalsFixtures.healthyAdultStrip),
          width: 1200,
        ),
      );
      expect(find.text('BP'), findsOneWidget);
      expect(find.text('HR'), findsOneWidget);
      expect(find.text('Temp'), findsOneWidget);
      expect(find.text('SpO2'), findsOneWidget);
      expect(find.text('RR'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
    });

    testWidgets('copdFlareStrip: RR + SpO2 warning, others success',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenVitalsRow(vitals: VitalsFixtures.copdFlareStrip),
          width: 1200,
        ),
      );
      final palette = EdenStatusPalette.forProfile(
        EdenThemeProfile.medicalInstitutional,
      );

      // Find the SpO2 tile's containing Container.
      Color bgOfLabel(String label) {
        final tile = find.ancestor(
          of: find.text(label),
          matching: find.byType(Container),
        ).first;
        final c = tester.widget<Container>(tile);
        return (c.decoration as BoxDecoration).color!;
      }

      expect(bgOfLabel('SpO2'), palette.warningBg); // 92% (low caution)
      expect(bgOfLabel('RR'), palette.warningBg); // 28 (elevated)
      expect(bgOfLabel('BP'), palette.successBg);
      expect(bgOfLabel('Temp'), palette.successBg);
    });
  });

  group('EdenVitalsRow — responsive (iPhone-narrow ≥390pt)', () {
    testWidgets('390pt baseline renders all 6 tiles + horizontal scrollable',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenVitalsRow(vitals: VitalsFixtures.healthyAdultStrip),
          width: 390,
        ),
      );
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      final scroller = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scroller.scrollDirection, Axis.horizontal);

      // All 6 tile labels present (some may be off-screen, but built).
      expect(find.text('BP'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);

      // No layout overflow exception.
      expect(tester.takeException(), isNull);
    });

    testWidgets('1200pt wide: scroll is no-op (all tiles fit)',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenVitalsRow(vitals: VitalsFixtures.healthyAdultStrip),
          width: 1200,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('BP'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
    });
  });

  group('EdenVitalsRow — timestamps', () {
    testWidgets('showTimestamps:false (default) → no "as of" caption',
        (tester) async {
      final vital = EdenVitalSign(
        patientId: 'pt-001',
        kind: EdenVitalKind.heartRate,
        unit: 'bpm',
        value: 72,
        recordedAt: DateTime.now().subtract(const Duration(minutes: 12)),
      );
      await tester.pumpWidget(wrap(EdenVitalsRow(vitals: [vital])));
      expect(find.textContaining('as of'), findsNothing);
    });

    testWidgets('showTimestamps:true → "as of" caption renders', (tester) async {
      final vital = EdenVitalSign(
        patientId: 'pt-001',
        kind: EdenVitalKind.heartRate,
        unit: 'bpm',
        value: 72,
        recordedAt: DateTime.now().subtract(const Duration(minutes: 12)),
      );
      await tester.pumpWidget(
        wrap(EdenVitalsRow(vitals: [vital], showTimestamps: true)),
      );
      expect(find.textContaining('as of'), findsOneWidget);
    });
  });

  group(
      'EdenVitalsRow — HIPAA isolation (multitenancy-equivalent per global TDD Playbook habit 6)',
      () {
    testWidgets('mixed patientId vitals → AssertionError', (tester) async {
      expect(
        () => EdenVitalsRow(vitals: const [
          VitalsFixtures.bpPatient001,
          VitalsFixtures.hrPatient002,
        ]),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets(
        'mixed list + explicit mismatched patientId → AssertionError',
        (tester) async {
      expect(
        () => EdenVitalsRow(
          vitals: const [
            VitalsFixtures.bpPatient001, // pt-001
            VitalsFixtures.hrPatient002, // pt-002
          ],
          patientId: 'pt-001',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('all-same-patient list renders without exception',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenVitalsRow(
            vitals: VitalsFixtures.healthyAdultStrip,
            patientId: 'pt-001',
          ),
          width: 1200,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('BP'), findsOneWidget);
    });

    testWidgets(
        'all-same-patient list, no explicit patientId → resolves to vitals.first.patientId',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenVitalsRow(vitals: VitalsFixtures.healthyAdultStrip),
          width: 1200,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('BP'), findsOneWidget);
    });

    testWidgets('empty list with patientId set does not throw',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenVitalsRow(vitals: [], patientId: 'pt-001')),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenVitalsRow — value formatting', () {
    testWidgets('integer values render without decimal (HR=72, not 72.0)',
        (tester) async {
      await tester.pumpWidget(wrap(EdenVitalsRow(vitals: [
        VitalsFixtures.heartRateNormal,
      ])));
      expect(find.text('72'), findsOneWidget);
      expect(find.text('72.0'), findsNothing);
    });

    testWidgets('decimal values render with one decimal (Temp=98.6)',
        (tester) async {
      await tester.pumpWidget(wrap(EdenVitalsRow(vitals: [
        VitalsFixtures.tempNormal,
      ])));
      expect(find.text('98.6'), findsOneWidget);
    });
  });
}
