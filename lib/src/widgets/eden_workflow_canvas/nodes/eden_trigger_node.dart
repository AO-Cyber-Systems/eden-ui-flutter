// EdenTriggerNode — workflow entry-point card (donor TriggerNode.tsx parity).
//
// Green-themed card (180-220pt min/max width). Tap anywhere to open an
// inline popover editor for triggerType + category. No delete button —
// Trigger is uniquely required.
//
// Composed inside `EdenDiagram` via the customNodeRenderer slot. Reads
// triggerType / category from `ctx.node.data`; fires updates via the
// `EdenTriggerNodeConfig.onUpdate` callback (mirrors obj 006
// `EdenProcessDecisionNode` config pattern — `EdenDiagramNodeContext`
// itself has no callbacks).
//
// Parity rows N-1 / X-1 / E-5.

import 'package:flutter/material.dart';

import '../../eden_diagram/diagram_data.dart';
import '../workflow_category_registry.dart';
import '../workflow_models.dart';

/// Config object passed alongside `EdenDiagramNodeContext` for the trigger
/// node renderer. Mirrors obj 006 `EdenProcessNodeRendererConfig` shape.
class EdenTriggerNodeConfig {
  const EdenTriggerNodeConfig({this.onUpdate});

  /// Fires when the user saves the popover editor. The map carries the new
  /// `triggerType` (enum name) and `category` (registry id) — consumer maps
  /// these back onto the `EdenDiagramNode.data` slot.
  final ValueChanged<Map<String, dynamic>>? onUpdate;
}

class EdenTriggerNode extends StatefulWidget {
  const EdenTriggerNode({
    super.key,
    required this.context,
    this.config = const EdenTriggerNodeConfig(),
  });

  final EdenDiagramNodeContext context;
  final EdenTriggerNodeConfig config;

  @override
  State<EdenTriggerNode> createState() => _EdenTriggerNodeState();
}

class _EdenTriggerNodeState extends State<EdenTriggerNode> {
  EdenWorkflowTriggerType get _triggerType {
    final raw = widget.context.node.data['triggerType'] as String?;
    return EdenWorkflowTriggerType.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => EdenWorkflowTriggerType.manual,
    );
  }

  String get _category =>
      widget.context.node.data['category'] as String? ?? 'appointment';

  IconData _icon(EdenWorkflowTriggerType type) => switch (type) {
        EdenWorkflowTriggerType.scheduled => Icons.calendar_today,
        EdenWorkflowTriggerType.completed => Icons.check_circle_outline,
        EdenWorkflowTriggerType.status_change => Icons.refresh,
        EdenWorkflowTriggerType.time_based => Icons.access_time,
        EdenWorkflowTriggerType.manual => Icons.touch_app,
        EdenWorkflowTriggerType.entity_created => Icons.bolt,
      };

  String _label(EdenWorkflowTriggerType type) => switch (type) {
        EdenWorkflowTriggerType.scheduled => 'On Schedule',
        EdenWorkflowTriggerType.completed => 'On Completion',
        EdenWorkflowTriggerType.status_change => 'Status Change',
        EdenWorkflowTriggerType.time_based => 'Time-Based',
        EdenWorkflowTriggerType.manual => 'Manual',
        EdenWorkflowTriggerType.entity_created => 'Entity Created',
      };

  Future<void> _openEditor() async {
    var newType = _triggerType;
    var newCategory = _category;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (stateCtx, setStateLocal) => AlertDialog(
            title: const Text('Edit Trigger'),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trigger Type',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<EdenWorkflowTriggerType>(
                    initialValue: newType,
                    isExpanded: true,
                    items: EdenWorkflowTriggerType.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(_label(t)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setStateLocal(() => newType = v ?? newType),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: newCategory,
                    isExpanded: true,
                    items: EdenWorkflowCategoryRegistry.instance
                        .all()
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setStateLocal(() => newCategory = v ?? newCategory),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
    if (saved == true) {
      widget.config.onUpdate?.call({
        'triggerType': newType.name,
        'category': newCategory,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final triggerType = _triggerType;
    final category = EdenWorkflowCategoryRegistry.instance.lookup(_category);
    final isSelected = widget.context.selected;
    final isDropTarget = widget.context.dropTarget;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openEditor,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minWidth: 180, maxWidth: 220),
          decoration: BoxDecoration(
            color: Colors.green.shade50, // donor color
            border: Border.all(
              color: isDropTarget
                  ? theme.colorScheme.tertiary
                  : isSelected
                      ? theme.colorScheme.primary
                      : Colors.green.shade400, // donor color
              width: (isSelected || isDropTarget) ? 2.5 : 2,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                blurRadius: 6,
                color: Color(0x14000000),
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.shade100, // donor color
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _icon(triggerType),
                  size: 16,
                  color: Colors.green.shade700, // donor color
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRIGGER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade700, // donor color
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      _label(triggerType),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      category?.displayName ?? _category,
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
