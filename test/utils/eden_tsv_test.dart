// TRD 40-05 — the TSV dialect, pinned.
//
// `SelectionArea` concatenates a drag-selection in tree order with NO cell
// delimiters (40-RESEARCH.md section 5), so a table that wants to paste into a
// spreadsheet has to emit TSV explicitly. These cases pin the dialect every
// Eden table shares, because a silent change to it corrupts the pasted grid
// rather than producing a visible error.
//
// Pure functions over plain values and Widget objects — no binding, no pump.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('edenTsvRow / edenRowsToTsv — the grid', () {
    test('joins cells with tabs', () {
      expect(edenTsvRow(<String>['a', 'b', 'c']), 'a\tb\tc');
    });

    test('joins rows with newlines and emits no trailing newline', () {
      final String tsv = edenRowsToTsv(<List<String>>[
        <String>['a', 'b'],
        <String>['c', 'd'],
      ]);
      expect(tsv, 'a\tb\nc\td');
      expect(
        tsv.endsWith('\n'),
        isFalse,
        reason: 'a trailing newline pastes into a spreadsheet as a phantom '
            'empty row, which then shows up in row counts and in any '
            'downstream SUM/COUNTA',
      );
    });

    test('header row is emitted first when supplied', () {
      expect(
        edenRowsToTsv(
          <List<String>>[
            <String>['a', 'b'],
          ],
          header: <String>['Name', 'Role'],
        ),
        'Name\tRole\na\tb',
      );
    });

    test('no header is emitted when none is supplied', () {
      expect(
        edenRowsToTsv(<List<String>>[
          <String>['a', 'b'],
        ]),
        'a\tb',
        reason: 'copy-row must never smuggle column labels onto the clipboard',
      );
    });

    test('an empty grid produces an empty string', () {
      expect(edenRowsToTsv(<List<String>>[]), '');
    });

    test('an empty grid with a header emits just the header line', () {
      expect(
        edenRowsToTsv(<List<String>>[], header: <String>['A', 'B']),
        'A\tB',
        reason: 'the caller asked for column names; copying an empty table '
            'puts its columns on the clipboard',
      );
    });

    test('ragged rows are preserved as-is', () {
      expect(
        edenRowsToTsv(<List<String>>[
          <String>['a', 'b', 'c'],
          <String>['d'],
        ]),
        'a\tb\tc\nd',
        reason: 'padding to the widest row would invent cells the caller never '
            'supplied and hide the modelling bug that produced the ragged grid',
      );
    });

    test('an empty cell stays empty and keeps its column', () {
      expect(
        edenTsvRow(<String>['a', '', 'c']),
        'a\t\tc',
        reason: 'the delimiters around a blank are still emitted, so column '
            'alignment survives an empty value',
      );
    });
  });

  group('edenTsvCell — normalisation', () {
    test('a tab inside a cell is collapsed to a space', () {
      expect(edenTsvCell('a\tb'), 'a b');

      // The structural consequence, which is the reason the rule exists.
      final String row = edenTsvRow(<String>['a\tb', 'c']);
      expect(
        row.split('\t').length,
        2,
        reason: 'TSV has no escaping; a raw tab shifts every later column of '
            'the row by one, silently, on paste',
      );
    });

    test('a newline inside a cell is collapsed to a space', () {
      expect(edenTsvCell('line1\nline2'), 'line1 line2');

      final String tsv = edenRowsToTsv(<List<String>>[
        <String>['line1\nline2', 'c'],
      ]);
      expect(
        tsv.split('\n').length,
        1,
        reason: 'a raw newline would split one record into two rows',
      );
    });

    test('a CRLF run collapses to a SINGLE space', () {
      expect(
        edenTsvCell('a\r\nb'),
        'a b',
        reason: 'the run is matched as one, so CRLF does not become 2 spaces',
      );
    });

    test('a lone carriage return is collapsed too', () {
      expect(edenTsvCell('a\rb'), 'a b');
    });

    test('leading and trailing whitespace is trimmed', () {
      expect(edenTsvCell('  padded  '), 'padded');
      expect(
        edenTsvCell('\tleading'),
        'leading',
        reason: 'a breaker becomes a space and is then trimmed away, so a '
            'leading tab does not leave a visible indent in the cell',
      );
    });

    test('an empty value stays empty', () {
      expect(edenTsvCell(''), '');
    });

    test('normal text is passed through untouched', () {
      expect(edenTsvCell('Alice Smith'), 'Alice Smith');
    });
  });

  group('edenExtractWidgetText — best-effort cell text', () {
    test('reads Text.data', () {
      expect(edenExtractWidgetText(const Text('cell value')), 'cell value');
    });

    test('flattens a Text built from a textSpan', () {
      expect(
        edenExtractWidgetText(
          const Text.rich(TextSpan(text: 'span value')),
        ),
        'span value',
      );
    });

    test('reads RichText', () {
      expect(
        edenExtractWidgetText(
          RichText(
            text: const TextSpan(text: 'rich value'),
            textDirection: TextDirection.ltr,
          ),
        ),
        'rich value',
      );
    });

    test('recurses through Padding/Expanded/Row', () {
      expect(
        edenExtractWidgetText(
          const Padding(
            padding: EdgeInsets.zero,
            child: Row(
              children: <Widget>[
                Expanded(child: Text('left')),
                Text('right'),
              ],
            ),
          ),
        ),
        'left right',
        reason: 'multi-child layouts join their textual children with a '
            'single space',
      );
    });

    test('recurses through the other whitelisted single-child wrappers', () {
      expect(edenExtractWidgetText(const Center(child: Text('c'))), 'c');
      expect(edenExtractWidgetText(const SizedBox(child: Text('s'))), 's');
      expect(edenExtractWidgetText(Container(child: const Text('k'))), 'k');
      expect(
        edenExtractWidgetText(
          const Tooltip(message: 'hint', child: Text('t')),
        ),
        't',
      );
    });

    test('returns null for a non-textual widget', () {
      expect(edenExtractWidgetText(const Icon(Icons.star)), isNull);
    });

    test('returns null for a layout whose children are all non-textual', () {
      expect(
        edenExtractWidgetText(
          const Row(
            children: <Widget>[Icon(Icons.star), Icon(Icons.check)],
          ),
        ),
        isNull,
        reason: 'children that yield nothing are skipped, so a Row of icons '
            'returns null rather than a run of spaces',
      );
    });

    test('does not recurse into a button label', () {
      expect(
        edenExtractWidgetText(
          TextButton(onPressed: () {}, child: const Text('Edit')),
        ),
        isNull,
        reason: 'an affordance is not data — recursing would paste the word '
            '"Edit" into a spreadsheet cell as though it were the record',
      );
      expect(
        edenExtractWidgetText(
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.copy),
            tooltip: 'Copy row',
          ),
        ),
        isNull,
      );
      expect(
        edenExtractWidgetText(
          GestureDetector(onTap: () {}, child: const Text('Tap me')),
        ),
        isNull,
      );
    });

    test('descends 8 wrapper levels but not 9', () {
      Widget nest(int levels) {
        Widget w = const Text('deep');
        for (int i = 0; i < levels; i++) {
          w = Padding(padding: EdgeInsets.zero, child: w);
        }
        return w;
      }

      expect(edenExtractWidgetText(nest(8)), 'deep');
      expect(
        edenExtractWidgetText(nest(9)),
        isNull,
        reason: 'the cap keeps a pathological or self-similar tree from '
            'hanging the UI thread on a copy',
      );
    });
  });
}
