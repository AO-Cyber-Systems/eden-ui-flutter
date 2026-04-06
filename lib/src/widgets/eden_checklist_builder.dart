import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import 'checklist_builder/checklist_items.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// The type of input a checklist item requires.
enum EdenChecklistItemType {
  /// Standard checkbox.
  checkbox,

  /// Free-text input required.
  textInput,

  /// Photo attachment required.
  photoRequired,

  /// Signature capture required.
  signatureRequired,
}

/// A single item in an [EdenChecklistBuilder].
class EdenChecklistItem {
  /// Creates a checklist item.
  EdenChecklistItem({
    required this.id,
    required this.title,
    this.isChecked = false,
    this.children = const [],
    this.isRequired = false,
    this.note,
    this.type = EdenChecklistItemType.checkbox,
    this.sectionHeader,
  });

  /// Unique identifier.
  final String id;

  /// Display title.
  final String title;

  /// Whether this item is completed.
  bool isChecked;

  /// Nested sub-items.
  List<EdenChecklistItem> children;

  /// Whether this item must be checked before completion.
  final bool isRequired;

  /// Optional attached note.
  String? note;

  /// The kind of check this item represents.
  final EdenChecklistItemType type;

  /// If non-null, this item acts as a collapsible section header.
  final String? sectionHeader;

  /// Whether this item is a section header.
  bool get isSection => sectionHeader != null;

  /// Deep copy.
  EdenChecklistItem copyWith({
    String? id,
    String? title,
    bool? isChecked,
    List<EdenChecklistItem>? children,
    bool? isRequired,
    String? note,
    EdenChecklistItemType? type,
    String? sectionHeader,
  }) {
    return EdenChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isChecked: isChecked ?? this.isChecked,
      children: children ?? this.children.map((c) => c.copyWith()).toList(),
      isRequired: isRequired ?? this.isRequired,
      note: note ?? this.note,
      type: type ?? this.type,
      sectionHeader: sectionHeader ?? this.sectionHeader,
    );
  }
}

// ---------------------------------------------------------------------------
// Main widget
// ---------------------------------------------------------------------------

/// A dynamic checklist builder with nested items, sections, reordering,
/// progress tracking, and read-only mode.
class EdenChecklistBuilder extends StatefulWidget {
  /// Creates a checklist builder.
  const EdenChecklistBuilder({
    super.key,
    required this.items,
    this.readOnly = false,
    this.showProgress = true,
    this.showCompletionSummary = true,
    this.allowAdd = true,
    this.allowDelete = true,
    this.allowReorder = true,
    this.onItemChanged,
    this.onItemAdded,
    this.onItemDeleted,
    this.onReorder,
    this.onComplete,
  });

  /// The checklist items to display.
  final List<EdenChecklistItem> items;

  /// When true, the checklist cannot be edited.
  final bool readOnly;

  /// Whether to show the progress bar at the top.
  final bool showProgress;

  /// Whether to show the completion summary at the bottom.
  final bool showCompletionSummary;

  /// Whether to show the inline add-item field.
  final bool allowAdd;

  /// Whether swipe-to-delete is enabled.
  final bool allowDelete;

  /// Whether drag-to-reorder is enabled.
  final bool allowReorder;

  /// Called when an item's checked state or note changes.
  final ValueChanged<EdenChecklistItem>? onItemChanged;

  /// Called when a new item is added via the inline field.
  final ValueChanged<String>? onItemAdded;

  /// Called when an item is deleted.
  final ValueChanged<String>? onItemDeleted;

  /// Called when items are reordered. Provides old and new indices.
  final void Function(int oldIndex, int newIndex)? onReorder;

  /// Called when all required items are checked.
  final VoidCallback? onComplete;

  @override
  State<EdenChecklistBuilder> createState() => _EdenChecklistBuilderState();
}

class _EdenChecklistBuilderState extends State<EdenChecklistBuilder> {
  final Set<String> _collapsedSections = {};
  final TextEditingController _addController = TextEditingController();
  final FocusNode _addFocus = FocusNode();
  bool _showAddField = false;

  // ---------------------------------------------------------------------------
  // Progress helpers
  // ---------------------------------------------------------------------------

  int _countTotal(List<EdenChecklistItem> items) {
    int total = 0;
    for (final item in items) {
      if (!item.isSection) total++;
      total += _countTotal(item.children);
    }
    return total;
  }

  int _countChecked(List<EdenChecklistItem> items) {
    int checked = 0;
    for (final item in items) {
      if (!item.isSection && item.isChecked) checked++;
      checked += _countChecked(item.children);
    }
    return checked;
  }

  bool _allRequiredComplete(List<EdenChecklistItem> items) {
    for (final item in items) {
      if (item.isRequired && !item.isChecked) return false;
      if (!_allRequiredComplete(item.children)) return false;
    }
    return true;
  }

  void _onCheckChanged(EdenChecklistItem item, bool? value) {
    setState(() {
      item.isChecked = value ?? false;
      // Cascade to children
      _setChildrenChecked(item, item.isChecked);
      // Auto-check parents when all siblings are checked
      _refreshParentStates(widget.items);
    });
    widget.onItemChanged?.call(item);
    _checkCompletion();
  }

  void _setChildrenChecked(EdenChecklistItem parent, bool value) {
    for (final child in parent.children) {
      child.isChecked = value;
      _setChildrenChecked(child, value);
    }
  }

  /// Walk the tree and set each parent's checked state based on its children.
  void _refreshParentStates(List<EdenChecklistItem> items) {
    for (final item in items) {
      if (item.children.isNotEmpty) {
        _refreshParentStates(item.children);
        final allChecked =
            item.children.where((c) => !c.isSection).every((c) => c.isChecked);
        if (!item.isSection) {
          item.isChecked = allChecked;
        }
      }
    }
  }

  void _checkCompletion() {
    if (_allRequiredComplete(widget.items)) {
      widget.onComplete?.call();
    }
  }

  void _submitNewItem() {
    final text = _addController.text.trim();
    if (text.isEmpty) return;
    widget.onItemAdded?.call(text);
    _addController.clear();
    _addFocus.requestFocus();
  }

  @override
  void dispose() {
    _addController.dispose();
    _addFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final total = _countTotal(widget.items);
    final checked = _countChecked(widget.items);
    final percent = total > 0 ? checked / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress bar
        if (widget.showProgress && total > 0)
          ChecklistProgressBar(
            checked: checked,
            total: total,
            percent: percent,
            isDark: isDark,
            theme: theme,
          ),

        if (widget.showProgress && total > 0)
          SizedBox(height: EdenSpacing.space3),

        // Items list
        if (widget.allowReorder && !widget.readOnly)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: widget.items.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = widget.items.removeAt(oldIndex);
                widget.items.insert(newIndex, item);
              });
              widget.onReorder?.call(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              return _buildItemTile(
                key: ValueKey(widget.items[index].id),
                item: widget.items[index],
                index: index,
                depth: 0,
                isDark: isDark,
                theme: theme,
                parentItems: widget.items,
              );
            },
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              return _buildItemTile(
                item: widget.items[index],
                index: index,
                depth: 0,
                isDark: isDark,
                theme: theme,
                parentItems: widget.items,
              );
            },
          ),

        // Add item field
        if (widget.allowAdd && !widget.readOnly) ...[
          SizedBox(height: EdenSpacing.space2),
          _buildAddField(isDark, theme),
        ],

        // Completion summary
        if (widget.showCompletionSummary && total > 0) ...[
          SizedBox(height: EdenSpacing.space4),
          CompletionSummary(
            checked: checked,
            total: total,
            percent: percent,
            allRequiredDone: _allRequiredComplete(widget.items),
            isDark: isDark,
            theme: theme,
          ),
        ],
      ],
    );
  }

  Widget _buildItemTile({
    Key? key,
    required EdenChecklistItem item,
    required int index,
    required int depth,
    required bool isDark,
    required ThemeData theme,
    required List<EdenChecklistItem> parentItems,
  }) {
    // Section header
    if (item.isSection) {
      return _buildSectionHeader(
        key: key,
        item: item,
        index: index,
        isDark: isDark,
        theme: theme,
      );
    }

    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final noteColor =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    final tile = Container(
      key: key,
      margin: EdgeInsets.only(
        left: depth * EdenSpacing.space6,
        bottom: EdenSpacing.space1,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Drag handle
              if (widget.allowReorder && !widget.readOnly && depth == 0)
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: EdgeInsets.only(right: EdenSpacing.space1),
                    child: Icon(
                      Icons.drag_indicator,
                      size: 18,
                      color: isDark
                          ? EdenColors.neutral[500]
                          : EdenColors.neutral[400],
                    ),
                  ),
                ),

              // Checkbox
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: item.isChecked,
                  onChanged: widget.readOnly
                      ? null
                      : (value) => _onCheckChanged(item, value),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              SizedBox(width: EdenSpacing.space2),

              // Type icon
              if (item.type != EdenChecklistItemType.checkbox) ...[
                TypeIcon(type: item.type, isDark: isDark),
                SizedBox(width: EdenSpacing.space1),
              ],

              // Title
              Expanded(
                child: Text(
                  item.title + (item.isRequired ? ' *' : ''),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    decoration:
                        item.isChecked ? TextDecoration.lineThrough : null,
                    color: item.isChecked
                        ? (isDark
                            ? EdenColors.neutral[500]
                            : EdenColors.neutral[400])
                        : null,
                    fontWeight: item.isRequired ? FontWeight.w600 : null,
                  ),
                ),
              ),

              // Note toggle
              if (!widget.readOnly)
                NoteToggle(
                  hasNote: item.note != null && item.note!.isNotEmpty,
                  isDark: isDark,
                  onTap: () {
                    setState(() {
                      item.note ??= '';
                    });
                  },
                ),
            ],
          ),

          // Note field
          if (item.note != null)
            Padding(
              padding: EdgeInsets.only(
                left: (widget.allowReorder && !widget.readOnly && depth == 0)
                    ? 24 + EdenSpacing.space1 + 24 + EdenSpacing.space2
                    : 24 + EdenSpacing.space2,
                bottom: EdenSpacing.space2,
                top: EdenSpacing.space1,
              ),
              child: widget.readOnly
                  ? Text(
                      item.note!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: noteColor,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : TextField(
                      controller: TextEditingController(text: item.note),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: noteColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add a note...',
                        hintStyle: theme.textTheme.bodySmall?.copyWith(
                          color: noteColor.withValues(alpha: 0.6),
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: EdenSpacing.space2,
                          vertical: EdenSpacing.space1,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: EdenRadii.borderRadiusSm,
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: EdenRadii.borderRadiusSm,
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                      maxLines: 2,
                      onChanged: (value) {
                        item.note = value;
                        widget.onItemChanged?.call(item);
                      },
                    ),
            ),

          // Children
          if (item.children.isNotEmpty)
            ...item.children.asMap().entries.map((entry) {
              return _buildItemTile(
                item: entry.value,
                index: entry.key,
                depth: depth + 1,
                isDark: isDark,
                theme: theme,
                parentItems: item.children,
              );
            }),
        ],
      ),
    );

    // Swipe to delete
    if (widget.allowDelete && !widget.readOnly && depth == 0) {
      return Dismissible(
        key: ValueKey('dismiss_${item.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: EdenSpacing.space4),
          color: EdenColors.error.withValues(alpha: 0.15),
          child: Icon(Icons.delete_outline, color: EdenColors.error),
        ),
        onDismissed: (_) {
          widget.onItemDeleted?.call(item.id);
        },
        child: tile,
      );
    }

    return tile;
  }

  Widget _buildSectionHeader({
    Key? key,
    required EdenChecklistItem item,
    required int index,
    required bool isDark,
    required ThemeData theme,
  }) {
    final isCollapsed = _collapsedSections.contains(item.id);
    final bgColor =
        isDark ? EdenColors.neutral[850]! : EdenColors.neutral[50]!;

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: '${item.sectionHeader}${isCollapsed ? ", collapsed" : ", expanded"}',
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isCollapsed) {
                  _collapsedSections.remove(item.id);
                } else {
                  _collapsedSections.add(item.id);
                }
              });
            },
            child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: EdenSpacing.space3,
              vertical: EdenSpacing.space2,
            ),
            margin: EdgeInsets.only(
              top: EdenSpacing.space2,
              bottom: EdenSpacing.space1,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: EdenRadii.borderRadiusSm,
            ),
            child: Row(
              children: [
                Icon(
                  isCollapsed
                      ? Icons.keyboard_arrow_right
                      : Icons.keyboard_arrow_down,
                  size: 20,
                  color: isDark
                      ? EdenColors.neutral[400]
                      : EdenColors.neutral[600],
                ),
                SizedBox(width: EdenSpacing.space2),
                Expanded(
                  child: Text(
                    item.sectionHeader!,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                // Section progress count
                if (item.children.isNotEmpty)
                  Text(
                    '${_countChecked(item.children)}/${_countTotal(item.children)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? EdenColors.neutral[400]
                          : EdenColors.neutral[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
        ),
        if (!isCollapsed)
          ...item.children.asMap().entries.map((entry) {
            return _buildItemTile(
              item: entry.value,
              index: entry.key,
              depth: 1,
              isDark: isDark,
              theme: theme,
              parentItems: item.children,
            );
          }),
      ],
    );
  }

  Widget _buildAddField(bool isDark, ThemeData theme) {
    if (!_showAddField) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () {
            setState(() => _showAddField = true);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _addFocus.requestFocus();
            });
          },
          icon: Icon(Icons.add, size: 18),
          label: const Text('Add item'),
        ),
      );
    }

    final borderColor =
        isDark ? EdenColors.neutral[600]! : EdenColors.neutral[300]!;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _addController,
            focusNode: _addFocus,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'New item...',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: EdenSpacing.space3,
                vertical: EdenSpacing.space2,
              ),
              border: OutlineInputBorder(
                borderRadius: EdenRadii.borderRadiusSm,
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: EdenRadii.borderRadiusSm,
                borderSide: BorderSide(color: borderColor),
              ),
            ),
            onSubmitted: (_) => _submitNewItem(),
          ),
        ),
        SizedBox(width: EdenSpacing.space2),
        IconButton(
          onPressed: _submitNewItem,
          icon: const Icon(Icons.check, size: 20),
          tooltip: 'Add',
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _showAddField = false;
              _addController.clear();
            });
          },
          icon: const Icon(Icons.close, size: 20),
          tooltip: 'Cancel',
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    );
  }
}

