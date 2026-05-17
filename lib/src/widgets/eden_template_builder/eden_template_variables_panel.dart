import 'package:flutter/material.dart';

import 'template_variables_registry.dart';

/// Right-rail variables panel — parity rows V-1 + V-3 + V-4 + V-5.
///
/// Reads from [EdenTemplateVariablesRegistry]; renders a search field +
/// grouped scrolling list of merge-variable tokens. Tap on a field fires
/// [onInsertField] with the full `{{group.field}}` token for direct paste
/// into the consumer's editor.
class EdenTemplateVariablesPanel extends StatefulWidget {
  const EdenTemplateVariablesPanel({
    super.key,
    required this.onInsertField,
    this.emptyPlaceholder,
  });

  /// Fired on tap with the full `{{group.field}}` token.
  final void Function(String token) onInsertField;

  /// Override for the empty-registry placeholder.
  final Widget? emptyPlaceholder;

  @override
  State<EdenTemplateVariablesPanel> createState() =>
      _EdenTemplateVariablesPanelState();
}

class _EdenTemplateVariablesPanelState
    extends State<EdenTemplateVariablesPanel> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allGroups = EdenTemplateVariablesRegistry.instance.all();
    if (allGroups.isEmpty) {
      return widget.emptyPlaceholder ?? const _DefaultEmptyPlaceholder();
    }

    final query = _searchQuery.toLowerCase();
    final filteredGroups = <String, List<String>>{};
    for (final entry in allGroups.entries) {
      final matching = query.isEmpty
          ? List<String>.from(entry.value)
          : entry.value
              .where((f) => f.toLowerCase().contains(query))
              .toList(growable: false);
      if (matching.isNotEmpty) filteredGroups[entry.key] = matching;
    }

    final sortedGroupNames = filteredGroups.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'VARIABLES',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search fields…',
                  isDense: true,
                  prefixIcon: Icon(Icons.search, size: 18),
                  border: OutlineInputBorder(),
                ),
                onChanged: (raw) => setState(() => _searchQuery = raw),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredGroups.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No matching fields',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final groupName in sortedGroupNames) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          groupName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      for (final field in filteredGroups[groupName]!)
                        _FieldRow(
                          token: '{{$groupName.$field}}',
                          onTap: () => widget
                              .onInsertField('{{$groupName.$field}}'),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _FieldRow extends StatefulWidget {
  const _FieldRow({required this.token, required this.onTap});

  final String token;
  final VoidCallback onTap;

  @override
  State<_FieldRow> createState() => _FieldRowState();
}

class _FieldRowState extends State<_FieldRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.18)
                : theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Text(
            widget.token,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontFamilyFallback: ['Courier', 'Menlo'],
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

class _DefaultEmptyPlaceholder extends StatelessWidget {
  const _DefaultEmptyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.code, size: 32),
          SizedBox(height: 8),
          Text('No variable groups registered'),
          SizedBox(height: 4),
          Text(
            'Consumers must call EdenTemplateVariablesRegistry.instance.register(group, fields) first.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
