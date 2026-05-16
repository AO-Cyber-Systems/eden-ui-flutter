import 'package:flutter/material.dart';

import 'eden_ai_models.dart';
import 'eden_ai_panel.dart';

/// Slot widget that conditionally renders an [EdenAiPanel].
///
/// Designed to live inside layout slots (e.g. `EdenDetailPageScaffold`) where
/// the AI panel is feature-flag gated. `EdenAiInsightSlot(enabled: false)` is
/// the canonical "AI off" rendering: a [SizedBox.shrink] with zero side-effects.
/// When [enabled] is true, the slot composes an [EdenAiPanel] with the passed
/// `insights` and `persona`.
///
/// **Default persona:** `EdenAiPersona.operations` when `persona` is null.
/// **Default insights:** `const []` when `insights` is null.
/// **Default isExpanded:** `true` when no external `isExpanded` is provided.
///
/// **State coexistence pattern** (matches the donor): consumers can either
/// own the expanded flag externally ([isExpanded] non-null + [onToggle]
/// callback fires on tap) OR delegate to the slot's internal state (omit
/// both, the slot manages a `bool _internalExpanded`).
///
/// Donor: `trades-flutter/lib/shared/widgets/ai_insight_slot.dart`.
class EdenAiInsightSlot extends StatefulWidget {
  const EdenAiInsightSlot({
    super.key,
    this.enabled = false,
    this.insights,
    this.persona,
    this.onToggle,
    this.isExpanded,
  });

  /// Master gate. False renders nothing.
  final bool enabled;

  /// Insights to display. Null defaults to `const []`.
  final List<EdenInsightContent>? insights;

  /// Active persona for the panel header. Null defaults to
  /// [EdenAiPersona.operations].
  final EdenAiPersona? persona;

  /// External toggle callback. When non-null, fires on chevron tap INSTEAD of
  /// the slot's internal `setState`.
  final VoidCallback? onToggle;

  /// External expanded state. When non-null, takes priority over the slot's
  /// internal mirror. A change here triggers [didUpdateWidget] sync.
  final bool? isExpanded;

  @override
  State<EdenAiInsightSlot> createState() => _EdenAiInsightSlotState();
}

class _EdenAiInsightSlotState extends State<EdenAiInsightSlot> {
  late bool _internalExpanded;

  @override
  void initState() {
    super.initState();
    _internalExpanded = widget.isExpanded ?? true;
  }

  @override
  void didUpdateWidget(EdenAiInsightSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != null &&
        widget.isExpanded != oldWidget.isExpanded) {
      _internalExpanded = widget.isExpanded!;
    }
  }

  void _toggle() {
    if (widget.onToggle != null) {
      widget.onToggle!();
    } else {
      setState(() => _internalExpanded = !_internalExpanded);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();

    final expanded = widget.isExpanded ?? _internalExpanded;

    return EdenAiPanel(
      insights: widget.insights ?? const <EdenInsightContent>[],
      persona: widget.persona ?? EdenAiPersona.operations,
      isExpanded: expanded,
      onToggle: _toggle,
    );
  }
}
