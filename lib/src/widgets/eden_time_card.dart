import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/eden_status_palette.dart';
import '../tokens/spacing.dart';
import 'eden_button.dart';
import 'eden_card.dart';
import 'eden_status_badge.dart';

/// Dispute state of a [EdenTimeCardEntry].
enum EdenTimeCardDispute { none, employeeDisputed, managerNote }

/// Approval actions emitted by [EdenTimeCard].
enum EdenTimeCardApprovalAction { approve, reject, requestEdit }

/// Event payload emitted on approval action.
@immutable
class EdenTimeCardApprovalEvent {
  const EdenTimeCardApprovalEvent({
    required this.entryId,
    required this.action,
    this.note,
  });

  final String entryId;
  final EdenTimeCardApprovalAction action;
  final String? note;
}

/// A single time-card row.
@immutable
class EdenTimeCardEntry {
  const EdenTimeCardEntry({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.clockedInAt,
    required this.clockedOutAt,
    required this.breaksAccumulated,
    this.dispute = EdenTimeCardDispute.none,
    this.note,
  });

  final String id;
  final String staffId;
  final String staffName;
  final DateTime clockedInAt;
  final DateTime? clockedOutAt;
  final Duration breaksAccumulated;
  final EdenTimeCardDispute dispute;
  final String? note;

  /// Worked duration excluding breaks; null when shift is still open.
  Duration get workedDuration {
    final out = clockedOutAt;
    if (out == null) return Duration.zero;
    return out.difference(clockedInAt) - breaksAccumulated;
  }

  bool get isOpen => clockedOutAt == null;

  EdenTimeCardEntry copyWith({
    String? id,
    String? staffId,
    String? staffName,
    DateTime? clockedInAt,
    DateTime? clockedOutAt,
    Duration? breaksAccumulated,
    EdenTimeCardDispute? dispute,
    String? note,
  }) {
    return EdenTimeCardEntry(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      clockedInAt: clockedInAt ?? this.clockedInAt,
      clockedOutAt: clockedOutAt ?? this.clockedOutAt,
      breaksAccumulated: breaksAccumulated ?? this.breaksAccumulated,
      dispute: dispute ?? this.dispute,
      note: note ?? this.note,
    );
  }
}

/// Manager approval queue for time-card entries (obj 015-05).
///
/// Table layout ≥600pt, stacked-card <600pt. Open-shift rows render
/// elapsed-time live and suppress approval actions.
class EdenTimeCard extends StatefulWidget {
  const EdenTimeCard({
    super.key,
    required this.entries,
    required this.onAction,
    this.showApprovalControls = true,
    this.currencyCode = 'USD',
  });

  final List<EdenTimeCardEntry> entries;
  final ValueChanged<EdenTimeCardApprovalEvent> onAction;
  final bool showApprovalControls;
  final String currencyCode;

  @override
  State<EdenTimeCard> createState() => _EdenTimeCardState();
}

class _EdenTimeCardState extends State<EdenTimeCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m}m';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Duration _displayedWorked(EdenTimeCardEntry e) {
    if (e.isOpen) {
      return DateTime.now().difference(e.clockedInAt) -
          e.breaksAccumulated;
    }
    return e.workedDuration;
  }

  Color? _rowTint(BuildContext context, EdenTimeCardEntry e) {
    if (e.dispute == EdenTimeCardDispute.employeeDisputed) {
      final palette = Theme.of(context).extension<EdenStatusPalette>() ??
          EdenStatusPalette.commercial();
      return palette.warningBg;
    }
    return null;
  }

  String _statusFor(EdenTimeCardEntry e) {
    if (e.isOpen) return 'pending'; // info badge in EdenStatusBadge
    if (e.dispute == EdenTimeCardDispute.employeeDisputed) {
      return 'warning';
    }
    return 'completed';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 600;
        if (narrow) return _stacked(context);
        return _table(context);
      },
    );
  }

  Widget _stacked(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in widget.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: EdenSpacing.space2),
              child: _stackedCard(context, e),
            ),
        ],
      ),
    );
  }

  Widget _stackedCard(BuildContext context, EdenTimeCardEntry e) {
    final theme = Theme.of(context);
    final tint = _rowTint(context, e);
    final worked = _displayedWorked(e);
    final workedLabel = _formatDuration(worked);
    return Semantics(
      label:
          'Time card for ${e.staffName}, ${_formatDateTime(e.clockedInAt)}, '
          'worked $workedLabel, ${e.isOpen ? "open shift" : "completed"}',
      explicitChildNodes: true,
      child: EdenCard(
        child: Container(
          color: tint,
          padding: const EdgeInsets.all(EdenSpacing.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(e.staffName,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (e.isOpen)
                    const EdenStatusBadge(status: 'pending')
                  else if (e.dispute == EdenTimeCardDispute.employeeDisputed)
                    const EdenStatusBadge(status: 'warning')
                  else
                    const EdenStatusBadge(status: 'completed'),
                ],
              ),
              const SizedBox(height: EdenSpacing.space2),
              Text('Clocked in: ${_formatDateTime(e.clockedInAt)}',
                  style: theme.textTheme.bodySmall),
              if (e.clockedOutAt != null)
                Text('Clocked out: ${_formatDateTime(e.clockedOutAt!)}',
                    style: theme.textTheme.bodySmall),
              Text('Breaks: ${_formatDuration(e.breaksAccumulated)}',
                  style: theme.textTheme.bodySmall),
              Text('Worked: $workedLabel',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              if (e.note != null && e.note!.isNotEmpty) ...[
                const SizedBox(height: EdenSpacing.space1),
                Text('Note: ${e.note}',
                    style: theme.textTheme.bodySmall),
              ],
              if (widget.showApprovalControls && !e.isOpen) ...[
                const SizedBox(height: EdenSpacing.space2),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    EdenButton(
                      label: 'Approve',
                      variant: EdenButtonVariant.success,
                      size: EdenButtonSize.sm,
                      onPressed: () => widget.onAction(EdenTimeCardApprovalEvent(
                            entryId: e.id,
                            action: EdenTimeCardApprovalAction.approve,
                          )),
                    ),
                    EdenButton(
                      label: 'Reject',
                      variant: EdenButtonVariant.danger,
                      outline: true,
                      size: EdenButtonSize.sm,
                      onPressed: () => widget.onAction(EdenTimeCardApprovalEvent(
                            entryId: e.id,
                            action: EdenTimeCardApprovalAction.reject,
                          )),
                    ),
                    EdenButton(
                      label: 'Request edit',
                      variant: EdenButtonVariant.secondary,
                      outline: true,
                      size: EdenButtonSize.sm,
                      onPressed: () => widget.onAction(EdenTimeCardApprovalEvent(
                            entryId: e.id,
                            action: EdenTimeCardApprovalAction.requestEdit,
                          )),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _table(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('Staff')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Clock in')),
          DataColumn(label: Text('Clock out')),
          DataColumn(label: Text('Breaks')),
          DataColumn(label: Text('Worked')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: [
          for (final e in widget.entries) _tableRow(context, e),
        ],
      ),
    );
  }

  DataRow _tableRow(BuildContext context, EdenTimeCardEntry e) {
    final worked = _displayedWorked(e);
    final workedLabel = _formatDuration(worked);
    final tint = _rowTint(context, e);
    final status = _statusFor(e);
    return DataRow(
      color: tint != null
          ? WidgetStatePropertyAll<Color>(tint)
          : null,
      cells: [
        DataCell(Text(e.staffName)),
        DataCell(Text(
            '${e.clockedInAt.year}-${e.clockedInAt.month.toString().padLeft(2, '0')}-${e.clockedInAt.day.toString().padLeft(2, '0')}')),
        DataCell(Text(_formatDateTime(e.clockedInAt))),
        DataCell(Text(
            e.clockedOutAt == null ? '—' : _formatDateTime(e.clockedOutAt!))),
        DataCell(Text(_formatDuration(e.breaksAccumulated))),
        DataCell(Text(workedLabel)),
        DataCell(EdenStatusBadge(status: status)),
        DataCell(_tableActionsCell(e)),
      ],
    );
  }

  Widget _tableActionsCell(EdenTimeCardEntry e) {
    if (e.isOpen || !widget.showApprovalControls) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        EdenButton(
          label: 'Approve',
          variant: EdenButtonVariant.success,
          size: EdenButtonSize.sm,
          onPressed: () => widget.onAction(EdenTimeCardApprovalEvent(
                entryId: e.id,
                action: EdenTimeCardApprovalAction.approve,
              )),
        ),
        const SizedBox(width: 8),
        EdenButton(
          label: 'Reject',
          variant: EdenButtonVariant.danger,
          outline: true,
          size: EdenButtonSize.sm,
          onPressed: () => widget.onAction(EdenTimeCardApprovalEvent(
                entryId: e.id,
                action: EdenTimeCardApprovalAction.reject,
              )),
        ),
        const SizedBox(width: 8),
        EdenButton(
          label: 'Request edit',
          variant: EdenButtonVariant.secondary,
          outline: true,
          size: EdenButtonSize.sm,
          onPressed: () => widget.onAction(EdenTimeCardApprovalEvent(
                entryId: e.id,
                action: EdenTimeCardApprovalAction.requestEdit,
              )),
        ),
      ],
    );
  }
}
