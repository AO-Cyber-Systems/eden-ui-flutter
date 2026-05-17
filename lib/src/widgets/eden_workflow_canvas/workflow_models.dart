// Value types for the visual workflow canvas (objective 020).
//
// Generic, vertical-agnostic, transport-agnostic.
// Mirrors donor `trades/client/src/components/workflow/types.ts`.
// Domain-specific concepts (category, action type) are registry-driven; see
// `workflow_category_registry.dart` and `workflow_action_registry.dart`.
//
// Reuses obj 006 value types: EdenProcessNodePosition, EdenProcessSavedEdge,
// EdenProcessViewport (per locked decision §7.6 — no parallel position type).

import 'dart:ui' show Color;

import '../eden_process_canvas/process_models.dart'
    show EdenProcessNodePosition, EdenProcessSavedEdge, EdenProcessViewport;

// ─────────── Enums ───────────

/// Trigger types for workflows. Small fixed semantic set — NOT a registry.
///
/// Six values cover the universe of what workflow-execution engines react to.
/// Verticals that need novel trigger types should request library evolution,
/// not register at runtime.
///
/// **Note:** `entity_created` ships despite the backend `entity_created` Zod
/// enum gap on the trades-go side (locked decision §7.3). Consumer wires
/// whichever backend they have.
// ignore: constant_identifier_names
enum EdenWorkflowTriggerType {
  scheduled,
  completed,
  // ignore: constant_identifier_names
  status_change,
  // ignore: constant_identifier_names
  time_based,
  manual,
  // ignore: constant_identifier_names
  entity_created,
}

/// Comparison operators for `EdenWorkflowCondition`. Small fixed set.
// ignore: constant_identifier_names
enum EdenWorkflowConditionOperator {
  equals,
  // ignore: constant_identifier_names
  not_equals,
  // ignore: constant_identifier_names
  greater_than,
  // ignore: constant_identifier_names
  less_than,
  contains,
  // ignore: constant_identifier_names
  not_contains,
}

// ─────────── EdenWorkflowCondition ───────────

/// A predicate applied to a workflow's entity. Parity row W-1.
///
/// `value` is `dynamic` — donor TS uses `any`. Library preserves int/String/
/// bool/null type fidelity through JSON round-trip.
class EdenWorkflowCondition {
  const EdenWorkflowCondition({
    required this.field,
    required this.operator,
    this.value,
  });

  final String field;
  final EdenWorkflowConditionOperator operator;
  final dynamic value;

  Map<String, dynamic> toJson() => {
        'field': field,
        'operator': operator.name,
        'value': value,
      };

  factory EdenWorkflowCondition.fromJson(Map<String, dynamic> json) =>
      EdenWorkflowCondition(
        field: json['field'] as String,
        operator: EdenWorkflowConditionOperator.values.firstWhere(
          (o) => o.name == json['operator'],
          orElse: () => EdenWorkflowConditionOperator.equals,
        ),
        value: json['value'],
      );

  @override
  bool operator ==(Object other) =>
      other is EdenWorkflowCondition &&
      other.field == field &&
      other.operator == operator &&
      other.value == value;

  @override
  int get hashCode => Object.hash(field, operator, value);
}

// ─────────── EdenWorkflowAction ───────────

/// A workflow action. Parity row W-1.
///
/// `actionType` is registry-driven (resolved via `EdenWorkflowActionRegistry`).
/// `config` is a free-form map for action-type-specific data.
///
/// **JSON wire shape:** the `toJson` key is `'type'` (not `'actionType'`) to
/// match donor TypeScript wire shape. The Dart field name `actionType` is
/// kept explicit because `type` collides with Dart's `Type` keyword in some
/// contexts.
class EdenWorkflowAction {
  const EdenWorkflowAction({
    required this.actionType,
    this.config = const {},
  });

  final String actionType;
  final Map<String, dynamic> config;

  Map<String, dynamic> toJson() => {
        'type': actionType, // donor wire shape uses 'type'
        'config': config,
      };

  factory EdenWorkflowAction.fromJson(Map<String, dynamic> json) =>
      EdenWorkflowAction(
        actionType: json['type'] as String,
        config:
            (json['config'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      );

  @override
  bool operator ==(Object other) {
    if (other is! EdenWorkflowAction) return false;
    if (other.actionType != actionType) return false;
    if (other.config.length != config.length) return false;
    for (final entry in config.entries) {
      if (other.config[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        actionType,
        Object.hashAll(config.entries.map((e) => Object.hash(e.key, e.value))),
      );
}

// ─────────── EdenWorkflowCanvasLayout ───────────

/// Saved canvas layout for a workflow definition. Parity row W-6.
///
/// **Reuses obj 006 value types directly** (locked decision §7.6):
/// - `nodes` map values are [EdenProcessNodePosition].
/// - `edges` list entries are [EdenProcessSavedEdge].
/// - `viewport` is [EdenProcessViewport].
///
/// This keeps the JSON byte-compatible with obj 006's process layout (per-entry
/// shape identical; node-id schemes differ).
class EdenWorkflowCanvasLayout {
  const EdenWorkflowCanvasLayout({
    this.version = 1,
    this.nodes = const {},
    this.edges = const [],
    this.viewport,
  });

  factory EdenWorkflowCanvasLayout.empty() => const EdenWorkflowCanvasLayout();

  /// Schema version (bump for breaking migrations).
  final int version;

  /// Node positions keyed by node id (e.g. `'trigger-0'`, `'condition-2'`).
  final Map<String, EdenProcessNodePosition> nodes;

  /// User-drawn edges only (auto-generated trigger→cond→action ladder is NOT
  /// persisted; it's recomputed by [EdenWorkflowGraphBuilder.toCanvas]).
  final List<EdenProcessSavedEdge> edges;

  /// Optional saved pan + zoom viewport.
  final EdenProcessViewport? viewport;

  Map<String, dynamic> toJson() => {
        'version': version,
        'nodes': nodes.map((k, v) => MapEntry(k, v.toJson())),
        if (edges.isNotEmpty) 'edges': edges.map((e) => e.toJson()).toList(),
        if (viewport != null) 'viewport': viewport!.toJson(),
      };

  factory EdenWorkflowCanvasLayout.fromJson(Map<String, dynamic> json) {
    final nodesJson = (json['nodes'] as Map<String, dynamic>?) ?? const {};
    return EdenWorkflowCanvasLayout(
      version: (json['version'] as num?)?.toInt() ?? 1,
      nodes: nodesJson.map(
        (k, v) => MapEntry(
          k,
          EdenProcessNodePosition.fromJson(v as Map<String, dynamic>),
        ),
      ),
      edges: (json['edges'] as List<dynamic>?)
              ?.map((e) =>
                  EdenProcessSavedEdge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      viewport: json['viewport'] == null
          ? null
          : EdenProcessViewport.fromJson(
              json['viewport'] as Map<String, dynamic>),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! EdenWorkflowCanvasLayout) return false;
    if (other.version != version) return false;
    if (other.viewport != viewport) return false;
    if (other.nodes.length != nodes.length) return false;
    for (final entry in nodes.entries) {
      if (other.nodes[entry.key] != entry.value) return false;
    }
    if (other.edges.length != edges.length) return false;
    for (int i = 0; i < edges.length; i++) {
      if (other.edges[i] != edges[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        version,
        Object.hashAll(nodes.entries.map((e) => Object.hash(e.key, e.value))),
        Object.hashAll(edges),
        viewport,
      );
}

// ─────────── EdenWorkflowDefinition ───────────

/// Top-level workflow definition. Parity row W-1.
///
/// `category` is a String (registry-driven via `EdenWorkflowCategoryRegistry`).
/// `triggerType` is a Dart enum (small fixed semantic set).
class EdenWorkflowDefinition {
  const EdenWorkflowDefinition({
    required this.id,
    required this.name,
    this.description,
    required this.version,
    required this.isPublished,
    required this.hasUnpublishedChanges,
    required this.triggerType,
    this.triggerConfig = const {},
    required this.category,
    this.conditions = const [],
    this.actions = const [],
    this.canvasLayout,
  });

  final int id;
  final String name;
  final String? description;
  final int version;
  final bool isPublished;
  final bool hasUnpublishedChanges;
  final EdenWorkflowTriggerType triggerType;
  final Map<String, dynamic> triggerConfig;
  final String category;
  final List<EdenWorkflowCondition> conditions;
  final List<EdenWorkflowAction> actions;
  final EdenWorkflowCanvasLayout? canvasLayout;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        'version': version,
        'isPublished': isPublished,
        'hasUnpublishedChanges': hasUnpublishedChanges,
        'triggerType': triggerType.name,
        'triggerConfig': triggerConfig,
        'category': category,
        'conditions': conditions.map((c) => c.toJson()).toList(),
        'actions': actions.map((a) => a.toJson()).toList(),
        if (canvasLayout != null) 'canvasLayout': canvasLayout!.toJson(),
      };

  factory EdenWorkflowDefinition.fromJson(Map<String, dynamic> json) =>
      EdenWorkflowDefinition(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        description: json['description'] as String?,
        version: (json['version'] as num?)?.toInt() ?? 1,
        isPublished: json['isPublished'] as bool? ?? false,
        hasUnpublishedChanges:
            json['hasUnpublishedChanges'] as bool? ?? false,
        triggerType: EdenWorkflowTriggerType.values.firstWhere(
          (t) => t.name == json['triggerType'],
          orElse: () => EdenWorkflowTriggerType.manual,
        ),
        triggerConfig: (json['triggerConfig'] as Map<String, dynamic>?) ??
            const <String, dynamic>{},
        category: json['category'] as String,
        conditions: (json['conditions'] as List<dynamic>?)
                ?.map((c) =>
                    EdenWorkflowCondition.fromJson(c as Map<String, dynamic>))
                .toList() ??
            const [],
        actions: (json['actions'] as List<dynamic>?)
                ?.map((a) =>
                    EdenWorkflowAction.fromJson(a as Map<String, dynamic>))
                .toList() ??
            const [],
        canvasLayout: json['canvasLayout'] == null
            ? null
            : EdenWorkflowCanvasLayout.fromJson(
                json['canvasLayout'] as Map<String, dynamic>),
      );

  @override
  bool operator ==(Object other) {
    if (other is! EdenWorkflowDefinition) return false;
    if (other.id != id) return false;
    if (other.name != name) return false;
    if (other.description != description) return false;
    if (other.version != version) return false;
    if (other.isPublished != isPublished) return false;
    if (other.hasUnpublishedChanges != hasUnpublishedChanges) return false;
    if (other.triggerType != triggerType) return false;
    if (other.category != category) return false;
    if (other.canvasLayout != canvasLayout) return false;
    if (other.triggerConfig.length != triggerConfig.length) return false;
    for (final entry in triggerConfig.entries) {
      if (other.triggerConfig[entry.key] != entry.value) return false;
    }
    if (other.conditions.length != conditions.length) return false;
    for (int i = 0; i < conditions.length; i++) {
      if (other.conditions[i] != conditions[i]) return false;
    }
    if (other.actions.length != actions.length) return false;
    for (int i = 0; i < actions.length; i++) {
      if (other.actions[i] != actions[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        version,
        isPublished,
        hasUnpublishedChanges,
        triggerType,
        category,
        canvasLayout,
        Object.hashAll(conditions),
        Object.hashAll(actions),
      );
}

// ─────────── EdenWorkflowSaveData ───────────

/// Return type of [EdenWorkflowGraphBuilder.fromCanvas]. Subset of
/// [EdenWorkflowDefinition] containing only the fields the canvas can derive
/// from its node/edge state.
class EdenWorkflowSaveData {
  const EdenWorkflowSaveData({
    required this.triggerType,
    required this.triggerConfig,
    required this.category,
    required this.conditions,
    required this.actions,
    required this.canvasLayout,
  });

  final EdenWorkflowTriggerType triggerType;
  final Map<String, dynamic> triggerConfig;
  final String category;
  final List<EdenWorkflowCondition> conditions;
  final List<EdenWorkflowAction> actions;
  final EdenWorkflowCanvasLayout canvasLayout;

  Map<String, dynamic> toJson() => {
        'triggerType': triggerType.name,
        'triggerConfig': triggerConfig,
        'category': category,
        'conditions': conditions.map((c) => c.toJson()).toList(),
        'actions': actions.map((a) => a.toJson()).toList(),
        'canvasLayout': canvasLayout.toJson(),
      };
}

// ─────────── EdenWorkflowEdgeStyle ───────────

/// Edge-style constants for user-drawn vs auto-generated edges. Parity row E-2.
///
/// **userColor:** donor indigo `#6366F1` — kept until token system has an
/// equivalent semantic color.
/// **userStrokeWidth / autoStrokeWidth:** both 2pt smoothstep (donor default).
///
/// Auto-edge color defers to `theme.colorScheme.outline` at render time
/// (no constant here — keeps the library theme-aware).
abstract class EdenWorkflowEdgeStyle {
  EdenWorkflowEdgeStyle._();

  static const Color userColor = Color(0xFF6366F1);
  static const double userStrokeWidth = 2;
  static const double autoStrokeWidth = 2;
}
