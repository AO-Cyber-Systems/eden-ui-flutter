import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// File display tile with content-type icon, size formatting, and date.
class EdenFileListTile extends StatelessWidget {
  const EdenFileListTile({
    super.key,
    required this.fileName,
    this.mimeType,
    this.fileSize,
    this.date,
    this.onTap,
    this.trailingActions = const [],
  });

  final String fileName;
  final String? mimeType;
  final int? fileSize;
  final String? date;
  final VoidCallback? onTap;
  final List<Widget> trailingActions;

  /// Format bytes into human-readable string.
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Icon for a given MIME type.
  static IconData iconForMimeType(String? mimeType) {
    if (mimeType == null) return Icons.insert_drive_file_outlined;
    final type = mimeType.toLowerCase();

    if (type.contains('pdf')) return Icons.picture_as_pdf;
    if (type.contains('word') || type.contains('doc')) return Icons.description;
    if (type.contains('sheet') || type.contains('excel') || type.contains('csv')) {
      return Icons.table_chart;
    }
    if (type.startsWith('image/')) return Icons.image_outlined;
    if (type.startsWith('video/')) return Icons.videocam_outlined;
    if (type.startsWith('audio/')) return Icons.audiotrack_outlined;
    if (type.contains('zip') || type.contains('tar') || type.contains('rar') ||
        type.contains('gz') || type.contains('archive')) {
      return Icons.folder_zip_outlined;
    }
    if (type.contains('json') || type.contains('xml') || type.contains('html') ||
        type.contains('css') || type.contains('javascript') || type.contains('typescript') ||
        type.contains('text/x-')) {
      return Icons.code;
    }
    return Icons.insert_drive_file_outlined;
  }

  /// Color for a given MIME type.
  static Color colorForMimeType(String? mimeType) {
    if (mimeType == null) return EdenColors.neutral[500]!;
    final type = mimeType.toLowerCase();

    if (type.contains('pdf')) return const Color(0xFFEF4444); // red
    if (type.contains('word') || type.contains('doc')) return const Color(0xFF3B82F6); // blue
    if (type.contains('sheet') || type.contains('excel') || type.contains('csv')) {
      return const Color(0xFF10B981); // green
    }
    if (type.startsWith('image/')) return const Color(0xFFA855F7); // purple
    if (type.startsWith('video/')) return const Color(0xFFF97316); // orange
    if (type.startsWith('audio/')) return const Color(0xFFEC4899); // pink
    if (type.contains('json') || type.contains('xml') || type.contains('html') ||
        type.contains('css') || type.contains('javascript') || type.contains('typescript') ||
        type.contains('text/x-')) {
      return const Color(0xFF06B6D4); // cyan
    }
    if (type.contains('zip') || type.contains('tar') || type.contains('rar') ||
        type.contains('gz') || type.contains('archive')) {
      return const Color(0xFFF59E0B); // amber
    }
    return EdenColors.neutral[500]!; // gray
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = colorForMimeType(mimeType);
    final fileIcon = iconForMimeType(mimeType);

    return Semantics(
      label: 'File: $fileName',
      button: onTap != null,
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: isDark
            ? EdenColors.neutral[800]!.withValues(alpha: 0.5)
            : EdenColors.neutral[50]!,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space4,
            vertical: EdenSpacing.space3,
          ),
          child: Row(
            children: [
              _buildIcon(color, fileIcon),
              const SizedBox(width: EdenSpacing.space3),
              Expanded(child: _buildContent(theme, isDark)),
              if (trailingActions.isNotEmpty) ...[
                const SizedBox(width: EdenSpacing.space2),
                ...trailingActions,
              ],
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildIcon(Color color, IconData fileIcon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: EdenRadii.borderRadiusMd,
      ),
      child: Icon(fileIcon, size: 20, color: color),
    );
  }

  Widget _buildContent(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fileName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            if (mimeType != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
                  borderRadius: EdenRadii.borderRadiusFull,
                ),
                child: Text(
                  _shortMimeType(mimeType!),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (fileSize != null)
              Text(
                formatFileSize(fileSize!),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? EdenColors.neutral[500]! : EdenColors.neutral[400]!,
                ),
              ),
            if (fileSize != null && date != null)
              Text(
                '  ·  ',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? EdenColors.neutral[600]! : EdenColors.neutral[300]!,
                ),
              ),
            if (date != null)
              Text(
                date!,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? EdenColors.neutral[500]! : EdenColors.neutral[400]!,
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _shortMimeType(String mime) {
    // Show just the subtype, e.g., "application/pdf" -> "PDF"
    final parts = mime.split('/');
    final sub = parts.length > 1 ? parts[1] : parts[0];
    // Clean up common prefixes
    final cleaned = sub
        .replaceAll('vnd.openxmlformats-officedocument.', '')
        .replaceAll('vnd.ms-', '')
        .replaceAll('x-', '')
        .split('.')
        .last;
    return cleaned.toUpperCase();
  }
}
