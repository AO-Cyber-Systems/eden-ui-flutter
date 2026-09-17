// TRD 40-05 — EdenKeyValueTable copy-table, asserted against a real clipboard.
//
// This table already holds Strings, so no widget-text extraction is involved:
// the interesting risks are (a) that the new copyable flag does not disturb the
// existing per-row onCopy API, and (b) that a tab hiding inside a value cannot
// corrupt the pasted grid.
//
// Same clipboard-mock pattern as eden_data_table_copy_test.dart.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  const List<EdenKeyValue> items = <EdenKeyValue>[
    EdenKeyValue(key: 'Status', value: 'Active'),
    EdenKeyValue(key: 'Region', value: 'us-east-1'),
  ];

  testWidgets('copy table writes key then TAB then value, one pair per line',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      const EdenKeyValueTable(items: items, copyable: true),
    ));

    await tester.tap(find.byTooltip('Copy table'));
    await tester.pump();

    expect(captured, 'Status\tActive\nRegion\tus-east-1');
  });

  testWidgets('a value containing a tab does not corrupt the grid',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      const EdenKeyValueTable(
        items: <EdenKeyValue>[
          EdenKeyValue(key: 'Note', value: 'before\tafter'),
          EdenKeyValue(key: 'Body', value: 'line1\nline2'),
        ],
        copyable: true,
      ),
    ));

    await tester.tap(find.byTooltip('Copy table'));
    await tester.pump();

    expect(captured, 'Note\tbefore after\nBody\tline1 line2');

    final List<String> lines = captured!.split('\n');
    expect(
      lines.length,
      2,
      reason: 'a raw newline in a value would split one pair into two rows',
    );
    for (final String line in lines) {
      expect(
        line.split('\t').length,
        2,
        reason: 'a raw tab in a value would shift every later column, '
            'silently, on paste — TSV has no escaping mechanism',
      );
    }
  });

  testWidgets('the existing onCopy callback still fires and is unchanged',
      (WidgetTester tester) async {
    int? copiedIndex;
    await tester.pumpWidget(wrap(
      EdenKeyValueTable(
        items: items,
        onCopy: (int index) => () => copiedIndex = index,
      ),
    ));

    expect(find.byTooltip('Copy value'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Copy value').last);
    await tester.pump();

    expect(copiedIndex, 1);
    expect(
      captured,
      isNull,
      reason: 'onCopy is a caller callback; it does not itself touch the '
          'clipboard, and TRD 40-05 must not change that',
    );
    expect(
      find.byTooltip('Copy table'),
      findsNothing,
      reason: 'copyable is independent of onCopy and still defaults to false',
    );
  });

  testWidgets('copyable and onCopy coexist', (WidgetTester tester) async {
    int? copiedIndex;
    await tester.pumpWidget(wrap(
      EdenKeyValueTable(
        items: items,
        copyable: true,
        onCopy: (int index) => () => copiedIndex = index,
      ),
    ));

    expect(find.byTooltip('Copy value'), findsNWidgets(2));
    expect(find.byTooltip('Copy table'), findsOneWidget);

    await tester.tap(find.byTooltip('Copy value').first);
    await tester.pump();
    expect(copiedIndex, 0);

    await tester.tap(find.byTooltip('Copy table'));
    await tester.pump();
    expect(captured, 'Status\tActive\nRegion\tus-east-1');
  });

  testWidgets('the per-row onCopy button sits in a SelectionContainer.disabled',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(
      EdenKeyValueTable(items: items, onCopy: (int index) => () {}),
    ));

    final Finder container = find
        .ancestor(
          of: find.byTooltip('Copy value').first,
          matching: find.byType(SelectionContainer),
        )
        .first;
    final SelectionContainer widget =
        tester.widget<SelectionContainer>(container);
    expect(widget.delegate, isNull);
    expect(
      widget.registrar,
      isNull,
      reason: 'a drag-select across the table must not pick up "Copy value"',
    );
  });
}
