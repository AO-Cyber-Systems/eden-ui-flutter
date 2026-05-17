import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_card.dart';
import 'eden_chip.dart';
import 'eden_input.dart';

/// Field types supported by the intake form builder.
enum EdenIntakeFieldType {
  shortText,
  longText,
  number,
  date,
  singleChoice,
  multiChoice,
  yesNo,
  signature,
  photo,
}

extension EdenIntakeFieldTypeLabel on EdenIntakeFieldType {
  String get displayLabel {
    switch (this) {
      case EdenIntakeFieldType.shortText:
        return 'Short text';
      case EdenIntakeFieldType.longText:
        return 'Long text';
      case EdenIntakeFieldType.number:
        return 'Number';
      case EdenIntakeFieldType.date:
        return 'Date';
      case EdenIntakeFieldType.singleChoice:
        return 'Single choice';
      case EdenIntakeFieldType.multiChoice:
        return 'Multi choice';
      case EdenIntakeFieldType.yesNo:
        return 'Yes / No';
      case EdenIntakeFieldType.signature:
        return 'Signature';
      case EdenIntakeFieldType.photo:
        return 'Photo';
    }
  }

  IconData get icon {
    switch (this) {
      case EdenIntakeFieldType.shortText:
        return Icons.short_text;
      case EdenIntakeFieldType.longText:
        return Icons.notes;
      case EdenIntakeFieldType.number:
        return Icons.numbers;
      case EdenIntakeFieldType.date:
        return Icons.calendar_today;
      case EdenIntakeFieldType.singleChoice:
        return Icons.radio_button_checked;
      case EdenIntakeFieldType.multiChoice:
        return Icons.check_box;
      case EdenIntakeFieldType.yesNo:
        return Icons.toggle_on;
      case EdenIntakeFieldType.signature:
        return Icons.draw;
      case EdenIntakeFieldType.photo:
        return Icons.photo_camera;
    }
  }
}

/// Conditional visibility primitive — `field X is visible WHEN field [fieldId]
/// equals|notEquals [value]`. v1 supports a single equals/notEquals; boolean
/// composition (AND/OR) is deferred to v2.
@immutable
class EdenIntakeVisibilityRule {
  const EdenIntakeVisibilityRule({
    required this.fieldId,
    this.equals,
    this.notEquals,
  });

  final String fieldId;
  final Object? equals;
  final Object? notEquals;
}

/// Single field in the builder's schema. The runner widget [EdenIntakeForm]
/// (obj 001-10) translates this to its own question shape — different value
/// class, complementary not co-modified.
@immutable
class EdenIntakeFieldSchema {
  const EdenIntakeFieldSchema({
    required this.id,
    required this.type,
    required this.label,
    this.required = false,
    this.options = const [],
    this.visibleWhen,
  });

  final String id;
  final EdenIntakeFieldType type;
  final String label;
  final bool required;
  final List<String> options;
  final EdenIntakeVisibilityRule? visibleWhen;

  EdenIntakeFieldSchema copyWith({
    String? id,
    EdenIntakeFieldType? type,
    String? label,
    bool? required,
    List<String>? options,
    EdenIntakeVisibilityRule? visibleWhen,
    bool clearVisibleWhen = false,
  }) {
    return EdenIntakeFieldSchema(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      required: required ?? this.required,
      options: options ?? this.options,
      visibleWhen:
          clearVisibleWhen ? null : (visibleWhen ?? this.visibleWhen),
    );
  }
}

/// Builder's output schema — consumer persists this to its own backend; the
/// runner widget consumes it to render the actual form.
@immutable
class EdenIntakeFormSchema {
  const EdenIntakeFormSchema({
    required this.id,
    required this.name,
    this.version = 1,
    this.fields = const [],
    this.publishedAt,
  });

  final String id;
  final String name;
  final int version;
  final List<EdenIntakeFieldSchema> fields;
  final DateTime? publishedAt;

  EdenIntakeFormSchema copyWith({
    String? id,
    String? name,
    int? version,
    List<EdenIntakeFieldSchema>? fields,
    DateTime? publishedAt,
  }) {
    return EdenIntakeFormSchema(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      fields: fields ?? this.fields,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}

/// Pure helper — returns the upstream fields (earlier in list) for visibleWhen
/// dropdown options. Exposed for direct testing.
@visibleForTesting
List<EdenIntakeFieldSchema> upstreamFieldsFor(
    EdenIntakeFormSchema schema, String selectedFieldId) {
  final idx = schema.fields.indexWhere((f) => f.id == selectedFieldId);
  if (idx <= 0) return const [];
  return schema.fields.sublist(0, idx);
}

/// Intake-form TEMPLATE authoring widget — drag-to-place field palette + canvas
/// reorder + per-field config. Produces a [EdenIntakeFormSchema] the consumer
/// persists; the runner widget [EdenIntakeForm] (obj 001-10) consumes the same
/// schema shape.
///
/// 3-pane layout at ≥900pt; tabbed at <900pt.
class EdenIntakeFormBuilder extends StatefulWidget {
  const EdenIntakeFormBuilder({
    super.key,
    required this.schema,
    required this.onSchemaChanged,
    this.onPublish,
    this.idGenerator,
  });

  final EdenIntakeFormSchema schema;
  final ValueChanged<EdenIntakeFormSchema> onSchemaChanged;
  final VoidCallback? onPublish;

  /// Optional deterministic id generator for tests.
  final String Function()? idGenerator;

  @override
  State<EdenIntakeFormBuilder> createState() => EdenIntakeFormBuilderState();
}

class EdenIntakeFormBuilderState extends State<EdenIntakeFormBuilder> {
  String? _selectedFieldId;
  int _idCounter = 0;

  String _genId() {
    if (widget.idGenerator != null) return widget.idGenerator!();
    return 'field-${DateTime.now().millisecondsSinceEpoch}-${_idCounter++}';
  }

  /// Append a new field of the given type. Public for test invocation.
  void addField(EdenIntakeFieldType type) {
    final field = EdenIntakeFieldSchema(
      id: _genId(),
      type: type,
      label: 'New ${type.displayLabel.toLowerCase()}',
    );
    widget.onSchemaChanged(
        widget.schema.copyWith(fields: [...widget.schema.fields, field]));
  }

  /// Move a field. Applies Flutter's ReorderableListView newIndex quirk.
  void reorderField(int oldIdx, int newIdx) {
    if (newIdx > oldIdx) newIdx -= 1;
    final list = [...widget.schema.fields];
    final f = list.removeAt(oldIdx);
    list.insert(newIdx, f);
    widget.onSchemaChanged(widget.schema.copyWith(fields: list));
  }

  /// Remove a field by id. Clears [_selectedFieldId] if it was the removed
  /// field, so the config pane doesn't crash on missing lookup.
  void removeField(String id) {
    final list = widget.schema.fields.where((f) => f.id != id).toList();
    if (_selectedFieldId == id) {
      setState(() => _selectedFieldId = null);
    }
    widget.onSchemaChanged(widget.schema.copyWith(fields: list));
  }

  /// Apply a mutator to one field's schema in place.
  void updateField(
      String id, EdenIntakeFieldSchema Function(EdenIntakeFieldSchema) mutate) {
    final list = widget.schema.fields
        .map((f) => f.id == id ? mutate(f) : f)
        .toList();
    widget.onSchemaChanged(widget.schema.copyWith(fields: list));
  }

  void _selectField(String? id) {
    setState(() => _selectedFieldId = id);
  }

  EdenIntakeFieldSchema? get _selectedField {
    if (_selectedFieldId == null) return null;
    final idx =
        widget.schema.fields.indexWhere((f) => f.id == _selectedFieldId);
    if (idx < 0) return null;
    return widget.schema.fields[idx];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        if (c.maxWidth >= 900) return _buildThreePane();
        return _buildTabbed();
      },
    );
  }

  Widget _buildThreePane() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 180, child: _PalettePane(state: this)),
        const VerticalDivider(width: 1),
        Expanded(child: _CanvasPane(state: this)),
        const VerticalDivider(width: 1),
        SizedBox(width: 280, child: _ConfigPane(state: this)),
      ],
    );
  }

  Widget _buildTabbed() {
    return DefaultTabController(
      length: 3,
      initialIndex: 1,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Palette'),
              Tab(text: 'Canvas'),
              Tab(text: 'Config'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _PalettePane(state: this),
                _CanvasPane(state: this),
                _ConfigPane(state: this),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PalettePane extends StatelessWidget {
  const _PalettePane({required this.state});
  final EdenIntakeFormBuilderState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(EdenSpacing.space2),
      children: [
        Text('Add field',
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: EdenSpacing.space2),
        for (final type in EdenIntakeFieldType.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Draggable<EdenIntakeFieldType>(
              key: ValueKey('palette-${type.name}'),
              data: type,
              feedback: Material(
                child: SizedBox(
                  width: 160,
                  child: _PaletteChip(type: type),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.4,
                child: _PaletteChip(type: type),
              ),
              child: InkWell(
                onTap: () => state.addField(type),
                child: _PaletteChip(type: type),
              ),
            ),
          ),
      ],
    );
  }
}

class _PaletteChip extends StatelessWidget {
  const _PaletteChip({required this.type});
  final EdenIntakeFieldType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space2, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              type.displayLabel,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CanvasPane extends StatelessWidget {
  const _CanvasPane({required this.state});
  final EdenIntakeFormBuilderState state;

  @override
  Widget build(BuildContext context) {
    return DragTarget<EdenIntakeFieldType>(
      onAcceptWithDetails: (details) => state.addField(details.data),
      builder: (ctx, candidates, rejected) {
        return Column(
          children: [
            Expanded(
              child: state.widget.schema.fields.isEmpty
                  ? Center(
                      child: Text(
                        'Drop fields here',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ReorderableListView.builder(
                      itemCount: state.widget.schema.fields.length,
                      itemBuilder: (ctx, i) {
                        final f = state.widget.schema.fields[i];
                        return _CanvasRow(
                          key: ValueKey('canvas-${f.id}'),
                          field: f,
                          selected: f.id == state._selectedFieldId,
                          onTap: () => state._selectField(f.id),
                          onDelete: () => state.removeField(f.id),
                        );
                      },
                      onReorder: state.reorderField,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(EdenSpacing.space2),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: state.widget.onPublish,
                  child: const Text('Publish'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CanvasRow extends StatelessWidget {
  const _CanvasRow({
    super.key,
    required this.field,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  final EdenIntakeFieldSchema field;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
            vertical: 2, horizontal: EdenSpacing.space2),
        padding: const EdgeInsets.symmetric(
            vertical: EdenSpacing.space2, horizontal: EdenSpacing.space2),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(field.type.icon, size: 18),
            const SizedBox(width: EdenSpacing.space2),
            Expanded(
              child: Text(
                field.label,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (field.required) ...[
              const SizedBox(width: EdenSpacing.space2),
              const EdenChip(label: 'Required'),
            ],
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onDelete,
              tooltip: 'Delete field',
            ),
            const Icon(Icons.drag_handle, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ConfigPane extends StatelessWidget {
  const _ConfigPane({required this.state});
  final EdenIntakeFormBuilderState state;

  @override
  Widget build(BuildContext context) {
    final field = state._selectedField;
    if (field == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(EdenSpacing.space4),
          child: Text('Tap a field to configure'),
        ),
      );
    }
    return _ConfigForm(state: state, field: field);
  }
}

class _ConfigForm extends StatefulWidget {
  const _ConfigForm({required this.state, required this.field});
  final EdenIntakeFormBuilderState state;
  final EdenIntakeFieldSchema field;

  @override
  State<_ConfigForm> createState() => _ConfigFormState();
}

class _ConfigFormState extends State<_ConfigForm> {
  late TextEditingController _labelCtrl;
  late TextEditingController _optionsCtrl;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.field.label);
    _optionsCtrl =
        TextEditingController(text: widget.field.options.join(', '));
  }

  @override
  void didUpdateWidget(_ConfigForm old) {
    super.didUpdateWidget(old);
    if (old.field.id != widget.field.id) {
      _labelCtrl.text = widget.field.label;
      _optionsCtrl.text = widget.field.options.join(', ');
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _optionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.field;
    final hasOptions = f.type == EdenIntakeFieldType.singleChoice ||
        f.type == EdenIntakeFieldType.multiChoice;
    return ListView(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      children: [
        EdenInput(
          label: 'Label',
          controller: _labelCtrl,
          onChanged: (v) =>
              widget.state.updateField(f.id, (x) => x.copyWith(label: v)),
        ),
        const SizedBox(height: EdenSpacing.space3),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Required'),
          value: f.required,
          onChanged: (v) =>
              widget.state.updateField(f.id, (x) => x.copyWith(required: v)),
        ),
        if (hasOptions) ...[
          const SizedBox(height: EdenSpacing.space2),
          EdenInput(
            label: 'Options (comma-separated)',
            controller: _optionsCtrl,
            maxLines: 3,
            onChanged: (v) => widget.state.updateField(
              f.id,
              (x) => x.copyWith(
                options: v
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList(),
              ),
            ),
          ),
        ],
        const SizedBox(height: EdenSpacing.space3),
        _VisibleWhenEditor(state: widget.state, field: f),
        const SizedBox(height: EdenSpacing.space4),
        TextButton.icon(
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete field'),
          onPressed: () => widget.state.removeField(f.id),
        ),
      ],
    );
  }
}

class _VisibleWhenEditor extends StatelessWidget {
  const _VisibleWhenEditor({required this.state, required this.field});
  final EdenIntakeFormBuilderState state;
  final EdenIntakeFieldSchema field;

  @override
  Widget build(BuildContext context) {
    final upstream = upstreamFieldsFor(state.widget.schema, field.id);
    final current = field.visibleWhen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Visible when', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        DropdownButton<String?>(
          isExpanded: true,
          value: current?.fieldId,
          hint: const Text('—'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('— (always visible)'),
            ),
            for (final u in upstream)
              DropdownMenuItem<String?>(value: u.id, child: Text(u.label)),
          ],
          onChanged: (v) {
            if (v == null) {
              state.updateField(
                  field.id, (x) => x.copyWith(clearVisibleWhen: true));
            } else {
              state.updateField(
                field.id,
                (x) => x.copyWith(
                  visibleWhen: EdenIntakeVisibilityRule(fieldId: v),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

// Marker import to make EdenCard reachable for consumers that compose the
// pane in their own scaffold — not directly used in this file's render path
// but kept exported via library symbol for future composition.
// ignore: unused_element
typedef _EdenCardMarker = EdenCard;
