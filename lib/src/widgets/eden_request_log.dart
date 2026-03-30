import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// HTTP method types for API request log entries.
enum EdenHttpMethod {
  /// HTTP GET request.
  get,

  /// HTTP POST request.
  post,

  /// HTTP PUT request.
  put,

  /// HTTP PATCH request.
  patch,

  /// HTTP DELETE request.
  delete,
}

/// A compact row displaying a single API request log entry.
///
/// Designed for use in scrollable lists. Shows the HTTP method, request path,
/// status code, optional model name, token usage, response time, streaming
/// indicator, and relative timestamp.
class EdenRequestLog extends StatelessWidget {
  const EdenRequestLog({
    super.key,
    required this.method,
    required this.path,
    required this.statusCode,
    this.model,
    this.inputTokens,
    this.outputTokens,
    this.responseTime,
    this.streamed = false,
    this.timestamp,
  });

  /// The HTTP method of the request.
  final EdenHttpMethod method;

  /// The request path (e.g. "/v1/chat/completions").
  final String path;

  /// The HTTP status code returned.
  final int statusCode;

  /// The model name used for the request, if applicable.
  final String? model;

  /// Number of input/prompt tokens consumed.
  final int? inputTokens;

  /// Number of output/completion tokens produced.
  final int? outputTokens;

  /// Formatted response time (e.g. "142ms").
  final String? responseTime;

  /// Whether the response was streamed.
  final bool streamed;

  /// When the request occurred.
  final DateTime? timestamp;

  String _methodLabel() {
    switch (method) {
      case EdenHttpMethod.get:
        return 'GET';
      case EdenHttpMethod.post:
        return 'POST';
      case EdenHttpMethod.put:
        return 'PUT';
      case EdenHttpMethod.patch:
        return 'PATCH';
      case EdenHttpMethod.delete:
        return 'DEL';
    }
  }

  Color _methodColor() {
    switch (method) {
      case EdenHttpMethod.get:
        return EdenColors.info;
      case EdenHttpMethod.post:
        return EdenColors.success;
      case EdenHttpMethod.put:
        return EdenColors.warning;
      case EdenHttpMethod.patch:
        return EdenColors.info;
      case EdenHttpMethod.delete:
        return EdenColors.error;
    }
  }

  Color _statusColor() {
    if (statusCode >= 200 && statusCode < 300) return EdenColors.success;
    if (statusCode >= 400 && statusCode < 500) return EdenColors.warning;
    if (statusCode >= 500) return EdenColors.error;
    return EdenColors.info;
  }

  String _relativeTimestamp() {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final diff = now.difference(timestamp!);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor = isDark ? EdenColors.neutral[800]! : EdenColors.neutral[200]!;
    final mutedTextColor = isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;
    final monoStyle = theme.textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Courier New', 'Courier'],
    );

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: EdenSpacing.space2,
        horizontal: EdenSpacing.space3,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Method badge
          _MethodBadge(
            label: _methodLabel(),
            color: _methodColor(),
          ),
          SizedBox(width: EdenSpacing.space2),

          // Path
          Expanded(
            flex: 3,
            child: Text(
              path,
              style: monoStyle?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          SizedBox(width: EdenSpacing.space2),

          // Status code badge
          _StatusBadge(
            code: statusCode,
            color: _statusColor(),
            textStyle: theme.textTheme.labelSmall,
          ),
          SizedBox(width: EdenSpacing.space3),

          // Model
          if (model != null) ...[
            SizedBox(
              width: 80,
              child: Text(
                model!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: mutedTextColor,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            SizedBox(width: EdenSpacing.space3),
          ],

          // Tokens
          if (inputTokens != null || outputTokens != null) ...[
            Text(
              _formatTokens(),
              style: monoStyle?.copyWith(
                color: mutedTextColor,
                fontSize: 11,
              ),
            ),
            SizedBox(width: EdenSpacing.space3),
          ],

          // Response time
          if (responseTime != null) ...[
            Text(
              responseTime!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: mutedTextColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            SizedBox(width: EdenSpacing.space2),
          ],

          // Streamed icon
          if (streamed) ...[
            Tooltip(
              message: 'Streamed',
              child: Icon(
                Icons.stream,
                size: 14,
                color: EdenColors.info,
              ),
            ),
            SizedBox(width: EdenSpacing.space2),
          ],

          // Timestamp
          if (timestamp != null)
            Text(
              _relativeTimestamp(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: mutedTextColor,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTokens() {
    final parts = <String>[];
    if (inputTokens != null) parts.add('\u2191${inputTokens}');
    if (outputTokens != null) parts.add('\u2193${outputTokens}');
    return parts.join(' ');
  }
}

class _MethodBadge extends StatelessWidget {
  const _MethodBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      padding: EdgeInsets.symmetric(
        horizontal: EdenSpacing.space1,
        vertical: EdenSpacing.space1 / 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: EdenRadii.borderRadiusSm,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          fontFamilyFallback: const ['Courier New', 'Courier'],
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.code,
    required this.color,
    required this.textStyle,
  });

  final int code;
  final Color color;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: EdenSpacing.space1 / 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: EdenRadii.borderRadiusSm,
      ),
      child: Text(
        code.toString(),
        style: textStyle?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
