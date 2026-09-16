// test/widgets/eden_data_grid_copy_test.dart
//
// TRD 40-08 — EdenDataGrid TSV clipboard.
//
// Every assertion here reads what actually reached the SYSTEM clipboard, via a
// mock on SystemChannels.platform. A test that inspected an internal helper
// would keep passing after the widget stopped calling Clipboard.setData at all.
//
// The delimiters are written as escape sequences, never as literal bytes: a raw
// tab in a Dart string literal is invisible in review, and a raw control byte in
// a source file blinds grep entirely (40-RESEARCH.md Appendix B4).

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// One row of the hand-built fixture grid.
class _Person {
  const _Person(this.name, this.role, this.score);
  final String name;
  final String role;
  final int score;
}

const List<_Person> _kPeople = <_Person>[
  _Person('Alice', 'Admin', 3),
  _Person('Bob', 'User', 1),
  _Person('Carol', 'User', 2),
];

List<EdenGridColumn<_Person>> _columns({
  String Function(_Person)? scoreCopyValue,
  bool nameFilterable = false,
}) {
  return <EdenGridColumn<_Person>>[
    EdenGridColumn<_Person>(
      id: 'name',
      label: 'Name',
      filterable: nameFilterable,
      cellBuilder: (_Person row, int index) => Text(row.name),
    ),
    EdenGridColumn<_Person>(
      id: 'role',
      label: 'Role',
      cellBuilder: (_Person row, int index) => Text(row.role),
    ),
    EdenGridColumn<_Person>(
      id: 'score',
      label: 'Score',
      // Renders an ICON, which yields no text at all. Without an explicit
      // copyValue this column is structurally uncopyable.
      cellBuilder: (_Person row, int index) => const Icon(Icons.star),
      copyValue: scoreCopyValue,
    ),
  ];
}

Widget _host({
  required List<_Person> rows,
  bool copyable = true,
  List<EdenGridColumn<_Person>>? columns,
  Set<String>? hiddenColumns,
  void Function(String columnId, String value)? onFilter,
  bool selectable = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 1200,
        height: 600,
        child: EdenDataGrid<_Person>(
          columns: columns ?? _columns(),
          rows: rows,
          copyable: copyable,
          hiddenColumns: hiddenColumns,
          onFilter: onFilter,
          selectable: selectable,
        ),
      ),
    ),
  );
}

void main() {
  /// The text the widget under test actually put on the clipboard.
  String? captured;

  setUp(() {
    captured = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform,
            (MethodCall call) async {
      if (call.method == 'Clipboard.setData') {
        // SystemChannels.platform uses JSONMethodCodec, so the decoded
        // arguments are Map<String, dynamic>. The loose cast is the correct
        // one for both codecs.
        captured = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('EdenDataGrid copy', () {
    // Case 1.
    testWidgets('copy-row writes tab-delimited text for that row',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        rows: _kPeople,
        columns: _columns(scoreCopyValue: (_Person p) => p.score.toString()),
      ));

      await tester.tap(find.byTooltip('Copy row').first);
      await tester.pump();

      expect(captured, 'Alice\tAdmin\t3');
    });

    // Case 1b — a row copy must never smuggle in the header line.
    testWidgets('copy-row emits no header line', (WidgetTester tester) async {
      await tester.pumpWidget(_host(rows: _kPeople));

      await tester.tap(find.byTooltip('Copy row').first);
      await tester.pump();

      expect(captured, isNot(contains('Name')));
      expect(captured, isNot(contains('\n')));
    });

    // Case 2.
    testWidgets('copy-table writes the header then every row',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        rows: _kPeople,
        columns: _columns(scoreCopyValue: (_Person p) => p.score.toString()),
      ));

      await tester.tap(find.byTooltip('Copy table'));
      await tester.pump();

      expect(
        captured,
        'Name\tRole\tScore\n'
        'Alice\tAdmin\t3\n'
        'Bob\tUser\t1\n'
        'Carol\tUser\t2',
      );
    });

    // Case 2b — no trailing terminator, or a spreadsheet gains a phantom row.
    testWidgets('copy-table emits no trailing newline',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(rows: _kPeople));

      await tester.tap(find.byTooltip('Copy table'));
      await tester.pump();

      expect(captured, isNotNull);
      expect(captured!.endsWith('\n'), isFalse);
    });

    // Case 3 — THE case that catches "copied the source list, not the view".
    //
    // EdenDataGrid is a CONTROLLED widget: onFilter only reports intent and the
    // owner passes the narrowed list back through `rows`. So filtering is driven
    // here exactly as a real consumer drives it — type into the filter field,
    // then rebuild with the result.
    testWidgets('copy-table after filtering copies only the visible rows',
        (WidgetTester tester) async {
      final List<String> filterCalls = <String>[];

      await tester.pumpWidget(_host(
        rows: _kPeople,
        columns: _columns(nameFilterable: true),
        onFilter: (String columnId, String value) =>
            filterCalls.add('$columnId=$value'),
      ));

      await tester.enterText(find.byType(TextField).first, 'User');
      await tester.pump();
      // The grid reported the filter rather than applying it itself.
      expect(filterCalls, <String>['name=User']);

      // The owner applies it and passes the narrowed view back.
      final List<_Person> filtered =
          _kPeople.where((_Person p) => p.role == 'User').toList();
      await tester.pumpWidget(_host(
        rows: filtered,
        columns: _columns(nameFilterable: true),
        onFilter: (String columnId, String value) {},
      ));

      await tester.tap(find.byTooltip('Copy table'));
      await tester.pump();

      expect(captured, contains('Bob'));
      expect(captured, contains('Carol'));
      // The excluded row must be absent.
      expect(captured, isNot(contains('Alice')));
      expect(captured, isNot(contains('Admin')));
    });

    // Case 4.
    testWidgets('copy-table after sorting copies in the displayed order',
        (WidgetTester tester) async {
      final List<_Person> descending = <_Person>[..._kPeople]
        ..sort((_Person a, _Person b) => b.name.compareTo(a.name));

      await tester.pumpWidget(_host(rows: descending));

      await tester.tap(find.byTooltip('Copy table'));
      await tester.pump();

      expect(
        captured,
        'Name\tRole\tScore\n'
        'Carol\tUser\t\n'
        'Bob\tUser\t\n'
        'Alice\tAdmin\t',
      );
    });

    // Case 5.
    testWidgets('copyValue accessor wins over widget extraction',
        (WidgetTester tester) async {
      final List<EdenGridColumn<_Person>> columns = <EdenGridColumn<_Person>>[
        EdenGridColumn<_Person>(
          id: 'name',
          label: 'Name',
          // The cell renders one thing; the datum is another.
          cellBuilder: (_Person row, int index) => Text(row.name.toUpperCase()),
          copyValue: (_Person row) => row.name,
        ),
      ];

      await tester.pumpWidget(_host(rows: _kPeople, columns: columns));

      await tester.tap(find.byTooltip('Copy row').first);
      await tester.pump();

      expect(captured, 'Alice');
      expect(captured, isNot('ALICE'));
    });

    // Case 5b — the fallback, and that a textless cell becomes EMPTY, never
    // the literal string "null".
    testWidgets('a cell with no text copies as an empty cell',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(rows: _kPeople));

      await tester.tap(find.byTooltip('Copy row').first);
      await tester.pump();

      expect(captured, 'Alice\tAdmin\t');
      expect(captured, isNot(contains('null')));
    });

    // Case 5c — a column that declares NO cellBuilder at all. Distinct from a
    // cell that renders something textless: there is no widget to extract from,
    // so this is its own branch, and the mutation sweep found it uncovered
    // while 5b passed (40-RESEARCH.md Appendix B5 — one mutation per path).
    testWidgets('a column with no cellBuilder copies as an empty cell',
        (WidgetTester tester) async {
      final List<EdenGridColumn<_Person>> columns = <EdenGridColumn<_Person>>[
        EdenGridColumn<_Person>(
          id: 'name',
          label: 'Name',
          cellBuilder: (_Person row, int index) => Text(row.name),
        ),
        // No cellBuilder, no copyValue. The grid renders SizedBox.shrink here.
        const EdenGridColumn<_Person>(id: 'blank', label: 'Blank'),
      ];

      await tester.pumpWidget(_host(rows: _kPeople, columns: columns));

      await tester.tap(find.byTooltip('Copy row').first);
      await tester.pump();

      expect(captured, 'Alice\t');
      expect(captured, isNot(contains('null')));
    });

    // Case 6.
    testWidgets('copyable: false renders no affordance',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(rows: _kPeople, copyable: false));

      expect(find.byTooltip('Copy table'), findsNothing);
      expect(find.byTooltip('Copy row'), findsNothing);
    });

    // Case 7.
    testWidgets('the copy affordances sit inside SelectionContainer.disabled',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(rows: _kPeople));

      // SelectionContainer.disabled is the named constructor that leaves BOTH
      // registrar and delegate null; a plain SelectionContainer requires a
      // delegate. That pair is the discriminator.
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

    // Case 8.
    testWidgets('the column filter field carries a resolved field purpose',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        rows: _kPeople,
        columns: _columns(nameFilterable: true),
        onFilter: (String columnId, String value) {},
      ));

      final TextField field = tester.widget<TextField>(
        find.byType(TextField).first,
      );
      final EdenFieldSemantics expected =
          EdenFieldPurpose.searchQuery.semantics;

      // A search box resolves NO autofill hints — there is no AutofillHints
      // constant for a search query — so the proof that a purpose was applied
      // is the resolved keyboard and action, not the presence of hints.
      // Asserting on hints alone would certify a field that carries hints and
      // a contradictory keyboard (40-RESEARCH.md Appendix B1).
      expect(field.keyboardType, expected.keyboardType);
      expect(field.textInputAction, expected.textInputAction);
      expect(field.textInputAction, TextInputAction.search);
      expect(field.autofillHints, expected.autofillHints);
      expect(field.autocorrect, expected.autocorrect);
      expect(field.enableSuggestions, expected.enableSuggestions);
      expect(field.obscureText, isFalse);
      // Probe 3: a normal field is already selectable and copyable, so nothing
      // here disables interactive selection. Asserted as `true` rather than
      // `null` because `TextField` resolves the default in its own initializer
      // list — the same early-resolution that makes Flutter's keyboard
      // inference unreachable (40-RESEARCH.md Appendix B1) — so an unset
      // argument still reads back as `true`.
      expect(field.enableInteractiveSelection, isTrue);
    });

    // Case 8b — the other half of "copy the view": a HIDDEN column is on the
    // source list but not on the screen, and the divergence is computed INSIDE
    // this widget rather than by its owner.
    testWidgets('copy-table omits hidden columns',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        rows: _kPeople,
        hiddenColumns: <String>{'role'},
      ));

      await tester.tap(find.byTooltip('Copy table'));
      await tester.pump();

      expect(captured, startsWith('Name\tScore'));
      expect(captured, isNot(contains('Role')));
      expect(captured, isNot(contains('Admin')));
    });

    // Case 8c — pinned columns float to the front on screen, so they must do
    // the same on the clipboard.
    testWidgets('copy-table follows the on-screen column order',
        (WidgetTester tester) async {
      final List<EdenGridColumn<_Person>> columns = <EdenGridColumn<_Person>>[
        EdenGridColumn<_Person>(
          id: 'name',
          label: 'Name',
          cellBuilder: (_Person row, int index) => Text(row.name),
        ),
        EdenGridColumn<_Person>(
          id: 'role',
          label: 'Role',
          pinned: true,
          cellBuilder: (_Person row, int index) => Text(row.role),
        ),
      ];

      // `selectable: true` is required, not incidental. The pinned layout builds
      // its frozen side with `includeCheckbox: true` unconditionally, so it
      // always renders a 48px checkbox slot — but `_pinnedColumnsWidth` only
      // reserves those 48px when `selectable` is set. With `selectable: false` a
      // pinned grid therefore overflows its own frozen region by exactly 48px.
      // That is pre-existing (40-08 touches neither expression) and this TRD is
      // explicitly not a pinning refactor, so the fixture stays on the
      // non-overflowing side of it rather than asserting through a layout bug.
      await tester.pumpWidget(
        _host(rows: _kPeople, columns: columns, selectable: true),
      );

      await tester.tap(find.byTooltip('Copy table').first);
      await tester.pump();

      // Declared name-then-role; rendered and copied role-then-name.
      expect(captured, startsWith('Role\tName\n'));
      expect(captured, contains('Admin\tAlice'));
    });

    // Case 8d — a cell value containing a tab must not shift the grid.
    testWidgets('a tab inside a value collapses instead of adding a column',
        (WidgetTester tester) async {
      const List<_Person> messy = <_Person>[_Person('a\tb', 'Admin', 1)];
      await tester.pumpWidget(_host(rows: messy));

      await tester.tap(find.byTooltip('Copy row').first);
      await tester.pump();

      expect(captured, 'a b\tAdmin\t');
      expect('\t'.allMatches(captured!).length, 2);
    });
  });
}
