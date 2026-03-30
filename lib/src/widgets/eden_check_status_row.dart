import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// The status of a CI/CD check or status check.
enum EdenCheckStatus {
  /// Check completed successfully.
  passed,

  /// Check completed with a failure.
  failed,

  /// Check is waiting to run.
  pending,

  /// Check is currently running.
  running,
}

/// A compact row displaying a CI/CD check or status check with its result,
/// description, duration, and a link to details.
///
/// Running checks display an animated spinner icon.
///
/// ```dart
/// EdenCheckStatusRow(
///   name: 'lint / eslint',
///   status: EdenCheckStatus.passed,
///   description: 'All checks passed',
///   duration: Duration(seconds: 45),
///   onDetailsTap: () => openUrl('https://ci.example.com/checks/1'),
/// )
/// ```
class EdenCheckStatusRow extends StatefulWidget {
  /// Creates a check status row widget.
  const EdenCheckStatusRow({
    super.key,
    required this.name,
    required this.status,
    this.description,
    this.duration,
    this.detailsUrl,
    this.onDetailsTap,
  });

  /// The name of the check.
  final String name;

  /// Current status of the check.
  final EdenCheckStatus status;

  /// Optional description of the check result.
  final String? description;

  /// Duration the check took to run.
  final Duration? duration;

  /// URL to the check details page.
  final String? detailsUrl;

  /// Called when the "Details" link is tapped.
  final VoidCallback? onDetailsTap;

  @override
  State<EdenCheckStatusRow> createState() => _EdenCheckStatusRowState();
}

class _EdenCheckStatusRowState extends State<EdenCheckStatusRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinnerController;

  @override
  void initState() {
    super.initState();
    _spinnerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.status == EdenCheckStatus.running) {
      _spinnerController.repeat();
    }
  }

  @override
  void didUpdateWidget(EdenCheckStatusRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == EdenCheckStatus.running &&
        oldWidget.status != EdenCheckStatus.running) {
      _spinnerController.repeat();
    } else if (widget.status != EdenCheckStatus.running &&
        oldWidget.status == EdenCheckStatus.running) {
      _spinnerController.stop();
      _spinnerController.reset();
    }
  }

  @override
  void dispose() {
    _spinnerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space3,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? EdenColors.neutral[800]!
                : EdenColors.neutral[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildStatusIcon(),
          const SizedBox(width: EdenSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? EdenColors.neutral[100]
                        : EdenColors.neutral[900],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.description != null) ...[
                  const SizedBox(height: EdenSpacing.space1),
                  Text(
                    widget.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: EdenColors.neutral[500],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (widget.duration != null) ...[
            const SizedBox(width: EdenSpacing.space2),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: EdenSpacing.space2,
                vertical: EdenSpacing.space1,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? EdenColors.neutral[800]
                    : EdenColors.neutral[100],
                borderRadius: EdenRadii.borderRadiusSm,
              ),
              child: Text(
                _formatDuration(widget.duration!),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  color: EdenColors.neutral[500],
                ),
              ),
            ),
          ],
          if (widget.onDetailsTap != null) ...[
            const SizedBox(width: EdenSpacing.space3),
            TextButton(
              onPressed: widget.onDetailsTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space2,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Details',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    final statusColor = _statusColor(widget.status);

    switch (widget.status) {
      case EdenCheckStatus.running:
        return SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: statusColor,
          ),
        );
      case EdenCheckStatus.passed:
        return Icon(Icons.check_circle, size: 18, color: statusColor);
      case EdenCheckStatus.failed:
        return Icon(Icons.cancel, size: 18, color: statusColor);
      case EdenCheckStatus.pending:
        return Icon(Icons.circle_outlined, size: 18, color: statusColor);
    }
  }

  Color _statusColor(EdenCheckStatus status) {
    switch (status) {
      case EdenCheckStatus.passed:
        return EdenColors.success;
      case EdenCheckStatus.failed:
        return EdenColors.error;
      case EdenCheckStatus.running:
        return EdenColors.info;
      case EdenCheckStatus.pending:
        return EdenColors.neutral[400]!;
    }
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    }
    return '${d.inSeconds}s';
  }
}
