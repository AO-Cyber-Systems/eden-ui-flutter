import 'package:flutter/material.dart';

import '../tokens/colors.dart';

/// A single immutable audit-log entry.
///
/// Federal use: HIPAA, FedRAMP, DOD audit trails. The hash-chain fields
/// ([prevHash] + [currHash]) are optional — consumer pre-computes the
/// chain (typically server-side) and passes it through; the widget
/// renders the verification badge.
///
/// Civilian re-use: SOC 2 audit trails, any compliance event stream.
@immutable
class EdenAuditLogEntry {
  const EdenAuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.actor,
    required this.action,
    required this.target,
    this.category,
    this.details = const {},
    this.prevHash,
    this.currHash,
    this.failed = false,
  });

  final String id;
  final DateTime timestamp;
  final String actor;
  final String action;
  final String target;
  final String? category;
  final Map<String, String> details;
  final String? prevHash;
  final String? currHash;
  final bool failed;
}

String _defaultTimestampFormat(DateTime t) {
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${t.year}-${pad(t.month)}-${pad(t.day)} '
      '${pad(t.hour)}:${pad(t.minute)}:${pad(t.second)}';
}

/// User-facing immutable activity stream for federal audit-trail UX.
///
/// Renders actor / action / target / timestamp with optional hash-chain
/// verification badge and failed-action indicator. Read-only by design —
/// audit logs MUST NOT be mutable from the UI layer.
///
/// Use this widget inside regulated dossiers (see also
/// [EdenCaseFileShell] in this Objective). Generic enough for civilian
/// re-use: SOC 2 audit trails, any compliance event stream.
///
/// **Library scope: display only.** Consumer computes the hash chain
/// (typically server-side) and pre-supplies broken-chain indices via
/// [brokenChainIndices].
class EdenAuditLogViewer extends StatefulWidget {
  const EdenAuditLogViewer({
    super.key,
    required this.entries,
    this.brokenChainIndices = const <int>{},
    this.timestampFormatter,
    this.showFilters = true,
  });

  final List<EdenAuditLogEntry> entries;

  /// Indices (into [entries]) where the hash chain is broken. The widget
  /// renders a red `link_off` icon + failed-chain Semantics on each.
  final Set<int> brokenChainIndices;

  /// Optional timestamp formatter. Defaults to `'YYYY-MM-DD HH:MM:SS'`.
  final String Function(DateTime)? timestampFormatter;

  /// Whether to render the actor-search + failed-only + category-chip
  /// filter row above the list.
  final bool showFilters;

  @override
  State<EdenAuditLogViewer> createState() => _EdenAuditLogViewerState();
}

class _EdenAuditLogViewerState extends State<EdenAuditLogViewer> {
  String _actorFilter = '';
  bool _failedOnly = false;
  final Set<String> _hiddenCategories = {};
  String? _expandedEntryId;

  String _formatTimestamp(DateTime t) =>
      (widget.timestampFormatter ?? _defaultTimestampFormat)(t);

  List<EdenAuditLogEntry> get _visibleEntries {
    var filtered = widget.entries;
    if (_actorFilter.isNotEmpty) {
      final q = _actorFilter.toLowerCase();
      filtered = filtered
          .where((e) => e.actor.toLowerCase().contains(q))
          .toList();
    }
    if (_failedOnly) {
      filtered = filtered.where((e) => e.failed).toList();
    }
    if (_hiddenCategories.isNotEmpty) {
      filtered = filtered
          .where((e) =>
              e.category == null || !_hiddenCategories.contains(e.category))
          .toList();
    }
    return filtered;
  }

  List<String> get _allCategories =>
      widget.entries
          .map((e) => e.category)
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();

  Widget _buildChainBadge(EdenAuditLogEntry entry, int originalIndex) {
    if (widget.brokenChainIndices.contains(originalIndex)) {
      return const Tooltip(
        message: 'Hash chain broken',
        child: Icon(Icons.link_off, color: EdenColors.error, size: 16),
      );
    }
    if (entry.prevHash != null && entry.currHash != null) {
      return const Tooltip(
        message: 'Hash chain verified',
        child: Icon(Icons.link, color: EdenColors.success, size: 16),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleEntries;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showFilters) _buildFilterRow(),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No audit log entries match the current filters'),
          )
        else
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: visible.length,
              itemBuilder: (context, idx) {
                final entry = visible[idx];
                final originalIndex = widget.entries.indexOf(entry);
                final expanded = _expandedEntryId == entry.id;
                final isBroken =
                    widget.brokenChainIndices.contains(originalIndex);
                final semanticLabel = StringBuffer('Audit: ${entry.actor} '
                    '${entry.action} ${entry.target} at '
                    '${_formatTimestamp(entry.timestamp)}');
                if (entry.failed) semanticLabel.write(', failed');
                if (isBroken) semanticLabel.write(', hash chain broken');
                return Semantics(
                  label: semanticLabel.toString(),
                  child: ListTile(
                    leading: entry.failed
                        ? const Icon(Icons.error_outline,
                            color: EdenColors.error)
                        : const Icon(Icons.history,
                            color: EdenColors.neutral),
                    title: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        Text(
                          '${entry.actor} ${entry.action} ${entry.target}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        if (entry.failed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: EdenColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'FAILED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: EdenColors.error,
                              ),
                            ),
                          ),
                        _buildChainBadge(entry, originalIndex),
                      ],
                    ),
                    subtitle: expanded
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_formatTimestamp(entry.timestamp),
                                  style: const TextStyle(fontSize: 11)),
                              const SizedBox(height: 4),
                              if (entry.details.isNotEmpty)
                                ...entry.details.entries.map(
                                  (kv) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 1),
                                    child: Text(
                                      '${kv.key}: ${kv.value}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : Text(_formatTimestamp(entry.timestamp),
                            style: const TextStyle(fontSize: 11)),
                    onTap: () => setState(
                      () => _expandedEntryId = expanded ? null : entry.id,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Filter by actor…',
              prefixIcon: Icon(Icons.search, size: 18),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _actorFilter = v),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Failed only',
                      style: TextStyle(fontSize: 12)),
                  Switch(
                    value: _failedOnly,
                    onChanged: (v) => setState(() => _failedOnly = v),
                  ),
                ],
              ),
              for (final cat in _allCategories)
                FilterChip(
                  label: Text(cat, style: const TextStyle(fontSize: 11)),
                  selected: !_hiddenCategories.contains(cat),
                  onSelected: (sel) {
                    setState(() {
                      if (sel) {
                        _hiddenCategories.remove(cat);
                      } else {
                        _hiddenCategories.add(cat);
                      }
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
