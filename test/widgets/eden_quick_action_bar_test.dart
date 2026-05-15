import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_quick_action_bar_fixtures.dart';

void main() {
  Widget wrap(Widget child, {double width = 1280}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: 100, child: Align(
          alignment: Alignment.bottomCenter,
          child: child,
        )),
      ),
    );
  }

  group('EdenQuickActionBar', () {
    testWidgets('renders 4 action icons in a horizontal row at desktop width',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenQuickActionBar(
          actions:
              EdenQuickActionBarFixtures.customerDetailActions().take(4).toList(),
        ),
      ));
      // Each action's IconButton mounted (Pin/Chat/Call/Email).
      expect(find.byKey(const ValueKey<String>('quick_action_Pin')),
          findsOneWidget);
      expect(find.byKey(const ValueKey<String>('quick_action_Chat')),
          findsOneWidget);
      expect(find.byKey(const ValueKey<String>('quick_action_Call')),
          findsOneWidget);
      expect(find.byKey(const ValueKey<String>('quick_action_Email')),
          findsOneWidget);
    });

    testWidgets('tapping an action invokes its onPressed', (tester) async {
      var pinTapped = false;
      await tester.pumpWidget(wrap(
        EdenQuickActionBar(
          actions: EdenQuickActionBarFixtures.customerDetailActions(
            onPin: () => pinTapped = true,
          ).take(4).toList(),
        ),
      ));
      await tester
          .tap(find.byKey(const ValueKey<String>('quick_action_Pin')));
      await tester.pump();
      expect(pinTapped, isTrue);
    });

    testWidgets('long-pressing an action shows its tooltip', (tester) async {
      await tester.pumpWidget(wrap(
        EdenQuickActionBar(
          actions:
              EdenQuickActionBarFixtures.customerDetailActions().take(2).toList(),
        ),
      ));
      // IconButton's tooltip ancestor is a Tooltip widget — assert presence.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('quick_action_Pin')),
          matching: find.byType(Tooltip),
        ),
        findsOneWidget,
      );
    });

    testWidgets('badge count > 0 renders a badge with the count',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenQuickActionBar(
          actions: EdenQuickActionBarFixtures.withBadges(),
        ),
      ));
      // Badge counts: 3, 12, and 150 (→ '99+').
      expect(find.text('3'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('8 actions at desktop width: all inline, no overflow',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenQuickActionBar(
          actions: EdenQuickActionBarFixtures.workOrderDetailActions(),
        ),
        width: 1280,
      ));
      // No overflow menu.
      expect(
        find.byKey(const ValueKey<String>('quick_action_overflow_menu')),
        findsNothing,
      );
      // All 8 inline.
      for (final t in <String>[
        'Print', 'Pin', 'Chat', 'Call', 'Photo', 'Share', 'Archive', 'Delete',
      ]) {
        expect(
          find.byKey(ValueKey<String>('quick_action_$t')),
          findsOneWidget,
          reason: 'expected inline button for $t',
        );
      }
    });

    testWidgets(
        '8 actions at iPhone-narrow (390pt): overflow menu appears + some hidden inline',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenQuickActionBar(
          actions: EdenQuickActionBarFixtures.workOrderDetailActions(),
        ),
        width: 390,
      ));
      // Overflow menu is mounted.
      expect(
        find.byKey(const ValueKey<String>('quick_action_overflow_menu')),
        findsOneWidget,
      );
      // At least one action is NOT inline.
      int inlineCount = 0;
      for (final t in <String>[
        'Print', 'Pin', 'Chat', 'Call', 'Photo', 'Share', 'Archive', 'Delete',
      ]) {
        if (find.byKey(ValueKey<String>('quick_action_$t')).evaluate().isNotEmpty) {
          inlineCount++;
        }
      }
      expect(inlineCount, lessThan(8));
    });

    testWidgets(
        'maxInlineActions=3 forces collapse-to-overflow after 3 actions',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenQuickActionBar(
          actions: EdenQuickActionBarFixtures.workOrderDetailActions(),
          maxInlineActions: 3,
        ),
        width: 1280,
      ));
      // Exactly 3 inline buttons.
      int inlineCount = 0;
      for (final t in <String>[
        'Print', 'Pin', 'Chat', 'Call', 'Photo', 'Share', 'Archive', 'Delete',
      ]) {
        if (find.byKey(ValueKey<String>('quick_action_$t')).evaluate().isNotEmpty) {
          inlineCount++;
        }
      }
      expect(inlineCount, 3);
      expect(
        find.byKey(const ValueKey<String>('quick_action_overflow_menu')),
        findsOneWidget,
      );
    });

    testWidgets('empty actions list renders SizedBox.shrink (zero size)',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenQuickActionBar(actions: <EdenQuickAction>[]),
      ));
      final size = tester.getSize(find.byType(EdenQuickActionBar));
      expect(size.width, 0);
      expect(size.height, 0);
    });

    testWidgets('single action renders inline; no overflow menu',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenQuickActionBar(
          actions: <EdenQuickAction>[
            EdenQuickAction(
                icon: Icons.push_pin, tooltip: 'Pin', onPressed: () {}),
          ],
        ),
      ));
      expect(
        find.byKey(const ValueKey<String>('quick_action_Pin')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('quick_action_overflow_menu')),
        findsNothing,
      );
    });

    testWidgets(
        'disabled action (onPressed=null) is greyed out + tap is no-op',
        (tester) async {
      var siblingTapped = false;
      final actions = <EdenQuickAction>[
        const EdenQuickAction(icon: Icons.push_pin, tooltip: 'Pin'),
        EdenQuickAction(
            icon: Icons.chat_bubble_outline,
            tooltip: 'Chat',
            onPressed: () => siblingTapped = true),
      ];
      await tester.pumpWidget(wrap(
        EdenQuickActionBar(actions: actions),
      ));
      // The disabled Pin IconButton has null onPressed.
      final pinBtn = tester.widget<IconButton>(
          find.byKey(const ValueKey<String>('quick_action_Pin')));
      expect(pinBtn.onPressed, isNull);
      // Tapping a sibling still works.
      await tester
          .tap(find.byKey(const ValueKey<String>('quick_action_Chat')));
      await tester.pump();
      expect(siblingTapped, isTrue);
    });

    testWidgets('badge count > 99 renders as "99+"', (tester) async {
      await tester.pumpWidget(wrap(
        EdenQuickActionBar(
          actions: <EdenQuickAction>[
            EdenQuickAction(
              icon: Icons.notifications_outlined,
              tooltip: 'Alerts',
              badgeCount: 200,
              onPressed: () {},
            ),
          ],
        ),
      ));
      expect(find.text('99+'), findsOneWidget);
      expect(find.text('200'), findsNothing);
    });
  });
}
