/// Runs the three detectors over Dart SOURCE, syntactically.
///
/// Used by `rules_test.dart` (against the hand-written fixtures) and by
/// `bin/measure_debt.dart` (to count the unscoped backlog). The detectors
/// themselves are the same functions the custom_lint rules call, so a test
/// that passes here is a statement about the shipped rule, not about a
/// parallel reimplementation of it.
library;

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'ctor.dart';
import 'no_magic_spacing.dart';
import 'no_raw_color.dart';
import 'scope.dart';
import 'text_style_needs_family.dart';

class EdenLintHit {
  const EdenLintHit(this.rule, this.line, this.message);

  final String rule;
  final int line;
  final String message;

  @override
  String toString() => '$rule:$line: $message';
}

typedef _Detector = String? Function(CtorCall call);

const Map<String, _Detector> kDetectors = <String, _Detector>{
  kNoRawColor: noRawColorMessage,
  kTextStyleNeedsFamily: textStyleNeedsFamilyMessage,
  kNoMagicSpacing: noMagicSpacingMessage,
};

/// Scans [source], attributed to repo-relative [path], honouring
/// [enforcedPaths] and the `lib/src/tokens/` exemption.
List<EdenLintHit> scanSource({
  required String source,
  required String path,
  required List<String> enforcedPaths,
  Set<String>? rules,
}) {
  if (!shouldLint(path, enforcedPaths)) return const <EdenLintHit>[];
  final parsed = parseString(content: source, throwIfDiagnostics: false);
  final visitor = _ScanVisitor(parsed.lineInfo, rules);
  parsed.unit.accept(visitor);
  return visitor.hits;
}

class _ScanVisitor extends RecursiveAstVisitor<void> {
  _ScanVisitor(this._lineInfo, this._rules);

  final dynamic _lineInfo;
  final Set<String>? _rules;
  final List<EdenLintHit> hits = <EdenLintHit>[];

  void _check(AstNode node) {
    final call = ctorOf(node);
    if (call == null) return;
    kDetectors.forEach((rule, detect) {
      if (_rules != null && !_rules.contains(rule)) return;
      final message = detect(call);
      if (message == null) return;
      hits.add(
        EdenLintHit(
          rule,
          _lineInfo.getLocation(node.offset).lineNumber as int,
          message,
        ),
      );
    });
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _check(node);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _check(node);
    super.visitMethodInvocation(node);
  }
}
