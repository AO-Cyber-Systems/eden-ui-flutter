import 'package:eden_ui_flutter/src/widgets/eden_tank_fleet_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_tank_fleet_map_fixtures.dart';

Widget wrap(Widget child, {double width = 1280}) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: 800, child: child),
      ),
    );

Future<void> pumpWide(WidgetTester tester, Widget child,
    {double width = 1280}) async {
  await tester.binding.setSurfaceSize(Size(width + 200, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(wrap(child, width: width));
}

void main() {
  group('EdenTankFleetMap — helpers', () {
    test('severityLabel renders human-readable', () {
      expect(EdenTankFleetMap.severityLabel(EdenFleetMapSeverity.full), 'Full');
      expect(EdenTankFleetMap.severityLabel(EdenFleetMapSeverity.warning),
          'Warning');
      expect(EdenTankFleetMap.severityLabel(EdenFleetMapSeverity.critical),
          'Critical');
      expect(EdenTankFleetMap.severityLabel(EdenFleetMapSeverity.staleTelemetry),
          'Stale telemetry');
      expect(EdenTankFleetMap.severityLabel(EdenFleetMapSeverity.unknown),
          'Unknown');
    });

    test('severityColor differs per severity', () {
      final colors = EdenFleetMapSeverity.values
          .map((s) => EdenTankFleetMap.severityColor(s, null).value)
          .toSet();
      // Severities should have distinct colors (some may overlap if neutral)
      expect(colors.length, greaterThanOrEqualTo(3));
    });
  });

  group('EdenTankFleetMap — 2-zone (>=1024pt)', () {
    testWidgets('renders both map + sidebar zones', (tester) async {
      await pumpWide(
        tester,
        EdenTankFleetMap(data: TankFleetMapFixtures.demo25()),
      );
      expect(find.textContaining('Fleet map'), findsOneWidget);
      expect(find.textContaining('Fleet ('), findsOneWidget);
    });

    testWidgets('sidebar shows fleet count with all visible',
        (tester) async {
      await pumpWide(
        tester,
        EdenTankFleetMap(data: TankFleetMapFixtures.demo25()),
      );
      // 25 total markers visible by default
      expect(find.text('Fleet (25 tanks)'), findsOneWidget);
    });

    testWidgets('severity filter chips count correctly', (tester) async {
      await pumpWide(
        tester,
        EdenTankFleetMap(data: TankFleetMapFixtures.demo25()),
      );
      expect(find.text('Full (8)'), findsOneWidget);
      expect(find.text('Warning (6)'), findsOneWidget);
      expect(find.text('Critical (4)'), findsOneWidget);
      expect(find.text('Stale telemetry (3)'), findsOneWidget);
      expect(find.text('Unknown (4)'), findsOneWidget);
    });

    testWidgets('filter chip toggle hides matching severity markers',
        (tester) async {
      await pumpWide(
        tester,
        EdenTankFleetMap(data: TankFleetMapFixtures.demo25()),
      );
      // Deselect 'full' filter
      await tester.tap(find.byKey(const Key('fleet-filter-full')));
      await tester.pumpAndSettle();
      // Count drops from 25 to 17 (25 - 8 full)
      expect(find.text('Fleet (17 tanks)'), findsOneWidget);
    });
  });

  group('EdenTankFleetMap — tabbed (<1024pt)', () {
    testWidgets('renders Map / List tabs at 800pt', (tester) async {
      await pumpWide(
        tester,
        EdenTankFleetMap(data: TankFleetMapFixtures.demo25()),
        width: 800,
      );
      expect(find.widgetWithText(Tab, 'Map'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'List'), findsOneWidget);
    });

    testWidgets('iPhone-narrow (390pt) renders without overflow',
        (tester) async {
      await pumpWide(
        tester,
        EdenTankFleetMap(data: TankFleetMapFixtures.demo25()),
        width: 390,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenTankFleetMap — empty', () {
    testWidgets('empty data renders No tanks visible', (tester) async {
      await pumpWide(
        tester,
        EdenTankFleetMap(data: TankFleetMapFixtures.emptyDemo()),
      );
      expect(find.text('No tanks visible'), findsOneWidget);
    });
  });

  group('EdenTankFleetMap — marker interactions', () {
    testWidgets('tap on marker fires onMarkerTap', (tester) async {
      String? tapped;
      await pumpWide(
        tester,
        EdenTankFleetMap(
          data: TankFleetMapFixtures.demo25(),
          onMarkerTap: (id) => tapped = id,
        ),
      );
      await tester
          .ensureVisible(find.byKey(const Key('fleet-marker-tank-full-1')));
      await tester.tap(find.byKey(const Key('fleet-marker-tank-full-1')));
      await tester.pumpAndSettle();
      expect(tapped, 'tank-full-1');
    });

    testWidgets('long-press on marker enters multi-select mode',
        (tester) async {
      await pumpWide(
        tester,
        EdenTankFleetMap(
          data: TankFleetMapFixtures.demo25(),
          onMultiSelect: (_) {},
        ),
      );
      await tester.longPress(
          find.byKey(const Key('fleet-marker-tank-full-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fleet-build-route')), findsOneWidget);
      expect(find.text('Build route (1)'), findsOneWidget);
    });

    testWidgets('Build route CTA fires onMultiSelect', (tester) async {
      List<String>? selected;
      await pumpWide(
        tester,
        EdenTankFleetMap(
          data: TankFleetMapFixtures.demo25(),
          onMultiSelect: (ids) => selected = ids,
        ),
      );
      await tester.longPress(
          find.byKey(const Key('fleet-marker-tank-full-1')));
      await tester.pumpAndSettle();
      await tester.longPress(
          find.byKey(const Key('fleet-marker-tank-warn-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fleet-build-route')));
      await tester.pumpAndSettle();
      expect(selected, isNotNull);
      expect(selected!.length, 2);
    });
  });
}
