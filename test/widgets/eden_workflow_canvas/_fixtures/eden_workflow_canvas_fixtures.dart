// Do NOT regenerate via LLM — hand-built fixtures for EdenVisualWorkflowCanvas.

import 'package:eden_ui_flutter/eden_ui.dart';

EdenWorkflowDefinition populatedWorkflowDefinitionFixture() =>
    const EdenWorkflowDefinition(
      id: 100,
      name: 'auto_followup',
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
          config: {'title': 'High-priority appointment'},
        ),
        EdenWorkflowAction(
          actionType: 'create_task',
          config: {'title': 'Follow up'},
        ),
      ],
    );

EdenWorkflowDefinition simpleWorkflowDefinitionFixture() =>
    const EdenWorkflowDefinition(
      id: 1,
      name: 'simple',
      version: 1,
      isPublished: false,
      hasUnpublishedChanges: false,
      triggerType: EdenWorkflowTriggerType.entity_created,
      category: 'task',
      triggerConfig: {},
      conditions: [],
      actions: [
        EdenWorkflowAction(actionType: 'create_task'),
      ],
    );

EdenWorkflowDefinition triggerOnlyDefinitionFixture() =>
    const EdenWorkflowDefinition(
      id: 2,
      name: 'trigger_only',
      version: 1,
      isPublished: false,
      hasUnpublishedChanges: false,
      triggerType: EdenWorkflowTriggerType.entity_created,
      category: 'appointment',
      triggerConfig: {},
      conditions: [],
      actions: [],
    );
