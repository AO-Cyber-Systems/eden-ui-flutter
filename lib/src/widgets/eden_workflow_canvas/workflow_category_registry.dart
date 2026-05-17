import 'package:flutter/material.dart';

/// A workflow category — describes the kind of entity this workflow operates
/// on (e.g. `appointment`, `task`, `project`, `customer`, `callback`).
///
/// Library ships 5 sensible defaults. Verticals register vertical-specific
/// categories (e.g. `visit`, `delivery_route`, `claim`) via
/// `EdenWorkflowCategoryRegistry.instance.register(...)`. Parity row R-1.
///
/// Equality is by `id` (the registry key) so a vertical can compare a
/// stored category id against a registered instance.
class EdenWorkflowCategory {
  const EdenWorkflowCategory({
    required this.id,
    required this.displayName,
    required this.icon,
    this.description,
  });

  final String id;
  final String displayName;
  final IconData icon;
  final String? description;

  @override
  bool operator ==(Object other) =>
      other is EdenWorkflowCategory && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Singleton registry of workflow categories — parity row R-1.
///
/// Library ships these 5 defaults pre-registered:
///   - appointment (Icons.event)
///   - task (Icons.task_alt)
///   - project (Icons.folder)
///   - customer (Icons.person)
///   - callback (Icons.phone_callback)
///
/// Test isolation: call `resetToDefaults()` in `setUp()` to restore the 5
/// defaults and clear any test-registered categories.
class EdenWorkflowCategoryRegistry {
  EdenWorkflowCategoryRegistry._() {
    _registerDefaults();
  }

  static final EdenWorkflowCategoryRegistry instance =
      EdenWorkflowCategoryRegistry._();

  final Map<String, EdenWorkflowCategory> _types = {};

  static const List<EdenWorkflowCategory> _defaults = [
    EdenWorkflowCategory(
      id: 'appointment',
      displayName: 'Appointment',
      icon: Icons.event,
    ),
    EdenWorkflowCategory(
      id: 'task',
      displayName: 'Task',
      icon: Icons.task_alt,
    ),
    EdenWorkflowCategory(
      id: 'project',
      displayName: 'Project',
      icon: Icons.folder,
    ),
    EdenWorkflowCategory(
      id: 'customer',
      displayName: 'Customer',
      icon: Icons.person,
    ),
    EdenWorkflowCategory(
      id: 'callback',
      displayName: 'Callback',
      icon: Icons.phone_callback,
    ),
  ];

  void _registerDefaults() {
    for (final c in _defaults) {
      _types[c.id] = c;
    }
  }

  /// Register a new category. Throws [StateError] on duplicate id —
  /// caller MUST `reset()` (or `resetToDefaults()`) first if overriding.
  void register(EdenWorkflowCategory category) {
    if (_types.containsKey(category.id)) {
      throw StateError(
        'Workflow category "${category.id}" already registered. '
        'Call reset() first.',
      );
    }
    _types[category.id] = category;
  }

  /// Look up a category by id. Returns null when not registered.
  EdenWorkflowCategory? lookup(String id) => _types[id];

  /// All registered categories (read-only snapshot).
  List<EdenWorkflowCategory> all() => List.unmodifiable(_types.values);

  /// Clear all registrations including library defaults. Use only in tests
  /// that specifically need an empty registry.
  void reset() => _types.clear();

  /// Reset to the 5 library defaults. Use this in test `setUp()` for tests
  /// that exercise the default-registered set.
  void resetToDefaults() {
    _types.clear();
    _registerDefaults();
  }
}
