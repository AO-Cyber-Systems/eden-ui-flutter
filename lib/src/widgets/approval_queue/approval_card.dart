import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../eden_approval_queue.dart';
import 'approval_filter_bar.dart';

// ---------------------------------------------------------------------------
// Approval card
// ---------------------------------------------------------------------------

class ApprovalCard extends StatelessWidget {
  const ApprovalCard({
    super.key,
    required this.item,
    required this.isDark,
    required this.theme,
    required this.isSelected,
    required this.showCheckbox,
    required this.onToggleSelect,
    this.onTap,
    this.onApprove,
    this.onReject,
    this.onRequestChanges,
  });

  final EdenApprovalItem item;
  final bool isDark;
  final ThemeData theme;
  final bool isSelected;
  final bool showCheckbox;
  final VoidCallback onToggleSelect;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onRequestChanges;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? EdenColors.neutral[850]! : Colors.white;
    final border = isSelected
        ? theme.colorScheme.primary.withValues(alpha: 0.5)
        : (isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!);
    final subtextColor = isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return Semantics(
      button: onTap != null,
      label: 'Approval item: ${item.title}',
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(EdenSpacing.space4),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.05) : cardBg,
            borderRadius: EdenRadii.borderRadiusLg,
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showCheckbox) ...[
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) => onToggleSelect(),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: EdenSpacing.space3),
                  ],
                  AvatarCircle(
                    initial: item.avatarInitial ?? (item.submittedBy.isNotEmpty ? item.submittedBy[0].toUpperCase() : '?'),
                    isDark: isDark,
                    theme: theme,
                  ),
                  const SizedBox(width: EdenSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? EdenColors.neutral[100] : EdenColors.neutral[900]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.subtitle != null)
                          Text(item.subtitle!, style: TextStyle(fontSize: 12, color: subtextColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: EdenSpacing.space2),
                  PriorityIndicator(priority: item.priority),
                  const SizedBox(width: EdenSpacing.space2),
                  StatusBadge(status: item.status, isDark: isDark),
                ],
              ),
              if (item.description != null) ...[
                const SizedBox(height: EdenSpacing.space3),
                Text(item.description!, style: TextStyle(fontSize: 13, color: subtextColor, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              if (item.metadata.isNotEmpty) ...[
                const SizedBox(height: EdenSpacing.space3),
                Wrap(
                  spacing: EdenSpacing.space3,
                  runSpacing: EdenSpacing.space1,
                  children: item.metadata.entries.map((e) => Text('${e.key}: ${e.value}', style: TextStyle(fontSize: 11, color: subtextColor))).toList(),
                ),
              ],
              const SizedBox(height: EdenSpacing.space3),
              Row(
                children: [
                  Text('by ${item.submittedBy}', style: TextStyle(fontSize: 11, color: subtextColor)),
                  const SizedBox(width: EdenSpacing.space2),
                  Text(_formatDate(item.submittedAt), style: TextStyle(fontSize: 11, color: subtextColor)),
                  const Spacer(),
                  if (item.status == EdenApprovalStatus.pending) ...[
                    if (onApprove != null)
                      SmallActionButton(label: 'Approve', icon: Icons.check, color: EdenColors.success, onTap: onApprove!),
                    if (onReject != null) ...[
                      const SizedBox(width: EdenSpacing.space2),
                      SmallActionButton(label: 'Reject', icon: Icons.close, color: EdenColors.error, onTap: onReject!),
                    ],
                    if (onRequestChanges != null) ...[
                      const SizedBox(width: EdenSpacing.space2),
                      SmallActionButton(label: 'Changes', icon: Icons.edit_outlined, color: EdenColors.info, onTap: onRequestChanges!),
                    ],
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}

// ---------------------------------------------------------------------------
// Avatar circle
// ---------------------------------------------------------------------------

class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.initial,
    required this.isDark,
    required this.theme,
  });

  final String initial;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: theme.colorScheme.primary, height: 1.0),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status badge
// ---------------------------------------------------------------------------

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    required this.isDark,
  });

  final EdenApprovalStatus status;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final resolved = _resolve();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: resolved.color.withValues(alpha: 0.1),
        borderRadius: EdenRadii.borderRadiusFull,
        border: Border.all(color: resolved.color.withValues(alpha: 0.25)),
      ),
      child: Text(resolved.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: resolved.color)),
    );
  }

  _ResolvedBadge _resolve() {
    switch (status) {
      case EdenApprovalStatus.pending: return const _ResolvedBadge(label: 'Pending', color: EdenColors.warning);
      case EdenApprovalStatus.approved: return const _ResolvedBadge(label: 'Approved', color: EdenColors.success);
      case EdenApprovalStatus.rejected: return const _ResolvedBadge(label: 'Rejected', color: EdenColors.error);
      case EdenApprovalStatus.changesRequested: return const _ResolvedBadge(label: 'Changes', color: EdenColors.info);
    }
  }
}

class _ResolvedBadge {
  const _ResolvedBadge({required this.label, required this.color});
  final String label;
  final Color color;
}

// ---------------------------------------------------------------------------
// Priority indicator
// ---------------------------------------------------------------------------

class PriorityIndicator extends StatelessWidget {
  const PriorityIndicator({super.key, required this.priority});

  final EdenApprovalPriority priority;

  @override
  Widget build(BuildContext context) {
    if (priority == EdenApprovalPriority.normal || priority == EdenApprovalPriority.low) {
      return const SizedBox.shrink();
    }
    final isUrgent = priority == EdenApprovalPriority.urgent;
    final color = isUrgent ? EdenColors.error : EdenColors.warning;
    return Tooltip(
      message: isUrgent ? 'Urgent' : 'High priority',
      child: Icon(isUrgent ? Icons.error : Icons.arrow_upward, size: 16, color: color),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    required this.icon,
    required this.isDark,
  });

  final String message;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: isDark ? EdenColors.neutral[600] : EdenColors.neutral[400]),
          const SizedBox(height: EdenSpacing.space4),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
