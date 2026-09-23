import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'ctor.dart';
import 'scope.dart';

const String kNoRawColor = 'no_raw_color';

/// The detector. Returns the problem message, or null when [call] is fine.
///
/// STUB -- not implemented yet (RED).
String? noRawColorMessage(CtorCall call) {
  return null;
}

class NoRawColor extends DartLintRule {
  const NoRawColor({this.enforcedPaths = const <String>[]}) : super(code: _code);

  final List<String> enforcedPaths;

  static const LintCode _code = LintCode(
    name: kNoRawColor,
    problemMessage: 'Raw Color literal outside lib/src/tokens/.',
    correctionMessage:
        'Use a token from EdenColors. A raw ARGB literal will never respond '
        'to a brand change.',
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
      if (noRawColorMessage(call) == null) return;
      reporter.atNode(node, _code);
    }

    context.registry.addInstanceCreationExpression(check);
    context.registry.addMethodInvocation(check);
  }
}
