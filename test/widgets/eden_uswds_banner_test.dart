import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_uswds_banner_fixtures.dart';

Widget wrap(Widget child, {double width = 600}) =>
    MaterialApp(home: Scaffold(body: SizedBox(width: width, child: child)));

void main() {
  group('EdenUSWDSBanner — collapsed state', () {
    testWidgets('renders English collapsed label', (tester) async {
      await tester.pumpWidget(wrap(const EdenUSWDSBanner()));
      expect(find.text(EdenUSWDSBannerFixtures.englishCollapsed), findsOneWidget);
    });

    testWidgets('renders expand affordance text', (tester) async {
      await tester.pumpWidget(wrap(const EdenUSWDSBanner()));
      expect(find.text(EdenUSWDSBannerFixtures.englishExpandLink), findsOneWidget);
    });

    testWidgets('renders chevron icon (expand_more_rounded)', (tester) async {
      await tester.pumpWidget(wrap(const EdenUSWDSBanner()));
      expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);
    });

    testWidgets('collapsed background is gray-cool-3', (tester) async {
      await tester.pumpWidget(wrap(const EdenUSWDSBanner()));
      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.color == EdenUSWDSBannerFixtures.grayCool3);
      expect(containers, isNotEmpty);
    });

    testWidgets('collapsed minHeight >= 36pt per USWDS spec', (tester) async {
      await tester.pumpWidget(wrap(const EdenUSWDSBanner()));
      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) =>
              c.color == EdenUSWDSBannerFixtures.grayCool3 &&
              c.constraints != null &&
              c.constraints!.minHeight >= 36);
      expect(containers, isNotEmpty);
    });

    testWidgets('initially expanded panel is hidden', (tester) async {
      await tester.pumpWidget(wrap(const EdenUSWDSBanner()));
      expect(find.text(EdenUSWDSBannerFixtures.englishGovHeading), findsNothing);
    });
  });

  group('EdenUSWDSBanner — tap to expand', () {
    testWidgets('tap reveals both info-panel headings + bodies', (tester) async {
      await tester.pumpWidget(wrap(const EdenUSWDSBanner()));
      await tester.tap(find.byType(EdenUSWDSBanner));
      await tester.pumpAndSettle();
      expect(find.text(EdenUSWDSBannerFixtures.englishGovHeading), findsOneWidget);
      expect(find.text(EdenUSWDSBannerFixtures.englishHttpsHeading), findsOneWidget);
      expect(find.textContaining(EdenUSWDSBannerFixtures.englishGovBodyKey), findsOneWidget);
      expect(find.textContaining(EdenUSWDSBannerFixtures.englishHttpsBodyKey), findsOneWidget);
    });

    testWidgets('second tap collapses panel', (tester) async {
      await tester.pumpWidget(wrap(const EdenUSWDSBanner()));
      await tester.tap(find.byType(EdenUSWDSBanner));
      await tester.pumpAndSettle();
      expect(find.text(EdenUSWDSBannerFixtures.englishGovHeading), findsOneWidget);

      await tester.tap(find.byType(EdenUSWDSBanner));
      await tester.pumpAndSettle();
      expect(find.text(EdenUSWDSBannerFixtures.englishGovHeading), findsNothing);
    });
  });

  group('EdenUSWDSBanner — language toggle (Spanish)', () {
    testWidgets('Spanish renders Spanish collapsed label', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenUSWDSBanner(language: EdenUSWDSLanguage.es),
      ));
      expect(find.text(EdenUSWDSBannerFixtures.spanishCollapsed), findsOneWidget);
    });

    testWidgets('Spanish renders Spanish expand link', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenUSWDSBanner(language: EdenUSWDSLanguage.es),
      ));
      expect(find.text(EdenUSWDSBannerFixtures.spanishExpandLink), findsOneWidget);
    });

    testWidgets('Spanish expanded shows Spanish heading', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenUSWDSBanner(language: EdenUSWDSLanguage.es),
      ));
      await tester.tap(find.byType(EdenUSWDSBanner));
      await tester.pumpAndSettle();
      expect(find.text(EdenUSWDSBannerFixtures.spanishGovHeading), findsOneWidget);
    });
  });

  group('EdenUSWDSBanner — custom govLabel', () {
    testWidgets('custom govLabel appears in label', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenUSWDSBanner(govLabel: EdenUSWDSBannerFixtures.customGovLabel),
      ));
      expect(find.text(EdenUSWDSBannerFixtures.expectedCustomLabel), findsOneWidget);
    });
  });

  group('EdenUSWDSBanner — Section 508 a11y', () {
    testWidgets('Semantics label includes Official + banner + expandable', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(const EdenUSWDSBanner()));
      final semantics = tester.getSemantics(find.byType(EdenUSWDSBanner));
      expect(semantics.label, contains('Official government website banner'));
      expect(semantics.label, contains('expandable'));
      handle.dispose();
    });

    testWidgets('Semantics flagged as button', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(const EdenUSWDSBanner()));
      final semantics = tester.getSemantics(find.byType(EdenUSWDSBanner));
      expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
      handle.dispose();
    });
  });

  group('EdenUSWDSBanner — iPhone-narrow safety', () {
    testWidgets('390pt: no overflow', (tester) async {
      await tester.pumpWidget(wrap(const EdenUSWDSBanner(), width: 390));
      expect(tester.takeException(), isNull);
    });

    testWidgets('extreme narrow 280pt: no overflow', (tester) async {
      await tester.pumpWidget(wrap(const EdenUSWDSBanner(), width: 280));
      expect(tester.takeException(), isNull);
    });

    testWidgets('expanded panel stacks vertically when width < 600pt', (tester) async {
      await tester.pumpWidget(wrap(const EdenUSWDSBanner(), width: 400));
      await tester.tap(find.byType(EdenUSWDSBanner));
      await tester.pumpAndSettle();
      // Vertical stacking: find the expanded-panel key with Column inside.
      final columns = tester.widgetList<Column>(find.descendant(
        of: find.byKey(const ValueKey('uswds-expanded-panel')),
        matching: find.byType(Column),
      ));
      expect(columns, isNotEmpty);
    });

    testWidgets('expanded panel uses Row layout when width >= 600pt', (tester) async {
      await tester.pumpWidget(wrap(const EdenUSWDSBanner(), width: 800));
      await tester.tap(find.byType(EdenUSWDSBanner));
      await tester.pumpAndSettle();
      final rows = tester.widgetList<Row>(find.descendant(
        of: find.byKey(const ValueKey('uswds-expanded-panel')),
        matching: find.byType(Row),
      ));
      expect(rows, isNotEmpty);
    });
  });
}
