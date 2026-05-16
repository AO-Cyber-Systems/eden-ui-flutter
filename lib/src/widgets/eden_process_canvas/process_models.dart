// Value types for the visual process canvas (objective 006).
//
// Generic, vertical-agnostic, transport-agnostic.
// Mirrors donor `trades/client/src/components/customizations/processes/visual-builder/types.ts`.
// Domain-specific concepts (entity type, runtime component) are registry-driven; see
// `process_entity_type_registry.dart` and `process_runtime_component_registry.dart`.

import 'dart:convert';

// ─────────── EdenProcessValidationSeverity ───────────

/// Severity of a validation issue surfaced by `EdenProcessValidator`.
enum EdenProcessValidationSeverity { error, warning }

// ─────────── EdenProcessNodePosition ───────────

/// Saved (x, y) position of a node in `EdenProcessLayoutData`.
///
/// `expanded` is an optional flag for phase / group nodes that have an
/// expand/collapse affordance.
class EdenProcessNodePosition {
  const EdenProcessNodePosition({
    required this.x,
    required this.y,
    this.expanded,
  });

  final double x;
  final double y;
  final bool? expanded;

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        if (expanded != null) 'expanded': expanded,
      };

  factory EdenProcessNodePosition.fromJson(Map<String, dynamic> json) =>
      EdenProcessNodePosition(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        expanded: json['expanded'] as bool?,
      );

  @override
  bool operator ==(Object other) =>
      other is EdenProcessNodePosition &&
      other.x == x &&
      other.y == y &&
      other.expanded == expanded;

  @override
  int get hashCode => Object.hash(x, y, expanded);
}

// ─────────── EdenProcessSavedEdge ───────────

/// A user-drawn edge persisted via `EdenProcessLayoutData`.
class EdenProcessSavedEdge {
  const EdenProcessSavedEdge({
    required this.id,
    required this.source,
    required this.target,
    this.sourceHandle,
    this.targetHandle,
  });

  final String id;
  final String source;
  final String target;
  final String? sourceHandle;
  final String? targetHandle;

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'target': target,
        if (sourceHandle != null) 'sourceHandle': sourceHandle,
        if (targetHandle != null) 'targetHandle': targetHandle,
      };

  factory EdenProcessSavedEdge.fromJson(Map<String, dynamic> json) =>
      EdenProcessSavedEdge(
        id: json['id'] as String,
        source: json['source'] as String,
        target: json['target'] as String,
        sourceHandle: json['sourceHandle'] as String?,
        targetHandle: json['targetHandle'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is EdenProcessSavedEdge &&
      other.id == id &&
      other.source == source &&
      other.target == target &&
      other.sourceHandle == sourceHandle &&
      other.targetHandle == targetHandle;

  @override
  int get hashCode => Object.hash(id, source, target, sourceHandle, targetHandle);
}

// ─────────── EdenProcessViewport ───────────

/// Pan + zoom viewport state persisted via `EdenProcessLayoutData`.
class EdenProcessViewport {
  const EdenProcessViewport({
    required this.x,
    required this.y,
    required this.zoom,
  });

  final double x;
  final double y;
  final double zoom;

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'zoom': zoom,
      };

  factory EdenProcessViewport.fromJson(Map<String, dynamic> json) =>
      EdenProcessViewport(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        zoom: (json['zoom'] as num).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      other is EdenProcessViewport &&
      other.x == x &&
      other.y == y &&
      other.zoom == zoom;

  @override
  int get hashCode => Object.hash(x, y, zoom);
}

// ─────────── EdenProcessLayoutData ───────────

/// Saved layout for a process — positions, user-drawn edges, viewport.
///
/// Round-trips to JSON for backend storage. Parity row L-5.
class EdenProcessLayoutData {
  const EdenProcessLayoutData({
    this.version = 1,
    this.autoLayout = false,
    required this.nodes,
    this.edges = const [],
    this.viewport,
  });

  /// Schema version (bump for breaking migrations).
  final int version;

  /// Whether the canvas should auto-layout on load (donor `autoLayout`).
  final bool autoLayout;

  /// Node positions keyed by node id.
  final Map<String, EdenProcessNodePosition> nodes;

  /// User-drawn edges.
  final List<EdenProcessSavedEdge> edges;

  /// Optional saved pan + zoom viewport.
  final EdenProcessViewport? viewport;

  Map<String, dynamic> toJson() => {
        'version': version,
        'autoLayout': autoLayout,
        'nodes': nodes.map((k, v) => MapEntry(k, v.toJson())),
        if (edges.isNotEmpty) 'edges': edges.map((e) => e.toJson()).toList(),
        if (viewport != null) 'viewport': viewport!.toJson(),
      };

  factory EdenProcessLayoutData.fromJson(Map<String, dynamic> json) {
    final nodesJson = (json['nodes'] as Map<String, dynamic>?) ?? const {};
    return EdenProcessLayoutData(
      version: (json['version'] as num?)?.toInt() ?? 1,
      autoLayout: json['autoLayout'] as bool? ?? false,
      nodes: nodesJson.map(
        (k, v) => MapEntry(
          k,
          EdenProcessNodePosition.fromJson(v as Map<String, dynamic>),
        ),
      ),
      edges: (json['edges'] as List<dynamic>?)
              ?.map((e) => EdenProcessSavedEdge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      viewport: json['viewport'] == null
          ? null
          : EdenProcessViewport.fromJson(json['viewport'] as Map<String, dynamic>),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! EdenProcessLayoutData) return false;
    if (other.version != version) return false;
    if (other.autoLayout != autoLayout) return false;
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
        autoLayout,
        Object.hashAll(nodes.entries.map((e) => Object.hash(e.key, e.value))),
        Object.hashAll(edges),
        viewport,
      );
}

// ─────────── EdenProcessDecisionConfig ───────────

/// A decision branch in the process — parity row N-6.
class EdenProcessDecisionConfig {
  const EdenProcessDecisionConfig({
    required this.id,
    required this.name,
    required this.condition,
  });

  final int id;
  final String name;
  final String condition;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'condition': condition,
      };

  factory EdenProcessDecisionConfig.fromJson(Map<String, dynamic> json) =>
      EdenProcessDecisionConfig(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        condition: json['condition'] as String,
      );

  @override
  bool operator ==(Object other) =>
      other is EdenProcessDecisionConfig &&
      other.id == id &&
      other.name == name &&
      other.condition == condition;

  @override
  int get hashCode => Object.hash(id, name, condition);
}

// ─────────── EdenProcessConfig ───────────

/// Top-level configuration on `EdenProcessDefinition.config`.
///
/// Carries the saved layout, decisions, and start/end flow-node flags.
/// `extra` is a passthrough slot for vertical-specific config (locked
/// decision §7.1 — library stays generic).
class EdenProcessConfig {
  const EdenProcessConfig({
    this.layout,
    this.decisions = const [],
    this.flowNodes,
    this.extra = const {},
  });

  final EdenProcessLayoutData? layout;
  final List<EdenProcessDecisionConfig> decisions;
  final Map<String, bool>? flowNodes;
  final Map<String, dynamic> extra;

  Map<String, dynamic> toJson() => {
        if (layout != null) 'layout': layout!.toJson(),
        if (decisions.isNotEmpty) 'decisions': decisions.map((d) => d.toJson()).toList(),
        if (flowNodes != null) 'flowNodes': flowNodes,
        if (extra.isNotEmpty) 'extra': extra,
      };

  factory EdenProcessConfig.fromJson(Map<String, dynamic> json) => EdenProcessConfig(
        layout: json['layout'] == null
            ? null
            : EdenProcessLayoutData.fromJson(json['layout'] as Map<String, dynamic>),
        decisions: (json['decisions'] as List<dynamic>?)
                ?.map((d) => EdenProcessDecisionConfig.fromJson(d as Map<String, dynamic>))
                .toList() ??
            const [],
        flowNodes: (json['flowNodes'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v as bool)),
        extra: (json['extra'] as Map<String, dynamic>?) ?? const {},
      );

  @override
  bool operator ==(Object other) {
    if (other is! EdenProcessConfig) return false;
    if (other.layout != layout) return false;
    if (other.decisions.length != decisions.length) return false;
    for (int i = 0; i < decisions.length; i++) {
      if (other.decisions[i] != decisions[i]) return false;
    }
    if (other.flowNodes?.length != flowNodes?.length) return false;
    if (flowNodes != null) {
      for (final entry in flowNodes!.entries) {
        if (other.flowNodes?[entry.key] != entry.value) return false;
      }
    }
    if (other.extra.length != extra.length) return false;
    for (final entry in extra.entries) {
      if (other.extra[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        layout,
        Object.hashAll(decisions),
        flowNodes == null ? 0 : Object.hashAll(flowNodes!.entries.map((e) => Object.hash(e.key, e.value))),
        Object.hashAll(extra.entries.map((e) => Object.hash(e.key, _hashJsonValue(e.value)))),
      );
}

// ─────────── EdenProcessTaskTemplate ───────────

/// A single task within a task group — parity row N-5.
///
/// `runtimeComponent` is a String — registry-driven via
/// `EdenProcessRuntimeComponentRegistry`. Verticals register their own runtime
/// components; arbitrary strings are accepted at construction (validation
/// happens at the registry lookup boundary).
class EdenProcessTaskTemplate {
  const EdenProcessTaskTemplate({
    required this.id,
    required this.taskGroupId,
    required this.name,
    required this.displayName,
    this.description,
    required this.sortOrder,
    required this.runtimeComponent,
    required this.runtimeComponentConfig,
    required this.isRequired,
    required this.photoRequired,
    required this.signatureRequired,
    required this.approvalRequired,
    required this.descriptionRequired,
    required this.attachmentRequired,
    required this.allowsNa,
    required this.allowsBlocked,
    required this.allowsCantDo,
    required this.blockingBehavior,
    this.materializesAsTask = true,
    this.approvalRole,
    this.approvalUserId,
    this.responsibilityType,
    this.onCompleteWorkflowId,
    this.onBlockedWorkflowId,
    this.onNaWorkflowId,
    this.onCantDoWorkflowId,
  });

  final int id;
  final int taskGroupId;
  final String name;
  final String displayName;
  final String? description;
  final int sortOrder;
  final String runtimeComponent;
  final Map<String, dynamic> runtimeComponentConfig;
  final bool isRequired;
  final bool photoRequired;
  final bool signatureRequired;
  final bool approvalRequired;
  final bool descriptionRequired;
  final bool attachmentRequired;
  final bool allowsNa;
  final bool allowsBlocked;
  final bool allowsCantDo;
  final String blockingBehavior;
  final bool materializesAsTask;
  final String? approvalRole;
  final String? approvalUserId;
  final String? responsibilityType;
  final int? onCompleteWorkflowId;
  final int? onBlockedWorkflowId;
  final int? onNaWorkflowId;
  final int? onCantDoWorkflowId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskGroupId': taskGroupId,
        'name': name,
        'displayName': displayName,
        if (description != null) 'description': description,
        'sortOrder': sortOrder,
        'runtimeComponent': runtimeComponent,
        'runtimeComponentConfig': runtimeComponentConfig,
        'isRequired': isRequired,
        'photoRequired': photoRequired,
        'signatureRequired': signatureRequired,
        'approvalRequired': approvalRequired,
        'descriptionRequired': descriptionRequired,
        'attachmentRequired': attachmentRequired,
        'allowsNa': allowsNa,
        'allowsBlocked': allowsBlocked,
        'allowsCantDo': allowsCantDo,
        'blockingBehavior': blockingBehavior,
        'materializesAsTask': materializesAsTask,
        if (approvalRole != null) 'approvalRole': approvalRole,
        if (approvalUserId != null) 'approvalUserId': approvalUserId,
        if (responsibilityType != null) 'responsibilityType': responsibilityType,
        if (onCompleteWorkflowId != null) 'onCompleteWorkflowId': onCompleteWorkflowId,
        if (onBlockedWorkflowId != null) 'onBlockedWorkflowId': onBlockedWorkflowId,
        if (onNaWorkflowId != null) 'onNaWorkflowId': onNaWorkflowId,
        if (onCantDoWorkflowId != null) 'onCantDoWorkflowId': onCantDoWorkflowId,
      };

  factory EdenProcessTaskTemplate.fromJson(Map<String, dynamic> json) =>
      EdenProcessTaskTemplate(
        id: (json['id'] as num).toInt(),
        taskGroupId: (json['taskGroupId'] as num).toInt(),
        name: json['name'] as String,
        displayName: json['displayName'] as String,
        description: json['description'] as String?,
        sortOrder: (json['sortOrder'] as num).toInt(),
        runtimeComponent: json['runtimeComponent'] as String,
        runtimeComponentConfig:
            (json['runtimeComponentConfig'] as Map<String, dynamic>?) ?? const {},
        isRequired: json['isRequired'] as bool,
        photoRequired: json['photoRequired'] as bool,
        signatureRequired: json['signatureRequired'] as bool,
        approvalRequired: json['approvalRequired'] as bool,
        descriptionRequired: json['descriptionRequired'] as bool? ?? false,
        attachmentRequired: json['attachmentRequired'] as bool? ?? false,
        allowsNa: json['allowsNa'] as bool,
        allowsBlocked: json['allowsBlocked'] as bool,
        allowsCantDo: json['allowsCantDo'] as bool,
        blockingBehavior: json['blockingBehavior'] as String,
        materializesAsTask: json['materializesAsTask'] as bool? ?? true,
        approvalRole: json['approvalRole'] as String?,
        approvalUserId: json['approvalUserId'] as String?,
        responsibilityType: json['responsibilityType'] as String?,
        onCompleteWorkflowId: (json['onCompleteWorkflowId'] as num?)?.toInt(),
        onBlockedWorkflowId: (json['onBlockedWorkflowId'] as num?)?.toInt(),
        onNaWorkflowId: (json['onNaWorkflowId'] as num?)?.toInt(),
        onCantDoWorkflowId: (json['onCantDoWorkflowId'] as num?)?.toInt(),
      );

  @override
  bool operator ==(Object other) {
    if (other is! EdenProcessTaskTemplate) return false;
    return other.id == id &&
        other.taskGroupId == taskGroupId &&
        other.name == name &&
        other.displayName == displayName &&
        other.description == description &&
        other.sortOrder == sortOrder &&
        other.runtimeComponent == runtimeComponent &&
        _mapEquals(other.runtimeComponentConfig, runtimeComponentConfig) &&
        other.isRequired == isRequired &&
        other.photoRequired == photoRequired &&
        other.signatureRequired == signatureRequired &&
        other.approvalRequired == approvalRequired &&
        other.descriptionRequired == descriptionRequired &&
        other.attachmentRequired == attachmentRequired &&
        other.allowsNa == allowsNa &&
        other.allowsBlocked == allowsBlocked &&
        other.allowsCantDo == allowsCantDo &&
        other.blockingBehavior == blockingBehavior &&
        other.materializesAsTask == materializesAsTask &&
        other.approvalRole == approvalRole &&
        other.approvalUserId == approvalUserId &&
        other.responsibilityType == responsibilityType &&
        other.onCompleteWorkflowId == onCompleteWorkflowId &&
        other.onBlockedWorkflowId == onBlockedWorkflowId &&
        other.onNaWorkflowId == onNaWorkflowId &&
        other.onCantDoWorkflowId == onCantDoWorkflowId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        taskGroupId,
        name,
        displayName,
        runtimeComponent,
        sortOrder,
        isRequired,
        photoRequired,
        signatureRequired,
        approvalRequired,
      );
}

// ─────────── EdenProcessTaskGroup ───────────

/// A group of tasks within a phase — parity row N-4.
class EdenProcessTaskGroup {
  const EdenProcessTaskGroup({
    required this.id,
    required this.processPhaseId,
    required this.name,
    required this.displayName,
    this.description,
    required this.sortOrder,
    required this.isCollapsedDefault,
    required this.isRequired,
    this.taskGroupTemplateId,
    this.linkedTaskTemplateId,
    this.onAllCompleteWorkflowId,
    this.onItemNaWorkflowId,
    this.onItemCantDoWorkflowId,
    this.tasks = const [],
  });

  final int id;
  final int processPhaseId;
  final String name;
  final String displayName;
  final String? description;
  final int sortOrder;
  final bool isCollapsedDefault;
  final bool isRequired;
  final int? taskGroupTemplateId;
  final int? linkedTaskTemplateId;
  final int? onAllCompleteWorkflowId;
  final int? onItemNaWorkflowId;
  final int? onItemCantDoWorkflowId;
  final List<EdenProcessTaskTemplate> tasks;

  Map<String, dynamic> toJson() => {
        'id': id,
        'processPhaseId': processPhaseId,
        'name': name,
        'displayName': displayName,
        if (description != null) 'description': description,
        'sortOrder': sortOrder,
        'isCollapsedDefault': isCollapsedDefault,
        'isRequired': isRequired,
        if (taskGroupTemplateId != null) 'taskGroupTemplateId': taskGroupTemplateId,
        if (linkedTaskTemplateId != null) 'linkedTaskTemplateId': linkedTaskTemplateId,
        if (onAllCompleteWorkflowId != null) 'onAllCompleteWorkflowId': onAllCompleteWorkflowId,
        if (onItemNaWorkflowId != null) 'onItemNaWorkflowId': onItemNaWorkflowId,
        if (onItemCantDoWorkflowId != null) 'onItemCantDoWorkflowId': onItemCantDoWorkflowId,
        if (tasks.isNotEmpty) 'tasks': tasks.map((t) => t.toJson()).toList(),
      };

  factory EdenProcessTaskGroup.fromJson(Map<String, dynamic> json) =>
      EdenProcessTaskGroup(
        id: (json['id'] as num).toInt(),
        processPhaseId: (json['processPhaseId'] as num).toInt(),
        name: json['name'] as String,
        displayName: json['displayName'] as String,
        description: json['description'] as String?,
        sortOrder: (json['sortOrder'] as num).toInt(),
        isCollapsedDefault: json['isCollapsedDefault'] as bool,
        isRequired: json['isRequired'] as bool,
        taskGroupTemplateId: (json['taskGroupTemplateId'] as num?)?.toInt(),
        linkedTaskTemplateId: (json['linkedTaskTemplateId'] as num?)?.toInt(),
        onAllCompleteWorkflowId: (json['onAllCompleteWorkflowId'] as num?)?.toInt(),
        onItemNaWorkflowId: (json['onItemNaWorkflowId'] as num?)?.toInt(),
        onItemCantDoWorkflowId: (json['onItemCantDoWorkflowId'] as num?)?.toInt(),
        tasks: (json['tasks'] as List<dynamic>?)
                ?.map((t) =>
                    EdenProcessTaskTemplate.fromJson(t as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  @override
  bool operator ==(Object other) {
    if (other is! EdenProcessTaskGroup) return false;
    if (other.id != id ||
        other.processPhaseId != processPhaseId ||
        other.name != name ||
        other.displayName != displayName ||
        other.description != description ||
        other.sortOrder != sortOrder ||
        other.isCollapsedDefault != isCollapsedDefault ||
        other.isRequired != isRequired ||
        other.taskGroupTemplateId != taskGroupTemplateId ||
        other.linkedTaskTemplateId != linkedTaskTemplateId ||
        other.onAllCompleteWorkflowId != onAllCompleteWorkflowId ||
        other.onItemNaWorkflowId != onItemNaWorkflowId ||
        other.onItemCantDoWorkflowId != onItemCantDoWorkflowId) {
      return false;
    }
    if (other.tasks.length != tasks.length) return false;
    for (int i = 0; i < tasks.length; i++) {
      if (other.tasks[i] != tasks[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(id, processPhaseId, name, displayName, sortOrder);
}

// ─────────── EdenProcessPhase ───────────

/// A phase in the process — parity row N-3.
class EdenProcessPhase {
  const EdenProcessPhase({
    required this.id,
    required this.processDefinitionId,
    required this.name,
    required this.displayName,
    this.description,
    required this.sortOrder,
    this.color,
    this.icon,
    required this.isRequired,
    required this.isMilestone,
    required this.canSkip,
    required this.autoAdvance,
    required this.runtimeComponent,
    required this.runtimeComponentConfig,
    required this.allowsScopeChange,
    required this.allowsAdHocTasks,
    this.groups = const [],
  });

  final int id;
  final int processDefinitionId;
  final String name;
  final String displayName;
  final String? description;
  final int sortOrder;
  final String? color;
  final String? icon;
  final bool isRequired;
  final bool isMilestone;
  final bool canSkip;
  final bool autoAdvance;
  final String runtimeComponent;
  final Map<String, dynamic> runtimeComponentConfig;
  final bool allowsScopeChange;
  final bool allowsAdHocTasks;
  final List<EdenProcessTaskGroup> groups;

  Map<String, dynamic> toJson() => {
        'id': id,
        'processDefinitionId': processDefinitionId,
        'name': name,
        'displayName': displayName,
        if (description != null) 'description': description,
        'sortOrder': sortOrder,
        if (color != null) 'color': color,
        if (icon != null) 'icon': icon,
        'isRequired': isRequired,
        'isMilestone': isMilestone,
        'canSkip': canSkip,
        'autoAdvance': autoAdvance,
        'runtimeComponent': runtimeComponent,
        'runtimeComponentConfig': runtimeComponentConfig,
        'allowsScopeChange': allowsScopeChange,
        'allowsAdHocTasks': allowsAdHocTasks,
        if (groups.isNotEmpty) 'groups': groups.map((g) => g.toJson()).toList(),
      };

  factory EdenProcessPhase.fromJson(Map<String, dynamic> json) => EdenProcessPhase(
        id: (json['id'] as num).toInt(),
        processDefinitionId: (json['processDefinitionId'] as num).toInt(),
        name: json['name'] as String,
        displayName: json['displayName'] as String,
        description: json['description'] as String?,
        sortOrder: (json['sortOrder'] as num).toInt(),
        color: json['color'] as String?,
        icon: json['icon'] as String?,
        isRequired: json['isRequired'] as bool,
        isMilestone: json['isMilestone'] as bool,
        canSkip: json['canSkip'] as bool,
        autoAdvance: json['autoAdvance'] as bool,
        runtimeComponent: json['runtimeComponent'] as String,
        runtimeComponentConfig:
            (json['runtimeComponentConfig'] as Map<String, dynamic>?) ?? const {},
        allowsScopeChange: json['allowsScopeChange'] as bool,
        allowsAdHocTasks: json['allowsAdHocTasks'] as bool,
        groups: (json['groups'] as List<dynamic>?)
                ?.map((g) => EdenProcessTaskGroup.fromJson(g as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  @override
  bool operator ==(Object other) {
    if (other is! EdenProcessPhase) return false;
    if (other.id != id ||
        other.processDefinitionId != processDefinitionId ||
        other.name != name ||
        other.displayName != displayName ||
        other.description != description ||
        other.sortOrder != sortOrder ||
        other.color != color ||
        other.icon != icon ||
        other.isRequired != isRequired ||
        other.isMilestone != isMilestone ||
        other.canSkip != canSkip ||
        other.autoAdvance != autoAdvance ||
        other.runtimeComponent != runtimeComponent ||
        other.allowsScopeChange != allowsScopeChange ||
        other.allowsAdHocTasks != allowsAdHocTasks) {
      return false;
    }
    if (other.groups.length != groups.length) return false;
    for (int i = 0; i < groups.length; i++) {
      if (other.groups[i] != groups[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(id, processDefinitionId, name, displayName, sortOrder);
}

// ─────────── EdenProcessDefinition ───────────

/// Top-level process definition.
///
/// Generic, vertical-agnostic. Entity-type association lives in
/// `EdenProcessEntityTypeRegistry` (registry-driven; locked decision §7.2).
class EdenProcessDefinition {
  const EdenProcessDefinition({
    required this.id,
    required this.processTypeId,
    required this.name,
    required this.displayName,
    this.description,
    required this.version,
    required this.isDefault,
    required this.isActive,
    required this.isPublished,
    required this.hasUnpublishedChanges,
    required this.config,
    required this.phases,
  });

  final int id;
  final int processTypeId;
  final String name;
  final String displayName;
  final String? description;
  final int version;
  final bool isDefault;
  final bool isActive;
  final bool isPublished;
  final bool hasUnpublishedChanges;
  final EdenProcessConfig config;
  final List<EdenProcessPhase> phases;

  Map<String, dynamic> toJson() => {
        'id': id,
        'processTypeId': processTypeId,
        'name': name,
        'displayName': displayName,
        if (description != null) 'description': description,
        'version': version,
        'isDefault': isDefault,
        'isActive': isActive,
        'isPublished': isPublished,
        'hasUnpublishedChanges': hasUnpublishedChanges,
        'config': config.toJson(),
        if (phases.isNotEmpty) 'phases': phases.map((p) => p.toJson()).toList(),
      };

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory EdenProcessDefinition.fromJson(Map<String, dynamic> json) =>
      EdenProcessDefinition(
        id: (json['id'] as num).toInt(),
        processTypeId: (json['processTypeId'] as num).toInt(),
        name: json['name'] as String,
        displayName: json['displayName'] as String,
        description: json['description'] as String?,
        version: (json['version'] as num).toInt(),
        isDefault: json['isDefault'] as bool,
        isActive: json['isActive'] as bool,
        isPublished: json['isPublished'] as bool,
        hasUnpublishedChanges: json['hasUnpublishedChanges'] as bool,
        config: EdenProcessConfig.fromJson(json['config'] as Map<String, dynamic>),
        phases: (json['phases'] as List<dynamic>?)
                ?.map((p) => EdenProcessPhase.fromJson(p as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  @override
  bool operator ==(Object other) {
    if (other is! EdenProcessDefinition) return false;
    if (other.id != id ||
        other.processTypeId != processTypeId ||
        other.name != name ||
        other.displayName != displayName ||
        other.description != description ||
        other.version != version ||
        other.isDefault != isDefault ||
        other.isActive != isActive ||
        other.isPublished != isPublished ||
        other.hasUnpublishedChanges != hasUnpublishedChanges ||
        other.config != config) {
      return false;
    }
    if (other.phases.length != phases.length) return false;
    for (int i = 0; i < phases.length; i++) {
      if (other.phases[i] != phases[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(id, processTypeId, name, displayName, version);
}

// ─────────── EdenProcessValidationIssue ───────────

/// A single validation finding from `EdenProcessValidator` — parity row V-1.
class EdenProcessValidationIssue {
  const EdenProcessValidationIssue({
    required this.type,
    required this.nodeId,
    required this.message,
    this.suggestion,
  });

  final EdenProcessValidationSeverity type;
  final String nodeId;
  final String message;
  final String? suggestion;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'nodeId': nodeId,
        'message': message,
        if (suggestion != null) 'suggestion': suggestion,
      };

  factory EdenProcessValidationIssue.fromJson(Map<String, dynamic> json) =>
      EdenProcessValidationIssue(
        type: EdenProcessValidationSeverity.values
            .firstWhere((s) => s.name == json['type']),
        nodeId: json['nodeId'] as String,
        message: json['message'] as String,
        suggestion: json['suggestion'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is EdenProcessValidationIssue &&
      other.type == type &&
      other.nodeId == nodeId &&
      other.message == message &&
      other.suggestion == suggestion;

  @override
  int get hashCode => Object.hash(type, nodeId, message, suggestion);
}

// ─────────── private helpers ───────────

bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key)) return false;
    final av = entry.value;
    final bv = b[entry.key];
    if (av is Map && bv is Map) {
      if (!_mapEquals(Map<String, dynamic>.from(av), Map<String, dynamic>.from(bv))) {
        return false;
      }
    } else if (av is List && bv is List) {
      if (av.length != bv.length) return false;
      for (int i = 0; i < av.length; i++) {
        if (av[i] != bv[i]) return false;
      }
    } else if (av != bv) {
      return false;
    }
  }
  return true;
}

int _hashJsonValue(dynamic v) {
  if (v is Map) return Object.hashAll(v.entries.map((e) => Object.hash(e.key, _hashJsonValue(e.value))));
  if (v is List) return Object.hashAll(v.map(_hashJsonValue));
  return v.hashCode;
}
