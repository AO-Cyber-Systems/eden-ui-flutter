// EdenPackoutPage — truck-load checklist usage tracking page.
//
// Donor: AOCyber-Trades/trades-flutter/lib/features/field_crew/presentation/
// packout_page.dart (479 LOC). Port strips:
//   - flutter_riverpod (ConsumerStatefulWidget + ref.watch + ref.read +
//     ref.invalidate) → StatefulWidget + constructor props + callbacks.
//   - `package:trades/.../packout_item_model.dart` PackoutItem → inlined
//     EdenPackoutItem value type with copyWith.
//   - `ref.refresh(packoutItemsProvider).future` pull-to-refresh →
//     consumer-supplied `onRefresh: Future<void> Function()?`.
//
// Library renders the UX; persistence + fetching are consumer
// responsibilities via callback props.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/spacing.dart';
import 'eden_empty_state.dart';

/// A single line item in a packout (truck-load inventory) checklist.
class EdenPackoutItem {
  const EdenPackoutItem({
    required this.id,
    required this.itemName,
    required this.quantityLoaded,
    required this.quantityUsed,
    required this.quantityReturned,
    required this.unit,
    this.sku,
    this.notes,
  });

  final String id;
  final String itemName;
  final String? sku;
  final int quantityLoaded;
  final int quantityUsed;
  final int quantityReturned;
  final String unit;
  final String? notes;

  EdenPackoutItem copyWith({
    int? quantityUsed,
    int? quantityReturned,
    String? notes,
  }) {
    return EdenPackoutItem(
      id: id,
      itemName: itemName,
      sku: sku,
      quantityLoaded: quantityLoaded,
      quantityUsed: quantityUsed ?? this.quantityUsed,
      quantityReturned: quantityReturned ?? this.quantityReturned,
      unit: unit,
      notes: notes ?? this.notes,
    );
  }
}

/// A proposed edit to an [EdenPackoutItem]. Captured locally in the page,
/// passed to `onSaveItem` for persistence.
class EdenPackoutEdit {
  const EdenPackoutEdit({
    required this.used,
    required this.returned,
    this.notes,
  });

  final int used;
  final int returned;
  final String? notes;
}

/// Full-page truck-load usage-tracking checklist.
///
/// **Layout:** AppBar with title + optional [appointmentTitle] subtitle.
/// Body branches:
///   - `items.isEmpty` → [EdenEmptyState] "No packout items".
///   - non-empty → Column with summary strip + ListView of expandable
///     `_PackoutItemCard` widgets.
///
/// **State ownership:**
///   - `_localItems` (page-level) — mutable copy of [items]; updated when
///     `onSaveItem` returns a refreshed item.
///   - `_pendingEdits` (page-level) — map of item id → [EdenPackoutEdit].
///   - `_savingItems` (page-level) — set of item ids with an in-flight save.
///   - Each card's expand state is local to `_PackoutItemCardState`.
///
/// **didUpdateWidget:** when the parent passes a new [items] list,
/// `_localItems` resets and pending edits are cleared. This matches the
/// "new appointment" use case.
class EdenPackoutPage extends StatefulWidget {
  const EdenPackoutPage({
    super.key,
    required this.items,
    this.appointmentTitle,
    this.appBarTitle = 'Packout / Materials',
    this.onSaveItem,
    this.onRefresh,
  });

  final List<EdenPackoutItem> items;
  final String? appointmentTitle;
  final String appBarTitle;
  final Future<EdenPackoutItem> Function(
      EdenPackoutItem item, EdenPackoutEdit edit)? onSaveItem;
  final Future<void> Function()? onRefresh;

  @override
  State<EdenPackoutPage> createState() => _EdenPackoutPageState();
}

class _EdenPackoutPageState extends State<EdenPackoutPage> {
  late List<EdenPackoutItem> _localItems;
  final Map<String, EdenPackoutEdit> _pendingEdits = {};
  final Set<String> _savingItems = {};

  @override
  void initState() {
    super.initState();
    _localItems = List<EdenPackoutItem>.of(widget.items);
  }

  @override
  void didUpdateWidget(covariant EdenPackoutPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      setState(() {
        _localItems = List<EdenPackoutItem>.of(widget.items);
        _pendingEdits.clear();
        _savingItems.clear();
      });
    }
  }

  int _effectiveUsed(EdenPackoutItem item) {
    final pending = _pendingEdits[item.id];
    return pending?.used ?? item.quantityUsed;
  }

  Future<void> _saveItem(EdenPackoutItem item) async {
    final edit = _pendingEdits[item.id];
    if (edit == null) return;
    if (_savingItems.contains(item.id)) return;
    if (widget.onSaveItem == null) return;

    setState(() => _savingItems.add(item.id));
    try {
      final updated = await widget.onSaveItem!.call(item, edit);
      if (!mounted) return;
      setState(() {
        _pendingEdits.remove(item.id);
        final idx = _localItems.indexWhere((it) => it.id == item.id);
        if (idx >= 0) _localItems[idx] = updated;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Usage saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save: $e'),
        backgroundColor: const Color(0xFFEF4444),
      ));
    } finally {
      if (mounted) setState(() => _savingItems.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.appBarTitle),
            if (widget.appointmentTitle != null)
              Text(
                widget.appointmentTitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      body: _localItems.isEmpty
          ? const EdenEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No packout items',
              description: 'No materials were loaded for this appointment.',
            )
          : _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final totalUsed =
        _localItems.fold<int>(0, (s, it) => s + _effectiveUsed(it));
    final pendingCount = _pendingEdits.length;

    final list = ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space3),
      itemCount: _localItems.length,
      itemBuilder: (ctx, i) {
        final item = _localItems[i];
        return _PackoutItemCard(
          key: ValueKey('eden_packout_card_${item.id}'),
          item: item,
          isDirty: _pendingEdits.containsKey(item.id),
          isSaving: _savingItems.contains(item.id),
          onEditChanged: (edit) {
            setState(() {
              if (edit == null) {
                _pendingEdits.remove(item.id);
              } else {
                _pendingEdits[item.id] = edit;
              }
            });
          },
          onSave: () => _saveItem(item),
          canSave: widget.onSaveItem != null,
        );
      },
    );

    return Column(
      children: [
        // Summary strip
        Container(
          width: double.infinity,
          color: theme.colorScheme.surfaceContainerLow,
          padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space4, vertical: EdenSpacing.space3),
          child: Row(
            children: [
              Icon(Icons.inventory_2_outlined,
                  color: theme.colorScheme.primary),
              const SizedBox(width: EdenSpacing.space3),
              Expanded(
                child: Text(
                  '${_localItems.length} item types loaded · $totalUsed units used',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (pendingCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$pendingCount unsaved',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFF59E0B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: widget.onRefresh != null
              ? RefreshIndicator(
                  onRefresh: widget.onRefresh!,
                  child: list,
                )
              : list,
        ),
      ],
    );
  }
}

class _PackoutItemCard extends StatefulWidget {
  const _PackoutItemCard({
    super.key,
    required this.item,
    required this.isDirty,
    required this.isSaving,
    required this.onEditChanged,
    required this.onSave,
    required this.canSave,
  });

  final EdenPackoutItem item;
  final bool isDirty;
  final bool isSaving;
  final ValueChanged<EdenPackoutEdit?> onEditChanged;
  final VoidCallback onSave;
  final bool canSave;

  @override
  State<_PackoutItemCard> createState() => _PackoutItemCardState();
}

class _PackoutItemCardState extends State<_PackoutItemCard> {
  bool _expanded = false;
  late TextEditingController _usedController;
  late TextEditingController _returnedController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _usedController =
        TextEditingController(text: '${widget.item.quantityUsed}');
    _returnedController =
        TextEditingController(text: '${widget.item.quantityReturned}');
    _notesController = TextEditingController(text: widget.item.notes ?? '');
  }

  @override
  void didUpdateWidget(covariant _PackoutItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item && !widget.isDirty) {
      _usedController.text = '${widget.item.quantityUsed}';
      _returnedController.text = '${widget.item.quantityReturned}';
      _notesController.text = widget.item.notes ?? '';
    }
  }

  @override
  void dispose() {
    _usedController.dispose();
    _returnedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onAnyEditChanged() {
    final used = int.tryParse(_usedController.text) ?? widget.item.quantityUsed;
    final returned =
        int.tryParse(_returnedController.text) ?? widget.item.quantityReturned;
    final notes = _notesController.text;
    final origNotes = widget.item.notes ?? '';
    final isDirty = used != widget.item.quantityUsed ||
        returned != widget.item.quantityReturned ||
        notes != origNotes;
    if (isDirty) {
      widget.onEditChanged(EdenPackoutEdit(
        used: used,
        returned: returned,
        notes: notes.isEmpty ? null : notes,
      ));
    } else {
      widget.onEditChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final borderColor =
        widget.isDirty ? const Color(0xFFF59E0B) : theme.dividerColor;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space3, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: widget.isDirty ? 1.5 : 1),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(EdenSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.itemName,
                                  style: theme.textTheme.titleSmall),
                              if (item.sku != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'SKU: ${item.sku!}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (widget.isDirty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Unsaved',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFF59E0B),
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Icon(_expanded
                            ? Icons.expand_less
                            : Icons.expand_more),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                            child: _QuantityChip(
                                label: 'Loaded',
                                value:
                                    '${item.quantityLoaded} ${item.unit}')),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _QuantityChip(
                                label: 'Used',
                                value:
                                    '${widget.isDirty ? (int.tryParse(_usedController.text) ?? item.quantityUsed) : item.quantityUsed} ${item.unit}')),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _QuantityChip(
                                label: 'Returned',
                                value:
                                    '${widget.isDirty ? (int.tryParse(_returnedController.text) ?? item.quantityReturned) : item.quantityReturned} ${item.unit}')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(EdenSpacing.space4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key:
                                ValueKey('eden_packout_used_${item.id}'),
                            controller: _usedController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration:
                                const InputDecoration(labelText: 'Used'),
                            onChanged: (_) => _onAnyEditChanged(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            key: ValueKey(
                                'eden_packout_returned_${item.id}'),
                            controller: _returnedController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration:
                                const InputDecoration(labelText: 'Returned'),
                            onChanged: (_) => _onAnyEditChanged(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: ValueKey('eden_packout_notes_${item.id}'),
                      controller: _notesController,
                      maxLines: 2,
                      decoration:
                          const InputDecoration(labelText: 'Notes (optional)'),
                      onChanged: (_) => _onAnyEditChanged(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: (widget.isDirty &&
                                !widget.isSaving &&
                                widget.canSave)
                            ? widget.onSave
                            : null,
                        icon: widget.isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(widget.isSaving ? 'Saving...' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuantityChip extends StatelessWidget {
  const _QuantityChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: EdenSpacing.space2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
