import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// Tag/chip creation input.
///
/// Displays tags as Material Chips inside an input field. Users type text
/// and press Enter (or the submit action) to create a new tag. Tags are
/// removable via the X button.
///
/// ```dart
/// EdenTagInput(
///   label: 'Skills',
///   tags: ['HVAC', 'Plumbing'],
///   onTagsChanged: (tags) => setState(() => skills = tags),
///   hint: 'Add a skill...',
/// )
/// ```
class EdenTagInput extends StatefulWidget {
  const EdenTagInput({
    super.key,
    required this.tags,
    required this.onTagsChanged,
    this.label,
    this.hint = 'Add tag...',
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.maxTags,
  });

  final List<String> tags;
  final ValueChanged<List<String>> onTagsChanged;
  final String? label;
  final String hint;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final int? maxTags;

  @override
  State<EdenTagInput> createState() => _EdenTagInputState();
}

class _EdenTagInputState extends State<EdenTagInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;
    if (widget.tags.contains(trimmed)) return;
    if (widget.maxTags != null && widget.tags.length >= widget.maxTags!) return;

    final newTags = [...widget.tags, trimmed];
    widget.onTagsChanged(newTags);
    _controller.clear();
  }

  void _removeTag(int index) {
    final newTags = [...widget.tags]..removeAt(index);
    widget.onTagsChanged(newTags);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = widget.errorText != null;
    final atMax = widget.maxTags != null && widget.tags.length >= widget.maxTags!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: hasError ? EdenColors.error : null,
            ),
          ),
          const SizedBox(height: 6),
        ],
        InputDecorator(
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            errorText: widget.errorText,
            errorStyle: const TextStyle(fontSize: 12),
            enabled: widget.enabled,
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (int i = 0; i < widget.tags.length; i++)
                Chip(
                  label: Text(widget.tags[i]),
                  onDeleted: widget.enabled ? () => _removeTag(i) : null,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  labelStyle: const TextStyle(fontSize: 13),
                  deleteIconColor: theme.colorScheme.onSurfaceVariant,
                ),
              if (!atMax && widget.enabled)
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      isDense: true,
                    ),
                    onSubmitted: (value) {
                      _addTag(value);
                      _focusNode.requestFocus();
                    },
                  ),
                ),
            ],
          ),
        ),
        if (widget.helperText != null && !hasError) ...[
          const SizedBox(height: 4),
          Text(
            widget.helperText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
