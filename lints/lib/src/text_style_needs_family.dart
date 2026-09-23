import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'ctor.dart';
import 'scope.dart';

const String kTextStyleNeedsFamily = 'text_style_needs_family';

/// The detector. Returns the problem message, or null when [call] is fine.
///
/// STUB -- not implemented yet (RED).
String? textStyleNeedsFamilyMessage(CtorCall call) {
  return null;
}

class TextStyleNeedsFamily extends DartLintRule {
  const TextStyleNeedsFamily({this.enforcedPaths = const <String>[]})
      : super(code: _code);

  final List<String> enforcedPaths;

  static const LintCode _code = LintCode(
    name: kTextStyleNeedsFamily,
    problemMessage: 'TextStyle without a fontFamily outside lib/src/tokens/.',
    correctionMessage:
        'Name the family, or build the style from EdenTypography. An '
        'unfamilied TextStyle silently inherits whatever theme is ambient.',
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
      if (textStyleNeedsFamilyMessage(call) == null) return;
      reporter.atNode(node, _code);
    }

    context.registry.addInstanceCreationExpression(check);
    context.registry.addMethodInvocation(check);
  }
}
