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
// WHAT COUNTS AS A SITE, stated because the rule has one deliberate hole:
//
//   * any `<accumulator>.add(<string literal>)` in a reachable function —
//     included whatever its length, because a message can be entirely
//     interpolation (`'${guideline.description}: ${failure.message}'`); and
//   * any `return <string literal>` in a reachable function whose message is
//     at least [_minimumReturnedMessage] characters after normalisation.
//
// The length floor on RETURNS exists because a reachable helper can return a
// PHRASE that is substituted into someone else's message —
// `_announcedAffordance` returns 'a button' — and those are not checks. The
// floor is a heuristic, so the hole it leaves is closed rather than ignored:
// every returned literal the floor REJECTS is reported in
// [OracleCheckInventory.rejectedFragments], and the catalogue pins that list
// by name. A new short returned message therefore cannot slip past — it
// arrives as an unrecognised fragment and the test asks whether it is a
// violation the table now has to account for.
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
  });

  /// Every message-producing site, ordered by id.
  final List<OracleCheckSite> sites;

  /// Returned literals rejected by the length floor, ordered. Pinned by the
  /// catalogue so a new short violation message cannot arrive unnoticed.
  final List<String> rejectedFragments;

  /// The functions reached transitively from `expectUiSane`'s aggregation.
  final List<String> reachedFunctions;

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
  final List<String> functions = reached.toList()..sort();

  for (final String function in functions) {
    final List<String> body = bodies[function]!;
    final List<String> slugs = <String>[];
    int ordinal = -1;
    for (int i = 0; i < body.length; i++) {
      final RegExpMatch? opener =
          RegExp(r'(\.add\(|\breturn\b)').firstMatch(body[i]);
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
      if (!rest.startsWith("'")) {
        continue;
      }
      ordinal++;
      final String message = _normalise(_gatherLiteral(body, at));
      final bool viaAdd = opener.group(1) != 'return';
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
  }

  sites.sort((OracleCheckSite a, OracleCheckSite b) => a.id.compareTo(b.id));
  rejected.sort();
  return OracleCheckInventory(
    sites: sites,
    rejectedFragments: rejected,
    reachedFunctions: functions,
  );
}

/// Joins the adjacent string literals that make up one Dart expression,
/// starting at [index].
///
/// Dart concatenates adjacent literals, and every message in the oracle is
/// written as one per source line, so a site's text is spread over up to a
/// dozen lines. Collection stops at the first line that does not end inside
/// the expression.
String _gatherLiteral(List<String> body, int index) {
  final RegExp literal = RegExp(r"'((?:[^'\\]|\\.)*)'");
  final StringBuffer out = StringBuffer();
  for (int i = index; i < body.length; i++) {
    final String line = body[i].trim();
    final Iterable<RegExpMatch> matches = literal.allMatches(line);
    if (matches.isEmpty) {
      break;
    }
    for (final RegExpMatch match in matches) {
      out.write(match.group(1));
    }
    if (line.endsWith("'") || line.endsWith("',")) {
      continue;
    }
    break;
  }
  return out.toString();
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
