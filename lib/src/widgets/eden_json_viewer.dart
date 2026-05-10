import 'dart:convert';
import 'package:flutter/material.dart';
import 'eden_code_block.dart';

/// Displays arbitrary JSON-serializable data as a syntax-highlighted,
/// copyable code block.
///
/// Accepts:
/// - a raw JSON `String` (will be parsed and pretty-printed)
/// - a decoded value (`Map`, `List`, primitive) — pretty-printed directly
/// - any other object — falls back to `toString()`
///
/// Indentation is 2 spaces. Output is read-only; copy is via the underlying
/// [EdenCodeBlock] copy affordance.
class EdenJsonViewer extends StatelessWidget {
  const EdenJsonViewer({
    super.key,
    required this.data,
    this.initiallyExpanded = true,
  });

  /// The value to render. May be a JSON string, a decoded `Map`/`List`, or
  /// any object with a useful `toString()`.
  final dynamic data;

  /// Reserved for future expand/collapse behavior on large payloads.
  /// Currently unused — the underlying [EdenCodeBlock] always renders the
  /// full content. Left in the API to avoid a breaking change later.
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    String formatted;
    try {
      if (data is String) {
        final parsed = jsonDecode(data as String);
        formatted = const JsonEncoder.withIndent('  ').convert(parsed);
      } else {
        formatted = const JsonEncoder.withIndent('  ').convert(data);
      }
    } catch (_) {
      formatted = data?.toString() ?? 'null';
    }

    return EdenCodeBlock(
      code: formatted,
      language: 'json',
      copyable: true,
    );
  }
}
