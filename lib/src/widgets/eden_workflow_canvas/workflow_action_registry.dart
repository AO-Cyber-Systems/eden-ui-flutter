import 'package:flutter/material.dart';

/// A workflow action type — describes the kind of side-effect a workflow
/// action triggers (e.g. `create_task`, `send_email`, `send_sms`).
///
/// Library ships 6 sensible defaults; verticals register vertical-specific
/// action types (e.g. `send_push`, `create_invoice`) via
/// `EdenWorkflowActionRegistry.instance.register(...)`. Parity rows W-5 / R-3.
///
/// `defaultConfig` is an action-type-scoped default payload (e.g. send_email
/// might default to `{'subject': '', 'body': ''}`). Library ships empty `{}`
/// defaults; TRD 020-03 layers per-action defaults on top.
class EdenWorkflowActionType {
  const EdenWorkflowActionType({
    required this.id,
    required this.displayName,
    required this.icon,
    this.description,
    this.defaultConfig = const {},
  });

  final String id;
  final String displayName;
  final IconData icon;
  final String? description;
  final Map<String, dynamic> defaultConfig;

  @override
  bool operator ==(Object other) =>
      other is EdenWorkflowActionType && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Singleton registry of workflow action types — parity rows W-5 / R-3.
///
/// Library ships these 6 defaults pre-registered:
///   - create_task (Icons.add_task)
///   - send_notification (Icons.notifications)
///   - create_callback (Icons.phone)
///   - update_status (Icons.swap_vert)
///   - send_email (Icons.mail)
///   - send_sms (Icons.message)
///
/// Test isolation: call `resetToDefaults()` in `setUp()`.
class EdenWorkflowActionRegistry {
  EdenWorkflowActionRegistry._() {
    _registerDefaults();
  }

  static final EdenWorkflowActionRegistry instance =
      EdenWorkflowActionRegistry._();

  final Map<String, EdenWorkflowActionType> _types = {};

  static const List<EdenWorkflowActionType> _defaults = [
    EdenWorkflowActionType(
      id: 'create_task',
      displayName: 'Create Task',
      icon: Icons.add_task,
    ),
    EdenWorkflowActionType(
      id: 'send_notification',
      displayName: 'Send Notification',
      icon: Icons.notifications,
    ),
    EdenWorkflowActionType(
      id: 'create_callback',
      displayName: 'Create Callback',
      icon: Icons.phone,
    ),
    EdenWorkflowActionType(
      id: 'update_status',
      displayName: 'Update Status',
      icon: Icons.swap_vert,
    ),
    EdenWorkflowActionType(
      id: 'send_email',
      displayName: 'Send Email',
      icon: Icons.mail,
    ),
    EdenWorkflowActionType(
      id: 'send_sms',
      displayName: 'Send SMS',
      icon: Icons.message,
    ),
  ];

  void _registerDefaults() {
    for (final t in _defaults) {
      _types[t.id] = t;
    }
  }

  void register(EdenWorkflowActionType type) {
    if (_types.containsKey(type.id)) {
      throw StateError(
        'Workflow action type "${type.id}" already registered. '
        'Call reset() first.',
      );
    }
    _types[type.id] = type;
  }

  EdenWorkflowActionType? lookup(String id) => _types[id];

  List<EdenWorkflowActionType> all() => List.unmodifiable(_types.values);

  void reset() => _types.clear();

  void resetToDefaults() {
    _types.clear();
    _registerDefaults();
  }
}
