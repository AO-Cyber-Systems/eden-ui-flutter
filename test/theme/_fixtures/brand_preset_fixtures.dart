// test/theme/_fixtures/brand_preset_fixtures.dart
//
// Hand-built test fixtures for EdenBrandPreset / EdenBrandPresetRegistry
// (objective 009 TRD 03). Do NOT regenerate via LLM — mutate in-place
// when the registry contract changes.
// Per global TDD Playbook habit 4 + resolver no_llm_test_data constraint.

class BrandPresetFixtures {
  BrandPresetFixtures._();

  /// LOCKED — the 15 preset ids the registry MUST ship with.
  /// Order matches the table in TRD 009-03-TRD.md `<objective>` section.
  /// Adding/removing requires updating both this list AND the registry.
  static const List<String> expectedIds = [
    // Rows 1-7: bridges from existing EdenColors.presets
    'gold',
    'blue',
    'emerald',
    'purple',
    'red',
    'slate',
    'cyan',
    // Rows 8-15: vertically-flavored
    'salon-coral',
    'trades-industrial-blue',
    'medical-teal',
    'fuel-energy-orange',
    'gov-federal-navy',
    'legal-navy',
    'retail-vibrant-magenta',
    'wellness-sage',
  ];

  /// LOCKED — the 7 bridge ids that wrap EdenColors.presets keys.
  /// Drift here breaks the migration path from
  /// `EdenColors.presets['gold']` → `EdenBrandPresetRegistry.byId('gold')`.
  static const List<String> bridgeIds = [
    'gold',
    'blue',
    'emerald',
    'purple',
    'red',
    'slate',
    'cyan',
  ];
}
