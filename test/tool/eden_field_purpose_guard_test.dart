// test/tool/eden_field_purpose_guard_test.dart
//
// TRD 40-17 — the field-purpose regression guard.
//
// WHY THIS EXISTS
//   Objective 040 swept 136 text inputs across 69 files and gave every one of
//   them an explicit EdenFieldPurpose. Without a guard that sweep is a snapshot
//   that decays from the next PR onward: one careless `TextField(` undoes it.
//   A field with no purpose emits `autocomplete="on"` with no name and no id
//   (`text_editing.dart:514-531`), so no password manager can classify it.
//
// THE RULE
//   In any `.dart` file under `lib/`, the number of TextField / TextFormField /
//   EdenInput instantiations found in CODE must not exceed the number of
//   purpose declarations in that file, where a declaration is any of:
//     - an `EdenFieldPurpose.` reference in code — a `purpose:` argument, or a
//       local `const p = EdenFieldPurpose.x;` feeding a `...p.semantics` spread
//     - an `// eden-field-purpose: EdenFieldPurpose.x` marker comment
//     - an `// eden-field-purpose: exempt — <why>` exemption WITH a reason
//
//   Counting rather than parsing is deliberate: dependency-free, fast, and
//   impossible to satisfy accidentally. The failure mode it permits (two fields
//   and two purposes, mismatched) is caught by the per-file behaviour tests the
//   sweeps added. The failure mode it PREVENTS — a new field landing with no
//   purpose anywhere in the file — is the one that actually happens.
//
// ANTI-VACUITY — why this file is longer than the rule it enforces
//   This objective produced FIVE separate checks that reported success while
//   testing nothing: a NUL byte that silently blinded every `grep`; copy/cut
//   assertions that passed because no text was selected; a one-row fixture that
//   made "copy row" and "copy table" byte-identical; an unquoted `md5 -q` that
//   diffed two empty files; and mutation probes that survived because only half
//   the assertion was written. A guard that passes vacuously is worse than no
//   guard, because it certifies the problem as solved. So:
//
//   1. It NEVER shells out to `grep`. Bytes are read and decoded in Dart, so
//      the NUL-byte blinding of 40-RESEARCH.md Appendix B4 is structurally
//      impossible — a NUL is valid UTF-8 and scans as an ordinary code point.
//      Genuinely malformed UTF-8 still fails loudly, and has its own case.
//   2. It pins the MEASURED census (files scanned, files with fields, total
//      fields, total purpose declarations) with lower bounds. A mis-globbed,
//      empty, or silently-blanked file set fails instead of passing.
//   3. It pins the PHANTOM. `lib/src/widgets/eden_scheduler.dart` contains the
//      token `TextField(` exactly once, inside a dartdoc, and contains no text
//      input at all (Appendix B8). Asserting it has ZERO fields means the
//      comment stripper cannot silently stop running: if it did, that file
//      would report one field and this test would fail. Its mirror — a file
//      that must report MORE than zero — means the stripper cannot silently
//      blank everything either. Both directions are nailed down.
//   4. Every branch of the scanner has a hand-written fixture: comments,
//      strings that look like comments, comments that look like markers, nested
//      block comments, raw and triple-quoted strings, interpolation, a NUL
//      byte, and an identifier that merely ends in `TextField`.
//
// NOT IN SCOPE, ON PURPOSE
//   Duplicate-DOM-id analysis. `element.id` is derived from the hint string, so
//   only HINT-BEARING purposes can collide (Appendix B9). Repeated hint-free
//   fields — repeater rows, split date components, per-row notes — are correct
//   and must not be flagged.

import 'dart:convert';
import 'dart:io';

import 'package:eden_ui_flutter/src/widgets/eden_field_purpose.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Reuse the engine's hint -> browser-token mirror rather than writing a second
// copy that can drift (40-RESEARCH.md Appendix B2). `AutofillHints.newPassword`
// is the camelCase string `newPassword`, which does NOT contain lowercase
// `password`; the engine maps it to `new-password` BEFORE the case-sensitive
// check at `text_editing.dart:514-531`. Only `show` is imported, so this file's
// own `main` is unaffected.
import '../widgets/eden_field_purpose_test.dart' show browserTokenFor;

// ---------------------------------------------------------------------------
// Part 1 — the comment/string stripper
//
// B8 requires that matches inside `//`, `///` and `/* */` are NOT counted as
// fields: `eden_scheduler.dart` has a `TextField(` in prose and no input at
// all, and a guard that counted it would force a meaningless marker comment —
// a lie — into a file with nothing to mark.
//
// Stripping comments correctly requires knowing where string literals are,
// because `'https://example.com'` is not a comment and a doubled slash inside
// a string is not one either. Once strings are tracked, blanking their CONTENTS
// is nearly free and removes a second class of false positive. This is a
// comment stripper, not a Dart parser: no `analyzer` dependency, no AST.
//
// Both output views preserve every newline at its original offset, so byte
// offsets and line numbers stay aligned with the original source.
// ---------------------------------------------------------------------------

const int _kNewline = 0x0A;
const int _kCarriageReturn = 0x0D;
const int _kSpace = 0x20;
const int _kSlash = 0x2F;
const int _kStar = 0x2A;
const int _kSingleQuote = 0x27;
const int _kDoubleQuote = 0x22;
const int _kBackslash = 0x5C;
const int _kDollar = 0x24;
const int _kOpenBrace = 0x7B;
const int _kCloseBrace = 0x7D;
const int _kOpenParen = 0x28;
const int _kCloseParen = 0x29;
const int _kLowerR = 0x72;
const int _kUnderscore = 0x5F;

bool _isIdentifierUnit(int unit) =>
    (unit >= 0x30 && unit <= 0x39) ||
    (unit >= 0x41 && unit <= 0x5A) ||
    (unit >= 0x61 && unit <= 0x7A) ||
    unit == _kUnderscore ||
    unit == _kDollar;

/// One Dart source file split into two line-aligned views of the same text.
class DartSourceSplit {
  const DartSourceSplit({required this.code, required this.comments});

  /// Everything outside comments and outside string-literal CONTENTS, with the
  /// removed spans replaced by spaces.
  final String code;

  /// The mirror image: comment text only, with code blanked.
  final String comments;
}

/// Splits [source] into a code view and a comment view.
DartSourceSplit splitDartSource(String source) {
  final List<int> units = source.codeUnits;
  final int n = units.length;
  final List<int> code = List<int>.filled(n, _kSpace);
  final List<int> comments = List<int>.filled(n, _kSpace);
  // Seed both views with the original line structure so neither can drift.
  for (int i = 0; i < n; i++) {
    if (units[i] == _kNewline || units[i] == _kCarriageReturn) {
      code[i] = units[i];
      comments[i] = units[i];
    }
  }
  _scanCode(units, 0, n, code, comments, stopAtCloseBrace: false);
  return DartSourceSplit(
    code: String.fromCharCodes(code),
    comments: String.fromCharCodes(comments),
  );
}

/// Scans [units] in `[start, end)` as CODE.
///
/// When [stopAtCloseBrace] is true, returns at the first `}` that is not
/// matched by an earlier `{` — that is how a `${ ... }` interpolation body ends.
int _scanCode(
  List<int> units,
  int start,
  int end,
  List<int> code,
  List<int> comments, {
  required bool stopAtCloseBrace,
}) {
  int i = start;
  int braceDepth = 0;
  while (i < end) {
    final int c = units[i];

    if (c == _kSlash && i + 1 < end && units[i + 1] == _kSlash) {
      while (i < end && units[i] != _kNewline) {
        comments[i] = units[i];
        i++;
      }
      continue;
    }

    if (c == _kSlash && i + 1 < end && units[i + 1] == _kStar) {
      i = _scanBlockComment(units, i, end, comments);
      continue;
    }

    if (_startsStringLiteral(units, i, end)) {
      i = _scanStringLiteral(units, i, end, code, comments);
      continue;
    }

    if (c == _kOpenBrace) {
      braceDepth++;
    } else if (c == _kCloseBrace) {
      if (stopAtCloseBrace && braceDepth == 0) {
        return i;
      }
      braceDepth--;
    }

    code[i] = c;
    i++;
  }
  return end;
}

/// Consumes a block comment, honouring Dart's NESTED block comments.
int _scanBlockComment(
  List<int> units,
  int start,
  int end,
  List<int> comments,
) {
  int i = start;
  int depth = 0;
  while (i < end) {
    if (units[i] == _kSlash && i + 1 < end && units[i + 1] == _kStar) {
      depth++;
      comments[i] = units[i];
      comments[i + 1] = units[i + 1];
      i += 2;
      continue;
    }
    if (units[i] == _kStar && i + 1 < end && units[i + 1] == _kSlash) {
      depth--;
      comments[i] = units[i];
      comments[i + 1] = units[i + 1];
      i += 2;
      if (depth <= 0) {
        return i;
      }
      continue;
    }
    comments[i] = units[i];
    i++;
  }
  return end;
}

/// True when a string literal starts at [i] — including a raw string, but not
/// an identifier that merely ends in `r`.
bool _startsStringLiteral(List<int> units, int i, int end) {
  final int c = units[i];
  if (c == _kSingleQuote || c == _kDoubleQuote) {
    return true;
  }
  if (c == _kLowerR &&
      i + 1 < end &&
      (units[i + 1] == _kSingleQuote || units[i + 1] == _kDoubleQuote)) {
    return i == 0 || !_isIdentifierUnit(units[i - 1]);
  }
  return false;
}

/// Consumes one string literal, blanking its CONTENTS but keeping its
/// delimiters in the code view.
///
/// A `${ ... }` interpolation body is handed back to [_scanCode], so an
/// expression inside a string keeps counting as code and its parens stay
/// balanced.
int _scanStringLiteral(
  List<int> units,
  int start,
  int end,
  List<int> code,
  List<int> comments,
) {
  int i = start;
  bool raw = false;
  if (units[i] == _kLowerR) {
    raw = true;
    code[i] = units[i];
    i++;
  }
  final int quote = units[i];
  final bool triple =
      i + 2 < end && units[i + 1] == quote && units[i + 2] == quote;
  final int delimiterLength = triple ? 3 : 1;
  for (int k = 0; k < delimiterLength && i + k < end; k++) {
    code[i + k] = units[i + k];
  }
  i += delimiterLength;

  while (i < end) {
    final int c = units[i];
    if (!raw && c == _kBackslash) {
      i += 2;
      continue;
    }
    // Raw strings do not interpolate.
    if (!raw && c == _kDollar && i + 1 < end && units[i + 1] == _kOpenBrace) {
      code[i] = c;
      code[i + 1] = units[i + 1];
      final int afterExpression = _scanCode(
        units,
        i + 2,
        end,
        code,
        comments,
        stopAtCloseBrace: true,
      );
      if (afterExpression >= end) {
        return end;
      }
      code[afterExpression] = units[afterExpression];
      i = afterExpression + 1;
      continue;
    }
    if (c == quote) {
      if (!triple) {
        code[i] = c;
        return i + 1;
      }
      if (i + 2 < end && units[i + 1] == quote && units[i + 2] == quote) {
        code[i] = c;
        code[i + 1] = c;
        code[i + 2] = c;
        return i + 3;
      }
    }
    if (!triple && c == _kNewline) {
      // Unterminated single-line string. Recover at the newline rather than
      // running away and desyncing every line after it.
      return i;
    }
    i++;
  }
  return end;
}

// ---------------------------------------------------------------------------
// Part 2 — the census
// ---------------------------------------------------------------------------

/// The constructors that create a text input in this package.
const List<String> kFieldConstructors = <String>[
  'TextField',
  'TextFormField',
  'EdenInput',
];

/// Any `EdenFieldPurpose.<member>` reference. Counted in the CODE view.
final RegExp kPurposeReferencePattern =
    RegExp(r'EdenFieldPurpose\.[A-Za-z_][A-Za-z0-9_]*');

/// The marker-comment form of a purpose declaration. Counted in the COMMENT
/// view — it is the mechanism by which a field that takes no autofill identity
/// says so without a `...semantics` spread that would change its keyboard.
final RegExp kPurposeMarkerPattern =
    RegExp(r'eden-field-purpose:\s*EdenFieldPurpose\.[A-Za-z_][A-Za-z0-9_]*');

/// Any exemption marker, reasoned or not.
final RegExp kExemptionPattern = RegExp(r'eden-field-purpose:\s*exempt');

/// An exemption marker WITH a written reason after a dash. An exemption with no
/// reason is an omission with extra steps, so only this form counts.
final RegExp kReasonedExemptionPattern =
    RegExp(r'eden-field-purpose:\s*exempt\s*(?:—|–|--|-)\s*(\S.*)$');

/// The shortest reason accepted on an exemption.
const int kMinimumExemptionReasonLength = 10;

/// One text-input construction site.
class EdenFieldSite {
  const EdenFieldSite({
    required this.constructorName,
    required this.line,
    required this.arguments,
  });

  final String constructorName;
  final int line;

  /// The argument list, from the code view, with comments and string contents
  /// already blanked.
  final String arguments;

  bool get declaresAutofillHints => arguments.contains('autofillHints');
  bool get declaresKeyboardType => arguments.contains('keyboardType');

  /// A field carrying hints but no explicit keyboard.
  ///
  /// `TextField` resolves a null `keyboardType` in its own initializer list
  /// (`material/text_field.dart:355`), so Flutter's inference from the hints
  /// NEVER runs and the field resolves to `TextInputType.text`. Since
  /// `AutofillHints.email` works only with `TextInputType.emailAddress`
  /// (`editable_text.dart:1855-1858`), such a field looks fixed in review and
  /// is still broken on iOS. Hints alone must fail (Appendix B1).
  bool get isHintOnly => declaresAutofillHints && !declaresKeyboardType;
}

/// What one file declares.
class EdenFieldFileCensus {
  const EdenFieldFileCensus({
    required this.path,
    required this.fieldSites,
    required this.purposeReferences,
    required this.purposeMarkers,
    required this.reasonedExemptions,
    required this.bareExemptions,
  });

  final String path;
  final List<EdenFieldSite> fieldSites;

  /// `EdenFieldPurpose.` references in CODE.
  final int purposeReferences;

  /// `eden-field-purpose: EdenFieldPurpose.x` marker comments.
  final int purposeMarkers;

  /// Exemption markers WITH a reason.
  final int reasonedExemptions;

  /// Exemption markers with no reason. Deliberately do NOT count.
  final int bareExemptions;

  int get fieldCount => fieldSites.length;

  int get declaredCoverage =>
      purposeReferences + purposeMarkers + reasonedExemptions;

  bool get isCovered => declaredCoverage >= fieldCount;

  List<EdenFieldSite> get hintOnlySites =>
      fieldSites.where((EdenFieldSite s) => s.isHintOnly).toList();
}

List<int> _newlineOffsets(String source) {
  final List<int> offsets = <int>[];
  for (int i = 0; i < source.length; i++) {
    if (source.codeUnitAt(i) == _kNewline) {
      offsets.add(i);
    }
  }
  return offsets;
}

int _lineFor(List<int> newlineOffsets, int offset) {
  int lo = 0;
  int hi = newlineOffsets.length;
  while (lo < hi) {
    final int mid = (lo + hi) >> 1;
    if (newlineOffsets[mid] < offset) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  return lo + 1;
}

/// Index of the `)` matching the `(` at [openIndex], or -1 when unbalanced.
int _matchingParen(String code, int openIndex) {
  int depth = 0;
  for (int i = openIndex; i < code.length; i++) {
    final int c = code.codeUnitAt(i);
    if (c == _kOpenParen) {
      depth++;
    } else if (c == _kCloseParen) {
      depth--;
      if (depth == 0) {
        return i;
      }
    }
  }
  return -1;
}

/// The counting rule, as a pure function over a String so it is directly
/// testable without touching the filesystem.
EdenFieldFileCensus analyzeDartSource(String source, {required String path}) {
  final DartSourceSplit split = splitDartSource(source);
  final String code = split.code;
  final List<int> newlines = _newlineOffsets(source);

  final List<EdenFieldSite> sites = <EdenFieldSite>[];
  for (final String name in kFieldConstructors) {
    final String needle = '$name(';
    int from = 0;
    while (true) {
      final int index = code.indexOf(needle, from);
      if (index < 0) {
        break;
      }
      from = index + 1;
      // A call to a custom widget whose name merely ENDS in one of these is
      // not a field; the real field lives inside that widget and is counted
      // there.
      if (index > 0 && _isIdentifierUnit(code.codeUnitAt(index - 1))) {
        continue;
      }
      final int open = index + name.length;
      final int close = _matchingParen(code, open);
      sites.add(EdenFieldSite(
        constructorName: name,
        line: _lineFor(newlines, index),
        arguments: close > open
            ? code.substring(open + 1, close)
            : code.substring(open + 1),
      ));
    }
  }
  sites.sort((EdenFieldSite a, EdenFieldSite b) => a.line.compareTo(b.line));

  int reasoned = 0;
  int bare = 0;
  for (final String line in const LineSplitter().convert(split.comments)) {
    if (!kExemptionPattern.hasMatch(line)) {
      continue;
    }
    final RegExpMatch? match = kReasonedExemptionPattern.firstMatch(line);
    final String reason = (match?.group(1) ?? '').trim();
    if (reason.length >= kMinimumExemptionReasonLength) {
      reasoned++;
    } else {
      bare++;
    }
  }

  return EdenFieldFileCensus(
    path: path,
    fieldSites: sites,
    purposeReferences: kPurposeReferencePattern.allMatches(code).length,
    purposeMarkers: kPurposeMarkerPattern.allMatches(split.comments).length,
    reasonedExemptions: reasoned,
    bareExemptions: bare,
  );
}

// ---------------------------------------------------------------------------
// Part 3 — reading the tree
// ---------------------------------------------------------------------------

/// The directory this guard polices. `src/`, `pages/` AND `dev_app/` are all in
/// scope: the showcase is exactly where a deprecated API gets demonstrated.
const String kScannedDirectory = 'lib';

/// Every `.dart` file under [directoryPath], sorted.
///
/// Fails LOUDLY with the resolved path when the directory is missing or empty,
/// rather than reporting success over nothing.
List<File> dartFilesUnder(String directoryPath) {
  final Directory dir = Directory(directoryPath);
  if (!dir.existsSync()) {
    fail(
      'Cannot scan "$directoryPath": it does not exist. Resolved against '
      '${Directory.current.absolute.path}. The guard must never silently scan '
      'an empty set.',
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
      'Scanned "$directoryPath" and found ZERO .dart files. Resolved against '
      '${Directory.current.absolute.path}. Refusing to pass vacuously.',
    );
  }
  return files;
}

/// Reads [file] as strict UTF-8, throwing a [FormatException] naming the path.
///
/// Deliberately NOT a `grep` subprocess. A raw NUL byte once made `grep` return
/// nothing for every pattern — silently, exit 1 — which is indistinguishable
/// from "no matches" and switched a whole file's scan off (Appendix B4). A NUL
/// is valid UTF-8, so decoding in Dart is immune to that; only genuinely
/// malformed bytes are an error, and they are an error rather than a skip.
String readDartSourceStrict(File file) {
  final List<int> bytes = file.readAsBytesSync();
  try {
    return utf8.decode(bytes, allowMalformed: false);
  } on FormatException catch (e) {
    throw FormatException(
      '${file.path} is not valid UTF-8 text (${e.message}). Fix the file '
      'rather than exempting it — a guard that skips a file it cannot read is '
      'a guard that is switched off for that file.',
    );
  }
}

/// A census of every file under [directoryPath].
List<EdenFieldFileCensus> censusOf(String directoryPath) {
  return <EdenFieldFileCensus>[
    for (final File file in dartFilesUnder(directoryPath))
      analyzeDartSource(readDartSourceStrict(file), path: file.path),
  ];
}

/// The failure text shown when a file declares more fields than purposes.
String describeViolation(EdenFieldFileCensus census) {
  final String sites = census.fieldSites
      .map((EdenFieldSite s) =>
          '  ${census.path}:${s.line}  ${s.constructorName}(')
      .join('\n');
  return '${census.path} declares ${census.fieldCount} field(s) but only '
      '${census.declaredCoverage} EdenFieldPurpose declaration(s).\n'
      '\n'
      'Sites:\n'
      '$sites\n'
      '\n'
      'Every TextField / TextFormField / EdenInput needs an explicit purpose:\n'
      '  - EdenInput(purpose: EdenFieldPurpose.email)\n'
      '  - TextField(autofillHints: p.semantics.autofillHints, '
      'keyboardType: p.semantics.keyboardType, ...)\n'
      '  - // eden-field-purpose: EdenFieldPurpose.none '
      '<why this field has no autofill purpose>\n'
      '  - // eden-field-purpose: exempt <why the rule does not apply here>\n'
      '\n'
      'A raw TextField satisfies this guard only when it passes keyboardType: '
      'sourced from the SAME purpose as its autofillHints: — hints alone leave '
      'the field mis-keyboarded (material/text_field.dart:355).\n'
      '\n'
      'Without a purpose the field emits autocomplete="on" with no name and no '
      'id (text_editing.dart:514-531) and no password manager can classify it.\n'
      'See .planning/objectives/40-ui-autofill-copypaste/40-RESEARCH.md '
      'section 2.';
}

// ---------------------------------------------------------------------------
// Measured baseline (2026-09-16, after sweeps 40-09 .. 40-16).
//
// Bounds, not equalities: adding an unrelated widget file must not fail the
// build. They sit just under the measured values, so a scan that finds
// materially less than the real tree fails loudly instead of passing.
// ---------------------------------------------------------------------------

/// Measured: 513 `.dart` files under `lib/`.
const int kMinimumDartFilesScanned = 480;

/// Measured: 87 files containing at least one of the three constructors.
const int kMinimumFilesWithFields = 80;

/// Measured: 202 sites (96 TextField + 40 TextFormField + 66 EdenInput).
const int kMinimumTotalFields = 190;

/// Measured: 119 `eden-field-purpose:` marker comments across `lib/`.
const int kMinimumPurposeMarkers = 100;

/// The externally verified ground truth, and the sharpest anti-vacuity pin in
/// this file.
///
/// 40-RESEARCH.md Appendix B8 re-counted `lib/` with comment awareness after
/// the original `grep` census over-reported 137 across 70 files: the real
/// figure is **136 raw `TextField` / `TextFormField` instantiations across 69
/// files**, with `eden_scheduler.dart` a comment-only phantom.
///
/// This scanner reproduces those two numbers EXACTLY and independently. Pinning
/// them means the stripper cannot regress in either direction without failing:
/// counting comments pushes the count above the truth in a way that no longer
/// matches, and blanking real code pushes it below the bound. `EdenInput` is
/// excluded here only because the published census did not include it.
const int kCensusRawFieldSites = 136;
const int kCensusRawFieldFiles = 69;

/// The comment-only file. Appendix B8: its single `TextField(` match is prose
/// in a dartdoc and it contains no text input at all.
const String kPhantomFileSuffix = 'eden_scheduler.dart';

/// A file that certainly DOES contain a real field — the mirror of the phantom.
const String kKnownFieldFileSuffix = 'eden_input.dart';

void main() {
  setUpAll(() {
    // Anchor the walk. If the harness ever runs from another cwd this fails
    // with the resolved path instead of scanning nothing and passing.
    expect(
      File('lib/eden_ui.dart').existsSync(),
      isTrue,
      reason: 'expected to run from the package root; cwd is '
          '${Directory.current.absolute.path}',
    );
  });

  // -------------------------------------------------------------------------
  group('TRD 40-17 — the counting rule (pure, over hand-written fixtures)', () {
    test('an unpurposed TextField is reported as a violation', () {
      final EdenFieldFileCensus c = analyzeDartSource('''
class Bad extends StatelessWidget {
  Widget build(BuildContext context) {
    return TextField(controller: _controller);
  }
}
''', path: 'fixture/bad.dart');
      expect(c.fieldCount, 1);
      expect(c.declaredCoverage, 0);
      expect(c.isCovered, isFalse);
      expect(describeViolation(c), contains('fixture/bad.dart:3'));
    });

    test('a purposed EdenInput satisfies the rule', () {
      final EdenFieldFileCensus c = analyzeDartSource('''
Widget build(BuildContext context) {
  return EdenInput(label: 'Email', purpose: EdenFieldPurpose.email);
}
''', path: 'fixture/good.dart');
      expect(c.fieldCount, 1);
      expect(c.purposeReferences, 1);
      expect(c.isCovered, isTrue);
    });

    test('a marker comment alone satisfies the rule', () {
      final EdenFieldFileCensus c = analyzeDartSource('''
Widget build(BuildContext context) {
  // eden-field-purpose: EdenFieldPurpose.none — one row of a repeater; N rows
  // sharing one hint would emit N duplicate DOM ids.
  return TextFormField(controller: c, keyboardType: TextInputType.text);
}
''', path: 'fixture/marker.dart');
      expect(c.fieldCount, 1);
      expect(c.purposeReferences, 0,
          reason: 'the only purpose is in a comment, which the code view drops');
      expect(c.purposeMarkers, 1);
      expect(c.isCovered, isTrue);
    });

    test('an exemption requires a written reason', () {
      const String bare = '''
// eden-field-purpose: exempt
Widget build(BuildContext context) => TextField(controller: c);
''';
      final EdenFieldFileCensus bareCensus =
          analyzeDartSource(bare, path: 'fixture/bare.dart');
      expect(bareCensus.bareExemptions, 1);
      expect(bareCensus.reasonedExemptions, 0);
      expect(bareCensus.isCovered, isFalse,
          reason: 'an exemption with no reason is an omission with extra steps');

      const String reasoned = '''
// eden-field-purpose: exempt — this widget is a pure layout probe with no real
// input; it exists only to measure intrinsic height.
Widget build(BuildContext context) => TextField(controller: c);
''';
      final EdenFieldFileCensus reasonedCensus =
          analyzeDartSource(reasoned, path: 'fixture/reasoned.dart');
      expect(reasonedCensus.reasonedExemptions, 1);
      expect(reasonedCensus.bareExemptions, 0);
      expect(reasonedCensus.isCovered, isTrue);
    });

    test('a too-short reason does not buy an exemption', () {
      final EdenFieldFileCensus c = analyzeDartSource('''
// eden-field-purpose: exempt — nope
Widget build(BuildContext context) => TextField(controller: c);
''', path: 'fixture/short.dart');
      expect(c.reasonedExemptions, 0);
      expect(c.bareExemptions, 1);
      expect(c.isCovered, isFalse);
    });

    test('a TextField inside a comment is not counted (the phantom case)', () {
      final EdenFieldFileCensus c = analyzeDartSource('''
/// Mirrors the Flutter `TextField(controller: ...)` lifetime-aware pattern.
//  See also TextFormField(...) and EdenInput(...).
/* Block prose about TextField( too. */
class NoInputHere {}
''', path: 'fixture/phantom.dart');
      expect(c.fieldCount, 0,
          reason: 'demanding a purpose here would force a lie into the source');
    });

    test('nested block comments are stripped whole', () {
      final EdenFieldFileCensus c = analyzeDartSource('''
/* outer /* inner TextField( */ still comment TextField( */
Widget build(BuildContext context) => EdenInput(purpose: EdenFieldPurpose.none);
''', path: 'fixture/nested.dart');
      expect(c.fieldCount, 1);
      expect(c.isCovered, isTrue);
    });

    test('a doubled slash inside a string literal does not start a comment', () {
      final EdenFieldFileCensus c = analyzeDartSource('''
const String docs = 'https://example.test/guide';
Widget build(BuildContext context) => EdenInput(purpose: EdenFieldPurpose.url);
''', path: 'fixture/url.dart');
      expect(c.fieldCount, 1,
          reason: 'a naive comment strip would truncate the line and hide the '
              'field that follows it');
      expect(c.purposeReferences, 1);
      expect(c.isCovered, isTrue);
    });

    test('a marker comment inside a string literal does not count', () {
      final EdenFieldFileCensus c = analyzeDartSource('''
const String help = 'eden-field-purpose: EdenFieldPurpose.none — why';
Widget build(BuildContext context) => TextField(controller: c);
''', path: 'fixture/string-marker.dart');
      expect(c.purposeMarkers, 0,
          reason: 'markers are read from the comment view, never from strings');
      expect(c.purposeReferences, 0,
          reason: 'string contents are blanked in the code view too');
      expect(c.isCovered, isFalse);
    });

    test('a field constructor named inside a string literal is not counted', () {
      final EdenFieldFileCensus c = analyzeDartSource('''
const String message = 'pass a purpose to TextField( at every call site';
class NoInputHere {}
''', path: 'fixture/string-field.dart');
      expect(c.fieldCount, 0);
    });

    test('raw and triple-quoted strings do not desync the scanner', () {
      final EdenFieldFileCensus c = analyzeDartSource("""
final RegExp p = RegExp(r'^\\d{0,3}');
const String prose = '''
  it is fine to have ' and " and a doubled slash // in here
''';
Widget build(BuildContext c) => EdenInput(purpose: EdenFieldPurpose.quantity);
""", path: 'fixture/strings.dart');
      expect(c.fieldCount, 1);
      expect(c.purposeReferences, 1);
      expect(c.isCovered, isTrue);
    });

    test('string interpolation keeps its expression as code', () {
      final EdenFieldFileCensus c = analyzeDartSource(r"""
String label(Map<String, String> m) => 'k ${m['key']} and more text';
Widget build(BuildContext c) => TextField(controller: c);
""", path: 'fixture/interp.dart');
      expect(c.fieldCount, 1,
          reason: 'a nested quote inside an interpolation must not swallow the '
              'line that follows it');
      expect(c.isCovered, isFalse);
    });

    test('a NUL byte does not blind the scan', () {
      // Appendix B4: this exact byte made `grep` return nothing for every
      // pattern, silently. It is valid UTF-8, so a Dart reader is immune.
      final EdenFieldFileCensus c = analyzeDartSource(
        'const String joined = \'a\u0000b\';\n'
        'Widget build(BuildContext c) => TextField(controller: c);\n',
        path: 'fixture/nul.dart',
      );
      expect(c.fieldCount, 1);
      expect(c.isCovered, isFalse);
    });

    test('an identifier merely ending in TextField is not counted', () {
      final EdenFieldFileCensus c = analyzeDartSource('''
Widget build(BuildContext c) => _EdenPasswordTextField(controller: c);
''', path: 'fixture/custom.dart');
      expect(c.fieldCount, 0,
          reason: 'the real field lives in that widget, and is counted there');
    });

    test('hints without a keyboardType is a violation even with a purpose', () {
      final EdenFieldFileCensus c = analyzeDartSource('''
const p = EdenFieldPurpose.email;
Widget build(BuildContext c) => TextField(
      controller: c,
      autofillHints: p.semantics.autofillHints,
    );
''', path: 'fixture/hint-only.dart');
      expect(c.isCovered, isTrue,
          reason: 'the counting rule alone is satisfied, which is exactly why '
              'the pairing check has to exist as well');
      expect(c.hintOnlySites, hasLength(1),
          reason: 'TextField pre-resolves keyboardType (text_field.dart:355), '
              'so hints alone leave the field mis-keyboarded on iOS');
    });

    test('hints WITH a keyboardType is not a violation', () {
      final EdenFieldFileCensus c = analyzeDartSource('''
const p = EdenFieldPurpose.email;
Widget build(BuildContext c) => TextField(
      controller: c,
      autofillHints: p.semantics.autofillHints,
      keyboardType: p.semantics.keyboardType,
    );
''', path: 'fixture/paired.dart');
      expect(c.hintOnlySites, isEmpty);
    });

    test('a nested widget does not steal the outer field arguments', () {
      // Balanced-paren extraction, not "to the end of the line".
      final EdenFieldFileCensus c = analyzeDartSource('''
Widget build(BuildContext c) => Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: c,
        decoration: const InputDecoration(hintText: 'x'),
      ),
    );
''', path: 'fixture/nested-args.dart');
      expect(c.fieldCount, 1);
      expect(c.fieldSites.single.arguments, contains('decoration'));
      expect(c.fieldSites.single.arguments, isNot(contains('padding')));
    });

    test('a missing directory fails loudly rather than scanning nothing', () {
      expect(
        () => dartFilesUnder('lib/this-directory-does-not-exist'),
        throwsA(isA<TestFailure>()),
      );
    });

    test('malformed UTF-8 fails loudly rather than being skipped', () {
      final Directory tmp =
          Directory.systemTemp.createTempSync('eden_field_guard_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      // 0xC3 starts a two-byte sequence; 0x28 is not a valid continuation.
      final File broken = File('${tmp.path}/broken.dart')
        ..writeAsBytesSync(<int>[0xC3, 0x28]);
      expect(() => readDartSourceStrict(broken), throwsFormatException);

      // ...while a NUL, which IS valid UTF-8, reads back intact.
      final File withNul = File('${tmp.path}/nul.dart')
        ..writeAsBytesSync(<int>[0x61, 0x00, 0x62]);
      expect(readDartSourceStrict(withNul), 'a\u0000b');
    });
  });

  // -------------------------------------------------------------------------
  group('TRD 40-17 — the guard, against the real lib/ tree', () {
    late List<EdenFieldFileCensus> census;

    setUpAll(() {
      census = censusOf(kScannedDirectory);
    });

    test('the walk found the real lib/ tree, not an empty set', () {
      final List<EdenFieldFileCensus> withFields =
          census.where((EdenFieldFileCensus c) => c.fieldCount > 0).toList();
      final int totalFields = census.fold<int>(
        0,
        (int sum, EdenFieldFileCensus c) => sum + c.fieldCount,
      );
      final int totalDeclarations = census.fold<int>(
        0,
        (int sum, EdenFieldFileCensus c) => sum + c.declaredCoverage,
      );
      final int totalMarkers = census.fold<int>(
        0,
        (int sum, EdenFieldFileCensus c) => sum + c.purposeMarkers,
      );

      // ignore: avoid_print
      print('CENSUS files=${census.length} withFields=${withFields.length} '
          'fields=$totalFields declarations=$totalDeclarations '
          'markers=$totalMarkers');

      expect(census.length, greaterThanOrEqualTo(kMinimumDartFilesScanned),
          reason: 'the walk must actually find lib/');
      expect(withFields.length, greaterThanOrEqualTo(kMinimumFilesWithFields),
          reason: 'the comment-aware census measured 69 files with fields; a '
              'scan finding far fewer is not scanning');
      expect(totalFields, greaterThanOrEqualTo(kMinimumTotalFields),
          reason: 'the comment-aware census measured 136 real instantiations');
      expect(totalDeclarations, greaterThanOrEqualTo(totalFields),
          reason: 'every field is covered, so declarations track fields');
      expect(totalMarkers, greaterThanOrEqualTo(kMinimumPurposeMarkers),
          reason: 'the sweeps left marker comments across lib/; near-zero here '
              'would mean the comment view is empty and the none-mechanism is '
              'untested');

      // The ground-truth pin. Counted over the same two constructors the
      // published census used, so the numbers are directly comparable.
      final List<EdenFieldFileCensus> rawFiles = census
          .where((EdenFieldFileCensus c) => c.fieldSites
              .any((EdenFieldSite s) => s.constructorName != 'EdenInput'))
          .toList();
      final int rawSites = census.fold<int>(
        0,
        (int sum, EdenFieldFileCensus c) =>
            sum +
            c.fieldSites
                .where((EdenFieldSite s) => s.constructorName != 'EdenInput')
                .length,
      );
      expect(rawSites, greaterThanOrEqualTo(kCensusRawFieldSites),
          reason: 'the comment-aware census (Appendix B8) measured exactly '
              '$kCensusRawFieldSites raw TextField/TextFormField sites. This '
              'scanner reproduced that number independently; finding fewer '
              'means the scan has gone blind somewhere.');
      expect(rawFiles.length, greaterThanOrEqualTo(kCensusRawFieldFiles),
          reason: 'the same census measured exactly $kCensusRawFieldFiles '
              'files carrying one');
    });

    test('the comment stripper is running in BOTH directions', () {
      final EdenFieldFileCensus phantom = census.firstWhere(
        (EdenFieldFileCensus c) => c.path.endsWith(kPhantomFileSuffix),
        orElse: () => fail('$kPhantomFileSuffix was not scanned at all'),
      );
      expect(phantom.fieldCount, 0,
          reason: '${phantom.path} contains the field token only inside a '
              'dartdoc and has no text input at all (Appendix B8). If this '
              'reports a field, comment stripping has stopped running, and the '
              'only way to satisfy the guard would be to add a meaningless '
              'marker comment to a file with nothing to mark.');

      final EdenFieldFileCensus known = census.firstWhere(
        (EdenFieldFileCensus c) => c.path.endsWith(kKnownFieldFileSuffix),
        orElse: () => fail('$kKnownFieldFileSuffix was not scanned at all'),
      );
      expect(known.fieldCount, greaterThan(0),
          reason: 'the mirror of the phantom: if this reports zero, the '
              'stripper is blanking everything and the whole guard is vacuous');
    });

    test('every lib/ file covers its fields with a purpose or an exemption', () {
      final List<EdenFieldFileCensus> violations =
          census.where((EdenFieldFileCensus c) => !c.isCovered).toList();
      expect(
        violations,
        isEmpty,
        reason: violations.map(describeViolation).join('\n\n'),
      );
    });

    test('no lib/ field passes autofillHints without a keyboardType', () {
      final List<String> offenders = <String>[
        for (final EdenFieldFileCensus c in census)
          for (final EdenFieldSite s in c.hintOnlySites)
            '${c.path}:${s.line}  ${s.constructorName}(',
      ];
      expect(
        offenders,
        isEmpty,
        reason: 'These fields carry autofillHints with no explicit '
            'keyboardType:\n  ${offenders.join('\n  ')}\n\n'
            'TextField resolves keyboardType in its own initializer list '
            '(material/text_field.dart:355), so Flutter never infers it from '
            'the hints. The field stays TextInputType.text while looking fixed '
            'in review, and AutofillHints.email works only with '
            'TextInputType.emailAddress (editable_text.dart:1855-1858). '
            'Source keyboardType from the SAME purpose as the hints.',
      );
    });

    test('no file carries a reasonless exemption', () {
      final List<String> bare = <String>[
        for (final EdenFieldFileCensus c in census)
          if (c.bareExemptions > 0) '${c.path} (${c.bareExemptions})',
      ];
      expect(bare, isEmpty,
          reason: 'an exemption with no written reason does not count and '
              'should not be left in the tree:\n  ${bare.join('\n  ')}');
    });
  });

  // -------------------------------------------------------------------------
  group('TRD 40-17 — purpose semantics the guard relies on', () {
    test('every obscured purpose emits a password-family BROWSER token', () {
      final List<EdenFieldPurpose> obscured = EdenFieldPurpose.values
          .where((EdenFieldPurpose p) => p.semantics.obscureText)
          .toList();
      expect(obscured, isNotEmpty,
          reason: 'anti-vacuity: the filter must select something, or the loop '
              'below asserts nothing at all');

      for (final EdenFieldPurpose p in obscured) {
        final List<String>? hints = p.semantics.autofillHints;
        // B6: assert EMPTINESS, never nullness.
        expect(hints != null && hints.isNotEmpty, isTrue,
            reason: '$p is obscured but carries no hint, so web renders it DOM '
                'type="text" (text_editing.dart:514-531)');
        expect(browserTokenFor(hints!.first).contains('password'), isTrue,
            reason: '$p resolves browser token '
                '"${browserTokenFor(hints.first)}", which does not classify as '
                'a password field');
      }
    });

    test('the browser-token mapping is load-bearing, not decorative', () {
      // Appendix B2: the raw camelCase constant does NOT contain lowercase
      // `password`. A guard checking the constant would flag every newPassword
      // field as a defect.
      expect(AutofillHints.newPassword.contains('password'), isFalse);
      expect(browserTokenFor(AutofillHints.newPassword), 'new-password');
      expect(browserTokenFor(AutofillHints.newPassword).contains('password'),
          isTrue);
    });

    test('hint-free purposes really carry no autofill identity', () {
      const List<EdenFieldPurpose> hintFree = <EdenFieldPurpose>[
        EdenFieldPurpose.none,
        EdenFieldPurpose.searchQuery,
        EdenFieldPurpose.multilineText,
        EdenFieldPurpose.quantity,
        EdenFieldPurpose.decimalAmount,
      ];
      for (final EdenFieldPurpose p in hintFree) {
        final List<String>? hints = p.semantics.autofillHints;
        // Both shapes are legitimate "no identity": a purpose spread resolves
        // null, a marker-comment-only field keeps TextField's const <String>[]
        // default. Accept both; never assert on nullness alone (B6).
        expect(hints == null || hints.isEmpty, isTrue,
            reason: '$p emits a hint, so it would emit an element.id and could '
                'collide when repeated inside one autofill scope (B9)');
      }
    });
  });
}
