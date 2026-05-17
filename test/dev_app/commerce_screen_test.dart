import 'package:eden_ui_flutter/dev_app/screens/commerce_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke + integration tests for the Objective 012 dev catalog screen.
///
/// TRD 012-01 bootstraps the screen with the LineItemEditor section across
/// 5 cross-vertical scenarios; subsequent Wave 1-3 TRDs (012-02..012-07)
/// APPEND additional sections beneath placeholder comments. Each TRD adds
/// smoke assertions here for the section it owns.
void main() {
  group('CommerceScreen', () {
    testWidgets('pumps without exception', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CommerceScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders LineItemEditor section with all 5 vertical scenario labels', (tester) async {
      // Wide+tall viewport keeps every Section in a single render so the
      // lazy ListView eagerly resolves all sections.
      tester.view.physicalSize = const Size(1200, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: CommerceScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Retail cart'), findsOneWidget);
      expect(find.text('Medical claim (with discount)'), findsOneWidget);
      expect(find.text('Fuel POD (single-item delivery)'), findsOneWidget);
      expect(find.text('Trades quote (labor + material + tax)'), findsOneWidget);
      expect(find.text('Salon services (read-only checkout preview)'), findsOneWidget);
    });

    testWidgets('renders AggregateKpiStrip section with all 4 vertical scenarios', (tester) async {
      // Wide+tall viewport keeps every Section in a single render so the
      // lazy ListView eagerly resolves all sections.
      tester.view.physicalSize = const Size(1200, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: CommerceScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Sales day (retail)'), findsOneWidget);
      expect(find.text('Fuel volume (week)'), findsOneWidget);
      expect(find.text('Medical claims rollup'), findsOneWidget);
      expect(find.text('Trades revenue'), findsOneWidget);
    });

    testWidgets('renders PaymentEntry section with all 4 vertical scenarios', (tester) async {
      tester.view.physicalSize = const Size(1200, 8000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: CommerceScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Retail POS — cash / card / gift'), findsOneWidget);
      expect(find.text('Medical copay — card / check / portal'), findsOneWidget);
      expect(find.text('Trades invoice — card / ACH / check'), findsOneWidget);
      expect(find.text('Fuel POD — cash / card / account'), findsOneWidget);
    });

    testWidgets('renders SplitTender section with 3 vertical scenarios', (tester) async {
      tester.view.physicalSize = const Size(1200, 12000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: CommerceScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Retail POS — 3-way split'), findsOneWidget);
      expect(find.text('Trades invoice — 2-way split with reference'), findsOneWidget);
      expect(find.text('Single-tender baseline (balanced)'), findsOneWidget);
    });

    testWidgets('renders Sparkline section with 5 cross-vertical scenarios', (tester) async {
      tester.view.physicalSize = const Size(1200, 14000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: CommerceScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Lab trend — hemoglobin'), findsOneWidget);
      expect(find.text('Sales 7-day trend (in KPI tile)'), findsOneWidget);
      expect(find.text('Tank level history'), findsOneWidget);
      expect(find.text('Flat line baseline'), findsOneWidget);
      expect(find.text('Sparkline with NaN gaps'), findsOneWidget);
    });
  });
}
