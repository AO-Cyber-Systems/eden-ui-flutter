import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'ctor.dart';
import 'scope.dart';

const String kNoMagicSpacing = 'no_magic_spacing';

/// The detector. Returns the problem message, or null when [call] is fine.
///
/// STUB -- not implemented yet (RED).
String? noMagicSpacingMessage(CtorCall call) {
  return null;
}

class NoMagicSpacing extends DartLintRule {
  const NoMagicSpacing({this.enforcedPaths = const <String>[]})
      : super(code: _code);

  final List<String> enforcedPaths;

  static const LintCode _code = LintCode(
    name: kNoMagicSpacing,
    problemMessage: 'Hardcoded spacing number outside lib/src/tokens/.',
    correctionMessage:
        'Use a step from EdenSpacing. A number that is on no scale cannot be '
        'restyled and cannot be reviewed.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!shouldLint(resolver.path, enforcedPaths)) return;
    void check(node) {
      final call = ctorOf(node);
      if (call == null) return;
      if (noMagicSpacingMessage(call) == null) return;
      reporter.atNode(node, _code);
    }

    context.registry.addInstanceCreationExpression(check);
    context.registry.addMethodInvocation(check);
  }
}
