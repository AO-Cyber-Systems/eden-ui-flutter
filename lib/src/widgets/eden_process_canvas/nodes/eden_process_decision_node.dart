import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../eden_diagram/eden_diagram_exports.dart';
import 'eden_process_node_renderer.dart';

/// Process-flow Decision node — parity row N-6.
///
/// 140×140 rotated-diamond shape. The diamond visual is a `Transform.rotate`
/// of a square; content (icon + name + condition) sits in a non-rotated
/// overlay so text stays upright.
///
/// **Ports** are emitted by `EdenProcessGraphBuilder.build()` directly on
/// the `EdenDiagramNode.ports` list (4 ports: top + left targets, yes +
/// no sources with green/red colors). The canvas engine (TRD 006-02)
/// renders the port dots; this widget renders only the diamond + content.
///
/// **Inline edit** opens an `AlertDialog` with two `TextField` rows (name +
/// condition). Saving with an empty name silently cancels (donor parity).
class EdenProcessDecisionNode extends StatefulWidget {
  const EdenProcessDecisionNode({
    super.key,
    required this.context,
    required this.config,
  });

  final EdenDiagramNodeContext context;
  final EdenProcessNodeRendererConfig config;

  @override
  State<EdenProcessDecisionNode> createState() =>
      _EdenProcessDecisionNodeState();
}

class _EdenProcessDecisionNodeState extends State<EdenProcessDecisionNode> {
  bool _hovered = false;

  int get _decisionId => widget.context.node.data['decisionId'] as int;

  Future<void> _openEditDialog() async {
    final decision = widget.config.decisionsById[_decisionId];
    if (decision == null) return;
    final nameCtrl = TextEditingController(text: decision.name);
    final condCtrl = TextEditingController(text: decision.condition);
    final result = await showDialog<({String name, String condition})>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Decision'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Decision Name',
                  hintText: 'e.g. Approval Required?',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: condCtrl,
                decoration: const InputDecoration(
                  labelText: 'Condition (optional)',
                  hintText: 'e.g. cost > 5000',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final trimmedName = nameCtrl.text.trim();
              if (trimmedName.isEmpty) {
                Navigator.pop(ctx);
                return;
              }
              Navigator.pop(
                ctx,
                (name: trimmedName, condition: condCtrl.text.trim()),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      widget.config.onUpdateDecision?.call(
        _decisionId,
        {'name': result.name, 'condition': result.condition},
      );
    }
    // Defer controller disposal until the dialog's exit animation finishes
    // — otherwise the still-mounted TextField subtree tries to read disposed
    // controllers during the close transition.
    Future.delayed(const Duration(milliseconds: 400), () {
      nameCtrl.dispose();
      condCtrl.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final decision = widget.config.decisionsById[_decisionId];
    if (decision == null) {
      return _MissingDecisionFallback(decisionId: _decisionId);
    }

    final theme = Theme.of(context);
    final isSelected = widget.context.selected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Diamond background — rotated square.
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.amber.shade300,
                  width: isSelected ? 2 : 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Content — non-rotated overlay.
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openEditDialog,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.call_split,
                      size: 22,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      decision.name,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    if (decision.condition.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          decision.condition,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.amber.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Delete button — top-right, hover-show.
          Positioned(
            top: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _hovered ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 120),
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 14),
                color: theme.colorScheme.error,
                tooltip: 'Delete',
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    widget.config.onDeleteDecision?.call(_decisionId),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingDecisionFallback extends StatelessWidget {
  const _MissingDecisionFallback({required this.decisionId});

  final int decisionId;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red),
          color: Colors.red.shade50,
        ),
        padding: const EdgeInsets.all(4),
        child: Text(
          'Missing decision $decisionId',
          style: const TextStyle(fontSize: 10, color: Colors.red),
        ),
      );
}
