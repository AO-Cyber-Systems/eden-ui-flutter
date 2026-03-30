import 'package:flutter/material.dart';

import '../tokens/radii.dart';
import '../tokens/spacing.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

/// A classification level in an approval flow.
class EdenApprovalLevel {
  const EdenApprovalLevel({
    required this.id,
    required this.label,
    required this.color,
    required this.icon,
    this.requiresApproval = false,
    this.approverRole,
    this.timeoutMinutes = 60,
  });

  final String id;
  final String label;
  final Color color;
  final IconData icon;
  final bool requiresApproval;
  final String? approverRole;
  final int timeoutMinutes;
}

/// Callback data when an approval level is changed.
class EdenApprovalChange {
  const EdenApprovalChange({
    required this.levelId,
    this.requiresApproval,
    this.approverRole,
    this.timeoutMinutes,
  });

  final String levelId;
  final bool? requiresApproval;
  final String? approverRole;
  final int? timeoutMinutes;
}

// ---------------------------------------------------------------------------
// Main widget
// ---------------------------------------------------------------------------

/// Per-classification approval flow editor with toggles, role dropdowns,
/// and timeout inputs.
///
/// Each [EdenApprovalLevel] renders as a row with a classification badge,
/// an approval toggle, and (when enabled) an approver role dropdown +
/// timeout field. Generic enough for any classification/tier system.
///
/// ```dart
/// EdenApprovalFlow(
///   title: 'Approval Configuration',
///   description: 'Configure which levels require approval.',
///   levels: [
///     EdenApprovalLevel(id: 'safe', label: 'Safe', color: Colors.green, icon: Icons.check_circle),
///     EdenApprovalLevel(id: 'destructive', label: 'Destructive', color: Colors.red, icon: Icons.warning, requiresApproval: true, approverRole: 'admin'),
///   ],
///   roles: ['any', 'manager', 'admin'],
///   onChanged: (change) => handleChange(change),
/// )
/// ```
class EdenApprovalFlow extends StatelessWidget {
  const EdenApprovalFlow({
    super.key,
    required this.levels,
    required this.roles,
    required this.onChanged,
    this.title,
    this.description,
    this.onSave,
    this.saveLabel = 'Save',
  });

  /// Classification levels to display as rows.
  final List<EdenApprovalLevel> levels;

  /// Available approver roles for the dropdown.
  final List<String> roles;

  /// Called when any value in a row changes.
  final ValueChanged<EdenApprovalChange> onChanged;

  /// Optional title above the rows.
  final String? title;

  /// Optional description below the title.
  final String? description;

  /// If provided, a save button is shown at the bottom.
  final VoidCallback? onSave;

  /// Label for the save button.
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(EdenSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(
              description!,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (title != null || description != null)
            const SizedBox(height: EdenSpacing.space4),
          Expanded(
            child: ListView(
              children: levels
                  .map((level) => _LevelRow(
                        level: level,
                        roles: roles,
                        onChanged: onChanged,
                      ))
                  .toList(),
            ),
          ),
          if (onSave != null)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onSave,
                child: Text(saveLabel),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Level row
// ---------------------------------------------------------------------------

class _LevelRow extends StatelessWidget {
  const _LevelRow({
    required this.level,
    required this.roles,
    required this.onChanged,
  });

  final EdenApprovalLevel level;
  final List<String> roles;
  final ValueChanged<EdenApprovalChange> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: EdenSpacing.space3),
      padding: const EdgeInsets.all(EdenSpacing.space3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: EdenRadii.borderRadiusMd,
      ),
      child: Row(
        children: [
          // Classification badge
          Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: level.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(level.icon, size: 14, color: level.color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    level.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: level.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: EdenSpacing.space4),

          // Approval toggle
          Switch(
            value: level.requiresApproval,
            onChanged: (v) => onChanged(EdenApprovalChange(
              levelId: level.id,
              requiresApproval: v,
            )),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Text(
            'Requires Approval',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: EdenSpacing.space4),

          // Conditional: role dropdown + timeout
          if (level.requiresApproval) ...[
            SizedBox(
              width: 120,
              height: 30,
              child: DropdownButtonFormField<String>(
                initialValue: level.approverRole ?? roles.first,
                items: roles
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                            r[0].toUpperCase() + r.substring(1),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    onChanged(EdenApprovalChange(
                      levelId: level.id,
                      approverRole: v,
                    ));
                  }
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8),
                  isDense: true,
                ),
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: EdenSpacing.space3),
            SizedBox(
              width: 80,
              height: 30,
              child: TextFormField(
                initialValue: level.timeoutMinutes.toString(),
                decoration: InputDecoration(
                  suffixText: 'min',
                  suffixStyle: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 11),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final parsed = int.tryParse(v);
                  if (parsed != null) {
                    onChanged(EdenApprovalChange(
                      levelId: level.id,
                      timeoutMinutes: parsed,
                    ));
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
