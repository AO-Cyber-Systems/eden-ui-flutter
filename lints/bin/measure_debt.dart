/// Counts what each rule WOULD report over a given scope, without fixing it.
///
/// An invisible backlog never gets budgeted. The enforced scope in
/// `analysis_options.yaml` is deliberately narrow; this prints the number the
/// widening commits have to work down, per rule, so "widen the scope later" is
/// a costed decision rather than a wish.
///
///   dart run eden_lints:measure_debt '<glob>' [<glob> ...]
///
/// Globs are repo relative and are resolved against the CURRENT directory, so
/// run it from the package root. Defaults to the whole of `lib/`.
library;

import 'dart:io';

import 'package:eden_lints/eden_lints.dart';

void main(List<String> args) {
  final scope = args.isEmpty ? <String>['lib/**'] : args;
  final counts = <String, int>{
    kNoRawColor: 0,
    kTextStyleNeedsFamily: 0,
    kNoMagicSpacing: 0,
  };
  final files = <String>{};
  var scanned = 0;

  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    final hits = scanSource(
      source: entity.readAsStringSync(),
      path: path,
      enforcedPaths: scope,
    );
    if (isEnforced(path, scope) && !isTokenPath(path)) scanned++;
    for (final hit in hits) {
      counts[hit.rule] = (counts[hit.rule] ?? 0) + 1;
      files.add(path);
    }
  }

  stdout.writeln('scope: ${scope.join(', ')}');
  stdout.writeln('files in scope (tokens/ excluded): $scanned');
  counts.forEach((rule, count) => stdout.writeln('$rule: $count'));
  stdout.writeln('files with at least one finding: ${files.length}');
}
