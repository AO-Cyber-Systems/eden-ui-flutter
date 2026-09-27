/// A constructor-shaped call, normalised across RESOLVED and UNRESOLVED ASTs.
///
/// This matters more than it looks. Inside custom_lint the AST is resolved, so
/// `Color(0xFF112233)` arrives as an `InstanceCreationExpression`. In the rule
/// tests we parse fixtures syntactically (no Flutter SDK, no resolution), and
/// the very same source parses as a `MethodInvocation`. A predicate that
/// understood only one of the two shapes would pass its tests and never fire
/// in CI -- the classic gate that never ran. Both shapes are handled here,
/// once, so the tested logic is the shipped logic.
library;

import 'package:analyzer/dart/ast/ast.dart';

class CtorCall {
  const CtorCall(this.typeName, this.constructorName, this.arguments);

  /// e.g. `Color`, `EdgeInsets`, `TextStyle`.
  final String typeName;

  /// Named constructor, e.g. `all` in `EdgeInsets.all(13)`; null for unnamed.
  final String? constructorName;

  final ArgumentList arguments;

  bool get isUnnamed => constructorName == null;
}

/// Normalises [node] to a [CtorCall], or null when it is not one.
CtorCall? ctorOf(AstNode node) {
  if (node is InstanceCreationExpression) {
    return CtorCall(
      node.constructorName.type.toSource(),
      node.constructorName.name?.name,
      node.argumentList,
    );
  }
  if (node is MethodInvocation) {
    final target = node.target;
    if (target == null) {
      // `Color(0xFF112233)` -- unresolved: bare call, the name IS the type.
      return CtorCall(node.methodName.name, null, node.argumentList);
    }
    if (target is SimpleIdentifier) {
      // `EdgeInsets.all(13)` -- unresolved: the target is the type.
      return CtorCall(target.name, node.methodName.name, node.argumentList);
    }
  }
  return null;
}

/// The named argument called [name], or null when absent.
NamedExpression? namedArg(ArgumentList args, String name) {
  for (final a in args.arguments) {
    if (a is NamedExpression && a.name.label.name == name) return a;
  }
  return null;
}

/// The integer value of [expression] when it is a bare numeric literal.
num? literalNumber(Expression expression) {
  var e = expression;
  if (e is PrefixExpression && e.operator.lexeme == '-') {
    final inner = literalNumber(e.operand);
    return inner == null ? null : -inner;
  }
  if (e is IntegerLiteral) return e.value;
  if (e is DoubleLiteral) return e.value;
  return null;
}
