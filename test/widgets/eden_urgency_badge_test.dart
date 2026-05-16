import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_urgency_badge_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenUrgencyBadge', () {
    testWidgets('renders Low label with no icon for urgency=low',
        (tester) async {
      await tester
          .pumpWidget(wrap(const EdenUrgencyBadge(urgency: 'low')));
      expect(find.text('Low'), findsOneWidget);
      expect(find.byIcon(Icons.priority_high), findsNothing);
      expect(find.byIcon(Icons.warning_rounded), findsNothing);
    });

    testWidgets('renders Medium label with no icon for urgency=medium',
        (tester) async {
      await tester
          .pumpWidget(wrap(const EdenUrgencyBadge(urgency: 'medium')));
      expect(find.text('Medium'), findsOneWidget);
      expect(find.byIcon(Icons.priority_high), findsNothing);
      expect(find.byIcon(Icons.warning_rounded), findsNothing);
    });

    testWidgets('renders High label with priority_high icon for urgency=high',
        (tester) async {
      await tester
          .pumpWidget(wrap(const EdenUrgencyBadge(urgency: 'high')));
      expect(find.text('High'), findsOneWidget);
      expect(find.byIcon(Icons.priority_high), findsOneWidget);
    });

    testWidgets(
        'renders Critical label with warning_rounded icon for urgency=critical',
        (tester) async {
      await tester
          .pumpWidget(wrap(const EdenUrgencyBadge(urgency: 'critical')));
      expect(find.text('Critical'), findsOneWidget);
      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
    });

    testWidgets(
        'unknown urgency renders raw string as label with no icon',
        (tester) async {
      await tester.pumpWidget(
          wrap(const EdenUrgencyBadge(urgency: 'urgent_af')));
      expect(find.text('urgent_af'), findsOneWidget);
      expect(find.byIcon(Icons.priority_high), findsNothing);
      expect(find.byIcon(Icons.warning_rounded), findsNothing);
    });

    testWidgets('uses theme.colorScheme.onSurfaceVariant for unknown urgency',
        (tester) async {
      final theme = ThemeData.light();
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: EdenUrgencyBadge(urgency: 'wat'),
        ),
      ));
      final textWidget = tester.widget<Text>(find.text('wat'));
      expect(textWidget.style?.color, theme.colorScheme.onSurfaceVariant);
    });

    testWidgets('fontSize override is applied to the Text style',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenUrgencyBadge(urgency: 'high', fontSize: 18),
      ));
      final textWidget = tester.widget<Text>(find.text('High'));
      expect(textWidget.style?.fontSize, 18);
    });

    testWidgets(
        'without fontSize override the Text style inherits from labelSmall',
        (tester) async {
      final theme = ThemeData.light();
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: EdenUrgencyBadge(urgency: 'high'),
        ),
      ));
      final textWidget = tester.widget<Text>(find.text('High'));
      expect(textWidget.style?.fontSize, theme.textTheme.labelSmall?.fontSize);
    });

    testWidgets(
        'renders inside SizedBox(width: 80) without RenderFlex overflow for all 5 cases',
        (tester) async {
      for (final urgency in [
        ...EdenUrgencyBadgeFixtures.knownLevels,
        EdenUrgencyBadgeFixtures.unknownSamples.first,
      ]) {
        await tester.pumpWidget(wrap(
          SizedBox(
            width: 80,
            child: EdenUrgencyBadge(urgency: urgency),
          ),
        ));
        expect(tester.takeException(), isNull,
            reason: 'overflowed for urgency=$urgency');
      }
    });
  });
}
