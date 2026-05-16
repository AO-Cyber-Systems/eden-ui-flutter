import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_activity_feed_item_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenActivityFeedItem', () {
    testWidgets(
        'renders actor + action + entity + initials + timeAgo for success variant',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenActivityFeedItem(
          item: EdenActivityFeedItemFixtures.successSample,
        ),
      ));
      expect(find.text('JS'), findsOneWidget);
      expect(find.text('5m ago'), findsOneWidget);
      // RichText: actor + action + entity composed inside a single TextSpan
      final richText = tester.widget<RichText>(find.byType(RichText).first);
      final span = richText.text as TextSpan;
      final flat = _flatten(span);
      expect(flat, contains('John Smith'));
      expect(flat, contains(' created '));
      expect(flat, contains('Customer #42'));
    });

    testWidgets('variant=warning tints avatar initials orange', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenActivityFeedItem(
          item: EdenActivityFeedItemFixtures.warningSample,
        ),
      ));
      final initialsText = tester.widget<Text>(find.text('MG'));
      expect(initialsText.style?.color, Colors.orange);
    });

    testWidgets('variant=danger tints avatar initials red', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenActivityFeedItem(
          item: EdenActivityFeedItemFixtures.dangerSample,
        ),
      ));
      final initialsText = tester.widget<Text>(find.text('AP'));
      expect(initialsText.style?.color, Colors.red);
    });

    testWidgets('variant=info uses theme.colorScheme.primary',
        (tester) async {
      final theme = ThemeData.light();
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: EdenActivityFeedItem(
            item: EdenActivityFeedItemFixtures.infoSample,
          ),
        ),
      ));
      final initialsText = tester.widget<Text>(find.text('DB'));
      expect(initialsText.style?.color, theme.colorScheme.primary);
    });

    testWidgets('avatar container is 36×36 circle',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenActivityFeedItem(
          item: EdenActivityFeedItemFixtures.successSample,
        ),
      ));
      final avatar = tester.widget<Container>(
        find.ancestor(of: find.text('JS'), matching: find.byType(Container)).first,
      );
      expect(avatar.constraints?.maxWidth, 36);
      expect(avatar.constraints?.maxHeight, 36);
      final decoration = avatar.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('initials Text has fontSize 13 + FontWeight.w700',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenActivityFeedItem(
          item: EdenActivityFeedItemFixtures.successSample,
        ),
      ));
      final initialsText = tester.widget<Text>(find.text('JS'));
      expect(initialsText.style?.fontSize, 13);
      expect(initialsText.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('onTap callback fires when row is tapped',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        EdenActivityFeedItem(
          item: EdenActivityFeedItemFixtures.successSample,
          onTap: () => tapped = true,
        ),
      ));
      await tester.tap(find.byType(EdenActivityFeedItem));
      expect(tapped, isTrue);
    });

    testWidgets('onTap null → no InkWell wrapper inside the item subtree',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenActivityFeedItem(
          item: EdenActivityFeedItemFixtures.successSample,
        ),
      ));
      final inkwellsInside = find.descendant(
        of: find.byType(EdenActivityFeedItem),
        matching: find.byType(InkWell),
      );
      expect(inkwellsInside, findsNothing);
    });

    testWidgets(
        'iPhone-narrow: no overflow inside SizedBox(width: 390) for all 4 variants',
        (tester) async {
      const samples = [
        EdenActivityFeedItemFixtures.successSample,
        EdenActivityFeedItemFixtures.warningSample,
        EdenActivityFeedItemFixtures.dangerSample,
        EdenActivityFeedItemFixtures.infoSample,
      ];
      for (final sample in samples) {
        await tester.pumpWidget(wrap(
          SizedBox(
            width: 390,
            child: EdenActivityFeedItem(item: sample),
          ),
        ));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('long entity name wraps without overflow at iPhone-narrow',
        (tester) async {
      await tester.pumpWidget(wrap(
        const SizedBox(
          width: 390,
          child: EdenActivityFeedItem(
            item: EdenActivityFeedItemFixtures.longEntitySample,
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('long initials (ABCDE) still render inside 36×36 avatar',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenActivityFeedItem(
          item: EdenActivityFeedItemData(
            actorName: 'X',
            actorInitials: 'ABCDE',
            action: 'did',
            entityName: 'Thing',
            timeAgo: 'now',
            variant: EdenActivityVariant.info,
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('ABCDE'), findsOneWidget);
    });
  });
}

String _flatten(TextSpan span) {
  final buf = StringBuffer();
  span.visitChildren((node) {
    if (node is TextSpan && node.text != null) {
      buf.write(node.text);
    }
    return true;
  });
  return buf.toString();
}
