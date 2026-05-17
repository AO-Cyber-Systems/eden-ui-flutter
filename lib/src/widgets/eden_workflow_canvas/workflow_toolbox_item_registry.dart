// EdenWorkflowToolboxItemRegistry — registry of toolbox items.
//
// Donor parity: `WorkflowToolbox.tsx` TOOLBOX_ITEMS (lines 25-210).
// Library ships 19 defaults across 4 categories (trigger / condition /
// action / flow). Verticals register custom items via .register().
// Parity row R-2.

import 'package:flutter/material.dart';

/// A single toolbox item — describes what gets created when dragged/clicked.
class EdenWorkflowToolboxItem {
  const EdenWorkflowToolboxItem({
    required this.id,
    required this.nodeType,
    required this.label,
    required this.icon,
    required this.description,
    required this.category,
    this.defaultData = const {},
  });

  final String id;
  final String nodeType;
  final String label;
  final IconData icon;
  final String description;
  final String category;
  final Map<String, dynamic> defaultData;

  @override
  bool operator ==(Object other) =>
      other is EdenWorkflowToolboxItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Singleton registry of workflow toolbox items. Ships 19 defaults.
class EdenWorkflowToolboxItemRegistry {
  EdenWorkflowToolboxItemRegistry._() {
    _registerDefaults();
  }

  static final EdenWorkflowToolboxItemRegistry instance =
      EdenWorkflowToolboxItemRegistry._();

  final Map<String, EdenWorkflowToolboxItem> _items = {};

  static const List<EdenWorkflowToolboxItem> _defaults = [
    // Triggers (5)
    EdenWorkflowToolboxItem(
      id: 'trigger-event',
      nodeType: 'trigger',
      label: 'Event Trigger',
      icon: Icons.bolt,
      description: 'When entity created/updated',
      category: 'trigger',
      defaultData: {'triggerType': 'entity_created'},
    ),
    EdenWorkflowToolboxItem(
      id: 'trigger-status',
      nodeType: 'trigger',
      label: 'Status Change',
      icon: Icons.refresh,
      description: 'When status changes',
      category: 'trigger',
      defaultData: {'triggerType': 'status_change'},
    ),
    EdenWorkflowToolboxItem(
      id: 'trigger-schedule',
      nodeType: 'trigger',
      label: 'Scheduled',
      icon: Icons.calendar_today,
      description: 'On a schedule',
      category: 'trigger',
      defaultData: {'triggerType': 'scheduled'},
    ),
    EdenWorkflowToolboxItem(
      id: 'trigger-time',
      nodeType: 'trigger',
      label: 'Time-Based',
      icon: Icons.access_time,
      description: 'When time elapses',
      category: 'trigger',
      defaultData: {'triggerType': 'time_based'},
    ),
    EdenWorkflowToolboxItem(
      id: 'trigger-manual',
      nodeType: 'trigger',
      label: 'Manual',
      icon: Icons.touch_app,
      description: 'Triggered manually',
      category: 'trigger',
      defaultData: {'triggerType': 'manual'},
    ),
    // Conditions (3)
    EdenWorkflowToolboxItem(
      id: 'condition-field',
      nodeType: 'condition',
      label: 'Field Condition',
      icon: Icons.tune,
      description: 'Branch on a field value',
      category: 'condition',
    ),
    EdenWorkflowToolboxItem(
      id: 'condition-priority',
      nodeType: 'condition',
      label: 'Priority = High',
      icon: Icons.priority_high,
      description: 'Pre-configured priority check',
      category: 'condition',
      defaultData: {
        'field': 'priority',
        'operator': 'equals',
        'value': 'high',
      },
    ),
    EdenWorkflowToolboxItem(
      id: 'condition-status',
      nodeType: 'condition',
      label: 'Status Check',
      icon: Icons.check_circle_outline,
      description: 'Branch on entity status',
      category: 'condition',
      defaultData: {
        'field': 'status',
        'operator': 'equals',
      },
    ),
    // Actions (6)
    EdenWorkflowToolboxItem(
      id: 'action-task',
      nodeType: 'action',
      label: 'Create Task',
      icon: Icons.add_task,
      description: 'Create a follow-up task',
      category: 'action',
      defaultData: {'actionType': 'create_task'},
    ),
    EdenWorkflowToolboxItem(
      id: 'action-notification',
      nodeType: 'action',
      label: 'Send Notification',
      icon: Icons.notifications,
      description: 'Notify team or customer',
      category: 'action',
      defaultData: {'actionType': 'send_notification'},
    ),
    EdenWorkflowToolboxItem(
      id: 'action-callback',
      nodeType: 'action',
      label: 'Create Callback',
      icon: Icons.phone,
      description: 'Schedule a callback',
      category: 'action',
      defaultData: {'actionType': 'create_callback'},
    ),
    EdenWorkflowToolboxItem(
      id: 'action-status',
      nodeType: 'action',
      label: 'Update Status',
      icon: Icons.swap_vert,
      description: 'Change entity status',
      category: 'action',
      defaultData: {'actionType': 'update_status'},
    ),
    EdenWorkflowToolboxItem(
      id: 'action-email',
      nodeType: 'action',
      label: 'Send Email',
      icon: Icons.mail,
      description: 'Email customer/team',
      category: 'action',
      defaultData: {'actionType': 'send_email'},
    ),
    EdenWorkflowToolboxItem(
      id: 'action-sms',
      nodeType: 'action',
      label: 'Send SMS',
      icon: Icons.message,
      description: 'Text customer',
      category: 'action',
      defaultData: {'actionType': 'send_sms'},
    ),
    // Flow (4)
    EdenWorkflowToolboxItem(
      id: 'flow-delay',
      nodeType: 'delay',
      label: 'Delay',
      icon: Icons.timer_outlined,
      description: 'Wait before next step',
      category: 'flow',
      defaultData: {'delayType': 'fixed', 'delayMinutes': 30},
    ),
    EdenWorkflowToolboxItem(
      id: 'flow-branch',
      nodeType: 'branch',
      label: 'Branch',
      icon: Icons.call_split,
      description: 'Parallel split into multiple paths',
      category: 'flow',
    ),
    EdenWorkflowToolboxItem(
      id: 'flow-merge',
      nodeType: 'merge',
      label: 'Merge',
      icon: Icons.merge,
      description: 'Join parallel paths',
      category: 'flow',
    ),
    EdenWorkflowToolboxItem(
      id: 'flow-end',
      nodeType: 'end',
      label: 'End',
      icon: Icons.stop,
      description: 'Workflow termination',
      category: 'flow',
    ),
  ];

  void _registerDefaults() {
    for (final item in _defaults) {
      _items[item.id] = item;
    }
  }

  void register(EdenWorkflowToolboxItem item) {
    if (_items.containsKey(item.id)) {
      throw StateError(
        'Toolbox item "${item.id}" already registered. Call reset() first.',
      );
    }
    _items[item.id] = item;
  }

  EdenWorkflowToolboxItem? lookup(String id) => _items[id];

  List<EdenWorkflowToolboxItem> all() => List.unmodifiable(_items.values);

  List<EdenWorkflowToolboxItem> byCategory(String category) =>
      _items.values.where((i) => i.category == category).toList(
            growable: false,
          );

  void reset() => _items.clear();

  void resetToDefaults() {
    _items.clear();
    _registerDefaults();
  }
}

/// Payload carried by `Draggable<EdenWorkflowToolboxDragPayload>`.
class EdenWorkflowToolboxDragPayload {
  const EdenWorkflowToolboxDragPayload({required this.itemId});
  final String itemId;
}
