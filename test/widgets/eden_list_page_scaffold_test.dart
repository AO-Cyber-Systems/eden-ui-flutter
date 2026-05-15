import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_list_page_scaffold_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenListPageScaffold', () {
    // ---------------- Happy path ----------------

    testWidgets('renders with only required props (title + body)',
        (tester) async {
      await tester.pumpWidget(wrap(EdenListPageScaffoldFixtures.minimal()));
      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('body'), findsOneWidget);
      // No create button when onCreate not provided.
      expect(find.textContaining('Create'), findsNothing);
      expect(find.byType(Chip), findsNothing);
      expect(find.byType(EdenSearchInput), findsNothing);
    });

    testWidgets('renders with full slot composition', (tester) async {
      final f = EdenListPageScaffoldFixtures.full();
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(f.widget));
      // Title
      expect(find.text('Customers'), findsOneWidget);
      // Create button label
      expect(find.textContaining('New Customer'), findsOneWidget);
      // Filter chips
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Archived'), findsOneWidget);
      // Search input
      expect(find.byType(EdenSearchInput), findsOneWidget);
      // Alerts slot
      expect(find.text('1 blocking alert'), findsOneWidget);
      // Body (a few rows from the ListView)
      expect(find.text('Row 0'), findsOneWidget);
    });

    testWidgets('tapping the + Create button invokes the onCreate callback',
        (tester) async {
      final f = EdenListPageScaffoldFixtures.full();
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(f.widget));
      // Find the EdenButton whose label contains "New Customer".
      final createBtn = find.widgetWithText(EdenButton, '+ New Customer');
      expect(createBtn, findsOneWidget);
      await tester.tap(createBtn);
      await tester.pump();
      expect(f.onCreateInvoked(), isTrue);
    });

    testWidgets('searchHint appears as placeholder when search slot is enabled',
        (tester) async {
      final f = EdenListPageScaffoldFixtures.full();
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(f.widget));
      expect(find.text('Search customers...'), findsOneWidget);
    });

    testWidgets('onSearchChanged fires with the typed value', (tester) async {
      final f = EdenListPageScaffoldFixtures.full();
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(f.widget));
      await tester.enterText(find.byType(TextField), 'acme');
      await tester.pump();
      expect(f.searchEvents, contains('acme'));
    });

    // ---------------- Edge cases ----------------

    testWidgets('createLabel provided but onCreate null → no button rendered',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenListPageScaffold(
          title: 'Pets',
          createLabel: 'New Pet',
          body: Text('body'),
        ),
      ));
      expect(find.textContaining('New Pet'), findsNothing);
      expect(find.byType(EdenButton), findsNothing);
    });

    testWidgets('filterPills null → no filter row spacing',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenListPageScaffold(
          title: 'Pets',
          body: Text('body'),
        ),
      ));
      // No Chip widgets anywhere.
      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('alerts null → no alerts content rendered',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenListPageScaffold(
          title: 'Pets',
          body: Text('body'),
        ),
      ));
      expect(find.text('1 blocking alert'), findsNothing);
    });

    testWidgets('tall scrollable body does not get wrapped in outer scroller',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(
        EdenListPageScaffold(
          title: 'Long',
          body: ListView(
            children: List.generate(50, (i) => ListTile(title: Text('R$i'))),
          ),
        ),
      ));
      // There should be exactly one ListView (the body); the scaffold must
      // not introduce its own SingleChildScrollView/Scrollable above the body.
      expect(find.byType(ListView), findsOneWidget);
      // No SingleChildScrollView introduced by the scaffold itself.
      expect(find.byType(SingleChildScrollView), findsNothing);
    });

    // ---------------- Failure / safety ----------------

    testWidgets('renders at iPhone-narrow (390pt) without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(
        EdenListPageScaffoldFixtures.narrowOverflowProbe(),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders at tablet (768pt) without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final f = EdenListPageScaffoldFixtures.full();
      await tester.pumpWidget(wrap(f.widget));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders at desktop (1280pt) without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final f = EdenListPageScaffoldFixtures.full();
      await tester.pumpWidget(wrap(f.widget));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
