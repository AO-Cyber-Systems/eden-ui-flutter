import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_section508_audit_fixtures.dart';

Widget wrap(Widget child, {double width = 500, double height = 600}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );

void main() {
  group('EdenSection508Issue + Controller', () {
    test('EdenSection508Issue stores required + optional fields', () {
      const issue = EdenSection508Issue(
        severity: EdenSection508Severity.error,
        category: EdenSection508Category.missingTapTarget,
        description: 'tap target too small',
      );
      expect(issue.severity, EdenSection508Severity.error);
      expect(issue.category, EdenSection508Category.missingTapTarget);
      expect(issue.fixHint, isNull);
      expect(issue.widgetTypeName, isNull);
    });

    test('controller initial state is idle with empty issues', () {
      final c = EdenSection508AuditController();
      expect(c.state, EdenSection508AuditState.idle);
      expect(c.issues, isEmpty);
    });

    test('startScan transitions to scanning + notifies', () {
      final c = EdenSection508AuditController();
      var notified = 0;
      c.addListener(() => notified++);
      c.startScan();
      expect(c.state, EdenSection508AuditState.scanning);
      expect(notified, 1);
    });

    test('completeScan stores issues + transitions to results', () {
      final c = EdenSection508AuditController();
      c.completeScan(EdenSection508AuditFixtures.mixed);
      expect(c.state, EdenSection508AuditState.results);
      expect(c.issues.length, 3);
    });

    test('reset returns to idle + empties', () {
      final c = EdenSection508AuditController()
        ..completeScan(EdenSection508AuditFixtures.mixed);
      c.reset();
      expect(c.state, EdenSection508AuditState.idle);
      expect(c.issues, isEmpty);
    });
  });

  group('EdenSection508Audit — floating toggle + panel', () {
    testWidgets('floating bug_report icon button visible', (tester) async {
      final c = EdenSection508AuditController();
      await tester.pumpWidget(wrap(EdenSection508Audit(controller: c)));
      expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
    });

    testWidgets('tap toggle reveals panel', (tester) async {
      final c = EdenSection508AuditController();
      await tester.pumpWidget(wrap(EdenSection508Audit(controller: c)));
      // Panel content not visible yet.
      expect(find.text('Section 508 Audit'), findsNothing);
      await tester.tap(find.byIcon(Icons.bug_report_outlined));
      await tester.pump();
      expect(find.text('Section 508 Audit'), findsOneWidget);
    });
  });

  group('EdenSection508Audit — panel states', () {
    Future<void> openPanel(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.bug_report_outlined));
      await tester.pump();
    }

    testWidgets('idle state renders Tap Scan prompt', (tester) async {
      final c = EdenSection508AuditController();
      await tester.pumpWidget(wrap(EdenSection508Audit(controller: c)));
      await openPanel(tester);
      expect(find.textContaining('Tap Scan'), findsOneWidget);
    });

    testWidgets('scanning state renders progress + Scanning…', (tester) async {
      final c = EdenSection508AuditController();
      await tester.pumpWidget(wrap(EdenSection508Audit(controller: c)));
      await openPanel(tester);
      c.startScan();
      await tester.pump();
      expect(find.text('Scanning…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('results state with 3 mixed issues renders 3 ListTiles', (tester) async {
      final c = EdenSection508AuditController()
        ..completeScan(EdenSection508AuditFixtures.mixed);
      await tester.pumpWidget(wrap(EdenSection508Audit(controller: c)));
      await openPanel(tester);
      expect(find.byType(ListTile), findsNWidgets(3));
    });

    testWidgets('counts pill shows 1 error, 1 warning, 1 info', (tester) async {
      final c = EdenSection508AuditController()
        ..completeScan(EdenSection508AuditFixtures.mixed);
      await tester.pumpWidget(wrap(EdenSection508Audit(controller: c)));
      await openPanel(tester);
      expect(find.textContaining('1 errors'), findsOneWidget);
      expect(find.textContaining('1 warnings'), findsOneWidget);
      expect(find.textContaining('1 info'), findsOneWidget);
    });

    testWidgets('tap on issue tile expands to show fix hint', (tester) async {
      final c = EdenSection508AuditController()
        ..completeScan(EdenSection508AuditFixtures.mixed);
      await tester.pumpWidget(wrap(EdenSection508Audit(controller: c)));
      await openPanel(tester);
      expect(find.textContaining('Fix:'), findsNothing);
      await tester.tap(find.byType(ListTile).first);
      await tester.pump();
      expect(find.textContaining('Fix:'), findsOneWidget);
    });

    testWidgets('empty results state renders No issues detected', (tester) async {
      final c = EdenSection508AuditController()..completeScan(const []);
      await tester.pumpWidget(wrap(EdenSection508Audit(controller: c)));
      await openPanel(tester);
      expect(find.textContaining('No issues detected'), findsOneWidget);
    });
  });

  group('EdenSection508Audit — filter chips', () {
    Future<void> openPanel(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.bug_report_outlined));
      await tester.pump();
    }

    testWidgets('filter chips render for each unique category in issues',
        (tester) async {
      final c = EdenSection508AuditController()
        ..completeScan(EdenSection508AuditFixtures.mixed);
      await tester.pumpWidget(wrap(EdenSection508Audit(controller: c)));
      await openPanel(tester);
      // 3 unique categories → 3 filter chips.
      expect(find.byType(FilterChip), findsNWidgets(3));
    });

    testWidgets('deselecting a category chip hides those issues', (tester) async {
      final c = EdenSection508AuditController()
        ..completeScan(EdenSection508AuditFixtures.mixed);
      await tester.pumpWidget(wrap(EdenSection508Audit(controller: c)));
      await openPanel(tester);
      expect(find.byType(ListTile), findsNWidgets(3));
      // Deselect missingSemanticLabel chip.
      final chip =
          find.widgetWithText(FilterChip, 'missingSemanticLabel').first;
      await tester.tap(chip);
      await tester.pump();
      expect(find.byType(ListTile), findsNWidgets(2));
    });
  });

  group('EdenSection508Audit — Section 508 (meta) a11y', () {
    Future<void> openPanel(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.bug_report_outlined));
      await tester.pump();
    }

    testWidgets('panel has Semantics ancestor with label Section 508 audit panel',
        (tester) async {
      final c = EdenSection508AuditController()
        ..completeScan(EdenSection508AuditFixtures.mixed);
      await tester.pumpWidget(wrap(EdenSection508Audit(controller: c)));
      await openPanel(tester);
      final panelSemantics = find.byWidgetPredicate(
        (w) =>
            w is Semantics && w.properties.label == 'Section 508 audit panel',
      );
      expect(panelSemantics, findsOneWidget);
    });

    testWidgets('each issue tile has Semantics announcing severity + category',
        (tester) async {
      final c = EdenSection508AuditController()
        ..completeScan(EdenSection508AuditFixtures.mixed);
      await tester.pumpWidget(wrap(EdenSection508Audit(controller: c)));
      await openPanel(tester);
      final issueSemantics = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            (w.properties.label?.contains('error') ?? false) &&
            (w.properties.label?.contains('missingSemanticLabel') ?? false),
      );
      expect(issueSemantics, findsAtLeastNWidgets(1));
    });
  });

  group('EdenSection508Audit — iPhone-narrow (390pt) safety', () {
    testWidgets('390pt: panel fits/scrolls without overflow', (tester) async {
      final c = EdenSection508AuditController()
        ..completeScan(EdenSection508AuditFixtures.mixed);
      await tester.pumpWidget(wrap(
        EdenSection508Audit(controller: c),
        width: 390,
      ));
      await tester.tap(find.byIcon(Icons.bug_report_outlined));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
