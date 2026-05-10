import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));
  }

  group('EdenJsonViewer', () {
    testWidgets('renders pretty-printed map', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenJsonViewer(
          data: {'name': 'Eden', 'count': 42},
        ),
      ));

      // EdenCodeBlock should be rendered
      expect(find.byType(EdenCodeBlock), findsOneWidget);
    });

    testWidgets('parses JSON string and renders code block', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenJsonViewer(data: '{"a":1,"b":2}'),
      ));

      expect(find.byType(EdenCodeBlock), findsOneWidget);
    });

    testWidgets('falls back to toString on invalid JSON string',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenJsonViewer(data: 'not json {{{'),
      ));

      expect(find.byType(EdenCodeBlock), findsOneWidget);
    });

    testWidgets('renders null as "null"', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenJsonViewer(data: null),
      ));

      expect(find.byType(EdenCodeBlock), findsOneWidget);
    });

    testWidgets('renders list', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenJsonViewer(data: [1, 2, 3]),
      ));

      expect(find.byType(EdenCodeBlock), findsOneWidget);
    });
  });
}
