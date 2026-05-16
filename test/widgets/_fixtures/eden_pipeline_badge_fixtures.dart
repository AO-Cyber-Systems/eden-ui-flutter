// Do NOT regenerate via LLM — hand-built fixtures for EdenPipelineBadge.
//
// Constants for the 5 canonical pipeline stages + alias mappings enumerated in
// 003-02-TRD.md test list. Add new tuples by hand only.

import 'package:flutter/material.dart';

class EdenPipelineBadgeFixtures {
  EdenPipelineBadgeFixtures._();

  /// The five canonical pipeline-stage strings the donor + library recognise.
  static const List<String> knownStages = <String>[
    'draft',
    'sent',
    'won',
    'lost',
    'expired',
  ];

  /// Aliases that resolve to canonical stages.
  /// 'accepted' → 'won'; 'rejected' → 'lost'.
  static const Map<String, String> aliasMap = <String, String>{
    'accepted': 'won',
    'rejected': 'lost',
  };

  /// Display labels for the canonical stages.
  static const Map<String, String> expectedLabels = <String, String>{
    'draft': 'Draft',
    'sent': 'Sent',
    'won': 'Won',
    'lost': 'Lost',
    'expired': 'Expired',
  };

  /// Icon mapping for canonical stages.
  static const Map<String, IconData> expectedIcons = <String, IconData>{
    'draft': Icons.edit_outlined,
    'sent': Icons.send_outlined,
    'won': Icons.check_circle_outline,
    'lost': Icons.cancel_outlined,
    'expired': Icons.schedule_outlined,
  };
}
