import 'dart:math';
import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Upload status for a single file.
enum EdenUploadStatus { pending, uploading, complete, error }

/// Represents a file in the upload queue.
class EdenUploadFile {
  const EdenUploadFile({
    required this.name,
    required this.sizeBytes,
    this.mimeType,
    this.progress = 0.0,
    this.status = EdenUploadStatus.pending,
    this.error,
    this.previewUrl,
    this.platformFile,
  });

  final String name;
  final int sizeBytes;
  final String? mimeType;
  final double progress;
  final EdenUploadStatus status;
  final String? error;
  final String? previewUrl;
  final dynamic platformFile;

  /// Creates a copy with updated fields.
  EdenUploadFile copyWith({
    String? name,
    int? sizeBytes,
    String? mimeType,
    double? progress,
    EdenUploadStatus? status,
    String? error,
    String? previewUrl,
    dynamic platformFile,
  }) {
    return EdenUploadFile(
      name: name ?? this.name,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      mimeType: mimeType ?? this.mimeType,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      error: error ?? this.error,
      previewUrl: previewUrl ?? this.previewUrl,
      platformFile: platformFile ?? this.platformFile,
    );
  }
}

/// A file upload component with drag-drop zone, progress, and file list.
///
/// The widget does not depend on any file picker package directly. Instead,
/// it exposes [onFilesSelected] and [onRemove] callbacks so consumers can
/// wire their own file selection logic.
class EdenFileUpload extends StatefulWidget {
  const EdenFileUpload({
    super.key,
    this.files = const [],
    this.onFilesSelected,
    this.onRemove,
    this.label,
    this.hint,
    this.errorText,
    this.allowedExtensions,
    this.maxFileSizeBytes,
    this.maxFiles,
    this.multiple = true,
    this.compact = false,
    this.enabled = true,
    this.showPreviews = true,
  });

  /// Current list of files (controlled externally).
  final List<EdenUploadFile> files;

  /// Called when the user requests to add files (tap or drop).
  final VoidCallback? onFilesSelected;

  /// Called when the user removes a file at the given index.
  final ValueChanged<int>? onRemove;

  final String? label;
  final String? hint;
  final String? errorText;

  /// Allowed file extensions, e.g. `['pdf', 'png', 'jpg']`.
  final List<String>? allowedExtensions;

  /// Maximum size in bytes for a single file.
  final int? maxFileSizeBytes;

  /// Maximum number of files.
  final int? maxFiles;
  final bool multiple;
  final bool compact;
  final bool enabled;
  final bool showPreviews;

  @override
  State<EdenFileUpload> createState() => _EdenFileUploadState();
}

class _EdenFileUploadState extends State<EdenFileUpload> {
  bool _isDragOver = false;

  bool get _canAddMore =>
      widget.maxFiles == null || widget.files.length < widget.maxFiles!;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: hasError ? EdenColors.error : null,
            ),
          ),
          const SizedBox(height: 6),
        ],
        if (widget.compact)
          _buildCompactZone(theme, hasError)
        else
          _buildDropZone(theme, hasError),
        if (widget.hint != null && !hasError) ...[
          const SizedBox(height: 4),
          Text(
            widget.hint!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: EdenColors.error,
            ),
          ),
        ],
        if (widget.files.isNotEmpty) ...[
          const SizedBox(height: EdenSpacing.space3),
          _buildFileList(theme),
        ],
      ],
    );
  }

  Widget _buildDropZone(ThemeData theme, bool hasError) {
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = hasError
        ? EdenColors.error
        : _isDragOver
            ? theme.colorScheme.primary
            : isDark
                ? EdenColors.neutral[600]!
                : EdenColors.neutral[300]!;
    final bgColor = _isDragOver
        ? theme.colorScheme.primary.withValues(alpha: 0.05)
        : isDark
            ? EdenColors.neutral[900]!
            : EdenColors.neutral[50]!;

    return DragTarget<Object>(
      onWillAcceptWithDetails: (_) {
        if (!widget.enabled || !_canAddMore) return false;
        setState(() => _isDragOver = true);
        return true;
      },
      onLeave: (_) => setState(() => _isDragOver = false),
      onAcceptWithDetails: (_) {
        setState(() => _isDragOver = false);
        widget.onFilesSelected?.call();
      },
      builder: (context, candidateData, rejectedData) {
        return Semantics(
          label: 'Upload files',
          button: true,
          child: GestureDetector(
          onTap: widget.enabled && _canAddMore
              ? widget.onFilesSelected
              : null,
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: borderColor,
              radius: EdenRadii.lg,
              dashWidth: 6,
              dashGap: 4,
              strokeWidth: 1.5,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: EdenSpacing.space8,
                horizontal: EdenSpacing.space4,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: EdenRadii.borderRadiusLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 40,
                    color: _isDragOver
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: EdenSpacing.space2),
                  Text(
                    'Drag & drop files here, or click to browse',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.allowedExtensions != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Allowed: ${widget.allowedExtensions!.join(', ')}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  if (widget.maxFileSizeBytes != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Max size: ${_formatFileSize(widget.maxFileSizeBytes!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        );
      },
    );
  }

  Widget _buildCompactZone(ThemeData theme, bool hasError) {
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = hasError
        ? EdenColors.error
        : isDark
            ? EdenColors.neutral[600]!
            : EdenColors.neutral[300]!;

    return Semantics(
      label: 'Choose files',
      button: true,
      child: GestureDetector(
        onTap: widget.enabled && _canAddMore ? widget.onFilesSelected : null,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space3,
            vertical: EdenSpacing.space2,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: EdenRadii.borderRadiusMd,
            color: isDark ? EdenColors.neutral[900]! : EdenColors.neutral[50]!,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.attach_file,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: EdenSpacing.space2),
              Text(
                widget.files.isEmpty
                    ? 'Choose files...'
                    : '${widget.files.length} file${widget.files.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileList(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < widget.files.length; i++) ...[
          if (i > 0) const SizedBox(height: EdenSpacing.space2),
          _buildFileItem(theme, widget.files[i], i),
        ],
      ],
    );
  }

  Widget _buildFileItem(ThemeData theme, EdenUploadFile file, int index) {
    final isDark = theme.brightness == Brightness.dark;
    final isError = file.status == EdenUploadStatus.error;
    final isUploading = file.status == EdenUploadStatus.uploading;

    return Container(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[800]! : Colors.white,
        borderRadius: EdenRadii.borderRadiusMd,
        border: Border.all(
          color: isError
              ? EdenColors.error.withValues(alpha: 0.3)
              : isDark
                  ? EdenColors.neutral[700]!
                  : EdenColors.neutral[200]!,
        ),
      ),
      child: Row(
        children: [
          if (widget.showPreviews && _isImage(file.mimeType))
            _buildThumbnail(theme, file)
          else
            _buildFileIcon(theme, file),
          const SizedBox(width: EdenSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  file.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _formatFileSize(file.sizeBytes),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (isError && file.error != null) ...[
                      const SizedBox(width: EdenSpacing.space2),
                      Expanded(
                        child: Text(
                          file.error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: EdenColors.error,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (isUploading) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: EdenRadii.borderRadiusFull,
                    child: LinearProgressIndicator(
                      value: file.progress.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: isDark
                          ? EdenColors.neutral[700]!
                          : EdenColors.neutral[200]!,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: EdenSpacing.space2),
          _buildStatusIndicator(theme, file),
          if (widget.enabled && widget.onRemove != null) ...[
            const SizedBox(width: EdenSpacing.space1),
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                onPressed: () => widget.onRemove?.call(index),
                icon: const Icon(Icons.close, size: 16),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                tooltip: 'Remove file',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileIcon(ThemeData theme, EdenUploadFile file) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: EdenRadii.borderRadiusMd,
      ),
      child: Icon(
        _fileIcon(file),
        size: 20,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildThumbnail(ThemeData theme, EdenUploadFile file) {
    final isDark = theme.brightness == Brightness.dark;

    if (file.previewUrl != null) {
      return ClipRRect(
        borderRadius: EdenRadii.borderRadiusMd,
        child: Image.network(
          file.previewUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          errorBuilder: (_, __, ___) => _buildFileIcon(theme, file),
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
        borderRadius: EdenRadii.borderRadiusMd,
      ),
      child: Icon(
        Icons.image_outlined,
        size: 20,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildStatusIndicator(ThemeData theme, EdenUploadFile file) {
    switch (file.status) {
      case EdenUploadStatus.pending:
        return const SizedBox.shrink();
      case EdenUploadStatus.uploading:
        return Text(
          '${(file.progress * 100).round()}%',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        );
      case EdenUploadStatus.complete:
        return const Icon(Icons.check_circle, size: 20, color: EdenColors.success);
      case EdenUploadStatus.error:
        return const Icon(Icons.error_outline, size: 20, color: EdenColors.error);
    }
  }

  bool _isImage(String? mimeType) {
    if (mimeType == null) return false;
    return mimeType.startsWith('image/');
  }

  IconData _fileIcon(EdenUploadFile file) {
    final mime = file.mimeType ?? '';
    if (mime.startsWith('image/')) return Icons.image_outlined;
    if (mime.startsWith('video/')) return Icons.videocam_outlined;
    if (mime.startsWith('audio/')) return Icons.audiotrack_outlined;
    if (mime.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (mime.contains('spreadsheet') || mime.contains('excel')) {
      return Icons.table_chart_outlined;
    }
    if (mime.contains('document') || mime.contains('word')) {
      return Icons.description_outlined;
    }
    return Icons.insert_drive_file_outlined;
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

/// Paints a dashed rounded-rectangle border using [CustomPainter].
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.dashWidth,
    required this.dashGap,
    required this.strokeWidth,
  });

  final Color color;
  final double radius;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().first;
    final totalLength = metrics.length;

    double distance = 0;
    while (distance < totalLength) {
      final end = min(distance + dashWidth, totalLength);
      final extracted = metrics.extractPath(distance, end);
      canvas.drawPath(extracted, paint);
      distance = end + dashGap;
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashGap != dashGap ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
