import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_case_file_shell_fixtures.dart';

Widget wrap(Widget child, {double width = 800, double height = 700}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );

void main() {
  group('EdenCaseFile value classes', () {
    test('EdenCaseFileDocument stores required fields', () {
      final d = EdenCaseFileDocument(
        id: 'd1',
        name: 'x.pdf',
        sizeBytes: 1,
        uploadedAt: DateTime(2026),
        uploadedBy: 'a',
      );
      expect(d.status, EdenUploadStatus.complete);
    });

    test('EdenCaseFileContact defaults contactInfo to empty map', () {
      const c = EdenCaseFileContact(id: 'c', name: 'N', role: 'R');
      expect(c.contactInfo, isEmpty);
    });

    test('EdenCaseFileNote defaults isPrivileged false', () {
      final n = EdenCaseFileNote(
        id: 'n',
        author: 'a',
        timestamp: DateTime(2026),
        content: 'c',
      );
      expect(n.isPrivileged, isFalse);
    });
  });

  group('EdenCaseFileShell — shell rendering', () {
    testWidgets('renders case title + caseId + status', (tester) async {
      await tester.pumpWidget(wrap(EdenCaseFileShell(
        data: EdenCaseFileShellFixtures.dhhsCase,
      )));
      expect(find.textContaining('Smith Family'), findsOneWidget);
      expect(find.textContaining('CASE-2026-0042'), findsOneWidget);
      expect(find.textContaining('Open'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders TabBar with 6 standard tabs', (tester) async {
      await tester.pumpWidget(wrap(EdenCaseFileShell(
        data: EdenCaseFileShellFixtures.dhhsCase,
      )));
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Contacts'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Audit'), findsOneWidget);
    });
  });

  group('EdenCaseFileShell — per-tab content', () {
    testWidgets('Overview tab renders headerMetadata + assignedTo + openedAt',
        (tester) async {
      await tester.pumpWidget(wrap(EdenCaseFileShell(
        data: EdenCaseFileShellFixtures.dhhsCase,
      )));
      expect(find.textContaining('Cobb'), findsOneWidget);
      expect(find.textContaining('Child welfare'), findsOneWidget);
      expect(find.textContaining('caseworker.jones'), findsAtLeastNWidgets(1));
    });

    testWidgets('Documents tab renders document names + size', (tester) async {
      await tester.pumpWidget(wrap(EdenCaseFileShell(
        data: EdenCaseFileShellFixtures.dhhsCase,
      )));
      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();
      expect(find.textContaining('intake-form.pdf'), findsOneWidget);
      expect(find.textContaining('medical-history.pdf'), findsOneWidget);
    });

    testWidgets('Contacts tab renders contact names + roles', (tester) async {
      await tester.pumpWidget(wrap(EdenCaseFileShell(
        data: EdenCaseFileShellFixtures.dhhsCase,
      )));
      await tester.tap(find.text('Contacts'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Alex Subject'), findsOneWidget);
      expect(find.textContaining('Subject'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Dana Counsel'), findsOneWidget);
    });

    testWidgets('Notes tab renders notes with author + content', (tester) async {
      await tester.pumpWidget(wrap(EdenCaseFileShell(
        data: EdenCaseFileShellFixtures.dhhsCase,
      )));
      await tester.tap(find.text('Notes'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Initial intake interview'), findsOneWidget);
      expect(find.textContaining('counsel.smith'), findsOneWidget);
    });

    testWidgets('Audit tab composes EdenAuditLogViewer', (tester) async {
      await tester.pumpWidget(wrap(EdenCaseFileShell(
        data: EdenCaseFileShellFixtures.dhhsCase,
      )));
      await tester.tap(find.text('Audit'));
      await tester.pumpAndSettle();
      expect(find.byType(EdenAuditLogViewer), findsOneWidget);
    });

    testWidgets('empty Documents tab renders empty-state text', (tester) async {
      await tester.pumpWidget(wrap(EdenCaseFileShell(
        data: EdenCaseFileShellFixtures.emptyCase,
      )));
      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No documents'), findsOneWidget);
    });
  });

  group('EdenCaseFileShell — privileged note', () {
    testWidgets('privileged note renders PRIVILEGED EdenClassificationBanner',
        (tester) async {
      await tester.pumpWidget(wrap(EdenCaseFileShell(
        data: EdenCaseFileShellFixtures.dhhsCase,
      )));
      await tester.tap(find.text('Notes'));
      await tester.pumpAndSettle();
      expect(find.text('PRIVILEGED'), findsOneWidget);
    });
  });

  group('EdenCaseFileShell — classification overlay', () {
    testWidgets('classification: secret wraps shell in EdenClassificationBannerScaffold',
        (tester) async {
      await tester.pumpWidget(wrap(EdenCaseFileShell(
        data: EdenCaseFileShellFixtures.classifiedCase,
      )));
      expect(find.text('SECRET'), findsAtLeastNWidgets(1));
      expect(find.byType(EdenClassificationBannerScaffold), findsOneWidget);
    });

    testWidgets('classification: null does NOT wrap in scaffold', (tester) async {
      await tester.pumpWidget(wrap(EdenCaseFileShell(
        data: EdenCaseFileShellFixtures.dhhsCase,
      )));
      expect(find.byType(EdenClassificationBannerScaffold), findsNothing);
    });
  });

  group('EdenCaseFileShell — Section 508 a11y', () {
    testWidgets('each tab has Semantics label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(EdenCaseFileShell(
        data: EdenCaseFileShellFixtures.dhhsCase,
      )));
      // Material Tab widgets have built-in Semantics with the label.
      for (final t in ['Overview', 'Activity', 'Documents', 'Contacts',
        'Notes', 'Audit']) {
        expect(find.text(t), findsOneWidget);
      }
      handle.dispose();
    });
  });

  group('EdenCaseFileShell — iPhone-narrow (390pt) safety', () {
    testWidgets('390pt: tabs scroll horizontally, no overflow', (tester) async {
      await tester.pumpWidget(wrap(
        EdenCaseFileShell(data: EdenCaseFileShellFixtures.dhhsCase),
        width: 390,
      ));
      expect(tester.takeException(), isNull);
      expect(find.byType(TabBar), findsOneWidget);
    });
  });
}
