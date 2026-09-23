/// Path scoping shared by all three Eden lint rules.
///
/// The enforced-path list is DECLARED (in `analysis_options.yaml`), not
/// inferred. A rule that fires everywhere on the day it lands gets switched
/// off within a week; a narrow rule that holds is worth more than a wide rule
/// that is disabled. Widen by adding a glob, in its own commit, after
/// clearing the findings it exposes.
library;

/// Directory where raw colours, raw font sizes and raw spacing numbers BELONG.
/// The exemption lives here, in rule logic -- never as a per-file
/// `// ignore:` comment, which would be indistinguishable from real debt.
const String kTokensDir = 'lib/src/tokens/';

/// True when [path] sits under the token definitions and is therefore exempt.
bool isTokenPath(String path) {
  final p = path.replaceAll(r'\', '/');
  return p.contains(kTokensDir);
}

/// True when [path] falls under one of the declared [enforcedPaths] globs.
///
/// [path] may be absolute (custom_lint hands us absolute paths) or repo
/// relative (the tests hand us virtual repo-relative paths); globs are always
/// repo relative and are matched against any path suffix boundary.
bool isEnforced(String path, List<String> enforcedPaths) {
  if (enforcedPaths.isEmpty) return false;
  final p = path.replaceAll(r'\', '/');
  for (final glob in enforcedPaths) {
    if (_globRegExp(glob).hasMatch(p)) return true;
  }
  return false;
}

RegExp _globRegExp(String glob) {
  final buffer = StringBuffer(r'(^|/)');
  for (var i = 0; i < glob.length; i++) {
    final c = glob[i];
    if (c == '*') {
      if (i + 1 < glob.length && glob[i + 1] == '*') {
        buffer.write('.*');
        i++;
      } else {
        buffer.write('[^/]*');
      }
    } else if (_needsEscape.contains(c)) {
      buffer.write('\\');
      buffer.write(c);
    } else {
      buffer.write(c);
    }
  }
  buffer.write(r'$');
  return RegExp(buffer.toString());
}

const String _needsEscape = r'\^$.|?+()[]{}';

/// True when a rule should look at [path] at all.
bool shouldLint(String path, List<String> enforcedPaths) =>
    isEnforced(path, enforcedPaths) && !isTokenPath(path);

/// Reads an `enforced_paths:` list out of a rule's custom_lint options map.
List<String> enforcedPathsFrom(Map<String, Object?>? json) {
  final raw = json?['enforced_paths'];
  if (raw is! List) return const <String>[];
  return raw.map((e) => '$e').toList(growable: false);
}
