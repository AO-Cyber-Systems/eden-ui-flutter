import 'package:flutter/material.dart';

import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A node in an [EdenHierarchyTree].
///
/// Supports up to N levels of nesting via [children]. Each node has a label,
/// optional color swatch, optional tag/badge, and action callbacks.
class EdenHierarchyNode {
  const EdenHierarchyNode({
    required this.id,
    required this.label,
    this.children = const [],
    this.color,
    this.tag,
    this.subtitle,
    this.icon,
    this.onEdit,
    this.onDelete,
    this.onAdd,
    this.addLabel,
    this.trailing,
  });

  /// Unique identifier for expansion state tracking.
  final String id;

  /// Display label for this node.
  final String label;

  /// Child nodes (next level in the hierarchy).
  final List<EdenHierarchyNode> children;

  /// Optional color swatch shown as a small square next to the label.
  final Color? color;

  /// Optional tag text (e.g., "System", "Default") shown as a small badge.
  final String? tag;

  /// Optional subtitle shown after the children count.
  final String? subtitle;

  /// Optional icon shown before the label (used for leaf nodes).
  final IconData? icon;

  /// Called when the edit action is triggered. If null, edit button is hidden.
  final VoidCallback? onEdit;

  /// Called when the delete action is triggered. If null, delete button is hidden.
  final VoidCallback? onDelete;

  /// Called when the add-child action is triggered. If null, add button is hidden.
  final VoidCallback? onAdd;

  /// Label for the add-child button (e.g., "Type", "Sub-type").
  final String? addLabel;

  /// Optional trailing widget (replaces edit/delete/add buttons).
  final Widget? trailing;
}

/// N-level expandable hierarchy tree with color swatches, inline actions,
/// and visual nesting indicators.
///
/// Supports arbitrary depth. Level 0 nodes render as section headers with
/// a colored background. Deeper levels indent progressively with a colored
/// left border that fades with depth.
///
/// ```dart
/// EdenHierarchyTree(
///   nodes: [
///     EdenHierarchyNode(
///       id: '1',
///       label: 'Service',
///       color: Colors.blue,
///       onAdd: () => addType(),
///       addLabel: 'Type',
///       children: [
///         EdenHierarchyNode(
///           id: '1-1',
///           label: 'HVAC',
///           onEdit: () => editType(),
///           children: [
///             EdenHierarchyNode(id: '1-1-1', label: 'Install', onEdit: () {}),
///             EdenHierarchyNode(id: '1-1-2', label: 'Repair', onEdit: () {}),
///           ],
///         ),
///       ],
///     ),
///   ],
/// )
/// ```
class EdenHierarchyTree extends StatefulWidget {
  const EdenHierarchyTree({
    super.key,
    required this.nodes,
    this.expandAllByDefault = true,
  });

  /// Top-level nodes in the tree.
  final List<EdenHierarchyNode> nodes;

  /// Whether all top-level nodes are expanded by default.
  final bool expandAllByDefault;

  @override
  State<EdenHierarchyTree> createState() => _EdenHierarchyTreeState();
}

class _EdenHierarchyTreeState extends State<EdenHierarchyTree> {
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    if (widget.expandAllByDefault) {
      for (final node in widget.nodes) {
        _expanded.add(node.id);
      }
    }
  }

  void _toggle(String id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.nodes
          .map((node) => _buildSection(node))
          .toList(),
    );
  }

  /// Level 0: section header with colored background.
  Widget _buildSection(EdenHierarchyNode node) {
    final theme = Theme.of(context);
    final isExpanded = _expanded.contains(node.id);

    return Container(
      margin: const EdgeInsets.only(bottom: EdenSpacing.space3),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: EdenRadii.borderRadiusMd,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header row
          GestureDetector(
            onTap: () => _toggle(node.id),
            child: Container(
              color: theme.colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(
                horizontal: EdenSpacing.space4,
                vertical: EdenSpacing.space3,
              ),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  if (node.color != null) ...[
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: node.color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          node.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (node.tag != null) ...[
                          const SizedBox(width: 8),
                          _TagBadge(label: node.tag!),
                        ],
                        if (node.children.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${node.children.length} ${node.subtitle ?? 'items'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (node.trailing != null)
                    node.trailing!
                  else ...[
                    if (node.onAdd != null)
                      TextButton.icon(
                        onPressed: node.onAdd,
                        icon: const Icon(Icons.add, size: 14),
                        label: Text(node.addLabel ?? 'Add'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          textStyle: const TextStyle(fontSize: 11),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          // Children (when expanded)
          if (isExpanded)
            ...node.children.map((child) => _buildRow(child, node.color, 1)),
        ],
      ),
    );
  }

  /// Level 1+: indented rows with colored left border.
  Widget _buildRow(EdenHierarchyNode node, Color? parentColor, int depth) {
    final theme = Theme.of(context);
    final isExpanded = _expanded.contains(node.id);
    final hasChildren = node.children.isNotEmpty;
    final borderColor = parentColor ?? theme.colorScheme.outlineVariant;
    final borderAlpha = depth <= 1 ? 1.0 : 0.4;
    final leftPadding = 24.0 + (depth * 16.0);
    final iconSize = depth <= 1 ? 14.0 : 12.0;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: borderColor.withValues(alpha: borderAlpha),
                width: 3,
              ),
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(
                  alpha: depth <= 1 ? 0.5 : 0.3,
                ),
              ),
            ),
          ),
          padding: EdgeInsets.only(
            left: leftPadding,
            right: EdenSpacing.space4,
            top: depth <= 1 ? 10 : 8,
            bottom: depth <= 1 ? 10 : 8,
          ),
          child: Row(
            children: [
              if (hasChildren)
                GestureDetector(
                  onTap: () => _toggle(node.id),
                  child: Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else if (node.icon != null)
                Icon(node.icon, size: iconSize,
                    color: theme.colorScheme.onSurfaceVariant)
              else
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      node.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: depth <= 1 ? FontWeight.w500 : null,
                        fontSize: depth <= 1 ? null : 12,
                        color: depth > 1
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                    if (node.tag != null) ...[
                      const SizedBox(width: 8),
                      _TagBadge(label: node.tag!),
                    ],
                    if (hasChildren) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${node.children.length} ${node.subtitle ?? 'items'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (node.trailing != null)
                node.trailing!
              else ...[
                if (node.onEdit != null)
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: iconSize),
                    onPressed: node.onEdit,
                    tooltip: 'Edit',
                    constraints: BoxConstraints(
                      minWidth: iconSize + 14,
                      minHeight: iconSize + 14,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                if (node.onDelete != null)
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: iconSize, color: theme.colorScheme.error),
                    onPressed: node.onDelete,
                    tooltip: 'Delete',
                    constraints: BoxConstraints(
                      minWidth: iconSize + 14,
                      minHeight: iconSize + 14,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                if (node.onAdd != null)
                  TextButton.icon(
                    onPressed: node.onAdd,
                    icon: const Icon(Icons.add, size: 12),
                    label: Text(node.addLabel ?? 'Add'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      textStyle: const TextStyle(fontSize: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ],
          ),
        ),
        if (isExpanded)
          ...node.children.map((child) => _buildRow(child, parentColor, depth + 1)),
      ],
    );
  }
}

class _TagBadge extends StatelessWidget {
  const _TagBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 9,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
