// The list of checks `expectUiSane` actually has, DERIVED FROM ITS SOURCE.
//
// WHY THIS IS NOT A HAND-MAINTAINED LIST. A hand-maintained inventory is the
// drift shape this programme has been bitten by repeatedly — most recently a
// pattern catalogue that claimed 78 rules and carried 2. A list that is typed
// out beside the thing it describes is correct exactly once, on the day it is
// written, and nothing makes it go red when the thing changes. The coverage
// table this feeds exists to answer "what does the oracle catch?", and an
// answer derived from a list someone maintained by hand answers "what did
// somebody once believe the oracle caught".
//
// So the inventory is read off `lib/testing/expect_ui_sane.dart` itself: the
// check functions `expectUiSane` aggregates, transitively, and every site in
// them that puts a MESSAGE into the report. Adding a check, deleting one, or
// rewording one changes this list on the next run, and the catalogue test
// fails until a fixture is declared against the new shape.
//
// WHAT COUNTS AS A SITE:
//
//   * any `<accumulator>.add(<string literal>)` in a reachable function —
//     included whatever its length, because a message can be entirely
//     interpolation (`'${guideline.description}: ${failure.message}'`); and
//   * any `return <string literal>` or `=> <string literal>` in a reachable
//     function whose message is at least [_minimumReturnedMessage] characters
//     after normalisation.
//
// Single AND double quoted, because the quote a message happens to be written
// in is not a fact about whether it is a check.
//
// THE PARSER IS BIDIRECTIONAL, and that is the part that makes the catalogue
// mean anything. Read one way it reports every site it recognises, and the
// catalogue fails on a site no row accounts for. That direction alone is
// worth very little: a site the parser does not RECOGNISE produces no row to
// be missing, so a new check written in a shape the regexes do not match adds
// nothing to the inventory and the catalogue passes — silently, with a check
// nothing exercises. The parser was in exactly that state: single quotes
// only, and only directly after `.add(` or `return`.
//
// So it is read the other way too. Every message-shaped string LITERAL inside
// a reachable function that no recognised site claims is reported in
// [OracleCheckInventory.unattributedLiterals], and the catalogue pins that
// list empty.
//
// THAT WAS NOT ENOUGH ON ITS OWN, and the gap is worth stating because the
// paragraph above used to claim it was closed. "Message-shaped" needs a
// floor, or every path fragment and format string is noise; the floor was 16
// characters after normalisation. A message that is PURE INTERPOLATION is
// under it — `'${a}: ${b}'` normalises to `*: *` — so a check written
//
//     final String m = '${node.identifier}: ${r.width}';
//     out.add(m);
//
// produced no site, no unattributed literal and no rejected fragment.
// Measured on the real oracle: the catalogue passed clean. That shape is one
// refactor away from existing — `_guidelineViolations` emits exactly such a
// string inline today.
//
// So a literal assigned to a LOCAL is tracked, and the local is promoted to a
// real SITE when it is what gets added or returned. Length never enters into
// it, because the site path has no floor. A check written that way now
// reaches the inventory with its message and the catalogue demands a row for
// it like any other.
//
// The same treatment closes the length floor on RETURNS. The floor exists
// because a reachable helper can return a PHRASE that is substituted into
// someone else's message — `_announcedAffordance` returns 'a button' — and
// those are not checks. Every returned literal the floor REJECTS is reported
// in [OracleCheckInventory.rejectedFragments], and the catalogue pins that
// list by name.
library;

import 'dart:io';

/// Returned literals shorter than this are treated as message FRAGMENTS
/// rather than violations. See the library comment.
const int _minimumReturnedMessage = 16;

/// One site in `expect_ui_sane.dart` that can put a message into the report.
class OracleCheckSite {
  const OracleCheckSite({
    required this.id,
    required this.function,
    required this.message,
    required this.viaAdd,
  });

  /// `<function>#<slug>`, the key the catalogue joins on.
  ///
  /// Derived from the first six words of the message, so rewording the TAIL
  /// of a violation keeps the row attached while rewording its opening —
  /// which is what a reader recognises a check by — deliberately breaks it.
  final String id;

  /// The function the site is in.
  final String function;

  /// The message literal, with every interpolation replaced by `*` and
  /// whitespace collapsed.
  final String message;

  /// True for an `.add(...)` site, false for a `return` site.
  final bool viaAdd;

  @override
  String toString() => '$id :: $message';
}

/// Everything [readOracleCheckInventory] found.
class OracleCheckInventory {
  const OracleCheckInventory({
    required this.sites,
    required this.rejectedFragments,
    required this.reachedFunctions,
    required this.unattributedLiterals,
  });

  /// Every message-producing site, ordered by id.
  final List<OracleCheckSite> sites;

  /// Returned literals rejected by the length floor, ordered. Pinned by the
  /// catalogue so a new short violation message cannot arrive unnoticed.
  final List<String> rejectedFragments;

  /// The functions reached transitively from `expectUiSane`'s aggregation.
  final List<String> reachedFunctions;

  /// `<function>: <literal>` for every message-shaped string literal inside a
  /// reachable function that NO recognised site claims, ordered.
  ///
  /// THE OTHER DIRECTION. Orphan sites (a site with no catalogue row) only
  /// catch a check the parser managed to SEE. These catch the check it did
  /// not: a message built into a local, an opener shape the regex does not
  /// match, a quote style nobody anticipated. The catalogue pins this empty,
  /// so an unrecognised message site fails loudly rather than quietly adding
  /// nothing to the inventory.
  final List<String> unattributedLiterals;

  /// The site carrying [id], or null.
  OracleCheckSite? operator [](String id) {
    for (final OracleCheckSite site in sites) {
      if (site.id == id) {
        return site;
      }
    }
    return null;
  }
}

/// Reads the oracle's source and returns every check it can report.
///
/// [path] is resolved against the process's working directory, which
/// `flutter test` sets to the package root — the same convention
/// `test/tool/eden_field_purpose_guard_test.dart` already relies on. A
/// missing file throws with the resolved absolute path in the message rather
/// than returning an empty inventory: an inventory that silently comes back
/// empty would make every coverage assertion below pass on nothing.
OracleCheckInventory readOracleCheckInventory({
  String path = 'lib/testing/expect_ui_sane.dart',
}) {
  final File file = File(path);
  if (!file.existsSync()) {
    throw StateError(
      'OracleCheckInventory: cannot read the oracle at "$path" (resolved to '
      '"${file.absolute.path}"). Run this test from the package root.',
    );
  }
  return parseOracleCheckInventory(file.readAsStringSync());
}

/// [readOracleCheckInventory]'s parser, exposed so it can be exercised on a
/// synthetic source string instead of only on the real oracle.
OracleCheckInventory parseOracleCheckInventory(String source) {
  final List<String> raw = source.split('\n');
  // Comment-only lines are blanked, not deleted, so line indices still line
  // up with the file. A doc comment sits BETWEEN two declarations and would
  // otherwise donate its code samples' string literals to the function above.
  final List<String> lines = <String>[
    for (final String line in raw)
      if (line.trimLeft().startsWith('//')) '' else line,
  ];

  final RegExp declaration = RegExp(
    r'^[A-Za-z_][A-Za-z0-9_<>,?\s\.]*\s(_?[A-Za-z][A-Za-z0-9_]*)\s*\(',
  );
  final List<(int, String)> starts = <(int, String)>[];
  for (int i = 0; i < raw.length; i++) {
    final String line = raw[i];
    if (line.isEmpty || line.startsWith(' ') || line.startsWith('//')) {
      continue;
    }
    final RegExpMatch? match = declaration.firstMatch(line);
    if (match != null) {
      starts.add((i, match.group(1)!));
    }
  }

  final Map<String, List<String>> bodies = <String, List<String>>{};
  for (int i = 0; i < starts.length; i++) {
    final int from = starts[i].$1;
    final int to = i + 1 < starts.length ? starts[i + 1].$1 : lines.length;
    bodies[starts[i].$2] = lines.sublist(from, to);
  }

  final List<String>? entry = bodies['expectUiSane'];
  if (entry == null) {
    throw StateError(
      'OracleCheckInventory: no top-level expectUiSane() found. The parser '
      'anchors on it; if the oracle was renamed, this file has to follow.',
    );
  }

  // SEED: `expectUiSane` ITSELF, plus everything it calls.
  //
  // THREE HOLES THIS CLOSED, all of them the same shape — a check the parser
  // could not see produces no row, so no orphan, so a clean run:
  //
  //   1. The seed used to be `violations.add(_f(` only, so `expectUiSane`'s
  //      OWN BODY was in no function's scan. A check written inline there —
  //      `if (bad) violations.add('...')` — was invisible to BOTH directions
  //      of this parser. It is now scanned like any other function.
  //   2. That same regex missed `final x = await _f(t); violations.addAll(x);`
  //      — an aggregation through a local. The seed is now every call in
  //      `expectUiSane`'s body that resolves to a function declared in this
  //      file, which subsumes the shape whatever the plumbing.
  //   3. Both the seed and the walk required a LEADING UNDERSCORE, so a
  //      public helper was never traversed. The `bodies.containsKey` guard is
  //      what keeps this honest — only top-level declarations in this file
  //      are followed — so the underscore was never load-bearing.
  //
  // Over-counting is the SAFE direction here: a function reached that emits
  // no message contributes nothing, while one not reached hides whatever it
  // emits.
  final RegExp anyCall = RegExp(r'\b([A-Za-z_][A-Za-z0-9_]*)\s*\(');
  final Set<String> reached = <String>{'expectUiSane'};
  for (final RegExpMatch call in anyCall.allMatches(entry.join('\n'))) {
    final String callee = call.group(1)!;
    if (bodies.containsKey(callee)) {
      reached.add(callee);
    }
  }
  // THE TRIPWIRE, ASSERTED ON THE AGGREGATION AND NOT ON `reached.length`.
  // Under the widened seed ANY file-local call satisfies a length test —
  // `identifiedNodes`, `rootSemanticsNodeOf` — so `reached.length < 2` stayed
  // quiet even if every `violations.addAll(...)` line moved to another file,
  // which is the one thing it was written to catch. Count the aggregation
  // itself instead.
  //
  // The floor is ONE, not a number chosen to fit the real oracle: this
  // parser is also run against small synthetic sources by its own tests, and
  // a floor tuned to the real file would have made those unrepresentable.
  // "How many checks should be here" is the catalogue's job, and it holds
  // the real file to >= 12 sites.
  final int aggregations =
      RegExp(r'violations\.add(?:All)?\(').allMatches(entry.join('\n')).length;
  if (aggregations == 0) {
    throw StateError(
      'OracleCheckInventory: expectUiSane aggregates nothing — no '
      'violations.add/addAll call in its body. Either the aggregation moved '
      'out of this function or the parser stopped matching it, and either '
      'way every coverage assertion downstream would be passing on an '
      'inventory built from almost nothing.',
    );
  }

  final List<String> queue = reached.toList();
  while (queue.isNotEmpty) {
    final String next = queue.removeLast();
    final List<String>? body = bodies[next];
    if (body == null) {
      continue;
    }
    for (final RegExpMatch call in anyCall.allMatches(body.join('\n'))) {
      final String callee = call.group(1)!;
      if (bodies.containsKey(callee) && reached.add(callee)) {
        queue.add(callee);
      }
    }
  }

  final List<OracleCheckSite> sites = <OracleCheckSite>[];
  final List<String> rejected = <String>[];
  final List<String> unattributed = <String>[];
  final List<String> functions = reached.toList()..sort();

  for (final String function in functions) {
    final List<String> body = bodies[function]!;
    final List<String> slugs = <String>[];
    // Lines a recognised site has already accounted for. The reverse scan
    // below reports every message-shaped literal that is NOT on one of them.
    final Set<int> claimed = <int>{};
    int ordinal = -1;
    // PASS 1 — STRING LOCALS. A message assembled into a local sits behind no
    // opener at all, so pass 2 cannot see it, and when the message is pure
    // interpolation the reverse scan cannot either: `'${a}: ${b}'` normalises
    // to `*: *`, five characters, below the message-shaped floor. Measured on
    // the real oracle: a brand-new check written
    //
    //     final String m = '${node.identifier}: ${r.width}';
    //     out.add(m);
    //
    // produced zero sites, zero unattributed literals and zero rejected
    // fragments — the catalogue passed clean on a check nothing exercises.
    // The shape is one refactor away in the code today: `_guidelineViolations`
    // emits exactly that string inline.
    //
    // So a literal assigned to a local is remembered here, and pass 2
    // promotes it to a REAL SITE when the local is what gets added or
    // returned. That is strictly better than reporting it as unattributed:
    // the check ends up in the inventory with its message, and the catalogue
    // demands a row for it like any other.
    final Map<String, (String, int, int)> localLiterals =
        <String, (String, int, int)>{};
    for (int i = 0; i < body.length; i++) {
      final RegExpMatch? assign = _localAssignment.firstMatch(body[i]);
      if (assign == null) {
        continue;
      }
      final (String raw, int last) = _gatherLiteral(body, i);
      localLiterals[assign.group(1)!] = (_normalise(raw), i, last);
    }
    for (int i = 0; i < body.length; i++) {
      final RegExpMatch? opener = _opener.firstMatch(body[i]);
      if (opener == null) {
        continue;
      }
      int at = i;
      String rest = body[i].substring(opener.end).trim();
      if (rest.isEmpty) {
        at = i + 1;
        while (at < body.length && body[at].trim().isEmpty) {
          at++;
        }
        rest = at < body.length ? body[at].trim() : '';
      }
      if (!_startsLiteral(rest)) {
        // The opener may be handing over a LOCAL that holds the message.
        final RegExpMatch? ident = _bareIdentifier.firstMatch(rest);
        final (String, int, int)? local =
            ident == null ? null : localLiterals[ident.group(1)!];
        if (local == null) {
          continue;
        }
        ordinal++;
        final String message = local.$1;
        claimed.add(i);
        for (int line = local.$2; line <= local.$3; line++) {
          claimed.add(line);
        }
        final bool viaAdd = opener.group(1) == '.add(';
        if (!viaAdd && message.length < _minimumReturnedMessage) {
          rejected.add(message);
          continue;
        }
        sites.add(
          OracleCheckSite(
            id: '$function#${_slugFor(message, slugs, ordinal)}',
            function: function,
            message: message,
            viaAdd: viaAdd,
          ),
        );
        continue;
      }
      ordinal++;
      final (String raw, int last) = _gatherLiteral(body, at);
      final String message = _normalise(raw);
      for (int line = i; line <= last; line++) {
        claimed.add(line);
      }
      final bool viaAdd = opener.group(1) == '.add(';
      if (!viaAdd && message.length < _minimumReturnedMessage) {
        rejected.add(message);
        continue;
      }
      sites.add(
        OracleCheckSite(
          id: '$function#${_slugFor(message, slugs, ordinal)}',
          function: function,
          message: message,
          viaAdd: viaAdd,
        ),
      );
    }

    // THE REVERSE SCAN — the direction the orphan check cannot see. Anything
    // message-shaped on a line no site claimed.
    for (int i = 0; i < body.length; i++) {
      if (claimed.contains(i)) {
        continue;
      }
      for (final String literal in _messageShapedLiterals(body[i])) {
        unattributed.add('$function: $literal');
      }
    }
  }

  sites.sort((OracleCheckSite a, OracleCheckSite b) => a.id.compareTo(b.id));
  rejected.sort();
  unattributed.sort();
  return OracleCheckInventory(
    sites: sites,
    rejectedFragments: rejected,
    reachedFunctions: functions,
    unattributedLiterals: unattributed,
  );
}

/// The three openers a message can sit behind. `=>` is here because an arrow
/// body is a return written shorter, and a check written as one produced no
/// inventory row at all.
final RegExp _opener = RegExp(r'(\.add\(|\breturn\b|=>)');

/// One string literal, either quote style. Dart does not care which a message
/// is written in and neither may this: recognising only `'` meant a
/// double-quoted message added no row and the catalogue passed with a check
/// it could not see.
final RegExp _anyLiteral =
    RegExp(r"'((?:[^'\\]|\\.)*)'" r'|"((?:[^"\\]|\\.)*)"');

/// A local assigned a string literal: `final String m = '...'`, `var m = "..."`,
/// or a bare reassignment. The capture is the local's NAME.
final RegExp _localAssignment = RegExp(
  r'''^\s*(?:final\s+|const\s+|var\s+)?(?:String\??\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*['"]''',
);

/// What follows an opener when it is handing over a bare local rather than a
/// literal: `out.add(m);`, `return m;`.
final RegExp _bareIdentifier =
    RegExp(r'^([A-Za-z_][A-Za-z0-9_]*)\s*[);,]');

/// The slug for [message], kept unique within one function.
///
/// Shared by both site paths — a literal behind an opener and a local
/// promoted to a site — so the two cannot drift into different id schemes.
String _slugFor(String message, List<String> slugs, int ordinal) {
  String slug = _slug(message);
  if (slug.isEmpty) {
    slug = 'site-$ordinal';
  }
  if (slugs.contains(slug)) {
    slug = '$slug-$ordinal';
  }
  slugs.add(slug);
  return slug;
}

/// Whether [rest] — what follows an opener — begins a string literal.
bool _startsLiteral(String rest) =>
    rest.startsWith("'") || rest.startsWith('"');

/// A single-quoted literal that is NOT a raw string, and the same for double
/// quotes. The lookbehind is what excludes `r'...'`: a raw string in this
/// file's scope is a regex or a path, never a violation message, and
/// `_describeOverflow`'s `RegExp(r'A (\w+) overflowed by ...')` would
/// otherwise be reported as an unattributed message for ever.
final List<RegExp> _nonRawLiterals = <RegExp>[
  RegExp(r"(?<![A-Za-z0-9_$'])'((?:[^'\\]|\\.)*)'"),
  RegExp(r'(?<![A-Za-z0-9_$"])"((?:[^"\\]|\\.)*)"'),
];

/// Every string literal on [line] that looks like a MESSAGE rather than like
/// punctuation, a key, or a format fragment.
///
/// "Message-shaped" is: at least [_minimumReturnedMessage] characters after
/// normalisation, and containing a space. Deliberately generous — a false
/// positive costs somebody one line in the catalogue's pin and a moment
/// deciding what it is; a false NEGATIVE is a check nothing exercises,
/// reported as a clean run.
List<String> _messageShapedLiterals(String line) {
  final List<String> out = <String>[];
  for (final RegExp pattern in _nonRawLiterals) {
    for (final RegExpMatch match in pattern.allMatches(line)) {
      final String normalised = _normalise(match.group(1)!);
      if (normalised.length >= _minimumReturnedMessage &&
          normalised.contains(' ')) {
        out.add(normalised);
      }
    }
  }
  return out;
}

/// Joins the adjacent string literals that make up one Dart expression,
/// starting at [index], and returns them with the index of the LAST line it
/// consumed.
///
/// The line index is what lets the reverse scan tell a literal that belongs
/// to a recognised site from one nothing claimed.
///
/// Dart concatenates adjacent literals, and every message in the oracle is
/// written as one per source line, so a site's text is spread over up to a
/// dozen lines. Collection stops at the first line that does not end inside
/// the expression.
(String, int) _gatherLiteral(List<String> body, int index) {
  final StringBuffer out = StringBuffer();
  int last = index;
  for (int i = index; i < body.length; i++) {
    final String line = body[i].trim();
    final Iterable<RegExpMatch> matches = _anyLiteral.allMatches(line);
    if (matches.isEmpty) {
      break;
    }
    for (final RegExpMatch match in matches) {
      out.write(match.group(1) ?? match.group(2));
    }
    last = i;
    if (line.endsWith("'") ||
        line.endsWith("',") ||
        line.endsWith('"') ||
        line.endsWith('",')) {
      continue;
    }
    break;
  }
  return (out.toString(), last);
}

/// A literal with every interpolation replaced by `*` and whitespace
/// collapsed, so the message is comparable across reflows of the source.
String _normalise(String literal) {
  return literal
      .replaceAll(RegExp(r'\$\{[^}]*\}'), '*')
      .replaceAll(RegExp(r'\$[A-Za-z_][A-Za-z0-9_.]*'), '*')
      .replaceAll(r'\n', ' ')
      .replaceAll(r"\'", "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// The first six words of [message], lowercased and hyphenated.
String _slug(String message) {
  final List<String> words = message
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((String word) => word.isNotEmpty)
      .take(6)
      .toList();
  return words.join('-');
}
