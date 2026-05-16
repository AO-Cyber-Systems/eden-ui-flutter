import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_mobile_quick_access_grid_fixtures.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('EdenMobileQuickAccessGrid — composition', () {
    testWidgets('renders GridView with items', (tester) async {
      await tester.pumpWidget(wrap(EdenMobileQuickAccessGrid(
        items: EdenMobileQuickAccessGridFixtures.twoItems(),
      )));
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Bravo'), findsOneWidget);
    });

    testWidgets('renders title when provided', (tester) async {
      await tester.pumpWidget(wrap(EdenMobileQuickAccessGrid(
        title: 'Quick Access',
        items: EdenMobileQuickAccessGridFixtures.twoItems(),
      )));
      expect(find.text('Quick Access'), findsOneWidget);
    });

    testWidgets('omits title when null (default)', (tester) async {
      await tester.pumpWidget(wrap(EdenMobileQuickAccessGrid(
        items: EdenMobileQuickAccessGridFixtures.twoItems(),
      )));
      expect(find.text('Quick Access'), findsNothing);
    });
  });

  group('EdenMobileQuickAccessGrid — per-tile rendering', () {
    testWidgets('each item renders its icon + label exactly once',
        (tester) async {
      final items = EdenMobileQuickAccessGridFixtures.tradesSix();
      await tester.pumpWidget(wrap(EdenMobileQuickAccessGrid(items: items)));
      for (final item in items) {
        expect(find.text(item.label), findsOneWidget,
            reason: 'label ${item.label}');
        expect(find.byIcon(item.icon), findsOneWidget,
            reason: 'icon ${item.icon.codePoint}');
      }
    });

    testWidgets('crossAxisCount: 3 (default) is reported on GridView delegate',
        (tester) async {
      await tester.pumpWidget(wrap(EdenMobileQuickAccessGrid(
        items: EdenMobileQuickAccessGridFixtures.tradesSix(),
      )));
      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);
    });

    testWidgets('crossAxisCount: 4 (override) reported on GridView delegate',
        (tester) async {
      await tester.pumpWidget(wrap(EdenMobileQuickAccessGrid(
        items: EdenMobileQuickAccessGridFixtures.eightItems(),
        crossAxisCount: 4,
      )));
      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 4);
    });
  });

  group('EdenMobileQuickAccessGrid — accent application', () {
    testWidgets('item with gold accent — label color matches accent',
        (tester) async {
      await tester.pumpWidget(wrap(EdenMobileQuickAccessGrid(
        items: EdenMobileQuickAccessGridFixtures.singleGold(),
      )));
      final label = tester.widget<Text>(find.text('Gold'));
      expect(label.style?.color, const Color(0xFFD4A853));
    });

    testWidgets('item with red accent — label color matches accent',
        (tester) async {
      await tester.pumpWidget(wrap(EdenMobileQuickAccessGrid(
        items: EdenMobileQuickAccessGridFixtures.singleRed(),
      )));
      final label = tester.widget<Text>(find.text('Red'));
      expect(label.style?.color, const Color(0xFFEF4444));
    });

    testWidgets('item with accent — icon color matches accent',
        (tester) async {
      await tester.pumpWidget(wrap(EdenMobileQuickAccessGrid(
        items: EdenMobileQuickAccessGridFixtures.singleGold(),
      )));
      final icon = tester.widget<Icon>(find.byIcon(Icons.attach_money));
      expect(icon.color, const Color(0xFFD4A853));
    });

    testWidgets('item with no accent — label color matches onSurface',
        (tester) async {
      late ThemeData captured;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (ctx) {
            captured = Theme.of(ctx);
            return EdenMobileQuickAccessGrid(
              items: EdenMobileQuickAccessGridFixtures.singlePlain(),
            );
          }),
        ),
      ));
      final label = tester.widget<Text>(find.text('Plain'));
      expect(label.style?.color, captured.colorScheme.onSurface);
    });
  });

  group('EdenMobileQuickAccessGrid — tap behavior', () {
    testWidgets('tap on tile fires onTap with item.id', (tester) async {
      final taps = <String>[];
      await tester.pumpWidget(wrap(EdenMobileQuickAccessGrid(
        items: EdenMobileQuickAccessGridFixtures.twoItems(),
        onTap: taps.add,
      )));
      await tester.tap(find.text('Alpha'));
      await tester.pump();
      expect(taps, ['a']);
    });

    testWidgets('onTap: null — tap does not throw', (tester) async {
      await tester.pumpWidget(wrap(EdenMobileQuickAccessGrid(
        items: EdenMobileQuickAccessGridFixtures.twoItems(),
      )));
      await tester.tap(find.text('Alpha'));
      await tester.pump();
      // no throw == pass
    });
  });

  group('EdenMobileQuickAccessGrid — reorder semantics', () {
    testWidgets('reorderable: false (default) — no LongPressDraggable in tree',
        (tester) async {
      await tester.pumpWidget(wrap(EdenMobileQuickAccessGrid(
        items: EdenMobileQuickAccessGridFixtures.tradesSix(),
      )));
      expect(find.byType(LongPressDraggable<int>), findsNothing);
    });

    testWidgets(
        'reorderable: true — LongPressDraggable count equals items.length',
        (tester) async {
      final items = EdenMobileQuickAccessGridFixtures.tradesSix();
      await tester.pumpWidget(wrap(EdenMobileQuickAccessGrid(
        items: items,
        reorderable: true,
      )));
      expect(find.byType(LongPressDraggable<int>), findsNWidgets(items.length));
    });

    testWidgets(
        'reorderable: true — onReorder is wired (callback prop is accepted)',
        (tester) async {
      // Wiring smoke — we accept the callback. Actual drag simulation across
      // DragTarget on a GridView is brittle; per <recovery>, we test only
      // that the prop is accepted and the draggable count is correct.
      final reorders = <(int, int)>[];
      await tester.pumpWidget(wrap(EdenMobileQuickAccessGrid(
        items: EdenMobileQuickAccessGridFixtures.twoItems(),
        reorderable: true,
        onReorder: (a, b) => reorders.add((a, b)),
      )));
      expect(find.byType(LongPressDraggable<int>), findsNWidgets(2));
      // No drag simulated; just confirm wiring compiles and renders.
      expect(reorders, isEmpty);
    });
  });

  group('EdenMobileQuickAccessGrid — iPhone-narrow ≥390pt', () {
    testWidgets('renders 6 items at 390pt without overflow (default 3-col)',
        (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(EdenMobileQuickAccessGrid(
        items: EdenMobileQuickAccessGridFixtures.tradesSix(),
      )));

      // No exception thrown == no overflow.
      // Sanity check: all 6 labels visible.
      for (final item in EdenMobileQuickAccessGridFixtures.tradesSix()) {
        expect(find.text(item.label), findsOneWidget);
      }
    });

    testWidgets('renders 8 items at 390pt with 4-col override (no overflow)',
        (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(EdenMobileQuickAccessGrid(
        items: EdenMobileQuickAccessGridFixtures.eightItems(),
        crossAxisCount: 4,
      )));

      for (final item in EdenMobileQuickAccessGridFixtures.eightItems()) {
        expect(find.text(item.label), findsOneWidget);
      }
    });
  });
}
