import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_media_row_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenMediaRow', () {
    testWidgets('empty items list renders only SizedBox.shrink',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenMediaRow(items: <EdenMediaRowItem>[]),
      ));
      expect(find.text('+ Add'), findsNothing);
      expect(find.byType(Container), findsNothing);
    });

    testWidgets(
        'happy path: 3 cells (photos + docs onAdd + budget trailing) render',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenMediaRow(items: [
          EdenMediaRowFixtures.photosItem(onAdd: () {}),
          EdenMediaRowFixtures.docsItem(onAdd: () {}),
          EdenMediaRowFixtures.budgetItem(),
        ]),
      ));
      expect(find.text('7 photos'), findsOneWidget);
      expect(find.text('3 documents'), findsOneWidget);
      expect(find.text(r'$24,500 budget'), findsOneWidget);
      // 2 + Add (photos + docs), 1 trailing '1 CO'
      expect(find.text('+ Add'), findsNWidgets(2));
      expect(find.text('1 CO'), findsOneWidget);
    });

    testWidgets("count + label combine to '7 photos'",
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenMediaRow(items: [EdenMediaRowFixtures.photosItem()]),
      ));
      expect(find.text('7 photos'), findsOneWidget);
    });

    testWidgets('label-only (no count) renders just the label',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenMediaRow(items: [EdenMediaRowFixtures.noCountItem]),
      ));
      expect(find.text('favorited'), findsOneWidget);
    });

    testWidgets(
        r'count + label combine to $24,500 budget for budgetItem',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenMediaRow(items: [EdenMediaRowFixtures.budgetItem()]),
      ));
      expect(find.text(r'$24,500 budget'), findsOneWidget);
    });

    testWidgets('onAddPressed renders + Add and fires callback on tap',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        EdenMediaRow(items: [
          EdenMediaRowFixtures.photosItem(onAdd: () => tapped = true),
        ]),
      ));
      expect(find.text('+ Add'), findsOneWidget);
      await tester.tap(find.text('+ Add'));
      expect(tapped, isTrue);
    });

    testWidgets(
        'onAddPressed null + trailingText set → renders trailingText only',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenMediaRow(items: [EdenMediaRowFixtures.budgetItem(trailing: '1 CO')]),
      ));
      expect(find.text('1 CO'), findsOneWidget);
      expect(find.text('+ Add'), findsNothing);
    });

    testWidgets(
        'onAddPressed null + trailingText null → no + Add, no trailing text',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenMediaRow(items: [EdenMediaRowFixtures.noCountItem]),
      ));
      expect(find.text('+ Add'), findsNothing);
      expect(find.text('1 CO'), findsNothing);
    });

    testWidgets(
        'onAddPressed wins over trailingText (button takes priority)',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenMediaRow(items: [
          EdenMediaRowItem(
            icon: Icons.camera_alt,
            label: 'photos',
            count: '7',
            onAddPressed: () {},
            trailingText: '1 CO',
          ),
        ]),
      ));
      expect(find.text('+ Add'), findsOneWidget);
      expect(find.text('1 CO'), findsNothing);
    });

    testWidgets(
        'iPhone-narrow: no overflow inside SizedBox(width: 390) with 3 cells',
        (tester) async {
      await tester.pumpWidget(wrap(
        SizedBox(
          width: 390,
          child: EdenMediaRow(items: [
            EdenMediaRowFixtures.photosItem(onAdd: () {}),
            EdenMediaRowFixtures.docsItem(onAdd: () {}),
            EdenMediaRowFixtures.budgetItem(),
          ]),
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'long label ellipsizes without overflowing a narrow cell',
        (tester) async {
      await tester.pumpWidget(wrap(
        const SizedBox(
          width: 200,
          child: EdenMediaRow(
              items: [EdenMediaRowFixtures.longLabelItem]),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
