import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // TRD 40-07: EdenCard's title/subtitle used to be SelectableText when the
  // card had no onTap. SelectableText nested inside a SelectionArea is an
  // un-draggable selection island (40-RESEARCH.md section 5), so the leaf is
  // now plain Text and selectability is owned by the ambient
  // EdenSelectableRegion that the Eden layouts and pages install (TRD 40-06).
  //
  // These tests therefore assert the SAME capability at its NEW owner: the
  // text renders, it is NOT a selection island, and it sits under a real
  // SelectableRegion that makes it selectable.
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: EdenSelectableRegion(child: child),
      ),
    );
  }

  group('EdenCard text selection', () {
    testWidgets('title text is selectable via the ambient region',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCard(title: 'Test Title'),
      ));
      await tester.pump();

      expect(find.text('Test Title'), findsOneWidget,
          reason: 'the title must still render');

      expect(
        find.descendant(
          of: find.byType(SelectableRegion),
          matching: find.text('Test Title'),
        ),
        findsOneWidget,
        reason:
            'EdenCard title must sit under the ambient EdenSelectableRegion so '
            'users can select and copy it, and so a drag can continue THROUGH '
            'it into surrounding content.',
      );
    });

    testWidgets('subtitle text is selectable via the ambient region',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCard(title: 'Card Title', subtitle: 'Test Subtitle'),
      ));
      await tester.pump();

      expect(find.text('Test Subtitle'), findsOneWidget,
          reason: 'the subtitle must still render');

      expect(
        find.descendant(
          of: find.byType(SelectableRegion),
          matching: find.text('Test Subtitle'),
        ),
        findsOneWidget,
        reason:
            'EdenCard subtitle must sit under the ambient EdenSelectableRegion '
            'so users can select and copy it.',
      );
    });

    testWidgets('an interactive card renders the SAME plain Text leaves',
        (tester) async {
      // The old code branched on `onTap == null` and only made read-only cards
      // selectable. Under a region that branch is obsolete: both variants must
      // render identically selectable text, and onTap must still fire.
      var taps = 0;
      await tester.pumpWidget(wrap(
        EdenCard(
          title: 'Tappable Title',
          subtitle: 'Tappable Subtitle',
          onTap: () => taps++,
        ),
      ));
      await tester.pump();

      for (final label in <String>['Tappable Title', 'Tappable Subtitle']) {
        expect(
          find.descendant(
            of: find.byType(SelectableRegion),
            matching: find.text(label),
          ),
          findsOneWidget,
          reason:
              'an interactive card must be just as selectable as a read-only '
              'one now that the text widget no longer owns selection',
        );
      }

      await tester.tap(find.text('Tappable Title'));
      await tester.pump();
      expect(taps, 1,
          reason:
              'collapsing the branch must not cost the card its tap handling');
    });
  });
}
