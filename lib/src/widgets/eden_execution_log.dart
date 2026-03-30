import 'package:flutter/material.dart';

import '../tokens/spacing.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

/// Result status for display in [EdenExecutionLog].
class EdenExecutionResult {
  const EdenExecutionResult({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  static const success =
      EdenExecutionResult(label: 'Success', color: Color(0xFF22C55E));
  static const failure =
      EdenExecutionResult(label: 'Failure', color: Color(0xFFEF4444));
  static const partial =
      EdenExecutionResult(label: 'Partial', color: Color(0xFFF59E0B));
}

/// A single record in an [EdenExecutionLog].
class EdenExecutionRecord {
  const EdenExecutionRecord({
    required this.timestamp,
    required this.trigger,
    required this.actions,
    required this.result,
    this.duration,
    this.errorMessage,
  });

  final DateTime timestamp;
  final String trigger;
  final List<String> actions;
  final EdenExecutionResult result;
  final Duration? duration;

  /// If present, the row is expandable to show this error detail.
  final String? errorMessage;
}

// ---------------------------------------------------------------------------
// Column definition
// ---------------------------------------------------------------------------

/// Defines the fixed-width columns. Override to customize headers.
class _Column {
  const _Column(this.label, this.width);
  final String label;
  final double? width; // null = expanded
}

const _columns = [
  _Column('Timestamp', 140),
  _Column('Trigger', 140),
  _Column('Actions', null),
  _Column('Result', 80),
  _Column('Duration', 80),
];

// ---------------------------------------------------------------------------
// Main widget
// ---------------------------------------------------------------------------

/// Fixed-column execution history log table with expandable error rows.
///
/// Displays timestamped records in a table layout with columns for
/// timestamp, trigger event, actions taken, result badge, and duration.
/// Rows with an [errorMessage] are expandable to show the detail.
///
/// ```dart
/// EdenExecutionLog(
///   records: [
///     EdenExecutionRecord(
///       timestamp: DateTime.now().subtract(Duration(minutes: 5)),
///       trigger: 'Project Created',
///       actions: ['Assign Tech', 'Send Notification'],
///       result: EdenExecutionResult.success,
///       duration: Duration(seconds: 12),
///     ),
///   ],
/// )
/// ```
class EdenExecutionLog extends StatelessWidget {
  const EdenExecutionLog({
    super.key,
    required this.records,
    this.emptyLabel = 'No execution history',
  });

  /// Records to display, sorted descending by timestamp.
  final List<EdenExecutionRecord> records;

  /// Text shown when [records] is empty.
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final sorted = [...records]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TableHeader(),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: EdenSpacing.space4),
            itemCount: sorted.length,
            itemBuilder: (context, index) =>
                _RecordRow(record: sorted[index]),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Table header
// ---------------------------------------------------------------------------

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: 10,
      ),
      child: Row(
        children: _columns.map((col) {
          final child = Text(col.label, style: style);
          return col.width != null
              ? SizedBox(width: col.width, child: child)
              : Expanded(child: child);
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Record row
// ---------------------------------------------------------------------------

class _RecordRow extends StatefulWidget {
  const _RecordRow({required this.record});

  final EdenExecutionRecord record;

  @override
  State<_RecordRow> createState() => _RecordRowState();
}

class _RecordRowState extends State<_RecordRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final record = widget.record;
    final hasError = record.errorMessage != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: hasError ? () => setState(() => _expanded = !_expanded) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 140,
                  child: Text(
                    _formatTimestamp(record.timestamp),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: Text(
                    record.trigger,
                    style: TextStyle(fontSize: 12, color: cs.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    record.actions.length > 3
                        ? '${record.actions.take(3).join(', ')}...'
                        : record.actions.join(', '),
                    style: TextStyle(fontSize: 12, color: cs.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: _ResultBadge(result: record.result),
                ),
                SizedBox(
                  width: 80,
                  child: Row(
                    children: [
                      Text(
                        record.duration != null
                            ? _formatDuration(record.duration!)
                            : '--',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                      if (hasError) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                          size: 14,
                          color: cs.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded && hasError)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              record.errorMessage!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
            ),
          ),
        Divider(
            height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Result badge
// ---------------------------------------------------------------------------

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.result});

  final EdenExecutionResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: result.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        result.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: result.color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Utilities
// ---------------------------------------------------------------------------

String _formatTimestamp(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return 'Today $h:$m';
  }
  if (diff.inDays == 1) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return 'Yesterday $h:$m';
  }
  return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

String _formatDuration(Duration d) {
  if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
  return '${d.inSeconds}s';
}
