// Do NOT regenerate via LLM — hand-built fixtures for EdenWorkflowModels.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

/// Hand-built fixtures for workflow-canvas tests. Stable / deterministic /
/// reviewable. Used across TRDs 020-01..020-07 (objective 020 — A4-b Visual
/// Workflow Designer).
///
/// Every factory returns a NEW instance per call (no shared mutable state).
/// IDs are deterministic; no random data.

// ─────────── EdenWorkflowCondition ───────────

EdenWorkflowCondition statusEqualsCompletedFixture() => const EdenWorkflowCondition(
      field: 'status',
      operator: EdenWorkflowConditionOperator.equals,
      value: 'completed',
    );

EdenWorkflowCondition priorityEqualsHighFixture() => const EdenWorkflowCondition(
      field: 'priority',
      operator: EdenWorkflowConditionOperator.equals,
      value: 'high',
    );

EdenWorkflowCondition amountGreaterThan5000Fixture() => const EdenWorkflowCondition(
      field: 'amount',
      operator: EdenWorkflowConditionOperator.greater_than,
      value: 5000,
    );

EdenWorkflowCondition customerNameContainsAcmeFixture() => const EdenWorkflowCondition(
      field: 'customer_name',
      operator: EdenWorkflowConditionOperator.contains,
      value: 'Acme',
    );

// ─────────── EdenWorkflowAction ───────────

EdenWorkflowAction createTaskActionFixture({Map<String, dynamic>? config}) =>
    EdenWorkflowAction(
      actionType: 'create_task',
      config: config ?? const {'title': 'Follow up'},
    );

EdenWorkflowAction sendNotificationActionFixture({Map<String, dynamic>? config}) =>
    EdenWorkflowAction(
      actionType: 'send_notification',
      config: config ?? const {'message': 'High priority appointment'},
    );

EdenWorkflowAction sendEmailActionFixture({Map<String, dynamic>? config}) =>
    EdenWorkflowAction(
      actionType: 'send_email',
      config: config ??
          const {
            'to': 'customer@example.com',
            'subject': 'Your appointment',
            'body': 'Hello',
          },
    );

EdenWorkflowAction sendSmsActionFixture({Map<String, dynamic>? config}) =>
    EdenWorkflowAction(
      actionType: 'send_sms',
      config: config ?? const {'to': '+15555550100', 'message': 'Reminder'},
    );

EdenWorkflowAction updateStatusActionFixture({Map<String, dynamic>? config}) =>
    EdenWorkflowAction(
      actionType: 'update_status',
      config: config ?? const {'newStatus': 'completed'},
    );

EdenWorkflowAction createCallbackActionFixture({Map<String, dynamic>? config}) =>
    EdenWorkflowAction(
      actionType: 'create_callback',
      config: config ?? const {'reason': 'follow up'},
    );

// ─────────── EdenWorkflowCanvasLayout ───────────

EdenWorkflowCanvasLayout layoutWithSavedPositionsFixture() => const EdenWorkflowCanvasLayout(
      version: 1,
      nodes: {
        'trigger-0': EdenProcessNodePosition(x: 100, y: 100),
        'condition-0': EdenProcessNodePosition(x: 400, y: 100),
        'action-0': EdenProcessNodePosition(x: 700, y: 50),
        'action-1': EdenProcessNodePosition(x: 700, y: 200),
        'end-0': EdenProcessNodePosition(x: 1000, y: 100),
      },
      edges: [],
    );

EdenWorkflowCanvasLayout emptyLayoutFixture() => EdenWorkflowCanvasLayout.empty();

EdenWorkflowCanvasLayout layoutFor2Cond3ActionFixture() => const EdenWorkflowCanvasLayout(
      version: 1,
      nodes: {
        'trigger-0': EdenProcessNodePosition(x: 100, y: 100),
        'condition-0': EdenProcessNodePosition(x: 400, y: 100),
        'condition-1': EdenProcessNodePosition(x: 700, y: 100),
        'action-0': EdenProcessNodePosition(x: 1000, y: 0),
        'action-1': EdenProcessNodePosition(x: 1000, y: 200),
        'action-2': EdenProcessNodePosition(x: 1000, y: 400),
        'end-0': EdenProcessNodePosition(x: 1300, y: 100),
      },
      edges: [],
    );

// ─────────── EdenWorkflowDefinition — graph-builder scenarios ───────────

EdenWorkflowDefinition definitionWithEmptyConditionsAndActionsFixture() =>
    const EdenWorkflowDefinition(
      id: 1,
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

EdenWorkflowDefinition definitionWithSingleActionFixture() => EdenWorkflowDefinition(
      id: 2,
      name: 'single_action',
      version: 1,
      isPublished: false,
      hasUnpublishedChanges: false,
      triggerType: EdenWorkflowTriggerType.entity_created,
      category: 'appointment',
      triggerConfig: const {},
      conditions: const [],
      actions: [sendNotificationActionFixture()],
    );

EdenWorkflowDefinition definitionWithSingleConditionFixture() => EdenWorkflowDefinition(
      id: 3,
      name: 'single_condition',
      version: 1,
      isPublished: false,
      hasUnpublishedChanges: false,
      triggerType: EdenWorkflowTriggerType.entity_created,
      category: 'appointment',
      triggerConfig: const {},
      conditions: [priorityEqualsHighFixture()],
      actions: const [],
    );

EdenWorkflowDefinition definitionWith2Conditions3ActionsFixture() =>
    EdenWorkflowDefinition(
      id: 4,
      name: 'two_cond_three_action',
      version: 1,
      isPublished: false,
      hasUnpublishedChanges: false,
      triggerType: EdenWorkflowTriggerType.entity_created,
      category: 'appointment',
      triggerConfig: const {},
      conditions: [
        priorityEqualsHighFixture(),
        amountGreaterThan5000Fixture(),
      ],
      actions: [
        sendNotificationActionFixture(),
        createTaskActionFixture(),
        sendEmailActionFixture(),
      ],
    );

EdenWorkflowDefinition definitionWithSavedLayoutFixture() => EdenWorkflowDefinition(
      id: 5,
      name: 'with_saved_layout',
      version: 1,
      isPublished: false,
      hasUnpublishedChanges: false,
      triggerType: EdenWorkflowTriggerType.entity_created,
      category: 'appointment',
      triggerConfig: const {},
      conditions: [
        priorityEqualsHighFixture(),
        amountGreaterThan5000Fixture(),
      ],
      actions: [
        sendNotificationActionFixture(),
        createTaskActionFixture(),
        sendEmailActionFixture(),
      ],
      canvasLayout: layoutFor2Cond3ActionFixture(),
    );

EdenWorkflowDefinition fullExampleDefinitionFixture() => EdenWorkflowDefinition(
      id: 100,
      name: 'auto_followup',
      description: 'Automated high-priority appointment follow-up',
      version: 1,
      isPublished: true,
      hasUnpublishedChanges: false,
      triggerType: EdenWorkflowTriggerType.entity_created,
      category: 'appointment',
      triggerConfig: const {'channel': 'web'},
      conditions: [priorityEqualsHighFixture()],
      actions: [
        sendNotificationActionFixture(),
        createTaskActionFixture(),
        sendSmsActionFixture(),
      ],
      canvasLayout: const EdenWorkflowCanvasLayout(
        version: 1,
        nodes: {
          'trigger-0': EdenProcessNodePosition(x: 100, y: 100),
          'condition-0': EdenProcessNodePosition(x: 400, y: 100),
          'action-0': EdenProcessNodePosition(x: 700, y: 0),
          'action-1': EdenProcessNodePosition(x: 700, y: 150),
          'action-2': EdenProcessNodePosition(x: 700, y: 300),
          'end-0': EdenProcessNodePosition(x: 1000, y: 150),
        },
      ),
    );

// ─────────── Registry fixtures ───────────

EdenWorkflowCategory visitCategoryFixture() => const EdenWorkflowCategory(
      id: 'visit',
      displayName: 'Patient Visit',
      icon: Icons.local_hospital,
    );

EdenWorkflowCategory deliveryCategoryFixture() => const EdenWorkflowCategory(
      id: 'delivery',
      displayName: 'Delivery Route',
      icon: Icons.local_shipping,
    );

EdenWorkflowActionType sendPushActionTypeFixture() => const EdenWorkflowActionType(
      id: 'send_push',
      displayName: 'Send Push Notification',
      icon: Icons.notifications_active,
    );

EdenWorkflowActionType createInvoiceActionTypeFixture() =>
    const EdenWorkflowActionType(
      id: 'create_invoice',
      displayName: 'Create Invoice',
      icon: Icons.receipt_long,
    );
