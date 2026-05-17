import 'package:flutter/material.dart';

import '../process_models.dart';

/// Lightweight template summary used by the task-group editor's import slot.
typedef EdenProcessTaskGroupTemplateOption = ({String id, String name});

/// Task group editor dialog — parity row X-2.
///
/// Edits name + description (blur-saved), isCollapsedDefault + isRequired
/// checkboxes, optional template-import dropdown (consumer-provided via
/// `loadTemplates` + `onImportTemplate`), 3 workflow-hook id inputs (numeric,
/// blur-saved with int? parsing), and an inline task list with add / delete
/// / edit affordances.
///
/// Stateless from the canvas's perspective: it never mutates the group. All
/// changes fire callbacks; consumer applies the mutation.
class EdenProcessTaskGroupEditorDialog extends StatefulWidget {
  const EdenProcessTaskGroupEditorDialog({
    super.key,
    required this.group,
    required this.onUpdate,
    required this.onAddTask,
    required this.onDeleteTask,
    required this.onEditTask,
    this.loadTemplates,
    this.onImportTemplate,
  });

  final EdenProcessTaskGroup group;
  final void Function(Map<String, dynamic> updates) onUpdate;
  final void Function(int groupId, Map<String, dynamic>? config) onAddTask;
  final void Function(int taskId) onDeleteTask;
  final void Function(int taskId) onEditTask;

  /// Optional template loader. When non-null, the dialog renders a template
  /// import dropdown populated by this future.
  final Future<List<EdenProcessTaskGroupTemplateOption>> Function()?
      loadTemplates;

  /// Fires when a template id is selected from the import dropdown.
  final void Function(String templateId)? onImportTemplate;

  @override
  State<EdenProcessTaskGroupEditorDialog> createState() =>
      _EdenProcessTaskGroupEditorDialogState();
}

class _EdenProcessTaskGroupEditorDialogState
    extends State<EdenProcessTaskGroupEditorDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _allCompleteCtrl;
  late TextEditingController _itemNaCtrl;
  late TextEditingController _itemCantDoCtrl;
  late FocusNode _nameFocus;
  late FocusNode _descFocus;
  late FocusNode _allCompleteFocus;
  late FocusNode _itemNaFocus;
  late FocusNode _itemCantDoFocus;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.group.displayName);
    _descCtrl = TextEditingController(text: widget.group.description ?? '');
    _allCompleteCtrl = TextEditingController(
      text: widget.group.onAllCompleteWorkflowId?.toString() ?? '',
    );
    _itemNaCtrl = TextEditingController(
      text: widget.group.onItemNaWorkflowId?.toString() ?? '',
    );
    _itemCantDoCtrl = TextEditingController(
      text: widget.group.onItemCantDoWorkflowId?.toString() ?? '',
    );
    _nameFocus = FocusNode()
      ..addListener(() {
        if (!_nameFocus.hasFocus) _saveName();
      });
    _descFocus = FocusNode()
      ..addListener(() {
        if (!_descFocus.hasFocus) _saveDescription();
      });
    _allCompleteFocus = FocusNode()
      ..addListener(() {
        if (!_allCompleteFocus.hasFocus) {
          _saveHook('onAllCompleteWorkflowId', _allCompleteCtrl,
              widget.group.onAllCompleteWorkflowId);
        }
      });
    _itemNaFocus = FocusNode()
      ..addListener(() {
        if (!_itemNaFocus.hasFocus) {
          _saveHook('onItemNaWorkflowId', _itemNaCtrl,
              widget.group.onItemNaWorkflowId);
        }
      });
    _itemCantDoFocus = FocusNode()
      ..addListener(() {
        if (!_itemCantDoFocus.hasFocus) {
          _saveHook('onItemCantDoWorkflowId', _itemCantDoCtrl,
              widget.group.onItemCantDoWorkflowId);
        }
      });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _allCompleteCtrl.dispose();
    _itemNaCtrl.dispose();
    _itemCantDoCtrl.dispose();
    _nameFocus.dispose();
    _descFocus.dispose();
    _allCompleteFocus.dispose();
    _itemNaFocus.dispose();
    _itemCantDoFocus.dispose();
    super.dispose();
  }

  void _saveName() {
    final trimmed = _nameCtrl.text.trim();
    if (trimmed.isNotEmpty && trimmed != widget.group.displayName) {
      widget.onUpdate({'displayName': trimmed});
    }
  }

  void _saveDescription() {
    final trimmed = _descCtrl.text.trim();
    final orig = widget.group.description ?? '';
    if (trimmed != orig) {
      widget.onUpdate({'description': trimmed.isEmpty ? null : trimmed});
    }
  }

  void _saveHook(String field, TextEditingController ctrl, int? originalValue) {
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
    _saveHook('onAllCompleteWorkflowId', _allCompleteCtrl,
        widget.group.onAllCompleteWorkflowId);
    _saveHook('onItemNaWorkflowId', _itemNaCtrl,
        widget.group.onItemNaWorkflowId);
    _saveHook('onItemCantDoWorkflowId', _itemCantDoCtrl,
        widget.group.onItemCantDoWorkflowId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Edit Task Group'),
      content: SizedBox(
        width: 480,
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
              const SizedBox(height: 12),
              _GroupCheck(
                label: 'Collapsed by default',
                value: widget.group.isCollapsedDefault,
                onChanged: (v) =>
                    widget.onUpdate({'isCollapsedDefault': v}),
              ),
              _GroupCheck(
                label: 'Required',
                value: widget.group.isRequired,
                onChanged: (v) => widget.onUpdate({'isRequired': v}),
              ),
              if (widget.loadTemplates != null) ...[
                const SizedBox(height: 16),
                Text('Import from template',
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 6),
                FutureBuilder<List<EdenProcessTaskGroupTemplateOption>>(
                  future: widget.loadTemplates!(),
                  builder: (ctx, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    final options = snap.data ?? const [];
                    if (options.isEmpty) {
                      return Text(
                        'No templates available',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      );
                    }
                    return DropdownButton<String>(
                      key: const ValueKey('template-import-dropdown'),
                      isExpanded: true,
                      value: null,
                      hint: const Text('Choose a template…'),
                      items: [
                        for (final opt in options)
                          DropdownMenuItem(
                            value: opt.id,
                            child: Text(opt.name),
                          ),
                      ],
                      onChanged: (id) {
                        if (id != null) {
                          widget.onImportTemplate?.call(id);
                        }
                      },
                    );
                  },
                ),
              ],
              const SizedBox(height: 16),
              Text('Workflow hooks', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 6),
              TextField(
                key: const ValueKey('hook-onAllCompleteWorkflowId'),
                controller: _allCompleteCtrl,
                focusNode: _allCompleteFocus,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'On all complete (workflow id)',
                ),
                onSubmitted: (_) => _saveHook(
                    'onAllCompleteWorkflowId',
                    _allCompleteCtrl,
                    widget.group.onAllCompleteWorkflowId),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('hook-onItemNaWorkflowId'),
                controller: _itemNaCtrl,
                focusNode: _itemNaFocus,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'On item N/A (workflow id)',
                ),
                onSubmitted: (_) => _saveHook('onItemNaWorkflowId',
                    _itemNaCtrl, widget.group.onItemNaWorkflowId),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('hook-onItemCantDoWorkflowId'),
                controller: _itemCantDoCtrl,
                focusNode: _itemCantDoFocus,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'On item cant-do (workflow id)',
                ),
                onSubmitted: (_) => _saveHook(
                    'onItemCantDoWorkflowId',
                    _itemCantDoCtrl,
                    widget.group.onItemCantDoWorkflowId),
              ),
              const SizedBox(height: 16),
              Text('Tasks (${widget.group.tasks.length})',
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 6),
              for (final task in widget.group.tasks)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.displayName,
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        key: ValueKey('edit-task-${task.id}'),
                        icon: const Icon(Icons.edit_outlined, size: 14),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Edit task',
                        onPressed: () => widget.onEditTask(task.id),
                      ),
                      IconButton(
                        key: ValueKey('delete-task-${task.id}'),
                        icon: const Icon(Icons.delete_outline, size: 14),
                        color: theme.colorScheme.error,
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Delete task',
                        onPressed: () => widget.onDeleteTask(task.id),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('add-task-button'),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Task'),
                  onPressed: () => widget.onAddTask(
                      widget.group.id, {'runtimeComponent': 'checklist'}),
                ),
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
}

class _GroupCheck extends StatelessWidget {
  const _GroupCheck({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
        key: ValueKey('group-checkbox-row-$label'),
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
