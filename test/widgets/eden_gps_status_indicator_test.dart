import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_gps_status_indicator_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  Widget wrapWithScope(Widget child, EdenAppModeController c) {
    return MaterialApp(
      home: Scaffold(
        body: EdenAppModeScope(controller: c, child: child),
      ),
    );
  }

  group('EdenGpsStatusIndicator — pill states (full mode)', () {
    testWidgets('high accuracy → green pill + 5 m + coords', (tester) async {
      await tester.pumpWidget(wrap(EdenGpsStatusIndicator(
        status: EdenGpsStatus.high,
        accuracyMeters: 5,
        position: EdenGpsStatusIndicatorFixtures.nyc,
      )));
      expect(find.text('High'), findsOneWidget);
      expect(find.text('5 m'), findsOneWidget);
      expect(find.text('40.712800, -74.006000'), findsOneWidget);
    });

    testWidgets('moderate accuracy → amber pill + 15 m', (tester) async {
      await tester.pumpWidget(wrap(EdenGpsStatusIndicator(
        status: EdenGpsStatus.moderate,
        accuracyMeters: 15,
        position: EdenGpsStatusIndicatorFixtures.nyc,
      )));
      expect(find.text('Moderate'), findsOneWidget);
      expect(find.text('15 m'), findsOneWidget);
    });

    testWidgets('poor accuracy → red pill + 80 m', (tester) async {
      await tester.pumpWidget(wrap(EdenGpsStatusIndicator(
        status: EdenGpsStatus.poor,
        accuracyMeters: 80,
        position: EdenGpsStatusIndicatorFixtures.nyc,
      )));
      expect(find.text('Poor'), findsOneWidget);
      expect(find.text('80 m'), findsOneWidget);
    });

    testWidgets('unavailable → gray "GPS unavailable" text only (no accuracy or coords)', (tester) async {
      await tester.pumpWidget(wrap(const EdenGpsStatusIndicator(
        status: EdenGpsStatus.unavailable,
      )));
      expect(find.text('GPS unavailable'), findsOneWidget);
      expect(find.textContaining(' m'), findsNothing);
      expect(find.textContaining(','), findsNothing); // no coords
    });
  });

  group('EdenGpsStatusIndicator — accuracy rounding', () {
    testWidgets('3.6 m → 4 m (round half-up)', (tester) async {
      await tester.pumpWidget(wrap(EdenGpsStatusIndicator(
        status: EdenGpsStatus.high,
        accuracyMeters: 3.6,
        position: EdenGpsStatusIndicatorFixtures.nyc,
      )));
      expect(find.text('4 m'), findsOneWidget);
    });

    testWidgets('12.4 m → 12 m (round half-down)', (tester) async {
      await tester.pumpWidget(wrap(EdenGpsStatusIndicator(
        status: EdenGpsStatus.high,
        accuracyMeters: 12.4,
        position: EdenGpsStatusIndicatorFixtures.nyc,
      )));
      expect(find.text('12 m'), findsOneWidget);
    });

    testWidgets('0 → 0 m', (tester) async {
      await tester.pumpWidget(wrap(EdenGpsStatusIndicator(
        status: EdenGpsStatus.high,
        accuracyMeters: 0,
        position: EdenGpsStatusIndicatorFixtures.nyc,
      )));
      expect(find.text('0 m'), findsOneWidget);
    });
  });

  group('EdenGpsStatusIndicator — coordinate formatting', () {
    testWidgets('positive-lat / negative-lng (NYC) → 6 decimals', (tester) async {
      await tester.pumpWidget(wrap(EdenGpsStatusIndicator(
        status: EdenGpsStatus.high,
        accuracyMeters: 5,
        position: EdenGpsStatusIndicatorFixtures.nyc,
      )));
      expect(find.text('40.712800, -74.006000'), findsOneWidget);
    });

    testWidgets('negative-lat / positive-lng (Sydney) → 6 decimals', (tester) async {
      await tester.pumpWidget(wrap(EdenGpsStatusIndicator(
        status: EdenGpsStatus.high,
        accuracyMeters: 5,
        position: EdenGpsStatusIndicatorFixtures.sydney,
      )));
      expect(find.text('-33.856800, 151.215300'), findsOneWidget);
    });
  });

  group('EdenGpsStatusIndicator — mode-aware compression (no compact override)', () {
    testWidgets('fieldCompanion → renders full UI (coords visible)', (tester) async {
      final c = EdenAppModeController(initialMode: EdenAppMode.fieldCompanion);
      await tester.pumpWidget(wrapWithScope(
        EdenGpsStatusIndicator(
          status: EdenGpsStatus.high,
          accuracyMeters: 5,
          position: EdenGpsStatusIndicatorFixtures.nyc,
        ),
        c,
      ));
      expect(find.text('40.712800, -74.006000'), findsOneWidget);
      expect(find.text('5 m'), findsOneWidget);
    });

    testWidgets('admin → renders compact UI (no coords)', (tester) async {
      final c = EdenAppModeController(initialMode: EdenAppMode.admin);
      await tester.pumpWidget(wrapWithScope(
        EdenGpsStatusIndicator(
          status: EdenGpsStatus.high,
          accuracyMeters: 5,
          position: EdenGpsStatusIndicatorFixtures.nyc,
        ),
        c,
      ));
      expect(find.text('40.712800, -74.006000'), findsNothing);
      expect(find.text('5 m'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('askUser → renders full UI (fallback to full)', (tester) async {
      final c = EdenAppModeController(initialMode: EdenAppMode.askUser);
      await tester.pumpWidget(wrapWithScope(
        EdenGpsStatusIndicator(
          status: EdenGpsStatus.high,
          accuracyMeters: 5,
          position: EdenGpsStatusIndicatorFixtures.nyc,
        ),
        c,
      ));
      expect(find.text('40.712800, -74.006000'), findsOneWidget);
    });

    testWidgets('no scope ancestor → renders full UI (graceful default)', (tester) async {
      await tester.pumpWidget(wrap(EdenGpsStatusIndicator(
        status: EdenGpsStatus.high,
        accuracyMeters: 5,
        position: EdenGpsStatusIndicatorFixtures.nyc,
      )));
      expect(find.text('40.712800, -74.006000'), findsOneWidget);
    });
  });

  group('EdenGpsStatusIndicator — compact override', () {
    testWidgets('compact: true overrides fieldCompanion mode (full → compact)', (tester) async {
      final c = EdenAppModeController(initialMode: EdenAppMode.fieldCompanion);
      await tester.pumpWidget(wrapWithScope(
        EdenGpsStatusIndicator(
          status: EdenGpsStatus.high,
          accuracyMeters: 5,
          position: EdenGpsStatusIndicatorFixtures.nyc,
          compact: true,
        ),
        c,
      ));
      expect(find.text('40.712800, -74.006000'), findsNothing);
      expect(find.text('5 m'), findsOneWidget);
    });

    testWidgets('compact: false overrides admin mode (compact → full)', (tester) async {
      final c = EdenAppModeController(initialMode: EdenAppMode.admin);
      await tester.pumpWidget(wrapWithScope(
        EdenGpsStatusIndicator(
          status: EdenGpsStatus.high,
          accuracyMeters: 5,
          position: EdenGpsStatusIndicatorFixtures.nyc,
          compact: false,
        ),
        c,
      ));
      expect(find.text('40.712800, -74.006000'), findsOneWidget);
    });
  });

  group('EdenGpsStatusIndicator — accessibility', () {
    testWidgets('high status exposes "GPS signal: high, accuracy 5 meters"', (tester) async {
      await tester.pumpWidget(wrap(EdenGpsStatusIndicator(
        status: EdenGpsStatus.high,
        accuracyMeters: 5,
        position: EdenGpsStatusIndicatorFixtures.nyc,
      )));
      final sem = tester.getSemantics(find.byType(EdenGpsStatusIndicator));
      expect(sem.label, contains('GPS signal: high'));
      expect(sem.label, contains('accuracy 5 meters'));
    });

    testWidgets('unavailable exposes "GPS unavailable"', (tester) async {
      await tester.pumpWidget(wrap(const EdenGpsStatusIndicator(
        status: EdenGpsStatus.unavailable,
      )));
      final sem = tester.getSemantics(find.byType(EdenGpsStatusIndicator));
      expect(sem.label, contains('GPS unavailable'));
    });
  });

  group('EdenGpsStatusIndicator — iPhone-narrow safety', () {
    testWidgets('390pt: full mode renders without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(EdenGpsStatusIndicator(
        status: EdenGpsStatus.high,
        accuracyMeters: 5,
        position: EdenGpsStatusIndicatorFixtures.nyc,
      )));
      expect(tester.takeException(), isNull);
    });
  });
}
