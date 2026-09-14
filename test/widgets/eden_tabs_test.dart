import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  final tabs = [
    const EdenTabItem(label: 'Overview'),
    const EdenTabItem(label: 'Details'),
    const EdenTabItem(label: 'History'),
  ];

  group('EdenTabs', () {
    testWidgets('renders all tab labels', (tester) async {
      await tester.pumpWidget(wrap(
        EdenTabs(tabs: tabs, selectedIndex: 0, onChanged: (_) {}),
      ));
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('tapping a tab calls onChanged with index', (tester) async {
      int? selected;
      await tester.pumpWidget(wrap(
        EdenTabs(tabs: tabs, selectedIndex: 0, onChanged: (i) => selected = i),
      ));
      await tester.tap(find.text('Details'));
      expect(selected, 1);
    });

    testWidgets('renders tab with badge', (tester) async {
      final badgedTabs = [
        const EdenTabItem(label: 'Inbox', badge: '5'),
        const EdenTabItem(label: 'Sent'),
      ];
      await tester.pumpWidget(wrap(
        EdenTabs(tabs: badgedTabs, selectedIndex: 0, onChanged: (_) {}),
      ));
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('renders tab with icon', (tester) async {
      final iconTabs = [
        const EdenTabItem(label: 'Home', icon: Icons.home),
        const EdenTabItem(label: 'Settings', icon: Icons.settings),
      ];
      await tester.pumpWidget(wrap(
        EdenTabs(tabs: iconTabs, selectedIndex: 0, onChanged: (_) {}),
      ));
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('an item key resolves to that tab, and its label is a '
        'descendant', (tester) async {
      final keyedTabs = [
        const EdenTabItem(label: 'Overview', key: Key('x.tab.overview')),
        const EdenTabItem(label: 'Details', key: Key('x.tab.details')),
        const EdenTabItem(label: 'History'), // unkeyed sibling still renders
      ];
      await tester.pumpWidget(wrap(
        EdenTabs(tabs: keyedTabs, selectedIndex: 0, onChanged: (_) {}),
      ));

      expect(find.byKey(const Key('x.tab.overview')), findsOneWidget);
      expect(find.byKey(const Key('x.tab.details')), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('x.tab.details')),
          matching: find.text('Details'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a keyed tab is tappable through its key', (tester) async {
      int? selected;
      final keyedTabs = [
        const EdenTabItem(label: 'Overview', key: Key('x.tab.overview')),
        const EdenTabItem(label: 'Details', key: Key('x.tab.details')),
      ];
      await tester.pumpWidget(wrap(
        EdenTabs(
            tabs: keyedTabs, selectedIndex: 0, onChanged: (i) => selected = i),
      ));

      await tester.tap(find.byKey(const Key('x.tab.details')));
      expect(selected, 1);
    });
  });
}
