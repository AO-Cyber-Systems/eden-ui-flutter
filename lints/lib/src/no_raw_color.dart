import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'ctor.dart';
import 'scope.dart';

const String kNoRawColor = 'no_raw_color';

/// The detector. Returns the problem message, or null when [call] is fine.
///
/// Every `Color` constructor counts, named ones included: `Color.fromARGB`
/// hardcodes a brand exactly as firmly as `Color(0xFF...)` does.
String? noRawColorMessage(CtorCall call) {
  if (call.typeName != 'Color') return null;
  final ctor = call.isUnnamed ? 'Color(...)' : 'Color.${call.constructorName}(...)';
  return 'Raw $ctor outside lib/src/tokens/ -- use an EdenColors token, or '
      'this colour will not respond to a brand change.';
}

class NoRawColor extends DartLintRule {
  const NoRawColor({
    this.enforcedPaths = const <String>[],
    this.legacyExemptions = const <String>[],
  }) : super(code: _code);

  final List<String> enforcedPaths;

  /// Dated, counted pre-existing offenders. See [isLegacyExempt].
  final List<String> legacyExemptions;

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
    if (!shouldLint(resolver.path, enforcedPaths,
        legacyExemptions: legacyExemptions)) {
      return;
    }
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
