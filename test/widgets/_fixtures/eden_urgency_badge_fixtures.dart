// Do NOT regenerate via LLM — hand-built fixtures for EdenUrgencyBadge.
//
// Constants for the urgency-level rendering expectations enumerated in
// 003-01-TRD.md test list. Add new tuples by hand only.

import 'package:flutter/material.dart';

class EdenUrgencyBadgeFixtures {
  EdenUrgencyBadgeFixtures._();

  /// The four canonical urgency strings the donor + library recognise.
  static const List<String> knownLevels = <String>[
    'low',
    'medium',
    'high',
    'critical',
  ];

  /// Display labels for the four canonical urgency strings.
  static const Map<String, String> expectedLabels = <String, String>{
    'low': 'Low',
    'medium': 'Medium',
    'high': 'High',
    'critical': 'Critical',
  };

  /// Only `high` and `critical` render an icon. `low` and `medium` do not.
  static const Map<String, IconData> iconLevels = <String, IconData>{
    'high': Icons.priority_high,
    'critical': Icons.warning_rounded,
  };

  /// Hand-picked unknown urgency strings — donor falls through to raw-input
  /// label on the onSurfaceVariant tone.
  static const List<String> unknownSamples = <String>[
    'urgent_af',
    'p0',
    'wat',
  ];
}
