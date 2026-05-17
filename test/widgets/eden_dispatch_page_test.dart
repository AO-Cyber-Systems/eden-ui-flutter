import 'package:eden_ui_flutter/src/widgets/eden_dispatch_page.dart';
import 'package:eden_ui_flutter/src/widgets/scheduler/scheduler_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_dispatch_page_fixtures.dart';

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
  group('EdenDispatchPage — helpers', () {
    test('defaultCrewCanHandle accepts empty skill requirements', () {
      const crew = EdenSchedulerResource(id: 'c1', name: 'Crew A');
      const item = EdenDispatchWorkItem(
        id: 'i1',
        title: 'x',
        customerName: 'y',
        address: 'z',
        urgency: 'low',
        estimatedDuration: Duration(hours: 1),
      );
      expect(EdenDispatchPage.defaultCrewCanHandle(crew, item), isTrue);
    });

    test('defaultCrewCanHandle matches via crew skills', () {
      const crew =
          EdenSchedulerResource(id: 'c1', name: 'Crew A', crew: ['hvac']);
      const item = EdenDispatchWorkItem(
        id: 'i1',
        title: 'x',
        customerName: 'y',
        address: 'z',
        urgency: 'low',
        estimatedDuration: Duration(hours: 1),
        requiredSkills: ['hvac'],
      );
      expect(EdenDispatchPage.defaultCrewCanHandle(crew, item), isTrue);
    });

    test('defaultCrewCanHandle rejects when skills missing', () {
      const crew =
          EdenSchedulerResource(id: 'c1', name: 'Crew A', crew: ['plumbing']);
      const item = EdenDispatchWorkItem(
        id: 'i1',
        title: 'x',
        customerName: 'y',
        address: 'z',
        urgency: 'low',
        estimatedDuration: Duration(hours: 1),
        requiredSkills: ['hvac'],
      );
      expect(EdenDispatchPage.defaultCrewCanHandle(crew, item), isFalse);
    });
  });

  group('EdenDispatchPage — 3-zone layout (>=1280pt)', () {
    testWidgets('renders Open Work queue header at 1280pt', (tester) async {
      await pumpWide(
          tester,
          EdenDispatchPage(
            data: DispatchFixtures.tradesDispatch(),
            onDispatchAssignment: (_) {},
          ));
      expect(find.text('Open Work'), findsOneWidget);
    });

    testWidgets('renders Schedule header in scheduler zone', (tester) async {
      await pumpWide(
          tester,
          EdenDispatchPage(
            data: DispatchFixtures.tradesDispatch(),
            onDispatchAssignment: (_) {},
          ));
      expect(find.text('Schedule'), findsOneWidget);
    });

    testWidgets('renders 4 crew columns from trades fixture',
        (tester) async {
      await pumpWide(
          tester,
          EdenDispatchPage(
            data: DispatchFixtures.tradesDispatch(),
            onDispatchAssignment: (_) {},
          ));
      expect(find.text('Crew A — HVAC'), findsOneWidget);
      expect(find.text('Crew B — Plumbing'), findsOneWidget);
      expect(find.text('Crew C — Electrical'), findsOneWidget);
      expect(find.text('Crew D — Generic'), findsOneWidget);
    });

    testWidgets('renders map zone when mapSlot provided', (tester) async {
      await pumpWide(
          tester,
          EdenDispatchPage(
            data: DispatchFixtures.tradesDispatch(),
            onDispatchAssignment: (_) {},
          ));
      expect(find.text('[map placeholder]'), findsOneWidget);
    });

    testWidgets('AI zone hidden by default (showAiZone: false)',
        (tester) async {
      await pumpWide(
          tester,
          EdenDispatchPage(
            data: DispatchFixtures.fuelDispatch(),
            onDispatchAssignment: (_) {},
          ));
      expect(find.text('[AI route optimizer]'), findsNothing);
    });

    testWidgets('AI zone shows when showAiZone: true + aiSlot wired',
        (tester) async {
      await pumpWide(
          tester,
          EdenDispatchPage(
            data: DispatchFixtures.fuelDispatch(),
            onDispatchAssignment: (_) {},
            showAiZone: true,
          ));
      expect(find.text('[AI route optimizer]'), findsOneWidget);
    });

    testWidgets('AI zone shows empty state when showAiZone but no aiSlot',
        (tester) async {
      await pumpWide(
          tester,
          EdenDispatchPage(
            data: DispatchFixtures.tradesDispatch(),
            onDispatchAssignment: (_) {},
            showAiZone: true,
          ));
      expect(find.text('AI assistant not configured'), findsOneWidget);
    });
  });

  group('EdenDispatchPage — 2-zone layout (>=1024pt and <1280pt)', () {
    testWidgets('shows floating drawer button at 1100pt', (tester) async {
      await pumpWide(
          tester,
          EdenDispatchPage(
            data: DispatchFixtures.tradesDispatch(),
            onDispatchAssignment: (_) {},
          ),
          width: 1100);
      expect(find.byKey(const Key('dispatch-floating-drawer')),
          findsOneWidget);
    });

    testWidgets('still renders scheduler + queue at 1100pt', (tester) async {
      await pumpWide(
          tester,
          EdenDispatchPage(
            data: DispatchFixtures.tradesDispatch(),
            onDispatchAssignment: (_) {},
          ),
          width: 1100);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Open Work'), findsOneWidget);
    });
  });

  group('EdenDispatchPage — tabbed (<1024pt)', () {
    testWidgets('renders 3 tabs at 800pt (Schedule / Queue / Map)',
        (tester) async {
      await pumpWide(
          tester,
          EdenDispatchPage(
            data: DispatchFixtures.tradesDispatch(),
            onDispatchAssignment: (_) {},
          ),
          width: 800);
      expect(find.widgetWithText(Tab, 'Schedule'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Queue'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Map'), findsOneWidget);
    });

    testWidgets('4 tabs when showAiZone: true', (tester) async {
      await pumpWide(
          tester,
          EdenDispatchPage(
            data: DispatchFixtures.fuelDispatch(),
            onDispatchAssignment: (_) {},
            showAiZone: true,
          ),
          width: 800);
      expect(find.widgetWithText(Tab, 'AI'), findsOneWidget);
    });

    testWidgets('renders without overflow at 390pt iPhone-narrow',
        (tester) async {
      await pumpWide(
          tester,
          EdenDispatchPage(
            data: DispatchFixtures.tradesDispatch(),
            onDispatchAssignment: (_) {},
          ),
          width: 390);
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenDispatchPage — empty data', () {
    testWidgets('empty crews show No crews configured', (tester) async {
      await pumpWide(
          tester,
          EdenDispatchPage(
            data: DispatchFixtures.emptyDispatch(),
            onDispatchAssignment: (_) {},
          ));
      expect(find.text('No crews configured'), findsOneWidget);
    });

    testWidgets('empty queue shows No open work', (tester) async {
      await pumpWide(
          tester,
          EdenDispatchPage(
            data: DispatchFixtures.emptyDispatch(),
            onDispatchAssignment: (_) {},
          ));
      expect(find.text('No open work'), findsOneWidget);
    });

    testWidgets('null mapSlot shows Map provider not configured',
        (tester) async {
      await pumpWide(
          tester,
          EdenDispatchPage(
            data: DispatchFixtures.emptyDispatch(),
            onDispatchAssignment: (_) {},
          ));
      expect(find.text('Map provider not configured'), findsOneWidget);
    });
  });

  group('EdenDispatchPage — work-item card rendering', () {
    testWidgets('renders title + customer + address for each item',
        (tester) async {
      await pumpWide(
          tester,
          EdenDispatchPage(
            data: DispatchFixtures.tradesDispatch(),
            onDispatchAssignment: (_) {},
          ));
      expect(find.text('AC not cooling'), findsOneWidget);
      expect(find.text('Patel residence'), findsAtLeastNWidgets(1));
    });

    testWidgets('queue items wrapped in LongPressDraggable at >=1024pt',
        (tester) async {
      await pumpWide(
          tester,
          EdenDispatchPage(
            data: DispatchFixtures.tradesDispatch(),
            onDispatchAssignment: (_) {},
          ));
      // At least one draggable for job-1
      expect(find.byKey(const Key('work-item-drag-job-1')), findsOneWidget);
    });
  });

  group('EdenDispatchPage — cross-vertical', () {
    testWidgets('fuel fixture renders 3 trucks', (tester) async {
      await pumpWide(
          tester,
          EdenDispatchPage(
            data: DispatchFixtures.fuelDispatch(),
            onDispatchAssignment: (_) {},
          ));
      expect(find.text('Truck-12 (4,000 gal diesel)'), findsOneWidget);
      expect(find.text('Truck-14 (3,000 gal propane)'), findsOneWidget);
      expect(find.text('Truck-22 (4,000 gal heating oil)'), findsOneWidget);
    });

    testWidgets('fuel fixture renders 8 deliveries in queue',
        (tester) async {
      await pumpWide(
          tester,
          EdenDispatchPage(
            data: DispatchFixtures.fuelDispatch(),
            onDispatchAssignment: (_) {},
          ));
      // Count badge near queue header should show 8
      expect(find.text('8'), findsAtLeastNWidgets(1));
    });
  });
}
