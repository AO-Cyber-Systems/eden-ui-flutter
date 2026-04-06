import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Data class for a file or image attachment.
class EdenAttachment {
  const EdenAttachment({
    required this.name,
    required this.size,
    this.type,
    this.url,
    this.thumbnailUrl,
    this.uploadProgress,
  });

  final String name;
  final int size;
  final String? type;
  final String? url;
  final String? thumbnailUrl;
  final double? uploadProgress;
}

/// A file/image attachment preview with type icons, size, and upload progress.
class EdenAttachmentPreview extends StatelessWidget {
  const EdenAttachmentPreview({
    super.key,
    required this.attachment,
    this.thumbnail,
    this.onTap,
    this.onRemove,
  });

  final EdenAttachment attachment;
  final ImageProvider? thumbnail;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  bool get _isImage {
    final type = attachment.type;
    return type != null && type.startsWith('image/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isImage && thumbnail != null) {
      return _buildImagePreview(theme, isDark);
    }
    return _buildFilePreview(theme, isDark);
  }

  Widget _buildImagePreview(ThemeData theme, bool isDark) {
    return Semantics(
      button: onTap != null,
      label: 'Image attachment: ${attachment.name}',
      child: GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: EdenRadii.borderRadiusMd,
              border: Border.all(
                color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
              ),
              image: DecorationImage(
                image: thumbnail!,
                fit: BoxFit.cover,
              ),
            ),
            clipBehavior: Clip.antiAlias,
          ),
          if (attachment.uploadProgress != null)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: EdenRadii.borderRadiusMd,
                ),
                child: Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      value: attachment.uploadProgress,
                      strokeWidth: 3,
                      color: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: _RemoveButton(onTap: onRemove!),
            ),
        ],
      ),
    ),
    );
  }

  Widget _buildFilePreview(ThemeData theme, bool isDark) {
    final fileStyle = _resolveFileStyle(attachment.name, attachment.type);

    return Semantics(
      button: onTap != null,
      label: 'File attachment: ${attachment.name}',
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(EdenSpacing.space3),
        decoration: BoxDecoration(
          color: isDark ? EdenColors.neutral[800] : EdenColors.neutral[50],
          borderRadius: EdenRadii.borderRadiusMd,
          border: Border.all(
            color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
          ),
        ),
        child: Stack(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: fileStyle.color.withValues(alpha: 0.1),
                    borderRadius: EdenRadii.borderRadiusSm,
                  ),
                  child: attachment.uploadProgress != null
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(fileStyle.icon, size: 20, color: fileStyle.color),
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                value: attachment.uploadProgress,
                                strokeWidth: 2,
                                color: fileStyle.color,
                                backgroundColor: fileStyle.color.withValues(alpha: 0.2),
                              ),
                            ),
                          ],
                        )
                      : Icon(fileStyle.icon, size: 20, color: fileStyle.color),
                ),
                const SizedBox(width: EdenSpacing.space3),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        attachment.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatFileSize(attachment.size),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? EdenColors.neutral[400]
                              : EdenColors.neutral[500],
                        ),
                      ),
                    ],
                  ),
                ),
                if (onRemove != null)
                  const SizedBox(width: EdenSpacing.space2),
              ],
            ),
            if (onRemove != null)
              Positioned(
                top: -4,
                right: -4,
                child: _RemoveButton(onTap: onRemove!),
              ),
          ],
        ),
      ),
    ),
    );
  }

  static _FileStyle _resolveFileStyle(String name, String? type) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return const _FileStyle(Icons.picture_as_pdf, Color(0xFFEF4444));
      case 'doc':
      case 'docx':
        return const _FileStyle(Icons.description, Color(0xFF3B82F6));
      case 'xls':
      case 'xlsx':
      case 'csv':
        return const _FileStyle(Icons.table_chart, Color(0xFF10B981));
      case 'ppt':
      case 'pptx':
        return const _FileStyle(Icons.slideshow, Color(0xFFF59E0B));
      case 'zip':
      case 'rar':
      case 'gz':
      case '7z':
        return const _FileStyle(Icons.folder_zip, Color(0xFF8B5CF6));
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'ogg':
        return const _FileStyle(Icons.audio_file, Color(0xFFEC4899));
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return const _FileStyle(Icons.video_file, Color(0xFF6366F1));
      default:
        if (type != null && type.startsWith('image/')) {
          return const _FileStyle(Icons.image, Color(0xFF06B6D4));
        }
        return const _FileStyle(Icons.insert_drive_file, Color(0xFF64748B));
    }
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// A compact inline chip showing file icon, name, size, and optional remove.
class EdenAttachmentChip extends StatelessWidget {
  const EdenAttachmentChip({
    super.key,
    required this.attachment,
    this.onTap,
    this.onRemove,
  });

  final EdenAttachment attachment;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fileStyle = EdenAttachmentPreview._resolveFileStyle(
      attachment.name,
      attachment.type,
    );

    return Semantics(
      button: onTap != null,
      label: 'Attachment: ${attachment.name}',
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? EdenColors.neutral[800] : EdenColors.neutral[100],
          borderRadius: EdenRadii.borderRadiusFull,
          border: Border.all(
            color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(fileStyle.icon, size: 14, color: fileStyle.color),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                attachment.name,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              EdenAttachmentPreview._formatFileSize(attachment.size),
              style: TextStyle(
                fontSize: 11,
                color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 4),
              Semantics(
                button: true,
                label: 'Remove attachment',
                child: GestureDetector(
                  onTap: onRemove,
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Remove',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, size: 12, color: Colors.white),
        ),
      ),
    );
  }
}

class _FileStyle {
  const _FileStyle(this.icon, this.color);
  final IconData icon;
  final Color color;
}
