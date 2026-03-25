import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// File selection input button.
///
/// Renders a styled button that displays selected file name(s).
/// The actual file picking logic is handled by the consumer via [onTap] —
/// this widget is framework-agnostic and doesn't depend on file_picker.
///
/// ```dart
/// EdenFileInput(
///   label: 'Attachment',
///   fileName: selectedFile?.name,
///   onTap: () async {
///     final result = await FilePicker.platform.pickFiles();
///     if (result != null) setState(() => selectedFile = result.files.first);
///   },
///   onClear: () => setState(() => selectedFile = null),
/// )
/// ```
class EdenFileInput extends StatelessWidget {
  const EdenFileInput({
    super.key,
    required this.onTap,
    this.label,
    this.hint = 'Choose file...',
    this.fileName,
    this.fileNames,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.onClear,
    this.icon = Icons.attach_file,
    this.accept,
  });

  final VoidCallback onTap;
  final String? label;
  final String hint;
  final String? fileName;

  /// For multi-file selection. Takes precedence over [fileName].
  final List<String>? fileNames;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final VoidCallback? onClear;
  final IconData icon;

  /// Accepted file types hint (for display only).
  final String? accept;

  bool get _hasFiles =>
      (fileNames != null && fileNames!.isNotEmpty) ||
      (fileName != null && fileName!.isNotEmpty);

  String get _displayText {
    if (fileNames != null && fileNames!.isNotEmpty) {
      return fileNames!.length == 1
          ? fileNames!.first
          : '${fileNames!.length} files selected';
    }
    return fileName ?? hint;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: hasError ? EdenColors.error : null,
            ),
          ),
          const SizedBox(height: 6),
        ],
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: InputDecorator(
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              errorText: errorText,
              errorStyle: const TextStyle(fontSize: 12),
              prefixIcon: Icon(icon, size: 20),
              suffixIcon: _hasFiles && onClear != null
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: onClear,
                    )
                  : null,
              enabled: enabled,
            ),
            child: Text(
              _displayText,
              style: TextStyle(
                fontSize: 14,
                color: _hasFiles
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (accept != null && !hasError) ...[
          const SizedBox(height: 4),
          Text(
            'Accepted: $accept',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ] else if (helperText != null && !hasError) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
