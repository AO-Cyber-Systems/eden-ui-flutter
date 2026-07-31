import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  final columns = [
    const EdenTableColumn(label: 'Name'),
    const EdenTableColumn(label: 'Email'),
    const EdenTableColumn(label: 'Role'),
  ];

  final rows = [
    const EdenTableRow(cells: [Text('Alice'), Text('alice@test.com'), Text('Admin')]),
    const EdenTableRow(cells: [Text('Bob'), Text('bob@test.com'), Text('User')]),
  ];

  group('EdenDataTable', () {
    testWidgets('renders column headers', (tester) async {
      await tester.pumpWidget(wrap(
        EdenDataTable(columns: columns, rows: rows),
      ));
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Role'), findsOneWidget);
    });

    testWidgets('renders row data cells', (tester) async {
      await tester.pumpWidget(wrap(
        EdenDataTable(columns: columns, rows: rows),
      ));
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('bob@test.com'), findsOneWidget);
    });

    testWidgets('striped rows render without error', (tester) async {
      await tester.pumpWidget(wrap(
        EdenDataTable(columns: columns, rows: rows, striped: true),
      ));
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('onRowTap fires with correct row index', (tester) async {
      int? tappedIndex;
      await tester.pumpWidget(wrap(
        EdenDataTable(
          columns: columns,
          rows: rows,
          onRowTap: (i) => tappedIndex = i,
        ),
      ));
      await tester.tap(find.text('Bob'));
      expect(tappedIndex, 1);
    });

    testWidgets('empty rows renders just headers', (tester) async {
      await tester.pumpWidget(wrap(
        EdenDataTable(columns: columns, rows: const []),
      ));
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Alice'), findsNothing);
    });

    testWidgets('optional per-row key resolves via find.byKey', (tester) async {
      await tester.pumpWidget(wrap(
        EdenDataTable(
          columns: columns,
          rows: const [
            EdenTableRow(
              key: Key('posts_list.row.abc-123'),
              cells: [Text('Alice'), Text('alice@test.com'), Text('Admin')],
            ),
            EdenTableRow(
              cells: [Text('Bob'), Text('bob@test.com'), Text('User')],
            ),
          ],
        ),
      ));
      // Keyed row is findable; the unkeyed row still renders (additive).
      expect(find.byKey(const Key('posts_list.row.abc-123')), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      // The key sits on the OUTERMOST row widget, so the row's cells are its
      // descendants — this is what makes a row-scoped finder work.
      expect(
        find.descendant(
          of: find.byKey(const Key('posts_list.row.abc-123')),
          matching: find.text('Alice'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('keyed row is tappable through the key', (tester) async {
      int? tappedIndex;
      await tester.pumpWidget(wrap(
        EdenDataTable(
          columns: columns,
          rows: const [
            EdenTableRow(
              key: Key('posts_list.row.abc-123'),
              cells: [Text('Alice'), Text('alice@test.com'), Text('Admin')],
            ),
          ],
          onRowTap: (i) => tappedIndex = i,
        ),
      ));
      await tester.tap(find.byKey(const Key('posts_list.row.abc-123')));
      expect(tappedIndex, 0);
    });

    testWidgets('dense variant applies the per-row key', (tester) async {
      await tester.pumpWidget(wrap(
        SizedBox(
          height: 300,
          child: EdenDataTable.dense(
            columns: columns,
            rows: const [
              EdenTableRow(
                key: Key('posts_list.row.dense-1'),
                cells: [Text('Alice'), Text('alice@test.com'), Text('Admin')],
              ),
            ],
          ),
        ),
      ));
      expect(find.byKey(const Key('posts_list.row.dense-1')), findsOneWidget);
    });
  });
}
