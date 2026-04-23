import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A card displaying Terraform state information for an infrastructure workspace.
class EdenTerraformStateCard extends StatefulWidget {
  const EdenTerraformStateCard({
    super.key,
    required this.name,
    this.resourceCount = 0,
    this.lastAppliedAt,
    this.stateVersion,
    this.isLocked = false,
    this.lockedBy,
    this.planSummary,
    this.onTap,
    this.onUnlock,
    this.onViewPlan,
  });

  final String name;
  final int resourceCount;
  final String? lastAppliedAt;
  final int? stateVersion;
  final bool isLocked;
  final String? lockedBy;
  final String? planSummary;
  final VoidCallback? onTap;
  final VoidCallback? onUnlock;
  final VoidCallback? onViewPlan;

  @override
  State<EdenTerraformStateCard> createState() => _EdenTerraformStateCardState();
}

class _EdenTerraformStateCardState extends State<EdenTerraformStateCard> {
  bool _planExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        decoration: BoxDecoration(
          color: isDark ? EdenColors.neutral[850] : Colors.white,
          borderRadius: EdenRadii.borderRadiusLg,
          border: Border.all(
            color: widget.isLocked
                ? EdenColors.warning.withValues(alpha: 0.5)
                : (isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.cloud_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: EdenSpacing.space2),
                Expanded(
                  child: Text(
                    widget.name,
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Resource count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: EdenRadii.borderRadiusFull,
                  ),
                  child: Text(
                    '${widget.resourceCount} resources',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: EdenSpacing.space3),

            // Lock status
            if (widget.isLocked) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space3,
                  vertical: EdenSpacing.space2,
                ),
                decoration: BoxDecoration(
                  color: EdenColors.warning.withValues(alpha: 0.1),
                  borderRadius: EdenRadii.borderRadiusMd,
                  border: Border.all(color: EdenColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outlined, size: 16, color: EdenColors.warning),
                    const SizedBox(width: EdenSpacing.space2),
                    Expanded(
                      child: Text(
                        widget.lockedBy != null
                            ? 'Locked by ${widget.lockedBy}'
                            : 'State is locked',
                        style: const TextStyle(
                          fontSize: 12,
                          color: EdenColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (widget.onUnlock != null)
                      GestureDetector(
                        onTap: widget.onUnlock,
                        child: const Text(
                          'Unlock',
                          style: TextStyle(
                            fontSize: 12,
                            color: EdenColors.warning,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: EdenSpacing.space3),
            ],

            // Metadata row
            Row(
              children: [
                if (widget.lastAppliedAt != null) ...[
                  Icon(Icons.access_time, size: 14,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    widget.lastAppliedAt!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: EdenSpacing.space4),
                ],
                if (widget.stateVersion != null) ...[
                  Icon(Icons.history, size: 14,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'v${widget.stateVersion}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),

            // Plan summary (collapsible)
            if (widget.planSummary != null) ...[
              const SizedBox(height: EdenSpacing.space3),
              GestureDetector(
                onTap: () => setState(() => _planExpanded = !_planExpanded),
                child: Row(
                  children: [
                    Icon(
                      _planExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Plan output',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    if (widget.onViewPlan != null)
                      GestureDetector(
                        onTap: widget.onViewPlan,
                        child: Text(
                          'View full plan',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (_planExpanded) ...[
                const SizedBox(height: EdenSpacing.space2),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(EdenSpacing.space3),
                  decoration: BoxDecoration(
                    color: isDark ? EdenColors.neutral[900] : EdenColors.neutral[50],
                    borderRadius: EdenRadii.borderRadiusMd,
                  ),
                  child: Text(
                    widget.planSummary!,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
