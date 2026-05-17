import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_file_upload_fixtures.dart';

Widget wrap(Widget child, {double width = 500}) =>
    MaterialApp(home: Scaffold(body: SizedBox(width: width, child: child)));

void main() {
  group('EdenUploadStatus — additive enum (backwards compat)', () {
    test('values length increased from 4 → 8 with 4 new compliance states', () {
      expect(EdenUploadStatus.values.length, 8);
    });

    test('existing indexes preserved: pending=0, uploading=1, complete=2, error=3', () {
      expect(EdenUploadStatus.pending.index, 0);
      expect(EdenUploadStatus.uploading.index, 1);
      expect(EdenUploadStatus.complete.index, 2);
      expect(EdenUploadStatus.error.index, 3);
    });

    test('new compliance states ordered after error', () {
      expect(EdenUploadStatus.virusScanning.index, 4);
      expect(EdenUploadStatus.virusScanFailed.index, 5);
      expect(EdenUploadStatus.cuiMarked.index, 6);
      expect(EdenUploadStatus.quarantined.index, 7);
    });
  });

  group('EdenUploadFile — additive fields', () {
    test('new fields default to null on minimal construction', () {
      const f = EdenUploadFile(name: 'x', sizeBytes: 1);
      expect(f.scanProgress, isNull);
      expect(f.cuiMarking, isNull);
      expect(f.quarantineReason, isNull);
    });

    test('copyWith applies new fields without dropping existing', () {
      const base = EdenUploadFile(
        name: 'doc.pdf',
        sizeBytes: 1024,
        mimeType: 'application/pdf',
      );
      final copied = base.copyWith(
        status: EdenUploadStatus.virusScanning,
        scanProgress: 0.5,
      );
      expect(copied.name, 'doc.pdf');
      expect(copied.sizeBytes, 1024);
      expect(copied.mimeType, 'application/pdf');
      expect(copied.status, EdenUploadStatus.virusScanning);
      expect(copied.scanProgress, 0.5);
    });
  });

  group('EdenFileUpload — baseline backwards compat (renders without throwing)', () {
    testWidgets('pending file renders', (tester) async {
      await tester.pumpWidget(wrap(const EdenFileUpload(
        files: [EdenFileUploadFixtures.baselinePending],
      )));
      expect(find.text('doc.pdf'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('all 4 baseline statuses render without exception', (tester) async {
      await tester.pumpWidget(wrap(const EdenFileUpload(
        files: [
          EdenFileUploadFixtures.baselinePending,
          EdenFileUploadFixtures.baselineUploading,
          EdenFileUploadFixtures.baselineComplete,
          EdenFileUploadFixtures.baselineError,
        ],
      )));
      expect(tester.takeException(), isNull);
      expect(find.text('42%'), findsOneWidget); // uploading 0.42 → 42%
    });
  });

  group('EdenFileUpload — new compliance status rendering', () {
    testWidgets('virusScanning renders progress spinner + Scanning text + percent',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenFileUpload(
        files: [EdenFileUploadFixtures.scanningWithProgress],
      )));
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      expect(find.textContaining('Scanning'), findsOneWidget);
      expect(find.textContaining('40'), findsOneWidget); // 0.4 → 40%
    });

    testWidgets('virusScanning with null scanProgress renders indeterminate',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenFileUpload(
        files: [EdenFileUploadFixtures.scanningIndeterminate],
      )));
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('virusScanFailed renders shield icon + Virus scan failed text',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenFileUpload(
        files: [EdenFileUploadFixtures.scanFailed],
      )));
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
      expect(find.text('Virus scan failed'), findsOneWidget);
    });

    testWidgets('cuiMarked renders warning icon + CUI: marking text', (tester) async {
      await tester.pumpWidget(wrap(const EdenFileUpload(
        files: [EdenFileUploadFixtures.cuiMarked],
      )));
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
      expect(find.textContaining('CUI'), findsAtLeastNWidgets(1));
      expect(find.textContaining('CUI//SP-PII'), findsOneWidget);
    });

    testWidgets('quarantined renders lock icon + Quarantined: reason', (tester) async {
      await tester.pumpWidget(wrap(const EdenFileUpload(
        files: [EdenFileUploadFixtures.quarantined],
      )));
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.textContaining('Quarantined'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Spillage'), findsOneWidget);
    });
  });

  group('EdenFileUpload — Section 508 a11y per new status', () {
    testWidgets('virusScanning Semantics announces Virus scanning in progress',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(const EdenFileUpload(
        files: [EdenFileUploadFixtures.scanningWithProgress],
      )));
      expect(find.bySemanticsLabel(RegExp('Virus scanning')),
          findsAtLeastNWidgets(1));
      handle.dispose();
    });

    testWidgets('virusScanFailed Semantics announces Virus scan failed', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(const EdenFileUpload(
        files: [EdenFileUploadFixtures.scanFailed],
      )));
      expect(find.bySemanticsLabel(RegExp('Virus scan failed')),
          findsAtLeastNWidgets(1));
      handle.dispose();
    });

    testWidgets('cuiMarked Semantics announces Controlled Unclassified', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(const EdenFileUpload(
        files: [EdenFileUploadFixtures.cuiMarked],
      )));
      expect(find.bySemanticsLabel(RegExp('Controlled Unclassified')),
          findsAtLeastNWidgets(1));
      handle.dispose();
    });

    testWidgets('quarantined Semantics announces Quarantined', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(const EdenFileUpload(
        files: [EdenFileUploadFixtures.quarantined],
      )));
      expect(find.bySemanticsLabel(RegExp('Quarantined')),
          findsAtLeastNWidgets(1));
      handle.dispose();
    });
  });

  group('EdenFileUpload — iPhone-narrow (390pt) safety', () {
    testWidgets('all 4 new statuses render without overflow at 390pt',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenFileUpload(
          files: [
            EdenFileUploadFixtures.scanningWithProgress,
            EdenFileUploadFixtures.scanFailed,
            EdenFileUploadFixtures.cuiMarked,
            EdenFileUploadFixtures.quarantined,
          ],
        ),
        width: 390,
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
