import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A selectable label with color.
class EdenLabel {
  const EdenLabel({
    required this.id,
    required this.name,
    required this.color,
    this.isSelected = false,
  });

  final String id;
  final String name;
  final Color color;
  final bool isSelected;

  EdenLabel copyWith({bool? isSelected}) => EdenLabel(
        id: id,
        name: name,
        color: color,
        isSelected: isSelected ?? this.isSelected,
      );
}

/// Bottom sheet multi-select picker with color palette and quick-create.
class EdenLabelPicker {
  EdenLabelPicker._();

  static const List<Color> presetColors = [
    Color(0xFFEF4444), // red
    Color(0xFFF97316), // orange
    Color(0xFFF59E0B), // amber
    Color(0xFF10B981), // green
    Color(0xFF3B82F6), // blue
    Color(0xFFA855F7), // purple
    Color(0xFFEC4899), // pink
    Color(0xFF6B7280), // gray
  ];

  static Future<void> show(
    BuildContext context, {
    required List<EdenLabel> labels,
    required ValueChanged<List<EdenLabel>> onDone,
    void Function(String name, Color color)? onCreateNew,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EdenLabelPickerContent(
        labels: labels,
        onDone: onDone,
        onCreateNew: onCreateNew,
      ),
    );
  }
}

class _EdenLabelPickerContent extends StatefulWidget {
  const _EdenLabelPickerContent({
    required this.labels,
    required this.onDone,
    this.onCreateNew,
  });

  final List<EdenLabel> labels;
  final ValueChanged<List<EdenLabel>> onDone;
  final void Function(String name, Color color)? onCreateNew;

  @override
  State<_EdenLabelPickerContent> createState() =>
      _EdenLabelPickerContentState();
}

class _EdenLabelPickerContentState extends State<_EdenLabelPickerContent> {
  late List<EdenLabel> _labels;
  final _searchController = TextEditingController();
  final _newNameController = TextEditingController();
  String _filter = '';
  bool _showCreateForm = false;
  Color _selectedColor = EdenLabelPicker.presetColors.first;

  @override
  void initState() {
    super.initState();
    _labels = widget.labels.map((l) => l).toList();
    _searchController.addListener(() {
      setState(() => _filter = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newNameController.dispose();
    super.dispose();
  }

  List<EdenLabel> get _filteredLabels {
    if (_filter.isEmpty) return _labels;
    return _labels.where((l) => l.name.toLowerCase().contains(_filter)).toList();
  }

  void _toggleLabel(int index) {
    final globalIndex = _labels.indexOf(_filteredLabels[index]);
    setState(() {
      _labels[globalIndex] = _labels[globalIndex].copyWith(
        isSelected: !_labels[globalIndex].isSelected,
      );
    });
  }

  void _createLabel() {
    final name = _newNameController.text.trim();
    if (name.isEmpty) return;
    widget.onCreateNew?.call(name, _selectedColor);
    setState(() {
      _labels.add(EdenLabel(
        id: 'new_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        color: _selectedColor,
        isSelected: true,
      ));
      _newNameController.clear();
      _showCreateForm = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.colorScheme.surface;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(EdenRadii.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: EdenSpacing.space2),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: EdenRadii.borderRadiusFull,
                ),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(
              EdenSpacing.space6,
              EdenSpacing.space4,
              EdenSpacing.space4,
              EdenSpacing.space2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('Labels', style: theme.textTheme.titleMedium),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: theme.colorScheme.outlineVariant),

          // Search
          Padding(
            padding: const EdgeInsets.all(EdenSpacing.space4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Filter labels...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space3,
                  vertical: EdenSpacing.space2,
                ),
                border: OutlineInputBorder(
                  borderRadius: EdenRadii.borderRadiusLg,
                  borderSide: BorderSide(
                    color: isDark
                        ? EdenColors.neutral[700]!
                        : EdenColors.neutral[300]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: EdenRadii.borderRadiusLg,
                  borderSide: BorderSide(
                    color: isDark
                        ? EdenColors.neutral[700]!
                        : EdenColors.neutral[300]!,
                  ),
                ),
              ),
            ),
          ),

          // Label list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space4),
              itemCount: _filteredLabels.length,
              itemBuilder: (context, index) {
                final label = _filteredLabels[index];
                return _LabelItem(
                  label: label,
                  onTap: () => _toggleLabel(index),
                  isDark: isDark,
                );
              },
            ),
          ),

          Divider(height: 1, color: theme.colorScheme.outlineVariant),

          // Create new / Done
          if (_showCreateForm)
            _CreateForm(
              nameController: _newNameController,
              selectedColor: _selectedColor,
              onColorChanged: (c) => setState(() => _selectedColor = c),
              onSubmit: _createLabel,
              onCancel: () => setState(() => _showCreateForm = false),
              isDark: isDark,
            )
          else
            Padding(
              padding: const EdgeInsets.all(EdenSpacing.space4),
              child: Row(
                children: [
                  if (widget.onCreateNew != null)
                    TextButton.icon(
                      onPressed: () => setState(() => _showCreateForm = true),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create new'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      widget.onDone(_labels.where((l) => l.isSelected).toList());
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: EdenRadii.borderRadiusLg,
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LabelItem extends StatelessWidget {
  const _LabelItem({
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  final EdenLabel label;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: EdenRadii.borderRadiusMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space3,
          vertical: EdenSpacing.space2 + 2,
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: label.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: EdenSpacing.space3),
            Expanded(
              child: Text(
                label.name,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? EdenColors.neutral[100]
                      : EdenColors.neutral[900],
                ),
              ),
            ),
            if (label.isSelected)
              Icon(
                Icons.check,
                size: 18,
                color: isDark
                    ? EdenColors.neutral[300]
                    : EdenColors.neutral[600],
              ),
          ],
        ),
      ),
    );
  }
}

class _CreateForm extends StatelessWidget {
  const _CreateForm({
    required this.nameController,
    required this.selectedColor,
    required this.onColorChanged,
    required this.onSubmit,
    required this.onCancel,
    required this.isDark,
  });

  final TextEditingController nameController;
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(EdenSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Label name',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: EdenSpacing.space3,
                vertical: EdenSpacing.space2,
              ),
              border: OutlineInputBorder(
                borderRadius: EdenRadii.borderRadiusLg,
                borderSide: BorderSide(
                  color: isDark
                      ? EdenColors.neutral[700]!
                      : EdenColors.neutral[300]!,
                ),
              ),
            ),
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: EdenSpacing.space3),
          Wrap(
            spacing: EdenSpacing.space2,
            runSpacing: EdenSpacing.space2,
            children: EdenLabelPicker.presetColors.map((color) {
              final isSelected = color == selectedColor;
              return GestureDetector(
                onTap: () => onColorChanged(color),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: isDark ? Colors.white : EdenColors.neutral[900]!,
                            width: 2,
                          )
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: EdenSpacing.space3),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: EdenSpacing.space2),
              ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: EdenRadii.borderRadiusLg,
                  ),
                ),
                child: const Text('Create'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
