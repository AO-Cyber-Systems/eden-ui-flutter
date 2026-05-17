import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_agency_identifier_fixtures.dart';

Widget wrap(Widget child, {double width = 600}) =>
    MaterialApp(home: Scaffold(body: SizedBox(width: width, child: child)));

void main() {
  group('EdenAgencyContactLink + EdenAgencyIdentity value classes', () {
    test('EdenAgencyContactLink stores label + url', () {
      const link = EdenAgencyContactLink(label: 'About', url: '/about');
      expect(link.label, 'About');
      expect(link.url, '/about');
    });

    test('EdenAgencyIdentity defaults contactLinks to empty list', () {
      const identity = EdenAgencyIdentity(
        agencyName: 'X',
        parentDepartment: 'Y',
      );
      expect(identity.contactLinks, isEmpty);
      expect(identity.seal, isNull);
    });
  });

  group('EdenAgencyIdentifier — header layout', () {
    testWidgets('header renders agency name', (tester) async {
      await tester.pumpWidget(wrap(const EdenAgencyIdentifier(
        identity: EdenAgencyIdentifierFixtures.dodMinimal,
      )));
      expect(find.text('Department of Defense'), findsOneWidget);
    });

    testWidgets('header background is gray-cool-3', (tester) async {
      await tester.pumpWidget(wrap(const EdenAgencyIdentifier(
        identity: EdenAgencyIdentifierFixtures.dodMinimal,
      )));
      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.color == EdenAgencyIdentifierFixtures.grayCool3);
      expect(containers, isNotEmpty);
    });

    testWidgets('header minHeight >= 48pt', (tester) async {
      await tester.pumpWidget(wrap(const EdenAgencyIdentifier(
        identity: EdenAgencyIdentifierFixtures.dodMinimal,
      )));
      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) =>
              c.color == EdenAgencyIdentifierFixtures.grayCool3 &&
              c.constraints != null &&
              c.constraints!.minHeight >= 48);
      expect(containers, isNotEmpty);
    });

    testWidgets('header with seal renders seal widget', (tester) async {
      await tester.pumpWidget(wrap(const EdenAgencyIdentifier(
        identity: EdenAgencyIdentifierFixtures.dodWithSeal,
      )));
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });

    testWidgets('header without seal does NOT render shield icon', (tester) async {
      await tester.pumpWidget(wrap(const EdenAgencyIdentifier(
        identity: EdenAgencyIdentifierFixtures.dodMinimal,
      )));
      expect(find.byIcon(Icons.shield_outlined), findsNothing);
    });
  });

  group('EdenAgencyIdentifier — footer layout', () {
    testWidgets('footer renders agency name + parent department', (tester) async {
      await tester.pumpWidget(wrap(const EdenAgencyIdentifier(
        identity: EdenAgencyIdentifierFixtures.dodMinimal,
        layout: EdenAgencyIdentifierLayout.footer,
      )));
      expect(find.text('Department of Defense'), findsOneWidget);
      expect(find.text('Federal Government'), findsOneWidget);
    });

    testWidgets('footer background is navy', (tester) async {
      await tester.pumpWidget(wrap(const EdenAgencyIdentifier(
        identity: EdenAgencyIdentifierFixtures.dodMinimal,
        layout: EdenAgencyIdentifierLayout.footer,
      )));
      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.color == EdenAgencyIdentifierFixtures.navy);
      expect(containers, isNotEmpty);
    });

    testWidgets('footer agency name is white', (tester) async {
      await tester.pumpWidget(wrap(const EdenAgencyIdentifier(
        identity: EdenAgencyIdentifierFixtures.dodMinimal,
        layout: EdenAgencyIdentifierLayout.footer,
      )));
      final text = tester.widget<Text>(find.text('Department of Defense'));
      expect(text.style?.color, EdenAgencyIdentifierFixtures.white);
    });

    testWidgets('footer renders all contact link labels', (tester) async {
      await tester.pumpWidget(wrap(const EdenAgencyIdentifier(
        identity: EdenAgencyIdentifierFixtures.gsaWithLinks,
        layout: EdenAgencyIdentifierLayout.footer,
      )));
      expect(find.text('About GSA'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('FOIA Requests'), findsOneWidget);
    });
  });

  group('EdenAgencyIdentifier — contact link interaction', () {
    testWidgets('tapping a contact link fires onContactLinkTap with the matching link',
        (tester) async {
      EdenAgencyContactLink? tapped;
      await tester.pumpWidget(wrap(EdenAgencyIdentifier(
        identity: EdenAgencyIdentifierFixtures.gsaWithLinks,
        layout: EdenAgencyIdentifierLayout.footer,
        onContactLinkTap: (link) => tapped = link,
      )));
      await tester.tap(find.text('Privacy Policy'));
      await tester.pump();
      expect(tapped, isNotNull);
      expect(tapped!.label, 'Privacy Policy');
      expect(tapped!.url, contains('privacy'));
    });

    testWidgets('no callback registered → tap does not throw', (tester) async {
      await tester.pumpWidget(wrap(const EdenAgencyIdentifier(
        identity: EdenAgencyIdentifierFixtures.gsaWithLinks,
        layout: EdenAgencyIdentifierLayout.footer,
      )));
      await tester.tap(find.text('About GSA'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenAgencyIdentifier — Section 508 a11y', () {
    testWidgets('header Semantics label includes agency + part of + parent + identifier',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(const EdenAgencyIdentifier(
        identity: EdenAgencyIdentifierFixtures.dodMinimal,
      )));
      final semantics =
          tester.getSemantics(find.byType(EdenAgencyIdentifier));
      expect(semantics.label, contains('Department of Defense'));
      expect(semantics.label, contains('part of'));
      expect(semantics.label, contains('Federal Government'));
      expect(semantics.label, contains('agency identifier'));
      handle.dispose();
    });

    testWidgets('footer Semantics label same format', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(const EdenAgencyIdentifier(
        identity: EdenAgencyIdentifierFixtures.dodMinimal,
        layout: EdenAgencyIdentifierLayout.footer,
      )));
      final semantics =
          tester.getSemantics(find.byType(EdenAgencyIdentifier));
      expect(semantics.label, contains('Department of Defense'));
      expect(semantics.label, contains('part of'));
      expect(semantics.label, contains('agency identifier'));
      handle.dispose();
    });

    testWidgets('footer contact links each flagged as button in semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(const EdenAgencyIdentifier(
        identity: EdenAgencyIdentifierFixtures.gsaWithLinks,
        layout: EdenAgencyIdentifierLayout.footer,
      )));
      // Confirm at least one Semantics ancestor with button: true exists for a link.
      final buttonSemantics = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.button == true,
      );
      expect(buttonSemantics, findsAtLeastNWidgets(3));
      handle.dispose();
    });
  });

  group('EdenAgencyIdentifier — iPhone-narrow (390pt) safety', () {
    testWidgets('header at 390pt: long agency name ellipsizes, no overflow',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenAgencyIdentifier(
          identity: EdenAgencyIdentifierFixtures.longName,
        ),
        width: 390,
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('footer at 390pt: contact links wrap, no overflow', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenAgencyIdentifier(
          identity: EdenAgencyIdentifierFixtures.gsaWithLinks,
          layout: EdenAgencyIdentifierLayout.footer,
        ),
        width: 390,
      ));
      expect(tester.takeException(), isNull);
      expect(find.byType(Wrap), findsAtLeastNWidgets(1));
    });
  });
}
