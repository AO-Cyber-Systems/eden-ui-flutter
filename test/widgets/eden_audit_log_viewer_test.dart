import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_audit_log_viewer_fixtures.dart';

Widget wrap(Widget child, {double width = 500, double height = 700}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );

void main() {
  group('EdenAuditLogEntry value class', () {
    test('constructs with required fields + defaults', () {
      final entry = EdenAuditLogEntry(
        id: 'x',
        timestamp: DateTime(2026),
        actor: 'a',
        action: 'b',
        target: 'c',
      );
      expect(entry.details, isEmpty);
      expect(entry.failed, isFalse);
      expect(entry.prevHash, isNull);
      expect(entry.currHash, isNull);
    });
  });

  group('EdenAuditLogViewer — rendering', () {
    testWidgets('renders all entries from the list', (tester) async {
      await tester.pumpWidget(wrap(EdenAuditLogViewer(
        entries: EdenAuditLogViewerFixtures.mixed,
        showFilters: false,
      )));
      expect(find.byType(ListTile), findsNWidgets(4));
    });

    testWidgets('each entry shows actor + action + target in title', (tester) async {
      await tester.pumpWidget(wrap(EdenAuditLogViewer(
        entries: [EdenAuditLogViewerFixtures.aliceLogin],
        showFilters: false,
      )));
      expect(find.textContaining('alice@dod.gov'), findsOneWidget);
      expect(find.textContaining('authenticated'), findsOneWidget);
      expect(find.textContaining('session/web'), findsOneWidget);
    });
  });

  group('EdenAuditLogViewer — hash chain integrity', () {
    testWidgets('entry with prevHash + currHash renders verified link icon',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAuditLogViewer(
        entries: [EdenAuditLogViewerFixtures.aliceLogin],
        showFilters: false,
      )));
      expect(find.byIcon(Icons.link), findsOneWidget);
    });

    testWidgets('entry in brokenChainIndices renders red broken link icon',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAuditLogViewer(
        entries: [EdenAuditLogViewerFixtures.aliceLogin],
        brokenChainIndices: const {0},
        showFilters: false,
      )));
      expect(find.byIcon(Icons.link_off), findsOneWidget);
    });

    testWidgets('entry without hashes renders no chain icon', (tester) async {
      await tester.pumpWidget(wrap(EdenAuditLogViewer(
        entries: [EdenAuditLogViewerFixtures.unchainedEntry],
        showFilters: false,
      )));
      expect(find.byIcon(Icons.link), findsNothing);
      expect(find.byIcon(Icons.link_off), findsNothing);
    });
  });

  group('EdenAuditLogViewer — failed action', () {
    testWidgets('failed=true entry renders red error icon + FAILED chip',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAuditLogViewer(
        entries: [EdenAuditLogViewerFixtures.aliceFailedDelete],
        showFilters: false,
      )));
      expect(find.text('FAILED'), findsOneWidget);
    });
  });

  group('EdenAuditLogViewer — filtering', () {
    testWidgets('actor text search filters entries', (tester) async {
      await tester.pumpWidget(wrap(EdenAuditLogViewer(
        entries: EdenAuditLogViewerFixtures.mixed,
      )));
      // 4 entries initially.
      expect(find.byType(ListTile), findsNWidgets(4));
      // Enter actor filter.
      await tester.enterText(find.byType(TextField).first, 'alice');
      await tester.pump();
      // alice has 2 entries (login + failed delete).
      expect(find.byType(ListTile), findsNWidgets(2));
    });

    testWidgets('failed-only toggle filters to failed entries', (tester) async {
      await tester.pumpWidget(wrap(EdenAuditLogViewer(
        entries: EdenAuditLogViewerFixtures.mixed,
      )));
      // Find Failed-only checkbox/switch and toggle.
      final toggle = find.byWidgetPredicate(
        (w) => w is Switch || w is Checkbox,
      );
      expect(toggle, findsAtLeastNWidgets(1));
      await tester.tap(toggle.first);
      await tester.pump();
      // Only failed entry visible (1).
      expect(find.byType(ListTile), findsOneWidget);
    });
  });

  group('EdenAuditLogViewer — empty state', () {
    testWidgets('filtered to no matches renders empty-state text', (tester) async {
      await tester.pumpWidget(wrap(EdenAuditLogViewer(
        entries: EdenAuditLogViewerFixtures.mixed,
      )));
      await tester.enterText(
          find.byType(TextField).first, 'zzz-no-actor-matches');
      await tester.pump();
      expect(
        find.text('No audit log entries match the current filters'),
        findsOneWidget,
      );
    });

    testWidgets('empty entries list renders empty-state text', (tester) async {
      await tester.pumpWidget(wrap(const EdenAuditLogViewer(
        entries: [],
        showFilters: false,
      )));
      expect(
        find.text('No audit log entries match the current filters'),
        findsOneWidget,
      );
    });
  });

  group('EdenAuditLogViewer — expand on tap', () {
    testWidgets('tap entry expands to show details key/value rows',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAuditLogViewer(
        entries: [EdenAuditLogViewerFixtures.bobReadFile],
        showFilters: false,
      )));
      expect(find.textContaining('file_size_bytes'), findsNothing);
      await tester.tap(find.byType(ListTile).first);
      await tester.pump();
      expect(find.textContaining('file_size_bytes'), findsOneWidget);
      expect(find.textContaining('128048'), findsOneWidget);
    });
  });

  group('EdenAuditLogViewer — Section 508 a11y', () {
    testWidgets('each entry has Semantics announcing audit phrasing',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAuditLogViewer(
        entries: [EdenAuditLogViewerFixtures.aliceLogin],
        showFilters: false,
      )));
      final semantics = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            (w.properties.label?.startsWith('Audit:') ?? false) &&
            (w.properties.label?.contains('alice@dod.gov') ?? false) &&
            (w.properties.label?.contains('authenticated') ?? false),
      );
      expect(semantics, findsAtLeastNWidgets(1));
    });

    testWidgets('failed action Semantics label includes "failed"',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAuditLogViewer(
        entries: [EdenAuditLogViewerFixtures.aliceFailedDelete],
        showFilters: false,
      )));
      final semantics = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            (w.properties.label?.startsWith('Audit:') ?? false) &&
            (w.properties.label?.contains('failed') ?? false),
      );
      expect(semantics, findsAtLeastNWidgets(1));
    });
  });

  group('EdenAuditLogViewer — iPhone-narrow (390pt) safety', () {
    testWidgets('390pt: no overflow', (tester) async {
      await tester.pumpWidget(wrap(
        EdenAuditLogViewer(entries: EdenAuditLogViewerFixtures.mixed),
        width: 390,
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
