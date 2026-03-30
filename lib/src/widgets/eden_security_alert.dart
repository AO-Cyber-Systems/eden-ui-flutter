import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// The type of security alert.
enum EdenSecurityAlertType {
  /// Alert from code scanning analysis.
  codeScan,

  /// Alert from secret scanning.
  secretScan,

  /// Alert from dependency vulnerability analysis.
  dependencyAlert,
}

/// The severity of a security alert.
enum EdenSecurityAlertSeverity {
  /// Critical severity.
  critical,

  /// High severity.
  high,

  /// Medium severity.
  medium,

  /// Low severity.
  low,
}

/// The lifecycle state of a security alert.
enum EdenSecurityAlertState {
  /// Alert is open and unresolved.
  open,

  /// Alert has been dismissed.
  dismissed,

  /// Alert has been fixed.
  fixed,
}

/// The reason for dismissing a security alert.
enum EdenSecurityDismissReason {
  /// The alert is a false positive.
  falsePositive,

  /// The flagged code is only used in tests.
  usedInTests,

  /// The team has decided not to fix this.
  wontFix,
}

/// A model representing a security alert finding.
class EdenSecurityAlertModel {
  /// Creates a security alert model.
  const EdenSecurityAlertModel({
    required this.id,
    required this.alertType,
    required this.title,
    required this.severity,
    this.filePath,
    this.lineRange,
    this.codeSnippet,
    this.state = EdenSecurityAlertState.open,
    this.dismissReason,
  });

  /// Unique identifier for the alert.
  final String id;

  /// The type of security alert.
  final EdenSecurityAlertType alertType;

  /// The alert title or summary.
  final String title;

  /// The severity level.
  final EdenSecurityAlertSeverity severity;

  /// The file path where the finding was detected.
  final String? filePath;

  /// The line range string (e.g. "42-48").
  final String? lineRange;

  /// A code snippet showing the finding context.
  final String? codeSnippet;

  /// The current state of this alert.
  final EdenSecurityAlertState state;

  /// The reason the alert was dismissed, if applicable.
  final EdenSecurityDismissReason? dismissReason;
}

/// A card widget displaying a security alert with type icon, severity badge,
/// file reference, optional code snippet, and state controls.
///
/// ```dart
/// EdenSecurityAlert(
///   alert: EdenSecurityAlertModel(
///     id: 'alert-1',
///     alertType: EdenSecurityAlertType.secretScan,
///     title: 'GitHub personal access token detected',
///     severity: EdenSecurityAlertSeverity.critical,
///     filePath: 'config/deploy.rb',
///     lineRange: '12-12',
///     codeSnippet: 'GITHUB_TOKEN = "ghp_xxxxxxxxxxxx"',
///   ),
///   onDismiss: (reason) {},
///   onFix: () {},
/// )
/// ```
class EdenSecurityAlert extends StatefulWidget {
  /// Creates an Eden security alert widget.
  const EdenSecurityAlert({
    super.key,
    required this.alert,
    this.onDismiss,
    this.onFix,
    this.onTap,
  });

  /// The security alert data to display.
  final EdenSecurityAlertModel alert;

  /// Callback when the alert is dismissed, with the selected reason.
  final ValueChanged<EdenSecurityDismissReason>? onDismiss;

  /// Callback when the fix action is triggered.
  final VoidCallback? onFix;

  /// Callback when the alert is tapped.
  final VoidCallback? onTap;

  @override
  State<EdenSecurityAlert> createState() => _EdenSecurityAlertState();
}

class _EdenSecurityAlertState extends State<EdenSecurityAlert> {
  bool _showDismissOptions = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final alert = widget.alert;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? EdenColors.neutral[900] : EdenColors.neutral[50],
          border: Border.all(
            color: isDark
                ? EdenColors.neutral[700]!
                : EdenColors.neutral[200]!,
          ),
          borderRadius: EdenRadii.borderRadiusLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(EdenSpacing.space4),
              child: Row(
                children: [
                  _AlertTypeIcon(alertType: alert.alertType),
                  const SizedBox(width: EdenSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                alert.title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: EdenSpacing.space2),
                            _SeverityBadge(severity: alert.severity),
                          ],
                        ),
                        if (alert.filePath != null) ...[
                          const SizedBox(height: EdenSpacing.space1),
                          _FileReference(
                            filePath: alert.filePath!,
                            lineRange: alert.lineRange,
                            isDark: isDark,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Code snippet
            if (alert.codeSnippet != null)
              _CodeSnippetBlock(
                snippet: alert.codeSnippet!,
                isDark: isDark,
              ),

            // State controls
            if (alert.state == EdenSecurityAlertState.open)
              _AlertActions(
                showDismissOptions: _showDismissOptions,
                onToggleDismiss: () => setState(
                  () => _showDismissOptions = !_showDismissOptions,
                ),
                onDismiss: widget.onDismiss,
                onFix: widget.onFix,
                isDark: isDark,
              )
            else
              _AlertStateBanner(
                state: alert.state,
                dismissReason: alert.dismissReason,
                isDark: isDark,
              ),
          ],
        ),
      ),
    );
  }
}

class _AlertTypeIcon extends StatelessWidget {
  const _AlertTypeIcon({required this.alertType});

  final EdenSecurityAlertType alertType;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (alertType) {
      EdenSecurityAlertType.codeScan => (
          Icons.code_rounded,
          EdenColors.purple[500]!,
        ),
      EdenSecurityAlertType.secretScan => (
          Icons.vpn_key_rounded,
          EdenColors.red[500]!,
        ),
      EdenSecurityAlertType.dependencyAlert => (
          Icons.inventory_2_rounded,
          EdenColors.warning,
        ),
    };

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: EdenRadii.borderRadiusMd,
      ),
      child: Center(
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity});

  final EdenSecurityAlertSeverity severity;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (severity) {
      EdenSecurityAlertSeverity.critical => (EdenColors.red[600]!, 'Critical'),
      EdenSecurityAlertSeverity.high => (EdenColors.red[400]!, 'High'),
      EdenSecurityAlertSeverity.medium => (EdenColors.warning, 'Medium'),
      EdenSecurityAlertSeverity.low => (EdenColors.info, 'Low'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: EdenRadii.borderRadiusFull,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _FileReference extends StatelessWidget {
  const _FileReference({
    required this.filePath,
    this.lineRange,
    required this.isDark,
  });

  final String filePath;
  final String? lineRange;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final lineInfo = lineRange != null ? ':$lineRange' : '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.insert_drive_file_outlined,
          size: 12,
          color: EdenColors.neutral[400],
        ),
        const SizedBox(width: EdenSpacing.space1),
        Flexible(
          child: Text(
            '$filePath$lineInfo',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: isDark
                  ? EdenColors.neutral[400]
                  : EdenColors.neutral[500],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _CodeSnippetBlock extends StatelessWidget {
  const _CodeSnippetBlock({
    required this.snippet,
    required this.isDark,
  });

  final String snippet;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: EdenSpacing.space4),
      padding: const EdgeInsets.all(EdenSpacing.space3),
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[950] : EdenColors.neutral[100],
        borderRadius: EdenRadii.borderRadiusMd,
      ),
      child: Text(
        snippet,
        style: TextStyle(
          fontSize: 12,
          fontFamily: 'monospace',
          color: isDark ? EdenColors.neutral[300] : EdenColors.neutral[700],
        ),
        maxLines: 6,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _AlertActions extends StatelessWidget {
  const _AlertActions({
    required this.showDismissOptions,
    required this.onToggleDismiss,
    this.onDismiss,
    this.onFix,
    required this.isDark,
  });

  final bool showDismissOptions;
  final VoidCallback onToggleDismiss;
  final ValueChanged<EdenSecurityDismissReason>? onDismiss;
  final VoidCallback? onFix;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(EdenSpacing.space3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onDismiss != null)
                _SmallButton(
                  label: 'Dismiss',
                  icon: Icons.visibility_off_rounded,
                  color: EdenColors.neutral[500]!,
                  onPressed: onToggleDismiss,
                ),
              if (onFix != null) ...[
                const SizedBox(width: EdenSpacing.space2),
                _SmallButton(
                  label: 'Fix',
                  icon: Icons.build_rounded,
                  color: EdenColors.success,
                  onPressed: onFix!,
                ),
              ],
            ],
          ),
        ),
        if (showDismissOptions && onDismiss != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space4,
              vertical: EdenSpacing.space3,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? EdenColors.neutral[800]!.withValues(alpha: 0.5)
                  : EdenColors.neutral[100],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(EdenRadii.lg),
                bottomRight: Radius.circular(EdenRadii.lg),
              ),
            ),
            child: Wrap(
              spacing: EdenSpacing.space2,
              runSpacing: EdenSpacing.space2,
              children: [
                _DismissReasonChip(
                  label: 'False positive',
                  reason: EdenSecurityDismissReason.falsePositive,
                  onTap: onDismiss!,
                ),
                _DismissReasonChip(
                  label: 'Used in tests',
                  reason: EdenSecurityDismissReason.usedInTests,
                  onTap: onDismiss!,
                ),
                _DismissReasonChip(
                  label: "Won't fix",
                  reason: EdenSecurityDismissReason.wontFix,
                  onTap: onDismiss!,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AlertStateBanner extends StatelessWidget {
  const _AlertStateBanner({
    required this.state,
    this.dismissReason,
    required this.isDark,
  });

  final EdenSecurityAlertState state;
  final EdenSecurityDismissReason? dismissReason;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (state) {
      EdenSecurityAlertState.fixed => (EdenColors.success, 'Fixed'),
      EdenSecurityAlertState.dismissed => (
          EdenColors.neutral[500]!,
          'Dismissed${_dismissReasonLabel()}',
        ),
      EdenSecurityAlertState.open => (EdenColors.error, 'Open'),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(EdenRadii.lg),
          bottomRight: Radius.circular(EdenRadii.lg),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            state == EdenSecurityAlertState.fixed
                ? Icons.check_circle_rounded
                : Icons.remove_circle_outline_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: EdenSpacing.space2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _dismissReasonLabel() {
    if (dismissReason == null) return '';
    return switch (dismissReason!) {
      EdenSecurityDismissReason.falsePositive => ' — False positive',
      EdenSecurityDismissReason.usedInTests => ' — Used in tests',
      EdenSecurityDismissReason.wontFix => " — Won't fix",
    };
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: EdenRadii.borderRadiusSm,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space2,
          vertical: EdenSpacing.space1,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: EdenRadii.borderRadiusSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: EdenSpacing.space1),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DismissReasonChip extends StatelessWidget {
  const _DismissReasonChip({
    required this.label,
    required this.reason,
    required this.onTap,
  });

  final String label;
  final EdenSecurityDismissReason reason;
  final ValueChanged<EdenSecurityDismissReason> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => onTap(reason),
      borderRadius: EdenRadii.borderRadiusFull,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space3,
          vertical: EdenSpacing.space1,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark
                ? EdenColors.neutral[600]!
                : EdenColors.neutral[300]!,
          ),
          borderRadius: EdenRadii.borderRadiusFull,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark
                ? EdenColors.neutral[300]
                : EdenColors.neutral[600],
          ),
        ),
      ),
    );
  }
}
