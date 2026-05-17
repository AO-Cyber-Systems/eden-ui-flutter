import 'package:flutter/material.dart';

import '../process_models.dart';

/// Phase editor dialog — parity row X-1.
///
/// Opens via `showDialog(context, builder: (_) => EdenProcessPhaseEditorDialog(
/// phase: phase, onUpdate: (updates) => ...))`.
///
/// Stateless from the canvas's perspective: it never mutates the phase
/// directly. Field changes fire `onUpdate(updates)` callbacks; the consumer
/// applies the mutation.
///
/// **Text save semantics:** text fields save on blur (focus change) or Enter
/// (onSubmitted). Closing the dialog also flushes any pending unsaved text.
class EdenProcessPhaseEditorDialog extends StatefulWidget {
  const EdenProcessPhaseEditorDialog({
    super.key,
    required this.phase,
    required this.onUpdate,
  });

  final EdenProcessPhase phase;
  final void Function(Map<String, dynamic> updates) onUpdate;

  @override
  State<EdenProcessPhaseEditorDialog> createState() =>
      _EdenProcessPhaseEditorDialogState();
}

class _EdenProcessPhaseEditorDialogState
    extends State<EdenProcessPhaseEditorDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late FocusNode _nameFocus;
  late FocusNode _descFocus;

  static const List<(String, Color)> _colors = [
    ('blue', Color(0xFF3B82F6)),
    ('green', Color(0xFF10B981)),
    ('amber', Color(0xFFF59E0B)),
    ('red', Color(0xFFEF4444)),
    ('purple', Color(0xFF8B5CF6)),
    ('pink', Color(0xFFEC4899)),
    ('cyan', Color(0xFF06B6D4)),
    ('gray', Color(0xFF6B7280)),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.phase.displayName);
    _descCtrl = TextEditingController(text: widget.phase.description ?? '');
    _nameFocus = FocusNode()
      ..addListener(() {
        if (!_nameFocus.hasFocus) _saveName();
      });
    _descFocus = FocusNode()
      ..addListener(() {
        if (!_descFocus.hasFocus) _saveDescription();
      });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _nameFocus.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  void _saveName() {
    final trimmed = _nameCtrl.text.trim();
    if (trimmed.isNotEmpty && trimmed != widget.phase.displayName) {
      widget.onUpdate({'displayName': trimmed});
    }
  }

  void _saveDescription() {
    final trimmed = _descCtrl.text.trim();
    final orig = widget.phase.description ?? '';
    if (trimmed != orig) {
      widget.onUpdate({'description': trimmed.isEmpty ? null : trimmed});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Edit Phase'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameCtrl,
                focusNode: _nameFocus,
                decoration: const InputDecoration(labelText: 'Name'),
                onSubmitted: (_) => _saveName(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                focusNode: _descFocus,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description'),
                onSubmitted: (_) => _saveDescription(),
              ),
              const SizedBox(height: 16),
              Text('Color', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final color in _colors)
                    GestureDetector(
                      key: ValueKey('color-swatch-${color.$1}'),
                      onTap: () {
                        if (widget.phase.color != color.$1) {
                          widget.onUpdate({'color': color.$1});
                        }
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color.$2,
                          shape: BoxShape.circle,
                          border: widget.phase.color == color.$1
                              ? Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 2.5,
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _PhaseCheck(
                label: 'Required',
                value: widget.phase.isRequired,
                onChanged: (v) => widget.onUpdate({'isRequired': v}),
              ),
              _PhaseCheck(
                label: 'Milestone',
                value: widget.phase.isMilestone,
                onChanged: (v) => widget.onUpdate({'isMilestone': v}),
              ),
              _PhaseCheck(
                label: 'Can skip',
                value: widget.phase.canSkip,
                onChanged: (v) => widget.onUpdate({'canSkip': v}),
              ),
              _PhaseCheck(
                label: 'Auto-advance',
                value: widget.phase.autoAdvance,
                onChanged: (v) => widget.onUpdate({'autoAdvance': v}),
              ),
              _PhaseCheck(
                label: 'Allows scope change',
                value: widget.phase.allowsScopeChange,
                onChanged: (v) =>
                    widget.onUpdate({'allowsScopeChange': v}),
              ),
              _PhaseCheck(
                label: 'Allows ad-hoc tasks',
                value: widget.phase.allowsAdHocTasks,
                onChanged: (v) =>
                    widget.onUpdate({'allowsAdHocTasks': v}),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _saveName();
            _saveDescription();
            Navigator.pop(context);
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _PhaseCheck extends StatelessWidget {
  const _PhaseCheck({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
        key: ValueKey('checkbox-row-$label'),
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
            ),
            Expanded(child: Text(label)),
          ],
        ),
      );
}
