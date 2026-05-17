// EdenConditionNode — workflow boolean predicate diamond (donor ConditionNode.tsx).
//
// Amber rotated-diamond shape (140x140 outer bbox). Inner Transform.rotate
// container forms the visual diamond; counter-rotated content sits in a Stack
// overlay. Tap to open popover with Field text + Operator dropdown + Value
// text. Yes/No source handles distinguished by color (green/red) at the
// graph-builder layer.
//
// Parity rows N-4 / X-3.

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';

import '../../eden_diagram/diagram_data.dart';
import '../workflow_models.dart';

class EdenConditionNodeConfig {
  const EdenConditionNodeConfig({this.onUpdate, this.onDelete});

  /// Fires on Save with: `field`, `operator` (enum name), `value`, `label`
  /// (formatted "field op value" string).
  final ValueChanged<Map<String, dynamic>>? onUpdate;
  final VoidCallback? onDelete;
}

class EdenConditionNode extends StatefulWidget {
  const EdenConditionNode({
    super.key,
    required this.context,
    this.config = const EdenConditionNodeConfig(),
  });

  final EdenDiagramNodeContext context;
  final EdenConditionNodeConfig config;

  @override
  State<EdenConditionNode> createState() => _EdenConditionNodeState();
}

class _EdenConditionNodeState extends State<EdenConditionNode> {
  bool _hovered = false;

  bool get _isTouchPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String get _field => widget.context.node.data['field'] as String? ?? '';
  EdenWorkflowConditionOperator get _operator =>
      EdenWorkflowConditionOperator.values.firstWhere(
        (o) => o.name == widget.context.node.data['operator'],
        orElse: () => EdenWorkflowConditionOperator.equals,
      );
  dynamic get _value => widget.context.node.data['value'];

  String _operatorSymbol(EdenWorkflowConditionOperator op) => switch (op) {
        EdenWorkflowConditionOperator.equals => '=',
        EdenWorkflowConditionOperator.not_equals => '!=',
        EdenWorkflowConditionOperator.greater_than => '>',
        EdenWorkflowConditionOperator.less_than => '<',
        EdenWorkflowConditionOperator.contains => 'contains',
        EdenWorkflowConditionOperator.not_contains => '!contains',
      };

  String _label(
    String field,
    EdenWorkflowConditionOperator op,
    dynamic value,
  ) {
    if (field.isEmpty) return 'Configure...';
    return '$field ${_operatorSymbol(op)} ${value ?? ''}'.trim();
  }

  Future<void> _openEditor() async {
    final fieldCtrl = TextEditingController(text: _field);
    final valueCtrl = TextEditingController(text: _value?.toString() ?? '');
    var newOp = _operator;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (stateCtx, setStateLocal) => AlertDialog(
          title: const Text('Edit Condition'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Field',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: fieldCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g. priority, status, amount',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Operator',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<EdenWorkflowConditionOperator>(
                  initialValue: newOp,
                  isExpanded: true,
                  items: EdenWorkflowConditionOperator.values
                      .map(
                        (op) => DropdownMenuItem(
                          value: op,
                          child: Text(_operatorSymbol(op)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setStateLocal(() => newOp = v ?? newOp),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Value',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: valueCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g. high, completed, 5000',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
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
      ),
    );
    if (saved == true && fieldCtrl.text.trim().isNotEmpty) {
      final newField = fieldCtrl.text.trim();
      final newValue = valueCtrl.text;
      widget.config.onUpdate?.call({
        'field': newField,
        'operator': newOp.name,
        'value': newValue,
        'label': _label(newField, newOp, newValue),
      });
    }
    Future.delayed(const Duration(milliseconds: 400), () {
      fieldCtrl.dispose();
      valueCtrl.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = widget.context.selected;
    final isDropTarget = widget.context.dropTarget;
    final showDelete = _hovered || _isTouchPlatform;
    final label = _label(_field, _operator, _value);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: SizedBox(
        width: 140,
        height: 140,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Diamond shape — rotated 45°.
            Positioned.fill(
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    border: Border.all(
                      color: isDropTarget
                          ? theme.colorScheme.tertiary
                          : isSelected
                              ? theme.colorScheme.primary
                              : Colors.amber.shade400,
                      width: (isSelected || isDropTarget) ? 2.5 : 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 4,
                        color: Color(0x14000000),
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Content — non-rotated overlay.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openEditor,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.call_split,
                        size: 22,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'IF',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.amber.shade700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                        border:
                            Border.all(color: Colors.red.shade400, width: 1),
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
      ),
    );
  }
}
