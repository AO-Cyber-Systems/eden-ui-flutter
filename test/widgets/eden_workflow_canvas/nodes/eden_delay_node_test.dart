import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_fixtures/eden_workflow_delay_merge_fixtures.dart';
import '../_fixtures/eden_workflow_node_fixtures.dart' show wrap;

void main() {
  group('EdenDelayNode — visual', () {
    testWidgets('renders purple card with timer icon', (tester) async {
      await tester.pumpWidget(
        wrap(EdenDelayNode(context: delayNodeContextFixture())),
      );
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      expect(find.text('DELAY'), findsOneWidget);
    });

    testWidgets('fixed 30m → "Wait 30m"', (tester) async {
      await tester.pumpWidget(
        wrap(EdenDelayNode(
          context: delayNodeContextFixture(minutes: 30),
        )),
      );
      expect(find.text('Wait 30m'), findsOneWidget);
    });

    testWidgets('fixed 60m → "Wait 1h"', (tester) async {
      await tester.pumpWidget(
        wrap(EdenDelayNode(
          context: delayNodeContextFixture(minutes: 60),
        )),
      );
      expect(find.text('Wait 1h'), findsOneWidget);
    });

    testWidgets('fixed 120m → "Wait 2h"', (tester) async {
      await tester.pumpWidget(
        wrap(EdenDelayNode(
          context: delayNodeContextFixture(minutes: 120),
        )),
      );
      expect(find.text('Wait 2h'), findsOneWidget);
    });

    testWidgets('fixed 1440m → "Wait 1d"', (tester) async {
      await tester.pumpWidget(
        wrap(EdenDelayNode(
          context: delayNodeContextFixture(minutes: 1440),
        )),
      );
      expect(find.text('Wait 1d'), findsOneWidget);
    });

    testWidgets('fixed 4320m → "Wait 3d"', (tester) async {
      await tester.pumpWidget(
        wrap(EdenDelayNode(
          context: delayNodeContextFixture(minutes: 4320),
        )),
      );
      expect(find.text('Wait 3d'), findsOneWidget);
    });

    testWidgets('until_time → "Until time"', (tester) async {
      await tester.pumpWidget(
        wrap(EdenDelayNode(
          context: delayNodeContextFixture(delayType: 'until_time'),
        )),
      );
      expect(find.text('Until time'), findsOneWidget);
    });

    testWidgets('until_business_hours → "Until business hours"',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenDelayNode(
          context: delayNodeContextFixture(
            delayType: 'until_business_hours',
          ),
        )),
      );
      expect(find.text('Until business hours'), findsOneWidget);
    });

    testWidgets('selection ring when selected', (tester) async {
      await tester.pumpWidget(
        wrap(EdenDelayNode(
          context: delayNodeContextFixture(selected: true),
        )),
      );
      final container = tester.widget<Container>(find
          .descendant(
            of: find.byType(InkWell).first,
            matching: find.byType(Container),
          )
          .first);
      final decoration = container.decoration as BoxDecoration;
      expect((decoration.border as Border).top.width, 2.5);
    });

    testWidgets('renders at 390pt narrow without overflow', (tester) async {
      await tester.pumpWidget(
        wrap(EdenDelayNode(context: delayNodeContextFixture()), width: 390),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenDelayNode — popover', () {
    testWidgets('tap opens popover with Delay Type dropdown', (tester) async {
      await tester.pumpWidget(
        wrap(EdenDelayNode(context: delayNodeContextFixture())),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(find.text('Edit Delay'), findsOneWidget);
      expect(find.text('Delay Type'), findsOneWidget);
    });

    testWidgets('fixed type shows Minutes input', (tester) async {
      await tester.pumpWidget(
        wrap(EdenDelayNode(context: delayNodeContextFixture())),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(find.text('Minutes'), findsOneWidget);
    });

    testWidgets(
        'switching to until_time hides Minutes input',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenDelayNode(
          context: delayNodeContextFixture(delayType: 'until_time'),
        )),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(find.text('Minutes'), findsNothing);
    });

    testWidgets('Save fires onUpdate with formatted label', (tester) async {
      final captures = <Map<String, dynamic>>[];
      await tester.pumpWidget(
        wrap(EdenDelayNode(
          context: delayNodeContextFixture(minutes: 30),
          config: EdenDelayNodeConfig(onUpdate: captures.add),
        )),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '45');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(captures.length, 1);
      expect(captures[0]['delayType'], 'fixed');
      expect(captures[0]['delayMinutes'], 45);
      expect(captures[0]['label'], 'Wait 45m');
      expect(captures[0]['delayConfig'], isA<Map<String, dynamic>>());
      expect(captures[0]['delayConfig']['minutes'], 45);
    });

    testWidgets('Cancel does NOT fire onUpdate', (tester) async {
      final captures = <Map<String, dynamic>>[];
      await tester.pumpWidget(
        wrap(EdenDelayNode(
          context: delayNodeContextFixture(),
          config: EdenDelayNodeConfig(onUpdate: captures.add),
        )),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(captures, isEmpty);
    });
  });

  group('EdenDelayNode — delete button', () {
    testWidgets('delete always visible on touch', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      var deleted = 0;
      await tester.pumpWidget(
        wrap(EdenDelayNode(
          context: delayNodeContextFixture(),
          config: EdenDelayNodeConfig(onDelete: () => deleted++),
        )),
      );
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(deleted, 1);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
