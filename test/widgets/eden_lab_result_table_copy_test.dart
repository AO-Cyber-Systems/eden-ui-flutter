// test/widgets/eden_lab_result_table_copy_test.dart
//
// TRD 40-08 — EdenLabResultTable TSV clipboard.
//
// Asserts what reached the SYSTEM clipboard, via a mock on
// SystemChannels.platform. Delimiters are written as escape sequences, never as
// literal bytes (40-RESEARCH.md Appendix B4).

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

EdenLabResult _result({
  required String id,
  required String testName,
  required String testCode,
  required double value,
  String unit = 'g/dL',
  double? referenceMin,
  double? referenceMax,
  EdenLabFlag flag = EdenLabFlag.normal,
  DateTime? collectedAt,
  List<double>? trendValues,
  String? notes,
}) {
  return EdenLabResult(
    id: id,
    patientId: 'p1',
    testName: testName,
    testCode: testCode,
    value: value,
    unit: unit,
    collectedAt: collectedAt ?? DateTime(2026, 3, 9),
    referenceMin: referenceMin,
    referenceMax: referenceMax,
    flag: flag,
    trendValues: trendValues,
    notes: notes,
  );
}

/// Two results, deliberately ordered so that sorting by test name REVERSES
/// them relative to the default date sort.
final List<EdenLabResult> _kResults = <EdenLabResult>[
  _result(
    id: '1',
    testName: 'Hemoglobin',
    testCode: 'HGB',
    value: 13.5,
    referenceMin: 12,
    referenceMax: 16,
    collectedAt: DateTime(2026, 3, 9),
    notes: 'fasting',
  ),
  _result(
    id: '2',
    testName: 'Albumin',
    testCode: 'ALB',
    value: 5,
    unit: 'g/L',
    flag: EdenLabFlag.criticalHigh,
    collectedAt: DateTime(2026, 1, 2),
  ),
];

Widget _host({List<EdenLabResult>? results, bool copyable = true}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 900,
        child: SingleChildScrollView(
          child: EdenLabResultTable(
            results: results ?? _kResults,
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

  group('EdenLabResultTable copy', () {
    // Case 12 — the column contract, pinned as one exact string.
    testWidgets('a row copies test, code, value, unit, range, flag, date, notes',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        results: <EdenLabResult>[_kResults.first],
      ));

      await tester.tap(find.byTooltip('Copy row').first);
      await tester.pump();

      expect(
        captured,
        'Hemoglobin\tHGB\t13.5\tg/dL\t12-16\tnormal\t2026-03-09\tfasting',
      );
    });

    // Case 13 — the reference range.
    testWidgets('reference range copies as min-max',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        results: <EdenLabResult>[_kResults.first],
      ));

      await tester.tap(find.byTooltip('Copy row').first);
      await tester.pump();

      expect(captured!.split('\t')[4], '12-16');
    });

    // Case 13b — and is EMPTY when both bounds are null. The cell renders an em
    // dash, which is a typographic placeholder rather than a value.
    testWidgets('reference range copies empty when both bounds are null',
        (WidgetTester tester) async {
      final EdenLabResult unbounded = _result(
        id: '9',
        testName: 'Mystery',
        testCode: 'MYS',
        value: 1,
      );

      await tester.pumpWidget(_host(results: <EdenLabResult>[unbounded]));

      // The dash really is on screen, so this is discriminating rather than
      // vacuous.
      expect(find.text('—'), findsWidgets);

      await tester.tap(find.byTooltip('Copy row').first);
      await tester.pump();

      expect(captured!.split('\t')[4], '');
      expect(captured, isNot(contains('—')));
    });

    // Case 14 — the flag copies its human label, not its clinical abbreviation.
    testWidgets('flag copies as its human label', (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        results: <EdenLabResult>[_kResults.last],
      ));

      // 'HH' is what the cell renders.
      expect(find.text('HH'), findsOneWidget);

      await tester.tap(find.byTooltip('Copy row').first);
      await tester.pump();

      final List<String> cells = captured!.split('\t');
      expect(cells[5], 'critical high');
      expect(cells, isNot(contains('HH')));
    });

    // Case 14b — every flag has a label, and `normal` is a word rather than the
    // blank it renders. An empty cell would read as "no flag recorded".
    test('every flag maps to a human label', () {
      expect(EdenLabFlag.normal.label, 'normal');
      expect(EdenLabFlag.high.label, 'high');
      expect(EdenLabFlag.low.label, 'low');
      expect(EdenLabFlag.criticalHigh.label, 'critical high');
      expect(EdenLabFlag.criticalLow.label, 'critical low');
    });

    // Case 15 — copy honours the ACTIVE sort, which this widget owns
    // internally. Default sort is date DESCENDING.
    testWidgets('copy-table honours the active sort',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host());

      await tester.tap(find.byTooltip('Copy table'));
      await tester.pump();

      List<String> lines = captured!.split('\n');
      // Newest first: Hemoglobin (March) before Albumin (January).
      expect(lines[1], startsWith('Hemoglobin\t'));
      expect(lines[2], startsWith('Albumin\t'));

      // Re-sort by test name ascending, then copy again.
      captured = null;
      await tester.tap(find.text('Test'));
      await tester.pump();

      await tester.tap(find.byTooltip('Copy table'));
      await tester.pump();

      lines = captured!.split('\n');
      // Alphabetical now: Albumin leads. If copy read the source list instead
      // of the sorted view, this would still say Hemoglobin.
      expect(lines[1], startsWith('Albumin\t'));
      expect(lines[2], startsWith('Hemoglobin\t'));
    });

    // Case 16 — the sparkline series is not copied.
    testWidgets('trendValues is absent from the copied text',
        (WidgetTester tester) async {
      final EdenLabResult trended = _result(
        id: '7',
        testName: 'Glucose',
        testCode: 'GLU',
        value: 99,
        trendValues: <double>[41.7, 42.9, 43.1],
      );

      await tester.pumpWidget(_host(results: <EdenLabResult>[trended]));

      await tester.tap(find.byTooltip('Copy row').first);
      await tester.pump();

      for (final double v in <double>[41.7, 42.9, 43.1]) {
        expect(captured, isNot(contains(v.toString())));
      }
      // Eight columns, so seven tabs — the trend adds no column of its own.
      expect('\t'.allMatches(captured!).length, 7);
    });

    // Case 16b — the date is ISO-8601, not the rendered MM/DD/YY.
    testWidgets('date copies as ISO-8601, not the rendered short form',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        results: <EdenLabResult>[_kResults.first],
      ));

      // '03/09/26' is what the cell renders.
      expect(find.text('03/09/26'), findsOneWidget);

      await tester.tap(find.byTooltip('Copy row').first);
      await tester.pump();

      expect(captured!.split('\t')[6], '2026-03-09');
      expect(captured, isNot(contains('03/09/26')));
    });

    // Case 16c — copy-table writes the header; copy-row never does.
    testWidgets('copy-table writes the header and copy-row does not',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        results: <EdenLabResult>[_kResults.first],
      ));

      await tester.tap(find.byTooltip('Copy table'));
      await tester.pump();
      expect(
        captured,
        'Test\tCode\tValue\tUnit\tRange\tFlag\tDate\tNotes\n'
        'Hemoglobin\tHGB\t13.5\tg/dL\t12-16\tnormal\t2026-03-09\tfasting',
      );

      captured = null;
      await tester.tap(find.byTooltip('Copy row').first);
      await tester.pump();
      expect(captured, isNot(contains('Code')));
      expect(captured, isNot(contains('\n')));
    });

    // Case 16d.
    testWidgets('copyable: false renders no affordance',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(copyable: false));

      expect(find.byTooltip('Copy table'), findsNothing);
      expect(find.byTooltip('Copy row'), findsNothing);
    });

    // Case 16e.
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

    // Case 16f — a null note is an EMPTY trailing cell, never "null".
    testWidgets('a null note copies as an empty cell',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        results: <EdenLabResult>[_kResults.last],
      ));

      await tester.tap(find.byTooltip('Copy row').first);
      await tester.pump();

      expect(captured!.split('\t').last, '');
      expect(captured, isNot(contains('null')));
    });
  });
}
