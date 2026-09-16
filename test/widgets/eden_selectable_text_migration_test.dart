// TRD 40-07 — migration guard.
//
// Objective 040 installs ONE selection region per layout/page
// (EdenSelectableRegion, TRD 40-02, wired in by TRD 40-06). Under that design a
// per-widget selectable-text widget is not a redundant belt-and-braces: nesting
// one inside a SelectionArea creates an un-draggable selection ISLAND, so a drag
// begun outside it stops dead at its boundary (40-RESEARCH.md section 5).
//
// The 8 ad-hoc call sites were migrated to plain Text. These cases keep them
// migrated, and keep a future contributor from reaching for the banned APIs.

import 'dart:convert';
import 'dart:io';

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The banned widget token, assembled at compile time from fragments so this
/// guard file never contains the literal it polices.
const String kBannedSelectableWidget = 'Selectable' 'Text';

/// Likewise for the selection-observer API. It does NOT exist at the declared
/// `>=3.27.0` SDK floor, so a contributor on a newer local SDK could reach for
/// it, compile fine locally, and break every consumer pinned to the floor.
const String kBannedSelectionObserver = 'Selection' 'Listener';

/// This file's own path, so the scan can skip it.
const String kGuardFileSuffix = 'eden_selectable_text_migration_test.dart';

/// Every `.dart` file under [dirPath], read as UTF-8.
///
/// Fails LOUDLY on a file it cannot decode rather than skipping it. A single
/// stray control byte once turned `grep` silently blind for a whole file
/// (40-RESEARCH.md Appendix B4) — a guard that quietly scans nothing is worse
/// than no guard at all.
List<File> _dartFilesUnder(String dirPath) {
  final Directory dir = Directory(dirPath);
  if (!dir.existsSync()) {
    fail(
      'Cannot scan "$dirPath": it does not exist. Resolved against '
      '${Directory.current.absolute.path}. The guard must never silently '
      'scan an empty set.',
    );
  }
  final List<File> files = dir
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((File a, File b) => a.path.compareTo(b.path));

  if (files.isEmpty) {
    fail(
      'Scanned "$dirPath" and found ZERO .dart files. Resolved against '
      '${Directory.current.absolute.path}. Refusing to pass vacuously.',
    );
  }
  return files;
}

/// Decodes [file] strictly, failing with the path if it is not valid UTF-8.
String _readStrict(File file) {
  try {
    return utf8.decode(file.readAsBytesSync(), allowMalformed: false);
  } on FormatException catch (e) {
    fail(
      'Could not read ${file.path} as UTF-8 text: $e\n'
      'A raw control byte in source silently blinds token scans '
      '(40-RESEARCH.md Appendix B4). Fix the file rather than exempting it.',
    );
  }
}

/// `path:line` for every line of every file under [dirPath] containing [token].
List<String> _scanFor(String token, String dirPath) {
  final List<String> hits = <String>[];
  for (final File file in _dartFilesUnder(dirPath)) {
    if (file.path.endsWith(kGuardFileSuffix)) continue;
    final List<String> lines = const LineSplitter().convert(_readStrict(file));
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains(token)) {
        hits.add('${file.path}:${i + 1}');
      }
    }
  }
  return hits;
}

void main() {
  group('TRD 40-07 — SelectableText migration guard', () {
    setUpAll(() {
      // Anchor the walk. If the harness ever runs from a different cwd this
      // fails with the resolved path instead of scanning nothing and passing.
      expect(
        File('lib/eden_ui.dart').existsSync(),
        isTrue,
        reason: 'expected to run from the package root; cwd is '
            '${Directory.current.absolute.path}',
      );
    });

    test('no $kBannedSelectableWidget remains under lib/', () {
      final List<String> hits = _scanFor(kBannedSelectableWidget, 'lib');
      expect(
        hits,
        isEmpty,
        reason: '$kBannedSelectableWidget found at:\n  ${hits.join('\n  ')}\n\n'
            '$kBannedSelectableWidget inside a SelectionArea is an '
            'un-draggable selection island (40-RESEARCH.md section 5). Use '
            'plain Text — the ambient EdenSelectableRegion makes it '
            'selectable, and a drag can then continue through it into the '
            'surrounding content.',
      );
    });

    test('no $kBannedSelectionObserver anywhere in lib/ or test/', () {
      final List<String> hits = <String>[
        ..._scanFor(kBannedSelectionObserver, 'lib'),
        ..._scanFor(kBannedSelectionObserver, 'test'),
      ];
      expect(
        hits,
        isEmpty,
        reason: '$kBannedSelectionObserver found at:\n  ${hits.join('\n  ')}\n\n'
            '$kBannedSelectionObserver does not exist at the declared '
            '>=3.27.0 SDK floor (40-BASELINE.md). Code using it compiles on a '
            'newer local SDK and breaks every consumer on the floor. Use '
            'SelectionArea.onSelectionChanged, forwarded by '
            'EdenSelectableRegion.',
      );
    });
  });

  group('TRD 40-07 — the migrated widgets still render their text', () {
    // Each fixture is hand-built inline and pumped under a test-local
    // EdenSelectableRegion — the same ancestor the Eden layouts and pages
    // install — proving the swap to plain Text cost no rendering.
    Widget wrap(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: EdenSelectableRegion(
            child: SingleChildScrollView(child: child),
          ),
        ),
      );
    }

    testWidgets('1/8 EdenCard renders title and subtitle', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCard(title: 'probe card title', subtitle: 'probe card sub'),
      ));
      expect(find.text('probe card title'), findsOneWidget);
      expect(find.text('probe card sub'), findsOneWidget);
    });

    testWidgets('2/8 EdenReceiptPreview sms body renders', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenReceiptPreview(
          mode: EdenReceiptPreviewMode.sms,
          data: EdenReceiptData(
            storeHeader: EdenReceiptStoreHeader(storeName: 'Probe Store'),
            lineItems: <EdenReceiptLineItem>[
              EdenReceiptLineItem(
                name: 'Probe Item',
                qty: 1,
                unitPriceCents: 500,
              ),
            ],
            subtotalCents: 500,
            taxCents: 40,
            totalCents: 540,
            tenderSummary: <EdenReceiptTender>[
              EdenReceiptTender(
                method: EdenReceiptTenderMethod.card,
                amountCents: 540,
              ),
            ],
          ),
        ),
      ));
      expect(find.textContaining('Probe Store'), findsOneWidget);
      expect(find.textContaining('Probe Item'), findsOneWidget);
    });

    testWidgets('3/8 EdenCommitDetail renders the sha', (tester) async {
      await tester.pumpWidget(wrap(
        EdenCommitDetail(
          sha: 'probe0sha0123',
          message: 'probe commit message',
          authorName: 'Probe Author',
          authorEmail: 'probe@example.test',
          timestamp: DateTime(2026, 1, 2, 3, 4),
        ),
      ));
      expect(find.text('probe0sha0123'), findsWidgets);
    });

    testWidgets('4/8 EdenEmailViewer renders the body', (tester) async {
      await tester.pumpWidget(wrap(
        const SizedBox(
          height: 900,
          child: EdenEmailViewer(
            subject: 'probe subject',
            from: 'probe@example.test',
            bodyText: 'probe email body',
          ),
        ),
      ));
      expect(find.text('probe email body'), findsOneWidget);
    });

    testWidgets('5/8 EdenSOAPNote view mode renders section values',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenSOAPNote(
          patientId: 'probe-pt',
          mode: EdenSoapMode.view,
          data: const EdenSoapNoteData(
            patientId: 'probe-pt',
            subjective: 'probe subjective value',
          ),
        ),
      ));
      expect(find.text('probe subjective value'), findsOneWidget);
    });

    testWidgets('6/8 EdenTerminalOutput renders the output', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenTerminalOutput(output: 'probe terminal output line'),
      ));
      expect(find.text('probe terminal output line'), findsOneWidget);
    });

    testWidgets('7/8 EdenArticleView renders the article body',
        (tester) async {
      await tester.pumpWidget(wrap(
        SizedBox(
          height: 900,
          child: EdenArticleView(
            article: const SupportArticle(
              id: 'probe-article',
              title: 'probe article title',
              viewCount: 0,
              helpfulCount: 0,
              body: 'probe article body',
            ),
            config: const EdenSupportPanelConfig(),
            onBack: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('probe article body'), findsOneWidget);
    });

    testWidgets('8/8 EdenHelpTab renders an article body on drill-in',
        (tester) async {
      const SupportArticle article = SupportArticle(
        id: 'probe-help',
        title: 'probe help title',
        viewCount: 0,
        helpfulCount: 0,
        body: 'probe help body',
      );
      await tester.pumpWidget(wrap(
        SizedBox(
          height: 900,
          child: EdenHelpTab(
            config: EdenSupportPanelConfig(
              listArticles: ({String? categoryId}) async =>
                  const <SupportArticle>[article],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('probe help title'));
      await tester.pumpAndSettle();

      expect(find.text('probe help body'), findsOneWidget);
    });
  });
}
