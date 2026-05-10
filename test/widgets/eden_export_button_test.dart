import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('EdenExportButton', () {
    testWidgets('renders default Export label', (tester) async {
      await tester.pumpWidget(wrap(
        EdenExportButton(
          onExportCsv: () {},
          onExportJson: () {},
        ),
      ));

      expect(find.text('Export'), findsOneWidget);
    });

    testWidgets('renders custom label', (tester) async {
      await tester.pumpWidget(wrap(
        EdenExportButton(
          label: 'Download',
          onExportCsv: () {},
        ),
      ));

      expect(find.text('Download'), findsOneWidget);
    });

    testWidgets('shows both menu items when both callbacks provided',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenExportButton(
          onExportCsv: () {},
          onExportJson: () {},
        ),
      ));

      await tester.tap(find.byType(EdenExportButton));
      await tester.pumpAndSettle();

      expect(find.text('Export CSV'), findsOneWidget);
      expect(find.text('Export JSON'), findsOneWidget);
    });

    testWidgets('hides CSV item when onExportCsv is null', (tester) async {
      await tester.pumpWidget(wrap(
        EdenExportButton(
          onExportJson: () {},
        ),
      ));

      await tester.tap(find.byType(EdenExportButton));
      await tester.pumpAndSettle();

      expect(find.text('Export CSV'), findsNothing);
      expect(find.text('Export JSON'), findsOneWidget);
    });

    testWidgets('invokes onExportCsv when CSV item selected',
        (tester) async {
      var csvCalled = false;
      var jsonCalled = false;
      await tester.pumpWidget(wrap(
        EdenExportButton(
          onExportCsv: () => csvCalled = true,
          onExportJson: () => jsonCalled = true,
        ),
      ));

      await tester.tap(find.byType(EdenExportButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export CSV'));
      await tester.pumpAndSettle();

      expect(csvCalled, isTrue);
      expect(jsonCalled, isFalse);
    });

    testWidgets('invokes onExportJson when JSON item selected',
        (tester) async {
      var jsonCalled = false;
      await tester.pumpWidget(wrap(
        EdenExportButton(
          onExportCsv: () {},
          onExportJson: () => jsonCalled = true,
        ),
      ));

      await tester.tap(find.byType(EdenExportButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export JSON'));
      await tester.pumpAndSettle();

      expect(jsonCalled, isTrue);
    });
  });
}
