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
  });
}
