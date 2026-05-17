/// Singleton registry of merge-variable groups — parity row R-2.
///
/// Ships EMPTY. Verticals fill it (e.g. salon registers `customer.name`,
/// medical registers `patient.name`, trades registers `job_site.address`).
///
/// `register(group, fields)` APPENDS to existing group — additive vertical
/// registration. Call [reset] in test `setUp()` for isolation.
class EdenTemplateVariablesRegistry {
  EdenTemplateVariablesRegistry._();

  static final EdenTemplateVariablesRegistry instance =
      EdenTemplateVariablesRegistry._();

  final Map<String, List<String>> _groups = {};

  /// Register fields under [group]. Appends to existing group if present.
  void register(String group, List<String> fields) {
    _groups.putIfAbsent(group, () => <String>[]).addAll(fields);
  }

  /// Look up fields for [group]. Returns null when group is unregistered.
  List<String>? lookup(String group) {
    final fields = _groups[group];
    if (fields == null) return null;
    return List.unmodifiable(fields);
  }

  /// All registered groups → fields. Returns an unmodifiable shallow copy.
  Map<String, List<String>> all() {
    return Map.unmodifiable(<String, List<String>>{
      for (final entry in _groups.entries)
        entry.key: List.unmodifiable(entry.value),
    });
  }

  /// List of registered group names, sorted alphabetically.
  List<String> groups() {
    final list = _groups.keys.toList()..sort();
    return List.unmodifiable(list);
  }

  /// Clear all registrations.
  void reset() => _groups.clear();
}
