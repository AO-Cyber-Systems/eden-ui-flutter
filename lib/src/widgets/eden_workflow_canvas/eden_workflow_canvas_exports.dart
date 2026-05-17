// Public exports for the visual workflow canvas (objective 020).
//
// Per-TRD additive — each wave appends new modules without modifying earlier
// exports.

// Wave 1 — Foundation (TRD 020-01)
export 'workflow_models.dart';
export 'workflow_category_registry.dart';
export 'workflow_action_registry.dart';
export 'workflow_graph_builder.dart';

// Wave 2 — Trigger node + Field registry + Event browser (TRD 020-02)
export 'workflow_field_registry.dart';
export 'nodes/eden_trigger_node.dart';
