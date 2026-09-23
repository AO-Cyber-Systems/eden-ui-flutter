import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'ctor.dart';
import 'scope.dart';

const String kTextStyleNeedsFamily = 'text_style_needs_family';

/// The detector. Returns the problem message, or null when [call] is fine.
///
/// Only the unnamed constructor: `TextStyle.lerp` interpolates two styles that
/// were each already subject to this rule.
String? textStyleNeedsFamilyMessage(CtorCall call) {
  if (call.typeName != 'TextStyle' || !call.isUnnamed) return null;
  if (namedArg(call.arguments, 'fontFamily') != null) return null;
  return 'TextStyle without a fontFamily outside lib/src/tokens/ -- name the '
      'family or build it from EdenTypography.';
}

class TextStyleNeedsFamily extends DartLintRule {
  const TextStyleNeedsFamily({
    this.enforcedPaths = const <String>[],
    this.legacyExemptions = const <String>[],
  })
      : super(code: _code);

  final List<String> enforcedPaths;

  /// Dated, counted pre-existing offenders. See [isLegacyExempt].
  final List<String> legacyExemptions;

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
    if (!shouldLint(resolver.path, enforcedPaths,
        legacyExemptions: legacyExemptions)) {
      return;
    }
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
