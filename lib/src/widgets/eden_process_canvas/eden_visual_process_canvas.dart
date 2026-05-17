import 'package:flutter/material.dart';

import '../eden_diagram/eden_diagram_exports.dart';
import 'dialogs/eden_process_phase_editor_dialog.dart';
import 'dialogs/eden_process_task_editor_dialog.dart';
import 'dialogs/eden_process_task_group_editor_dialog.dart';
import 'eden_edge_context_menu.dart';
import 'eden_node_context_menu.dart';
import 'eden_process_toolbox.dart';
import 'eden_process_validation_panel.dart';
import 'nodes/eden_process_node_renderer.dart';
import 'process_controller.dart';
import 'process_graph_builder.dart';
import 'process_layout_engine.dart';
import 'process_models.dart';
import 'process_validator.dart';

/// Composite root for the visual process canvas — parity rows D-3 / D-4 /
/// D-5 / L-4 / V-3 (validation panel wire-up).
///
/// Wires the Wave 1-4 widgets together: toolbox + EdenDiagram + chrome +
/// editor dialogs + context menus + validation panel. Consumer-facing API
/// is callback-only — the canvas never mutates the definition directly.
///
/// **iPhone-narrow fallback (Constraint 7):** at MediaQuery.width < 1200,
/// renders a read-only summary widget. Process building requires
/// tablet/desktop width.
class EdenVisualProcessCanvas extends StatefulWidget {
  const EdenVisualProcessCanvas({
    super.key,
    required this.definition,
    this.controller,
    this.layout,
    this.onClose,
    this.onAddPhase,
    this.onUpdatePhase,
    this.onDeletePhase,
    this.onAddTaskGroup,
    this.onUpdateTaskGroup,
    this.onDeleteTaskGroup,
    this.onAddTask,
    this.onAddTaskInPhase,
    this.onUpdateTask,
    this.onDeleteTask,
    this.onAddDecision,
    this.onUpdateDecision,
    this.onDeleteDecision,
    this.onImportTemplate,
    this.onSplitTaskToNewGroup,
    this.onSaveLayout,
    this.onPublish,
    this.onRevert,
    this.isPublishing = false,
    this.isSaving = false,
    this.isReverting = false,
    this.hideToolbox = false,
    this.toolboxCategories,
    this.toolboxTemplates,
    this.recommendedWorkCategoryId,
    this.templatesForPhaseMenu = const [],
  });

  final EdenProcessDefinition definition;
  final EdenProcessController? controller;
  final EdenProcessLayoutEngine? layout;
  final VoidCallback? onClose;
  final VoidCallback? onAddPhase;
  final void Function(int phaseId, Map<String, dynamic> updates)? onUpdatePhase;
  final void Function(int phaseId)? onDeletePhase;
  final void Function(int phaseId)? onAddTaskGroup;
  final void Function(int groupId, Map<String, dynamic> updates)?
      onUpdateTaskGroup;
  final void Function(int groupId)? onDeleteTaskGroup;
  final void Function(int groupId, Map<String, dynamic>? config)? onAddTask;
  final void Function(int phaseId, Map<String, dynamic>? config)?
      onAddTaskInPhase;
  final void Function(int taskId, Map<String, dynamic> updates)? onUpdateTask;
  final void Function(int taskId)? onDeleteTask;
  final VoidCallback? onAddDecision;
  final void Function(int decisionId, Map<String, dynamic> updates)?
      onUpdateDecision;
  final void Function(int decisionId)? onDeleteDecision;
  final void Function(int phaseId, int templateId)? onImportTemplate;
  final void Function(int taskId, int newPhaseId)? onSplitTaskToNewGroup;
  final void Function(EdenProcessLayoutData layout)? onSaveLayout;
  final VoidCallback? onPublish;
  final VoidCallback? onRevert;
  final bool isPublishing;
  final bool isSaving;
  final bool isReverting;
  final bool hideToolbox;
  final List<EdenProcessToolboxCategory>? toolboxCategories;
  final List<EdenProcessToolboxTemplate>? toolboxTemplates;
  final int? recommendedWorkCategoryId;
  final List<({int id, String name})> templatesForPhaseMenu;

  @override
  State<EdenVisualProcessCanvas> createState() =>
      _EdenVisualProcessCanvasState();
}

class _EdenVisualProcessCanvasState extends State<EdenVisualProcessCanvas> {
  late EdenProcessController _controller;
  bool _ownsController = false;
  final _diagramKey = GlobalKey<EdenDiagramState>();

  Offset? _menuPos;
  EdenDiagramNode? _menuNode;
  EdenDiagramEdge? _menuEdge;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = EdenProcessController(layout: widget.layout);
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 1200) {
      return _NarrowFallback(definition: widget.definition);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (ctx, _) => _buildFullCanvas(ctx),
    );
  }

  Widget _buildFullCanvas(BuildContext context) {
    final (nodes, edges) =
        EdenProcessGraphBuilder.build(widget.definition, controller: _controller);
    final laidOut = _controller.layout.applyLayout(nodes, edges);
    final allNodes = <EdenDiagramNode>[...laidOut, ..._controller.orphans];
    final allEdges = <EdenDiagramEdge>[...edges, ..._controller.userEdges];
    final diagramData = EdenDiagramData(nodes: allNodes, edges: allEdges);

    final phasesById = {for (final p in widget.definition.phases) p.id: p};
    final groupsById = {
      for (final p in widget.definition.phases)
        for (final g in p.groups) g.id: g
    };
    final tasksById = {
      for (final p in widget.definition.phases)
        for (final g in p.groups)
          for (final t in g.tasks) t.id: t
    };
    final decisionsById = {
      for (final d in widget.definition.config.decisions) d.id: d
    };

    final rendererConfig = EdenProcessNodeRendererConfig(
      onDeleteOrphan: (id) => _controller.removeOrphan(id),
      onTogglePhaseExpanded: (id) => _controller.togglePhaseExpanded(id),
      onUpdatePhase: widget.onUpdatePhase,
      onDeletePhase: widget.onDeletePhase,
      onOpenPhaseEditor: (id) => _openPhaseEditor(id, phasesById),
      phasesById: phasesById,
      expandedPhaseIds: _controller.expandedPhaseIds,
      groupsById: groupsById,
      onUpdateTaskGroup: widget.onUpdateTaskGroup,
      onDeleteTaskGroup: widget.onDeleteTaskGroup,
      onOpenTaskGroupEditor: (id) => _openTaskGroupEditor(id, groupsById),
      onAddTaskInGroup: widget.onAddTask,
      onUpdateTask: widget.onUpdateTask,
      onDeleteTask: widget.onDeleteTask,
      onSplitTaskToNewGroup: widget.onSplitTaskToNewGroup,
      tasksById: tasksById,
      decisionsById: decisionsById,
      onOpenTaskEditor: (id) => _openTaskEditor(id, tasksById),
      onUpdateDecision: widget.onUpdateDecision,
      onDeleteDecision: widget.onDeleteDecision,
    );

    final validation =
        EdenProcessValidator.validate(widget.definition, allNodes, allEdges);

    return Column(
      children: [
        _Toolbar(
          definition: widget.definition,
          validation: validation,
          isSaving: widget.isSaving,
          isPublishing: widget.isPublishing,
          isReverting: widget.isReverting,
          onAutoLayout: _autoLayout,
          onSave: _handleSave,
          onPublish: widget.onPublish,
          onRevert: widget.onRevert,
          onClose: widget.onClose,
        ),
        Expanded(
          child: Row(
            children: [
              if (!widget.hideToolbox)
                EdenProcessToolbox(
                  categories:
                      widget.toolboxCategories ?? const [],
                  templates:
                      widget.toolboxTemplates ?? const [],
                  recommendedWorkCategoryId:
                      widget.recommendedWorkCategoryId,
                  onAddNode: _handleClickAddNode,
                  onTemplateSelected: _handleClickTemplate,
                ),
              Expanded(
                child: DragTarget<EdenProcessDragPayload>(
                  onWillAcceptWithDetails: (_) => true,
                  onMove: (details) => _diagramKey.currentState
                      ?.onDragUpdate(details.offset),
                  onLeave: (_) =>
                      _diagramKey.currentState?.onDragLeave(),
                  onAcceptWithDetails: (details) =>
                      _handleDrop(details.data, details.offset),
                  builder: (ctx, candidate, rejected) => Stack(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onSecondaryTapDown: (details) =>
                            _maybeOpenContextMenu(details.globalPosition),
                        onLongPressStart: (details) =>
                            _maybeOpenContextMenu(details.globalPosition),
                        child: EdenDiagram(
                          key: _diagramKey,
                          data: diagramData,
                          customNodeRenderer: (nodeCtx) =>
                              EdenProcessNodeRenderer.dispatch(
                            nodeCtx,
                            config: rendererConfig,
                          ),
                          onDropTargetChanged: (_) {},
                        ),
                      ),
                      if (_menuNode != null && _menuPos != null)
                        Positioned(
                          left: _menuPos!.dx,
                          top: _menuPos!.dy,
                          child: SizedBox(
                            width: 240,
                            child: EdenNodeContextMenu(
                              actions: _buildContextActions(
                                _menuNode!,
                                phasesById,
                                groupsById,
                                tasksById,
                                decisionsById,
                              ),
                              onClose: () => setState(() {
                                _menuNode = null;
                                _menuPos = null;
                              }),
                            ),
                          ),
                        ),
                      if (_menuEdge != null && _menuPos != null)
                        Positioned(
                          left: _menuPos!.dx,
                          top: _menuPos!.dy,
                          child: SizedBox(
                            width: 200,
                            child: EdenEdgeContextMenu(
                              onDelete: () => _controller
                                  .removeUserEdge(_menuEdge!.id),
                              onClose: () => setState(() {
                                _menuEdge = null;
                                _menuPos = null;
                              }),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────── handlers ───────────

  void _autoLayout() {
    // Force a notifyListeners by toggling a no-op (auto-layout requires
    // controller state to refresh). Simplest: call updateLayoutEngine with
    // the same layout — but that's a no-op. Just trigger setState.
    setState(() {});
  }

  void _handleSave() {
    final data = _controller.toLayoutData();
    widget.onSaveLayout?.call(data);
  }

  void _handleClickAddNode(String dragType, Map<String, dynamic>? config) {
    _dispatchAdd(dragType, config, null);
  }

  void _handleClickTemplate(int templateId) {
    final phaseId = widget.definition.phases.isNotEmpty
        ? widget.definition.phases.first.id
        : null;
    if (phaseId != null) {
      widget.onImportTemplate?.call(phaseId, templateId);
    }
  }

  void _handleDrop(EdenProcessDragPayload payload, Offset screenPos) {
    final target = _diagramKey.currentState?.hitTestNode(screenPos);
    _dispatchAdd(payload.dragType, payload.config, target);
  }

  void _dispatchAdd(
    String dragType,
    Map<String, dynamic>? config,
    EdenDiagramNode? target,
  ) {
    final targetType = target?.data['nodeType'] as String?;
    switch (dragType) {
      case 'phase':
        widget.onAddPhase?.call();
      case 'task':
        if (targetType == 'taskGroup') {
          widget.onAddTask?.call(target!.data['groupId'] as int, config);
        } else if (targetType == 'phase') {
          widget.onAddTaskInPhase
              ?.call(target!.data['phaseId'] as int, config);
        } else {
          final firstPhaseId = widget.definition.phases.isNotEmpty
              ? widget.definition.phases.first.id
              : null;
          if (firstPhaseId != null) {
            widget.onAddTaskInPhase?.call(firstPhaseId, config);
          }
        }
      case 'taskGroup':
        final phaseId = targetType == 'phase'
            ? target!.data['phaseId'] as int
            : widget.definition.phases.isNotEmpty
                ? widget.definition.phases.first.id
                : null;
        if (phaseId != null) widget.onAddTaskGroup?.call(phaseId);
      case 'templateGroup':
        final phaseId = targetType == 'phase'
            ? target!.data['phaseId'] as int
            : widget.definition.phases.isNotEmpty
                ? widget.definition.phases.first.id
                : null;
        final templateId = config?['templateId'] as int?;
        if (phaseId != null && templateId != null) {
          widget.onImportTemplate?.call(phaseId, templateId);
        }
      case 'decision':
        widget.onAddDecision?.call();
    }
  }

  void _maybeOpenContextMenu(Offset screenPos) {
    final state = _diagramKey.currentState;
    if (state == null) return;
    final localPos = _toLocal(screenPos);
    final hitNode = state.hitTestNode(screenPos);
    if (hitNode != null) {
      setState(() {
        _menuNode = hitNode;
        _menuEdge = null;
        _menuPos = localPos;
      });
      return;
    }
    final hitEdge = state.hitTestEdge(screenPos);
    if (hitEdge != null) {
      setState(() {
        _menuEdge = hitEdge;
        _menuNode = null;
        _menuPos = localPos;
      });
    }
  }

  Offset _toLocal(Offset screenPos) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return screenPos;
    return box.globalToLocal(screenPos);
  }

  List<EdenNodeContextMenuAction> _buildContextActions(
    EdenDiagramNode node,
    Map<int, EdenProcessPhase> phasesById,
    Map<int, EdenProcessTaskGroup> groupsById,
    Map<int, EdenProcessTaskTemplate> tasksById,
    Map<int, EdenProcessDecisionConfig> decisionsById,
  ) {
    final type = node.data['nodeType'] as String?;
    switch (type) {
      case 'phase':
        final id = node.data['phaseId'] as int;
        return [
          EdenNodeContextMenuAction(
            label: 'Add Task',
            icon: Icons.check_box,
            onTap: () => widget.onAddTaskInPhase?.call(id, null),
          ),
          EdenNodeContextMenuAction(
            label: 'Add Task Group',
            icon: Icons.folder,
            onTap: () => widget.onAddTaskGroup?.call(id),
          ),
          if (widget.templatesForPhaseMenu.isNotEmpty)
            EdenNodeContextMenuAction(
              label: 'Apply Template',
              icon: Icons.menu_book,
              onTap: () {},
              submenuItems: [
                for (final t in widget.templatesForPhaseMenu)
                  EdenNodeContextMenuAction(
                    label: t.name,
                    icon: Icons.description,
                    onTap: () =>
                        widget.onImportTemplate?.call(id, t.id),
                  ),
              ],
            ),
          EdenNodeContextMenuAction(
            label: 'Edit',
            icon: Icons.edit,
            onTap: () => _openPhaseEditor(id, phasesById),
          ),
          EdenNodeContextMenuAction(
            label: 'Delete',
            icon: Icons.delete,
            destructive: true,
            onTap: () => widget.onDeletePhase?.call(id),
          ),
        ];
      case 'taskGroup':
        final id = node.data['groupId'] as int;
        return [
          EdenNodeContextMenuAction(
            label: 'Add Task',
            icon: Icons.check_box,
            onTap: () => widget.onAddTask?.call(id, null),
          ),
          EdenNodeContextMenuAction(
            label: 'Edit',
            icon: Icons.edit,
            onTap: () => _openTaskGroupEditor(id, groupsById),
          ),
          EdenNodeContextMenuAction(
            label: 'Delete',
            icon: Icons.delete,
            destructive: true,
            onTap: () => widget.onDeleteTaskGroup?.call(id),
          ),
        ];
      case 'task':
        final id = node.data['taskId'] as int;
        return [
          EdenNodeContextMenuAction(
            label: 'Edit',
            icon: Icons.edit,
            onTap: () => _openTaskEditor(id, tasksById),
          ),
          EdenNodeContextMenuAction(
            label: 'Delete',
            icon: Icons.delete,
            destructive: true,
            onTap: () => widget.onDeleteTask?.call(id),
          ),
        ];
      case 'decision':
        final id = node.data['decisionId'] as int;
        return [
          EdenNodeContextMenuAction(
            label: 'Delete',
            icon: Icons.delete,
            destructive: true,
            onTap: () => widget.onDeleteDecision?.call(id),
          ),
        ];
      case 'orphan':
        return [
          EdenNodeContextMenuAction(
            label: 'Delete',
            icon: Icons.delete,
            destructive: true,
            onTap: () => _controller.removeOrphan(node.id),
          ),
        ];
      default:
        return const [];
    }
  }

  Future<void> _openPhaseEditor(
    int phaseId,
    Map<int, EdenProcessPhase> phasesById,
  ) async {
    final phase = phasesById[phaseId];
    if (phase == null) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => EdenProcessPhaseEditorDialog(
        phase: phase,
        onUpdate: (updates) =>
            widget.onUpdatePhase?.call(phaseId, updates),
      ),
    );
  }

  Future<void> _openTaskGroupEditor(
    int groupId,
    Map<int, EdenProcessTaskGroup> groupsById,
  ) async {
    final group = groupsById[groupId];
    if (group == null) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => EdenProcessTaskGroupEditorDialog(
        group: group,
        onUpdate: (updates) =>
            widget.onUpdateTaskGroup?.call(groupId, updates),
        onAddTask: (gid, cfg) => widget.onAddTask?.call(gid, cfg),
        onDeleteTask: (id) => widget.onDeleteTask?.call(id),
        onEditTask: (id) {
          final tasksById = {
            for (final p in widget.definition.phases)
              for (final g in p.groups)
                for (final t in g.tasks) t.id: t
          };
          _openTaskEditor(id, tasksById);
        },
      ),
    );
  }

  Future<void> _openTaskEditor(
    int taskId,
    Map<int, EdenProcessTaskTemplate> tasksById,
  ) async {
    final task = tasksById[taskId];
    if (task == null) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => EdenProcessTaskEditorDialog(
        task: task,
        onUpdate: (updates) =>
            widget.onUpdateTask?.call(taskId, updates),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.definition,
    required this.validation,
    required this.isSaving,
    required this.isPublishing,
    required this.isReverting,
    required this.onAutoLayout,
    required this.onSave,
    required this.onPublish,
    required this.onRevert,
    required this.onClose,
  });

  final EdenProcessDefinition definition;
  final EdenProcessValidationResult validation;
  final bool isSaving;
  final bool isPublishing;
  final bool isReverting;
  final VoidCallback onAutoLayout;
  final VoidCallback onSave;
  final VoidCallback? onPublish;
  final VoidCallback? onRevert;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          if (onClose != null)
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 16),
              tooltip: 'Back',
              onPressed: onClose,
            ),
          Text(
            definition.displayName,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          EdenProcessValidationPanel(result: validation),
          const Spacer(),
          TextButton.icon(
            key: const ValueKey('canvas-auto-layout-button'),
            onPressed: onAutoLayout,
            icon: const Icon(Icons.auto_awesome, size: 14),
            label: const Text('Auto-layout'),
          ),
          const SizedBox(width: 4),
          if (definition.hasUnpublishedChanges && onRevert != null)
            TextButton.icon(
              key: const ValueKey('canvas-revert-button'),
              onPressed: isReverting ? null : onRevert,
              icon: const Icon(Icons.undo, size: 14),
              label: const Text('Revert'),
            ),
          const SizedBox(width: 4),
          FilledButton.icon(
            key: const ValueKey('canvas-save-button'),
            onPressed: isSaving ? null : onSave,
            icon: const Icon(Icons.save, size: 14),
            label: const Text('Save'),
          ),
          if (onPublish != null &&
              (!definition.isPublished ||
                  definition.hasUnpublishedChanges)) ...[
            const SizedBox(width: 4),
            FilledButton.icon(
              key: const ValueKey('canvas-publish-button'),
              onPressed: isPublishing ? null : onPublish,
              icon: const Icon(Icons.publish, size: 14),
              label: const Text('Publish'),
            ),
          ],
        ],
      ),
    );
  }
}

class _NarrowFallback extends StatelessWidget {
  const _NarrowFallback({required this.definition});

  final EdenProcessDefinition definition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: const ValueKey('canvas-narrow-fallback'),
      color: theme.colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            definition.displayName,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Process builder requires tablet/desktop width (≥1200pt). '
            'Below is a read-only summary of this process.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          if (definition.phases.isEmpty)
            Text(
              'No phases defined yet.',
              style: theme.textTheme.bodyMedium,
            )
          else
            for (final phase in definition.phases) ...[
              Text(
                phase.displayName,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              for (final group in phase.groups)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: Text(
                    '${group.displayName} — ${group.tasks.length} task${group.tasks.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}
