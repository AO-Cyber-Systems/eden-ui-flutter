import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_app_tour_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenContextualTip', () {
    testWidgets(
        'visible=false collapses to SizedBox.shrink (zero-size, no bubble)',
        (tester) async {
      final targetKey = GlobalKey();
      await tester.pumpWidget(wrap(
        EdenContextualTip(
          target: targetKey,
          message: ContextualTipFixtures.shortMessage,
          visible: false,
        ),
      ));
      // Message text is not in the tree.
      expect(find.text(ContextualTipFixtures.shortMessage), findsNothing);
      // Bubble key is not in the tree.
      expect(
        find.byKey(const ValueKey<String>('contextual_tip_bubble')),
        findsNothing,
      );
      // EdenContextualTip itself paints a zero-size SizedBox when hidden.
      final tipSize = tester.getSize(find.byType(EdenContextualTip));
      expect(tipSize.width, 0);
      expect(tipSize.height, 0);
    });

    testWidgets('renders info bubble with the given text when visible=true',
        (tester) async {
      final targetKey = GlobalKey();
      await tester.pumpWidget(wrap(
        EdenContextualTip(
          target: targetKey,
          message: ContextualTipFixtures.shortMessage,
          visible: true,
        ),
      ));
      expect(find.text(ContextualTipFixtures.shortMessage), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('contextual_tip_bubble')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('tapping dismiss icon invokes onDismiss', (tester) async {
      final targetKey = GlobalKey();
      var dismissed = false;
      await tester.pumpWidget(wrap(
        EdenContextualTip(
          target: targetKey,
          message: ContextualTipFixtures.shortMessage,
          onDismiss: () => dismissed = true,
        ),
      ));
      await tester
          .tap(find.byKey(const ValueKey<String>('contextual_tip_dismiss')));
      await tester.pump();
      expect(dismissed, isTrue);
    });

    testWidgets(
        'no dismiss icon when onDismiss is null but bubble still renders',
        (tester) async {
      final targetKey = GlobalKey();
      await tester.pumpWidget(wrap(
        EdenContextualTip(
          target: targetKey,
          message: ContextualTipFixtures.shortMessage,
        ),
      ));
      // Bubble is present.
      expect(
        find.byKey(const ValueKey<String>('contextual_tip_bubble')),
        findsOneWidget,
      );
      // But no dismiss icon.
      expect(
        find.byKey(const ValueKey<String>('contextual_tip_dismiss')),
        findsNothing,
      );
    });
  });
}
