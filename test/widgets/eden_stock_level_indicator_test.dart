import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  Color colorOfBar(WidgetTester tester) {
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    return bar.valueColor!.value!;
  }

  group('EdenStockLevelIndicator', () {
    testWidgets('GREEN: currentStock=80 reorderPoint=50 → green.shade600 bar',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenStockLevelIndicator(currentStock: 80, reorderPoint: 50),
      ));
      expect(colorOfBar(tester), Colors.green.shade600);
    });

    testWidgets(
        'GREEN: currentStock=100 reorderPoint=50 (percent clamped to 1.0) → green',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenStockLevelIndicator(currentStock: 100, reorderPoint: 50),
      ));
      expect(colorOfBar(tester), Colors.green.shade600);
      // value clamped to 1.0
      final bar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator));
      expect(bar.value, 1.0);
    });

    testWidgets(
        'AMBER: currentStock=35 reorderPoint=0 → amber.shade700 bar (reachable only when reorderPoint=0)',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenStockLevelIndicator(currentStock: 35, reorderPoint: 0),
      ));
      expect(colorOfBar(tester), Colors.amber.shade700);
    });

    testWidgets(
        'RED via isBelowReorder priority: currentStock=50 reorderPoint=100 (50≤100) → theme.error',
        (tester) async {
      final theme = ThemeData.light();
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: EdenStockLevelIndicator(currentStock: 50, reorderPoint: 100),
        ),
      ));
      expect(colorOfBar(tester), theme.colorScheme.error);
    });

    testWidgets(
        'RED via percent<0.25 with reorderPoint=0: currentStock=5 reorderPoint=0 → theme.error',
        (tester) async {
      final theme = ThemeData.light();
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: EdenStockLevelIndicator(currentStock: 5, reorderPoint: 0),
        ),
      ));
      expect(colorOfBar(tester), theme.colorScheme.error);
    });

    testWidgets(
        'RED boundary inclusive: currentStock=100 reorderPoint=100 → theme.error',
        (tester) async {
      final theme = ThemeData.light();
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: EdenStockLevelIndicator(currentStock: 100, reorderPoint: 100),
        ),
      ));
      expect(colorOfBar(tester), theme.colorScheme.error);
    });

    testWidgets('label visible by default — shows "N in stock" + "Reorder at M"',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenStockLevelIndicator(currentStock: 50, reorderPoint: 100),
      ));
      expect(find.text('50 in stock'), findsOneWidget);
      expect(find.text('Reorder at 100'), findsOneWidget);
    });

    testWidgets('showLabel: false hides both labels',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenStockLevelIndicator(
            currentStock: 50, reorderPoint: 100, showLabel: false),
      ));
      expect(find.text('50 in stock'), findsNothing);
      expect(find.text('Reorder at 100'), findsNothing);
    });

    testWidgets(
        'reorderPoint=0 hides Reorder text but keeps "N in stock"',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenStockLevelIndicator(currentStock: 5, reorderPoint: 0),
      ));
      expect(find.text('5 in stock'), findsOneWidget);
      expect(find.textContaining('Reorder at'), findsNothing);
    });

    testWidgets('height override sets SizedBox height + matching borderRadius',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenStockLevelIndicator(
            currentStock: 50, reorderPoint: 50, height: 16),
      ));
      // Locate the SizedBox that directly hosts LinearProgressIndicator.
      final sizedBox = tester.widget<SizedBox>(find.ancestor(
        of: find.byType(LinearProgressIndicator),
        matching: find.byType(SizedBox),
      ));
      expect(sizedBox.height, 16);
      // ClipRRect with matching circular radius.
      final clip = tester.widget<ClipRRect>(find.ancestor(
        of: find.byType(LinearProgressIndicator),
        matching: find.byType(ClipRRect),
      ));
      expect(
        clip.borderRadius,
        BorderRadius.circular(8), // height / 2 == 8
      );
    });

    testWidgets(
        'iPhone-narrow: no overflow inside SizedBox(width: 390) across green/amber/red cases',
        (tester) async {
      const cases = [
        EdenStockLevelIndicator(currentStock: 80, reorderPoint: 50),
        EdenStockLevelIndicator(currentStock: 35, reorderPoint: 0),
        EdenStockLevelIndicator(currentStock: 50, reorderPoint: 100),
      ];
      for (final widget in cases) {
        await tester.pumpWidget(wrap(
          SizedBox(width: 390, child: widget),
        ));
        expect(tester.takeException(), isNull);
      }
    });
  });
}
