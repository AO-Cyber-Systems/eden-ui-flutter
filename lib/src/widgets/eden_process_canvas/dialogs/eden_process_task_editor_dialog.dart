import 'package:flutter/material.dart';

import '../process_models.dart';
import '../process_runtime_component_registry.dart';

/// Task editor dialog — parity row X-3.
///
/// Biggest of the three editor dialogs. Exposes:
/// - name + description (text, blur-saved)
/// - runtime-component picker (DropdownButton populated from
///   `EdenProcessRuntimeComponentRegistry.instance.all()`)
/// - 9 boolean flags (8 required-style + materializesAsTask)
/// - blockingBehavior dropdown (3 default options: soft/hard/none; override
///   via `blockingBehaviorOptions`)
/// - approvalRole + approvalUserId (free-form text)
/// - 4 workflow-hook id inputs (numeric, optional, int? via tryParse)
///
/// Stateless from canvas's perspective.
class EdenProcessTaskEditorDialog extends StatefulWidget {
  const EdenProcessTaskEditorDialog({
    super.key,
    required this.task,
    required this.onUpdate,
    this.blockingBehaviorOptions = const ['soft', 'hard', 'none'],
  });

  final EdenProcessTaskTemplate task;
  final void Function(Map<String, dynamic> updates) onUpdate;
  final List<String> blockingBehaviorOptions;

  @override
  State<EdenProcessTaskEditorDialog> createState() =>
      _EdenProcessTaskEditorDialogState();
}

class _EdenProcessTaskEditorDialogState
    extends State<EdenProcessTaskEditorDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _approvalRoleCtrl;
  late TextEditingController _approvalUserCtrl;
  late TextEditingController _onCompleteCtrl;
  late TextEditingController _onBlockedCtrl;
  late TextEditingController _onNaCtrl;
  late TextEditingController _onCantDoCtrl;

  late FocusNode _nameFocus;
  late FocusNode _descFocus;
  late FocusNode _approvalRoleFocus;
  late FocusNode _approvalUserFocus;
  late FocusNode _onCompleteFocus;
  late FocusNode _onBlockedFocus;
  late FocusNode _onNaFocus;
  late FocusNode _onCantDoFocus;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.task.displayName);
    _descCtrl = TextEditingController(text: widget.task.description ?? '');
    _approvalRoleCtrl =
        TextEditingController(text: widget.task.approvalRole ?? '');
    _approvalUserCtrl =
        TextEditingController(text: widget.task.approvalUserId ?? '');
    _onCompleteCtrl = TextEditingController(
      text: widget.task.onCompleteWorkflowId?.toString() ?? '',
    );
    _onBlockedCtrl = TextEditingController(
      text: widget.task.onBlockedWorkflowId?.toString() ?? '',
    );
    _onNaCtrl = TextEditingController(
      text: widget.task.onNaWorkflowId?.toString() ?? '',
    );
    _onCantDoCtrl = TextEditingController(
      text: widget.task.onCantDoWorkflowId?.toString() ?? '',
    );
    _nameFocus = FocusNode()
      ..addListener(() {
        if (!_nameFocus.hasFocus) _saveName();
      });
    _descFocus = FocusNode()
      ..addListener(() {
        if (!_descFocus.hasFocus) _saveDescription();
      });
    _approvalRoleFocus = FocusNode()
      ..addListener(() {
        if (!_approvalRoleFocus.hasFocus) _saveApprovalRole();
      });
    _approvalUserFocus = FocusNode()
      ..addListener(() {
        if (!_approvalUserFocus.hasFocus) _saveApprovalUser();
      });
    _onCompleteFocus = FocusNode()
      ..addListener(() {
        if (!_onCompleteFocus.hasFocus) {
          _saveHook('onCompleteWorkflowId', _onCompleteCtrl,
              widget.task.onCompleteWorkflowId);
        }
      });
    _onBlockedFocus = FocusNode()
      ..addListener(() {
        if (!_onBlockedFocus.hasFocus) {
          _saveHook('onBlockedWorkflowId', _onBlockedCtrl,
              widget.task.onBlockedWorkflowId);
        }
      });
    _onNaFocus = FocusNode()
      ..addListener(() {
        if (!_onNaFocus.hasFocus) {
          _saveHook('onNaWorkflowId', _onNaCtrl,
              widget.task.onNaWorkflowId);
        }
      });
    _onCantDoFocus = FocusNode()
      ..addListener(() {
        if (!_onCantDoFocus.hasFocus) {
          _saveHook('onCantDoWorkflowId', _onCantDoCtrl,
              widget.task.onCantDoWorkflowId);
        }
      });
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _descCtrl,
      _approvalRoleCtrl,
      _approvalUserCtrl,
      _onCompleteCtrl,
      _onBlockedCtrl,
      _onNaCtrl,
      _onCantDoCtrl,
    ]) {
      c.dispose();
    }
    for (final f in [
      _nameFocus,
      _descFocus,
      _approvalRoleFocus,
      _approvalUserFocus,
      _onCompleteFocus,
      _onBlockedFocus,
      _onNaFocus,
      _onCantDoFocus,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  void _saveName() {
    final trimmed = _nameCtrl.text.trim();
    if (trimmed.isNotEmpty && trimmed != widget.task.displayName) {
      widget.onUpdate({'displayName': trimmed});
    }
  }

  void _saveDescription() {
    final trimmed = _descCtrl.text.trim();
    final orig = widget.task.description ?? '';
    if (trimmed != orig) {
      widget.onUpdate({'description': trimmed.isEmpty ? null : trimmed});
    }
  }

  void _saveApprovalRole() {
    final trimmed = _approvalRoleCtrl.text.trim();
    final orig = widget.task.approvalRole ?? '';
    if (trimmed != orig) {
      widget.onUpdate({'approvalRole': trimmed.isEmpty ? null : trimmed});
    }
  }

  void _saveApprovalUser() {
    final trimmed = _approvalUserCtrl.text.trim();
    final orig = widget.task.approvalUserId ?? '';
    if (trimmed != orig) {
      widget.onUpdate({'approvalUserId': trimmed.isEmpty ? null : trimmed});
    }
  }

  void _saveHook(
      String field, TextEditingController ctrl, int? originalValue) {
    final text = ctrl.text.trim();
    int? newValue;
    if (text.isNotEmpty) {
      newValue = int.tryParse(text);
    }
    if (newValue != originalValue) {
      widget.onUpdate({field: newValue});
    }
  }

  void _flushAll() {
    _saveName();
    _saveDescription();
    _saveApprovalRole();
    _saveApprovalUser();
    _saveHook('onCompleteWorkflowId', _onCompleteCtrl,
        widget.task.onCompleteWorkflowId);
    _saveHook('onBlockedWorkflowId', _onBlockedCtrl,
        widget.task.onBlockedWorkflowId);
    _saveHook(
        'onNaWorkflowId', _onNaCtrl, widget.task.onNaWorkflowId);
    _saveHook('onCantDoWorkflowId', _onCantDoCtrl,
        widget.task.onCantDoWorkflowId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final components = EdenProcessRuntimeComponentRegistry.instance.all();
    return AlertDialog(
      title: const Text('Edit Task'),
      content: SizedBox(
        width: 520,
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
              Text('Runtime component', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 6),
              if (components.isEmpty)
                Text(
                  'No runtime components registered',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                DropdownButton<String>(
                  key: const ValueKey('runtime-component-dropdown'),
                  isExpanded: true,
                  value: components.any((c) => c.id == widget.task.runtimeComponent)
                      ? widget.task.runtimeComponent
                      : null,
                  items: [
                    for (final comp in components)
                      DropdownMenuItem(
                        value: comp.id,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(comp.icon, size: 14),
                            const SizedBox(width: 6),
                            Text(comp.displayName),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null && v != widget.task.runtimeComponent) {
                      widget.onUpdate({'runtimeComponent': v});
                    }
                  },
                ),
              const SizedBox(height: 16),
              Text('Flags', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 6),
              _TaskCheck(
                label: 'Required',
                value: widget.task.isRequired,
                onChanged: (v) => widget.onUpdate({'isRequired': v}),
              ),
              _TaskCheck(
                label: 'Photo required',
                value: widget.task.photoRequired,
                onChanged: (v) => widget.onUpdate({'photoRequired': v}),
              ),
              _TaskCheck(
                label: 'Signature required',
                value: widget.task.signatureRequired,
                onChanged: (v) =>
                    widget.onUpdate({'signatureRequired': v}),
              ),
              _TaskCheck(
                label: 'Approval required',
                value: widget.task.approvalRequired,
                onChanged: (v) =>
                    widget.onUpdate({'approvalRequired': v}),
              ),
              _TaskCheck(
                label: 'Description required',
                value: widget.task.descriptionRequired,
                onChanged: (v) =>
                    widget.onUpdate({'descriptionRequired': v}),
              ),
              _TaskCheck(
                label: 'Attachment required',
                value: widget.task.attachmentRequired,
                onChanged: (v) =>
                    widget.onUpdate({'attachmentRequired': v}),
              ),
              _TaskCheck(
                label: 'Allows N/A',
                value: widget.task.allowsNa,
                onChanged: (v) => widget.onUpdate({'allowsNa': v}),
              ),
              _TaskCheck(
                label: 'Allows blocked',
                value: widget.task.allowsBlocked,
                onChanged: (v) => widget.onUpdate({'allowsBlocked': v}),
              ),
              _TaskCheck(
                label: 'Allows cant-do',
                value: widget.task.allowsCantDo,
                onChanged: (v) => widget.onUpdate({'allowsCantDo': v}),
              ),
              _TaskCheck(
                label: 'Materializes as task',
                value: widget.task.materializesAsTask,
                onChanged: (v) =>
                    widget.onUpdate({'materializesAsTask': v}),
              ),
              const SizedBox(height: 16),
              Text('Blocking behavior', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 6),
              DropdownButton<String>(
                key: const ValueKey('blocking-behavior-dropdown'),
                isExpanded: true,
                value: widget.blockingBehaviorOptions
                        .contains(widget.task.blockingBehavior)
                    ? widget.task.blockingBehavior
                    : null,
                hint: const Text('Select…'),
                items: [
                  for (final opt in widget.blockingBehaviorOptions)
                    DropdownMenuItem(value: opt, child: Text(opt)),
                ],
                onChanged: (v) {
                  if (v != null && v != widget.task.blockingBehavior) {
                    widget.onUpdate({'blockingBehavior': v});
                  }
                },
              ),
              const SizedBox(height: 16),
              Text('Approval', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 6),
              TextField(
                controller: _approvalRoleCtrl,
                focusNode: _approvalRoleFocus,
                decoration: const InputDecoration(labelText: 'Approval role'),
                onSubmitted: (_) => _saveApprovalRole(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _approvalUserCtrl,
                focusNode: _approvalUserFocus,
                decoration:
                    const InputDecoration(labelText: 'Approval user id'),
                onSubmitted: (_) => _saveApprovalUser(),
              ),
              const SizedBox(height: 16),
              Text('Workflow hooks', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 6),
              _hookField(
                'On complete (workflow id)',
                'hook-onCompleteWorkflowId',
                _onCompleteCtrl,
                _onCompleteFocus,
                () => _saveHook('onCompleteWorkflowId', _onCompleteCtrl,
                    widget.task.onCompleteWorkflowId),
              ),
              const SizedBox(height: 8),
              _hookField(
                'On blocked (workflow id)',
                'hook-onBlockedWorkflowId',
                _onBlockedCtrl,
                _onBlockedFocus,
                () => _saveHook('onBlockedWorkflowId', _onBlockedCtrl,
                    widget.task.onBlockedWorkflowId),
              ),
              const SizedBox(height: 8),
              _hookField(
                'On N/A (workflow id)',
                'hook-onNaWorkflowId',
                _onNaCtrl,
                _onNaFocus,
                () => _saveHook(
                    'onNaWorkflowId', _onNaCtrl, widget.task.onNaWorkflowId),
              ),
              const SizedBox(height: 8),
              _hookField(
                'On cant-do (workflow id)',
                'hook-onCantDoWorkflowId',
                _onCantDoCtrl,
                _onCantDoFocus,
                () => _saveHook('onCantDoWorkflowId', _onCantDoCtrl,
                    widget.task.onCantDoWorkflowId),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _flushAll();
            Navigator.pop(context);
          },
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _hookField(
    String label,
    String keyName,
    TextEditingController ctrl,
    FocusNode focus,
    VoidCallback onSave,
  ) {
    return TextField(
      key: ValueKey(keyName),
      controller: ctrl,
      focusNode: focus,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onSubmitted: (_) => onSave(),
    );
  }
}

class _TaskCheck extends StatelessWidget {
  const _TaskCheck({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
        key: ValueKey('task-checkbox-row-$label'),
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
