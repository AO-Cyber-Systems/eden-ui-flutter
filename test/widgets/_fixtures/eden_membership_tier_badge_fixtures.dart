// Do NOT regenerate via LLM — hand-built fixtures for EdenMembershipTierBadge.
//
// Preset tier list + custom-tier examples for cross-vertical use cases.

import 'package:flutter/material.dart';

@immutable
class EdenCustomTierExample {
  const EdenCustomTierExample({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;
}

class EdenMembershipTierBadgeFixtures {
  EdenMembershipTierBadgeFixtures._();

  /// All preset tier names (matches enum EdenMembershipTier values).
  static const List<String> presetTierNames = [
    'Bronze',
    'Silver',
    'Gold',
    'Platinum',
    'VIP',
  ];

  /// Custom-tier examples covering salon/retail/legal/gov use cases.
  static const List<EdenCustomTierExample> customExamples = [
    EdenCustomTierExample(
      label: 'Elite',
      background: Color(0xFFEC4899),
      foreground: Color(0xFFFFFFFF),
    ),
    EdenCustomTierExample(
      label: 'TS-SCI',
      background: Color(0xFF7F1D1D),
      foreground: Color(0xFFFFFFFF),
      icon: Icons.security,
    ),
    EdenCustomTierExample(
      label: 'Lapsed',
      background: Color(0xFFE5E7EB),
      foreground: Color(0xFF374151),
    ),
  ];
}
