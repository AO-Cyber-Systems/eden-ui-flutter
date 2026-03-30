import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/section.dart';

/// Showcase screen for canvas and process components:
/// EdenCanvasToolbar, EdenSwimlaneChart, EdenRuleTree, EdenPhaseChecklist.
class ProcessScreen extends StatefulWidget {
  const ProcessScreen({super.key});

  @override
  State<ProcessScreen> createState() => _ProcessScreenState();
}

class _ProcessScreenState extends State<ProcessScreen> {
  double _swimlaneZoom = 1.0;
  double _ruleTreeZoom = 1.0;
  final _swimlaneController = TransformationController();
  final _ruleTreeController = TransformationController();

  @override
  void dispose() {
    _swimlaneController.dispose();
    _ruleTreeController.dispose();
    super.dispose();
  }

  void _setZoom(
    TransformationController controller,
    double Function() getZoom,
    void Function(double) setZoom,
    double delta,
  ) {
    setState(() {
      final newZoom = (getZoom() + delta).clamp(0.5, 2.0);
      setZoom(newZoom);
      controller.value = Matrix4.diagonal3Values(newZoom, newZoom, 1.0);
    });
  }

  void _resetZoom(
    TransformationController controller,
    void Function(double) setZoom,
  ) {
    setState(() {
      setZoom(1.0);
      controller.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Process & Canvas')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          // ---------------------------------------------------------------
          // Swimlane Chart
          // ---------------------------------------------------------------
          Section(
            title: 'Swimlane Chart with Toolbar',
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: EdenRadii.borderRadiusLg,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  EdenCanvasToolbar(
                    zoomLevel: _swimlaneZoom,
                    onZoomIn: () => _setZoom(
                      _swimlaneController,
                      () => _swimlaneZoom,
                      (v) => _swimlaneZoom = v,
                      0.1,
                    ),
                    onZoomOut: () => _setZoom(
                      _swimlaneController,
                      () => _swimlaneZoom,
                      (v) => _swimlaneZoom = v,
                      -0.1,
                    ),
                    onZoomFit: () =>
                        _resetZoom(_swimlaneController, (v) => _swimlaneZoom = v),
                    actions: [
                      EdenCanvasToolbarAction(
                        label: '+ Phase',
                        icon: Icons.view_stream_outlined,
                      ),
                      EdenCanvasToolbarAction(
                        label: '+ Group',
                        icon: Icons.view_column_outlined,
                      ),
                    ],
                  ),
                  Expanded(
                    child: EdenSwimlaneChart(
                      transformationController: _swimlaneController,
                      phases: const [
                        EdenSwimlanePhase(
                          name: 'Prep',
                          color: Color(0xFF3B82F6),
                          groups: [
                            EdenSwimlaneGroup(name: 'Materials', items: [
                              EdenSwimlaneItem(
                                  label: 'Order supplies', isRequired: true),
                              EdenSwimlaneItem(label: 'Confirm delivery'),
                            ]),
                            EdenSwimlaneGroup(name: 'Permits', items: [
                              EdenSwimlaneItem(
                                  label: 'Submit permit', isRequired: true),
                              EdenSwimlaneItem(label: 'Inspection scheduled'),
                            ]),
                          ],
                        ),
                        EdenSwimlanePhase(
                          name: 'Install',
                          color: Color(0xFF10B981),
                          groups: [
                            EdenSwimlaneGroup(name: 'Rough-In', items: [
                              EdenSwimlaneItem(
                                  label: 'Run ductwork', isRequired: true),
                              EdenSwimlaneItem(label: 'Electrical connections'),
                              EdenSwimlaneItem(label: 'Test airflow'),
                            ]),
                            EdenSwimlaneGroup(name: 'Equipment', items: [
                              EdenSwimlaneItem(
                                  label: 'Mount unit', isRequired: true),
                              EdenSwimlaneItem(label: 'Connect refrigerant'),
                            ]),
                          ],
                        ),
                        EdenSwimlanePhase(
                          name: 'Close',
                          color: Color(0xFFA855F7),
                          groups: [
                            EdenSwimlaneGroup(name: 'Final', items: [
                              EdenSwimlaneItem(label: 'Final inspection'),
                              EdenSwimlaneItem(label: 'Customer walkthrough'),
                              EdenSwimlaneItem(label: 'Sign-off'),
                            ]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: EdenSpacing.space6),

          // ---------------------------------------------------------------
          // Rule Tree
          // ---------------------------------------------------------------
          Section(
            title: 'Rule Tree — Decision Flow',
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: EdenRadii.borderRadiusLg,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  EdenCanvasToolbar(
                    zoomLevel: _ruleTreeZoom,
                    onZoomIn: () => _setZoom(
                      _ruleTreeController,
                      () => _ruleTreeZoom,
                      (v) => _ruleTreeZoom = v,
                      0.1,
                    ),
                    onZoomOut: () => _setZoom(
                      _ruleTreeController,
                      () => _ruleTreeZoom,
                      (v) => _ruleTreeZoom = v,
                      -0.1,
                    ),
                    onZoomFit: () =>
                        _resetZoom(_ruleTreeController, (v) => _ruleTreeZoom = v),
                  ),
                  Expanded(
                    child: EdenRuleTree(
                      transformationController: _ruleTreeController,
                      roots: const [
                        EdenRuleNode(
                          title: 'Project Created',
                          style: EdenRuleNodeStyles.trigger,
                          subtitle: 'entity_created event',
                          children: [
                            EdenRuleNode(
                              title: 'Value > \$10K?',
                              style: EdenRuleNodeStyles.condition,
                              children: [
                                EdenRuleNode(
                                  title: 'Assign Senior Tech',
                                  style: EdenRuleNodeStyles.action,
                                  subtitle: 'Auto-assign by skill',
                                ),
                                EdenRuleNode(
                                  title: 'Wait 2 Hours',
                                  style: EdenRuleNodeStyles.delay,
                                  children: [
                                    EdenRuleNode(
                                      title: 'Notify Dispatcher',
                                      style: EdenRuleNodeStyles.action,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const EdenDivider(label: 'Phase Checklist'),

          // ---------------------------------------------------------------
          // Phase Checklist
          // ---------------------------------------------------------------
          Section(
            title: 'Phase Checklist — Execution View',
            child: EdenPhaseChecklist(
              onTaskToggle: (id, value) {},
              onTaskLongPress: (id) {},
              phases: const [
                EdenChecklistPhase(
                  id: 'prep',
                  name: 'Preparation',
                  groups: [
                    EdenChecklistGroup(name: 'Materials', tasks: [
                      EdenChecklistTask(
                        id: '1',
                        title: 'Order HVAC unit',
                        isCompleted: true,
                        isRequired: true,
                      ),
                      EdenChecklistTask(
                        id: '2',
                        title: 'Confirm delivery date',
                        isCompleted: true,
                      ),
                      EdenChecklistTask(
                        id: '3',
                        title: 'Stage equipment on-site',
                        assignedTo: 'Mike R.',
                      ),
                    ]),
                    EdenChecklistGroup(name: 'Permits', tasks: [
                      EdenChecklistTask(
                        id: '4',
                        title: 'Submit building permit',
                        isCompleted: true,
                        isRequired: true,
                      ),
                      EdenChecklistTask(
                        id: '5',
                        title: 'Schedule inspection',
                      ),
                    ]),
                  ],
                ),
                EdenChecklistPhase(
                  id: 'install',
                  name: 'Installation',
                  groups: [
                    EdenChecklistGroup(name: 'Rough-In', tasks: [
                      EdenChecklistTask(
                        id: '6',
                        title: 'Run ductwork',
                        isRequired: true,
                        isBlocked: true,
                        blockedReason: 'PO-2847',
                      ),
                      EdenChecklistTask(
                        id: '7',
                        title: 'Electrical connections',
                      ),
                    ]),
                    EdenChecklistGroup(name: 'Equipment', tasks: [
                      EdenChecklistTask(
                        id: '8',
                        title: 'Mount condenser unit',
                        isRequired: true,
                      ),
                      EdenChecklistTask(
                        id: '9',
                        title: 'Connect refrigerant lines',
                      ),
                      EdenChecklistTask(
                        id: '10',
                        title: 'Old thermostat removal',
                        isNa: true,
                        naReason: 'New construction, no existing unit',
                      ),
                    ]),
                  ],
                ),
                EdenChecklistPhase(
                  id: 'close',
                  name: 'Closeout',
                  groups: [
                    EdenChecklistGroup(name: 'Final Steps', tasks: [
                      EdenChecklistTask(
                        id: '11',
                        title: 'Final inspection',
                        isRequired: true,
                      ),
                      EdenChecklistTask(
                        id: '12',
                        title: 'Customer walkthrough',
                      ),
                      EdenChecklistTask(
                        id: '13',
                        title: 'Collect sign-off',
                        isRequired: true,
                      ),
                    ]),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
