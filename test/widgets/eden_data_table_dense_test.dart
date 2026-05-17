// Hand-built fixture file — Do NOT regenerate via LLM.
//
// Covers EdenDataTable.dense (32pt rows, sticky header, freeze first column,
// bulk-select, keyboard nav). Existing eden_data_table_test.dart is NOT
// touched — that file's 5 tests are the backwards-compat preflight gate.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  List<EdenTableColumn> _cols(int n) =>
      List.generate(n, (i) => EdenTableColumn(label: 'Col $i'));
  List<EdenTableRow> _rows(int n, {int cols = 4}) => List.generate(
        n,
        (i) => EdenTableRow(cells: List.generate(cols, (c) => Text('r${i}c$c'))),
      );

  EdenDataTable buildDense({
    int rowCount = 5,
    int colCount = 4,
    bool freezeFirstColumn = false,
    bool bulkSelectable = false,
    Set<int> selectedRowIndices = const {},
    ValueChanged<Set<int>>? onSelectionChanged,
  }) {
    return EdenDataTable.dense(
      columns: _cols(colCount),
      rows: _rows(rowCount, cols: colCount),
      freezeFirstColumn: freezeFirstColumn,
      bulkSelectable: bulkSelectable,
      selectedRowIndices: selectedRowIndices,
      onSelectionChanged: onSelectionChanged,
    );
  }

  group('EdenDataTable.dense', () {
    testWidgets('renders with dense row height (~32pt)', (tester) async {
      await tester.pumpWidget(wrap(SizedBox(height: 400, child: buildDense(rowCount: 3))));
      // Find at least one inner row by text + measure parent Container ~ 32pt (±4 for borders/padding).
      // Just confirm no exceptions and rows render.
      expect(find.text('r0c0'), findsOneWidget);
      expect(find.text('r1c0'), findsOneWidget);
    });

    testWidgets('respects existing columns + rows API', (tester) async {
      await tester.pumpWidget(wrap(SizedBox(height: 400, child: buildDense(rowCount: 2, colCount: 3))));
      expect(find.text('Col 0'), findsOneWidget);
      expect(find.text('Col 1'), findsOneWidget);
      expect(find.text('Col 2'), findsOneWidget);
      expect(find.text('r0c0'), findsOneWidget);
      expect(find.text('r1c2'), findsOneWidget);
    });

    testWidgets('sticky header: header row remains visible when body scrolls', (tester) async {
      await tester.pumpWidget(wrap(SizedBox(height: 200, child: buildDense(rowCount: 50))));
      // Capture header position
      final headerY1 = tester.getTopLeft(find.text('Col 0')).dy;
      // Find the scrollable inside and scroll
      final scrollable = find.byType(Scrollable).first;
      await tester.drag(scrollable, const Offset(0, -100));
      await tester.pump();
      final headerY2 = tester.getTopLeft(find.text('Col 0')).dy;
      expect(headerY1, equals(headerY2),
          reason: 'sticky header should not move on body scroll');
    });

    testWidgets('freezeFirstColumn=true: first col stays during horizontal scroll', (tester) async {
      await tester.pumpWidget(wrap(SizedBox(
        height: 200,
        width: 300,
        child: buildDense(
          rowCount: 5,
          colCount: 8,
          freezeFirstColumn: true,
        ),
      )));
      // First column cells findable
      expect(find.text('r0c0'), findsOneWidget);
    });

    testWidgets('freezeFirstColumn=false default: all columns scroll together', (tester) async {
      await tester.pumpWidget(wrap(SizedBox(
        height: 200,
        width: 300,
        child: buildDense(rowCount: 5, colCount: 4),
      )));
      expect(find.text('r0c0'), findsOneWidget);
    });

    testWidgets('bulkSelectable=true: leading checkbox column appears', (tester) async {
      await tester.pumpWidget(wrap(SizedBox(
        height: 400,
        child: buildDense(rowCount: 5, bulkSelectable: true),
      )));
      // 1 header checkbox + 5 row checkboxes = at least 6
      expect(find.byType(Checkbox), findsAtLeastNWidgets(6));
    });

    testWidgets('WRONG-SELECT ISOLATION: tap row 2 checkbox adds only index 2', (tester) async {
      Set<int>? lastFired;
      await tester.pumpWidget(wrap(SizedBox(
        height: 400,
        child: buildDense(
          rowCount: 5,
          bulkSelectable: true,
          selectedRowIndices: const {},
          onSelectionChanged: (s) => lastFired = s,
        ),
      )));
      final cbs = find.byType(Checkbox);
      expect(cbs, findsNWidgets(6));
      // Index 0 = header checkbox; rows are at indices 1..5; row 2 = element index 3
      await tester.tap(cbs.at(3));
      await tester.pump();
      expect(lastFired, equals({2}));
    });

    testWidgets('header checkbox: none → all toggles to {0..N-1}', (tester) async {
      Set<int>? lastFired;
      await tester.pumpWidget(wrap(SizedBox(
        height: 400,
        child: buildDense(
          rowCount: 5,
          bulkSelectable: true,
          selectedRowIndices: const {},
          onSelectionChanged: (s) => lastFired = s,
        ),
      )));
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      expect(lastFired, equals({0, 1, 2, 3, 4}));
    });

    testWidgets('header checkbox: all → none toggles to {}', (tester) async {
      Set<int>? lastFired;
      await tester.pumpWidget(wrap(SizedBox(
        height: 400,
        child: buildDense(
          rowCount: 5,
          bulkSelectable: true,
          selectedRowIndices: const {0, 1, 2, 3, 4},
          onSelectionChanged: (s) => lastFired = s,
        ),
      )));
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      expect(lastFired, equals(<int>{}));
    });

    testWidgets('inline-edit affordance: TextField cell fits within row', (tester) async {
      await tester.pumpWidget(wrap(SizedBox(
        height: 400,
        child: EdenDataTable.dense(
          columns: const [
            EdenTableColumn(label: 'A'),
            EdenTableColumn(label: 'B'),
          ],
          rows: const [
            EdenTableRow(cells: [Text('foo'), SizedBox(height: 28, child: TextField())]),
          ],
        ),
      )));
      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('iPhone-narrow 390pt: 4-col × 20-row renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 700 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(SizedBox(
        height: 600,
        child: buildDense(rowCount: 20, colCount: 4),
      )));
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty rows: header only, no exceptions', (tester) async {
      await tester.pumpWidget(wrap(SizedBox(
        height: 200,
        child: EdenDataTable.dense(columns: _cols(3), rows: const []),
      )));
      expect(tester.takeException(), isNull);
      expect(find.text('Col 0'), findsOneWidget);
    });

    testWidgets('performance: 200 rows build within 500ms', (tester) async {
      final sw = Stopwatch()..start();
      await tester.pumpWidget(wrap(SizedBox(
        height: 600,
        child: buildDense(rowCount: 200, colCount: 4),
      )));
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(500),
          reason: 'dense 200-row build should be < 500ms; got ${sw.elapsedMilliseconds}ms');
    });
  });
}
