// EdenWorkflowFieldRegistry — registry-driven entity field catalog.
//
// Distinct from Category + Action registries: ships EMPTY by default.
// Verticals fill it with their entity fields (per category). Library does
// NOT presume what an `appointment`'s fields are — varies per vertical.
// Parity row R-4.

/// A registered entity field (e.g. `customer.name`, `start_time`).
///
/// `category` matches `EdenWorkflowCategoryRegistry` ids (e.g. 'appointment',
/// 'customer'). `type` is one of: `string`, `number`, `date`, `boolean`,
/// `object` — used by the EventBrowser badge rendering.
///
/// Equality is by `name` (the registry key).
class EdenWorkflowField {
  const EdenWorkflowField({
    required this.name,
    required this.label,
    required this.type,
    this.description,
    required this.category,
  });

  final String name;
  final String label;
  final String type;
  final String? description;
  final String category;

  @override
  bool operator ==(Object other) =>
      other is EdenWorkflowField && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

/// Singleton registry of entity fields. **Ships EMPTY** (parity row R-4).
///
/// Verticals register their entity fields with the registry so the
/// EventBrowser can populate the field picker UI for `{customer.name}`-style
/// interpolation tokens in action configs.
class EdenWorkflowFieldRegistry {
  EdenWorkflowFieldRegistry._();

  static final EdenWorkflowFieldRegistry instance =
      EdenWorkflowFieldRegistry._();

  final Map<String, EdenWorkflowField> _fields = {};

  /// Register an entity field. Throws [StateError] on duplicate name.
  void register(EdenWorkflowField field) {
    if (_fields.containsKey(field.name)) {
      throw StateError(
        'Workflow field "${field.name}" already registered. '
        'Call reset() first.',
      );
    }
    _fields[field.name] = field;
  }

  /// Look up a field by its full name (e.g. `customer.name`).
  EdenWorkflowField? lookup(String name) => _fields[name];

  /// All registered fields (read-only snapshot).
  List<EdenWorkflowField> all() => List.unmodifiable(_fields.values);

  /// Fields filtered by category id.
  List<EdenWorkflowField> byCategory(String categoryId) => _fields.values
      .where((f) => f.category == categoryId)
      .toList(growable: false);

  /// Case-insensitive search matching field name OR label. Optionally
  /// scoped to a single category.
  ///
  /// Empty query returns ALL fields in the optional category scope.
  List<EdenWorkflowField> search(String query, {String? categoryId}) {
    final q = query.toLowerCase();
    return _fields.values
        .where((f) {
          if (categoryId != null && f.category != categoryId) return false;
          if (q.isEmpty) return true;
          return f.name.toLowerCase().contains(q) ||
              f.label.toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  /// Clear all registered fields.
  void reset() => _fields.clear();
}
