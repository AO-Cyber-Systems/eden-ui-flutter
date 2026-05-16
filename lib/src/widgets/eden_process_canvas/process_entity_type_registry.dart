import 'package:flutter/material.dart' show IconData;

/// A registered entity type that a process definition may be associated with.
///
/// Verticals register their own entity types via
/// `EdenProcessEntityTypeRegistry.instance.register(...)`. Library ships the
/// registry EMPTY — locked decision §7.2 (the library is vertical-agnostic).
class EdenProcessEntityType {
  const EdenProcessEntityType({
    required this.id,
    required this.displayName,
    required this.icon,
    this.description,
    this.data = const {},
  });

  final String id;
  final String displayName;
  final IconData icon;
  final String? description;
  final Map<String, dynamic> data;

  @override
  bool operator ==(Object other) =>
      other is EdenProcessEntityType &&
      other.id == id &&
      other.displayName == displayName &&
      other.icon == icon &&
      other.description == description;

  @override
  int get hashCode => Object.hash(id, displayName, icon, description);
}

/// Singleton registry of process entity types — parity row R-1.
///
/// Ships EMPTY. Verticals fill it (e.g. trades registers `service_visit`,
/// fuel registers `fuel_delivery`, etc).
///
/// Test isolation: call `reset()` in `setUp()` to clear all registrations.
class EdenProcessEntityTypeRegistry {
  EdenProcessEntityTypeRegistry._();

  static final EdenProcessEntityTypeRegistry instance =
      EdenProcessEntityTypeRegistry._();

  final Map<String, EdenProcessEntityType> _types = {};

  /// Register an entity type. Throws [StateError] if id is already registered.
  void register(EdenProcessEntityType type) {
    if (_types.containsKey(type.id)) {
      throw StateError(
        'Entity type "${type.id}" already registered. Call reset() first.',
      );
    }
    _types[type.id] = type;
  }

  /// Look up an entity type by id. Returns null when not registered.
  EdenProcessEntityType? lookup(String id) => _types[id];

  /// All registered entity types (read-only snapshot).
  List<EdenProcessEntityType> all() => List.unmodifiable(_types.values);

  /// Clear all registrations. MUST be called in tests' `setUp()` to avoid
  /// cross-test bleed.
  void reset() => _types.clear();
}
