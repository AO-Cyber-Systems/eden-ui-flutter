import 'package:flutter/material.dart';

import '../theme/eden_status_palette.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import 'eden_app_mode.dart' show kEdenAppModeCompactMax;
import 'eden_card.dart';
import 'eden_data_table.dart';
import 'eden_empty_state.dart';
import 'eden_input.dart';
import 'eden_modal.dart';
import 'eden_select.dart';
import 'eden_tabs.dart';

/// Section identifier for the [EdenPriceBookBuilder] 4-section navigation.
enum EdenPriceBookSection { categories, items, tiers, taxes }

/// Immutable container for the pricebook's tax-rate matrix.
@immutable
class EdenPriceBookTaxMatrix {
  const EdenPriceBookTaxMatrix({
    required this.jurisdictions,
    required this.itemTypes,
    required this.rates,
  });

  final List<String> jurisdictions;
  final List<String> itemTypes;
  final Map<String, Map<String, double>> rates;

  /// Returns the rate for `jurisdiction × itemType`, falling back to `0.0`
  /// when either key is missing. Never throws.
  double rateFor(String jurisdiction, String itemType) {
    final j = rates[jurisdiction];
    if (j == null) return 0.0;
    return j[itemType] ?? 0.0;
  }

  EdenPriceBookTaxMatrix copyWith({
    List<String>? jurisdictions,
    List<String>? itemTypes,
    Map<String, Map<String, double>>? rates,
  }) =>
      EdenPriceBookTaxMatrix(
        jurisdictions: jurisdictions ?? this.jurisdictions,
        itemTypes: itemTypes ?? this.itemTypes,
        rates: rates ?? this.rates,
      );
}

/// Optional 3-tier good-better-best presentation for upsell items.
@immutable
class EdenPriceBookGoodBetterBest {
  const EdenPriceBookGoodBetterBest({
    required this.goodPrice,
    required this.goodLabel,
    required this.betterPrice,
    required this.betterLabel,
    required this.bestPrice,
    required this.bestLabel,
  });

  final double goodPrice;
  final String goodLabel;
  final double betterPrice;
  final String betterLabel;
  final double bestPrice;
  final String bestLabel;

  EdenPriceBookGoodBetterBest copyWith({
    double? goodPrice,
    String? goodLabel,
    double? betterPrice,
    String? betterLabel,
    double? bestPrice,
    String? bestLabel,
  }) =>
      EdenPriceBookGoodBetterBest(
        goodPrice: goodPrice ?? this.goodPrice,
        goodLabel: goodLabel ?? this.goodLabel,
        betterPrice: betterPrice ?? this.betterPrice,
        betterLabel: betterLabel ?? this.betterLabel,
        bestPrice: bestPrice ?? this.bestPrice,
        bestLabel: bestLabel ?? this.bestLabel,
      );
}

/// Generic line item — consumer maps domain rows (HVAC SKU, salon service,
/// fuel grade) onto this shape.
@immutable
class EdenPriceBookItem {
  const EdenPriceBookItem({
    required this.id,
    required this.name,
    required this.description,
    required this.baseFlatRate,
    this.tierOverrides = const {},
    this.skuCode,
    this.laborHoursLabel,
    this.gbb,
  });

  final String id;
  final String name;
  final String description;
  final double baseFlatRate;

  /// `tierId -> price` override map. Empty when this item uses tier default
  /// markup (computed from [EdenPriceBookTier.defaultMarkupPct]).
  final Map<String, double> tierOverrides;

  final String? skuCode;
  final String? laborHoursLabel;
  final EdenPriceBookGoodBetterBest? gbb;

  EdenPriceBookItem copyWith({
    String? id,
    String? name,
    String? description,
    double? baseFlatRate,
    Map<String, double>? tierOverrides,
    String? skuCode,
    String? laborHoursLabel,
    EdenPriceBookGoodBetterBest? gbb,
    bool clearGbb = false,
  }) =>
      EdenPriceBookItem(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        baseFlatRate: baseFlatRate ?? this.baseFlatRate,
        tierOverrides: tierOverrides ?? this.tierOverrides,
        skuCode: skuCode ?? this.skuCode,
        laborHoursLabel: laborHoursLabel ?? this.laborHoursLabel,
        gbb: clearGbb ? null : (gbb ?? this.gbb),
      );
}

/// Category groups items. 1-level nesting only via [parentId].
@immutable
class EdenPriceBookCategory {
  const EdenPriceBookCategory({
    required this.id,
    required this.name,
    this.parentId,
    this.items = const [],
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String? parentId;
  final List<EdenPriceBookItem> items;
  final int sortOrder;

  EdenPriceBookCategory copyWith({
    String? id,
    String? name,
    String? parentId,
    List<EdenPriceBookItem>? items,
    int? sortOrder,
    bool clearParentId = false,
  }) =>
      EdenPriceBookCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        parentId: clearParentId ? null : (parentId ?? this.parentId),
        items: items ?? this.items,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}

/// Pricing tier (`Standard`, `Gold`, `Commercial`, etc.).
@immutable
class EdenPriceBookTier {
  const EdenPriceBookTier({
    required this.id,
    required this.name,
    this.defaultMarkupPct,
    this.description,
  });

  final String id;
  final String name;

  /// Default markup as a signed fraction (`-0.10` = 10% discount, `+0.15`
  /// = 15% markup). Used when an item has no entry in [EdenPriceBookItem.tierOverrides].
  final double? defaultMarkupPct;

  final String? description;

  EdenPriceBookTier copyWith({
    String? id,
    String? name,
    double? defaultMarkupPct,
    String? description,
    bool clearDefaultMarkupPct = false,
  }) =>
      EdenPriceBookTier(
        id: id ?? this.id,
        name: name ?? this.name,
        defaultMarkupPct: clearDefaultMarkupPct
            ? null
            : (defaultMarkupPct ?? this.defaultMarkupPct),
        description: description ?? this.description,
      );
}

/// Top-level immutable container for an entire pricebook.
@immutable
class EdenPriceBookData {
  const EdenPriceBookData({
    required this.categories,
    required this.tiers,
    required this.taxMatrix,
  });

  final List<EdenPriceBookCategory> categories;
  final List<EdenPriceBookTier> tiers;
  final EdenPriceBookTaxMatrix taxMatrix;
}

/// Edited snapshot emitted via [EdenPriceBookBuilder.onSave] /
/// [EdenPriceBookBuilder.onDraftChange].
@immutable
class EdenPriceBookDraft {
  const EdenPriceBookDraft({
    required this.categories,
    required this.tiers,
    required this.taxMatrix,
  });

  final List<EdenPriceBookCategory> categories;
  final List<EdenPriceBookTier> tiers;
  final EdenPriceBookTaxMatrix taxMatrix;
}

/// Foundational 4-section pricebook editor (categories / items / tiers /
/// taxes). Generic across trades / salon / fuel verticals — consumer maps
/// domain rows into [EdenPriceBookItem].
///
/// **Read-only mode** hides all add / remove / edit affordances and the
/// save button; the data view stays visible.
///
/// **Dirty-state tracking** via an internal mutation counter; emits
/// `onDraftChange` on every mutation and `onSave` when the user explicitly
/// confirms.
class EdenPriceBookBuilder extends StatefulWidget {
  const EdenPriceBookBuilder({
    super.key,
    required this.initialData,
    required this.onSave,
    this.onDraftChange,
    this.readOnly = false,
    this.itemPickerSlot,
    this.initialSection = EdenPriceBookSection.categories,
  });

  final EdenPriceBookData initialData;
  final ValueChanged<EdenPriceBookDraft> onSave;
  final ValueChanged<EdenPriceBookDraft>? onDraftChange;
  final bool readOnly;
  final Widget? itemPickerSlot;
  final EdenPriceBookSection initialSection;

  @override
  State<EdenPriceBookBuilder> createState() => _EdenPriceBookBuilderState();
}

class _EdenPriceBookBuilderState extends State<EdenPriceBookBuilder> {
  late List<EdenPriceBookCategory> _categories;
  late List<EdenPriceBookTier> _tiers;
  late EdenPriceBookTaxMatrix _taxMatrix;
  late EdenPriceBookSection _section;
  String? _selectedCategoryId;

  int _mutationCount = 0;
  int _savedMutationCount = 0;

  // Lazy controllers for tax-matrix cells — keyed by `"$jurisdiction-$itemType"`.
  final Map<String, TextEditingController> _taxControllers = {};

  bool get isDirty => _mutationCount != _savedMutationCount;

  EdenPriceBookDraft get _currentDraft => EdenPriceBookDraft(
        categories: List.unmodifiable(_categories),
        tiers: List.unmodifiable(_tiers),
        taxMatrix: _taxMatrix,
      );

  @override
  void initState() {
    super.initState();
    _adoptInitialData();
    _section = widget.initialSection;
  }

  void _adoptInitialData() {
    _categories = List.from(widget.initialData.categories);
    _tiers = List.from(widget.initialData.tiers);
    _taxMatrix = widget.initialData.taxMatrix;
    _selectedCategoryId = _categories.isNotEmpty ? _categories.first.id : null;
    _mutationCount = 0;
    _savedMutationCount = 0;
  }

  @override
  void didUpdateWidget(covariant EdenPriceBookBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset only when the consumer passes a NEW identity for initialData.
    // Value-equal updates don't trigger reset (avoids losing section state).
    if (!identical(oldWidget.initialData, widget.initialData)) {
      setState(_adoptInitialData);
    }
  }

  @override
  void dispose() {
    for (final c in _taxControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    _mutationCount++;
    widget.onDraftChange?.call(_currentDraft);
  }

  void _revert() {
    setState(_adoptInitialData);
  }

  void _save() {
    widget.onSave(_currentDraft);
    setState(() {
      _savedMutationCount = _mutationCount;
    });
  }

  TextEditingController _taxControllerFor(String j, String t, double initial) {
    final key = '$j-$t';
    return _taxControllers.putIfAbsent(
      key,
      () => TextEditingController(text: initial.toStringAsFixed(4)),
    );
  }

  // ───────────────────── Categories mutators ──────────────────────

  void _addCategory() {
    final id = 'cat-${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _categories = [
        ..._categories,
        EdenPriceBookCategory(id: id, name: 'New category', items: const []),
      ];
      _selectedCategoryId = id;
    });
    _markDirty();
  }

  void _renameCategory(String id, String name) {
    setState(() {
      _categories = _categories
          .map((c) => c.id == id ? c.copyWith(name: name) : c)
          .toList();
    });
    _markDirty();
  }

  void _deleteCategory(String id) {
    setState(() {
      _categories = _categories.where((c) => c.id != id).toList();
      if (_selectedCategoryId == id) {
        _selectedCategoryId =
            _categories.isNotEmpty ? _categories.first.id : null;
      }
    });
    _markDirty();
  }

  void _reorderCategory(int oldIndex, int newIndex) {
    // ReorderableListView newIndex quirk: when moving DOWN, newIndex is the
    // index AFTER removal. Subtract 1 so consumers don't see off-by-one.
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    setState(() {
      final next = List<EdenPriceBookCategory>.from(_categories);
      final c = next.removeAt(oldIndex);
      next.insert(adjusted, c);
      _categories = next;
    });
    _markDirty();
  }

  // ───────────────────── Item mutators ──────────────────────

  void _updateItem(String categoryId, EdenPriceBookItem updated) {
    setState(() {
      _categories = _categories.map((c) {
        if (c.id != categoryId) return c;
        return c.copyWith(
          items: c.items.map((i) => i.id == updated.id ? updated : i).toList(),
        );
      }).toList();
    });
    _markDirty();
  }

  void _removeItem(String categoryId, String itemId) {
    setState(() {
      _categories = _categories.map((c) {
        if (c.id != categoryId) return c;
        return c.copyWith(
          items: c.items.where((i) => i.id != itemId).toList(),
        );
      }).toList();
    });
    _markDirty();
  }

  // ───────────────────── Tier mutators ──────────────────────

  void _addTier() {
    final id = 'tier-${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _tiers = [..._tiers, EdenPriceBookTier(id: id, name: 'New tier')];
    });
    _markDirty();
  }

  void _updateTier(EdenPriceBookTier updated) {
    setState(() {
      _tiers = _tiers.map((t) => t.id == updated.id ? updated : t).toList();
    });
    _markDirty();
  }

  // ───────────────────── Tax mutators ──────────────────────

  void _updateTaxRate(String jurisdiction, String itemType, double rate) {
    final next = Map<String, Map<String, double>>.from(_taxMatrix.rates);
    final jurMap =
        Map<String, double>.from(next[jurisdiction] ?? <String, double>{});
    jurMap[itemType] = rate;
    next[jurisdiction] = jurMap;
    setState(() {
      _taxMatrix = _taxMatrix.copyWith(rates: next);
    });
    _markDirty();
  }

  // ────────────────────────── Build ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<EdenStatusPalette>();
    return LayoutBuilder(builder: (ctx, constraints) {
      final isNarrow = constraints.maxWidth <
          900; // breakpoint: 900 — price-book two-pane fold
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.readOnly && isDirty) _DirtyBanner(onCancel: _revert),
          if (!widget.readOnly)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: EdenSpacing.space3,
                vertical: EdenSpacing.space2,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: isDirty ? _save : null,
                  child: const Text('Save'),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space3,
            ),
            child: _buildSectionNav(isNarrow),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(EdenSpacing.space3),
              child: _buildSectionContent(palette, isNarrow),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSectionNav(bool isNarrow) {
    if (isNarrow) {
      return EdenSelect<EdenPriceBookSection>(
        value: _section,
        options: const [
          EdenSelectOption(
              value: EdenPriceBookSection.categories, label: 'Categories'),
          EdenSelectOption(value: EdenPriceBookSection.items, label: 'Items'),
          EdenSelectOption(value: EdenPriceBookSection.tiers, label: 'Tiers'),
          EdenSelectOption(value: EdenPriceBookSection.taxes, label: 'Taxes'),
        ],
        onChanged: (s) {
          if (s != null) setState(() => _section = s);
        },
      );
    }
    final index = _section.index;
    return EdenTabs(
      tabs: const [
        EdenTabItem(label: 'Categories'),
        EdenTabItem(label: 'Items'),
        EdenTabItem(label: 'Tiers'),
        EdenTabItem(label: 'Taxes'),
      ],
      selectedIndex: index,
      onChanged: (i) =>
          setState(() => _section = EdenPriceBookSection.values[i]),
    );
  }

  Widget _buildSectionContent(EdenStatusPalette? palette, bool isNarrow) {
    switch (_section) {
      case EdenPriceBookSection.categories:
        return _buildCategoriesSection(palette);
      case EdenPriceBookSection.items:
        return _buildItemsSection(palette, isNarrow);
      case EdenPriceBookSection.tiers:
        return _buildTiersSection(palette);
      case EdenPriceBookSection.taxes:
        return _buildTaxesSection(palette, isNarrow);
    }
  }

  // ─────────────────────── Categories ────────────────────────

  Widget _buildCategoriesSection(EdenStatusPalette? palette) {
    if (_categories.isEmpty) {
      return EdenEmptyState(
        title: 'No categories yet',
        description:
            'Create your first category to start organizing your pricebook.',
        action: widget.readOnly
            ? null
            : ElevatedButton(
                onPressed: _addCategory,
                child: const Text('Create your first category'),
              ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.readOnly)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const Key('price-book-add-category'),
              onPressed: _addCategory,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add category'),
            ),
          ),
        Flexible(
          child: widget.readOnly
              ? ListView.builder(
                  shrinkWrap: true,
                  itemCount: _categories.length,
                  itemBuilder: (ctx, i) => _categoryTile(_categories[i], i),
                )
              : ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _categories.length,
                  onReorder: _reorderCategory,
                  itemBuilder: (ctx, i) {
                    final c = _categories[i];
                    return _categoryTile(c, i, key: Key('cat-${c.id}'));
                  },
                ),
        ),
      ],
    );
  }

  Widget _categoryTile(EdenPriceBookCategory c, int i, {Key? key}) {
    final selected = c.id == _selectedCategoryId;
    return InkWell(
      key: key,
      onTap: () => setState(() => _selectedCategoryId = c.id),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space3,
          vertical: EdenSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
              : null,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                c.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ),
            Text(
              '${c.items.length} items',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            if (!widget.readOnly) ...[
              IconButton(
                key: Key('cat-rename-${c.id}'),
                icon: const Icon(Icons.edit_outlined, size: 16),
                tooltip: 'Rename',
                onPressed: () => _showRenameDialog(c),
              ),
              IconButton(
                key: Key('cat-delete-${c.id}'),
                icon: const Icon(Icons.delete_outline, size: 16),
                tooltip: 'Delete',
                onPressed: () => _confirmDeleteCategory(c),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameDialog(EdenPriceBookCategory c) async {
    final controller = TextEditingController(text: c.name);
    await EdenModal.show<void>(
      context,
      title: 'Rename category',
      child: EdenInput(controller: controller, label: 'Name'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            _renameCategory(c.id, controller.text);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteCategory(EdenPriceBookCategory c) async {
    final confirmed = await EdenModal.show<bool>(
      context,
      title: 'Delete category?',
      child: Text('Delete "${c.name}" and all its items?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
    if (confirmed == true) {
      _deleteCategory(c.id);
    }
  }

  // ────────────────────────── Items ───────────────────────────

  Widget _buildItemsSection(EdenStatusPalette? palette, bool isNarrow) {
    if (_selectedCategoryId == null) {
      return const EdenEmptyState(
        title: 'Select a category to view items',
      );
    }
    final category = _categories.firstWhere((c) => c.id == _selectedCategoryId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.itemPickerSlot != null) ...[
          widget.itemPickerSlot!,
          const SizedBox(height: EdenSpacing.space3),
        ],
        Text(category.name, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: EdenSpacing.space2),
        if (category.items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: EdenSpacing.space3),
            child: Text('No items in this category yet.'),
          )
        else
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: category.items.length,
              itemBuilder: (ctx, i) {
                final item = category.items[i];
                return _itemRow(category, item, palette);
              },
            ),
          ),
      ],
    );
  }

  Widget _itemRow(EdenPriceBookCategory cat, EdenPriceBookItem item,
      EdenStatusPalette? palette) {
    final overrides = item.tierOverrides.length;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space3,
        vertical: EdenSpacing.space2,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.name, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  item.description,
                  style: Theme.of(context).textTheme.labelSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: widget.readOnly
                ? Text('\$${item.baseFlatRate.toStringAsFixed(2)}')
                : _BaseRateInput(
                    initial: item.baseFlatRate,
                    onChanged: (v) =>
                        _updateItem(cat.id, item.copyWith(baseFlatRate: v)),
                  ),
          ),
          const SizedBox(width: 8),
          if (item.laborHoursLabel != null)
            Tooltip(
              message: item.laborHoursLabel!,
              child: const Icon(Icons.build, size: 14),
            ),
          if (item.skuCode != null) ...[
            const SizedBox(width: 4),
            Text(item.skuCode!, style: Theme.of(context).textTheme.labelSmall),
          ],
          const SizedBox(width: 8),
          if (overrides > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    (palette?.infoBg ?? EdenColors.info.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$overrides overrides',
                style: TextStyle(
                  fontSize: 10,
                  color: palette?.infoFg ?? EdenColors.info,
                ),
              ),
            ),
          const SizedBox(width: 8),
          if (item.gbb != null && !widget.readOnly)
            TextButton(
              key: Key('item-gbb-${item.id}'),
              onPressed: () => _showGbbModal(cat, item),
              child: const Text('Edit GBB'),
            ),
          if (item.gbb != null && widget.readOnly)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: palette?.successBg ??
                    EdenColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('GBB',
                  style: TextStyle(
                    fontSize: 10,
                    color: palette?.successFg ?? EdenColors.success,
                  )),
            ),
          if (!widget.readOnly)
            IconButton(
              key: Key('item-remove-${item.id}'),
              icon: const Icon(Icons.delete_outline, size: 16),
              onPressed: () => _removeItem(cat.id, item.id),
            ),
        ],
      ),
    );
  }

  Future<void> _showGbbModal(
      EdenPriceBookCategory cat, EdenPriceBookItem item) async {
    final gbb = item.gbb!;
    final goodCtrl =
        TextEditingController(text: gbb.goodPrice.toStringAsFixed(2));
    final betterCtrl =
        TextEditingController(text: gbb.betterPrice.toStringAsFixed(2));
    final bestCtrl =
        TextEditingController(text: gbb.bestPrice.toStringAsFixed(2));
    final goodLabelCtrl = TextEditingController(text: gbb.goodLabel);
    final betterLabelCtrl = TextEditingController(text: gbb.betterLabel);
    final bestLabelCtrl = TextEditingController(text: gbb.bestLabel);

    Widget col(String tier, TextEditingController price,
            TextEditingController label) =>
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tier, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            EdenInput(controller: label, label: 'Label'),
            const SizedBox(height: 6),
            EdenInput(
                controller: price,
                label: 'Price',
                keyboardType: TextInputType.number),
          ],
        );

    await EdenModal.show<void>(
      context,
      title: 'Edit Good / Better / Best — ${item.name}',
      size: EdenModalSize.lg,
      child: LayoutBuilder(builder: (ctx, c) {
        final wide = c.maxWidth >= kEdenAppModeCompactMax;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: col('Good', goodCtrl, goodLabelCtrl)),
              const SizedBox(width: 12),
              Expanded(child: col('Better', betterCtrl, betterLabelCtrl)),
              const SizedBox(width: 12),
              Expanded(child: col('Best', bestCtrl, bestLabelCtrl)),
            ],
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            col('Good', goodCtrl, goodLabelCtrl),
            const SizedBox(height: 12),
            col('Better', betterCtrl, betterLabelCtrl),
            const SizedBox(height: 12),
            col('Best', bestCtrl, bestLabelCtrl),
          ],
        );
      }),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedGbb = EdenPriceBookGoodBetterBest(
              goodPrice: double.tryParse(goodCtrl.text) ?? gbb.goodPrice,
              goodLabel: goodLabelCtrl.text,
              betterPrice: double.tryParse(betterCtrl.text) ?? gbb.betterPrice,
              betterLabel: betterLabelCtrl.text,
              bestPrice: double.tryParse(bestCtrl.text) ?? gbb.bestPrice,
              bestLabel: bestLabelCtrl.text,
            );
            _updateItem(cat.id, item.copyWith(gbb: updatedGbb));
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  // ────────────────────────── Tiers ───────────────────────────

  Widget _buildTiersSection(EdenStatusPalette? palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.readOnly)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const Key('price-book-add-tier'),
              onPressed: _addTier,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add tier'),
            ),
          ),
        if (_tiers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: EdenSpacing.space3),
            child: Text('No tiers configured.'),
          )
        else
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _tiers.length,
              itemBuilder: (ctx, i) => _tierCard(_tiers[i]),
            ),
          ),
      ],
    );
  }

  Widget _tierCard(EdenPriceBookTier t) {
    final overrideCount = _categories
        .expand((c) => c.items)
        .where((i) => i.tierOverrides.containsKey(t.id))
        .length;
    final markupPct = t.defaultMarkupPct == null
        ? '—'
        : '${(t.defaultMarkupPct! * 100).toStringAsFixed(1)}%';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: EdenCard(
        child: Padding(
          padding: const EdgeInsets.all(EdenSpacing.space3),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.name, style: Theme.of(context).textTheme.bodyLarge),
                    if (t.description != null)
                      Text(t.description!,
                          style: Theme.of(context).textTheme.labelSmall),
                    Text('$overrideCount item overrides',
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: widget.readOnly
                    ? Text('Markup $markupPct')
                    : _MarkupInput(
                        initialPct: t.defaultMarkupPct,
                        onChanged: (v) =>
                            _updateTier(t.copyWith(defaultMarkupPct: v)),
                      ),
              ),
              if (!widget.readOnly)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _section = EdenPriceBookSection.items;
                    });
                  },
                  child: const Text('Edit overrides'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────── Taxes ───────────────────────────

  Widget _buildTaxesSection(EdenStatusPalette? palette, bool isNarrow) {
    if (_taxMatrix.jurisdictions.isEmpty || _taxMatrix.itemTypes.isEmpty) {
      return EdenEmptyState(
        title: 'No tax matrix configured',
        description:
            'Add jurisdictions and item types to start configuring tax rates.',
        action: widget.readOnly
            ? null
            : ElevatedButton(
                onPressed: () {
                  setState(() {
                    _taxMatrix = const EdenPriceBookTaxMatrix(
                      jurisdictions: ['CA'],
                      itemTypes: ['service', 'parts'],
                      rates: {
                        'CA': {'service': 0.0825, 'parts': 0.0825}
                      },
                    );
                  });
                  _markDirty();
                },
                child: const Text('Configure jurisdictions'),
              ),
      );
    }
    if (isNarrow) {
      // Vertical-stacked jurisdiction cards at narrow widths.
      return ListView(
        shrinkWrap: true,
        children: [
          for (final j in _taxMatrix.jurisdictions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: EdenCard(
                child: Padding(
                  padding: const EdgeInsets.all(EdenSpacing.space3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(j, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      for (final t in _taxMatrix.itemTypes)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(child: Text(t)),
                              SizedBox(
                                width: 100,
                                child: _TaxRateCell(
                                  controller: _taxControllerFor(
                                      j, t, _taxMatrix.rateFor(j, t)),
                                  readOnly: widget.readOnly,
                                  onChanged: (v) => _updateTaxRate(j, t, v),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    }
    // Wide layout — EdenDataTable.dense
    return EdenDataTable.dense(
      columns: [
        const EdenTableColumn(label: 'Jurisdiction', flex: 2),
        for (final t in _taxMatrix.itemTypes)
          EdenTableColumn(label: t, flex: 2),
      ],
      rows: _taxMatrix.jurisdictions
          .map(
            (j) => EdenTableRow(cells: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(j),
              ),
              for (final t in _taxMatrix.itemTypes)
                _TaxRateCell(
                  controller: _taxControllerFor(j, t, _taxMatrix.rateFor(j, t)),
                  readOnly: widget.readOnly,
                  onChanged: (v) => _updateTaxRate(j, t, v),
                ),
            ]),
          )
          .toList(),
    );
  }
}

class _DirtyBanner extends StatelessWidget {
  const _DirtyBanner({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<EdenStatusPalette>();
    final bg = palette?.warningBg ?? EdenColors.warning.withValues(alpha: 0.1);
    final fg = palette?.warningFg ?? EdenColors.warning;
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space3,
        vertical: EdenSpacing.space2,
      ),
      child: Row(
        children: [
          Icon(Icons.edit_outlined, size: 16, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Unsaved changes — Save or Cancel',
              style: TextStyle(color: fg),
            ),
          ),
          TextButton(
            key: const Key('price-book-cancel-changes'),
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _BaseRateInput extends StatefulWidget {
  const _BaseRateInput({required this.initial, required this.onChanged});

  final double initial;
  final ValueChanged<double> onChanged;

  @override
  State<_BaseRateInput> createState() => _BaseRateInputState();
}

class _BaseRateInputState extends State<_BaseRateInput> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initial.toStringAsFixed(2));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EdenInput(
      controller: _ctrl,
      keyboardType: TextInputType.number,
      onSubmitted: (s) {
        final v = double.tryParse(s);
        if (v != null) widget.onChanged(v);
      },
      onChanged: (s) {
        final v = double.tryParse(s);
        if (v != null) widget.onChanged(v);
      },
    );
  }
}

class _MarkupInput extends StatefulWidget {
  const _MarkupInput({required this.initialPct, required this.onChanged});

  final double? initialPct;
  final ValueChanged<double?> onChanged;

  @override
  State<_MarkupInput> createState() => _MarkupInputState();
}

class _MarkupInputState extends State<_MarkupInput> {
  late final TextEditingController _ctrl = TextEditingController(
      text: widget.initialPct == null
          ? ''
          : (widget.initialPct! * 100).toStringAsFixed(1));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EdenInput(
      controller: _ctrl,
      hint: '%',
      keyboardType: TextInputType.number,
      onChanged: (s) {
        if (s.isEmpty) {
          widget.onChanged(null);
        } else {
          final v = double.tryParse(s);
          if (v != null) widget.onChanged(v / 100.0);
        }
      },
    );
  }
}

class _TaxRateCell extends StatelessWidget {
  const _TaxRateCell({
    required this.controller,
    required this.readOnly,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool readOnly;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    if (readOnly) {
      final v = double.tryParse(controller.text) ?? 0.0;
      return Text('${(v * 100).toStringAsFixed(2)}%');
    }
    // Use a bare TextField so the cell fits within the dense table's 32pt row.
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 13),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        border: OutlineInputBorder(),
      ),
      onChanged: (s) {
        final v = double.tryParse(s);
        if (v != null) onChanged(v);
      },
    );
  }
}
