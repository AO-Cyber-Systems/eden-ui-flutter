// test/widgets/eden_project_table_copy_test.dart
//
// TRD 40-08 — EdenProjectTable TSV clipboard.
//
// Asserts what reached the SYSTEM clipboard, via a mock on
// SystemChannels.platform. Delimiters are written as escape sequences, never as
// literal bytes (40-RESEARCH.md Appendix B4).

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const List<EdenProjectStatusOption> _kStatuses = <EdenProjectStatusOption>[
  EdenProjectStatusOption(label: 'In Progress', color: Colors.blue),
  EdenProjectStatusOption(label: 'Done', color: Colors.green),
];

const List<EdenProjectStatusOption> _kPriorities = <EdenProjectStatusOption>[
  EdenProjectStatusOption(label: 'High', color: Colors.red),
  EdenProjectStatusOption(label: 'Low', color: Colors.grey),
];

const List<EdenProjectField> _kFields = <EdenProjectField>[
  EdenProjectField(id: 'title', label: 'Title'),
  EdenProjectField(
    id: 'status',
    label: 'Status',
    type: EdenProjectFieldType.status,
    options: _kStatuses,
  ),
  EdenProjectField(
    id: 'priority',
    label: 'Priority',
    type: EdenProjectFieldType.priority,
    options: _kPriorities,
  ),
  EdenProjectField(
    id: 'owner',
    label: 'Owner',
    type: EdenProjectFieldType.assignee,
  ),
  EdenProjectField(
    id: 'due',
    label: 'Due',
    type: EdenProjectFieldType.date,
  ),
  EdenProjectField(
    id: 'points',
    label: 'Points',
    type: EdenProjectFieldType.number,
  ),
];

final List<EdenProjectRow> _kRows = <EdenProjectRow>[
  EdenProjectRow(
    id: 'r1',
    fields: <String, dynamic>{
      'title': 'Ship the grid',
      'status': 'In Progress',
      'priority': 'High',
      'owner': 'Jane Doe',
      'due': DateTime(2026, 3, 9),
      'points': 5,
    },
  ),
  EdenProjectRow(
    id: 'r2',
    fields: <String, dynamic>{
      'title': 'Write the docs',
      'status': 'Done',
      'priority': 'Low',
      'owner': 'Sam Ray',
      'due': DateTime(2026, 11, 24),
      'points': 2,
    },
  ),
];

Widget _host({
  bool copyable = true,
  List<EdenProjectRow>? rows,
  List<EdenProjectField>? fields,
  String? groupByFieldId,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 1400,
        child: SingleChildScrollView(
          child: EdenProjectTable(
            fields: fields ?? _kFields,
            rows: rows ?? _kRows,
            groupByFieldId: groupByFieldId,
            copyable: copyable,
          ),
        ),
      ),
    ),
  );
}

void main() {
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

  group('EdenProjectTable copy', () {
    // Case 9 — per-type copy formatting, all in one row so the column
    // positions are pinned alongside the values.
    testWidgets('copies each field type as DATA, not as rendered',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host());

      await tester.tap(find.byTooltip('Copy row').first);
      await tester.pump();

      expect(
        captured,
        'Ship the grid\tIn Progress\tHigh\tJane Doe\t2026-03-09\t5',
      );
    });

    // Case 9a — date. ISO-8601, zero-padded, never a localised string.
    testWidgets('date copies as zero-padded ISO-8601',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host());

      await tester.tap(find.byTooltip('Copy row').first);
      await tester.pump();

      // March 9th: both month and day padded, so a spreadsheet sorts it.
      expect(captured, contains('2026-03-09'));
      expect(captured, isNot(contains('2026-3-9')));
      expect(captured, isNot(contains('3/9/2026')));
    });

    // Case 9b — status and priority copy their LABEL. The badge colour carries
    // meaning on screen and none in a spreadsheet, so it is dropped.
    testWidgets('status and priority copy their option label',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host());

      await tester.tap(find.byTooltip('Copy row').last);
      await tester.pump();

      expect(captured, contains('Done'));
      expect(captured, contains('Low'));
      // Nothing about the rendering leaks in.
      expect(captured, isNot(contains('Color')));
      expect(captured, isNot(contains('MaterialColor')));
    });

    // Case 9c — assignee. THE rendering-vs-data case in this widget: the avatar
    // shows initials, the datum is the name.
    testWidgets('assignee copies the name, never the avatar initials',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host());

      // The initials really are on screen, so the assertion below is not
      // vacuous — it is discriminating between two things both present.
      expect(find.text('JD'), findsOneWidget);

      await tester.tap(find.byTooltip('Copy row').first);
      await tester.pump();

      expect(captured, contains('Jane Doe'));
      final List<String> cells = captured!.split('\t');
      expect(cells, isNot(contains('JD')));
    });

    // Case 10.
    testWidgets('copy-table emits the field labels as the header row',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host());

      await tester.tap(find.byTooltip('Copy table'));
      await tester.pump();

      expect(
        captured,
        'Title\tStatus\tPriority\tOwner\tDue\tPoints\n'
        'Ship the grid\tIn Progress\tHigh\tJane Doe\t2026-03-09\t5\n'
        'Write the docs\tDone\tLow\tSam Ray\t2026-11-24\t2',
      );
    });

    // Case 10b — copy-row must not smuggle the header in.
    testWidgets('copy-row emits no header line', (WidgetTester tester) async {
      await tester.pumpWidget(_host());

      await tester.tap(find.byTooltip('Copy row').first);
      await tester.pump();

      expect(captured, isNot(contains('Title')));
      expect(captured, isNot(contains('\n')));
    });

    // Case 11.
    testWidgets('copyable: false renders no affordance',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(copyable: false));

      expect(find.byTooltip('Copy table'), findsNothing);
      expect(find.byTooltip('Copy row'), findsNothing);
    });

    // Case 11b.
    testWidgets('the copy affordances sit inside SelectionContainer.disabled',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host());

      for (final String tooltip in <String>['Copy table', 'Copy row']) {
        final SelectionContainer wrapper = tester.widget<SelectionContainer>(
          find
              .ancestor(
                of: find.byTooltip(tooltip),
                matching: find.byType(SelectionContainer),
              )
              .first,
        );
        expect(wrapper.delegate, isNull, reason: tooltip);
        expect(wrapper.registrar, isNull, reason: tooltip);
      }
    });

    // Case 11c — a missing value is an EMPTY cell that keeps its column, never
    // the literal string "null".
    testWidgets('a missing field copies as an empty cell',
        (WidgetTester tester) async {
      final List<EdenProjectRow> sparse = <EdenProjectRow>[
        const EdenProjectRow(
          id: 'r1',
          fields: <String, dynamic>{'title': 'Only a title'},
        ),
      ];

      await tester.pumpWidget(_host(rows: sparse));

      await tester.tap(find.byTooltip('Copy row').first);
      await tester.pump();

      expect(captured, 'Only a title\t\t\t\t\t');
      expect(captured, isNot(contains('null')));
    });

    // Case 11d — grouping reorders the rows on screen, so it must reorder them
    // on the clipboard. Grouping is computed INSIDE this widget, which makes
    // this the project table's real "view vs source" case.
    testWidgets('copy-table follows group display order',
        (WidgetTester tester) async {
      // Source order is r1 (In Progress) then r2 (Done); grouping by status
      // keeps first-seen group order, so In Progress still leads. Add a third
      // row whose group already exists to prove rows are regrouped rather than
      // emitted in source order.
      final List<EdenProjectRow> rows = <EdenProjectRow>[
        ..._kRows,
        EdenProjectRow(
          id: 'r3',
          fields: <String, dynamic>{
            'title': 'Third',
            'status': 'In Progress',
            'priority': 'High',
            'owner': 'Ada Lovelace',
            'due': DateTime(2026, 1, 2),
            'points': 1,
          },
        ),
      ];

      await tester.pumpWidget(_host(rows: rows, groupByFieldId: 'status'));

      await tester.tap(find.byTooltip('Copy table'));
      await tester.pump();

      final List<String> lines = captured!.split('\n');
      // Header, then the two In Progress rows adjacent, then the Done row —
      // NOT the r1, r2, r3 order they were supplied in.
      expect(lines.first, startsWith('Title\t'));
      expect(lines[1], startsWith('Ship the grid\t'));
      expect(lines[2], startsWith('Third\t'));
      expect(lines[3], startsWith('Write the docs\t'));
    });

    // Case 11e — the inline cell editor carries an explicit purpose, so the
    // wave-5/6 sweep does not need to reopen this file.
    testWidgets('the inline cell editor carries a resolved field purpose',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1400,
              child: SingleChildScrollView(
                child: EdenProjectTable(
                  fields: _kFields,
                  rows: _kRows,
                  copyable: true,
                  // The editor only exists once editing is possible.
                  onCellChanged: (String r, String f, dynamic v) {},
                ),
              ),
            ),
          ),
        ),
      );

      // A status cell opens its editor on a SINGLE tap. Deliberately not the
      // text cell, which opens on double tap and leaves the double-tap
      // recognizer's timer pending past teardown — that trips the binding's
      // `!timersPending` invariant and fails the test after its assertions have
      // already passed, which is a confusing way to learn nothing.
      await tester.tap(find.text('In Progress'));
      await tester.pump();

      final Finder editor = find.byType(TextField);
      expect(editor, findsOneWidget);

      final TextField field = tester.widget<TextField>(editor);
      final EdenFieldSemantics expected = EdenFieldPurpose.none.semantics;

      // `none` is a RESOLVED purpose, not an absent one: it still pins a
      // keyboardType, which is the half that `autofillHints` alone can never
      // fix (40-RESEARCH.md Appendix B1).
      expect(field.keyboardType, expected.keyboardType);
      expect(field.textInputAction, expected.textInputAction);
      expect(field.textCapitalization, expected.textCapitalization);
      expect(field.autocorrect, expected.autocorrect);
      expect(field.enableSuggestions, expected.enableSuggestions);
      // A cell editor has no autofill meaning; one controller serves every
      // column, so any hint would be wrong for most cells.
      expect(field.autofillHints, isNull);
      expect(field.obscureText, isFalse);
    });
  });
}
