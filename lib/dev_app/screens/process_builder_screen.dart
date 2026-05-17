import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

/// Dev-catalog screen demonstrating `EdenVisualProcessCanvas` with a
/// populated definition + layout toggle + toolbox toggle + reset.
///
/// Demo state is local — refresh the page (or tap Reset Demo) to restore
/// initial values. Use `just dev-ui` to launch this in the dev catalog.
class ProcessBuilderScreen extends StatefulWidget {
  const ProcessBuilderScreen({super.key});

  @override
  State<ProcessBuilderScreen> createState() => _ProcessBuilderScreenState();
}

class _ProcessBuilderScreenState extends State<ProcessBuilderScreen> {
  late EdenProcessDefinition _definition;
  EdenProcessLayoutEngine _layout = const EdenSwimlaneLayout();
  bool _hideToolbox = false;
  late EdenProcessController _controller;

  @override
  void initState() {
    super.initState();
    _definition = _initialDemo();
    _controller = EdenProcessController(layout: _layout);
    _seedOrphan();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _seedOrphan() {
    _controller.addOrphan(EdenDiagramNode(
      id: _controller.generateOrphanId(),
      x: 800,
      y: 50,
      width: 180,
      height: 56,
      label: 'Inspect machinery',
      data: const {
        'nodeType': 'orphan',
        'orphanType': 'task',
        'displayName': 'Inspect machinery',
        'config': {'runtimeComponent': 'checklist'},
      },
    ));
  }

  void _resetDemo() {
    setState(() {
      _controller.reset();
      _definition = _initialDemo();
      _seedOrphan();
    });
  }

  void _setLayout(EdenProcessLayoutEngine engine) {
    setState(() {
      _layout = engine;
      _controller.layout = engine;
    });
  }

  EdenProcessDefinition _replacePhase(
    int phaseId,
    EdenProcessPhase Function(EdenProcessPhase) update,
  ) {
    final newPhases = _definition.phases
        .map((p) => p.id == phaseId ? update(p) : p)
        .toList();
    return _withPhases(newPhases);
  }

  EdenProcessDefinition _withPhases(List<EdenProcessPhase> phases) =>
      EdenProcessDefinition(
        id: _definition.id,
        processTypeId: _definition.processTypeId,
        name: _definition.name,
        displayName: _definition.displayName,
        description: _definition.description,
        version: _definition.version,
        isDefault: _definition.isDefault,
        isActive: _definition.isActive,
        isPublished: _definition.isPublished,
        hasUnpublishedChanges: _definition.hasUnpublishedChanges,
        config: _definition.config,
        phases: phases,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Process Builder Demo'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<String>(
              value: _layout.id,
              dropdownColor: Theme.of(context).colorScheme.surface,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'swimlane', child: Text('Swimlane')),
                DropdownMenuItem(value: 'free_form', child: Text('Free-form')),
                DropdownMenuItem(value: 'grid', child: Text('Grid')),
                DropdownMenuItem(value: 'linear', child: Text('Linear')),
              ],
              onChanged: (v) {
                switch (v) {
                  case 'swimlane':
                    _setLayout(const EdenSwimlaneLayout());
                  case 'free_form':
                    _setLayout(const EdenFreeFormLayout());
                  case 'grid':
                    _setLayout(const EdenGridLayout());
                  case 'linear':
                    _setLayout(const EdenLinearLayout());
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Demo',
            onPressed: _resetDemo,
          ),
          IconButton(
            icon: Icon(_hideToolbox ? Icons.visibility : Icons.visibility_off),
            tooltip: 'Toggle Toolbox',
            onPressed: () => setState(() => _hideToolbox = !_hideToolbox),
          ),
        ],
      ),
      body: EdenVisualProcessCanvas(
        definition: _definition,
        controller: _controller,
        hideToolbox: _hideToolbox,
        onAddPhase: () {
          // Demo: append a synthetic phase.
          final nextId = (_definition.phases.isEmpty
                  ? 0
                  : _definition.phases
                      .map((p) => p.id)
                      .reduce((a, b) => a > b ? a : b)) +
              1;
          setState(() {
            _definition = _withPhases([
              ..._definition.phases,
              EdenProcessPhase(
                id: nextId,
                processDefinitionId: _definition.id,
                name: 'phase_$nextId',
                displayName: 'New Phase',
                sortOrder: _definition.phases.length,
                color: 'gray',
                isRequired: true,
                isMilestone: false,
                canSkip: false,
                autoAdvance: false,
                runtimeComponent: 'phase_default',
                runtimeComponentConfig: const {},
                allowsScopeChange: false,
                allowsAdHocTasks: false,
                groups: const [],
              ),
            ]);
          });
        },
        onUpdatePhase: (phaseId, updates) {
          setState(() {
            _definition = _replacePhase(phaseId, (p) {
              return EdenProcessPhase(
                id: p.id,
                processDefinitionId: p.processDefinitionId,
                name: p.name,
                displayName:
                    (updates['displayName'] as String?) ?? p.displayName,
                description: updates.containsKey('description')
                    ? updates['description'] as String?
                    : p.description,
                sortOrder: p.sortOrder,
                color: (updates['color'] as String?) ?? p.color,
                icon: p.icon,
                isRequired:
                    (updates['isRequired'] as bool?) ?? p.isRequired,
                isMilestone:
                    (updates['isMilestone'] as bool?) ?? p.isMilestone,
                canSkip: (updates['canSkip'] as bool?) ?? p.canSkip,
                autoAdvance:
                    (updates['autoAdvance'] as bool?) ?? p.autoAdvance,
                runtimeComponent: p.runtimeComponent,
                runtimeComponentConfig: p.runtimeComponentConfig,
                allowsScopeChange: (updates['allowsScopeChange'] as bool?) ??
                    p.allowsScopeChange,
                allowsAdHocTasks: (updates['allowsAdHocTasks'] as bool?) ??
                    p.allowsAdHocTasks,
                groups: p.groups,
              );
            });
          });
        },
        onSaveLayout: (data) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Layout saved (${data.nodes.length} positions, '
                '${data.edges.length} edges)',
              ),
            ),
          );
        },
        onPublish: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Publish — demo only')),
          );
        },
      ),
    );
  }

  EdenProcessDefinition _initialDemo() => _buildDevDemoDefinition();
}

// ─────────── Dev demo definition (private to this screen) ───────────

EdenProcessTaskTemplate _t({
  required int id,
  required int groupId,
  required String displayName,
  required int sortOrder,
  required String runtimeComponent,
  bool isRequired = false,
  bool photoRequired = false,
  bool signatureRequired = false,
  bool approvalRequired = false,
  bool allowsNa = true,
  String blockingBehavior = 'soft',
  String? approvalRole,
}) =>
    EdenProcessTaskTemplate(
      id: id,
      taskGroupId: groupId,
      name: 't_$id',
      displayName: displayName,
      sortOrder: sortOrder,
      runtimeComponent: runtimeComponent,
      runtimeComponentConfig: const {},
      isRequired: isRequired,
      photoRequired: photoRequired,
      signatureRequired: signatureRequired,
      approvalRequired: approvalRequired,
      descriptionRequired: false,
      attachmentRequired: false,
      allowsNa: allowsNa,
      allowsBlocked: false,
      allowsCantDo: false,
      blockingBehavior: blockingBehavior,
      approvalRole: approvalRole,
    );

EdenProcessTaskGroup _g({
  required int id,
  required int phaseId,
  required String displayName,
  required int sortOrder,
  required List<EdenProcessTaskTemplate> tasks,
}) =>
    EdenProcessTaskGroup(
      id: id,
      processPhaseId: phaseId,
      name: 'group_$id',
      displayName: displayName,
      sortOrder: sortOrder,
      isCollapsedDefault: false,
      isRequired: true,
      tasks: tasks,
    );

EdenProcessPhase _p({
  required int id,
  required String displayName,
  required int sortOrder,
  required String color,
  bool isMilestone = false,
  required List<EdenProcessTaskGroup> groups,
}) =>
    EdenProcessPhase(
      id: id,
      processDefinitionId: 1,
      name: 'phase_$id',
      displayName: displayName,
      sortOrder: sortOrder,
      color: color,
      isRequired: true,
      isMilestone: isMilestone,
      canSkip: false,
      autoAdvance: false,
      runtimeComponent: 'phase_default',
      runtimeComponentConfig: const {},
      allowsScopeChange: id == 1,
      allowsAdHocTasks: id != 3,
      groups: groups,
    );

EdenProcessDefinition _buildDevDemoDefinition() {
  final planning = _p(
    id: 1,
    displayName: 'Planning',
    sortOrder: 0,
    color: 'blue',
    groups: [
      _g(
        id: 11,
        phaseId: 1,
        displayName: 'Site Scoping',
        sortOrder: 0,
        tasks: [
          _t(
            id: 100,
            groupId: 11,
            displayName: 'Confirm access',
            sortOrder: 0,
            runtimeComponent: 'checklist',
            isRequired: true,
          ),
          _t(
            id: 101,
            groupId: 11,
            displayName: 'Site survey photos',
            sortOrder: 1,
            runtimeComponent: 'photo_gallery',
            isRequired: true,
            photoRequired: true,
          ),
          _t(
            id: 102,
            groupId: 11,
            displayName: 'Customer interview',
            sortOrder: 2,
            runtimeComponent: 'form',
          ),
        ],
      ),
      _g(
        id: 12,
        phaseId: 1,
        displayName: 'Estimation',
        sortOrder: 1,
        tasks: [
          _t(
            id: 110,
            groupId: 12,
            displayName: 'Material list',
            sortOrder: 0,
            runtimeComponent: 'checklist',
            isRequired: true,
          ),
          _t(
            id: 111,
            groupId: 12,
            displayName: 'Labor estimate',
            sortOrder: 1,
            runtimeComponent: 'form',
            isRequired: true,
          ),
          _t(
            id: 112,
            groupId: 12,
            displayName: 'Customer sign-off',
            sortOrder: 2,
            runtimeComponent: 'signature_capture',
            isRequired: true,
            signatureRequired: true,
            blockingBehavior: 'hard',
          ),
        ],
      ),
    ],
  );

  final execution = _p(
    id: 2,
    displayName: 'Execution',
    sortOrder: 1,
    color: 'green',
    groups: [
      _g(
        id: 21,
        phaseId: 2,
        displayName: 'Crew Prep',
        sortOrder: 0,
        tasks: [
          _t(
            id: 200,
            groupId: 21,
            displayName: 'Pack truck',
            sortOrder: 0,
            runtimeComponent: 'checklist',
            isRequired: true,
          ),
          _t(
            id: 201,
            groupId: 21,
            displayName: 'Safety briefing',
            sortOrder: 1,
            runtimeComponent: 'checklist',
            isRequired: true,
          ),
        ],
      ),
      _g(
        id: 22,
        phaseId: 2,
        displayName: 'On-Site Work',
        sortOrder: 1,
        tasks: [
          _t(
            id: 210,
            groupId: 22,
            displayName: 'Before photos',
            sortOrder: 0,
            runtimeComponent: 'photo_gallery',
            isRequired: true,
            photoRequired: true,
          ),
          _t(
            id: 211,
            groupId: 22,
            displayName: 'Install equipment',
            sortOrder: 1,
            runtimeComponent: 'checklist',
            isRequired: true,
          ),
          _t(
            id: 212,
            groupId: 22,
            displayName: 'After photos',
            sortOrder: 2,
            runtimeComponent: 'photo_gallery',
            isRequired: true,
            photoRequired: true,
          ),
          _t(
            id: 213,
            groupId: 22,
            displayName: 'Cleanup',
            sortOrder: 3,
            runtimeComponent: 'checklist',
          ),
        ],
      ),
    ],
  );

  final closeout = _p(
    id: 3,
    displayName: 'Closeout',
    sortOrder: 2,
    color: 'amber',
    isMilestone: true,
    groups: [
      _g(
        id: 31,
        phaseId: 3,
        displayName: 'QA Inspection',
        sortOrder: 0,
        tasks: [
          _t(
            id: 300,
            groupId: 31,
            displayName: 'Manager review',
            sortOrder: 0,
            runtimeComponent: 'approval_gate',
            isRequired: true,
            approvalRequired: true,
            approvalRole: 'manager',
            blockingBehavior: 'hard',
          ),
          _t(
            id: 301,
            groupId: 31,
            displayName: 'Customer walkthrough',
            sortOrder: 1,
            runtimeComponent: 'checklist',
            isRequired: true,
          ),
          _t(
            id: 302,
            groupId: 31,
            displayName: 'Customer sign-off',
            sortOrder: 2,
            runtimeComponent: 'signature_capture',
            isRequired: true,
            signatureRequired: true,
            blockingBehavior: 'hard',
          ),
        ],
      ),
      _g(
        id: 32,
        phaseId: 3,
        displayName: 'Invoicing',
        sortOrder: 1,
        tasks: [
          _t(
            id: 310,
            groupId: 32,
            displayName: 'Final invoice',
            sortOrder: 0,
            runtimeComponent: 'form',
            isRequired: true,
          ),
          _t(
            id: 311,
            groupId: 32,
            displayName: 'Send to customer',
            sortOrder: 1,
            runtimeComponent: 'checklist',
            isRequired: true,
          ),
        ],
      ),
    ],
  );

  return EdenProcessDefinition(
    id: 1,
    processTypeId: 1,
    name: 'demo_process',
    displayName: 'Dev Demo — Work Order Process',
    description:
        'Three-phase process showing planning, execution, closeout.',
    version: 1,
    isDefault: true,
    isActive: true,
    isPublished: false,
    hasUnpublishedChanges: false,
    config: const EdenProcessConfig(
      flowNodes: {'start': true, 'end': true},
      decisions: [
        EdenProcessDecisionConfig(
          id: 1,
          name: 'High-value job?',
          condition: 'cost > 5000',
        ),
      ],
    ),
    phases: [planning, execution, closeout],
  );
}
