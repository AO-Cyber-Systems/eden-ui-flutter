import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_app_tour_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenStarterTemplateCard', () {
    testWidgets('renders title + description', (tester) async {
      const data = StarterTemplateFixtures.salonStarter;
      await tester.pumpWidget(wrap(
        EdenStarterTemplateCard(
          title: data.title,
          description: data.description,
        ),
      ));
      expect(find.text(data.title), findsOneWidget);
      expect(find.text(data.description), findsOneWidget);
    });

    testWidgets('renders thumbnail when provided', (tester) async {
      const data = StarterTemplateFixtures.tradesStarter;
      await tester.pumpWidget(wrap(
        EdenStarterTemplateCard(
          title: data.title,
          description: data.description,
          thumbnail: Icon(data.icon),
        ),
      ));
      expect(find.byIcon(data.icon), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('thumbnail_slot')),
        findsOneWidget,
      );
    });

    testWidgets('renders effort badge when effortLabel provided',
        (tester) async {
      const data = StarterTemplateFixtures.medicalStarter;
      await tester.pumpWidget(wrap(
        EdenStarterTemplateCard(
          title: data.title,
          description: data.description,
          effortLabel: data.effortLabel,
        ),
      ));
      expect(find.text(data.effortLabel), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('effort_badge')),
        findsOneWidget,
      );
    });

    testWidgets('tapping the card invokes onSelect', (tester) async {
      var tapped = false;
      const data = StarterTemplateFixtures.legalStarter;
      await tester.pumpWidget(wrap(
        EdenStarterTemplateCard(
          title: data.title,
          description: data.description,
          onSelect: () => tapped = true,
        ),
      ));
      await tester.tap(find.text(data.title));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('selected=true renders accent border + tint', (tester) async {
      const data = StarterTemplateFixtures.salonStarter;
      await tester.pumpWidget(wrap(
        EdenStarterTemplateCard(
          title: data.title,
          description: data.description,
          selected: true,
        ),
      ));
      // Find the AnimatedContainer the card uses for its surface.
      final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first);
      final decoration = container.decoration as BoxDecoration;
      // Border is non-null and has width > 1 when selected.
      expect(decoration.border, isNotNull);
      final border = decoration.border as Border;
      expect(border.top.width, greaterThan(1.0),
          reason: 'selected state must thicken the border');
    });
  });
}
