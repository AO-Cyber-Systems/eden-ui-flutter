import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // EdenPlaceholderPage OWNS its Scaffold — don't double-wrap.
  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

  group('EdenPlaceholderPage', () {
    testWidgets(
        'happy path: AppBar title + 64px icon + headline + default Coming soon subtitle',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenPlaceholderPage(title: 'Reports', icon: Icons.bar_chart),
      ));
      // AppBar title + headline both render the same text.
      expect(find.text('Reports'), findsNWidgets(2));
      // Bar chart icon present.
      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
      // Default subtitle.
      expect(find.text('Coming soon'), findsOneWidget);
    });

    testWidgets('icon size is 64',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenPlaceholderPage(title: 'Reports', icon: Icons.bar_chart),
      ));
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.bar_chart));
      expect(iconWidget.size, 64);
    });

    testWidgets('custom subtitle overrides default',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenPlaceholderPage(
          title: 'Reports',
          icon: Icons.bar_chart,
          subtitle: 'Pending review',
        ),
      ));
      expect(find.text('Pending review'), findsOneWidget);
      expect(find.text('Coming soon'), findsNothing);
    });

    testWidgets('subtitle null → no subtitle text rendered',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenPlaceholderPage(
          title: 'Reports',
          icon: Icons.bar_chart,
          subtitle: null,
        ),
      ));
      expect(find.text('Coming soon'), findsNothing);
      expect(find.text('Pending review'), findsNothing);
    });

    testWidgets('onAction + actionLabel renders FilledButton and fires onPressed',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        EdenPlaceholderPage(
          title: 'Reports',
          icon: Icons.bar_chart,
          onAction: () => tapped = true,
          actionLabel: 'Notify me',
        ),
      ));
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Notify me'), findsOneWidget);
      await tester.tap(find.text('Notify me'));
      expect(tapped, isTrue);
    });

    testWidgets('onAction null → no FilledButton',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenPlaceholderPage(
          title: 'Reports',
          icon: Icons.bar_chart,
          actionLabel: 'Notify me',
        ),
      ));
      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('Notify me'), findsNothing);
    });

    testWidgets('actionLabel null → no FilledButton (both must be non-null)',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenPlaceholderPage(
          title: 'Reports',
          icon: Icons.bar_chart,
          onAction: () {},
        ),
      ));
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets(
        'iPhone-narrow: no overflow inside SizedBox(width: 390, height: 700)',
        (tester) async {
      await tester.pumpWidget(wrap(
        const SizedBox(
          width: 390,
          height: 700,
          child: EdenPlaceholderPage(
            title: 'Reports',
            icon: Icons.bar_chart,
            subtitle: 'A longer-than-default subtitle to stress test',
            actionLabel: 'Notify me when ready',
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
