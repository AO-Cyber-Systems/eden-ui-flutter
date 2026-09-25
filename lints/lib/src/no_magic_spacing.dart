import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'ctor.dart';
import 'scope.dart';

const String kNoMagicSpacing = 'no_magic_spacing';

/// Named arguments of `SizedBox` that are spacing, not layout flags.
const Set<String> _sizedBoxSpacingArgs = <String>{'width', 'height'};

/// The detector. Returns the problem message, or null when [call] is fine.
///
/// Zero is deliberately exempt: zero is not a magic number, it is the absence
/// of one, and `EdgeInsets.symmetric(horizontal: 0)` says something a token
/// cannot say more clearly.
String? noMagicSpacingMessage(CtorCall call) {
  final offenders = <num>[];
  if (call.typeName == 'EdgeInsets') {
    for (final arg in call.arguments.arguments) {
      final value = literalNumber(arg is NamedExpression ? arg.expression : arg);
      if (value != null && value != 0) offenders.add(value);
    }
  } else if (call.typeName == 'SizedBox') {
    for (final name in _sizedBoxSpacingArgs) {
      final arg = namedArg(call.arguments, name);
      if (arg == null) continue;
      final value = literalNumber(arg.expression);
      if (value != null && value != 0) offenders.add(value);
    }
  }
  if (offenders.isEmpty) return null;
  return 'Hardcoded spacing ${offenders.join(', ')} in '
      '${call.typeName} outside lib/src/tokens/ -- use an EdenSpacing step.';
}

class NoMagicSpacing extends DartLintRule {
  const NoMagicSpacing({
    this.enforcedPaths = const <String>[],
    this.legacyExemptions = const <String>[],
  })
      : super(code: _code);

  final List<String> enforcedPaths;

  /// Dated, counted pre-existing offenders. See [isLegacyExempt].
  final List<String> legacyExemptions;

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
    if (!shouldLint(resolver.path, enforcedPaths,
        legacyExemptions: legacyExemptions)) {
      return;
    }
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
