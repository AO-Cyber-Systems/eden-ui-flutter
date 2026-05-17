// lib/src/theme/eden_brand_preset.dart
//
// Hand-built brand preset registry. Do NOT regenerate via LLM —
// mutate in-place when the registry contract changes.
// Per global TDD Playbook habit 4 + resolver no_llm_test_data constraint.
//
// Closed v1 set of 15 presets per TRD 009-03-TRD.md.
// Adding presets requires updating both the _all list AND the
// BrandPresetFixtures.expectedIds list in
// test/theme/_fixtures/brand_preset_fixtures.dart.

import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// A named brand-color preset shippable as a tenant-config option.
///
/// Brand presets are PROFILE-INDEPENDENT — a tenant can pick any preset
/// with any [EdenThemeProfile]. See [EdenAdaptiveTheme] (objective 009
/// TRD 05) for the wiring entry point.
///
/// Per OBJECTIVE.md (009) Constraint 2 + aesthetic-preservation principle 1:
/// presets reuse existing [EdenColors] MaterialColors. The distinction
/// between e.g. `red` and `salon-coral` is the **id + displayName +
/// recommendedFor metadata**, not the rendered hex.
@immutable
class EdenBrandPreset {
  const EdenBrandPreset({
    required this.id,
    required this.displayName,
    required this.color,
    required this.recommendedFor,
  });

  /// Stable kebab-case identifier. Used for tenant config persistence +
  /// registry lookup via [EdenBrandPresetRegistry.byId].
  final String id;

  /// Human-facing label for "Choose brand" UI surfaces.
  final String displayName;

  /// The MaterialColor applied as the brand color when the preset is active.
  final MaterialColor color;

  /// Vertical tags this preset is recommended for. Used by
  /// [EdenBrandPresetRegistry.forVertical] for case-insensitive filtering.
  /// Non-empty by contract; at least one tag per preset.
  final List<String> recommendedFor;
}

/// Static registry of ship-with brand presets. Closed v1 set — for runtime
/// custom presets, downstream apps construct their own [EdenBrandPreset]
/// instances and feed them into [EdenAdaptiveTheme] directly.
class EdenBrandPresetRegistry {
  EdenBrandPresetRegistry._();

  // ===========================================================================
  // The 15 ship-with presets. HAND-BUILT — do not regenerate.
  // Rows 1-7: bridges from existing EdenColors.presets (id-stable migration).
  // Rows 8-15: vertically-flavored (existing colors, new metadata).
  // ===========================================================================
  static const List<EdenBrandPreset> _all = [
    // ------- Bridges from EdenColors.presets ----------------------------------
    EdenBrandPreset(
      id: 'gold',
      displayName: 'Gold',
      color: EdenColors.gold,
      recommendedFor: ['default', 'commercial', 'salon', 'wellness'],
    ),
    EdenBrandPreset(
      id: 'blue',
      displayName: 'Blue',
      color: EdenColors.blue,
      recommendedFor: ['commercial', 'trades', 'gov'],
    ),
    EdenBrandPreset(
      id: 'emerald',
      displayName: 'Emerald',
      color: EdenColors.emerald,
      recommendedFor: ['commercial', 'wellness', 'fuel'],
    ),
    EdenBrandPreset(
      id: 'purple',
      displayName: 'Purple',
      color: EdenColors.purple,
      recommendedFor: ['commercial', 'retail'],
    ),
    EdenBrandPreset(
      id: 'red',
      displayName: 'Red',
      color: EdenColors.red,
      recommendedFor: ['commercial', 'fuel', 'gov'],
    ),
    EdenBrandPreset(
      id: 'slate',
      displayName: 'Slate',
      color: EdenColors.slate,
      recommendedFor: ['commercial', 'legal'],
    ),
    EdenBrandPreset(
      id: 'cyan',
      displayName: 'Cyan',
      color: EdenColors.cyan,
      recommendedFor: ['commercial', 'medical'],
    ),
    // ------- Vertically-flavored ---------------------------------------------
    EdenBrandPreset(
      id: 'salon-coral',
      displayName: 'Coral',
      color: EdenColors.red,
      recommendedFor: ['salon', 'spa', 'wellness'],
    ),
    EdenBrandPreset(
      id: 'trades-industrial-blue',
      displayName: 'Industrial Blue',
      color: EdenColors.blue,
      recommendedFor: ['trades', 'hvac', 'plumbing', 'electrical'],
    ),
    EdenBrandPreset(
      id: 'medical-teal',
      displayName: 'Medical Teal',
      color: EdenColors.cyan,
      recommendedFor: ['medical', 'healthtech', 'home-visit'],
    ),
    EdenBrandPreset(
      id: 'fuel-energy-orange',
      displayName: 'Energy Orange',
      color: EdenColors.gold,
      recommendedFor: ['fuel', 'logistics', 'fleet'],
    ),
    EdenBrandPreset(
      id: 'gov-federal-navy',
      displayName: 'Federal Navy',
      color: EdenColors.blue,
      recommendedFor: ['gov', 'federal', 'dhhs', 'dod'],
    ),
    EdenBrandPreset(
      id: 'legal-navy',
      displayName: 'Legal Navy',
      color: EdenColors.slate,
      recommendedFor: ['legal', 'practice-management'],
    ),
    EdenBrandPreset(
      id: 'retail-vibrant-magenta',
      displayName: 'Vibrant Magenta',
      color: EdenColors.purple,
      recommendedFor: ['retail', 'pos', 'commerce'],
    ),
    EdenBrandPreset(
      id: 'wellness-sage',
      displayName: 'Wellness Sage',
      color: EdenColors.emerald,
      recommendedFor: ['wellness', 'spa', 'fitness'],
    ),
  ];

  /// Lazily built id-lookup map. First access also runs the duplicate-id
  /// integrity check; assertion fires in debug if duplicates found.
  static final Map<String, EdenBrandPreset> _byId = _buildById();

  static Map<String, EdenBrandPreset> _buildById() {
    final map = <String, EdenBrandPreset>{};
    for (final p in _all) {
      assert(!map.containsKey(p.id),
          'Duplicate EdenBrandPreset id detected: ${p.id}');
      map[p.id] = p;
    }
    return map;
  }

  /// All registered presets in their canonical order. Returns an
  /// unmodifiable list — callers wanting to mutate should construct their own.
  static List<EdenBrandPreset> all() => List.unmodifiable(_all);

  /// Lookup by id. Returns null when not found.
  static EdenBrandPreset? byId(String id) => _byId[id];

  /// Filter presets recommending the given vertical (case-insensitive).
  /// Returns an empty list when no matches. Never null.
  static List<EdenBrandPreset> forVertical(String vertical) {
    final lower = vertical.toLowerCase();
    return _all
        .where((p) => p.recommendedFor.any((v) => v.toLowerCase() == lower))
        .toList();
  }
}
