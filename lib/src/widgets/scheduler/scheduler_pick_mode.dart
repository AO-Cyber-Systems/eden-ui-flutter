import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';

/// A draft event-block created during pick mode (donor `DraftAppointmentBlock`
/// shape). Represents an intended-but-uncommitted event.
@immutable
class EdenSchedulerDraftBlock {
  const EdenSchedulerDraftBlock({
    required this.id,
    required this.start,
    required this.end,
    this.resourceId,
    this.label,
  });

  final String id;
  final DateTime start;
  final DateTime end;
  final String? resourceId;
  final String? label;

  EdenSchedulerDraftBlock copyWith({
    DateTime? start,
    DateTime? end,
    String? resourceId,
    String? label,
  }) {
    return EdenSchedulerDraftBlock(
      id: id,
      start: start ?? this.start,
      end: end ?? this.end,
      resourceId: resourceId ?? this.resourceId,
      label: label ?? this.label,
    );
  }
}

/// Controller for [EdenScheduler] pick mode (parity row DR-4). Tracks an
/// `active` flag and a list of [EdenSchedulerDraftBlock] drafts. Notifies
/// listeners on every state change.
class EdenSchedulerPickModeController extends ChangeNotifier {
  EdenSchedulerPickModeController();

  bool _active = false;
  final List<EdenSchedulerDraftBlock> _drafts = [];

  bool get active => _active;
  List<EdenSchedulerDraftBlock> get drafts => List.unmodifiable(_drafts);

  void enter() {
    if (_active) return;
    _active = true;
    notifyListeners();
  }

  void exit({bool clearDrafts = true}) {
    if (!_active && _drafts.isEmpty) return;
    _active = false;
    if (clearDrafts) _drafts.clear();
    notifyListeners();
  }

  void toggle() => _active ? exit() : enter();

  void appendDraft(EdenSchedulerDraftBlock block) {
    _drafts.add(block);
    notifyListeners();
  }

  void updateDraft(String id, EdenSchedulerDraftBlock Function(EdenSchedulerDraftBlock) patch) {
    final i = _drafts.indexWhere((d) => d.id == id);
    if (i < 0) return;
    _drafts[i] = patch(_drafts[i]);
    notifyListeners();
  }

  void removeDraft(String id) {
    final i = _drafts.indexWhere((d) => d.id == id);
    if (i < 0) return;
    _drafts.removeAt(i);
    notifyListeners();
  }

  void clearDrafts() {
    if (_drafts.isEmpty) return;
    _drafts.clear();
    notifyListeners();
  }
}

/// Bottom-anchored bar visible when pick-mode has 1+ drafts. Mirrors donor
/// `PickModeFloatingBar`.
class EdenSchedulerPickModeBar extends StatelessWidget {
  const EdenSchedulerPickModeBar({
    super.key,
    required this.controller,
    this.onCommit,
  });

  final EdenSchedulerPickModeController controller;
  final void Function(List<EdenSchedulerDraftBlock> drafts)? onCommit;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.drafts.isEmpty) return const SizedBox.shrink();
        final theme = Theme.of(context);
        final count = controller.drafts.length;
        return Material(
          color: theme.colorScheme.primary,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space4,
              vertical: EdenSpacing.space2,
            ),
            child: Row(
              children: [
                Icon(Icons.edit_note, color: theme.colorScheme.onPrimary),
                const SizedBox(width: EdenSpacing.space2),
                Expanded(
                  child: Text(
                    count == 1 ? '1 draft' : '$count drafts',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: controller.clearDrafts,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: EdenSpacing.space2),
                FilledButton(
                  onPressed: onCommit == null
                      ? null
                      : () => onCommit!(controller.drafts),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.onPrimary,
                    foregroundColor: theme.colorScheme.primary,
                  ),
                  child: Text(count == 1 ? 'Save 1' : 'Save $count'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Visual placeholder for a draft block in the time grid. Translucent with a
/// dashed border (rendered via standard Container + DashedBorderPainter
/// approximation using a thin dotted background).
class EdenSchedulerDraftBlockWidget extends StatelessWidget {
  const EdenSchedulerDraftBlockWidget({
    super.key,
    required this.draft,
    this.onTap,
    this.onRemove,
  });

  final EdenSchedulerDraftBlock draft;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: EdenRadii.borderRadiusSm,
          border: Border.all(
            color: color,
            width: 1.5,
            style: BorderStyle.solid, // Dart paints solid; dashed = manual painter.
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space2,
          vertical: EdenSpacing.space1,
        ),
        child: Row(
          children: [
            Icon(Icons.add_box_outlined, size: 14, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                draft.label ?? 'Draft',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onRemove != null)
              GestureDetector(
                onTap: onRemove,
                child: Icon(Icons.close, size: 14, color: color),
              ),
          ],
        ),
      ),
    );
  }
}
