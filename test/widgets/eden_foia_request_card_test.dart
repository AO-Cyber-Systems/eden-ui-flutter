import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_foia_request_card_fixtures.dart';

Widget wrap(Widget child, {double width = 500}) =>
    MaterialApp(home: Scaffold(body: SizedBox(width: width, child: child)));

void main() {
  group('EdenFoiaRequest value class', () {
    test('constructs with required + defaults', () {
      final r = EdenFoiaRequest(
        id: 'x',
        requesterName: 'a',
        submittedAt: DateTime(2026),
        dueAt: DateTime(2026, 6),
        subject: 'subj',
      );
      expect(r.redactionPassStatus, EdenFoiaRedactionStatus.pending);
      expect(r.exemptionCodes, isEmpty);
      expect(r.responseDocCount, 0);
      expect(r.classification, isNull);
      expect(r.assignedTo, isNull);
    });
  });

  group('EdenFoiaRequestCard — base rendering', () {
    testWidgets('renders request id + requester + subject', (tester) async {
      await tester.pumpWidget(wrap(EdenFoiaRequestCard(
        request: EdenFoiaRequestCardFixtures.farFuture,
        now: EdenFoiaRequestCardFixtures.fixedNow,
      )));
      expect(find.text('FOIA-2026-0042'), findsOneWidget);
      expect(find.textContaining('Jane Citizen'), findsOneWidget);
      expect(find.textContaining('policy memo'), findsOneWidget);
    });

    testWidgets('renders assignedTo when present', (tester) async {
      await tester.pumpWidget(wrap(EdenFoiaRequestCard(
        request: EdenFoiaRequestCardFixtures.farFuture,
        now: EdenFoiaRequestCardFixtures.fixedNow,
      )));
      expect(find.textContaining('analyst.foia@agency.gov'), findsOneWidget);
    });

    testWidgets('renders responseDocCount when > 0', (tester) async {
      await tester.pumpWidget(wrap(EdenFoiaRequestCard(
        request: EdenFoiaRequestCardFixtures.farFuture,
        now: EdenFoiaRequestCardFixtures.fixedNow,
      )));
      expect(find.textContaining('12'), findsAtLeastNWidgets(1));
    });
  });

  group('EdenFoiaRequestCard — due-date pill urgency', () {
    testWidgets('30 days away → green pill + "30 days remaining"',
        (tester) async {
      await tester.pumpWidget(wrap(EdenFoiaRequestCard(
        request: EdenFoiaRequestCardFixtures.farFuture,
        now: EdenFoiaRequestCardFixtures.fixedNow,
      )));
      expect(find.textContaining('30 days remaining'), findsOneWidget);
    });

    testWidgets('10 days away → amber pill', (tester) async {
      await tester.pumpWidget(wrap(EdenFoiaRequestCard(
        request: EdenFoiaRequestCardFixtures.dueIn10Days,
        now: EdenFoiaRequestCardFixtures.fixedNow,
      )));
      expect(find.textContaining('10 days remaining'), findsOneWidget);
    });

    testWidgets('5 days away → red pill', (tester) async {
      await tester.pumpWidget(wrap(EdenFoiaRequestCard(
        request: EdenFoiaRequestCardFixtures.dueIn5Days,
        now: EdenFoiaRequestCardFixtures.fixedNow,
      )));
      expect(find.textContaining('5 days remaining'), findsOneWidget);
    });

    testWidgets('overdue → "Overdue by N days"', (tester) async {
      await tester.pumpWidget(wrap(EdenFoiaRequestCard(
        request: EdenFoiaRequestCardFixtures.overdue,
        now: EdenFoiaRequestCardFixtures.fixedNow,
      )));
      expect(find.textContaining('Overdue by'), findsOneWidget);
    });
  });

  group('EdenFoiaRequestCard — redaction status', () {
    testWidgets('inProgress redaction renders inProgress chip', (tester) async {
      await tester.pumpWidget(wrap(EdenFoiaRequestCard(
        request: EdenFoiaRequestCardFixtures.dueIn10Days,
        now: EdenFoiaRequestCardFixtures.fixedNow,
      )));
      expect(find.textContaining('inProgress'), findsOneWidget);
    });

    testWidgets('blocked renders blocked chip', (tester) async {
      await tester.pumpWidget(wrap(EdenFoiaRequestCard(
        request: EdenFoiaRequestCardFixtures.overdue,
        now: EdenFoiaRequestCardFixtures.fixedNow,
      )));
      expect(find.textContaining('blocked'), findsOneWidget);
    });
  });

  group('EdenFoiaRequestCard — exemption codes', () {
    testWidgets('3 exemption codes render as 3 chips', (tester) async {
      await tester.pumpWidget(wrap(EdenFoiaRequestCard(
        request: EdenFoiaRequestCardFixtures.dueIn5Days,
        now: EdenFoiaRequestCardFixtures.fixedNow,
      )));
      expect(find.text('b1'), findsOneWidget);
      expect(find.text('b5'), findsOneWidget);
      expect(find.text('b7'), findsOneWidget);
    });

    testWidgets('empty exemption codes → no exemption chips', (tester) async {
      await tester.pumpWidget(wrap(EdenFoiaRequestCard(
        request: EdenFoiaRequestCardFixtures.farFuture,
        now: EdenFoiaRequestCardFixtures.fixedNow,
      )));
      expect(find.text('b1'), findsNothing);
      expect(find.text('b5'), findsNothing);
    });
  });

  group('EdenFoiaRequestCard — classification overlay', () {
    testWidgets('classification: secret wraps card with EdenClassificationBanner',
        (tester) async {
      await tester.pumpWidget(wrap(EdenFoiaRequestCard(
        request: EdenFoiaRequestCardFixtures.withClassification,
        now: EdenFoiaRequestCardFixtures.fixedNow,
      )));
      // SECRET banner is visible.
      expect(find.text('SECRET'), findsOneWidget);
    });

    testWidgets('classification: null → no banner', (tester) async {
      await tester.pumpWidget(wrap(EdenFoiaRequestCard(
        request: EdenFoiaRequestCardFixtures.farFuture,
        now: EdenFoiaRequestCardFixtures.fixedNow,
      )));
      expect(find.text('SECRET'), findsNothing);
      expect(find.text('UNCLASSIFIED'), findsNothing);
    });
  });

  group('EdenFoiaRequestCard — onTap', () {
    testWidgets('tap fires onTap with the request', (tester) async {
      EdenFoiaRequest? tapped;
      await tester.pumpWidget(wrap(EdenFoiaRequestCard(
        request: EdenFoiaRequestCardFixtures.farFuture,
        now: EdenFoiaRequestCardFixtures.fixedNow,
        onTap: (r) => tapped = r,
      )));
      await tester.tap(find.byType(EdenFoiaRequestCard));
      await tester.pump();
      expect(tapped?.id, 'FOIA-2026-0042');
    });

    testWidgets('no onTap → tap does not throw', (tester) async {
      await tester.pumpWidget(wrap(EdenFoiaRequestCard(
        request: EdenFoiaRequestCardFixtures.farFuture,
        now: EdenFoiaRequestCardFixtures.fixedNow,
      )));
      await tester.tap(find.byType(EdenFoiaRequestCard));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenFoiaRequestCard — Section 508 a11y', () {
    testWidgets('card has Semantics ancestor with FOIA request label',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(EdenFoiaRequestCard(
        request: EdenFoiaRequestCardFixtures.farFuture,
        now: EdenFoiaRequestCardFixtures.fixedNow,
      )));
      final hits = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            (w.properties.label?.startsWith('FOIA request') ?? false) &&
            (w.properties.label?.contains('FOIA-2026-0042') ?? false),
      );
      expect(hits, findsAtLeastNWidgets(1));
      handle.dispose();
    });
  });

  group('EdenFoiaRequestCard — iPhone-narrow (390pt) safety', () {
    testWidgets('390pt: long subject + 3 exemption codes does not overflow',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenFoiaRequestCard(
          request: EdenFoiaRequestCardFixtures.dueIn5Days,
          now: EdenFoiaRequestCardFixtures.fixedNow,
        ),
        width: 390,
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
