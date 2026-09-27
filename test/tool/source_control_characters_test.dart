// No source file may carry a raw ANSI/C0 control byte.
//
// WHY THIS EXISTS. `tool/gen_story_tests.dart` and
// `test_support/ui_oracle/story_harness.dart` each carried a comment that
// began with a terminal CLEAR-SCREEN sequence (ESC [3J ESC [H ESC [2J) typed
// into the source IN PLACE OF THE IDENTIFIER the sentence was about, in the
// commit that introduced both lines (6840f7c).
//
// Every tool downstream read it as if nothing were wrong: `dart analyze` is
// clean, `dart format` leaves it alone, and a reviewer's terminal literally
// clears the screen where the name should be, so the sentence reads as if it
// had always started mid-word. Both comments survived for five days naming
// nothing.
//
// It is cheap to make that class of accident loud, and there is no legitimate
// reason for a raw ESC, BEL, NUL or vertical-tab byte in a `.dart`, `.yaml`,
// `.md` or shell source here — an escape a program is meant to EMIT is
// written as an escape sequence in a string literal, which the source can be
// read through.
//
// ANTI-VACUITY. The census is pinned with a lower bound: a mis-globbed or
// empty file set would otherwise scan nothing and report a pass. Bytes are
// read and decoded in Dart rather than shelled out to `grep`, for the reason
// `eden_field_purpose_guard_test.dart` gives at length — a control byte is
// exactly the thing that blinds a grep.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Directories scanned, relative to the package root.
const List<String> kScannedRoots = <String>[
  'lib',
  'test',
  'test_support',
  'tool',
  'lints',
  '.github',
];

/// Extensions scanned. Binary payloads (`.png`, fonts) are excluded because a
/// control byte in them is data, not source.
const Set<String> kScannedExtensions = <String>{
  '.dart',
  '.yaml',
  '.yml',
  '.md',
  '.sh',
  '.json',
};

/// The C0 control characters that are legitimate in a text file: tab, line
/// feed, carriage return.
const Set<int> kAllowedControls = <int>{0x09, 0x0A, 0x0D};

List<File> _sources() {
  final List<File> out = <File>[];
  for (final String root in kScannedRoots) {
    final Directory dir = Directory(root);
    if (!dir.existsSync()) {
      continue;
    }
    for (final FileSystemEntity entity in dir.listSync(recursive: true)) {
      if (entity is! File) {
        continue;
      }
      final String path = entity.path;
      final int dot = path.lastIndexOf('.');
      if (dot < 0 || !kScannedExtensions.contains(path.substring(dot))) {
        continue;
      }
      out.add(entity);
    }
  }
  out.sort((File a, File b) => a.path.compareTo(b.path));
  return out;
}

void main() {
  final List<File> sources = _sources();

  test('the census is non-trivial, or the scan below proves nothing', () {
    // Measured well above this when it landed. The bound is deliberately far
    // below the real count: it is here to catch a scan that found NOTHING,
    // not to be a number somebody has to maintain.
    expect(
      sources.length,
      greaterThan(200),
      reason: 'the source scan found ${sources.length} files. A glob that '
          'matches nothing passes the assertion below without reading a '
          'byte.',
    );
  });

  test('no source file carries a raw control byte', () {
    final List<String> offences = <String>[];

    for (final File file in sources) {
      final String text =
          utf8.decode(file.readAsBytesSync(), allowMalformed: true);
      int line = 1;
      for (final int rune in text.runes) {
        if (rune == 0x0A) {
          line++;
          continue;
        }
        if (rune < 0x20 && !kAllowedControls.contains(rune)) {
          final String hex =
              rune.toRadixString(16).padLeft(4, '0').toUpperCase();
          offences.add('${file.path}:$line carries U+$hex');
        }
      }
    }

    expect(
      offences,
      isEmpty,
      reason: 'a raw control byte is in the source. If it replaced an '
          'identifier in a comment — which is what happened in 6840f7c, '
          'twice — restore the identifier. If a program is genuinely meant '
          'to EMIT the escape, write it as an escape sequence inside a '
          'string literal so the source can be read.\n  '
          '${offences.join('\n  ')}',
    );
  });
}
