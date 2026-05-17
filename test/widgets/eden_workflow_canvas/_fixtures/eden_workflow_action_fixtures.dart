// Do NOT regenerate via LLM — hand-built fixtures for EdenWorkflowActions.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

/// Hand-built fixtures for action-node tests (TRD 020-03).

EdenDiagramNodeContext actionNodeContextFixture({
  String actionType = 'create_task',
  Map<String, dynamic> config = const {'title': 'Follow up'},
  bool selected = false,
  bool dropTarget = false,
}) {
  return EdenDiagramNodeContext(
    node: EdenDiagramNode(
      id: 'action-0',
      x: 0,
      y: 0,
      width: 200,
      height: 80,
      label: 'Action',
      data: {
        'nodeType': 'action',
        'actionType': actionType,
        'config': config,
      },
    ),
    selected: selected,
    dropTarget: dropTarget,
  );
}

EdenWorkflowActionType customActionTypeFixture() => const EdenWorkflowActionType(
      id: 'send_push',
      displayName: 'Send Push Notification',
      icon: Icons.notifications_active,
      fields: [
        EdenWorkflowActionFieldSpec(
          id: 'deviceToken',
          label: 'Device Token',
          type: 'text',
        ),
        EdenWorkflowActionFieldSpec(
          id: 'title',
          label: 'Title',
          type: 'text',
        ),
        EdenWorkflowActionFieldSpec(
          id: 'body',
          label: 'Body',
          type: 'textarea',
        ),
      ],
    );

EdenWorkflowActionType createInvoiceActionTypeFixture() =>
    const EdenWorkflowActionType(
      id: 'create_invoice',
      displayName: 'Create Invoice',
      icon: Icons.receipt_long,
      fields: [
        EdenWorkflowActionFieldSpec(
          id: 'amount',
          label: 'Amount',
          type: 'number',
        ),
        EdenWorkflowActionFieldSpec(
          id: 'description',
          label: 'Description',
          type: 'textarea',
        ),
      ],
    );
