// TRD 40-05 — EdenDataTable copy affordances, asserted against a real clipboard.
//
// The point of these cases is that they assert what actually reaches the
// SYSTEM CLIPBOARD, not what some internal helper returned. A test that checks
// an internal string would keep passing if the widget stopped calling
// Clipboard.setData entirely.
//
// The mock below is the pattern TRD 40-08 reuses verbatim for the other three
// tabular widgets. Install it in setUp — BEFORE pumpWidget — and always tear it
// down, or it leaks into every later test file in the same shard.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// The text the widget under test actually put on the clipboard.
  String? captured;

  setUp(() {
    captured = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform,
            (MethodCall call) async {
      if (call.method == 'Clipboard.setData') {
        captured = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  const List<EdenTableColumn> columns = <EdenTableColumn>[
    EdenTableColumn(label: 'Name'),
    EdenTableColumn(label: 'Email'),
    EdenTableColumn(label: 'Role'),
  ];

  const List<EdenTableRow> rows = <EdenTableRow>[
    EdenTableRow(
      cells: <Widget>[Text('a'), Text('b'), Text('c')],
    ),
    EdenTableRow(
      cells: <Widget>[Text('d'), Text('e'), Text('f')],
    ),
  ];

  group('EdenDataTable — copy row', () {
    testWidgets('copy row writes tab-delimited text for that row only',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        const EdenDataTable(columns: columns, rows: rows, copyable: true),
      ));

      expect(find.byTooltip('Copy row'), findsNWidgets(2));
      await tester.tap(find.byTooltip('Copy row').first);
      await tester.pump();

      expect(
        captured,
        'a\tb\tc',
        reason: 'tab-delimited so it pastes into a spreadsheet as three '
            'separate cells, and the second row is NOT included',
      );
    });

    testWidgets('copyValues takes precedence over widget extraction',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        const EdenDataTable(
          columns: columns,
          rows: <EdenTableRow>[
            EdenTableRow(
              cells: <Widget>[
                Icon(Icons.star),
                Icon(Icons.check),
                Icon(Icons.close),
              ],
              copyValues: <String>['x', 'y', 'z'],
            ),
          ],
          copyable: true,
        ),
      ));

      await tester.tap(find.byTooltip('Copy row'));
      await tester.pump();

      expect(
        captured,
        'x\ty\tz',
        reason: 'the cells render icons, which yield no text — without '
            'copyValues this row would copy as two bare tabs',
      );
    });

    testWidgets('a cell widget that yields no text copies as an empty cell',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        const EdenDataTable(
          columns: columns,
          rows: <EdenTableRow>[
            EdenTableRow(
              cells: <Widget>[Text('a'), Icon(Icons.star), Text('c')],
            ),
          ],
          copyable: true,
        ),
      ));

      await tester.tap(find.byTooltip('Copy row'));
      await tester.pump();

      expect(
        captured,
        'a\t\tc',
        reason: 'never the literal string "null", and the column alignment of '
            'the pasted grid survives the blank',
      );
    });
  });

  group('EdenDataTable — copy table', () {
    testWidgets('copy table writes the header row then every row, '
        'newline-delimited', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        const EdenDataTable(columns: columns, rows: rows, copyable: true),
      ));

      expect(find.byTooltip('Copy table'), findsOneWidget);
      await tester.tap(find.byTooltip('Copy table'));
      await tester.pump();

      expect(captured, 'Name\tEmail\tRole\na\tb\tc\nd\te\tf');
      expect(
        captured!.endsWith('\n'),
        isFalse,
        reason: 'no trailing newline, or the paste gains a phantom empty row',
      );
    });
  });

  group('EdenDataTable — the affordance itself', () {
    testWidgets('copyable: false renders no copy affordance',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        const EdenDataTable(columns: columns, rows: rows),
      ));

      expect(
        find.byTooltip('Copy row'),
        findsNothing,
        reason: 'copyable defaults to false — a new icon appearing in every '
            'existing consumer table unannounced is a visual regression',
      );
      expect(find.byTooltip('Copy table'), findsNothing);
    });

    testWidgets('the copy affordance is inside a SelectionContainer.disabled',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        const EdenDataTable(columns: columns, rows: rows, copyable: true),
      ));

      for (final String tooltip in <String>['Copy table', 'Copy row']) {
        final Finder container = find
            .ancestor(
              of: find.byTooltip(tooltip),
              matching: find.byType(SelectionContainer),
            )
            .first;
        expect(
          container,
          findsOneWidget,
          reason: '$tooltip must sit under a SelectionContainer',
        );

        // SelectionContainer.disabled is the named constructor that leaves BOTH
        // registrar and delegate null; a plain SelectionContainer requires a
        // delegate. Asserting on those fields is what distinguishes the two.
        final SelectionContainer widget =
            tester.widget<SelectionContainer>(container);
        expect(
          widget.delegate,
          isNull,
          reason: 'must be SelectionContainer.disabled, so a drag-select '
              'across the table picks up the data and not the word "Copy"',
        );
        expect(widget.registrar, isNull);
      }
    });

    testWidgets('EdenDataTable.dense also honours copyable',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        const SizedBox(
          height: 300,
          child: EdenDataTable.dense(
            columns: columns,
            rows: rows,
            copyable: true,
          ),
        ),
      ));

      expect(
        find.byTooltip('Copy table'),
        findsOneWidget,
        reason: 'dense is a SECOND constructor over the same field set — a '
            'parameter added to only one of them is silently lost',
      );

      await tester.tap(find.byTooltip('Copy row').first);
      await tester.pump();
      expect(captured, 'a\tb\tc');
    });

    testWidgets('EdenDataTable.dense copyable: false renders no affordance',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        const SizedBox(
          height: 300,
          child: EdenDataTable.dense(columns: columns, rows: rows),
        ),
      ));

      expect(find.byTooltip('Copy row'), findsNothing);
      expect(find.byTooltip('Copy table'), findsNothing);
    });
  });
}
