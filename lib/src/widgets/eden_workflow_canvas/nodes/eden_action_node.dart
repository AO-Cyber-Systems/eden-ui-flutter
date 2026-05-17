// EdenActionNode — workflow action outcome card (donor ActionNode.tsx parity).
//
// Blue-themed card (180-220pt min/max width). Tap to open popover editor
// with action-type select + dynamic per-action-type config-field grid.
// Hover-shown delete button (always visible on touch platforms).
//
// Parity rows N-2 / X-2.

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';

import '../../eden_diagram/diagram_data.dart';
import '../workflow_action_field_spec.dart';
import '../workflow_action_registry.dart';

/// Config object for the action node — callbacks + per-node config.
/// Mirrors `EdenTriggerNodeConfig` / obj 006 `EdenProcessNodeRendererConfig`.
class EdenActionNodeConfig {
  const EdenActionNodeConfig({this.onUpdate, this.onDelete});

  /// Fires when the popover Save button is tapped. Map carries:
  /// `actionType` (String, registry id), `config` (`Map<String, dynamic>`),
  /// `label` (String, registry displayName).
  final ValueChanged<Map<String, dynamic>>? onUpdate;

  /// Fires when the delete button is tapped.
  final VoidCallback? onDelete;
}

class EdenActionNode extends StatefulWidget {
  const EdenActionNode({
    super.key,
    required this.context,
    this.config = const EdenActionNodeConfig(),
  });

  final EdenDiagramNodeContext context;
  final EdenActionNodeConfig config;

  @override
  State<EdenActionNode> createState() => _EdenActionNodeState();
}

class _EdenActionNodeState extends State<EdenActionNode> {
  bool _hovered = false;

  bool get _isTouchPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String get _actionType =>
      widget.context.node.data['actionType'] as String? ?? 'create_task';

  Map<String, dynamic> get _config =>
      (widget.context.node.data['config'] as Map?)?.cast<String, dynamic>() ??
      const <String, dynamic>{};

  String _configSummary(String actionType, Map<String, dynamic> config) =>
      switch (actionType) {
        'create_task' => config['title'] as String? ?? '',
        'send_notification' => config['title'] as String? ?? '',
        'create_callback' => config['reason'] as String? ?? '',
        'update_status' =>
          config['newStatus'] != null ? '→ ${config['newStatus']}' : '',
        'send_email' => config['to'] as String? ?? '',
        'send_sms' => config['phoneNumber'] as String? ?? '',
        _ => '',
      };

  Future<void> _openEditor() async {
    var newType = _actionType;
    final newConfig = Map<String, dynamic>.from(_config);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (stateCtx, setStateLocal) {
            final typeMeta =
                EdenWorkflowActionRegistry.instance.lookup(newType);
            final fields = typeMeta?.fields ?? const [];
            return AlertDialog(
              title: const Text('Edit Action'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400, maxWidth: 320),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Action Type',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: newType,
                        isExpanded: true,
                        items: EdenWorkflowActionRegistry.instance
                            .all()
                            .map(
                              (a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(a.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setStateLocal(() {
                            newType = v ?? newType;
                            // Reset config when action type changes
                            newConfig.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      ...fields.map(
                        (spec) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildFieldEditor(
                            spec,
                            newConfig,
                            setStateLocal,
                          ),
                        ),
                      ),
                    ],
                  ),
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
            );
          },
        );
      },
    );
    if (saved == true) {
      final meta = EdenWorkflowActionRegistry.instance.lookup(newType);
      widget.config.onUpdate?.call({
        'actionType': newType,
        'config': Map<String, dynamic>.from(newConfig),
        'label': meta?.displayName ?? newType,
      });
    }
  }

  Widget _buildFieldEditor(
    EdenWorkflowActionFieldSpec spec,
    Map<String, dynamic> editingConfig,
    StateSetter setStateLocal,
  ) {
    final currentValue = editingConfig[spec.id] as String?;
    if (spec.type == 'select') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            spec.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: spec.options.any((o) => o.value == currentValue)
                ? currentValue
                : null,
            isExpanded: true,
            items: spec.options
                .map(
                  (o) => DropdownMenuItem(
                    value: o.value,
                    child: Text(o.label),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setStateLocal(() => editingConfig[spec.id] = v);
              }
            },
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          spec.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: currentValue ?? '',
          maxLines: spec.type == 'textarea' ? 3 : 1,
          keyboardType: spec.type == 'number'
              ? TextInputType.number
              : (spec.type == 'textarea'
                  ? TextInputType.multiline
                  : TextInputType.text),
          decoration: InputDecoration(
            hintText: spec.placeholder,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
          onChanged: (v) => setStateLocal(() => editingConfig[spec.id] = v),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionType = _actionType;
    final meta = EdenWorkflowActionRegistry.instance.lookup(actionType);
    final summary = _configSummary(actionType, _config);
    final isSelected = widget.context.selected;
    final isDropTarget = widget.context.dropTarget;
    final showDelete = _hovered || _isTouchPlatform;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openEditor,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(minWidth: 180, maxWidth: 220),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50, // donor color
                  border: Border.all(
                    color: isDropTarget
                        ? theme.colorScheme.tertiary
                        : isSelected
                            ? theme.colorScheme.primary
                            : Colors.blue.shade400, // donor color
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
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        meta?.icon ?? Icons.bolt,
                        size: 16,
                        color: Colors.blue.shade700, // donor color
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACTION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue.shade700, // donor color
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            meta?.displayName ?? actionType,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (summary.isNotEmpty)
                            Text(
                              summary,
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
          ),
          // Delete button — top-right, hover-show on desktop, always on touch.
          if (showDelete && widget.config.onDelete != null)
            Positioned(
              top: -8,
              right: -8,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: widget.config.onDelete,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade400, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      size: 14,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
