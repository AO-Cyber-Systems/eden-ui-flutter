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
// list empty. A message built into a local, a message returned from a shape
// the opener regex does not match, a message in a quote style nobody
// anticipated — each of them now arrives as an unattributed literal and fails
// the table, instead of being ignored.
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

  // SEED: the functions expectUiSane folds into its aggregated report. Any
  // check that is not reachable from here cannot produce a violation, so
  // starting anywhere else would over-count.
  final Set<String> reached = RegExp(
    r'violations\.add(?:All)?\(\s*(?:await\s+)?(_[A-Za-z0-9_]+)\(',
  ).allMatches(entry.join('\n')).map((RegExpMatch m) => m.group(1)!).toSet();
  if (reached.isEmpty) {
    throw StateError(
      'OracleCheckInventory: expectUiSane aggregates no check functions. '
      'Either the aggregation moved or the parser stopped matching it.',
    );
  }

  final List<String> queue = reached.toList();
  while (queue.isNotEmpty) {
    final String next = queue.removeLast();
    final List<String>? body = bodies[next];
    if (body == null) {
      continue;
    }
    for (final RegExpMatch call
        in RegExp(r'\b(_[A-Za-z0-9_]+)\(').allMatches(body.join('\n'))) {
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
      String slug = _slug(message);
      if (slug.isEmpty) {
        slug = 'site-$ordinal';
      }
      if (slugs.contains(slug)) {
        slug = '$slug-$ordinal';
      }
      slugs.add(slug);
      sites.add(
        OracleCheckSite(
          id: '$function#$slug',
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
