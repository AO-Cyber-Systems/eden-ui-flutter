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
export 'nodes/eden_workflow_event_browser.dart';

// Wave 2 — Action node + field specs (TRD 020-03)
export 'workflow_action_field_spec.dart';
export 'nodes/eden_action_node.dart';

// Wave 3 — Branch + Condition nodes (TRD 020-04)
export 'nodes/eden_branch_node.dart';
export 'nodes/eden_condition_node.dart';

// Wave 3 — Delay + Merge nodes + public port helpers (TRD 020-05)
export 'nodes/eden_delay_node.dart';
export 'nodes/eden_merge_node.dart';
