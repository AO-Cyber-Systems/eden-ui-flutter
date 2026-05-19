// EdenSchemaForm — schema-driven form widget (upstream from CmsFrontmatterForm).
//
// Generic primitive: renders a Flutter form from a [List<EdenSchemaField>].
// No CMS coupling, no Riverpod, no RPC imports — safe to pumpWidget in tests.
//
// CMS-specific glue (slug auto-gen, frontmatter field names) stays in eden-biz.
// The locked-field concept is kept as a generic [lockedFieldKeys] set; callers
// decide which keys are immutable (e.g. 'slug' in the CMS use-case).
//
// Type coercion contract (matches original CmsFrontmatterForm):
//   text / select / mediaUrl → String
//   number                   → int  (via int.tryParse; defaults to 0)
//   toggle                   → bool
//   date                     → DateTime?
//
// MediaUrl fields: tapping the pick icon fires [onMediaPickRequest] with the
// field key. The caller opens whatever media picker is appropriate and sets
// the URL via an external [initialValues] update.

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Public model types
// ---------------------------------------------------------------------------

/// Supported field types for [EdenSchemaField].
enum EdenSchemaFieldType {
  /// Single-line text input. [onChanged] delivers a [String].
  text,

  /// Integer input. [onChanged] delivers an [int] (via int.tryParse).
  number,

  /// Date picker. [onChanged] delivers a [DateTime?].
  date,

  /// Boolean toggle (SwitchListTile). [onChanged] delivers a [bool].
  toggle,

  /// Dropdown select from [EdenSchemaField.selectOptions].
  /// [onChanged] delivers the selected [String].
  select,

  /// URL string for an image/media asset. [onChanged] delivers a [String].
  /// Tapping the pick icon fires [EdenSchemaForm.onMediaPickRequest].
  mediaUrl,

  /// List of `{value: String}` maps. [onChanged] delivers
  /// a [List<Map<String, dynamic>>].
  repeater,
}

/// Describes a single field in an [EdenSchemaForm] schema.
@immutable
class EdenSchemaField {
  const EdenSchemaField({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.selectOptions,
  });

  /// Unique key used to read/write [EdenSchemaForm.initialValues].
  final String key;

  /// Human-readable label shown above / alongside the field.
  final String label;

  /// Field type — determines which Flutter widget is rendered.
  final EdenSchemaFieldType type;

  /// Whether the field is required. When true, an empty text/select value
  /// produces a validation error via [TextFormField.validator].
  final bool required;

  /// Option strings for [EdenSchemaFieldType.select] fields.
  /// Ignored for all other types.
  final List<String>? selectOptions;
}

// ---------------------------------------------------------------------------
// EdenSchemaForm
// ---------------------------------------------------------------------------

/// Schema-driven form widget. Renders one Flutter input widget per
/// [EdenSchemaField] in [schema], in order.
///
/// ### Usage
/// ```dart
/// EdenSchemaForm(
///   schema: [
///     EdenSchemaField(key: 'title', label: 'Title', type: EdenSchemaFieldType.text, required: true),
///     EdenSchemaField(key: 'published', label: 'Published', type: EdenSchemaFieldType.toggle),
///   ],
///   initialValues: {'title': 'My Post', 'published': false},
///   onChanged: (key, value) => ref.read(formProvider.notifier).set(key, value),
///   onMediaPickRequest: (key) => showMediaPicker(key),
/// )
/// ```
///
/// Wrap with [Form] + a [GlobalKey<FormState>] to trigger validation via
/// `formKey.currentState!.validate()`.
class EdenSchemaForm extends StatefulWidget {
  const EdenSchemaForm({
    super.key,
    required this.schema,
    required this.initialValues,
    required this.onChanged,
    required this.onMediaPickRequest,
    this.lockedFieldKeys = const {},
  });

  /// Ordered list of field descriptors.
  final List<EdenSchemaField> schema;

  /// Initial field values keyed by [EdenSchemaField.key].
  /// Supply a value matching the field's type (String, int, bool, DateTime?).
  final Map<String, dynamic> initialValues;

  /// Called when any field value changes.
  /// [key] matches the field's [EdenSchemaField.key].
  /// [value] type depends on [EdenSchemaField.type] — see file-level contract.
  final void Function(String key, dynamic value) onChanged;

  /// Called when a [EdenSchemaFieldType.mediaUrl] field's pick icon is tapped.
  /// Receives the field key; the caller is responsible for opening a media
  /// picker and updating [initialValues] to reflect the chosen URL.
  final void Function(String fieldKey) onMediaPickRequest;

  /// Keys of fields that should render as readOnly. The field is still
  /// visible and carries its current value, but cannot be edited.
  /// Example: `{'slug'}` to lock the slug field after first save.
  final Set<String> lockedFieldKeys;

  @override
  State<EdenSchemaForm> createState() => _EdenSchemaFormState();
}

class _EdenSchemaFormState extends State<EdenSchemaForm> {
  /// TextEditingControllers for text / number / mediaUrl fields.
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    for (final spec in widget.schema) {
      if (spec.type == EdenSchemaFieldType.text ||
          spec.type == EdenSchemaFieldType.number ||
          spec.type == EdenSchemaFieldType.mediaUrl) {
        _controllers[spec.key] = TextEditingController(
          text: widget.initialValues[spec.key]?.toString() ?? '',
        );
      }
    }
  }

  @override
  void didUpdateWidget(EdenSchemaForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controllers when initialValues changes externally
    // (e.g. slug auto-generation, external value injection).
    for (final spec in widget.schema) {
      final ctrl = _controllers[spec.key];
      if (ctrl == null) continue;
      final newVal = widget.initialValues[spec.key]?.toString() ?? '';
      if (ctrl.text != newVal) {
        ctrl.text = newVal;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Field builders
  // ---------------------------------------------------------------------------

  Widget _buildField(EdenSchemaField spec) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: switch (spec.type) {
        EdenSchemaFieldType.text => _buildTextField(spec),
        EdenSchemaFieldType.number => _buildNumberField(spec),
        EdenSchemaFieldType.date => _buildDateField(spec),
        EdenSchemaFieldType.toggle => _buildToggleField(spec),
        EdenSchemaFieldType.select => _buildSelectField(spec),
        EdenSchemaFieldType.mediaUrl => _buildMediaUrlField(spec),
        EdenSchemaFieldType.repeater => _buildRepeaterField(spec),
      },
    );
  }

  Widget _buildTextField(EdenSchemaField spec) {
    final isLocked = widget.lockedFieldKeys.contains(spec.key);
    final controller = _controllers[spec.key]!;

    if (isLocked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(spec.label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            readOnly: true,
            decoration: InputDecoration(
              hintText: spec.label,
              suffixIcon: const Icon(Icons.lock_outline, size: 16),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(spec.label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(hintText: spec.label),
          validator: spec.required
              ? (v) => (v == null || v.trim().isEmpty)
                  ? '${spec.label} is required'
                  : null
              : null,
          onChanged: (v) => widget.onChanged(spec.key, v),
        ),
      ],
    );
  }

  Widget _buildNumberField(EdenSchemaField spec) {
    final controller = _controllers[spec.key]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(spec.label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: spec.label),
          // CRITICAL: int.tryParse prevents type-coercion bugs.
          // Matches the original CmsFrontmatterForm contract.
          onChanged: (v) => widget.onChanged(spec.key, int.tryParse(v) ?? 0),
        ),
      ],
    );
  }

  Widget _buildDateField(EdenSchemaField spec) {
    final currentDate = widget.initialValues[spec.key] as DateTime?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(spec.label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: currentDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              widget.onChanged(spec.key, picked);
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              hintText: 'Select date',
              suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
            ),
            child: Text(
              currentDate != null
                  ? '${currentDate.year}-'
                      '${currentDate.month.toString().padLeft(2, '0')}-'
                      '${currentDate.day.toString().padLeft(2, '0')}'
                  : spec.label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleField(EdenSchemaField spec) {
    final value = widget.initialValues[spec.key] as bool? ?? false;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(spec.label),
      value: value,
      onChanged: (v) => widget.onChanged(spec.key, v),
    );
  }

  Widget _buildSelectField(EdenSchemaField spec) {
    final options = spec.selectOptions ?? const [];
    final currentValue = widget.initialValues[spec.key] as String?;
    final validValue = options.contains(currentValue) ? currentValue : null;

    return DropdownButtonFormField<String>(
      initialValue: validValue,
      decoration: InputDecoration(labelText: spec.label),
      items: options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: (v) {
        if (v != null) widget.onChanged(spec.key, v);
      },
    );
  }

  Widget _buildMediaUrlField(EdenSchemaField spec) {
    final controller = _controllers[spec.key]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(spec.label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                readOnly: true,
                decoration: const InputDecoration(
                  hintText: 'No image selected',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.image_search),
              tooltip: 'Pick image',
              onPressed: () => widget.onMediaPickRequest(spec.key),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRepeaterField(EdenSchemaField spec) {
    // MVP: list of {value: String} entries. Drag-drop ordering is v2.
    final items = (widget.initialValues[spec.key] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(spec.label, style: Theme.of(context).textTheme.labelMedium),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              onPressed: () {
                final newItems = List<Map<String, dynamic>>.from(items)
                  ..add({'value': ''});
                widget.onChanged(spec.key, newItems);
              },
            ),
          ],
        ),
        ...items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item['value']?.toString() ?? '',
                    decoration: InputDecoration(
                      hintText: '${spec.label} item ${idx + 1}',
                    ),
                    onChanged: (v) {
                      final newItems = List<Map<String, dynamic>>.from(items);
                      newItems[idx] = {'value': v};
                      widget.onChanged(spec.key, newItems);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                  onPressed: () {
                    final newItems = List<Map<String, dynamic>>.from(items)
                      ..removeAt(idx);
                    widget.onChanged(spec.key, newItems);
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widget.schema.map(_buildField).toList(),
    );
  }
}
