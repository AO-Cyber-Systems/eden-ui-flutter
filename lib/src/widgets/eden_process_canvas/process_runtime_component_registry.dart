import 'package:flutter/material.dart';

/// A runtime-component type — describes the renderer used when a task
/// instance is executed (e.g. `checklist`, `photo_gallery`, `signature_capture`).
///
/// Library ships 6 sensible defaults; consumers register vertical-specific
/// runtime components via `EdenProcessRuntimeComponentRegistry.instance.register(...)`.
class EdenProcessRuntimeComponentType {
  const EdenProcessRuntimeComponentType({
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
      other is EdenProcessRuntimeComponentType && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Singleton registry of runtime-component types — parity row R-2.
///
/// Library ships these 6 defaults pre-registered (matching donor's most-used
/// runtime components):
///   - checklist
///   - form
///   - photo_gallery
///   - signature_capture
///   - approval_gate
///   - notes_log
///
/// Donor `TaskNode.tsx` maps 15 runtime components total; the remaining 9
/// (timeline, equipment_list, materials_tracker, lien_waiver_tracker,
/// closeout_checklist, multi_checklist, kanban, status_selector, document_upload)
/// are vertical-specific and registered by downstream consumers.
///
/// Test isolation: call `resetToDefaults()` in `setUp()` to restore the 6
/// defaults and clear any test-registered components.
class EdenProcessRuntimeComponentRegistry {
  EdenProcessRuntimeComponentRegistry._() {
    _registerDefaults();
  }

  static final EdenProcessRuntimeComponentRegistry instance =
      EdenProcessRuntimeComponentRegistry._();

  final Map<String, EdenProcessRuntimeComponentType> _types = {};

  static const List<EdenProcessRuntimeComponentType> _defaults = [
    EdenProcessRuntimeComponentType(
      id: 'checklist',
      displayName: 'Checklist',
      icon: Icons.check_box,
    ),
    EdenProcessRuntimeComponentType(
      id: 'form',
      displayName: 'Form',
      icon: Icons.description,
    ),
    EdenProcessRuntimeComponentType(
      id: 'photo_gallery',
      displayName: 'Photo Gallery',
      icon: Icons.image,
    ),
    EdenProcessRuntimeComponentType(
      id: 'signature_capture',
      displayName: 'Signature Capture',
      icon: Icons.draw,
    ),
    EdenProcessRuntimeComponentType(
      id: 'approval_gate',
      displayName: 'Approval Gate',
      icon: Icons.shield,
    ),
    EdenProcessRuntimeComponentType(
      id: 'notes_log',
      displayName: 'Notes Log',
      icon: Icons.notes,
    ),
  ];

  void _registerDefaults() {
    for (final t in _defaults) {
      _types[t.id] = t;
    }
  }

  /// Register a new runtime component. Throws [StateError] on duplicate id —
  /// caller MUST `reset()` (or `resetToDefaults()`) first if overriding.
  void register(EdenProcessRuntimeComponentType type) {
    if (_types.containsKey(type.id)) {
      throw StateError(
        'Runtime component "${type.id}" already registered. Call reset() first.',
      );
    }
    _types[type.id] = type;
  }

  /// Look up a runtime component by id. Returns null when not registered.
  EdenProcessRuntimeComponentType? lookup(String id) => _types[id];

  /// All registered runtime components (read-only snapshot).
  List<EdenProcessRuntimeComponentType> all() => List.unmodifiable(_types.values);

  /// Clear all registrations including library defaults. Use only in tests
  /// that specifically need an empty registry.
  void reset() => _types.clear();

  /// Reset to the 6 library defaults. Use this in test `setUp()` for tests
  /// that exercise the default-registered set.
  void resetToDefaults() {
    _types.clear();
    _registerDefaults();
  }
}
