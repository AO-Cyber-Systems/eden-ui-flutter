import 'package:flutter/material.dart';

/// File/document card with type icon, name, and metadata.
///
/// ```dart
/// EdenFileCard(
///   fileName: 'Invoice_2026.pdf',
///   fileSize: '2.4 MB',
///   fileType: 'pdf',
///   onTap: () => openFile(file),
///   onDelete: () => deleteFile(file),
/// )
/// ```
class EdenFileCard extends StatelessWidget {
  const EdenFileCard({
    super.key,
    required this.fileName,
    this.fileSize,
    this.fileType,
    this.uploadedBy,
    this.uploadedAt,
    this.onTap,
    this.onDelete,
    this.onDownload,
  });

  final String fileName;
  final String? fileSize;
  final String? fileType;
  final String? uploadedBy;
  final String? uploadedAt;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onDownload;

  IconData get _typeIcon {
    switch (fileType?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc' || 'docx':
        return Icons.description;
      case 'xls' || 'xlsx' || 'csv':
        return Icons.table_chart;
      case 'png' || 'jpg' || 'jpeg' || 'gif' || 'webp':
        return Icons.image;
      case 'zip' || 'rar' || '7z':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _typeColor(ThemeData theme) {
    switch (fileType?.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc' || 'docx':
        return Colors.blue;
      case 'xls' || 'xlsx' || 'csv':
        return Colors.green;
      case 'png' || 'jpg' || 'jpeg' || 'gif' || 'webp':
        return Colors.purple;
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _typeColor(theme);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_typeIcon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (fileSize != null) fileSize,
                        if (uploadedBy != null) uploadedBy,
                        if (uploadedAt != null) uploadedAt,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDownload != null)
                IconButton(
                  icon: const Icon(Icons.download, size: 20),
                  onPressed: onDownload,
                  tooltip: 'Download',
                ),
              if (onDelete != null)
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 20, color: theme.colorScheme.error),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
