import 'template_models.dart';

/// Pure-function variables resolver — parity row V-6.
///
/// Substitutes `{{group.field}}` tokens (and dotted nested paths like
/// `{{customer.address.line1}}`) in a template string against a data map.
///
/// Stateless static class — no instance state, no side effects.
class EdenTemplateVariablesResolver {
  EdenTemplateVariablesResolver._();

  /// Regex anchors the path to a strict identifier character class so the
  /// match cannot span multiple tokens or accept non-identifier chars.
  /// Whitespace inside `{{ }}` is tolerated.
  static final RegExp _tokenPattern =
      RegExp(r'\{\{\s*([a-zA-Z_][a-zA-Z0-9_.]*)\s*\}\}');

  /// Substitute tokens in [text] using values from [data].
  ///
  /// - When a token's path cannot be resolved (missing key, null intermediate,
  ///   or non-Map intermediate before the final segment): if [throwOnMissing]
  ///   is true, throws [EdenTemplateMissingVariableException]; else replaces
  ///   the token with [missingPlaceholder] (default empty string).
  /// - Non-String final values are stringified via `toString()`.
  static String resolve(
    String text,
    Map<String, dynamic> data, {
    bool throwOnMissing = false,
    String missingPlaceholder = '',
  }) {
    return text.replaceAllMapped(_tokenPattern, (match) {
      final path = match.group(1)!;
      final value = _walkPath(path, data);
      if (value == null) {
        if (throwOnMissing) {
          throw EdenTemplateMissingVariableException(path);
        }
        return missingPlaceholder;
      }
      return value.toString();
    });
  }

  static Object? _walkPath(String path, Map<String, dynamic> data) {
    final parts = path.split('.');
    Object? current = data;
    for (final part in parts) {
      if (current is! Map) return null;
      current = current[part];
      if (current == null) return null;
    }
    return current;
  }
}
