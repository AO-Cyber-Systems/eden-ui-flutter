// The guard's own guard.
//
// `tool/probe_guard_assert.sh` is the only place the bundle guard makes a
// decision. A script nobody has watched go red is not a gate, so these tests
// drive it against HAND-BUILT fixture bundles and prove it exits non-zero in
// each way it is supposed to -- including the inert-guard case, which is the
// failure this whole differential control exists to catch.
//
// The two slow `flutter build web --release` runs stay in probe_guard.sh and
// run in CI; what is testable here is every judgement the guard makes about
// the bundles those builds produce.
@Tags(<String>['tool'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A stand-in for a compiled bundle. Hand-built, not generated: the only thing
/// the guard reads out of a 3MB `main.dart.js` is whether the token is there.
File _bundle(Directory dir, String name, {required bool withProbe}) {
  final File file = File('${dir.path}/$name');
  file.writeAsStringSync(
    withProbe
        ? 'var a=1;window.__edenProbe={find:b,tree:c};var d=2;\n'
        : 'var a=1;var d=2;\n',
  );
  return file;
}

ProcessResult _runGuard(String script, File prod, File probe) {
  return Process.runSync('bash', <String>[script, prod.path, probe.path]);
}

void main() {
  // bash is the shell under test; POSIX separators are correct on the only
  // two platforms this runs on (macOS locally, ubuntu-latest in CI).
  final String script = '${Directory.current.path}/tool/probe_guard_assert.sh';

  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('probe_guard_test');
  });

  tearDown(() {
    dir.deleteSync(recursive: true);
  });

  test('passes when the production bundle is clean and the probe bundle is not',
      () {
    final ProcessResult result = _runGuard(
      script,
      _bundle(dir, 'production.js', withProbe: false),
      _bundle(dir, 'probe.js', withProbe: true),
    );

    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    expect(result.stdout, contains('production bundle: 0   probe bundle: 1'));
  });

  test('FAILS when __edenProbe leaks into the production bundle', () {
    final ProcessResult result = _runGuard(
      script,
      _bundle(dir, 'production.js', withProbe: true),
      _bundle(dir, 'probe.js', withProbe: true),
    );

    expect(result.exitCode, isNot(0));
    expect(result.stdout, contains('found in a production bundle'));
  });

  test('FAILS when the probe bundle has no __edenProbe either — the inert guard',
      () {
    // This is the case that makes the guard mean something. Both bundles
    // clean looks like a pass to a one-sided check, and would keep looking
    // like a pass if the bridge were deleted outright.
    final ProcessResult result = _runGuard(
      script,
      _bundle(dir, 'production.js', withProbe: false),
      _bundle(dir, 'probe.js', withProbe: false),
    );

    expect(result.exitCode, isNot(0));
    expect(result.stdout, contains('the guard is inert'));
  });

  test('FAILS when a build produced no bundle at all', () {
    final File prod = _bundle(dir, 'production.js', withProbe: false);
    final File missing = File('${dir.path}/never-built.js');

    final ProcessResult result = _runGuard(script, prod, missing);

    expect(result.exitCode, isNot(0));
    expect(result.stdout, contains('no bundle at'));
  });
}
