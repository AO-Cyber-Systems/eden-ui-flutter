import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

/// Dev-catalog screen demonstrating `EdenVisualWorkflowCanvas` with a
/// populated demo workflow (entity_created on appointment → priority=high →
/// send_notification → create_task → end).
///
/// Use `just dev-ui` to launch in the dev catalog.
class WorkflowDesignerScreen extends StatefulWidget {
  const WorkflowDesignerScreen({super.key});

  @override
  State<WorkflowDesignerScreen> createState() => _WorkflowDesignerScreenState();
}

class _WorkflowDesignerScreenState extends State<WorkflowDesignerScreen> {
  late EdenWorkflowDefinition _definition;
  EdenWorkflowSaveData? _lastSave;

  @override
  void initState() {
    super.initState();
    _definition = _initialDemo();
  }

  EdenWorkflowDefinition _initialDemo() => const EdenWorkflowDefinition(
        id: 1,
        name: 'auto_followup',
        description: 'Automated follow-up for high-priority appointments',
        version: 1,
        isPublished: false,
        hasUnpublishedChanges: false,
        triggerType: EdenWorkflowTriggerType.entity_created,
        category: 'appointment',
        triggerConfig: {},
        conditions: [
          EdenWorkflowCondition(
            field: 'priority',
            operator: EdenWorkflowConditionOperator.equals,
            value: 'high',
          ),
        ],
        actions: [
          EdenWorkflowAction(
            actionType: 'send_notification',
            config: {'title': 'High-priority appointment created'},
          ),
          EdenWorkflowAction(
            actionType: 'create_task',
            config: {
              'title': 'Follow up with customer',
              'priority': 'high',
            },
          ),
          EdenWorkflowAction(
            actionType: 'send_sms',
            config: {'phoneNumber': '+15555550100'},
          ),
        ],
      );

  void _resetDemo() {
    setState(() {
      _definition = _initialDemo();
      _lastSave = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workflow Designer (obj 020)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset demo',
            onPressed: _resetDemo,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_lastSave != null)
            Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.check, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Save fired — ${_lastSave!.actions.length} actions, '
                      '${_lastSave!.conditions.length} conditions',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: EdenVisualWorkflowCanvas(
              definition: _definition,
              onSave: (save) => setState(() => _lastSave = save),
            ),
          ),
        ],
      ),
    );
  }
}
